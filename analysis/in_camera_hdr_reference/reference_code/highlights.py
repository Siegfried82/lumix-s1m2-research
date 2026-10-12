"""Original shortest-frame censoring lower-bound guard, recovered WGSL equations."""
from graph import torch

@torch.inference_mode()
def guard_fully_clipped(bank,coordinates,metadata,prediction,shortest):
    _,k,h,w=bank.shape;o=prediction.shape[-1];device=bank.device
    bounds=torch.zeros((3,o,o),device=device);possible=torch.ones((o,o),device=device,dtype=torch.bool)
    def observation(frame,colour,dx,dy):
        cc=0 if coordinates.shape[1]==1 else colour;q=coordinates[frame,cc];cell=q.floor().long()
        x,y=cell[...,0]+dx,cell[...,1]+dy;cx,cy=x.clamp(0,w-1),y.clamp(0,h-1)
        valid=(x>=0)&(y>=0)&(x<w)&(y<h)&(bank[1,frame,cy,cx]>0)
        phase=(cy%2)*2+cx%2;planes=torch.argsort(metadata[frame,1:5]).long();plane=planes[phase]
        samplecolour=torch.where(phase==metadata[frame,1],0,torch.where(phase==metadata[frame,4],2,1))
        raw=bank[0,frame,cy,cx];white=metadata[frame,5+plane];flag=bank[2,frame,cy,cx]>0
        return valid,samplecolour==colour,raw,white,flag
    for colour in range(3):
        bound=torch.full((o,o),3.402823e38,device=device);seen=torch.zeros_like(possible)
        for dy in range(2):
            for dx in range(2):
                valid,matching,raw,white,flag=observation(shortest,colour,dx,dy)
                possible &= valid & (~matching | flag | (raw>=white))
                bound=torch.where(matching,torch.minimum(bound,white/metadata[shortest,0]),bound);seen|=matching&valid
        possible &= seen;bounds[colour]=bound
    for colour in range(3):
        for frame in range(k):
            for dy in range(2):
                for dx in range(2):
                    valid,matching,raw,white,flag=observation(frame,colour,dx,dy)
                    a,b,c,d=metadata[frame,13:17];variance=a*white+b+c+d*white*white;margin=3*torch.sqrt(variance.clamp_min(0));e=metadata[frame,0]
                    conflict=valid&matching&~flag&(raw<white-margin)&(raw/e<bounds[colour]-margin/e)
                    possible &= ~conflict
    return torch.where(possible[None,None],torch.maximum(prediction,bounds[None]),prediction)
