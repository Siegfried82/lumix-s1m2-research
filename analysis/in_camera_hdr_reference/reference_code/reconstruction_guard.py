"""Calibrated RAW radiance envelope for unsupported neural overshoot.

This is a Mac robustness addition, not a recovered original-client stage.
No blur, display clipping or range-to-[0,1] conversion is performed.
"""
from graph import torch

@torch.inference_mode()
def radiance_envelope(bank,coordinates,metadata,sigma=3.):
    _,k,h,w=bank.shape;o=coordinates.shape[-2]
    low=torch.full((1,3,o,o),torch.inf,device=bank.device)
    high=torch.full_like(low,-torch.inf);count=torch.zeros_like(low);uncertainty=torch.zeros_like(low)
    # Four enclosing samples from each of R/Gr/Gb/B, in native Bayer coordinates.
    for frame in range(k):
        e=metadata[frame,0];a,b,c,d=metadata[frame,13:17]
        for plane,colour in enumerate((0,1,1,2)):
            q=coordinates[frame,0 if coordinates.shape[1]==1 else colour]
            phase=metadata[frame,1+plane].long();px,py=phase%2,phase//2
            cell=((q-torch.stack((px,py)))*.5).floor().long()
            for t in range(4):
                ij=cell+torch.tensor((t%2,t//2),device=bank.device)
                x,y=ij[...,0]*2+px,ij[...,1]*2+py
                cx,cy=x.clamp(0,w-1),y.clamp(0,h-1)
                raw=bank[0,frame,cy,cx]
                valid=(x>=0)&(y>=0)&(x<w)&(y<h)&(bank[1,frame,cy,cx]>0)
                valid &= (bank[2,frame,cy,cx]<=0)&(bank[3,frame,cy,cx]<=0)&(raw<metadata[frame,5+plane])&(raw>metadata[frame,9+plane])
                signal=raw/e;z=raw.clamp_min(0)
                margin=sigma*torch.sqrt((a*z+b+c+d*z*z).clamp_min(0))/e
                low[0,colour]=torch.minimum(low[0,colour],torch.where(valid,signal-margin,torch.inf))
                high[0,colour]=torch.maximum(high[0,colour],torch.where(valid,signal+margin,-torch.inf))
                count[0,colour]+=valid
                uncertainty[0,colour]=torch.maximum(uncertainty[0,colour],torch.where(valid,margin,0))
    return low,high,count,uncertainty

@torch.inference_mode()
def guard_prediction(prediction,bank,coordinates,metadata,base=None):
    low,high,count,uncertainty=radiance_envelope(bank,coordinates,metadata)
    if base is not None:
        # One native-pixel neighborhood on the 2x output lattice. Restrict newly
        # invented extrema, without filtering the learned detail inside bounds.
        F=torch.nn.functional
        padded=F.pad(base,(2,2,2,2),mode='replicate')
        physical_high=F.max_pool2d(padded,5,stride=1)+uncertainty
        physical_low=-F.max_pool2d(-padded,5,stride=1)-uncertainty
        low=torch.maximum(low,physical_low);high=torch.minimum(high,physical_high)
        # Numerical/mismatched bounds do not justify fabricating a value.
        count=torch.where(low<=high,count,0)
    supported=count>=2
    corrected=torch.where(supported,torch.maximum(low,torch.minimum(prediction,high)),prediction)
    return corrected,(corrected!=prediction)
