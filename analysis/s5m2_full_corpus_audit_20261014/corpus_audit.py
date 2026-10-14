"""A+B: offline S5M2 corpus inventory, strict UPD parsing and literal byte differences."""
import argparse
import hashlib
import json
import mmap
import os
import re
import struct
import zipfile
import zlib
from collections import Counter, defaultdict
from contextlib import ExitStack
from pathlib import Path, PurePosixPath

HERE = Path(__file__).resolve().parent
BASE, COUNT_AT, DIR_AT, ENTRY = 0x200, 0x2E8, 0x2EC, 92
FILENAME = re.compile(r"^S5m2(?P<x>X)?_?V(?P<v>\d+)(?: \(\d+\))?\.(?P<kind>bin|zip)$", re.I)
def sha(data):
    return hashlib.sha256(data).hexdigest()
def file_sha(path):
    h = hashlib.sha256()
    with Path(path).open("rb") as f:
        for b in iter(lambda: f.read(1024*1024), b""):
            h.update(b)
    return h.hexdigest()
def write_new(path, obj):
    path = Path(path)
    path.parent.mkdir(parents=True, exist_ok=True)
    with path.open("x", encoding="utf-8", newline="\n") as f:
        json.dump(obj, f, ensure_ascii=False, indent=2)
        f.write("\n")
def identify(name):
    m = FILENAME.fullmatch(Path(name).name)
    if not m:
        return None
    return f"S5M2{'X' if m['x'] else ''}_V{m['v']}"
def u32(data, off):
    return struct.unpack_from("<I", data, off)[0]
def constant_kind(blob):
    if not blob:
        return "empty"
    if blob.count(0) == len(blob):
        return "all_00"
    if blob.count(255) == len(blob):
        return "all_ff"
    return "nonconstant"
def parse_upd(data):
    if len(data) < DIR_AT:
        raise ValueError("Truncated header")
    if data[:4] != b"UPD\0" or data[0x2A0:0x2A4] != b"UPD\0":
        raise ValueError("UPD magic mismatch")
    if u32(data,4)!=BASE:
        raise ValueError("Unsupported header size")
    if u32(data, 8) != 0x200 or u32(data, 0x34) != 3:
        raise ValueError("Unsupported revision/selector")
    if u32(data, 0x3C) != len(data)-BASE:
        raise ValueError("Declared image length mismatch")
    crc = zlib.crc32(memoryview(data)[BASE:]) & 0xFFFFFFFF
    if u32(data, 0x40) != crc:
        raise ValueError("CRC32 mismatch")
    count = u32(data, COUNT_AT)
    end = DIR_AT + count*ENTRY
    if not 0 < count <= 4096 or end > len(data):
        raise ValueError("Directory count/range invalid")
    model = data[12:28].split(b"\0",1)[0].decode("ascii")
    rows, ranges, occurrences = [], [], Counter()
    for idx in range(count):
        pos = DIR_AT + idx*ENTRY
        name = data[pos:pos+12].split(b"\0",1)[0].decode("ascii")
        if not name or any(ord(c)<32 or ord(c)>126 for c in name):
            raise ValueError("Invalid component name")
        rel, size, target, flags = struct.unpack_from("<4I", data, pos+12)
        absolute = BASE + rel
        if flags not in (2,3):
            raise ValueError("Unsupported flags")
        if absolute < end or absolute > len(data) or absolute+size > len(data):
            raise ValueError(f"Component {idx} range invalid")
        payload = data[absolute:absolute+size]
        occurrence = occurrences[name]
        occurrences[name] += 1
        candidate, raw = data[pos+28:pos+60].hex(), sha(payload)
        rows.append({"index":idx, "name":name, "occurrence":occurrence,
            "identity":f"{name}#{occurrence}", "entry_offset":pos,
            "relative_offset":rel, "absolute_offset":absolute, "size":size,
            "destination_field":target, "flags":flags,
            "directory_digest":candidate, "raw_sha256":raw,
            "raw_matches_directory_digest":raw==candidate,
            "tail_candidate_16":data[pos+60:pos+76].hex(),
            "tail_remaining_16":data[pos+76:pos+92].hex(),
            "constant_content":constant_kind(payload), "in_bounds":True})
        if size:
            ranges.append((absolute,absolute+size,idx))
    ranges.sort()
    if any(a[1]>b[0] for a,b in zip(ranges,ranges[1:])):
        raise ValueError("Nonempty components overlap")
    return {"bytes":len(data), "sha256":sha(data), "model":model,
        "revision":u32(data,8), "selector":u32(data,0x34),
        "crc32":f"{crc:08x}", "directory_count":count, "directory_end":end,
        "payload_start":ranges[0][0] if ranges else None,
        "payload_end":ranges[-1][1] if ranges else None,
        "payload_contiguous":all(a[1]==b[0] for a,b in zip(ranges,ranges[1:])),
        "flags_counts":dict(Counter(str(r["flags"]) for r in rows)),
        "all_ranges_valid":True,
        "auth_candidate_64":data[0x220:0x260].hex(),
        "header_version_raw_16":data[0x1C:0x2C].hex(),
        "rows":rows}
def validate_profile(image, profile):
    for field in ("bytes","sha256","model","directory_count"):
        if image[field] != profile[field]:
            raise ValueError("Profile mismatch: "+field)
def open_map(stack, path):
    stream = stack.enter_context(Path(path).open("rb"))
    return stack.enter_context(mmap.mmap(stream.fileno(),0,access=mmap.ACCESS_READ))
def discover(roots):
    found, seen = [], set()
    for label in ("projects","desktop","downloads"):
        root = Path(roots[label])
        if not root.is_dir():
            raise ValueError("Search root missing: "+label)
        for directory, dirs, names in os.walk(root, followlinks=False):
            dirs[:] = [n for n in dirs if n not in {".git",".tools","node_modules","__pycache__"}]
            for name in names:
                item_id = identify(name)
                if not item_id:
                    continue
                path = Path(directory)/name
                if path.is_symlink():
                    continue
                canonical = str(path.resolve()).casefold()
                if canonical in seen:
                    continue
                seen.add(canonical)
                found.append((label+":"+path.relative_to(root).as_posix(),path,item_id))
    return sorted(found)
def asset_record(source_ref, path, item_id, profiles):
    kind = path.suffix.lower()
    record = {"source_ref":source_ref,"id":item_id,"kind":kind,
              "asset_bytes":path.stat().st_size,"asset_sha256":file_sha(path)}
    if kind==".bin":
        record.update(bin_sha256=record["asset_sha256"],bin_bytes=record["asset_bytes"])
    else:
        with zipfile.ZipFile(path) as z:
            entries = [m for m in z.infolist() if not m.is_dir()]
            names = [m.filename for m in entries]
            if len(names)!=len(set(names)):
                raise ValueError("Duplicated ZIP member")
            for name in names:
                p = PurePosixPath(name)
                if p.is_absolute() or ".." in p.parts or "\\" in name:
                    raise ValueError("Unsafe ZIP member name")
            bins = [m for m in entries if m.filename.lower().endswith(".bin")]
            if len(bins)!=1 or identify(bins[0].filename)!=item_id:
                raise ValueError("ZIP BIN identity/count mismatch")
            info=bins[0]; h=hashlib.sha256(); total=0
            with z.open(info) as f:
                for block in iter(lambda:f.read(1024*1024),b""):
                    h.update(block); total+=len(block)
            if total!=info.file_size:
                raise ValueError("ZIP member short read")
            record.update(bin_sha256=h.hexdigest(),bin_bytes=total,member=info.filename,
                zip_member_crc32=f"{info.CRC:08x}",zip_member_crc_verified=True,
                other_members_not_read=[n for n in names if n!=info.filename])
    profile=profiles.get(item_id)
    record["in_profile_scope"]=profile is not None
    if profile:
        if record["bin_sha256"]!=profile["sha256"] or record["bin_bytes"]!=profile["bytes"]:
            raise ValueError("BIN identity does not match pinned profile")
    return record
def indexed(image):
    rows=image["rows"]
    result={r["identity"]:r for r in rows}
    if len(result)!=len(rows):
        raise ValueError("Repeated component identity")
    return result
def byte_difference(a,b,oa,ob,size):
    different=0
    for at in range(0,size,65536):
        n=min(65536,size-at)
        x=int.from_bytes(a[oa+at:oa+at+n],"little")^int.from_bytes(b[ob+at:ob+at+n],"little")
        different+=n-x.to_bytes(n,"little").count(0)
    return different
def compare(left,right,a=None,b=None):
    lm,rm=indexed(left),indexed(right)
    rows=[]
    for identity in sorted(lm.keys()&rm.keys()):
        l,r=lm[identity],rm[identity]
        same_size=l["size"]==r["size"]
        difference=byte_difference(a,b,l["absolute_offset"],r["absolute_offset"],l["size"]) if a is not None and b is not None and same_size else None
        raw_same=l["raw_sha256"]==r["raw_sha256"]
        if difference is not None and (difference==0)!=raw_same:
            raise ValueError("Byte comparison/hash disagreement")
        rows.append({"identity":identity,"left_index":l["index"],"right_index":r["index"],
            "left_size":l["size"],"right_size":r["size"],"left_flags":l["flags"],"right_flags":r["flags"],
            "left_absolute_offset":l["absolute_offset"],"right_absolute_offset":r["absolute_offset"],
            "digest_changed":l["directory_digest"]!=r["directory_digest"],
            "tail16_changed":l["tail_candidate_16"]!=r["tail_candidate_16"],
            "tail12_prefix_changed":l["tail_candidate_16"][:24]!=r["tail_candidate_16"][:24],
            "remaining16_changed":l["tail_remaining_16"]!=r["tail_remaining_16"],
            "raw_changed":not raw_same,"size_same":same_size,"raw_differing_bytes":difference,
            "destination_changed":l["destination_field"]!=r["destination_field"],
            "layout_same":all(l[k]==r[k] for k in ("index","absolute_offset","size","destination_field","flags")),
            "both_flags3":l["flags"]==r["flags"]==3})
    classes=Counter((r["digest_changed"],r["tail16_changed"],r["raw_changed"]) for r in rows)
    def changed(field):
        return [r["identity"] for r in rows if r[field]]
    return {"left":left["id"],"right":right["id"],"common_count":len(rows),
        "added":sorted(rm.keys()-lm.keys()),"removed":sorted(lm.keys()-rm.keys()),
        "same_layout":len(lm)==len(rm) and all(r["layout_same"] for r in rows),
        "digest_changed":changed("digest_changed"),"tail16_changed":changed("tail16_changed"),
        "raw_changed":changed("raw_changed"),
        "same_digest_tail_changed_raw_changed":[r["identity"] for r in rows if not r["digest_changed"] and r["tail16_changed"] and r["raw_changed"]],
        "flags3_same_digest_tail_changed_raw_changed":[r["identity"] for r in rows if r["both_flags3"] and not r["digest_changed"] and r["tail16_changed"] and r["raw_changed"]],
        "same_digest_same_tail_raw_changed":[r["identity"] for r in rows if not r["digest_changed"] and not r["tail16_changed"] and r["raw_changed"]],
        "tail12_vs16_disagreements":[r["identity"] for r in rows if r["tail16_changed"]!=r["tail12_prefix_changed"]],
        "classification_counts":{f"digest_changed={k[0]},tail16_changed={k[1]},raw_changed={k[2]}":v for k,v in sorted(classes.items())},
        "rows":rows}
def delta_stats(maps,offsets,sizes):
    if len(set(sizes))!=1:
        return None
    size=sizes[0]; active=equal=active_blocks=equal_blocks=0
    for at in range(0,size,65536):
        n=min(65536,size-at)
        v=[int.from_bytes(m[o+at:o+at+n],"little") for m,o in zip(maps,offsets)]
        x,y=v[0]^v[1],v[2]^v[3]
        inactive=(x|y).to_bytes(n,"little").count(0)
        active+=n-inactive
        equal+=(x^y).to_bytes(n,"little").count(0)-inactive
        if inactive!=n:
            active_blocks+=1
            equal_blocks+=x==y
    return {"bytes":size,"active_delta_bytes":active,"equal_delta_bytes_within_active":equal,
            "equal_delta_ratio_within_active":equal/active if active else None,
            "active_64k_blocks":active_blocks,"exactly_equal_delta_64k_blocks":equal_blocks}
def fourway(images,maps):
    roles=["S5M2_V34","S5M2_V37","S5M2X_V24","S5M2X_V27"]
    tables=[indexed(images[k]) for k in roles]
    rows=[]
    for identity in sorted(set.intersection(*(set(t) for t in tables))):
        p=[t[identity] for t in tables]
        rows.append({"identity":identity,"indices":[r["index"] for r in p],
            "offsets":[r["absolute_offset"] for r in p],"sizes":[r["size"] for r in p],
            "digest_changed_s5m2":p[0]["directory_digest"]!=p[1]["directory_digest"],
            "digest_changed_s5m2x":p[2]["directory_digest"]!=p[3]["directory_digest"],
            "tail16_changed_s5m2":p[0]["tail_candidate_16"]!=p[1]["tail_candidate_16"],
            "tail16_changed_s5m2x":p[2]["tail_candidate_16"]!=p[3]["tail_candidate_16"],
            "cross_model_digest_diff_before":p[0]["directory_digest"]!=p[2]["directory_digest"],
            "cross_model_digest_diff_after":p[1]["directory_digest"]!=p[3]["directory_digest"],
            "delta_stats":delta_stats(maps,[r["absolute_offset"] for r in p],[r["size"] for r in p])})
    active=[r for r in rows if r["delta_stats"] and r["delta_stats"]["active_delta_bytes"]]
    total=sum(r["delta_stats"]["active_delta_bytes"] for r in active)
    equal=sum(r["delta_stats"]["equal_delta_bytes_within_active"] for r in active)
    return {"roles":roles,"common_count":len(rows),
        "digest_change_pattern_mismatches":[r["identity"] for r in rows if r["digest_changed_s5m2"]!=r["digest_changed_s5m2x"]],
        "tail16_change_pattern_mismatches":[r["identity"] for r in rows if r["tail16_changed_s5m2"]!=r["tail16_changed_s5m2x"]],
        "cross_model_digest_differences_before":[r["identity"] for r in rows if r["cross_model_digest_diff_before"]],
        "cross_model_digest_differences_after":[r["identity"] for r in rows if r["cross_model_digest_diff_after"]],
        "aggregate_delta":{"active_delta_bytes":total,"equal_delta_bytes_within_active":equal,
            "equal_delta_ratio_within_active":equal/total if total else None,
            "partitions_with_active_delta":len(active),
            "partitions_with_any_exact_equal_delta_block":[r["identity"] for r in active if r["delta_stats"]["exactly_equal_delta_64k_blocks"]]},
        "rows":rows,
        "boundary":"Finite literal byte comparison, not a proof of cipher, plaintext, key scope, shared build tree or impossibility."}
def legacy_view(data, image):
    result=[]
    for r in image["rows"]:
        old_pos=r["entry_offset"]-16
        size,offset,_=struct.unpack_from("<III",data,old_pos+0x20)
        if r["name"]=="boot" and size==0:
            size,offset=struct.unpack_from("<II",data,old_pos+4)
        in_file=offset+size<=len(data)
        result.append({"identity":r["identity"],"index":r["index"],
            "old_absolute_offset":offset,"correct_absolute_offset":r["absolute_offset"],
            "old_size":size,"correct_size":r["size"],"old_in_file":in_file,
            "old_raw_sha256":sha(data[offset:offset+size]) if in_file else None,
            "correct_raw_sha256":r["raw_sha256"],"range_exact":(offset,size)==(r["absolute_offset"],r["size"]),
            "candidate_tail12":data[old_pos+0x4C:old_pos+0x58].hex(),
            "omitted_tail4":r["tail_candidate_16"][24:],
            "old_directory_digest":data[old_pos+0x2C:old_pos+0x4C].hex(),
            "correct_directory_digest":r["directory_digest"]})
    return result
def snapshot_history(roots,out):
    spec=json.loads((HERE/"historical_sources.json").read_text(encoding="utf-8"))
    result=[]
    for row in spec:
        root=Path(roots["projects"])
        src=root/row["relative_path"]
        resolved=src.resolve()
        if not resolved.is_relative_to(root.resolve()):
            raise ValueError("Historical source escaped root")
        data=src.read_bytes()
        target=out/"historical_snapshots"/row["snapshot_name"]
        target.parent.mkdir(exist_ok=True)
        with target.open("xb") as f:
            f.write(data)
        result.append({**row,"source_ref":"projects:"+row["relative_path"],
                       "bytes":len(data),"sha256":sha(data)})
    return result
def audit_legacy_results(history, out, images, legacy, comparisons):
    by_sha={v["sha256"]:k for k,v in images.items()}
    records=[]
    for src in history:
        if not src["snapshot_name"].endswith(".json"):
            continue
        obj=json.loads((out/"historical_snapshots"/src["snapshot_name"]).read_text(encoding="utf-8"))
        prior_images=obj.get("images",[])
        if "left" in obj and isinstance(obj["left"],dict):
            prior_images=[obj["left"],obj["right"]]
        image_records=[]
        for old in prior_images:
            item_id=by_sha.get(old.get("sha256"))
            if not item_id:
                continue
            correct=indexed(images[item_id]); old_rows=old.get("partitions",old.get("entries",[]))
            if not isinstance(old_rows,list) or not old_rows:
                continue
            counts=Counter(); mismatches=[]; occurrence=Counter()
            for r in old_rows:
                name=r["name"]; identity=r.get("identity",f"{name}#{occurrence[name]}"); occurrence[name]+=1
                current=correct.get(identity)
                if not current:
                    mismatches.append({"identity":identity,"field":"missing_identity"}); continue
                if "entries" in old:
                    pairs={"size":"size","flags":"flags","absolute_offset":"absolute_offset",
                           "stored_sha256":"directory_digest","raw_sha256":"raw_sha256","iv":"tail_candidate_16"}
                else:
                    pairs={"size":"size","flags":"flags","offset":"absolute_offset","digest":"directory_digest",
                           "nonce":"tail_prefix12","stored_sha256":"raw_sha256","image_sha256":"raw_sha256"}
                for oldkey,newkey in pairs.items():
                    if oldkey not in r:
                        continue
                    actual=current["tail_candidate_16"][:24] if newkey=="tail_prefix12" else current[newkey]
                    # Empty legacy image_sha256 was omitted in one early tool; explicitly record, do not excuse.
                    equal=r[oldkey]==actual
                    counts[oldkey+"_equal" if equal else oldkey+"_different"]+=1
                    if not equal:
                        mismatches.append({"identity":identity,"field":oldkey,"old":r[oldkey],"correct":actual})
            image_records.append({"id":item_id,"old_rows":len(old_rows),"correct_rows":len(correct),
                                  "field_counts":dict(counts),"mismatches":mismatches})
        pair_records=[]
        for p in obj.get("comparisons",[]):
            left,right=identify(p.get("left","")),identify(p.get("right",""))
            current=next((v for v in comparisons if v["left"]==left and v["right"]==right),None)
            if current is None:
                continue
            checks={}
            for oldkey,newkey in (("changed_partition_digests","digest_changed"),
                                  ("changed_partition_nonces","tail16_changed"),
                                  ("unchanged_digest_changed_nonce_changed_blob","same_digest_tail_changed_raw_changed")):
                if oldkey in p:
                    checks[oldkey]={"old_count":len(p[oldkey]),"correct_count":len(current[newkey]),
                        "same_identity_set":set(p[oldkey])==set(current[newkey]),
                        "old_only":sorted(set(p[oldkey])-set(current[newkey])),
                        "correct_only":sorted(set(current[newkey])-set(p[oldkey]))}
            if checks:
                pair_records.append({"left":left,"right":right,"checks":checks})
        records.append({"source":src["snapshot_name"],"source_sha256":src["sha256"],
                        "images":image_records,"comparisons":pair_records})
    return {"records":records,"replayed_wrong_ranges":legacy,
            "boundary":"Original tools not executed. Wrong offset formula reproduced independently on pinned BINs; historical snapshots preserved."}
def main():
    p=argparse.ArgumentParser(description=__doc__)
    p.add_argument("--roots",type=Path,required=True)
    p.add_argument("--output",type=Path,required=True)
    args=p.parse_args()
    out=args.output
    if out.exists():
        raise ValueError("Output already exists")
    out.mkdir(parents=True)
    roots=json.loads(args.roots.read_text(encoding="utf-8"))
    profiles=json.loads((HERE/"corpus_profiles.json").read_text(encoding="utf-8"))["images"]
    found=discover(roots); assets=[]; errors=[]; raw_paths={}
    for ref,path,item_id in found:
        try:
            row=asset_record(ref,path,item_id,profiles)
            assets.append(row)
            if row["in_profile_scope"] and row["kind"]==".bin":
                raw_paths.setdefault(item_id,[]).append((ref,path))
        except Exception as e:
            errors.append({"source_ref":ref,"id":item_id,"type":type(e).__name__,"error":str(e)})
    groups=[]
    for item_id,profile in profiles.items():
        aliases=[r for r in assets if r["id"]==item_id and r["in_profile_scope"]]
        groups.append({"id":item_id,"expected_sha256":profile["sha256"],
                       "assets":len(aliases),"bin_sources":sum(r["kind"]==".bin" for r in aliases),
                       "zip_sources":sum(r["kind"]==".zip" for r in aliases)})
        if item_id not in raw_paths:
            errors.append({"id":item_id,"error":"No matching standalone BIN; no extraction attempted"})
    write_new(out/"inventory.json",{"search_roots":list(roots),"search_scope":"Filename discovery in projects/desktop/downloads; skip symlinks and tool/cache directories.",
        "assets":assets,"groups":groups,"errors":errors,"unique_profile_bins":len(raw_paths),
        "boundaries":["Local snapshot identities, not cryptographic authenticity or original download provenance.",
                      "ZIP CRC verified on the BIN member; other members not read.","No original moved, changed, extracted or executed."]})
    if errors:
        raise ValueError("Inventory errors recorded; stopped before corpus/diff")
    history=snapshot_history(roots,out)
    write_new(out/"historical_sources.json",history)
    images={}; paths={}; legacy={}
    for item_id,profile in profiles.items():
        ref,path=sorted(raw_paths[item_id])[0]
        with ExitStack() as stack:
            data=open_map(stack,path)
            image=parse_upd(data);validate_profile(image,profile)
            image.update(id=item_id,source_ref=ref,version_label=profile["version_label"],
                         provenance=profile["provenance"])
            legacy[item_id]=legacy_view(data,image)
        images[item_id]=image;paths[item_id]=path
        print(json.dumps({"id":item_id,"count":image["directory_count"],"crc32":image["crc32"],"all_ranges_valid":True}),flush=True)
    write_new(out/"corpus.json",{"images":images,"semantics":"Directory digest, flags and tail are observations; no plaintext/IV/signature semantics established."})
    order=["11","20","22","31","32","33","34","37"]
    pairs=[("S5M2_V"+a,"S5M2_V"+b,"adjacent_s5m2") for a,b in zip(order,order[1:])]
    pairs += [("S5M2X_V24","S5M2X_V27","adjacent_s5m2x"),
              ("S5M2_V34","S5M2X_V24","same_generation_cross_model"),
              ("S5M2_V37","S5M2X_V27","same_generation_cross_model")]
    for a,b in [("20","31"),("31","37"),("32","37"),("33","37")]:
        pairs.append(("S5M2_V"+a,"S5M2_V"+b,"historical_bridge"))
    comparisons=[]
    for left,right,kind in pairs:
        with ExitStack() as stack:
            a,b=open_map(stack,paths[left]),open_map(stack,paths[right])
            report=compare(images[left],images[right],a,b)
        report["kind"]=kind;comparisons.append(report)
    write_new(out/"comparisons.json",{"pairing":"name plus occurrence in directory order; retain both indices. Pairing is not proof of semantic module equivalence.",
                                    "comparisons":comparisons})
    with ExitStack() as stack:
        maps=[open_map(stack,paths[k]) for k in ("S5M2_V34","S5M2_V37","S5M2X_V24","S5M2X_V27")]
        four=fourway(images,maps)
    write_new(out/"fourway.json",four)
    audit=audit_legacy_results(history,out,images,legacy,comparisons)
    oldfour=json.loads((out/"historical_snapshots"/"locator_fourway.json").read_text(encoding="utf-8"))
    audit["fourway_old_vs_correct"]={"old":oldfour["aggregate_delta"],"correct":four["aggregate_delta"]}
    write_new(out/"legacy_audit.json",audit)
    print(json.dumps({"inventory_assets":len(assets),"profile_images":len(images),
        "total_directory_entries":sum(v["directory_count"] for v in images.values()),
        "comparisons":len(comparisons),"fourway_active_bytes":four["aggregate_delta"]["active_delta_bytes"],
        "all_success":True}),flush=True)
if __name__=="__main__":
    main()
