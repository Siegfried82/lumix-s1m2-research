# LUMIX Lab Java crypto call sites

Recorded every visible Cipher.getInstance, SecretKeySpec, IvParameterSpec and doFinal call site in the existing decompiler output. No matching file was found in com/panasonic namespace. This is a bounded lexical result, not proof that the application cannot decrypt firmware: helper packages are obfuscated, native code exists and some methods were incompletely decompiled.

The examined ia/B.java call explicitly wraps a key named TLS (line 33), so this occurrence does not provide a firmware key or UPD decryption path. The earlier verified firmware route reads file fragments and submits them unchanged to HTTPS firmware/send.

The next useful input is a camera-side loader/runtime binary with a verifiable origin, or an identified native caller receiving UPD data. Further crypto-library name lists cannot establish firmware plaintext. No camera command, application execution or key brute force was performed.

## Native dependency audit

All 18 arm64 libraries in the existing split APK were statically inspected. Saved complete dynamic symbols, dependencies, entry hashes and matched imports to native_symbols.json; audit_native.py reproduces the inventory. The libllc SHA-256 and complete dynamic-symbol name set independently match the earlier inventory.

libllc has no matching imported EVP/AES/RSA/decrypt symbols and no direct dependency on libcrypto/libssl; dependencies include HEIF, YUV and image conversion libraries. libtechorfilter likewise has no matching crypto imports; its three firmware-named exports are Canon/Mamiya EXIF metadata accessors, not an identified Panasonic firmware loader. Crypto imports are visible in libssl and multimedia libraries. These symbol/dependency facts do not exclude static cryptography, dynamic loading or unnamed internal functions.

No native UPD input caller or verified decoder was found in this bounded inspection. The missing camera-side loader/decoder remains the decisive gap; symbol searches alone cannot satisfy the firmware-plaintext objective.
