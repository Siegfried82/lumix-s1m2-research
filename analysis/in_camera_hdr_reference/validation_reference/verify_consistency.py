"""Independent geometric roundtrip and signed/HDR observation regressions."""
from graph import torch,BASE
from geometry import tile_coordinates
from reconstruction_consistency import inverse_coordinates,project,enforce_consistency
from alignment import sample
import json

def main():
    torch.set_num_threads(4);checks={};details={}
    y,x=torch.meshgrid(torch.arange(48),torch.arange(48),indexing='ij')
    flows=torch.zeros(7,2,48,48)
    for k in range(1,7):
        flows[k,0]=.16*k+.03*torch.sin(x*.13)
        flows[k,1]=-.09*k+.02*torch.cos(y*.11)
    H=torch.eye(3).repeat(7,1,1)
    for k in range(1,7):H[k]=torch.tensor([[1.001,.002,k*.21],[-.001,.999,-k*.17],[.00002,-.00001,1.]])
    native=32;origin=(12,14);q=tile_coordinates(flows,H,native,origin)
    yy,xx=torch.meshgrid(torch.arange(64),torch.arange(64),indexing='ij')
    expected=torch.stack((xx*.5+origin[0],yy*.5+origin[1]),-1)
    for mode,lca in [('plain',None),('lca',dict(coefficients_rgb=[.003,0,-.002],center_native_xy=[48,48]))]:
        q=tile_coordinates(flows,H,native,origin,lca);errors=[]
        for k in range(7):
            for c in range(q.shape[1]):
                recovered,valid=inverse_coordinates(q[k,c],c,H[k],flows[k],lca,k==0)
                errors.append(float((recovered-expected).abs().max()))
                checks[f'{mode}_{k}_{c}_converged']=bool(valid.all())
        details[mode+'_max_native_roundtrip_error']=max(errors)
        checks[mode+'_geometric_roundtrip']=max(errors)<2e-5
    # Fully observed signed/HDR image: fit calibrated measurements, not [0,1].
    truth=torch.tensor([-.3,0.,.8,1.4,2.2])
    index=torch.arange(5)[:,None].repeat(1,4);weight=torch.zeros(5,4);weight[:,0]=1
    result,report=project(truth+.4,index,weight,truth,torch.ones(5),regularization=.03)
    checks['observations_improve']=report['weighted_error_after']<report['weighted_error_before']*.002
    checks['negative_preserved']=float(result[0])<0
    checks['hdr_preserved']=float(result[-1])>2
    # Saturated/invalid bank offers no justified correction.
    prior=torch.full((1,3,8,8),1.7);bank=torch.zeros(4,7,4,4)
    metadata=torch.zeros(7,17);metadata[:,0]=1;metadata[:,1:5]=torch.tensor([0,1,2,3]);metadata[:,5:9]=1
    output,report=enforce_consistency(prior,bank,torch.zeros(7,2),metadata,flows,H,(0,0))
    checks['no_observations_preserve_prior']=torch.equal(prior,output) and report['observations']==0
    # Independently known smooth scene, subpixel translated Bayer observations,
    # exposure variation and each of the four Bayer layouts.
    yy,xx=torch.meshgrid(torch.arange(32),torch.arange(32),indexing='ij')
    scene=torch.stack((-.2+.018*xx,.2+.02*yy,1.2+.01*(xx+yy)))[None]
    sy,sx=torch.meshgrid(torch.arange(12),torch.arange(12),indexing='ij')
    source=torch.stack((sx,sy),-1).float();phase=(sy%2)*2+sx%2
    f=torch.zeros(7,2,16,16);matrices=torch.eye(3).repeat(7,1,1)
    for k in range(1,7):matrices[k,0,2]=k*.08;matrices[k,1,2]=-k*.06
    for pattern in ((0,1,2,3),(3,2,1,0),(1,0,3,2),(2,3,0,1)):
        md=torch.zeros(7,17);md[:,0]=torch.tensor([1.,.5,.7,1.2,.9,.6,1.1])
        md[:,1:5]=torch.tensor(pattern);md[:,5:9]=5;md[:,9:13]=-5;md[:,14]=.0001
        b=torch.zeros(4,7,12,12);b[1]=1
        for k in range(7):
            coord=(source-matrices[k,:2,2])*2;rgb=sample(scene,coord)[0]
            for plane,c in enumerate((0,1,1,2)):
                mask=phase==pattern[plane];b[0,k][mask]=rgb[c][mask]*md[k,0]
        result,report=enforce_consistency(scene+.25,b,torch.zeros(7,2),md,f,matrices,(0,0))
        # Only test observed central region; unobserved pixels retain the prior.
        before=float((scene[:,:,:22,:22]+.25-scene[:,:,:22,:22]).square().mean())
        after=float((result[:,:,:22,:22]-scene[:,:,:22,:22]).square().mean())
        # This sparse burst does not observe every RGB lattice site. Require
        # scene improvement as well as an accurate fit at the actual samples.
        checks['bayer_'+''.join(map(str,pattern))+'_scene_improved']=after<before*.8
        checks['bayer_'+''.join(map(str,pattern))+'_observations_fit']=report['weighted_error_after']<report['weighted_error_before']*.002
        details['bayer_'+''.join(map(str,pattern))+'_rmse_ratio']=(after/before)**.5
    r=dict(checks=checks,details=details,all_passed=all(checks.values()))
    (BASE/'consistency_verification.json').write_text(json.dumps(r,indent=2)+'\n');print(json.dumps(r,indent=2));assert r['all_passed']

if __name__=='__main__':main()
