#!/usr/bin/env python3
"""
common.py — shared networking / health / logging for the S5 second-wave
probe campaign. Pure Python standard library.

The camera is a DC-S5 running a RESEARCH build on the MC801 SoC. cam.cgi is
a query-string CGI:  /cam.cgi?mode=<m>&type=<t>&value=<v>&value2=<v2>
The User-Agent MUST be exactly "LUMIX Sync" or most commands are rejected.

Safety model (hard constraints from the user):
  * READ-ONLY / reversible  -> safe, runs by default (phases A-G)
  * write / upgrade / format / reboot / power  -> RISKY, gated behind --confirm
  * After every probe we run a getstate health guard; if the camera restarts
    we wait for it; if it stays offline we abort.
"""
import json
import os
import socket
import time
import urllib.request
import urllib.error
from xml.etree import ElementTree

UA = {"User-Agent": "LUMIX Sync"}

# generic "rejection" substrings: a probe returning one of these is NOT
# interesting (it just means "unknown parameter"). Everything else is a
# candidate finding worth keeping.
GENERIC_REJECT = (
    "err_param", "err_unsuitable", "err_reject", "err_not_impl",
    "err_not_supported", "err_not_support", "err_no_data", "err_none",
    "err_no_response", "err_busy", "err_timeout", "err_critical",
    "err_unsupported", "err_invalid", "err_notfound", "err_not_found",
    "error", "not_impl", "unsupported", "no_msg",
)


def parse_camrply(body):
    """Parse <camrply> XML into a dict; fall back to CSV-ish split."""
    try:
        root = ElementTree.fromstring(body.decode("utf-8", "replace"))
        d = {}
        for child in root:
            d[child.tag] = (child.text or "").strip()
        return d
    except Exception:
        s = body.decode("utf-8", "replace").strip()
        if not s:
            return {"result": "EMPTY"}
        parts = s.split(",")
        return {"result": parts[0], "_csv": s}


class Net:
    """Thin HTTP client with timing + result parsing against the camera."""

    def __init__(self, ip, port=80, timeout=15, pace=0.35):
        self.ip = ip
        self.port = port
        self.timeout = timeout
        self.pace = pace  # base pacing between probes (s)
        self._last = 0.0

    def _pace(self):
        gap = time.time() - self._last
        if gap < self.pace:
            time.sleep(self.pace - gap)
        self._last = time.time()

    def get(self, path, extra=None, timeout=None):
        """GET -> (status:int|None, headers:dict, body:bytes, elapsed:float)."""
        self._pace()
        url = f"http://{self.ip}:{self.port}{path}"
        headers = dict(UA)
        if extra:
            headers.update(extra)
        req = urllib.request.Request(url, headers=headers)
        t0 = time.time()
        try:
            with urllib.request.urlopen(req, timeout=timeout or self.timeout) as r:
                body = r.read()
                return r.status, dict(r.headers), body, time.time() - t0
        except urllib.error.HTTPError as e:
            body = e.read() if e.fp else b""
            return e.code, dict(e.headers), body, time.time() - t0
        except Exception as e:
            return None, {}, f"EXC {type(e).__name__}: {e}".encode(), time.time() - t0

    def raw(self, method, path, data=None, extra=None, timeout=None,
            content_type=None):
        """Arbitrary method -> (status, headers, body, elapsed). For
        OPTIONS/PUT/DELETE/TRACE/CONNECT and malformed requests."""
        self._pace()
        url = f"http://{self.ip}:{self.port}{path}"
        headers = dict(UA)
        if extra:
            headers.update(extra)
        if content_type:
            headers["Content-Type"] = content_type
        body = data if isinstance(data, (bytes, bytearray)) else (data.encode() if data else None)
        req = urllib.request.Request(url, data=body, method=method, headers=headers)
        t0 = time.time()
        try:
            with urllib.request.urlopen(req, timeout=timeout or self.timeout) as r:
                resp = r.read()
                return r.status, dict(r.headers), resp, time.time() - t0
        except urllib.error.HTTPError as e:
            resp = e.read() if e.fp else b""
            return e.code, dict(e.headers), resp, time.time() - t0
        except Exception as e:
            return None, {}, f"EXC {type(e).__name__}: {e}".encode(), time.time() - t0

    def tcp(self, host, port, timeout=1.0):
        """Raw TCP connect (port probe / raw payload). -> bool open."""
        s = socket.socket()
        s.settimeout(timeout)
        try:
            s.connect((host, port))
            return True
        except Exception:
            return False
        finally:
            s.close()

    def tcp_send(self, host, port, payload, recv=4096, timeout=6.0):
        """Send raw bytes, read reply. -> (open:bool, reply:bytes)."""
        s = socket.socket()
        s.settimeout(timeout)
        try:
            s.connect((host, port))
            try:
                s.sendall(payload)
            except Exception:
                pass
            s.settimeout(timeout)
            try:
                return True, s.recv(recv)
            except Exception:
                return True, b""
        except Exception:
            return False, b""
        finally:
            s.close()


def is_generic(result_str):
    if not result_str:
        return False
    r = result_str.lower()
    return any(g in r for g in GENERIC_REJECT)


class Reporter:
    """Append-only JSONL + human markdown. `report(...)` is the single
    funnel every phase uses, so findings and raw data never get lost."""

    def __init__(self, out_dir):
        os.makedirs(out_dir, exist_ok=True)
        self.md_path = os.path.join(out_dir, "campaign.md")
        self.jsonl_path = os.path.join(out_dir, "campaign.jsonl")
        self.findings = []
        self._md_lines = []

    def _md(self, line):
        self._md_lines.append(line)
        with open(self.md_path, "a") as f:
            f.write(line + "\n")
        print(line, flush=True)

    def _jl(self, rec):
        with open(self.jsonl_path, "a") as f:
            f.write(json.dumps(rec, ensure_ascii=False) + "\n")

    def header(self, phase, note=""):
        ts = time.strftime("%Y-%m-%d %H:%M:%S")
        self._md(f"\n## Phase {phase} @ {ts}  {note}".rstrip())
        self._jl({"phase": phase, "type": "header", "ts": time.time(), "note": note})

    def log(self, phase, op, resp, elapsed, extra=None, verdict=None, finding=None):
        """Record one probe. `resp` is a parse_camrply dict or a string.
        `finding`: if set, this probe is a FINDING (kept + surfaced)."""
        if isinstance(resp, dict):
            res = resp.get("result", "")
            full = json.dumps(resp, ensure_ascii=False)
        else:
            res = resp
            full = str(resp)
        rec = {"phase": phase, "op": op, "result": res, "elapsed": round(elapsed, 3),
               "ts": time.time()}
        if extra:
            rec.update(extra)
        if verdict:
            rec["verdict"] = verdict
        if finding:
            rec["finding"] = finding
        self._jl(rec)
        # markdown: compact line
        line = f"- [{phase}] {op} -> `{res}` ({elapsed:.2f}s)"
        if verdict:
            line += f"  [{verdict}]"
        if finding:
            line += f"  **<== {finding}**"
        self._md(line)
        if finding:
            self.findings.append({"phase": phase, "op": op, "finding": finding,
                                  "result": res, "elapsed": round(elapsed, 3)})
        return res


class Health:
    """getstate-based health guard. Handles 'camera rebooting' (wait) and
    'camera offline' (abort)."""

    def __init__(self, net, rep, wait_reboot=180, offline_abort=True):
        self.net = net
        self.rep = rep
        self.wait_reboot = wait_reboot
        self.offline_abort = offline_abort
        self.dead = False

    def getstate(self):
        st, hd, body, dt = self.net.get("/cam.cgi?mode=getstate", timeout=10)
        d = parse_camrply(body)
        return d.get("result", "") if isinstance(d, dict) else str(d)

    def ok(self, tag=""):
        """True if camera currently returns ok. Prints a health line."""
        try:
            r = self.getstate()
        except Exception as e:
            self.rep._md(f"  [health{tag}] EXC {e}")
            return False
        good = (r.lower() == "ok")
        self.rep._md(f"  [health{tag}] getstate={r}")
        return good

    def guard(self, phase, tag=""):
        """Call after each (or batch of) probes. Returns True to continue.
        If the camera is not ok, wait up to wait_reboot for it to come back
        (it may have rebooted). If it never comes back, mark dead + abort."""
        if self.ok(tag):
            return True
        # not ok -> may be rebooting. wait.
        self.rep._md(f"  [health{tag}] getstate not ok; waiting up to {self.wait_reboot}s "
                     f"for the camera to come back...")
        self.rep._jl({"phase": phase, "type": "health_wait", "tag": tag, "ts": time.time()})
        deadline = time.time() + self.wait_reboot
        while time.time() < deadline:
            time.sleep(15)
            try:
                r = self.getstate()
                self.rep._md(f"  [health{tag}] retry getstate={r}")
                if r.lower() == "ok":
                    self.rep._md(f"  [health{tag}] camera back after reboot; continuing")
                    return True
            except Exception:
                pass
        self.dead = True
        self.rep._md(f"  [health{tag}] !! camera did NOT come back within {self.wait_reboot}s; "
                     f"ABORTING campaign.")
        self.rep._jl({"phase": phase, "type": "health_abort", "tag": tag, "ts": time.time()})
        return False


class KA:
    """Persistent HTTP/1.1 keep-alive client to the camera.

    Reuses ONE TCP connection across many request/response cycles to avoid the
    per-request TCP handshake that dominates upload time (a fresh-connection
    request was ~250ms; a keep-alive request is ~15ms). The camera holds the
    connection open (it sends no explicit Connection header, so HTTP/1.1
    defaults to keep-alive). Reconnects automatically on connection failure.

    No request pipelining: strictly one request, then read its full response,
    then the next. This matches the app's request/response cadence.
    """
    def __init__(self, host, port=80, timeout=15):
        self.host = host
        self.port = port
        self.timeout = timeout
        self.sock = None
        self.buf = b""
        self.conn_errors = 0  # count of connection-level failures (diagnostic)

    def _connect(self):
        self.close()
        s = socket.create_connection((self.host, self.port), timeout=self.timeout)
        try:
            s.setsockopt(socket.IPPROTO_TCP, socket.TCP_NODELAY, 1)
        except Exception:
            pass
        s.settimeout(self.timeout)
        self.sock = s
        self.buf = b""

    def close(self):
        if self.sock is not None:
            try:
                self.sock.close()
            except Exception:
                pass
            self.sock = None
        self.buf = b""

    def _recv(self, n):
        """Read exactly n bytes; reconnect once if the connection drops."""
        while len(self.buf) < n:
            if self.sock is None:
                self._connect()
            try:
                c = self.sock.recv(65536)
            except Exception:
                self.conn_errors += 1
                self._connect()
                c = self.sock.recv(65536)
            if not c:
                self.close()
                continue
            self.buf += c
        out, self.buf = self.buf[:n], self.buf[n:]
        return out

    def _recv_until(self, delim):
        while delim not in self.buf:
            if self.sock is None:
                self._connect()
            try:
                c = self.sock.recv(65536)
            except Exception:
                self.conn_errors += 1
                self._connect()
                c = self.sock.recv(65536)
            if not c:
                self.close()
                continue
            self.buf += c
        i = self.buf.index(delim) + len(delim)
        out, self.buf = self.buf[:i], self.buf[i:]
        return out

    def _send(self, data):
        if self.sock is None:
            self._connect()
        try:
            self.sock.sendall(data)
        except Exception:
            self.conn_errors += 1
            self._connect()
            self.sock.sendall(data)

    def request(self, method, path, headers=None, body=None):
        """One request/response cycle on the persistent connection.
        -> (status:int|None, headers:dict, body:bytes, elapsed:float)."""
        h = dict(headers or {})
        h.setdefault("User-Agent", "LUMIX Sync")
        h.setdefault("Connection", "Keep-Alive")
        if body is not None:
            h.setdefault("Content-Length", str(len(body)))
        lines = ["%s %s HTTP/1.1" % (method, path), "Host: %s" % self.host]
        lines += ["%s: %s" % (k, v) for k, v in h.items()]
        req = ("\r\n".join(lines) + "\r\n\r\n").encode()
        if body is not None:
            req += body
        t0 = time.time()
        for attempt in range(2):
            try:
                self._send(req)
                status, hdrs, rbody = self._read_response()
                return status, hdrs, rbody, time.time() - t0
            except Exception as e:
                self.close()
                if attempt == 1:
                    return None, {}, ("%s: %s" % (type(e).__name__, e)).encode(), time.time() - t0
                # attempt 0: connection was reset; close() already done, reconnect
                # on the next _send and retry the full request.
        return None, {}, b"", time.time() - t0

    def _read_response(self):
        """Read one full HTTP response from the persistent connection.
        -> (status:int, headers:dict, body:bytes)."""
        head = self._recv_until(b"\r\n\r\n")
        hlines = head.split(b"\r\n")
        status = int(hlines[0].split(b" ", 2)[1])
        hdrs = {}
        for line in hlines[1:]:
            if b":" in line:
                k, v = line.split(b":", 1)
                hdrs[k.strip().decode("latin1")] = v.strip().decode("latin1")
        cl = int(hdrs.get("Content-Length", "0") or "0")
        rbody = self._recv(cl) if cl > 0 else b""
        if hdrs.get("Connection", "").lower() == "close":
            self.close()
        return status, hdrs, rbody

    def send(self, req):
        """Send a FULLY-BUILT request (request-line + headers + body, as one
        bytes object) and read the response. This is the fastest path for the
        upload loop: the caller pre-builds everything except the per-chunk data
        bytes, so the only per-chunk work is `prefix + chunk + trailer`.
        -> (status:int|None, headers:dict, body:bytes, elapsed:float)."""
        t0 = time.time()
        for attempt in range(2):
            try:
                self._send(req)
                status, hdrs, rbody = self._read_response()
                return status, hdrs, rbody, time.time() - t0
            except Exception as e:
                self.close()
                if attempt == 1:
                    return None, {}, ("%s: %s" % (type(e).__name__, e)).encode(), time.time() - t0
        return None, {}, b"", time.time() - t0
