"""Independent consistency checks for generated evidence and unchanged original files."""
import argparse
import json
from collections import Counter
from pathlib import Path
from corpus_audit import file_sha
HERE=Path(__file__).resolve().parent
def check(value,message):
    if not value:raise ValueError(message)
def original_path(ref,roots):
    key,rel=ref.split(":",1)
    root=Path(roots[key]).resolve();target=(root/rel).resolve()
    check(target.is_relative_to(root),"Source ref escaped root")
    return target
def main():
    p=argparse.ArgumentParser()
    p.add_argument("--results",type=Path,required=True)
    p.add_argument("--roots",type=Path,required=True)
    a=p.parse_args();r=a.results
    roots=json.loads(a.roots.read_text(encoding="utf-8"))
    profiles=json.loads((HERE/"corpus_profiles.json").read_text(encoding="utf-8"))["images"]
    inv=json.loads((r/"inventory.json").read_text(encoding="utf-8"))
    images=json.loads((r/"corpus.json").read_text(encoding="utf-8"))["images"]
    comparisons=json.loads((r/"comparisons.json").read_text(encoding="utf-8"))["comparisons"]
    history=json.loads((r/"historical_sources.json").read_text(encoding="utf-8"))
    legacy=json.loads((r/"legacy_audit.json").read_text(encoding="utf-8"))
    four=json.loads((r/"fourway.json").read_text(encoding="utf-8"))
    check(not inv["errors"],"Inventory errors")
    check(set(images)==set(profiles),"Profile set differs")
    total=0
    for key,img in images.items():
        profile=profiles[key];rows=img["rows"];total+=len(rows)
        for field in ("bytes","sha256","model","directory_count"):
            check(img[field]==profile[field],key+" "+field)
        check(len(rows)==img["directory_count"],"Count differs")
        check(len({v["identity"] for v in rows})==len(rows),"Duplicate identity")
        for idx,v in enumerate(rows):
            check(v["index"]==idx,"Index not preserved")
            check(v["absolute_offset"]==512+v["relative_offset"],"Bad base")
            check(img["directory_end"]<=v["absolute_offset"]<=img["bytes"] and v["absolute_offset"]+v["size"]<=img["bytes"],"Bad range")
            check(len(v["tail_candidate_16"])==32 and len(v["tail_remaining_16"])==32,"Tail truncated")
            check(v["raw_matches_directory_digest"]==(v["raw_sha256"]==v["directory_digest"]),"Wrong digest equality")
        if img["payload_end"] is not None:check(img["payload_end"]<=img["bytes"],"Payload beyond EOF")
    for c in comparisons:
        l={v["identity"]:v for v in images[c["left"]]["rows"]}
        rr={v["identity"]:v for v in images[c["right"]]["rows"]}
        check(c["common_count"]==len(l.keys()&rr.keys())==len(c["rows"]),"Common count")
        check(set(c["added"])==rr.keys()-l.keys() and set(c["removed"])==l.keys()-rr.keys(),"Added/removed")
        check(sum(c["classification_counts"].values())==len(c["rows"]),"Classification total")
        for row in c["rows"]:
            x,y=l[row["identity"]],rr[row["identity"]]
            for field,source in (("digest_changed","directory_digest"),("tail16_changed","tail_candidate_16"),("raw_changed","raw_sha256")):
                check(row[field]==(x[source]!=y[source]),"Wrong equality predicate")
            diff=row["raw_differing_bytes"]
            if x["size"]==y["size"]:
                check(isinstance(diff,int) and 0<=diff<=x["size"],"Difference count invalid")
                check((diff==0)==(not row["raw_changed"]),"Literal bytes/hash disagreement")
            else:check(diff is None,"Unequal sizes received byte count")
    aggregate=four["aggregate_delta"];parts=[v["delta_stats"] for v in four["rows"] if v["delta_stats"]]
    check(aggregate["active_delta_bytes"]==sum(v["active_delta_bytes"] for v in parts),"Fourway active")
    check(aggregate["equal_delta_bytes_within_active"]==sum(v["equal_delta_bytes_within_active"] for v in parts),"Fourway equal")
    for v in parts:check(0<=v["equal_delta_bytes_within_active"]<=v["active_delta_bytes"]<=v["bytes"],"Fourway bounds")
    correct=[rec for rec in legacy["records"] if rec["source"].startswith("correct_")]
    check(len(correct)==4 and all(not img["mismatches"] for rec in correct for img in rec["images"]),"Previously correct readers no longer agree")
    for row in inv["assets"]:
        check(file_sha(original_path(row["source_ref"],roots))==row["asset_sha256"],"Original asset changed: "+row["source_ref"])
    for row in history:
        check(file_sha(original_path(row["source_ref"],roots))==row["sha256"],"Original history changed")
        check(file_sha(r/"historical_snapshots"/row["snapshot_name"])==row["sha256"],"Historical snapshot differs")
    print(json.dumps({"images_verified":len(images),"rows_verified":total,"comparisons_verified":len(comparisons),
        "original_assets_unchanged":len(inv["assets"]),"original_historical_sources_unchanged":len(history),
        "previous_correct_jsons_agree":len(correct),"all_passed":True}))
if __name__=="__main__":main()
