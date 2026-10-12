#!/usr/bin/env python3
"""Encrypted-connection handshake probe (this build reports 'encrypted' in the
req_acc CSV). Sequence: req_acc_g -> key; XOR-encode uuid+name; req_acc_e.
Then, if accepted, test fw_update_mode with the session token.
READ-ONLY except the handshake itself (no firmware is written)."""
import http.client, random, time, urllib.parse, sys

IP = sys.argv[1] if len(sys.argv) > 1 else "192.168.1.131"
UA = "LUMIX Sync"
DEFAULT_KEY = -1875740628  # 0x9032782C


def conn():
    return http.client.HTTPConnection(IP, 80, timeout=8)


def req(c, path, headers=None):
    h = {"User-Agent": UA}
    if headers:
        h.update(headers)
    c.request("GET", path, headers=h)
    r = c.getresponse()
    return r.status, r.read().decode("utf-8", "replace")


def xor_obfuscate(s, key):
    if key == 0:
        key = DEFAULT_KEY
    chars = list(s)
    while len(chars) % 4 != 0:
        chars.append("\u00ff")
    out = []
    for i in range(0, len(chars), 4):
        c0, c1, c2, c3 = (ord(ch) for ch in chars[i:i + 4])
        j7 = (c0 << 24) | (c1 << 16) | (c2 << 8) | c3
        j8 = key if key >= 0 else key + 4294967296
        j9 = j7 ^ j8
        swapped = ((j9 >> 24) & 0xFF) | ((j9 << 24) & 0xFF000000) | ((j9 << 8) & 0xFF0000) | ((j9 >> 8) & 0xFF00)
        out.append("%08x" % swapped)
    return "".join(out)


def getstate(c):
    _, body = req(c, "/cam.cgi?mode=getstate")
    return body


def main():
    uuid = "4D454930-0100-1000-8001-%012x" % random.getrandbits(48)
    name = "LUMIX Sync"
    print("UUID:", uuid)

    c = conn()
    # Step 1: req_acc_g -> key
    print("=== req_acc_g (get key) ===")
    try:
        status, body = req(c, "/cam.cgi?mode=accctrl&type=req_acc_g")
    except Exception as e:
        print("  EXC", e); c.close()
        c = conn()
    print("  req_acc_g -> %r" % body.strip())
    key = 0
    parts = [p.strip() for p in body.split(",")]
    if len(parts) >= 2:
        try:
            key = int(parts[1], 16)
        except Exception:
            key = 0
    print("  key = 0x%08x" % (key & 0xFFFFFFFF))

    # Step 2: encode
    ev = xor_obfuscate(uuid, key)
    ev2 = xor_obfuscate(name, key)
    print("  encoded value  =", ev)
    print("  encoded value2 =", ev2)

    # Step 3: req_acc_e
    print("=== req_acc_e (poll to ok) ===")
    token = None
    accepted = False
    for i in range(1, 25):
        try:
            status, body = req(c, "/cam.cgi?" + urllib.parse.urlencode(
                {"mode": "accctrl", "type": "req_acc_e", "value": ev, "value2": ev2}))
        except Exception as e:
            print("[%d] EXC %s (reconnect)" % (i, e)); c.close(); c = conn(); time.sleep(1.5); continue
        print("[%d] req_acc_e -> %r" % (i, body.strip()))
        p2 = [p.strip() for p in body.split(",")]
        res = p2[0].lower() if p2 else ""
        if res == "ok":
            accepted = True
            if len(p2) >= 5 and p2[4]:
                token = p2[4]
            print("    ACCEPTED. fields=%d token=%r" % (len(p2), token))
            break
        time.sleep(1.0)

    print()
    print("=== post-accept getstate (same conn) ===")
    print(getstate(c))

    print()
    print("=== fw_update_mode sweep (with X-SESSION_ID if token) ===")
    hdrs = {"X-SESSION_ID": token} if token else None
    for v in ("V2.90", "V3.00", "V9.99"):
        try:
            status, body = req(c, "/cam.cgi?" + urllib.parse.urlencode(
                {"mode": "camctrl", "type": "fw_update_mode", "value": v}), hdrs)
            print("  fw_update_mode(%s) -> %r" % (v, body.strip()))
        except Exception as e:
            print("  fw_update_mode(%s) EXC %s" % (v, e))
        time.sleep(0.5)
    c.close()
    print("done. accepted=%s token=%r" % (accepted, token))


if __name__ == "__main__":
    main()
