"""Static reconstruction of v15.2 noise-qualified SIFT/global model selection."""
from graph import np
import cv2
MODELS=(('translation',2),('similarity',4),('affine',6),('homography',8))
THRESHOLD=1.5

def guides(raws,metadata,valids=None,max_side=1600):
    h,w=raws[0].shape;ratio=min(1.,max_side/max(h//2,w//2))
    rh,rw=max(8,round(h//2*ratio)),max(8,round(w//2*ratio));area=rw*rh/(w//2*(h//2));kernel=cv2.getGaussianKernel(5,.55)
    result=[]
    for i,(raw,meta) in enumerate(zip(raws,metadata)):
        e=float(meta[0]);cal=np.asarray(meta[13:17],np.float64);green=np.zeros((rh,rw),np.float32);variance=np.zeros_like(green);valid=np.ones_like(green)
        for c in (1,2):
            p=int(meta[1+c]);phase=np.asarray(raw[p//2::2,p%2::2]);positive=np.maximum(phase,0)
            pixelvar=cal[0]*positive+cal[1]+cal[2]+cal[3]*positive**2
            green+=cv2.resize(phase,(rw,rh),interpolation=cv2.INTER_AREA)*(.5/e)
            variance+=cv2.resize(pixelvar,(rw,rh),interpolation=cv2.INTER_AREA)*(.25*area/e**2)
            usable=(phase<meta[5+c])&(phase>meta[9+c])
            if valids is not None and valids[i] is not None:usable &= valids[i][p//2::2,p%2::2]!=0
            valid=np.minimum(valid,cv2.resize(usable.astype(np.float32),(rw,rh),interpolation=cv2.INTER_AREA))
        green=cv2.sepFilter2D(green,-1,kernel,kernel)
        variance=cv2.sepFilter2D(np.sqrt(variance),-1,kernel,kernel)**2
        valid=cv2.erode(valid,np.ones((5,5),np.uint8))>.999
        white=float(np.mean(meta[6:8]))/e;floor=max(5*np.sqrt((cal[1]+cal[2])*.5*area)/e,white*1e-8)
        result.append(dict(linear=green,variance=variance,valid=valid,white=white,floor=floor))
    lattice=np.array([[w/rw,0,(w/rw-1)/2],[0,h/rh,(h/rh-1)/2],[0,0,1]])
    return result,lattice

def features(guide,ceiling=None):
    ceiling=min(guide['white'],ceiling if ceiling is not None else guide['white']);floor=guide['floor'];signal=guide['linear']
    if not np.isfinite(floor) or not np.isfinite(ceiling) or ceiling<=floor:return [((),None)]
    resolved=guide['valid']&(signal>5*np.sqrt(guide['variance']))&(signal>floor)&(signal<ceiling)
    view=np.uint8(np.rint(np.clip((np.log(np.maximum(signal,floor))-np.log(floor))/np.log(ceiling/floor),0,1)*255))
    return [cv2.SIFT_create(nfeatures=10000,contrastThreshold=.005).detectAndCompute(view,np.uint8(resolved)*255)]

def matches(ref,src):
    matcher=cv2.BFMatcher();pairs=[]
    for (rk,rd),(sk,sd) in zip(ref,src):
        if rd is None or sd is None or min(len(rd),len(sd))<2:continue
        forward=[v[0] for v in matcher.knnMatch(rd,sd,k=2) if len(v)==2 and v[0].distance<.75*v[1].distance]
        reverse={(v[0].trainIdx,v[0].queryIdx) for v in matcher.knnMatch(sd,rd,k=2) if len(v)==2 and v[0].distance<.75*v[1].distance}
        pairs.extend((m.distance,rk[m.queryIdx].pt,sk[m.trainIdx].pt) for m in forward if (m.queryIdx,m.trainIdx) in reverse)
    used_a,used_b=set(),set();a,b=[],[]
    for _,x,y in sorted(pairs):
        ca,cb=tuple(np.rint(np.array(x)/2).astype(int)),tuple(np.rint(np.array(y)/2).astype(int))
        if ca not in used_a and cb not in used_b:used_a.add(ca);used_b.add(cb);a.append(x);b.append(y)
    return np.asarray(a,np.float64).reshape(-1,2),np.asarray(b,np.float64).reshape(-1,2)

def project(H,p):
    q=np.c_[p,np.ones(len(p))]@H.T
    return q[:,:2]/q[:,2:3]

def errors(H,a,b):
    try:return np.maximum(np.linalg.norm(project(H,a)-b,axis=1),np.linalg.norm(project(np.linalg.inv(H),b)-a,axis=1))
    except np.linalg.LinAlgError:return np.full(len(a),np.inf)

def fit(kind,a,b,robust=True):
    if len(a)<4:return None
    H=np.eye(3,dtype=np.float64)
    if kind=='translation':
        d=b-a
        if robust:
            proposals=d[np.linspace(0,len(d)-1,min(len(d),256)).astype(int)]
            counts=[np.sum(np.linalg.norm(d-center,axis=1)<THRESHOLD) for center in proposals]
            center=proposals[int(np.argmax(counts))];d=d[np.linalg.norm(d-center,axis=1)<THRESHOLD]
        H[:2,2]=np.median(d,axis=0)
    elif not robust:
        if kind=='similarity':
            x,y=a.T;design=np.zeros((2*len(a),4));design[0::2]=np.c_[x,-y,np.ones(len(a)),np.zeros(len(a))];design[1::2]=np.c_[y,x,np.zeros(len(a)),np.ones(len(a))]
            s,r,tx,ty=np.linalg.lstsq(design,b.ravel(),rcond=None)[0];H[:2]=[[s,-r,tx],[r,s,ty]]
        elif kind=='affine':H[:2]=np.linalg.lstsq(np.c_[a,np.ones(len(a))],b,rcond=None)[0].T
        else:H,_=cv2.findHomography(a,b,method=0)
    elif kind=='homography':H,_=cv2.findHomography(a,b,cv2.USAC_MAGSAC,THRESHOLD,maxIters=5000,confidence=.999)
    else:
        fitter=cv2.estimateAffinePartial2D if kind=='similarity' else cv2.estimateAffine2D
        m,_=fitter(a,b,method=cv2.RANSAC,ransacReprojThreshold=THRESHOLD,maxIters=5000,confidence=.999,refineIters=10)
        if m is None:return None
        H[:2]=m
    return H if H is not None and np.isfinite(H).all() else None

def sane(H,hw):
    if H is None:return False
    h,w=hw;p=np.array([[0,0],[w-1,0],[w-1,h-1],[0,h-1],[w/2,h/2]])
    den=np.c_[p,np.ones(5)]@H[2]
    if not np.isfinite(H).all() or den.min()*den.max()<=0:return False
    q=project(H,p)
    if np.max(np.abs(q-p))>max(h,w)*2:return False
    for axis in (np.array([1.,0]),np.array([0.,1])):
        length=np.linalg.norm(project(H,p+axis)-q,axis=1)
        if length.min()<.25 or length.max()>4:return False
    return bool(cv2.isContourConvex(np.float32(q[:4])) and np.linalg.det(H[:2,:2])>0)

def estimate_pair(a,b,hw):
    if len(a)<12:raise ValueError(f'Only {len(a)} independent reciprocal matches')
    candidates=[];h,w=hw;corners=np.array([[0,0],[w-1,0],[w-1,h-1],[0,h-1]])
    for kind,dof in MODELS:
        H=fit(kind,a,b)
        if not sane(H,hw):continue
        keep=errors(H,a,b)<THRESHOLD
        if keep.sum()<max(12,2*dof):continue
        H=fit(kind,a[keep],b[keep],robust=False)
        if not sane(H,hw):continue
        err=errors(H,a,b);keep=err<THRESHOLD
        if keep.sum()<max(12,2*dof):continue
        ia,ib=a[keep],b[keep];order=np.lexsort((ia[:,1],ia[:,0]));validation=[];extrapolation=[]
        for fold in range(4):
            test=np.arange(len(ia))%4==fold;train_ids,test_ids=order[~test],order[test]
            m=fit(kind,ia[train_ids],ib[train_ids],robust=False)
            if not sane(m,hw):validation.append(float('inf'));extrapolation.append(float('inf'));continue
            validation.extend(errors(m,ia[test_ids],ib[test_ids]));extrapolation.extend(np.linalg.norm(project(m,corners)-project(H,corners),axis=1))
        if not np.isfinite(validation).all() or not np.isfinite(extrapolation).all():continue
        cv90=float(np.quantile(validation,.9));uncertainty=float(np.max(extrapolation))
        if cv90>THRESHOLD or uncertainty>8:continue
        score=2*np.log1p((err/(THRESHOLD/3))**2).sum()+dof*np.log(len(a))
        candidates.append(dict(kind=kind,dof=dof,H=H,inliers=int(keep.sum()),residual_median=float(np.median(err[keep])),cv90=cv90,extrapolation=uncertainty,score=float(score)))
    if not candidates:raise ValueError('No geometrically stable model explains reciprocal matches')
    support=max(c['inliers'] for c in candidates);best=min((c for c in candidates if c['inliers']>=.9*support),key=lambda c:c['score'])
    report={k:v for k,v in best.items() if k!='H'};report['matches']=len(a);report['candidates']=[{k:v for k,v in c.items() if k!='H'} for c in candidates]
    return best['H'],report

def register(raws,metadata,valids=None):
    matrices=[np.eye(3,dtype=np.float32)]+[None]*6;reports=[];failures={};cv2.setRNGSeed(540)
    for side in (1600,3200):
        images,lattice=guides(raws,metadata,valids,max_side=side);cache={};inv=np.linalg.inv(lattice)
        for i in range(1,7):
            if matrices[i] is not None:continue
            ceiling=min(images[0]['white'],images[i]['white'])
            if ceiling not in cache:cache[ceiling]=features(images[0],ceiling)
            a,b=matches(cache[ceiling],features(images[i],ceiling))
            try:H,row=estimate_pair(a,b,images[0]['linear'].shape)
            except ValueError as exc:failures[i]=str(exc);continue
            matrices[i]=(lattice@H@inv).astype(np.float32);row.update(frame=i,guide_hw=list(images[0]['linear'].shape),native_pixel_scale=list(lattice.diagonal()[:2]));reports.append(row)
        if all(m is not None for m in matrices):return np.stack(matrices),reports
    raise ValueError('Insufficient reliable alignment evidence: '+str(failures))
