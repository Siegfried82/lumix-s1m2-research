#!/usr/bin/env python3
"""menu_map.py — READ-ONLY: build the full menu-item map and find hidden candidates.

Concepts (from allmenu.xml = menu LAYOUT/definition, curmenu.xml = live enable-state):
  * allmenu item = a renderable menu node: id, title_id, func_type, cmd_mode,
    cmd_type, cmd_value, cmd_value2, img.  (has a title -> CAN render in the physical menu)
  * curmenu item = live state: id, enable=yes/no, value.  (enable=yes -> currently active)

Hidden candidates we care about:
  CAT2  "hidden OPTION":  item exists in allmenu (has title/layout node) but curmenu enable=no
          -> if we can flip it to enabled, it would SHOW in the menu.  Most valuable.
  CAT1  "hidden VALUE":   item in allmenu accepts a value not in the standard declared set,
          OR a value present+enabled in curmenu whose item is NOT in allmenu (like hlg_photo_8k).
  CAT3  "no layout node":  item enabled in curmenu but absent from allmenu (hlg_photo_8k).
          -> cannot render in menu; can only be set as a value.

Pure read-only. No camera writes. Uses the captured reference snapshots.
"""
import os, re, json
import xml.etree.ElementTree as ET

HERE = os.path.dirname(os.path.abspath(__file__))
BASE = os.path.join(HERE, "out", "opengate")
ALL = os.path.join(BASE, "allmenu.xml")
CUR = os.path.join(BASE, "curmenu.xml")

def parse_items(path):
    """Return list of dicts for every <item .../> anywhere in the file."""
    root = ET.parse(path).getroot()
    items = []
    for el in root.iter("item"):
        d = dict(el.attrib)
        items.append(d)
    return items

all_items = parse_items(ALL)
cur_items = parse_items(CUR)

# index by id (ids may repeat across sections; keep a set + a first-seen dict)
all_by_id = {}
for d in all_items:
    i = d.get("id")
    if i and i not in all_by_id:
        all_by_id[i] = d
cur_by_id = {}
for d in cur_items:
    i = d.get("id")
    if i and i not in cur_by_id:
        cur_by_id[i] = d

setsetting_all = [d for d in all_items if d.get("cmd_mode") == "setsetting"]

print("=== SUMMARY ===")
print("allmenu total items:      ", len(all_items))
print("allmenu setsetting items: ", len(setsetting_all))
print("curmenu total items:      ", len(cur_items))
print()

# CAT3: in curmenu (enable=yes) but NOT in allmenu at all -> no layout node
cat3 = []
for i, d in cur_by_id.items():
    if d.get("enable") == "yes" and i not in all_by_id:
        cat3.append((i, d))
print("=== CAT3: enabled in curmenu but NO node in allmenu (value-only, can't render) ===")
for i, d in cat3:
    print(f"  {i}  value={d.get('value','-')}")
print()

# For each setsetting allmenu item with a title, get its curmenu enable state
def cur_enable(i):
    c = cur_by_id.get(i)
    return (c.get("enable") if c else "ABSENT")

# CAT2: setsetting item WITH a title, currently enable=no in curmenu (hidden option)
cat2 = []
for d in setsetting_all:
    i = d.get("id")
    t = d.get("title_id")
    if not t:
        continue
    e = cur_enable(i)
    if e == "no":
        cat2.append((i, t, d.get("cmd_type"), d.get("cmd_value"), d.get("cmd_value2"), e))

# group CAT2 by cmd_type for readability
from collections import defaultdict
by_type = defaultdict(list)
for i, t, ct, cv, cv2, e in cat2:
    by_type[ct or "?"].append((i, t, cv, cv2))
print("=== CAT2: setsetting items WITH title, currently enable=no (hidden OPTION candidates) ===")
print(f"  total: {len(cat2)}  across {len(by_type)} cmd_types")
for ct in sorted(by_type):
    lst = by_type[ct]
    print(f"  [{ct}]  {len(lst)}")
    for i, t, cv, cv2 in lst[:12]:
        print(f"      {i}  -> {t}   value={cv}{('/'+cv2) if cv2 else ''}")
    if len(lst) > 12:
        print(f"      ... +{len(lst)-12} more")

# dump the CAT2 + CAT3 to json for further work
out = {
    "cat3_no_layout": [{"id": i, "value": d.get("value")} for i, d in cat3],
    "cat2_hidden_options": [
        {"id": i, "title_id": t, "cmd_type": ct, "cmd_value": cv, "cmd_value2": cv2}
        for i, t, ct, cv, cv2, e in cat2
    ],
    "setsetting_all_ids": sorted(all_by_id.get(i, {}).get("id") for i in []),
}
os.makedirs(os.path.join(HERE, "out"), exist_ok=True)
with open(os.path.join(HERE, "out", "menu_map.json"), "w") as f:
    json.dump(out, f, ensure_ascii=False, indent=2)
print()
print("wrote out/menu_map.json")
