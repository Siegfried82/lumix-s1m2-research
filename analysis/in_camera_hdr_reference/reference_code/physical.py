"""Static reconstruction of v15.2 Physical merge/covariance/blur/prepare.
Requires pre-aligned source-coordinate maps and calibrated RAW bank/metadata.
"""
from evidence import build_evidence
from graph import torch
F = torch.nn.functional

def _measure(bank, metadata, coordinates, frame, colour, dx, dy, shortest):
    _,_,h,w=bank.shape
    cc=0 if coordinates.shape[1]==1 else colour
    q=coordinates[frame,cc]
    cell=torch.floor(q).long()
    x,y=cell[...,0]+dx,cell[...,1]+dy
    cx,cy=x.clamp(0,w-1),y.clamp(0,h-1)
    raw=bank[0,frame,cy,cx]
    phase=(cy%2)*2+cx%2
    planes=torch.argsort(metadata[frame,1:5]).long()
    plane=planes[phase]
    white=metadata[frame,5+plane]
    valid=(x>=0)&(y>=0)&(x<w)&(y<h)&(bank[1,frame,cy,cx]>0)
    saturated=(bank[2,frame,cy,cx]>0)|(raw>=white)
    under=(bank[3,frame,cy,cx]>0)|(raw<=metadata[frame,9+plane])
    if shortest==frame:
        shoulder=raw>=.95*white
        saturated=saturated&~shoulder
        u=((raw/white-.95)/.05).clamp(0,1)
        raw=torch.where(shoulder,torch.minimum(raw,white)-.001*white*u*u,raw)
    # Outside coordinates cannot be usable; original phase_colour uses max rather than clamp.
    lattice_phase=(y.clamp_min(0)%2)*2+x.clamp_min(0)%2
    sample_colour=torch.ones_like(lattice_phase)
    sample_colour=torch.where(lattice_phase==metadata[frame,1],0,sample_colour)
    sample_colour=torch.where(lattice_phase==metadata[frame,4],2,sample_colour)
    return valid&~saturated&~under,raw/metadata[frame,0],sample_colour,x-q[...,0],y-q[...,1]

@torch.inference_mode()
def merge(bank,coordinates,metadata,covariance=None,shortest=None):
    seed=covariance is None
    o=coordinates.shape[-2]
    fields=torch.zeros((1,1 if seed else 12,o,o),device=bank.device)
    for colour in ((1,) if seed else (0,1,2)):
        top=torch.full((o,o),-3.402823e38,device=bank.device)
        mass=torch.zeros_like(top);total=torch.zeros_like(top)
        energy=torch.zeros_like(top);count=torch.zeros_like(top)
        for frame in range(bank.shape[1]):
            for dy in range(-1,3):
                for dx in range(-1,3):
                    ok,v,sample_colour,xx,yy=_measure(bank,metadata,coordinates,frame,colour,dx,dy,shortest)
                    energy_ok=ok & (sample_colour==colour) if coordinates.shape[1]==3 else ok
                    energy+=torch.where(energy_ok,v*v,0);count+=energy_ok
                    usable=ok&(sample_colour==colour)
                    if seed: score=-.5*(xx*xx+yy*yy)/.09
                    else: score=-.5*(covariance[0,0]*xx*xx+2*covariance[0,1]*xx*yy+covariance[0,2]*yy*yy)
                    score+=torch.log(metadata[frame,0])
                    nt=torch.maximum(top,score)
                    old=torch.exp(top-nt);add=torch.exp(score-nt)
                    total=torch.where(usable,total*old+add*v,total)
                    mass=torch.where(usable,mass*old+add,mass)
                    top=torch.where(usable,nt,top)
        fields[0,0 if seed else colour]=torch.where(mass>0,total/mass.clamp_min(1e-30),0)
        if not seed:
            fields[0,3+colour]=(mass>0).float();fields[0,6+colour]=energy;fields[0,9+colour]=count
    return fields

@torch.inference_mode()
def covariance(seed):
    down=seed[:,:,::2,::2]
    sobel=torch.tensor([[-1.,0,1],[-2,0,2],[-1,0,1]],device=seed.device)*.25
    gradients=F.conv2d(F.pad(down,(1,1,1,1),mode='reflect'),torch.stack((sobel,sobel.T))[:,None])
    gx,gy=gradients[:,0:1],gradients[:,1:2]
    tensor=torch.cat((gx*gx,gx*gy,gy*gy),dim=1)
    kernel=torch.ones((3,1,3,3),device=seed.device)
    j=F.conv2d(F.pad(tensor,(1,1,1,1),mode='reflect'),kernel,groups=3)
    trace=j[:,0]+j[:,2];nonflat=trace>0
    j=j/torch.where(nonflat,trace,1)[:,None]
    a,b,c=j[:,0],j[:,1],j[:,2];tr=a+c
    disc=torch.sqrt((.25*tr*tr-(a*c-b*b)).clamp_min(0))
    l1=(.5*tr+disc).clamp_min(1e-12);l2=(.5*tr-disc).clamp_min(0)
    anis=1+torch.sqrt(((l1-l2)/(l1+l2+1e-12)).clamp(0,1))
    across=(.12*(1+anis*.5*(-.5))).clamp_min(.20)
    along=(.12*(1+anis*.5*3)).clamp_min(.20)
    ax,ay=b,l1-a;bx,by=l1-c,b
    choose=bx*bx+by*by>ax*ax+ay*ay
    ex,ey=torch.where(choose,bx,ax),torch.where(choose,by,ay)
    norm=torch.sqrt(ex*ex+ey*ey);defined=norm>1e-6*l1
    ex=torch.where(defined,ex/norm.clamp_min(1e-30),1);ey=torch.where(defined,ey/norm.clamp_min(1e-30),0)
    ai=1/along/along;ci=1/across/across;diff=ci-ai
    result=torch.stack((torch.where(nonflat,ai+diff*ex*ex,11.1111111111),
                        torch.where(nonflat,diff*ex*ey,0),
                        torch.where(nonflat,ai+diff*ey*ey,11.1111111111)),dim=1)
    return result.repeat_interleave(2,-2).repeat_interleave(2,-1)

@torch.inference_mode()
def prepare(bank,coordinates,metadata,shortest_rolloff=None):
    device=bank.device
    bank=bank.float();coordinates=coordinates.to(device=device,dtype=torch.float32);metadata=metadata.to(device=device,dtype=torch.float32)
    seed=merge(bank,coordinates,metadata,shortest=shortest_rolloff)
    cov=covariance(seed)
    fields=merge(bank,coordinates,metadata,cov,shortest_rolloff)
    square=(fields[:,:3]*fields[:,:3]).mean(dim=1,keepdim=True)
    kernel=torch.exp(-.5*(torch.arange(-16,17,device=device).float()/4)**2);kernel/=kernel.sum()
    blurred=F.conv2d(F.pad(square,(16,16,0,0),mode='reflect'),kernel[None,None,None,:])
    blurred=F.conv2d(F.pad(blurred,(0,0,16,16),mode='reflect'),kernel[None,None,:,None])
    energy=fields[:,6:9].sum(dim=1,keepdim=True);count=fields[:,9:12].sum(dim=1,keepdim=True)
    amplitude=torch.maximum(torch.sqrt(blurred.clamp_min(0)),.001*torch.sqrt(energy/count.clamp_min(1)))
    peak=amplitude.max();amplitude=amplitude.clamp_min(torch.where(peak>0,peak*.000001,torch.ones_like(peak)))
    evidence,white=build_evidence(bank,coordinates,metadata,amplitude,shortest_rolloff)
    return evidence,fields[:,:3].contiguous(),amplitude,(fields[:,3:6]>0),white
