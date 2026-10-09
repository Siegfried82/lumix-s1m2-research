"""Extract the stored RAR4 BIN member from a legacy SFX; never execute it."""
from pathlib import Path
import hashlib
import json
import struct
import zlib

OUT = Path(__file__).resolve().parent
path = OUT / 'sources/ptool_static/GH2__V11.exe'
data = path.read_bytes()
pos = data.index(b'Rar!\x1a\x07\0') + 7
while True:
    crc, kind, flags, header_size = struct.unpack_from('<HBHH', data, pos)
    assert header_size >= 7 and pos + header_size <= len(data)
    assert crc == zlib.crc32(data[pos+2:pos+header_size]) & 65535
    if kind == 0x74:
        packed, unpacked, host, file_crc, timestamp, version, method, name_len, attr = struct.unpack_from('<IIBIIBBHI', data, pos+7)
        name = data[pos+32:pos+32+name_len]
        assert name == b'GH2__V11.bin' and method == 0x30 and packed == unpacked
        blob = data[pos+header_size:pos+header_size+packed]
        assert len(blob) == packed and zlib.crc32(blob) == file_crc
        dest = OUT / 'sources/GH2__V11.bin'
        dest.write_bytes(blob)
        result = dict(archive_sha256=hashlib.sha256(data).hexdigest(),
                      member=name.decode(), member_size=len(blob),
                      member_sha256=hashlib.sha256(blob).hexdigest(),
                      rar_header_crc_matches=True, member_crc32_matches=True,
                      execution=False, output=str(dest))
        (OUT / 'sources/gh2_control_extraction.json').write_text(json.dumps(result,indent=2)+'\n')
        print(json.dumps(result,indent=2))
        break
    assert kind == 0x73
    pos += header_size
