// ble_read.swift — connect to the S5 and read a list of characteristics one at a
// time, reporting the value or the exact error for each. Diagnostic for the
// LUMIX BLE pairing chain (see 01_研究报告/15_蓝牙BLE协议逆向_20261013.md).
//
// Build: swiftc -framework CoreBluetooth -framework Foundation -o ble_read ble_read.swift
// Run:   ./ble_read [seconds]
import Foundation
import CoreBluetooth

let SVC_MAIN = "054AC620-3214-11E6-AC0D-0002A5D5C51B"

// read-routing targets from C5/e.java z(): idx36/37/38 (device info block),
// idx35 INITIAL_INFORM, idx5 SSID, idx6 WIFI PASSWORD, idx15
let READS = [
    "054AC621-3214-11E6-0001-0002A5D5C51B",
    "054AC622-3214-11E6-0001-0002A5D5C51B",
    "054AC623-3214-11E6-0001-0002A5D5C51B",
    "03E23A31-A54C-40FA-A668-DE9ACDC910BB",
    "E206A5C0-3214-11E6-AFE4-0002A5D5C51B",
    "C97CF1A5-3C03-4290-8C1B-9E74B9500F54",
    "E1392720-3215-11E6-A035-0002A5D5C51B",
    "69E4D998-54B7-40F5-A5F8-4CC236CD2347",
    "9C781C60-3218-11E6-9932-0002A5D5C51B",
    "3D22C6BE-BAA6-451B-AA2C-F96C50005910",
]

func hex(_ b: [UInt8]) -> String { b.prefix(48).map { String(format: "%02x", $0) }.joined() }

final class R: NSObject, CBCentralManagerDelegate, CBPeripheralDelegate {
    var central: CBCentralManager!
    var target: CBPeripheral?
    var chars: [String: CBCharacteristic] = [:]
    var servicesSeen = 0, servicesWithChars = 0, idx = 0
    var done = false

    func centralManagerDidUpdateState(_ c: CBCentralManager) {
        if c.state == .poweredOn { c.scanForPeripherals(withServices: [CBUUID(string: SVC_MAIN)], options: nil) }
        else { print("[!] state \(c.state.rawValue)") }
    }
    func centralManager(_ c: CBCentralManager, didDiscover p: CBPeripheral, advertisementData a: [String: Any], rssi R: NSNumber) {
        print("[HIT] \((a[CBAdvertisementDataLocalNameKey] as? String) ?? p.name ?? "?") rssi=\(R)")
        target = p; p.delegate = self; c.stopScan(); c.connect(p, options: nil)
    }
    func centralManager(_ c: CBCentralManager, didConnect p: CBPeripheral) {
        print("[+] connected; discovering services"); p.discoverServices(nil)
    }
    func centralManager(_ c: CBCentralManager, didDisconnectPeripheral p: CBPeripheral, error: Error?) {
        print("[!] disconnected: \(error?.localizedDescription ?? "clean")"); done = true
        CFRunLoopStop(CFRunLoopGetMain())
    }
    func peripheral(_ p: CBPeripheral, didDiscoverServices error: Error?) {
        servicesSeen = (p.services ?? []).count
        print("[*] \(servicesSeen) services")
        for s in p.services ?? [] { p.discoverCharacteristics(nil, for: s) }
    }
    func peripheral(_ p: CBPeripheral, didDiscoverCharacteristicsFor s: CBService, error: Error?) {
        servicesWithChars += 1
        for ch in s.characteristics ?? [] { chars[ch.uuid.uuidString.uppercased()] = ch }
        if servicesWithChars == servicesSeen {
            print("[*] discovery complete: \(chars.count) characteristics")
            if CommandLine.arguments.contains("--idle") {
                print("[*] IDLE MODE: no reads issued; watching for spontaneous disconnect")
            } else {
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { self.next() }
            }
        }
    }
    func next() {
        guard let p = target else { return }
        if idx >= READS.count { print("[*] read list done"); done = true; CFRunLoopStop(CFRunLoopGetMain()); return }
        let u = READS[idx]; idx += 1
        if let ch = chars[u] { print("  read \(u.prefix(8)) → request"); p.readValue(for: ch) }
        else { print("  read \(u.prefix(8)) → characteristic ABSENT"); next() }
    }
    func peripheral(_ p: CBPeripheral, didUpdateValueFor ch: CBCharacteristic, error: Error?) {
        let u = ch.uuid.uuidString.uppercased()
        if let e = error { print("    \(u.prefix(8)) ERR: \(e.localizedDescription)") }
        else if let v = ch.value { print("    \(u.prefix(8)) OK (\(v.count) B): \(hex([UInt8](v)))") }
        else { print("    \(u.prefix(8)) OK but nil value") }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) { self.next() }
    }
}

let secs = CommandLine.arguments.compactMap { Double($0) }.first ?? 40
let r = R(); r.central = CBCentralManager(delegate: r, queue: nil)
RunLoop.main.run(until: Date().addingTimeInterval(secs))
if !r.done { print("[*] window ended") }
