# LUMIX Lab APK analysis for DC-S5M2

Updated: 2026-10-10

## Scope and provenance

This report records static analysis of Panasonic LUMIX Lab 3.1.0
(`com.panasonic.jp.lumixlab`, versionCode 22) as delivered by Google Play for an
ARM64, zh/en, xxhdpi configuration. The application was downloaded for offline
analysis and was not installed.

Base APK SHA-256:

`6BA873110D201675A905F7DAC39BCDA3291674E7440A484D6D5BD1A78447115F`

The proprietary APK, extracted files, decompiler output, downloaded tools, and
large logs are intentionally not committed to this repository.

## Static-analysis coverage

- Base APK and ARM64, English, Chinese, and xxhdpi split APKs were collected.
- The base package contains two DEX files.
- JADX 1.5.6 produced approximately 13,496 Java source files and 3,856 resource
  files.
- Approximately 529 Java files are in Panasonic namespaces.
- JADX reported 42 methods that were not cleanly reconstructed; these require
  direct DEX/Smali inspection.
- ARM64 native libraries were extracted but have not yet received full native
  disassembly and semantic analysis.

This is sufficient for target-specific application-flow analysis, but it is not
a claim that every application or native-code path has been recovered.

## DC-S5M2 identification

The application identifies DC-S5M2 with:

- device byte: `0x03`
- display name: `DC-S5M2`
- model code: `MC8223`
- family: `S`

DC-S5M2X uses model code `MC8223X`.

## Primary finding: camera-reported function-level mask

The most useful application-side feature gate is not the static model table or
the bundled firmware list. During connection, LUMIX Lab reads one byte from a
BLE GATT characteristic and stores it as a function-level bit mask.

The callback behavior is equivalent to:

```java
int functionLevel = response[0] & 0xffff;
if (functionLevel != 0) {
    FunctionLevel.mask = functionLevel;
    FunctionLevel.wasRead = true;
}
```

The application tests a feature number with:

```java
return ((1 << (featureNumber - 1)) & mask) != 0;
```

Observed menu mapping:

| Bit | Application feature |
| --- | --- |
| 1 | LUT transfer |
| 2 | Shutter remote control, remote shooting, Wi-Fi disconnect |
| 3 | Live Delivery |
| 4 | One firmware-update eligibility condition |
| 5 | Remote Photo Style |

The camera menu adds the Live Delivery item only when bit 3 is set. This is a
confirmed APK-side display/navigation gate and is the smallest candidate for a
controlled proof-of-concept change.

## Why this is not yet a camera-kernel entry point

Bypassing the menu condition would only make the application flow reachable.
It does not demonstrate that DC-S5M2 firmware implements or accepts the
corresponding commands.

After the menu item is selected, the application still:

1. Establishes or verifies the camera Wi-Fi connection.
2. Uses a camera-issued authorization token when querying camera state.
3. Prevents entry when the camera reports an incompatible current state.
4. Parses a NUL-separated camera capability string.
5. Uses the capability version to select RTMP/RTMPS behavior.
6. Blocks two Live Delivery entry actions when the reported profile is
   `cinema`.

Therefore the current result is an entry into the application service flow, not
a shell, bootloader entry, arbitrary code execution primitive, memory-access
primitive, or verified firmware-signature bypass.

## Firmware-list finding

The bundled `assets/firm_list.json` entry for DC-S5M2 is disabled, but it also
lacks the nested firmware object and download URL present for enabled models.
The application dereferences the firmware URL for enabled entries. Changing
only `isEnabled` is therefore expected to cause a null-data failure rather
than provide a usable update.

Even with synthetic metadata, this would expose only the application UI.
Firmware transfer still depends on camera authorization, camera HTTP endpoints,
and device-side parsing and signature checks.

## Static model flags

The DC-S5M2 static model flags in the application are
`false, false, true, false`. Traced uses affect HLG naming, warning behavior,
and parts of Remote Photo Style handling. They are not the principal Live
Delivery menu gate.

## Network and update boundary

The firmware-update flow uses the connected camera as an HTTP endpoint and
includes the application's current camera authorization token. The application
contains operations for preparing, sending, aborting, and completing firmware
data transfer. This confirms an update transport path, not a method to extract
decrypted firmware or bypass device-side validation.

TLS-related code also requires dynamic verification before drawing a security
conclusion: permissive-looking trust-manager callbacks coexist with a
certificate-fingerprint comparison whose expected value is supplied through
the camera connection flow.

## Recommended validation order

1. Make only the Live Delivery menu condition reachable; do not alter
   authentication, TLS, or firmware-transfer behavior.
2. Re-decompile the resulting test build and verify that no unrelated condition
   changed.
3. If a later test-device installation is explicitly authorized, first confirm
   only whether the Live Delivery screen can be reached.
4. Record the actual DC-S5M2 function-level byte and the raw capability string.
5. Distinguish an application-side rejection from a camera-side unsupported
   command before pursuing deeper work.
6. Inspect the remaining failed DEX methods and relevant ARM64 JNI call paths
   only where they intersect BLE, PTP, Live Delivery, or firmware processing.

## Current assessment

Confirmed application-side gates:

- Live Delivery menu visibility
- Live Delivery navigation
- the `cinema` profile UI restriction

Not confirmed:

- DC-S5M2 support for Live Delivery commands
- a camera shell or kernel interface
- arbitrary code execution
- bootloader/debug access
- firmware decryption or signature bypass

The accurate conclusion at this stage is: the application exposes identifiable
service-layer paths to the camera, but no camera-kernel entry point has been
demonstrated.
