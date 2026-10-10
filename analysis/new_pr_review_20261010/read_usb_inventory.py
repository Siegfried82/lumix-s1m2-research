"""Read macOS registry only. No USB control transfers, opens, resets, or writes."""
import json
import plistlib
import subprocess
from pathlib import Path

FIELDS = ("IORegistryEntryName", "USB Product Name", "idVendor", "idProduct",
          "bDeviceClass", "bDeviceSubClass", "bDeviceProtocol", "bNumConfigurations",
          "bConfigurationValue", "bInterfaceNumber", "bAlternateSetting",
          "bInterfaceClass", "bInterfaceSubClass", "bInterfaceProtocol", "bNumEndpoints")

def collect(node, output, under_camera=False):
    if isinstance(node, list):
        for child in node:
            collect(child, output, under_camera)
    elif isinstance(node, dict):
        name = str(node.get("USB Product Name", node.get("IORegistryEntryName", "")))
        selected = under_camera or "S1M2" in name
        if selected:
            row = {key: node[key] for key in FIELDS if key in node}
            if row:
                output.append(row)
        for child in node.get("IORegistryEntryChildren", []):
            collect(child, output, selected)

def main():
    raw = subprocess.check_output(["ioreg", "-p", "IOUSB", "-a"])
    rows = []
    collect(plistlib.loads(raw), rows)
    result = {"source": "macOS IOUSB registry", "camera_detected": bool(rows),
              "records": rows, "usb_control_transfers_sent": 0,
              "limitation": "Registry fields may be absent; descriptors cannot establish deployed driver identity."}
    target = Path(__file__).with_name("usb_registry_snapshot.json")
    target.write_text(json.dumps(result, ensure_ascii=False, indent=2))
    print(json.dumps(result, ensure_ascii=False))

if __name__ == "__main__":
    main()
