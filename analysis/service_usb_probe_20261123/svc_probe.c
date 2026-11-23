// svc_probe.c — LUMIX 服务模式 USB (04DA:2370) 只读探测器  [S1M2 移植试验]
//
// 原理与帧格式来自公开前作，并由 USER-HFC/Lumix_Tool 的 app/python/s5svc.py 复刻：
//   flickering-star/lumix-firmware-research
//   gavenomix/lumix-gx8-usb-service
//
// 服务模式（关机按住 PLAY + AF-ON 开机）下相机枚举为 04DA:2370，
// 厂商自定义类，Bulk OUT/IN 上跑自定义帧：
//   [0]=kind [1]=0x00 [2]=0xFF [3]=opcode ... [n-2]=checksum [n-1]=0
//   checksum = sum(bytes[1 .. n-3]) & 0xFF
//
// 本程序只实现两个只读操作：
//   0x38  设置字读（area 0x20, index u16, 16 字节帧）
//   0x5C  绝对物理地址 1 KiB 块读（1030 字节帧）
//
// 刻意不包含 0x9C（半字写）与 0x70（会冻机）的任何代码路径。
// 写入 S1M2 的 RAM 没有任何已验证的地址/映射，本工具永远不写。
//
// 用法:
//   ./svc_probe identify                      # 0x38 读 0x3F80..0x3F8F 的识别字节
//   ./svc_probe read 0x40000000 [--out f]     # 读 1 KiB
//   ./svc_probe dump 0x40000000 0x10000 [--out f]
//   ./svc_probe selftest                      # 离线校验帧构造
//   选项: --timeout-ms N  --settle-ms N
//
// 编译: make   (或: clang $(pkg-config --cflags libusb-1.0) svc_probe.c $(pkg-config --libs libusb-1.0) -o svc_probe)

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <stdint.h>
#include <unistd.h>
#include <libusb.h>

#define VID 0x04DA
#define PID_SERVICE 0x2370
#define PID_TETHR 0x2382
#define FRAME_LEN 16
#define BLOCK_DATA_LEN 1024
#define BLOCK_FRAME_LEN (BLOCK_DATA_LEN + 6)  // 1030
#define IDENTIFY_AREA 0x20
#define IDENTIFY_FIRST 0x3F80
#define IDENTIFY_LAST 0x3F8F

static int g_timeout_ms = 2000;
static int g_settle_ms = 100;
static int g_quiet = 0;

static void note(const char *s) { fprintf(stderr, "[*] %s\n", s); fflush(stderr); }
static void fail(const char *s) { fprintf(stderr, "[!] %s\n", s); fflush(stderr); }

static uint8_t frame_checksum(const uint8_t *f, size_t len) {
    unsigned s = 0;
    for (size_t i = 1; i + 2 < len; i++) s += f[i];
    return (uint8_t)(s & 0xFF);
}

static void build_0x38(uint8_t f[FRAME_LEN], uint16_t index) {
    memset(f, 0, FRAME_LEN);
    f[0] = 0x08; f[1] = 0x00; f[2] = 0xFF; f[3] = 0x38;
    f[4] = index & 0xFF; f[5] = (index >> 8) & 0xFF; f[6] = IDENTIFY_AREA;
    f[14] = frame_checksum(f, FRAME_LEN); f[15] = 0;
}

static void build_0x9b(uint8_t f[FRAME_LEN], uint32_t addr) {
    memset(f, 0, FRAME_LEN);
    f[0] = 0x08; f[1] = 0x00; f[2] = 0xFF; f[3] = 0x9B;
    f[4] = addr & 0xFF; f[5] = (addr >> 8) & 0xFF;
    f[6] = (addr >> 16) & 0xFF; f[7] = (addr >> 24) & 0xFF;
    f[14] = frame_checksum(f, FRAME_LEN); f[15] = 0;
}

static void build_0x5c(uint8_t f[BLOCK_FRAME_LEN], uint32_t addr) {
    memset(f, 0, BLOCK_FRAME_LEN);
    f[0] = 0x01; f[1] = 0x00; f[2] = 0xFF; f[3] = 0x5C;
    f[4] = addr & 0xFF; f[5] = (addr >> 8) & 0xFF;
    f[6] = (addr >> 16) & 0xFF; f[7] = (addr >> 24) & 0xFF;
    uint32_t end = addr + BLOCK_DATA_LEN;
    f[8] = end & 0xFF; f[9] = (end >> 8) & 0xFF;
    f[10] = (end >> 16) & 0xFF; f[11] = (end >> 24) & 0xFF;
    f[1028] = frame_checksum(f, BLOCK_FRAME_LEN); f[1029] = 0;
}

static int check_frame(const uint8_t *f, size_t len) {
    return f[len - 1] == 0 && f[len - 2] == frame_checksum(f, len);
}

typedef struct {
    libusb_device_handle *h;
    uint8_t ep_out, ep_in;
    int ifnum;
} svc_t;

static int find_endpoints(libusb_device *dev, svc_t *svc) {
    struct libusb_config_descriptor *cfg = NULL;
    int r = libusb_get_active_config_descriptor(dev, &cfg);
    if (r != 0 || !cfg) { fail(libusb_error_name(r)); return -1; }

    printf("config %d: %d interface(s)\n", cfg->bConfigurationValue, cfg->bNumInterfaces);
    int chosen = -1;
    for (int i = 0; i < cfg->bNumInterfaces; i++) {
        const struct libusb_interface_descriptor *id = &cfg->interface[i].altsetting[0];
        printf("  if%d alt0: class=0x%02x sub=0x%02x proto=0x%02x eps=%d",
               id->bInterfaceNumber, id->bInterfaceClass, id->bInterfaceSubClass,
               id->bInterfaceProtocol, id->bNumEndpoints);
        int has_out = 0, has_in = 0;
        for (int e = 0; e < id->bNumEndpoints; e++) {
            const struct libusb_endpoint_descriptor *ep = &id->endpoint[e];
            int is_bulk = (ep->bmAttributes & 0x03) == LIBUSB_TRANSFER_TYPE_BULK;
            printf(" ep0x%02x%s", ep->bEndpointAddress, is_bulk ? "bulk" : "");
            if (is_bulk && (ep->bEndpointAddress & 0x80)) has_in = 1;
            if (is_bulk && !(ep->bEndpointAddress & 0x80)) has_out = 1;
        }
        printf("\n");
        if (has_in && has_out && (chosen < 0 || id->bInterfaceClass == 0xFF))
            chosen = i;
    }
    if (chosen < 0) { fail("no interface with bulk IN + bulk OUT"); libusb_free_config_descriptor(cfg); return -1; }

    const struct libusb_interface_descriptor *id = &cfg->interface[chosen].altsetting[0];
    svc->ifnum = id->bInterfaceNumber;
    svc->ep_out = 0; svc->ep_in = 0;
    for (int e = 0; e < id->bNumEndpoints; e++) {
        const struct libusb_endpoint_descriptor *ep = &id->endpoint[e];
        if ((ep->bmAttributes & 0x03) != LIBUSB_TRANSFER_TYPE_BULK) continue;
        if (ep->bEndpointAddress & 0x80) {
            if (!svc->ep_in || ep->bEndpointAddress == 0x82) svc->ep_in = ep->bEndpointAddress;
        } else {
            if (!svc->ep_out || ep->bEndpointAddress == 0x01) svc->ep_out = ep->bEndpointAddress;
        }
    }
    if (getenv("SVC_EP_IN")) svc->ep_in = (uint8_t)strtoul(getenv("SVC_EP_IN"), NULL, 0);
    if (getenv("SVC_EP_OUT")) svc->ep_out = (uint8_t)strtoul(getenv("SVC_EP_OUT"), NULL, 0);
    printf("using if%d ep_out=0x%02x ep_in=0x%02x\n", svc->ifnum, svc->ep_out, svc->ep_in);
    libusb_free_config_descriptor(cfg);
    return 0;
}

static int open_service(svc_t *svc) {
    memset(svc, 0, sizeof(*svc));
    if (libusb_init(NULL) != 0) { fail("libusb_init failed"); return -1; }
    libusb_device **list;
    ssize_t n = libusb_get_device_list(NULL, &list);
    if (n < 0) { fail("device list failed"); return -1; }

    libusb_device *dev = NULL;
    printf("libusb devices: %ld\n", (long)n);
    for (ssize_t i = 0; i < n; i++) {
        struct libusb_device_descriptor dd;
        int dr = libusb_get_device_descriptor(list[i], &dd);
        if (dr != 0) {
            printf("  dev[%ld] descriptor error: %s\n", (long)i, libusb_error_name(dr));
            continue;
        }
        printf("  dev[%ld] %04x:%04x bus=%d addr=%d\n", (long)i, dd.idVendor, dd.idProduct,
               libusb_get_bus_number(list[i]), libusb_get_device_address(list[i]));
        if (dd.idVendor == VID && dd.idProduct == PID_SERVICE) dev = list[i];
    }
    if (!dev) {
        fail("no 04DA:2370 — 相机不在服务模式（关机按住 PLAY+AF-ON 开机），"
             "或本机枚举到的只有 04DA:2382 (Tether/PTP)");
        libusb_free_device_list(list, 1);
        libusb_exit(NULL);
        return -1;
    }

    int r = libusb_open(dev, &svc->h);
    if (r != 0) {
        fail(libusb_error_name(r));
        libusb_free_device_list(list, 1);
        libusb_exit(NULL);
        return -1;
    }

    if (find_endpoints(dev, svc) != 0) {
        libusb_close(svc->h); svc->h = NULL;
        libusb_free_device_list(list, 1);
        libusb_exit(NULL);
        return -1;
    }

#ifdef __linux__
    libusb_set_auto_detach_kernel_driver(svc->h, 1);
#endif
    r = libusb_claim_interface(svc->h, svc->ifnum);
    if (r != 0) {
        fprintf(stderr, "[!] claim interface %d failed: %s\n", svc->ifnum, libusb_error_name(r));
        libusb_close(svc->h); svc->h = NULL;
        libusb_free_device_list(list, 1);
        libusb_exit(NULL);
        return -1;
    }
    libusb_free_device_list(list, 1);
    note("service interface claimed");
    return 0;
}

static void close_service(svc_t *svc) {
    if (svc->h) {
        libusb_release_interface(svc->h, svc->ifnum);
        libusb_close(svc->h);
    }
    libusb_exit(NULL);
}

static int ctrl(svc_t *svc, uint16_t index) {
    int r = libusb_control_transfer(svc->h, 0x40, 0x00, 0x0000, index, NULL, 0, g_timeout_ms);
    if (r < 0) { fail(libusb_error_name(r)); return -1; }
    return 0;
}

static int bulk_out(svc_t *svc, const uint8_t *buf, int len) {
    int transferred = 0;
    int r = libusb_bulk_transfer(svc->h, svc->ep_out, (unsigned char *)buf, len,
                                 &transferred, g_timeout_ms);
    if (r != 0) { fprintf(stderr, "[!] bulk OUT: %s\n", libusb_error_name(r)); return -1; }
    if (transferred != len) { fprintf(stderr, "[!] short bulk OUT %d/%d\n", transferred, len); return -1; }
    return 0;
}

static int bulk_in(svc_t *svc, uint8_t *buf, int len) {
    int transferred = 0;
    int r = libusb_bulk_transfer(svc->h, svc->ep_in, buf, len, &transferred, g_timeout_ms);
    if (r != 0) { fprintf(stderr, "[!] bulk IN: %s\n", libusb_error_name(r)); return -1; }
    if (transferred != len) { fprintf(stderr, "[!] short bulk IN %d/%d\n", transferred, len); return -1; }
    return 0;
}

// GX9 原生协议文档给出的帧类 -> 完整帧长度（含类型字节和校验尾）
static int reply_len_for_class(uint8_t c) {
    switch (c) {
        case 0x08: return 16;
        case 0x01: return 1030;
        case 0x02: return 32774;
        case 0x03: return 8198;
        case 0x04: return 4102;
        case 0x05: return 106;
        case 0x10: return 262;
        default: return -1;
    }
}

// 帧交换（与 s5svc.py 的 exchange 逐步一致；回复长度按实际类字节决定）
static int exchange(svc_t *svc, const uint8_t *frame, int frame_len,
                    uint8_t *reply, int max_len, int *out_len) {
    if (ctrl(svc, 0) != 0) return -1;
    if (bulk_out(svc, frame, frame_len) != 0) return -1;
    usleep(g_settle_ms * 1000);
    if (ctrl(svc, 1) != 0) return -1;

    uint8_t kind = 0;
    if (bulk_in(svc, &kind, 1) != 0) return -1;
    int rlen = reply_len_for_class(kind);
    if (rlen < 0) {
        fprintf(stderr, "[!] unknown reply class 0x%02x (request class 0x%02x)\n", kind, frame[0]);
        return -1;
    }
    if (rlen > max_len) {
        fprintf(stderr, "[!] reply class 0x%02x needs %d bytes, buffer %d\n", kind, rlen, max_len);
        return -1;
    }
    if (ctrl(svc, 1) != 0) return -1;
    if (bulk_in(svc, reply, rlen) != 0) return -1;
    if (!check_frame(reply, rlen)) {
        fprintf(stderr, "[!] reply checksum/terminator bad: ");
        for (int i = 0; i < (rlen < 16 ? rlen : 16); i++) fprintf(stderr, "%02x", reply[i]);
        fprintf(stderr, "\n");
        return -1;
    }
    if (out_len) *out_len = rlen;
    return 0;
}

static int cmd_identify(svc_t *svc) {
    uint8_t data[32];
    int got = 0;
    for (int idx = IDENTIFY_FIRST; idx <= IDENTIFY_LAST; idx++) {
        uint8_t f[FRAME_LEN], reply[FRAME_LEN];
        build_0x38(f, (uint16_t)idx);
        if (exchange(svc, f, FRAME_LEN, reply, FRAME_LEN, NULL) != 0) {
            printf("index 0x%04X: no valid reply\n", idx);
            continue;
        }
        if (reply[3] != 0x36) {
            printf("index 0x%04X: unexpected opcode 0x%02x  frame=", idx, reply[3]);
            for (int k = 0; k < FRAME_LEN; k++) printf("%02x", reply[k]);
            printf("\n");
            continue;
        }
        if (got + 2 <= (int)sizeof(data)) { data[got++] = reply[4]; data[got++] = reply[5]; }
        printf("index 0x%04X: %02x %02x\n", idx, reply[4], reply[5]);
    }
    printf("identify bytes (%d): ", got);
    for (int i = 0; i < got; i++) printf("%02x", data[i]);
    printf("\nidentify ascii  : ");
    for (int i = 0; i < got; i++) putchar((data[i] >= 32 && data[i] < 127) ? data[i] : '.');
    printf("\n");
    return got > 0 ? 0 : -1;
}

// 16 字节帧的绝对 2 字节读（GX9 时代 opcode 0x9B），只读
static int cmd_word(svc_t *svc, uint32_t addr) {
    uint8_t f[FRAME_LEN], reply[FRAME_LEN];
    build_0x9b(f, addr);
    if (exchange(svc, f, FRAME_LEN, reply, FRAME_LEN, NULL) != 0) return -1;
    printf("word 0x%08X reply: ", addr);
    for (int i = 0; i < FRAME_LEN; i++) printf("%02x", reply[i]);
    printf("\n");
    if (reply[3] == 0x36)
        printf("  value = 0x%04X\n", (unsigned)(reply[4] | (reply[5] << 8)));
    else
        printf("  status byte 0x%02x (expected 0x36)\n", reply[3]);
    return 0;
}

// 只读协议探索：允许 16 字节请求帧，但只放行只读 opcode
static int cmd_raw(svc_t *svc, uint8_t op, const char *args) {
    static const uint8_t allowed[] = {0x35, 0x38, 0x3A, 0x75, 0x9B};
    int ok = 0;
    for (size_t i = 0; i < sizeof(allowed); i++) if (op == allowed[i]) ok = 1;
    if (!ok) {
        fprintf(stderr, "[!] raw 只允许只读 opcode 0x35/0x38/0x3A/0x75/0x9B\n");
        return -1;
    }
    uint8_t f[FRAME_LEN];
    memset(f, 0, FRAME_LEN);
    f[0] = 0x08; f[1] = 0x00; f[2] = 0xFF; f[3] = op;
    size_t n = args ? strlen(args) : 0;
    if (n % 2 || n > 20) { fprintf(stderr, "[!] args 需为偶数字节 hex，最多 10 字节\n"); return -1; }
    for (size_t i = 0; i < n; i += 2) {
        unsigned v = 0;
        if (sscanf(args + i, "%2x", &v) != 1) { fprintf(stderr, "[!] bad hex\n"); return -1; }
        f[4 + i / 2] = (uint8_t)v;
    }
    f[14] = frame_checksum(f, FRAME_LEN); f[15] = 0;

    static uint8_t reply[32774];
    int rlen = 0;
    if (exchange(svc, f, FRAME_LEN, reply, sizeof(reply), &rlen) != 0) return -1;
    printf("raw 0x%02x reply (%d bytes): ", op, rlen);
    int show = rlen < 96 ? rlen : 96;
    for (int i = 0; i < show; i++) printf("%02x", reply[i]);
    if (show < rlen) printf(" ...");
    printf("\n");
    if (rlen > 4 && reply[3] == 0x3B) {
        // 0x3a 元数据回复：按 8 字节一行打印，便于人工读 area/capacity
        for (int i = 4; i + 7 < rlen - 2; i += 8) {
            printf("  +%03d: %02x%02x%02x%02x  %02x%02x%02x%02x\n",
                   i, reply[i], reply[i+1], reply[i+2], reply[i+3],
                   reply[i+4], reply[i+5], reply[i+6], reply[i+7]);
        }
    }
    return 0;
}

// 有界字扫描：0x35（设置影子）或 0x38（存储 bank），不涉及绝对地址
static int cmd_sweep(svc_t *svc, uint8_t op, uint32_t sel,
                     uint32_t first, uint32_t last) {
    if (op != 0x35 && op != 0x38) {
        fprintf(stderr, "[!] sweep 只支持 0x35 / 0x38\n");
        return -1;
    }
    if (first > last || last > 0xFFFF || sel > 0xFF) {
        fprintf(stderr, "[!] 参数范围: sel 0..0xff, index 0..0xffff, first<=last\n");
        return -1;
    }
    printf("sweep op=0x%02x sel=0x%02x index=0x%04X..0x%04X\n", op, (unsigned)sel,
           (unsigned)first, (unsigned)last);
    unsigned nonzero = 0, errors = 0, statuses = 0;
    for (uint32_t idx = first; idx <= last; idx++) {
        uint8_t f[FRAME_LEN], reply[FRAME_LEN];
        memset(f, 0, FRAME_LEN);
        f[0] = 0x08; f[1] = 0x00; f[2] = 0xFF; f[3] = op;
        f[4] = idx & 0xFF; f[5] = (idx >> 8) & 0xFF; f[6] = (uint8_t)sel;
        f[14] = frame_checksum(f, FRAME_LEN); f[15] = 0;
        if (exchange(svc, f, FRAME_LEN, reply, FRAME_LEN, NULL) != 0) {
            errors++;
            if (errors > 8) { fprintf(stderr, "[!] too many errors, stop\n"); break; }
            continue;
        }
        if (reply[3] != 0x36) {
            statuses++;
            printf("  idx 0x%04X status 0x%02x\n", (unsigned)idx, reply[3]);
            continue;
        }
        unsigned v = reply[4] | (reply[5] << 8);
        if (v) {
            printf("  idx 0x%04X = 0x%04X\n", (unsigned)idx, v);
            nonzero++;
        }
        if (idx != last && ((idx - first) & 0x3F) == 0x3F) {
            fprintf(stderr, "  ... 0x%04X\n", (unsigned)idx);
        }
    }
    printf("sweep done: nonzero=%u errors=%u non-0x36=%u\n", nonzero, errors, statuses);
    return errors ? -1 : 0;
}

static int cmd_read(svc_t *svc, uint32_t addr, const char *out) {
    if (addr % BLOCK_DATA_LEN) {
        fail("0x5C 要求地址 1 KiB 对齐");
        return -1;
    }
    uint8_t f[BLOCK_FRAME_LEN], reply[BLOCK_FRAME_LEN];
    build_0x5c(f, addr);
    if (exchange(svc, f, BLOCK_FRAME_LEN, reply, BLOCK_FRAME_LEN, NULL) != 0) return -1;
    if (reply[3] != 0x05) {
        fprintf(stderr, "[!] block reply opcode 0x%02x (expected 0x05)\n", reply[3]);
        return -1;
    }
    const uint8_t *d = reply + 4;
    printf("block 0x%08X: PASS\n", addr);
    printf("  first 64: ");
    for (int i = 0; i < 64; i++) printf("%02x", d[i]);
    printf("\n  ascii   : ");
    for (int i = 0; i < 64; i++) putchar((d[i] >= 32 && d[i] < 127) ? d[i] : '.');
    printf("\n");
    if (out) {
        FILE *fp = fopen(out, "wb");
        if (!fp) { perror(out); return -1; }
        fwrite(d, 1, BLOCK_DATA_LEN, fp);
        fclose(fp);
        printf("  saved: %s\n", out);
    }
    return 0;
}

static int cmd_dump(svc_t *svc, uint32_t start, uint32_t len, const char *out) {
    if (start % BLOCK_DATA_LEN) { fail("起始地址必须 1 KiB 对齐"); return -1; }
    if ((uint64_t)start + len > 0xFFFFFFFFull) { fail("地址范围超出 u32（0x5C 帧是 32 位地址）"); return -1; }
    if (out) {
        FILE *chk = fopen(out, "rb");
        if (chk) {
            fseek(chk, 0, SEEK_END);
            long sz = ftell(chk);
            fclose(chk);
            if (sz > 0) { fprintf(stderr, "[!] refusing to overwrite non-empty %s\n", out); return -1; }
        }
    }
    FILE *fp = out ? fopen(out, "wb") : NULL;
    if (out && !fp) { perror(out); return -1; }

    uint32_t addr = start, end = start + len;
    unsigned done = 0;
    while (addr < end) {
        uint8_t f[BLOCK_FRAME_LEN], reply[BLOCK_FRAME_LEN];
        build_0x5c(f, addr);
        if (exchange(svc, f, BLOCK_FRAME_LEN, reply, BLOCK_FRAME_LEN, NULL) != 0) {
            fprintf(stderr, "[!] failed at 0x%08X\n", addr);
            if (fp) fclose(fp);
            return -1;
        }
        if (reply[3] != 0x05) {
            fprintf(stderr, "[!] opcode 0x%02x at 0x%08X\n", reply[3], addr);
            if (fp) fclose(fp);
            return -1;
        }
        if (fp) fwrite(reply + 4, 1, BLOCK_DATA_LEN, fp);
        if (!g_quiet && done % 64 == 0) {
            printf("  %u / %u KiB\n", done, len / 1024);
            fflush(stdout);
        }
        addr += BLOCK_DATA_LEN;
        done++;
    }
    if (fp) { fclose(fp); printf("saved %s (%u KiB)\n", out, done); }
    return 0;
}

static int selftest(void) {
    uint8_t f[FRAME_LEN], b[BLOCK_FRAME_LEN];
    build_0x38(f, 0x3F80);
    const uint8_t want[] = {0x08, 0x00, 0xFF, 0x38, 0x80, 0x3F, 0x20};
    if (memcmp(f, want, sizeof(want)) != 0) { fail("0x38 frame mismatch"); return 1; }
    if (!check_frame(f, FRAME_LEN)) { fail("0x38 checksum"); return 1; }
    build_0x5c(b, 0x40000000);
    if (b[0] != 0x01 || b[3] != 0x5C) { fail("0x5C header"); return 1; }
    if (b[4] != 0x00 || b[5] != 0x00 || b[6] != 0x00 || b[7] != 0x40) { fail("0x5C addr"); return 1; }
    if (!check_frame(b, BLOCK_FRAME_LEN)) { fail("0x5C checksum"); return 1; }
    printf("selftest PASS\n");
    return 0;
}

static uint64_t parse_u64(const char *s, int *ok) {
    char *end = NULL;
    uint64_t v = strtoull(s, &end, 0);
    *ok = (end && *end == '\0');
    return v;
}

int main(int argc, char **argv) {
    const char *cmd = NULL, *out = NULL;
    const char *raw_op = NULL, *raw_args = NULL;
    uint64_t a1 = 0, a2 = 0, a3 = 0, a4 = 0;
    int have1 = 0, have2 = 0, have3 = 0, have4 = 0;

    for (int i = 1; i < argc; i++) {
        if (!strcmp(argv[i], "--timeout-ms") && i + 1 < argc) g_timeout_ms = atoi(argv[++i]);
        else if (!strcmp(argv[i], "--settle-ms") && i + 1 < argc) g_settle_ms = atoi(argv[++i]);
        else if (!strcmp(argv[i], "--out") && i + 1 < argc) out = argv[++i];
        else if (!strcmp(argv[i], "--quiet")) g_quiet = 1;
        else if (!cmd) cmd = argv[i];
        else if (!strcmp(cmd, "raw")) {
            if (!raw_op) raw_op = argv[i];
            else if (!raw_args) raw_args = argv[i];
            else { fail("raw: too many arguments"); return 2; }
        } else {
            int ok = 0;
            uint64_t v = parse_u64(argv[i], &ok);
            if (!ok) { fprintf(stderr, "bad number: %s\n", argv[i]); return 2; }
            if (!have1) { a1 = v; have1 = 1; }
            else if (!have2) { a2 = v; have2 = 1; }
            else if (!have3) { a3 = v; have3 = 1; }
            else { a4 = v; have4 = 1; }
        }
    }
    setvbuf(stdout, NULL, _IOLBF, 0);

    if (!cmd) {
        fprintf(stderr,
            "usage:\n"
            "  %s identify\n"
            "  %s word <addr>                # 0x9B 2-byte read\n"
            "  %s raw <opcode> [arghex]      # 0x35/0x38/0x3A/0x75/0x9B only\n"
            "  %s sweep <0x35|0x38> <sel> <first> <last>   # bounded word sweep\n"
            "  %s read <addr> [--out f]\n"
            "  %s dump <addr> <len> [--out f]\n"
            "  %s selftest\n"
            "options: --timeout-ms N --settle-ms N --quiet\n",
            argv[0], argv[0], argv[0], argv[0], argv[0], argv[0], argv[0]);
        return 2;
    }
    if (!strcmp(cmd, "selftest")) return selftest();

    int needs_addr = !strcmp(cmd, "read") || !strcmp(cmd, "dump") || !strcmp(cmd, "word");
    if (needs_addr && !have1) { fail("missing address"); return 2; }
    if (needs_addr && a1 > 0xFFFFFFFFull) {
        fprintf(stderr,
            "[!] 0x%llX 超出 32 位。0x5C 帧的地址字段是 u32；\n"
            "    S1M2 的 Linux DRAM 在 0x4_0370_0000（34 位），本协议能否寻址需实测——\n"
            "    先用 32 位窗口/别名地址试探，不要试图截断高位。\n", (unsigned long long)a1);
        return 2;
    }

    svc_t svc;
    if (open_service(&svc) != 0) return 1;

    int rc;
    if (!strcmp(cmd, "identify")) rc = cmd_identify(&svc);
    else if (!strcmp(cmd, "word")) rc = cmd_word(&svc, (uint32_t)a1);
    else if (!strcmp(cmd, "raw")) {
        if (!raw_op) { fail("raw needs <opcode> [arghex]"); rc = 2; }
        else rc = cmd_raw(&svc, (uint8_t)strtoul(raw_op, NULL, 0), raw_args);
    }
    else if (!strcmp(cmd, "sweep")) {
        if (!have3 || !have4) { fail("sweep needs <op> <sel> <first> <last>"); rc = 2; }
        else rc = cmd_sweep(&svc, (uint8_t)a1, (uint32_t)a2, (uint32_t)a3, (uint32_t)a4);
    }
    else if (!strcmp(cmd, "read")) rc = cmd_read(&svc, (uint32_t)a1, out);
    else if (!strcmp(cmd, "dump")) {
        if (!have2) { fail("dump needs <addr> <len>"); rc = 2; }
        else rc = cmd_dump(&svc, (uint32_t)a1, (uint32_t)a2, out);
    } else { fail("unknown command"); rc = 2; }

    close_service(&svc);
    return rc == 0 ? 0 : 1;
}
