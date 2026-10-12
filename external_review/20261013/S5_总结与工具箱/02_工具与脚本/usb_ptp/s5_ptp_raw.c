/*
 * s5_ptp_raw.c — DC-S5 raw USB PTP client (bypasses ImageCaptureCore).
 *
 * Why: on this Mac the S5 in "PC(Tether)" mode enumerates as
 *   VID 0x04DA / PID 0x2370, interface class 0xFF/0xA0/0xB0 (vendor specific).
 *   macOS's icdd does not match that PID, so ImageCaptureCore (and therefore
 *   ./s5_ptp_dump) never gets a camera object and times out.
 * This tool talks to the PTP bulk endpoints directly through IOUSBLib, so it
 * does not depend on the host camera database at all.
 *
 * READ-ONLY by construction. It only ever sends:
 *   0x1001 GetDeviceInfo, 0x1002 OpenSession, 0x1004 GetStorageIDs,
 *   0x9104 GetSyncList, 0x9421 (Get_SetupFilesConfigSet_Info, tag),
 *   0x9605 Get_Event_Info, 0x1003 CloseSession.
 * It never sends 0x9406 / 0x9422 / 0x9423 / 0x940d / format / upgrade / reset.
 * Container lengths are computed exactly (a wrong length hangs the PTP data
 * plane until USB replug on this camera).
 *
 * Build:  clang -framework IOKit -framework CoreFoundation -o s5_ptp_raw s5_ptp_raw.c
 * Usage:  ./s5_ptp_raw <outdir> [vid] [pid]        (defaults 0x04da 0x2370)
 *         ./s5_ptp_raw --list
 */
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <sys/stat.h>
#include <IOKit/IOKitLib.h>
#include <IOKit/IOCFPlugIn.h>
#include <IOKit/usb/IOUSBLib.h>
#include <IOKit/usb/USBSpec.h>
#include <CoreFoundation/CoreFoundation.h>

#define DEFAULT_VID 0x04DA
#define DEFAULT_PID 0x2370
#define RDBUF (1024 * 1024)

static IOUSBDeviceInterface **g_dev = NULL;
static IOUSBInterfaceInterface **g_intf = NULL;
static UInt8 g_pipe_out = 0, g_pipe_in = 0, g_pipe_int = 0;
static UInt32 g_tid = 0;
static UInt8 g_pipe_int_candidate = 0;

static UInt32 u32le(const unsigned char *p) {
    return (UInt32)p[0] | ((UInt32)p[1] << 8) | ((UInt32)p[2] << 16) | ((UInt32)p[3] << 24);
}
static UInt16 u16le(const unsigned char *p) { return (UInt16)(p[0] | (p[1] << 8)); }

static int open_device(UInt32 vid, UInt32 pid) {
    CFMutableDictionaryRef match = IOServiceMatching(kIOUSBDeviceClassName);
    if (!match) { fprintf(stderr, "IOServiceMatching failed\n"); return -1; }
    CFNumberRef nv = CFNumberCreate(kCFAllocatorDefault, kCFNumberSInt32Type, &vid);
    CFNumberRef np = CFNumberCreate(kCFAllocatorDefault, kCFNumberSInt32Type, &pid);
    CFDictionarySetValue(match, CFSTR(kUSBVendorID), nv);
    CFDictionarySetValue(match, CFSTR(kUSBProductID), np);
    CFRelease(nv); CFRelease(np);

    io_service_t svc = IOServiceGetMatchingService(kIOMainPortDefault, match);
    if (!svc) { fprintf(stderr, "device %04x:%04x not found\n", vid, pid); return -1; }

    IOCFPlugInInterface **plug = NULL;
    SInt32 score = 0;
    kern_return_t kr = IOCreatePlugInInterfaceForService(svc, kIOUSBDeviceUserClientTypeID,
                                                         kIOCFPlugInInterfaceID, &plug, &score);
    IOObjectRelease(svc);
    if (kr != KERN_SUCCESS || !plug) { fprintf(stderr, "IOCreatePlugInInterfaceForService(dev) failed\n"); return -1; }

    HRESULT hr = (*plug)->QueryInterface(plug, CFUUIDGetUUIDBytes(kIOUSBDeviceInterfaceID),
                                          (LPVOID *)&g_dev);
    (*plug)->Release(plug);
    if (hr || !g_dev) { fprintf(stderr, "QueryInterface(IOUSBDeviceInterface) failed\n"); return -1; }

    IOReturn r = (*g_dev)->USBDeviceOpen(g_dev);
    if (r) {
        fprintf(stderr, "USBDeviceOpen failed: 0x%08x (trying seize)\n", r);
        r = (*g_dev)->USBDeviceOpenSeize(g_dev);
        if (r) { fprintf(stderr, "USBDeviceOpenSeize failed: 0x%08x\n", r); return -1; }
    }
    printf("[1] device opened (%04x:%04x)\n", vid, pid);

    /* pick a configuration that has a bulk-in + bulk-out pair with 3 endpoints */
    UInt8 ncfg = 0;
    (*g_dev)->GetNumberOfConfigurations(g_dev, &ncfg);
    printf("    configurations: %d\n", ncfg);
    for (UInt8 cfg = 1; cfg <= ncfg; cfg++) {
        IOUSBConfigurationDescriptorPtr cd = NULL;
        if ((*g_dev)->GetConfigurationDescriptorPtr(g_dev, cfg, &cd)) continue;
        if (cd->bNumInterfaces < 1) continue;
        if ((*g_dev)->SetConfiguration(g_dev, cfg)) continue;
        printf("    using configuration %d (bNumInterfaces=%d)\n", cfg, cd->bNumInterfaces);
        break;
    }

    IOUSBFindInterfaceRequest req;
    req.bInterfaceClass = kIOUSBFindInterfaceDontCare;
    req.bInterfaceSubClass = kIOUSBFindInterfaceDontCare;
    req.bInterfaceProtocol = kIOUSBFindInterfaceDontCare;
    req.bAlternateSetting = kIOUSBFindInterfaceDontCare;
    io_iterator_t it = 0;
    if ((*g_dev)->CreateInterfaceIterator(g_dev, &req, &it)) {
        fprintf(stderr, "CreateInterfaceIterator failed\n"); return -1;
    }
    io_service_t ifsvc = 0;
    int found = 0;
    while ((ifsvc = IOIteratorNext(it))) {
        IOCFPlugInInterface **ip = NULL; SInt32 sc = 0;
        if (IOCreatePlugInInterfaceForService(ifsvc, kIOUSBInterfaceUserClientTypeID,
                                              kIOCFPlugInInterfaceID, &ip, &sc) || !ip) {
            IOObjectRelease(ifsvc); continue;
        }
        IOUSBInterfaceInterface **intf = NULL;
        (*ip)->QueryInterface(ip, CFUUIDGetUUIDBytes(kIOUSBInterfaceInterfaceID), (LPVOID *)&intf);
        (*ip)->Release(ip);
        if (!intf) { IOObjectRelease(ifsvc); continue; }

        IOReturn r2 = (*intf)->USBInterfaceOpen(intf);
        printf("    interface open -> 0x%08x\n", r2);
        { IOUSBInterfaceInterface190 **i190 = (IOUSBInterfaceInterface190 **)intf;
          IOReturn rs = (*i190)->USBInterfaceOpenSeize(i190);
          printf("    interface seize -> 0x%08x\n", rs); }
        if (r2) {
            printf("    interface open failed: 0x%08x (skipping)\n", r2);
            (*intf)->Release(intf); IOObjectRelease(ifsvc); continue;
        }
        UInt8 n = 0;
        (*intf)->GetNumEndpoints(intf, &n);
        UInt8 pout = 0, pin = 0;
        for (UInt8 i = 1; i <= n; i++) {
            UInt8 dir = 0, num = 0, tt = 0; UInt16 mps = 0; UInt8 iv = 0;
            if ((*intf)->GetPipeProperties(intf, i, &dir, &num, &tt, &mps, &iv)) continue;
            if (tt != kUSBBulk) continue;
            if (dir == kUSBOut) pout = i;
            if (dir == kUSBIn) { if (tt == kUSBInterrupt) g_pipe_int_candidate = i; pin = i; }
        }
        printf("    interface: endpoints=%d bulkIn=%d bulkOut=%d\n", n, pin, pout);
        if (pin && pout) {
            g_intf = intf; g_pipe_in = pin; g_pipe_out = pout;
            (*intf)->ClearPipeStallBothEnds(intf, pin);
            (*intf)->ClearPipeStallBothEnds(intf, pout);
            { UInt8 d0,n0,t0; UInt16 m0; UInt8 i0;
              (*intf)->GetPipeProperties(intf, pin, &d0,&n0,&t0,&m0,&i0);
              printf("    bulk IN  ep=0x%02x mps=%u\n", n0 | 0x80, m0);
              (*intf)->GetPipeProperties(intf, pout, &d0,&n0,&t0,&m0,&i0);
              printf("    bulk OUT ep=0x%02x mps=%u\n", n0, m0); }
            (*intf)->ClearPipeStallBothEnds(intf, pout);
            IOObjectRelease(ifsvc);
            found = 1; break;
        }
        (*intf)->USBInterfaceClose(intf);
        (*intf)->Release(intf);
        IOObjectRelease(ifsvc);
    }
    IOObjectRelease(it);
    if (!found) { fprintf(stderr, "no usable bulk interface found\n"); return -1; }
    g_pipe_int = g_pipe_int_candidate;
    printf("[2] PTP bulk pipe ready (interrupt pipe ref=%u)\n", g_pipe_int);
    /* drain diagnostics: read any IN pipe for a moment before speaking */
    unsigned char *rb = malloc(65536);
    for (int pass = 0; pass < 2; pass++) {
        UInt8 pr = pass == 0 ? g_pipe_int : g_pipe_in;
        if (!pr) continue;
        for (int k = 0; k < 2; k++) {
            UInt32 sz = 65536; IOReturn rr = (*g_intf)->ReadPipeTO(g_intf, pr, rb, &sz, 0, 1500);
            printf("    [diag] %s read -> 0x%08x size=%u%s\n",
                   pass == 0 ? "INT " : "BULK", rr, sz, (rr == 0 && sz) ? "  <<< DATA" : "");
            if (rr == 0 && sz) { for (UInt32 i = 0; i < sz && i < 32; i++) printf("%02x ", rb[i]); printf("\n"); }
            if (rr) break;
        }
    }
    free(rb);
    return 0;
}

/* read one complete container (collect short reads until len matches) */
static int read_container(unsigned char *buf, size_t cap, size_t *got, int timeout_ms) {
    size_t have = 0;
    while (1) {
        if (have >= 12) {
            UInt32 need = u32le(buf);
            if (need >= 12 && have >= need) { *got = have; return 0; }
        }
        UInt32 size = (UInt32)(cap - have);
        IOReturn r = (*g_intf)->ReadPipeTO(g_intf, g_pipe_in, buf + have, &size, 0, timeout_ms);
        if (r) return (int)r;
        if (size == 0) continue;
        have += size;
    }
}

/* send command, collect optional data container + response container */
static int ptp(uint16_t op, const UInt32 *params, int nparams, const char *name,
               unsigned char **data_out, size_t *data_len, uint16_t *rcode,
               const char *outdir) {
    unsigned char cmd[12 + 4 * 8];
    UInt32 len = 12 + 4 * (UInt32)nparams;
    static int alt_done = 0;
    if (!alt_done) {
        alt_done = 1;
        UInt8 cur = 0; (*g_intf)->GetAlternateSetting(g_intf, &cur);
        IOReturn ra = (*g_intf)->SetAlternateInterface(g_intf, 0);
        printf("    alt setting: cur=%u set(0)->0x%08x (bulk pipe armed)\n", cur, ra);
        usleep(200000);
    }
    IOReturn r = (IOReturn)-1;
    for (int attempt = 0; attempt < 3; attempt++) {
        r = (*g_intf)->WritePipeTO(g_intf, g_pipe_out, cmd, len, 0, 3000);
        if (!r) break;
        printf("    [%s] write attempt %d -> 0x%08x (clearing stall)\n", name, attempt + 1, r);
        (*g_intf)->ClearPipeStallBothEnds(g_intf, g_pipe_out);
        (*g_intf)->ClearPipeStallBothEnds(g_intf, g_pipe_in);
        usleep(300000);
    }
    if (r) { printf("    [%s] write failed 0x%08x\n", name, r); return -1; }

    static unsigned char *buf = NULL;
    if (!buf) buf = malloc(RDBUF);
    unsigned char *data = NULL; size_t dlen = 0; uint16_t rc = 0; int have_resp = 0;

    for (int i = 0; i < 4; i++) {
        size_t got = 0;
        int rr = read_container(buf, RDBUF, &got, 15000);
        if (rr) { printf("    [%s] read %d (got %zu)\n", name, rr, got); break; }
        uint16_t type = u16le(buf + 4), code = u16le(buf + 6);
        if (type == 2) {
            data = malloc(got); memcpy(data, buf, got); dlen = got;
            printf("    [%s] data container %zu B\n", name, got);
        } else if (type == 3) {
            rc = code; have_resp = 1;
            printf("    [%s] response 0x%04x (%zu B)\n", name, code, got);
            if (outdir) {
                char p[1024];
                snprintf(p, sizeof p, "%s/%s.resp.bin", outdir, name);
                FILE *f = fopen(p, "wb"); if (f) { fwrite(buf, 1, got, f); fclose(f); }
            }
            break;
        } else {
            printf("    [%s] unexpected container type %u\n", name, type);
        }
    }
    *rcode = rc;
    if (data_out) { *data_out = data; *data_len = dlen; }
    else free(data);
    return have_resp ? 0 : -1;
}

static void close_all(void) {
    if (g_intf) { (*g_intf)->USBInterfaceClose(g_intf); (*g_intf)->Release(g_intf); g_intf = NULL; }
    if (g_dev)  { (*g_dev)->USBDeviceClose(g_dev); (*g_dev)->Release(g_dev); g_dev = NULL; }
}

int main(int argc, char **argv) {
    if (argc >= 2 && strcmp(argv[1], "--list") == 0) {
        CFMutableDictionaryRef m = IOServiceMatching(kIOUSBDeviceClassName);
        io_iterator_t it = 0;
        if (IOServiceGetMatchingServices(kIOMainPortDefault, m, &it) == KERN_SUCCESS) {
            io_service_t s;
            while ((s = IOIteratorNext(it))) {
                UInt32 v = 0, p = 0;
                CFTypeRef rv = IORegistryEntryCreateCFProperty(s, CFSTR("idVendor"), kCFAllocatorDefault, 0);
                CFTypeRef rp = IORegistryEntryCreateCFProperty(s, CFSTR("idProduct"), kCFAllocatorDefault, 0);
                if (rv) { CFNumberGetValue(rv, kCFNumberSInt32Type, &v); CFRelease(rv); }
                if (rp) { CFNumberGetValue(rp, kCFNumberSInt32Type, &p); CFRelease(rp); }
                printf("  USB device %04x:%04x\n", v, p);
                IOObjectRelease(s);
            }
            IOObjectRelease(it);
        }
        return 0;
    }

    const char *outdir = (argc >= 2) ? argv[1] : "ptp_raw_out";
    UInt32 vid = (argc >= 3) ? (UInt32)strtoul(argv[2], NULL, 0) : DEFAULT_VID;
    UInt32 pid = (argc >= 4) ? (UInt32)strtoul(argv[3], NULL, 0) : DEFAULT_PID;
    mkdir(outdir, 0755);

    printf("== s5_ptp_raw: raw USB PTP (read-only) ==\n");
    if (open_device(vid, pid)) { close_all(); return 1; }

    uint16_t rc;
    unsigned char *data = NULL; size_t dlen = 0;

    ptp(0x1001, NULL, 0, "device_info", &data, &dlen, &rc, outdir);
    if (data && dlen >= 12) {
        char *s = malloc(dlen - 12 + 1); memcpy(s, data + 12, dlen - 12); s[dlen - 12] = 0;
        /* manufacturer(9) + model(9) + version(9) .. just show printable */
        printf("    model field: %.40s\n", s + 8);
        FILE *f = fopen("device_info.bin", "wb");
        if (f) { fwrite(data, 1, dlen, f); fclose(f); }
    }
    free(data); data = NULL;

    UInt32 sid = 1;
    if (ptp(0x1002, &sid, 1, "open_session", &data, &dlen, &rc, outdir)) { printf("!! OpenSession failed\n"); close_all(); return 1; }
    free(data); data = NULL;

    ptp(0x1004, NULL, 0, "storage_ids", &data, &dlen, &rc, outdir); free(data); data = NULL;
    ptp(0x9104, NULL, 0, "sync_list", &data, &dlen, &rc, outdir); free(data); data = NULL;

    UInt32 tags[3] = { 0x080000a2, 0x080000a1, 0x00000000 };
    for (int t = 0; t < 3; t++) {
        char nm[64]; snprintf(nm, sizeof nm, "config_0x9421_tag%08x", tags[t]);
        data = NULL; dlen = 0;
        if (ptp(0x9421, &tags[t], 1, nm, &data, &dlen, &rc, outdir) == 0 && rc == 0x2001 && data && dlen > 12) {
            char p[1024]; snprintf(p, sizeof p, "%s/config_0x9421.bin", outdir);
            FILE *f = fopen(p, "wb"); if (f) { fwrite(data + 12, 1, dlen - 12, f); fclose(f); }
            printf("    >>> saved %s (%zu bytes payload)\n", p, dlen - 12);
            free(data);
            break;
        }
        free(data);
    }

    UInt32 ev = 0x41000013;
    ptp(0x9605, &ev, 1, "fwup_ev_0x41000013", NULL, NULL, &rc, outdir);

    ptp(0x1003, NULL, 0, "close_session", NULL, NULL, &rc, outdir);
    close_all();
    printf("== done ==\n");
    return 0;
}
