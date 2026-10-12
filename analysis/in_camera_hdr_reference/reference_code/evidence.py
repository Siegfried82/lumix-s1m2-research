"""Recovered v15.2 evidence130/white stage, after physical amplitude estimation.

bank: [4,K,H,W] raw, validity, saturation, underexposure layers.
coordinates: [K,1 or 3,O,O,2] mapped source RAW coordinates, ordered x,y.
metadata: [K,17] exposure, RGGB phase permutation, white, under, noise.
This stage does not perform alignment or estimate the physical base/amplitude.
"""
from graph import torch


def build_evidence(bank, coordinates, metadata, amplitude, shortest_rolloff=None):
    device = bank.device
    bank = bank.to(dtype=torch.float32)
    coordinates = coordinates.to(device=device, dtype=torch.float32)
    metadata = metadata.to(device=device, dtype=torch.float32)
    amplitude = amplitude.to(device=device, dtype=torch.float32)
    if bank.ndim != 4 or bank.shape[0] != 4: raise ValueError('bank must be [4,K,H,W]')
    _, k, h, w = bank.shape
    if k != 7: raise ValueError('Transformer requires seven frames')
    if metadata.shape != (k,17): raise ValueError('metadata must be [7,17]')
    if amplitude.ndim != 4 or amplitude.shape[:2] != (1,1): raise ValueError('amplitude must be [1,1,O,O]')
    o = amplitude.shape[-1]
    if amplitude.shape[-2] != o or o % 16: raise ValueError('output lattice must be square and divisible by 16')
    if coordinates.shape not in ((k,1,o,o,2),(k,3,o,o,2)): raise ValueError('coordinate shape mismatch')
    if not bool(torch.all(torch.isfinite(amplitude) & (amplitude > 0))): raise ValueError('amplitude must be finite and positive')
    if not bool(torch.all(torch.isfinite(metadata))) or not bool(torch.all(metadata[:,0] > 0)): raise ValueError('invalid metadata')
    phases = metadata[:,1:5]
    if not bool(torch.all(torch.sort(phases,dim=1).values == torch.arange(4,device=device))): raise ValueError('CFA phases must be a permutation of 0..3')
    if shortest_rolloff is not None and not 0 <= shortest_rolloff < k: raise ValueError('invalid shortest frame')
    r = o // 4
    hp = torch.arange(r,device=device)*4+1
    sampled_amplitude = amplitude[0,0][hp[:,None],hp[None,:]]
    aqmax = sampled_amplitude.max()
    evidence = torch.empty((1,k,130,r,r),device=device)
    white = metadata[:,5:9,None,None] / (metadata[:,0,None,None,None]*sampled_amplitude[None,None])
    for frame in range(k):
        den = metadata[frame,0]*sampled_amplitude
        phase_plane = torch.argsort(phases[frame]).long()
        for plane, colour in enumerate((0,1,1,2)):
            phase = phases[frame,plane].long()
            phase_x, phase_y = phase % 2, phase // 2
            cc = 0 if coordinates.shape[1] == 1 else colour
            coord = coordinates[frame,cc][hp[:,None],hp[None,:]]
            q = (coord-torch.stack((phase_x,phase_y)))*.5
            cell = torch.floor(q).long()
            for neighbour in range(4):
                ij = cell + torch.tensor((neighbour%2,neighbour//2),device=device)
                x,y = ij[...,0]*2+phase_x, ij[...,1]*2+phase_y
                inside = (x>=0)&(y>=0)&(x<w)&(y<h)
                cx,cy = x.clamp(0,w-1), y.clamp(0,h-1)
                raw = bank[0,frame,cy,cx]
                valid = inside & (bank[1,frame,cy,cx]>0)
                actual_plane = phase_plane[(cy%2)*2+cx%2]
                threshold = metadata[frame,5+actual_plane]
                saturated = (bank[2,frame,cy,cx]>0)|(raw>=threshold)
                under = (bank[3,frame,cy,cx]>0)|(raw<=metadata[frame,9+actual_plane])
                measurement = raw
                if shortest_rolloff == frame:
                    shoulder = raw >= .95*threshold
                    saturated = saturated & ~shoulder
                    u = ((raw/threshold-.95)/.05).clamp(0,1)
                    measurement = torch.where(shoulder, torch.minimum(raw,threshold)-.001*threshold*u*u,raw)
                usable = valid & ~saturated & ~under
                z = measurement.clamp_min(0)
                a,b,c,d = metadata[frame,13:17]
                variance = a*z+b+c+d*z*z
                signal = torch.where(usable,measurement,0)/den
                variance = torch.where(usable,variance,0)/(den*den)
                offset = ij-q
                values = (torch.sign(signal)*torch.log(signal.abs()+torch.sqrt(signal*signal+1)),
                          torch.log1p(variance),usable,valid&saturated,valid&under,
                          offset[...,0],offset[...,1],
                          (1-offset[...,0].abs())*(1-offset[...,1].abs())*inside)
                start = (plane*4+neighbour)*8
                evidence[0,frame,start:start+8] = torch.stack([v.float() for v in values])
        evidence[0,frame,128] = torch.log2(metadata[frame,0])
        evidence[0,frame,129] = torch.log(sampled_amplitude/aqmax)
    return evidence, white.unsqueeze(0)
