"""Read-only before/after DAT comparison; reports changes, not field semantics."""
from pathlib import Path
import argparse, hashlib, json


def compare(before, after):
    result = dict(before_size=len(before), after_size=len(after),
                  before_sha256=hashlib.sha256(before).hexdigest(),
                  after_sha256=hashlib.sha256(after).hexdigest(),
                  same_size=len(before)==len(after),
                  byte_sum_mod256=[sum(before)%256, sum(after)%256])
    ranges=[]; start=None; changed=0
    for i in range(max(len(before),len(after))):
        different=i>=min(len(before),len(after)) or before[i]!=after[i]
        if different:
            changed+=1
            if start is None: start=i
        elif start is not None:
            ranges.append(dict(start=start,end_exclusive=i,length=i-start));start=None
    if start is not None:
        ranges.append(dict(start=start,end_exclusive=max(len(before),len(after)),length=max(len(before),len(after))-start))
    result.update(changed_bytes=changed,changed_ranges=ranges)
    slots=[]
    # Historical hypothesis only. Do not apply if model/header or total size differs.
    if len(before)==len(after)==9197409 and b'DC-S1M2' in before[:64] and b'DC-S1M2' in after[:64]:
        for i in range(41):
            s=0x4ae88+8+i*215632;e=s+215632
            x=before[s:e];y=after[s:e]
            slots.append(dict(candidate_slot=i,start=s,end_exclusive=e,
                              changed_bytes=sum(a!=b for a,b in zip(x,y)),
                              before_sha256=hashlib.sha256(x).hexdigest(),
                              after_sha256=hashlib.sha256(y).hexdigest()))
    result['historical_candidate_blocks']=slots
    result['boundary']='Offsets are file-relative. Candidate slot mapping is unverified; size changes may shift data. Byte-sum is arithmetic only, not acceptance proof.'
    return result

if __name__=='__main__':
    ap=argparse.ArgumentParser(description=__doc__)
    ap.add_argument('before',type=Path);ap.add_argument('after',type=Path)
    a=ap.parse_args()
    print(json.dumps(compare(a.before.read_bytes(),a.after.read_bytes()),indent=2))
