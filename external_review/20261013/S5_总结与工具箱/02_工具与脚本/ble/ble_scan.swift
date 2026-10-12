// ble_scan.swift — scan for (Panasonic LUMIX) BLE peripherals and enumerate GATT.
//
// The S5 exposes BLE for LUMIX Sync (pairing / geotag / wake-up). The app's
// decompiled code shows a Panasonic GATT layout:
//   service        054ac620-3214-11e6-ac0d-0002a5d5c51b   (and ...-0001-...)
//   characteristic bb5d2a8c-5d3b-43ad-bfc3-470cad55c1ca
//   characteristic e182ec40/41-3213-11e6-ab07-0002a5d5c51b
// This tool only SCANS and READS (discover services/characteristics); it never
// writes a characteristic.
//
// Build: swiftc -framework CoreBluetooth -framework Foundation -o ble_scan ble_scan.swift
// Run:   ./ble_scan [seconds]
import Foundation
import CoreBluetooth

let LUMIX_SVC = "054AC620-3214-11E6-AC0D-0002A5D5C51B"
let LUMIX_CHAR = "BB5D2A8C-5D3B-43AD-BFC3-470CAD55C1CA"

final class Scanner: NSObject, CBCentralManagerDelegate, CBPeripheralDelegate {
    var seen = Set<UUID>()
    var peripherals: [UUID: CBPeripheral] = [:]
    var target: CBPeripheral?
    var done = false
    var readIssued = false

    func centralManagerDidUpdateState(_ c: CBCentralManager) {
        switch c.state {
        case .poweredOn:
            print("[*] bluetooth powered on, scanning…")
            c.scanForPeripherals(withServices: nil,
                                 options: [CBCentralManagerScanOptionAllowDuplicatesKey: false])
        case .unauthorized:
            print("[!] Bluetooth permission DENIED (TCC). Grant Bluetooth access to the terminal/DSH app.")
        case .poweredOff:
            print("[!] bluetooth is OFF")
        default:
            print("[!] central state = \(c.state.rawValue)")
        }
    }

    func centralManager(_ c: CBCentralManager, didDiscover p: CBPeripheral,
                        advertisementData a: [String: Any], rssi R: NSNumber) {
        let name = (a[CBAdvertisementDataLocalNameKey] as? String) ?? p.name ?? "(no name)"
        let svcs = (a[CBAdvertisementDataServiceUUIDsKey] as? [CBUUID]) ?? []
        let ovf = (a[CBAdvertisementDataOverflowServiceUUIDsKey] as? [CBUUID]) ?? []
        var mfg = ""
        if let m = a[CBAdvertisementDataManufacturerDataKey] as? Data {
            mfg = m.map { String(format: "%02x", $0) }.joined()
        }
        let key = p.identifier
        if seen.contains(key) { return }
        seen.insert(key)
        let interesting = svcs.contains { $0.uuidString.uppercased() == LUMIX_SVC } || mfg.hasPrefix("da04")
        print(String(format: "%@ name=%@ id=%@ rssi=%@ svcs=%@%s mfg=%@",
                     interesting ? "[HIT]" : "[seen]", name, key.uuidString, R.stringValue,
                     svcs.map { $0.uuidString }.joined(separator: ","),
                     ovf.isEmpty ? "" : " ovf=\(ovf.map { $0.uuidString }.joined(separator: ","))",
                     mfg))
        peripherals[key] = p
        if interesting && target == nil {
            target = p
            p.delegate = self
            print("[*] connecting to \(name) …")
            c.stopScan()
            c.connect(p, options: nil)
        }
    }

    func centralManager(_ c: CBCentralManager, didConnect p: CBPeripheral) {
        print("[+] connected: \(p.name ?? "?")")
        p.discoverServices(nil)
    }

    func centralManager(_ c: CBCentralManager, didFailToConnect p: CBPeripheral, error: Error?) {
        print("[!] connect failed: \(error?.localizedDescription ?? "?")")
        c.scanForPeripherals(withServices: nil, options: nil)
    }

    func peripheral(_ p: CBPeripheral, didUpdateNotificationStateFor ch: CBCharacteristic, error: Error?) {
        print("      notify state \(ch.uuid.uuidString) -> \(ch.isNotifying) \(error?.localizedDescription ?? "")")
    }

    func peripheral(_ p: CBPeripheral, didDiscoverServices error: Error?) {
        if let e = error { print("[!] discoverServices: \(e.localizedDescription)"); return }
        for s in p.services ?? [] {
            print("  service \(s.uuid.uuidString)")
            p.discoverCharacteristics(nil, for: s)
        }
    }

    func peripheral(_ p: CBPeripheral, didDiscoverCharacteristicsFor s: CBService, error: Error?) {
        if let e = error { print("  [!] chars for \(s.uuid): \(e.localizedDescription)"); return }
        for ch in s.characteristics ?? [] {
            let props = ch.properties
            var f: [String] = []
            if props.contains(.read) { f.append("R") }
            if props.contains(.write) { f.append("W") }
            if props.contains(.writeWithoutResponse) { f.append("w") }
            if props.contains(.notify) { f.append("N") }
            if props.contains(.indicate) { f.append("I") }
            print("    char \(ch.uuid.uuidString) [\(f.joined())]")
            if props.contains(.read) && !readIssued {
                readIssued = true
                print("      -> issuing READ on \(ch.uuid.uuidString)")
                p.readValue(for: ch)
            }
        }
        done = true
    }

    func peripheral(_ p: CBPeripheral, didUpdateValueFor ch: CBCharacteristic, error: Error?) {
        if let e = error {
            print("      read \(ch.uuid.uuidString) FAILED: \(e.localizedDescription)")
            return
        }
        if let v = ch.value {
            let hex = v.prefix(32).map { String(format: "%02x", $0) }.joined()
            print("      read \(ch.uuid.uuidString) = \(hex)\(v.count > 32 ? " …(\(v.count)B)" : "")")
        }
    }
}

let secs = CommandLine.arguments.count > 1 ? Double(CommandLine.arguments[1])! : 20.0
let sc = Scanner()
let cm = CBCentralManager(delegate: sc, queue: nil)
RunLoop.main.run(until: Date().addingTimeInterval(secs))
print("[*] scan window (\(Int(secs))s) ended; \(sc.seen.count) peripheral(s) seen")
