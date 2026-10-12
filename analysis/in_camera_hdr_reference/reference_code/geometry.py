"""v15.2 native reference -> source flow/projective/LCA coordinate composition."""
from alignment import sample
from graph import torch,np
from raw_input import frame_bank

@torch.inference_mode()
def homography_warp(value,H):
    h,w=value.shape[-2:];device=value.device
    y,x=torch.meshgrid(torch.arange(h,device=device),torch.arange(w,device=device),indexing='ij')
    native=torch.stack((x*2+.5,y*2+.5,torch.ones_like(x)),-1).float()
    matrix=torch.as_tensor(H,dtype=torch.float32,device=device);q=native@matrix.T
    q=(q[...,:2]/q[...,2:3]-.5)*.5
    return sample(value,q)

@torch.inference_mode()
def tile_coordinates(flows,H,native,origin,lca=None):
    device=flows.device;o=native*2
    y,x=torch.meshgrid(torch.arange(o,device=device),torch.arange(o,device=device),indexing='ij')
    refq=torch.stack((x*.5+origin[0],y*.5+origin[1]),-1)
    qp=(refq-.5)*.5
    matrices=torch.as_tensor(H,dtype=torch.float32,device=device)
    coefficients=(lca or {}).get('coefficients_rgb',[0,0,0]);center=torch.tensor((lca or {}).get('center_native_xy',[0,0]),device=device)
    channels=1 if all(c==0 for c in coefficients) else 3
    result=torch.empty((7,channels,o,o,2),device=device)
    for k in range(7):
        flow=torch.zeros_like(refq) if k==0 else sample(flows[k:k+1],qp)[0].permute(1,2,0)*2
        q=refq+flow;projected=torch.cat((q,torch.ones_like(q[...,:1])),dim=-1)@matrices[k].T
        source=projected[...,:2]/projected[...,2:3]
        for c in range(channels):result[k,c]=source+(source-center)*float(coefficients[c])
    if not bool(torch.isfinite(result).all()):raise ValueError('Nonfinite source projection')
    return result

@torch.inference_mode()
def source_crops(raws,valids,coordinates,device):
    low=coordinates.amin(dim=(1,2,3)).cpu().numpy();high=coordinates.amax(dim=(1,2,3)).cpu().numpy()
    origins=(np.floor((low-2)/2)*2).astype(np.int64);ends=(np.ceil((high+3)/2)*2).astype(np.int64)
    widths=ends-origins;size=(np.ceil(widths.max(axis=0)/32)*32).astype(int)
    if np.any(size<=0):raise ValueError('Invalid source crop')
    banks=[frame_bank(raw,valid,origin=origin,shape=(int(size[1]),int(size[0]))) for raw,valid,origin in zip(raws,valids,origins)]
    bank=torch.from_numpy(np.stack(banks,axis=1)).to(device)
    local=coordinates-torch.as_tensor(origins,dtype=torch.float32,device=device)[:,None,None,None,:]
    return bank,local,origins
