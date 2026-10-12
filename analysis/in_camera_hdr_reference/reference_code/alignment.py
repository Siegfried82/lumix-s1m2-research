"""Recovered Transformer CFA proxy and original six-level SPyNet + HDR branch.
Global homography estimation and flow/H/LCA composition are separate stages.
"""
from graph import torch,np,ASSETS
import hashlib,json,math
F=torch.nn.functional

def sample(value,q):
    """Original WGSL bilinear equation with source coordinates clamped at border."""
    h,w=value.shape[-2:];x=q[...,0].clamp(0,w-1);y=q[...,1].clamp(0,h-1)
    ix,iy=torch.floor(x).long(),torch.floor(y).long();ex,ey=(ix+1).clamp_max(w-1),(iy+1).clamp_max(h-1)
    fx,fy=x-ix,y-iy
    return (value[...,iy,ix]*(1-fx)+value[...,iy,ex]*fx)*(1-fy)+(value[...,ey,ix]*(1-fx)+value[...,ey,ex]*fx)*fy

@torch.inference_mode()
def components(bank,meta,sample_stride=1,lca=None,origin=(0,0)):
    # bank: four layers for one frame, metadata: 17 entries.
    _,h,w=bank.shape;device=bank.device
    hp,wp=math.ceil(h/2/sample_stride),math.ceil(w/2/sample_stride)
    yy,xx=torch.meshgrid(torch.arange(hp,device=device),torch.arange(wp,device=device),indexing='ij')
    qbase=torch.stack((xx*2*sample_stride+.5,yy*2*sample_stride+.5),-1)
    coeff=(lca or {}).get('coefficients_rgb',[0,0,0]);center=(lca or {}).get('center_native_xy',[0,0])
    fields=torch.zeros((3,4,hp,wp),device=device)
    for c,colour in enumerate((0,1,1,2)):
        qnative=qbase+(qbase+torch.tensor(origin,device=device)-torch.tensor(center,device=device))*float(coeff[colour])
        phase=meta[1+c].long();px,py=phase%2,phase//2
        q=(qnative-torch.stack((px,py)))*.5;cell=q.floor().long()
        value=torch.zeros((hp,wp),device=device);variance=torch.zeros_like(value);ok=torch.ones_like(value,dtype=torch.bool)
        for t in range(4):
            ij=cell+torch.tensor((t%2,t//2),device=device);d=ij-q
            weight=(1-d[...,0].abs())*(1-d[...,1].abs())
            x,y=ij[...,0]*2+px,ij[...,1]*2+py
            sx=ij[...,0].clamp(0,w//2-1)*2+px;sy=ij[...,1].clamp(0,h//2-1)*2+py
            raw=bank[0,sy,sx];z=raw.clamp_min(0);e=meta[0]
            value+=weight*raw/e;variance+=weight*weight*(meta[13]*z+meta[14]+meta[15]+meta[16]*z*z)/(e*e)
            cx,cy=x.clamp(0,w-1),y.clamp(0,h-1)
            actual=torch.argsort(meta[1:5]).long()[(cy%2)*2+cx%2]
            observed=bank[0,cy,cx]
            usable=(x>=0)&(y>=0)&(x<w)&(y<h)&(bank[1,cy,cx]>0)&~((bank[2,cy,cx]>0)|(observed>=meta[5+actual]))&~((bank[3,cy,cx]>0)|(observed<=meta[9+actual]))
            ok &= usable
        fields[0,c]=value;fields[1,c]=variance;fields[2,c]=ok
    # Green signal/support mean, independent green variance quarter-sum.
    rgb=torch.stack((fields[:,0],(fields[:,1]+fields[:,2])*torch.tensor([.5,.25,.5],device=device)[:,None,None],fields[:,3]),dim=1)
    return rgb.reshape(1,9,hp,wp)

@torch.inference_mode()
def normalize(component,meta,scale):
    z=component[:,:3]/scale
    white=torch.stack((meta[5],(meta[6]+meta[7])*.5,meta[8]))/meta[0]/scale
    gamma=z.clamp(0,1).pow(1/2.2)
    ash=z.sign()*torch.log(z.abs()+torch.sqrt(1+z*z))
    extra=torch.cat((ash,component[:,6:9],torch.log1p(white)[None,:,None,None].expand_as(z),torch.log1p(component[:,3:6]/(scale*scale))),dim=1)
    return gamma,extra

@torch.inference_mode()
def prepare_proxies(bank,metadata,lca=None):
    small=[components(bank[:,i],metadata[i],sample_stride=32,lca=lca)[:,:3].cpu().numpy().ravel() for i in range(7)]
    scale=max(float(np.quantile(np.maximum(np.concatenate(small),0),.9)),.0001)
    pairs=[normalize(components(bank[:,i],metadata[i],lca=lca),metadata[i],scale) for i in range(7)]
    return torch.cat([p[0] for p in pairs]),torch.cat([p[1] for p in pairs]),scale

class SPyNet:
    def __init__(self,device='cpu',core=256):
        self.core=core
        self.device=torch.device(device);path=ASSETS/'spynet.npz'
        manifest=json.loads((ASSETS/'MANIFEST.json').read_text())
        if hashlib.sha256(path.read_bytes()).hexdigest()!=manifest['files']['spynet.npz']:raise ValueError('SPyNet weight hash mismatch')
        with np.load(path,allow_pickle=False) as archive:self.weights={k:torch.from_numpy(archive[k].copy()).to(device) for k in archive.files}
    def conv_branch(self,value,level,branch,boundary_mask=None):
        count=5 if branch=='basic_module' else 2
        for j in range(count):
            name=f'basic_module.{level}.basic_module.{j}.conv' if branch=='basic_module' else f'hdr.{level}.{j*2}'
            weight=self.weights[name+'.weight'];value=F.conv2d(value,weight,self.weights[name+'.bias'],padding=weight.shape[-1]//2)
            if j<count-1:value=F.relu(value)
            if boundary_mask is not None:value=value*boundary_mask
        return value
    @torch.inference_mode()
    def __call__(self,reference,source,reference_hdr,source_hdr):
        h,w=reference.shape[-2:];uh,uw=math.ceil(h/32)*32,math.ceil(w/32)*32
        pyramids=[]
        for i,value in enumerate((reference,source,reference_hdr,source_hdr)):
            value=value.to(self.device);value=F.interpolate(value,size=(uh,uw),mode='bilinear',align_corners=False)
            if i<2:
                mean=torch.tensor([.485,.456,.406],device=self.device)[None,:,None,None]
                std=torch.tensor([.229,.224,.225],device=self.device)[None,:,None,None];value=(value-mean)/std
            p=[value]
            for _ in range(5):p.append(F.avg_pool2d(p[-1],2))
            pyramids.append(p[::-1])
        flow=None
        for level in range(6):
            rr,ss,rc,sc=(p[level] for p in pyramids);lh,lw=rr.shape[-2:]
            flow=torch.zeros((1,2,lh,lw),device=self.device) if flow is None else F.interpolate(flow,size=(lh,lw),mode='bilinear',align_corners=True)*2
            if self.core is None:
                y,x=torch.meshgrid(torch.arange(lh,device=self.device),torch.arange(lw,device=self.device),indexing='ij')
                q=torch.stack((x,y),-1).float()+flow[0].permute(1,2,0)
                basic=torch.cat((rr,sample(ss,q),flow),dim=1)
                hdr=torch.cat((rc,sample(sc,q)),dim=1)
                flow=flow+self.conv_branch(basic,level,'basic_module')+self.conv_branch(hdr,level,'hdr')
            else:
                result=torch.empty_like(flow)
                for oy in range(0,lh,self.core):
                    for ox in range(0,lw,self.core):
                        ch,cw=min(self.core,lh-oy),min(self.core,lw-ox)
                        y,x=torch.meshgrid(torch.arange(oy-15,oy+ch+15,device=self.device),torch.arange(ox-15,ox+cw+15,device=self.device),indexing='ij')
                        mask=((x>=0)&(y>=0)&(x<lw)&(y<lh))[None,None]
                        lattice=torch.stack((x,y),-1).float()
                        f=sample(flow,lattice)*mask
                        q=lattice+f[0].permute(1,2,0)
                        basic=torch.cat((sample(rr,lattice)*mask,sample(ss,q)*mask,f),dim=1)
                        hdr=torch.cat((sample(rc,lattice)*mask,sample(sc,q)*mask),dim=1)
                        correction=self.conv_branch(basic,level,'basic_module',mask)+self.conv_branch(hdr,level,'hdr',mask)
                        result[:,:,oy:oy+ch,ox:ox+cw]=flow[:,:,oy:oy+ch,ox:ox+cw]+correction[:,:,15:15+ch,15:15+cw]
                flow=result
        flow=F.interpolate(flow,size=(h,w),mode='bilinear',align_corners=False)
        flow=flow*torch.tensor([w/uw,h/uh],device=self.device)[None,:,None,None]
        return flow
