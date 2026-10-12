#!/usr/bin/env python3
"""Parse S5 camsetting blobs' TLV record stream and analyze fields.

Stream layout (verified): 44-byte header (0x00..0x2b: "Panasonic" + "DC-S5")
+ 8-byte sub-header `cc ff 00 00 00 03 00 00` (0x2c..0x33, identical across
all six blobs) + 831 TLV records (0x34..0xfff7, first is tag 0x0001 = model
identity = 13x u16 0x0049 'I') + 4-byte trailer `ff ff 00 00`
(0xfff8..0xfffb) + 1-byte checksum (0xfffc, the last byte).

Record = [field_id u16 LE][len u16 LE][flag u16 LE][payload: len-6 bytes].
"""
BLOBS = {
    "A": "06_数据与证据/camera_settings/camsetting.bin",
    "B": "01_研究报告/03_隐藏格式_可分发版_20261012/reference/camsetting.bin",
    "C": "01_研究报告/01_固件AES绕过_调研_20261010/03-离线破解与上传预言机/oracle/burst_183125/live_camsetting_full.bin",
    "D": "04_工具与脚本/campaign2/out/diff_blob_mov.bin",
    "E": "04_工具与脚本/campaign2/out/diff_blob_mp4.bin",
    "F": "04_工具与脚本/campaign2/out/blob_postreboot_20261013_000547.bin",
}

START = 0x34  # first record (after 44-byte header + 8-byte sub-header)
TRAILER = 0xfff8
CHECKSUM = 0xfffc


def parse(blob: bytes):
    recs = []
    off = START
    n = len(blob)
    while off + 6 <= TRAILER:
        field_id = int.from_bytes(blob[off:off+2], "little")
        rlen = int.from_bytes(blob[off+2:off+4], "little")
        flag = int.from_bytes(blob[off+4:off+6], "little")
        if rlen < 6 or off + rlen > n:
            raise SystemExit(f"bad record @0x{off:04x} fid=0x{field_id:04x} rlen={rlen}")
        payload = blob[off+6:off+rlen]
        recs.append((off, field_id, rlen, flag, payload))
        off += rlen
    assert off == TRAILER, f"ended 0x{off:04x}, expected 0x{TRAILER:04x}"
    return recs


def main():
    parsed, raw = {}, {}
    for name, path in BLOBS.items():
        with open(path, "rb") as f:
            blob = f.read()
        assert len(blob) == 65533 and sum(blob) % 256 == 0, name
        raw[name] = blob
        parsed[name] = parse(blob)

    # (a) consolidated field dictionary
    print("=== (a) consolidated field dictionary ===")
    fields = {}
    for name, recs in parsed.items():
        for off, fid, rlen, flag, payload in recs:
            d = fields.setdefault(fid, {"n": 0, "lens": set(), "flags": set(),
                                        "payloads": {}, "offs": {}})
            d["n"] += 1
            d["lens"].add(rlen)
            d["flags"].add(flag)
            d["offs"][name] = off
            d["payloads"].setdefault(payload.hex(), []).append(name)

    n_fields = len(fields)
    n_variant = sum(1 for d in fields.values() if len(d["payloads"]) > 1)
    print(f"total distinct field_ids: {n_fields}; fields with >1 payload variant: {n_variant}\n")
    for fid in sorted(fields):
        d = fields[fid]
        const = len(d["payloads"]) == 1
        status = "CONST" if const else f"{len(d['payloads'])} variants"
        print(f"0x{fid:04x} len={sorted(d['lens'])} flag={sorted(d['flags'])} "
              f"blobs={d['n']} [{status}]")
        if not const:
            for ph, names in sorted(d["payloads"].items(), key=lambda kv: kv[1]):
                print(f"      {ph} <- {','.join(names)}")

    # (b) record 0x005e
    print("\n=== (b) record 0x005e (videoformat) payload per blob ===")
    for name, recs in parsed.items():
        for off, fid, rlen, flag, payload in recs:
            if fid == 0x005e:
                print(f"{name}: off=0x{off:04x} len={rlen} flag=0x{flag:04x} "
                      f"payload({len(payload)}B)={payload.hex(' ')}")
                print(f"        bytes[0..13]= {[b for b in payload]}")

    # (c) 0x048f and 0x0495
    print("\n=== (c) records 0x048f / 0x0495 per blob ===")
    for target in (0x048f, 0x0495):
        for name, recs in parsed.items():
            for off, fid, rlen, flag, payload in recs:
                if fid == target:
                    print(f"0x{fid:04x} {name}: off=0x{off:04x} len={rlen} "
                          f"payload({len(payload)}B)={payload.hex(' ')}")

    # (d) 0x0124 videoquality (13 u16 slots, NOT 16 as earlier fieldmap claimed)
    print("\n=== (d) record 0x0124 (videoquality) per blob ===")
    for name, recs in parsed.items():
        for off, fid, rlen, flag, payload in recs:
            if fid == 0x0124:
                vals = [int.from_bytes(payload[i:i+2], "little")
                        for i in range(0, len(payload), 2)]
                print(f"{name}: off=0x{off:04x} len={rlen} ({len(vals)} u16 slots) "
                      f"slots={[hex(v) for v in vals]}")

    # (e) constant container-like byte scan
    print("\n=== (e) constant 0x05/0x06/0x08 bytes across all six blobs ===")
    # map file offset -> (blob, field_id, payload_off)
    offmap = {}
    for name, recs in parsed.items():
        for off, fid, rlen, flag, payload in recs:
            for i in range(off + 6, off + rlen):
                offmap.setdefault(i, (name, fid, i - (off + 6)))

    hits = []
    for i in range(START, CHECKSUM):
        vals = {raw[n][i] for n in raw}
        if len(vals) == 1 and next(iter(vals)) in (0x05, 0x06, 0x08):
            hits.append((i, next(iter(vals))))
    print(f"total constant container-like bytes in payload region: {len(hits)}")
    for i, v in hits:
        owner = offmap.get(i)
        if owner:
            name, fid, poff = owner
            print(f"  0x{fid:04x} payload_off={poff:2d} file_off=0x{i:04x} = 0x{v:02x}")
        else:
            print(f"  <preamble/trailer> file_off=0x{i:04x} = 0x{v:02x}")


if __name__ == "__main__":
    main()
