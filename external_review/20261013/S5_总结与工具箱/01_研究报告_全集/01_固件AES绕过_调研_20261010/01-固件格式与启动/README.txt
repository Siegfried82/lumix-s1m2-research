Panasonic LUMIX Sync firmware catalog — fetch results
=======================================================

Catalog files
-------------
firm_list.xml  — firmware catalog (body + lens). HTTP 200, 1573 bytes.
apli_list.xml  — app (iOS/Android) version catalog. HTTP 200, 443 bytes.

Entry counts
------------
<body> entries: 7
<lens> entries: 0  (the <lens> section is empty — no lens firmware is listed)

Body entries (modelNumber, version, url)
----------------------------------------
1. DC-S5     v2.8  https://panasonic.jp/support/share/eww/com/software/lumix_sync/dsc/ff/s5___v28/firm_info.xml
2. DC-GH6_   v3.0  https://panasonic.jp/support/share/eww/com/software/lumix_sync/dsc/fts/gh6__v30/firm_info.xml
3. DC-GH5M2  v1.3  https://panasonic.jp/support/share/eww/com/software/lumix_sync/dsc/fts/gh5m2v13/firm_info.xml
4. DC-S5M2   v3.1  https://panasonic.jp/support/share/eww/com/software/lumix_sync/dsc/ff/s5m2_v31/firm_info.xml
5. DC-S5M2X  v2.1  https://panasonic.jp/support/share/eww/com/software/lumix_sync/dsc/ff/s5m2xv21/firm_info.xml
6. DC-G9M2   v2.2  https://panasonic.jp/support/share/eww/com/software/lumix_sync/dsc/fts/g9m2_v22/firm_info.xml
7. DC-GH7    v1.1  https://panasonic.jp/support/share/eww/com/software/lumix_sync/dsc/fts/gh7__v11/firm_info.xml

Note: the catalog modelNumber for the GH6 is "DC-GH6_" (trailing underscore); the
firm_info.xml resolves that to the clean model "DC-GH6".

Representative firm_info (DC-S5M2) — saved as firm_info_s5m2.xml
----------------------------------------------------------------
  model       DC-S5M2
  type        body
  version     Ver.3.1
  date        20241009
  size        205683712      (this is the UNCOMPRESSED .bin size, see below)
  url         https://panasonic.jp/support/share/eww/com/software/lumix_sync/dsc/ff/zip/S5m2_V31.zip
  history_url (en) https://panasonic.jp/support/share/eww/com/software/lumix_sync/dsc/ff/s5m2_v31/history_en.html
  eula_url    (en) https://panasonic.jp/support/share/eww/com/software/lumix_sync/eula/eula_en.html

All 7 body firm_info.xml files follow the same shape (model/type/version/date/size/url
+ per-language history_url/eula_url). No <lens> firm_info exists because the lens
section of the catalog is empty.

Firmware binary (DC-S5M2 example)
---------------------------------
<url> points to a ZIP, not the raw binary:
  https://panasonic.jp/support/share/eww/com/software/lumix_sync/dsc/ff/zip/S5m2_V31.zip

HTTP: the panasonic.jp URL returns HTTP/2 302 and redirects to the real origin:
  https://av.jpn.support.panasonic.com/support/share/eww/com/software/lumix_sync/dsc/ff/zip/S5m2_V31.zip
The path after the hostname is identical; only the hostname changes.

Final headers (av.jpn.support.panasonic.com):
  HTTP/1.1 200 OK
  Content-Type: application/zip
  Content-Length: 186598983   (~178 MiB)
  Accept-Ranges: bytes
  ETag: "b1f4647-622da5b67ad00"   (opaque Apache size+mtime tag, NOT a content hash)
  Last-Modified: Tue, 24 Sep 2024 09:44:52 GMT

ZIP structure (first 64 KiB captured as fw_sample.bin):
  Local file header at offset 0: 50 4B 03 04  (PK zip magic)
    compression method = 8 (deflate)
    entry name          = S5m2_V31.bin
    CRC-32              = 0x2E50464C
    compressed size     = 186598809 bytes
    uncompressed size   = 205683712 bytes  (matches the XML <size> exactly)
  The ZIP contains a single file: S5m2_V31.bin.

Inner firmware image (decompressed from fw_sample.bin):
  First bytes: 55 50 44 00 00 02 00 00 00 02 00 00  "UPD...."
  then chip/model string "MC8223" (offset 12).
  Magic = "UPD" (0x55 0x50 0x44), i.e. a Panasonic firmware update container
  whose payload carries a Panasonic LSI model identifier (MC8223).

Download URL template
---------------------
  catalog:    https://panasonic.jp/support/share/eww/com/software/lumix_sync/firm_list.xml
  firm_info:  https://panasonic.jp/support/share/eww/com/software/lumix_sync/dsc/{ff|fts}/{key}/firm_info.xml
  firmware:   https://panasonic.jp/support/share/eww/com/software/lumix_sync/dsc/{ff|fts}/zip/{FILE}.zip
              (302 -> https://av.jpn.support.panasonic.com/support/share/eww/com/software/lumix_sync/dsc/{ff|fts}/zip/{FILE}.zip)
  {ff|fts}   = product family directory (ff = full-frame, fts = MFT/other)
  {FILE}     = e.g. S5m2_V31.zip, S5___V28.zip, GH6_VV30.zip, GH5m2V13.zip,
                    S5m2XV21.zip, G9m2_V22.zip, GH7__V11.zip

Per-model firmware URL / XML size
---------------------------------
  DC-S5     https://panasonic.jp/support/share/eww/com/software/lumix_sync/dsc/ff/zip/S5___V28.zip   size 90238464
  DC-GH6    https://panasonic.jp/support/share/eww/com/software/lumix_sync/dsc/fts/zip/GH6_VV30.zip  size 198363136
  DC-GH5M2  https://panasonic.jp/support/share/eww/com/software/lumix_sync/dsc/fts/zip/GH5m2V13.zip  size 100039680
  DC-S5M2   https://panasonic.jp/support/share/eww/com/software/lumix_sync/dsc/ff/zip/S5m2_V31.zip   size 205683712
  DC-S5M2X  https://panasonic.jp/support/share/eww/com/software/lumix_sync/dsc/ff/zip/S5m2XV21.zip   size 205683712
  DC-G9M2   https://panasonic.jp/support/share/eww/com/software/lumix_sync/dsc/fts/zip/G9m2_V22.zip  size 209746432
  DC-GH7    https://panasonic.jp/support/share/eww/com/software/lumix_sync/dsc/fts/zip/GH7__V11.zip  size 207125504
  (sizes are the uncompressed .bin payload sizes declared in each firm_info.xml)

Signature / hash / checksum
---------------------------
NONE. The firm_info.xml contains no hash, signature, or checksum field for the
firmware binary. The HTTP responses carry no Content-MD5 / Digest / Content-Signature
header; the only ETag present ("b1f4647-622da5b67ad00") is Apache's opaque
size+mtime entity tag (its first component 0x0b1f4647 = 186598983 = the byte size),
not a cryptographic hash. The only checksum anywhere is the standard ZIP CRC-32 of
each archive entry (a ZIP-format integrity field, not a signature). The firmware
is delivered with integrity but no authenticity protection.

Files in this folder
--------------------
firm_list.xml          original body/lens catalog
apli_list.xml          original app catalog
firm_info_s5m2.xml     full firm_info for DC-S5M2 (representative body entry)
fw_sample.bin          first 65536 bytes of S5m2_V31.zip (PK header + start of entry)
README.txt             this file
