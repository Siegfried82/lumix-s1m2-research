#!/usr/bin/env python3
"""Persistent-connection gate probe: poll req_acc until real 'ok' (with session
token), then test fw_update_mode with the X-SESSION_ID header. Read-only except
for req_acc (which we then cancel). No firmware is written."""
import http.client, random, time, urllib.parse, sys

IP = sys.argv[1] if len(sys.argv) > 1 else "192.168.1.131"
UA = "LUMIX Sync"


def conn():
    return http.client.HTTPConnection(IP, 80, timeout=8)


def req(c, path, headers=None):
    h = {"User-Agent": UA}
    if headers:
        h.update(headers)
    c.request("GET", path, headers=h)
    r = c.getresponse()
    body = r.read().decode("utf-8", "replace")
    return r.status, body


def getstate(c):
    _, body = req(c, "/cam.cgi?mode=getstate")
    return body


def main():
    uuid = "4D454930-0100-1000-8001-%012x" % random.getrandbits(48)
    print("UUID:", uuid)

    # reset any pending request first
    c0 = conn()
    try:
        print("req_acc_can ->", req(c0, "/cam.cgi?mode=accctrl&type=req_acc_can")[1])
    except Exception as e:
        print("req_acc_can err", e)
    c0.close()
    time.sleep(2)

    # fresh persistent connection for the whole handshake
    c = conn()
    token = None
    accepted = False
    for i in range(1, 40):
        try:
            status, body = req(c, "/cam.cgi?" + urllib.parse.urlencode(
                {"mode": "accctrl", "type": "req_acc", "value": uuid, "value2": "LUMIX Sync"}))
        except Exception as e:
            print("[%d] EXC %s (reconnect)" % (i, e))
            c.close(); c = conn(); time.sleep(1.5); continue
        print("[%d] req_acc -> %r" % (i, body.strip()))
        parts = [p.strip() for p in body.split(",")]
        res = parts[0].lower() if parts else ""
        if res == "ok":
            accepted = True
            if len(parts) >= 5 and parts[4]:
                token = parts[4]
            print("    ACCEPTED. fields=%d token=%r" % (len(parts), token))
            break
        if res == "err_others_requesting":
            c2 = conn(); req(c2, "/cam.cgi?mode=accctrl&type=req_acc_can"); c2.close()
        if res not in ("ok_under_research_no_msg", "err_busy", "err_reject"):
            pass
        time.sleep(1.0)

    print()
    print("=== post-req_acc getstate (same conn) ===")
    print(getstate(c))

    print()
    print("=== fw_update_mode sweep (same conn, with X-SESSION_ID if token) ===")
    hdrs = {"X-SESSION_ID": token} if token else None
    for v in ("V2.80", "V2.90", "V3.00", "V9.99"):
        try:
            status, body = req(c, "/cam.cgi?" + urllib.parse.urlencode(
                {"mode": "camctrl", "type": "fw_update_mode", "value": v}), hdrs)
            print("  fw_update_mode(%s) -> %r" % (v, body.strip()))
        except Exception as e:
            print("  fw_update_mode(%s) EXC %s" % (v, e))
        time.sleep(0.5)
    c.close()

    print()
    print("=== control: fresh conn, NO token, fw_update_mode(V3.00) ===")
    c3 = conn()
    try:
        print("  ->", req(c3, "/cam.cgi?" + urllib.parse.urlencode(
            {"mode": "camctrl", "type": "fw_update_mode", "value": "V3.00"}))[1].strip())
    except Exception as e:
        print("  EXC", e)
    c3.close()


if __name__ == "__main__":
    main()
