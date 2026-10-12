// ble_pair.swift — reproduce the LUMIX Sync BLE pairing chain on a DC-S5.
//
// Reconstructed from the Android APK (see 01_研究报告/15_蓝牙BLE协议逆向_20261013.md):
//   C5/e.java   : K() write routing, z() read routing
//   C5/g.java   : T0() notify routing / A() registNotify
//   E5/j.java   : connect + handshake order
//   p154t5/b.java: session key = first 4 bytes (big endian) of INITIAL_INFORM
//   H5/s.java   : byte-permutation + 32-bit XOR codec (default key 0x9032782C)
//
// Flow: connect -> discover -> enable the 12 notify CCCDs -> read INITIAL_INFORM
//       (session key) -> write DLNA_UUID_APS + FRIENDLY_NAME_APS (encoded)
//       -> read CAMERA_SSID -> read CAMERA_WIFI_PASSWORD -> decode.
//
// Build: swiftc -framework CoreBluetooth -framework Foundation -o ble_pair ble_pair.swift
// Run:   ./ble_pair [seconds]
import Foundation
import CoreBluetooth

let SVC_MAIN    = "054AC620-3214-11E6-AC0D-0002A5D5C51B"
let CH_INITIAL  = "03E23A31-A54C-40FA-A668-DE9ACDC910BB"   // read idx35
let CH_DLNA_APS = "BB5D2A8C-5D3B-43AD-BFC3-470CAD55C1CA"   // write idx16
let CH_NAME_APS = "7B61774F-EFB4-44C6-A66D-C69E3B384C4A"   // write idx17
let CH_SSID     = "E206A5C0-3214-11E6-AFE4-0002A5D5C51B"   // read idx5
let CH_PASS     = "C97CF1A5-3C03-4290-8C1B-9E74B9500F54"   // read idx6

// C5/g.java T0(): notify registration list (order as in A())
let NOTIFY_UUIDS = [
    "4CF487C0-32A7-11E6-A50D-0002A5D5C51B", // 10
    "37701B80-32A7-11E6-BB83-0002A5D5C51B", // 8
    "18345BE1-3217-11E6-B56C-0002A5D5C51B", // 30
    "48669DA0-3217-11E6-B08D-0002A5D5C51B", // 13
    "E182EC43-3213-11E6-AB07-0002A5D5C51B", // 14
    "DA534D0A-63A3-447C-A889-AAB701906AF2", // 29
    "D611B4A0-3217-11E6-8D98-0002A5D5C51B", // 25
    "E182EC41-3213-11E6-AB07-0002A5D5C51B", // 31
    "E182EC42-3213-11E6-AB07-0002A5D5C51B", // 32
    "7BE5FE6E-475B-11E7-A919-92EBCB67FE33", // 40
    "A31A7A87-9C47-4DA1-A740-853BB603C511", // 43
    "D009F95F-1A84-45EF-B242-8E4D645ABD49", // 53
]

// ---- H5/s.java codec -------------------------------------------------------
let DEFAULT_KEY: UInt32 = UInt32(bitPattern: -1875740628)   // 0x9032782C

func swap32(_ v: UInt32) -> UInt32 {
    ((v >> 24) & 0xFF) | ((v << 24) & 0xFF000000) |
    ((v << 8) & 0x00FF0000) | ((v >> 8) & 0x0000FF00)
}

func decode(_ data: [UInt8], key: UInt32) -> [UInt8]? {
    guard data.count % 4 == 0 else { return nil }
    let k: UInt32 = (key == 0) ? DEFAULT_KEY : key
    var out = [UInt8]()
    var i = 0
    while i < data.count {
        let v = (UInt32(data[i+3]) << 24) | (UInt32(data[i+2]) << 16) |
                (UInt32(data[i+1]) << 8) | UInt32(data[i])
        let x = swap32(v) ^ k
        if i == 0 {
            out += [UInt8((x >> 8) & 0xFF), UInt8((x >> 16) & 0xFF), UInt8((x >> 24) & 0xFF)]
        } else {
            out += [UInt8(x & 0xFF), UInt8((x >> 8) & 0xFF), UInt8((x >> 16) & 0xFF), UInt8((x >> 24) & 0xFF)]
        }
        i += 4
    }
    if let z = out.firstIndex(of: 0xFF) { out = Array(out[0..<z]) }
    return out
}

func encode(_ payload: [UInt8], key: UInt32, total: Int = 20) -> [UInt8] {
    let k: UInt32 = (key == 0) ? DEFAULT_KEY : key
    var buf = [UInt8](repeating: 0xFF, count: total)
    buf[0] = UInt8(payload.count & 0xFF)
    for (i, b) in payload.enumerated() where (1 + i) < total { buf[1 + i] = b }
    var out = [UInt8]()
    var i = 0
    while i < total {
        let b = Array(buf[i..<min(i+4, total)])
        let v = (UInt32(b[3]) << 24) | (UInt32(b[2]) << 16) | (UInt32(b[1]) << 8) | UInt32(b[0])
        let x = v ^ k
        out += [UInt8((x >> 24) & 0xFF), UInt8((x >> 16) & 0xFF), UInt8((x >> 8) & 0xFF), UInt8(x & 0xFF)]
        i += 4
    }
    return out
}

func hex(_ b: [UInt8]) -> String { b.map { String(format: "%02x", $0) }.joined() }
func printable(_ b: [UInt8]) -> String {
    String(bytes: b.map { ($0 >= 32 && $0 < 127) ? $0 : UInt8(ascii: ".") }, encoding: .utf8) ?? ""
}

// ---- BLE ------------------------------------------------------------------
final class Pair: NSObject, CBCentralManagerDelegate, CBPeripheralDelegate {
    var central: CBCentralManager!
    var target: CBPeripheral?
    var chars: [String: CBCharacteristic] = [:]
    var notifyDone = 0
    var started = false
    var notifyIdx = 0
    var descriptors: [String: CBDescriptor] = [:]
    var key: UInt32 = 0
    var log: [String] = []
    var ssid: String?
    var pass: String?
    var finished = false
    let outPath: String

    init(out: String) { outPath = out; super.init() }

    func note(_ s: String) { print(s); log.append(s) }

    func centralManagerDidUpdateState(_ c: CBCentralManager) {
        if c.state == .poweredOn {
            note("[*] scanning…")
            c.scanForPeripherals(withServices: [CBUUID(string: SVC_MAIN)], options: nil)
        } else { note("[!] central state \(c.state.rawValue)") }
    }

    func centralManager(_ c: CBCentralManager, didDiscover p: CBPeripheral,
                        advertisementData a: [String: Any], rssi R: NSNumber) {
        let name = (a[CBAdvertisementDataLocalNameKey] as? String) ?? p.name ?? "?"
        note("[HIT] \(name) rssi=\(R)")
        target = p; p.delegate = self
        c.stopScan()
        note("[*] connecting…")
        c.connect(p, options: nil)
    }

    func centralManager(_ c: CBCentralManager, didConnect p: CBPeripheral) {
        note("[+] connected \(p.name ?? "?")")
        p.discoverServices(nil)
    }

    func centralManager(_ c: CBCentralManager, didDisconnectPeripheral p: CBPeripheral, error: Error?) {
        note("[!] disconnected: \(error?.localizedDescription ?? "clean")")
        finish()
    }

    func peripheral(_ p: CBPeripheral, didDiscoverServices error: Error?) {
        for s in p.services ?? [] { p.discoverCharacteristics(nil, for: s) }
    }

    func peripheral(_ p: CBPeripheral, didDiscoverCharacteristicsFor s: CBService, error: Error?) {
        if let e = error { note("  chars for \(s.uuid.uuidString.prefix(8)) ERR \(e.localizedDescription)") }
        for ch in s.characteristics ?? [] { chars[ch.uuid.uuidString.uppercased()] = ch }
        if started || chars.count < 20 { return }
        started = true
        note("[*] discovered \(chars.count) characteristics; subscribing notify CCCDs one by one")
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { self.nextDescriptor() }
    }

    func nextDescriptor() {
        guard let p = target else { return }
        if notifyIdx >= NOTIFY_UUIDS.count {
            note("[*] notify subscription pass done (\(notifyDone) ok); reading INITIAL_INFORM")
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                if let ch = self.chars[CH_INITIAL] { p.readValue(for: ch) }
            }
            return
        }
        let u = NOTIFY_UUIDS[notifyIdx]; notifyIdx += 1
        if let ch = chars[u] { p.discoverDescriptors(for: ch) } else { note("    \(u.prefix(8)): characteristic absent"); nextDescriptor() }
    }

    func peripheral(_ p: CBPeripheral, didDiscoverDescriptorsFor ch: CBCharacteristic, error: Error?) {
        let u = ch.uuid.uuidString.uppercased()
        if let e = error { note("    \(u.prefix(8)): discoverDescriptors ERR \(e.localizedDescription)"); nextDescriptor(); return }
        let ds = ch.descriptors ?? []
        let custom = ds.first { $0.uuid.uuidString.uppercased() == u }
        let cccd = ds.first { $0.uuid.uuidString.uppercased().hasPrefix("00002902") || $0.uuid.uuidString.uppercased() == "2902" }
        if let d = custom ?? cccd {
            note("    \(u.prefix(8)): writing descriptor \(d.uuid.uuidString) = 0100")
            p.writeValue(Data([0x01, 0x00]), for: d)
        } else {
            note("    \(u.prefix(8)): no descriptor (\(ds.count) found) -> setNotifyValue")
            p.setNotifyValue(true, for: ch)
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) { self.nextDescriptor() }
    }

    func peripheral(_ p: CBPeripheral, didUpdateNotificationStateFor ch: CBCharacteristic, error: Error?) {
        if error == nil { notifyDone += 1 }
    }

    func peripheral(_ p: CBPeripheral, didWriteValueFor ch: CBCharacteristic, error: Error?) {
        note("    write \(ch.uuid.uuidString.prefix(8)) -> \(error == nil ? "ok" : "ERR \(error!)")")
    }

    func peripheral(_ p: CBPeripheral, didUpdateValueFor ch: CBCharacteristic, error: Error?) {
        let u = ch.uuid.uuidString.uppercased()
        if let e = error { note("    read \(u.prefix(8)) ERR \(e.localizedDescription)"); return }
        guard let v = ch.value else { return }
        let b = [UInt8](v)
        if u == CH_INITIAL {
            key = (UInt32(b[0]) << 24) | (UInt32(b[1]) << 16) | (UInt32(b[2]) << 8) | UInt32(b[3])
            note("    INITIAL_INFORM = \(hex(b))")
            note("    session key = 0x\(String(format: "%08X", key))")
            // C5/e.java o()/n(): write DLNA_UUID_APS and FRIENDLY_NAME_APS, encoded
            let dlna = Array("4D454930010010008001020000025AD6".utf8)  // H5/p.A() style MEI id
            if let c1 = chars[CH_DLNA_APS] {
                p.writeValue(Data(encode(dlna, key: key)), for: c1, type: .withResponse)
            }
            if let c2 = chars[CH_NAME_APS] {
                p.writeValue(Data(encode(Array("MacBLE".utf8), key: key)), for: c2, type: .withResponse)
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                self.note("[*] reading CAMERA_SSID")
                if let ch = self.chars[CH_SSID] { p.readValue(for: ch) }
            }
        } else if u == CH_SSID {
            let d = decode(b, key: key) ?? []
            ssid = String(bytes: d, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines)
            note("    CAMERA_SSID raw = \(hex(b))")
            note("    >>> SSID = \(ssid ?? "?")")
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                self.note("[*] reading CAMERA_WIFI_PASSWORD")
                if let ch = self.chars[CH_PASS] { p.readValue(for: ch) }
            }
        } else if u == CH_PASS {
            let d = decode(b, key: key) ?? []
            pass = String(bytes: d, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines)
            note("    CAMERA_WIFI_PASSWORD raw = \(hex(b))")
            note("    >>> PASSWORD = \(pass ?? "?")")
            finished = true
            finish()
        }
    }

    func finish() {
        save()
        CFRunLoopStop(CFRunLoopGetMain())
    }

    func save() {
        var s = "== ble_pair evidence (\(Date())) ==\n"
        s += log.joined(separator: "\n") + "\n"
        s += "session_key = 0x\(String(format: "%08X", key))\n"
        s += "SSID = \(ssid ?? "(none)")\n"
        s += "WIFI_PASSWORD = \(pass ?? "(none)")\n"
        try? s.write(toFile: outPath, atomically: true, encoding: .utf8)
        print("[*] evidence -> \(outPath)")
    }
}

let secs = CommandLine.arguments.count > 2 ? Double(CommandLine.arguments[2])! : 45.0
let out = CommandLine.arguments.count > 1 ? CommandLine.arguments[1] : "out/ble_pair_evidence.txt"
let p = Pair(out: out)
p.central = CBCentralManager(delegate: p, queue: nil)
RunLoop.main.run(until: Date().addingTimeInterval(secs))
if !p.finished { p.note("[*] window ended without completion"); p.save() }
