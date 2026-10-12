"""Create standards-based Bayer DNGs and exercise the actual LibRaw decoder."""
from raw_input import normalize_sensor,decode_raw,prepare_raws,load_manifest,frame_bank
from graph import np,ROOT
from pathlib import Path
import tifffile,json

def write_dng(path,mosaic,pattern=((0,1),(1,2)),black=(512,512,512,512),white=16383):
    identity=(1,1,0,1,0,1,0,1,1,1,0,1,0,1,0,1,1,1)
    tags=[(271,'s',0,'Synthetic',False),(272,'s',0,'Transformer Mac Test',False),(274,'H',1,1,False),(50706,'B',4,(1,4,0,0),False),(50707,'B',4,(1,1,0,0),False),(50708,'s',0,'Transformer Synthetic CFA',False),(33421,'H',2,(2,2),False),(33422,'B',4,tuple(np.asarray(pattern).ravel()),False),(50713,'H',2,(2,2),False),(50714,'2I',4,tuple(v for b in black for v in (int(b),1)),False),(50717,'I',1,white,False),(50721,'2i',9,identity,False),(50728,'2I',3,(1,1)*3,False),(50778,'H',1,21,False),(33434,'2I',1,(1,100),False),(34855,'H',1,100,False)]
    tifffile.imwrite(path,np.asarray(mosaic,np.uint16),photometric=32803,metadata=None,extratags=tags,compression=None)

def run():
    root=ROOT/'transformer_mac/fixtures/raw';root.mkdir(parents=True,exist_ok=True)
    raw=np.full((70,74),2000,np.uint16);raw[0,0]=500;raw[2,2]=16383
    expected,crop=normalize_sensor(raw,512,16383)
    path=root/'signed.dng';write_dng(path,raw)
    decoded,record=decode_raw(path)
    checks={'decoder_matches_equation':bool(np.allclose(decoded,expected,atol=1e-7)),
        'negative_values_preserved':float(decoded[0,0])<0,
        'above_white_preserved':float(decoded[2,2])>1,
        'trailing_crop_only':decoded.shape==(64,72) and record['crop_xywh']==[0,0,72,64],
        'cfa_phase_order':record['cfa_index']==[0,1,2,3],
        'five_dn_headroom':record['white_headroom_dn']==5 and record['white'][0][0]==16378}
    manifest=prepare_raws([path]*7,root/'prepared',[.01,.002,.003,.004],exposures=[1,2,4,1,.5,2,1])
    bank,meta,data=load_manifest(manifest)
    checks['seven_frame_manifest']=tuple(bank.shape)==(4,7,64,72) and tuple(meta.shape)==(7,17)
    checks['phase_underflow']=bool(np.allclose(meta[:,9:13].numpy(),-512/(16383-5-512)))
    border=frame_bank(decoded,origin=(-2,-4),shape=(64,64))
    checks['padded_validity']=bool((border[1,:4]==0).all() and (border[1,:,:2]==0).all() and (border[1,4:,2:]==1).all())
    alternate=root/'bggr.dng';write_dng(alternate,raw,pattern=((2,1),(1,0)))
    _,alt=decode_raw(alternate);checks['bggr_decode']=alt['cfa_index']==[3,2,1,0]
    report=dict(checks=checks,all_passed=all(checks.values()),scope='Real LibRaw decoding of generated DNG files; no camera photographs supplied.')
    (ROOT/'transformer_mac/raw_verification.json').write_text(json.dumps(report,indent=2)+'\n');print(json.dumps(report,indent=2));assert report['all_passed']
if __name__=='__main__':run()
