> **Codex核验评论（2026-10-13）**：以下正文是外部作者材料的公开副本。收录不等于证实；作者说法与本项目核验分开。原稿 SHA-256：`8a05ac1832bfe9287672453225660258eadd7bc22df5519b0c426f1b93c03876`。原稿行号仍按未注释原件计算。
> 参见[该包纠错总评](../../../CODEX_REVIEW.md)；未在本轮执行其脚本、设备请求或录像实验。

# S5 `camsetting` blob field-map — container-field hunt

Analysis date: 2026-10-12. Pure offline diff of six 65533-byte `camsetting` blobs
already in the repo. No camera contact.

## Input blobs

| # | State | Path |
|---|---|---|
| A | pal + mp4 + videoquality `0xc1` | `06_数据与证据/camera_settings/camsetting.bin` |
| B | reference copy (hidden-format report) | `01_研究报告/03_隐藏格式_可分发版_20261012/reference/camsetting.bin` |
| C | live full (burst/photo state) | `01_研究报告/01_固件AES绕过_调研_20261010/03-离线破解与上传预言机/oracle/burst_183125/live_camsetting_full.bin` |
| D | ntsc + **mov** + `0x8b` | `04_工具与脚本/campaign2/out/diff_blob_mov.bin` |
| E | ntsc + mp4 + `0x8b` | `04_工具与脚本/campaign2/out/diff_blob_mp4.bin` |
| F | post-reboot (ntsc + mp4 + `0x8b`) | `04_工具与脚本/campaign2/out/blob_postreboot_20261013_000547.bin` |

All six are exactly 65533 bytes and satisfy `sum(blob) % 256 == 0`.

## (a) Header vs payload boundary

The header is **44 bytes (0x2C)** and is byte-identical across all six blobs:

```
offset  0x00: 50 61 6e 61 73 6f 6e 69 63   "Panasonic"   (9 bytes)
        0x09: 00 00 00 00 00 00 00 00 00   9 × 0x00
        0x12: 44 43 2d 53 35                  "DC-S5"      (5 bytes)
        0x17: 00 … 00                        21 × 0x00
        0x2c: cc ff 00 00 00 03 00 00 01 00 20 00 01 00 …   ← payload begins
```

- `"DC-S5"` sits at offset `0x12` (decimal 18), ends at `0x17`.
- The first non-zero payload byte is `0xcc` at offset **`0x2C` (decimal 44)**.
- Header layout: `"Panasonic"` + 9 NULs + `"DC-S5"` + 21 NULs. Payload = everything from `0x2C` onward.

The payload itself begins with `cc ff 00 00 00 03 00 00 01 00 20 00 …`, i.e. it is a
tagged/TLV stream of setting records (see record structure below).

## Record structure (context for step 4)

Every setting is a self-describing record:

```
[ field_id: u16 LE ][ len: u16 LE ][ flag: u16 LE ][ payload: (len-6) bytes ]
```

`len` is the **total record size including the 6-byte header**. The three known
fields live inside such records:

| Field | Record offset | field_id | len | flag | payload | active value |
|---|---|---|---|---|---|---|
| videoformat | `0x0bee` (3054) | `0x005e` | `0x14`=20 | `0x0001` | 14 B | byte `3062` |
| videoquality | `0x1b44` (6980) | `0x0124` | `0x20`=32 | `0x0001` | 32 B = 16×u16 | u16 @ `6986` |
| ntsc_pal | `0xfec8` (65224) | `0x0495` | `0x14`=20 | `0x0001` | 14 B | byte `65230` |

Note the two byte-valued fields (`0x005e` videoformat and `0x0495` ntsc_pal, and a
third `0x048f` @ 65104, see below) all use a **13-byte value run + 1 NUL terminator**
payload, where only **byte[0]** carries the active value and bytes[1..12] stay fixed.
`videoquality` instead uses a **16-entry u16 array** where slot 0 holds the selected
code and slots 1..15 hold `0x00c0` (disabled/not-applicable sentinel).

## (b) Complete differing-offset table

Among the five campaign blobs (A/B/D/E/F) there are exactly **52** offsets that ever
differ. Blob **B == A** and blob **F == E** byte-for-byte (0 diffs each), so the two
pairs collapse. The `0xc1↔0x8b` quality switch accounts for ~48 of these; the
`pal↔ntsc` switch for 2; the `mov↔mp4` switch for exactly **1** (plus the checksum).

### Full 52-offset table (A/B pal+mp4+0xc1 · D mov+0x8b · E/F mp4+0x8b)

| off | hex | A | B | D | E | F |
|---|---|---|---|---|---|---|
| 3062 | 0x0bf6 | 05 | 05 | **06** | 05 | 05 |
| 3202 | 0x0c82 | 00 | 00 | 01 | 01 | 01 |
| 3302 | 0x0ce6 | 00 | 00 | 01 | 01 | 01 |
| 3402 | 0x0d4a | 00 | 00 | 01 | 01 | 01 |
| 4062 | 0x0fde | 00 | 00 | 01 | 01 | 01 |
| 4182 | 0x1056 | 00 | 00 | 01 | 01 | 01 |
| 5122 | 0x1402 | 00 | 00 | 01 | 01 | 01 |
| 5282 | 0x14a2 | e6 | e6 | 4b | 4b | 4b |
| 5314 | 0x14c2 | ad | ad | 3f | 3f | 3f |
| 5410 | 0x1522 | 21 | 21 | c8 | c8 | c8 |
| 5411 | 0x1523 | 05 | 05 | f9 | f9 | f9 |
| 5442 | 0x1542 | e8 | e8 | ce | ce | ce |
| 5443 | 0x1543 | 03 | 03 | fb | fb | fb |
| 5506 | 0x1582 | 21 | 21 | c8 | c8 | c8 |
| 5507 | 0x1583 | 05 | 05 | f9 | f9 | f9 |
| 5538 | 0x15a2 | e8 | e8 | ce | ce | ce |
| 5539 | 0x15a3 | 03 | 03 | fb | fb | fb |
| 5602 | 0x15e2 | 21 | 21 | c8 | c8 | c8 |
| 5603 | 0x15e3 | 05 | 05 | f9 | f9 | f9 |
| 5634 | 0x1602 | e8 | e8 | ce | ce | ce |
| 5635 | 0x1603 | 03 | 03 | fb | fb | fb |
| 5762 | 0x1682 | 8e | 8e | 01 | 01 | 01 |
| 5794 | 0x16a2 | 39 | 39 | 6d | 6d | 6d |
| 5914 | 0x171a | 20 | 20 | 73 | 73 | 73 |
| 5926 | 0x1726 | 4f | 4f | cf | cf | cf |
| 5928 | 0x1728 | 4f | 4f | c3 | c3 | c3 |
| 5930 | 0x172a | 4f | 4f | 1d | 1d | 1d |
| 5932 | 0x172c | 4f | 4f | 69 | 69 | 69 |
| 5934 | 0x172e | 4f | 4f | 11 | 11 | 11 |
| 6954 | 0x1b2a | 22 | 22 | 21 | 21 | 21 |
| 6986 | 0x1b4a | c1 | c1 | 8b | 8b | 8b |
| 11482 | 0x2cda | 01 | 01 | 02 | 02 | 02 |
| 11950 | 0x2eae | 03 | 03 | 05 | 05 | 05 |
| 11970 | 0x2ec2 | 02 | 02 | 04 | 04 | 04 |
| 11990 | 0x2ed6 | 01 | 01 | 00 | 00 | 00 |
| 13626 | 0x353a | 01 | 01 | 02 | 02 | 02 |
| 15206 | 0x3b66 | 01 | 01 | 03 | 03 | 03 |
| 15934 | 0x3e3e | 02 | 02 | 01 | 01 | 01 |
| 15954 | 0x3e52 | 00 | 00 | 01 | 01 | 01 |
| 16424 | 0x4028 | ff | ff | 23 | 23 | 23 |
| 16425 | 0x4029 | ff | ff | 00 | 00 | 00 |
| 16558 | 0x40ae | 02 | 02 | 03 | 03 | 03 |
| 17410 | 0x4402 | 21 | 21 | c8 | c8 | c8 |
| 17411 | 0x4403 | 05 | 05 | f9 | f9 | f9 |
| 17442 | 0x4422 | e8 | e8 | ce | ce | ce |
| 17443 | 0x4423 | 03 | 03 | fb | fb | fb |
| 22902 | 0x5976 | 01 | 01 | 00 | 00 | 00 |
| 44154 | 0xac7a | 00 | 00 | 01 | 01 | 01 |
| 57762 | 0xe1a2 | 00 | 00 | 01 | 01 | 01 |
| 65110 | 0xfe56 | 02 | 02 | 00 | 00 | 00 |
| 65230 | 0xfece | 01 | 01 | 00 | 00 | 00 |
| 65532 | 0xfffc | 4d | 4d | df | e0 | e0 |

### Grouping of the 52 offsets

| Group | Offsets | Count | Meaning |
|---|---|---|---|
| **videoformat** | 3062 | 1 | `0x05`=mp4, `0x06`=mov (only D=06) |
| checksum | 65532 | 1 | derived; differs whenever any payload byte differs |
| **ntsc_pal** | 65110, 65230 | 2 | 65230=`0x01`pal/`0x00`ntsc; 65110 (field `0x048f`) also flips `0x02`→`0x00` |
| videoquality cascade | the remaining 48 | 48 | `0xc1`(mp4_30p_20mbps) ↔ `0x8b`(mov_60p_200mbps_c4k_10bit) ripples across many records |

The `mov↔mp4` switch touches **only** byte 3062 (and its checksum byte 65532). The
`0xc1↔0x8b` quality switch is the one that cascades widely.

### Blob C (live_full / burst) — separate state

Blob C is a burst/photo capture, not a video-format variant. It differs from the
campaign blobs at 288 total offsets (236 of them unique to C, scattered in ~173 runs
including a 44-byte `0xff` region at `0x402a..0x4055`). These are burst-mode fields,
not container/quality signals, and are excluded from the table above (the table covers
the campaign states A/B/D/E/F only).

## Pairwise diff counts (key rows)

| Pair | # differing |
|---|---|
| A (pal+mp4+0xc1) vs B (ref) | 0 — identical |
| E (mp4+0x8b) vs F (post-reboot) | **0 — identical** |
| D (mov+0x8b) vs E (mp4+0x8b) | **2** (3062, 65532) |
| D (mov+0x8b) vs F (post-reboot) | **2** (3062, 65532) |
| A vs D (mov) | 52 |
| A vs E (mp4) | 51 |

## (c) Is there a second / authoritative format field? — **No.**

`mov` vs `mp4` differ at exactly two bytes: `3062` (`06` vs `05`) and the checksum
`65532` (`df` vs `e0`). There is **no second offset** that changes on the format switch,
and there is **no offset that stays constant while plausibly holding a separate
"default container"**. The container is a single byte at 3062, and it is the only
container signal anywhere in the 65533-byte blob.

The format byte sits inside a 13-byte value run (record `0x005e`); in the mov state
only byte[0] of that run flips to `06` while bytes[1..12] remain `05`:

```
record 0x005e @ 0x0bee:  5e 00 14 00 01 00   [06 05 05 05 05 05 05 05 05 05 05 05 05] 00
                          id    len  flag     ^  active value (3062)
```

So the mov value `0x06` is written to only one byte, and there is no mirror copy.

## (d) Why byte 3062 reverts to mp4 on boot — best hypothesis

Empirically: the post-reboot blob F is byte-for-byte identical to the mp4 blob E. On
boot the camera reset `3062` from `0x06` (mov) back to `0x05` (mp4) and recomputed the
checksum (`0xdf`→`0xe0`), while **`6986 = 0x8b` survived** (the `mov_60p_200mbps_c4k_10bit`
quality code persisted).

This matches the persistence model already documented in
`04_工具与脚本/campaign2/隐藏格式持久化_成果.md`: `videoformat`/`videoquality` written via the
`setsetting` CGI land **only in the RAM copy**, not flash, whereas `ntsc_pal` (and a full
blob flash-write) land in flash. The mov state captured in `diff_blob_mov.bin` was a
**RAM-only** container change (`3062=0x06`), so on reboot the camera reloaded flash and
re-derived the container back to mp4. The quality `0x8b` did persist, which is consistent
with the container being a separately-gated "menu visibility" flag that is re-initialised
on boot rather than a stored value.

Conclusion for the open question: **the container has no second persistent field inside
this blob.** If mov is to survive a power cycle, `3062=0x06` must be written to flash as
part of a full 65533-byte blob upload (with a valid `sum%256==0` checksum), not via a
RAM `setsetting` — and there is no other byte in the blob to also set.

## Known-field 64-byte contexts (hex)

All six blobs agree on the header; the fields below are shown for blob A (pal+mp4+0xc1),
which is representative.

```
videoformat @ 3062 (0x0bf6) — record 0x005e @ 0x0bee:
  3030  00 02 00 02 00 02 00 02 00 02 00 02 00 02 00 02
  3046  00 02 00 02 00 02 00 02 00 02 5e 00 14 00 01 00
  3062  05 05 05 05 05 05 05 05 05 05 05 05 05 00 5f 00
  3078  14 00 01 00 01 01 01 01 01 01 01 01 01 01 01 01
  3094  01 00 60 00 14 00 01 00 00 00 00 00 00 00 00 00
  3110  00 00 00 00 00 00 61 00 14 00 01 00 00 00 00 00
          (mov state: first byte here = 06, rest unchanged 05)

videoquality @ 6986 (0x1b4a) — record 0x0124 @ 0x1b44:
  6960  21 00 21 00 21 00 21 00 21 00 21 00 21 00 21 00
  6976  21 00 21 00 24 01 20 00 01 00 c1 00 c0 00 c0 00
  6992  c0 00 c0 00 c0 00 c0 00 c0 00 c0 00 c0 00 c0 00
  7008  c0 00 c0 00 25 01 14 00 01 00 01 01 01 01 01 01
  7024  01 01 01 01 01 01 01 00 26 01 14 00 01 00 00 00
  7040  00 00 00 00 00 00 00 00 00 00 00 00 28 01 14 00
          (0x8b state: 6986=8b 00, then 15 × c0 00)

ntsc_pal @ 65230 (0xfece) — record 0x0495 @ 0xfec8:
  65200  00 00 00 00 94 04 14 00 00 00 00 00 00 00 00 00
  65216  00 00 00 00 00 00 00 00 95 04 14 00 01 00 01 00
  65232  00 00 00 00 00 00 00 00 00 00 00 00 a2 04 14 00
  65248  01 00 01 01 01 01 01 01 01 01 01 01 01 01 01 00
          (ntsc state: 65230=00)

checksum @ 65532 (0xfffc) — last byte of the 65533-byte blob:
  65500  02 02 02 02 02 02 02 00 b5 04 14 00 01 00 01 01
  65516  01 01 01 01 01 01 01 01 01 01 01 01 01 00 ff ff 00 00 4d
          (checksum = 0x4d for A/B, 0xdf for D, 0xe0 for E/F)
```

## Key finding (summary)

- Header = 44 bytes (`0x00..0x2b`): `"Panasonic"` + 9 NUL + `"DC-S5"` + 21 NUL; payload starts at **`0x2c`**.
- `videoformat` (byte **3062**, record `0x005e`) is the **sole** container field: `mov↔mp4` changes exactly that one byte (plus the derived checksum).
- There is **no second/authoritative "default container" field** in the blob — nothing else moves on the format switch and nothing constant could encode a default.
- On boot the mov value (`0x06`) reverts to mp4 (`0x05`) while quality `0x8b` persists; consistent with a RAM-only `videoformat` write that the firmware re-initialises from flash at boot. To persist mov, flash-write the full blob with `3062=0x06` and a valid checksum.
