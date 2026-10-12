# Unencoded region audit

All 13 regions marked unencoded in the 62-entry manifest were read in full. Four are empty; seven contain only byte 0x00 and two contain only byte 0xff. Every actual SHA-256 matches the stored directory digest, including empty regions. There is no program plaintext in these 13 extracted regions. See evidence.json for paths, sizes, hashes and byte sets.

The other 49 payloads remain undecoded. Parser names is_encrypted and iv_hex are interpretations, not camera-side proof of the algorithm or IV semantics.

The examined NT public U-Boot configuration is pvc04v_MC8266_defconfig, containing unzip and booti commands. The sc2006a-evb board_init function only returns zero. Neither proves a UPD decoder or a correspondence with S1M2 encoded components.
