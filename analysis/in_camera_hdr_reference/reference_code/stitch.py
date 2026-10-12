"""Original v15.1 fixed Bayer lattice schedule and sine-square overlap weights.
Host stripe storage bounds RAM; final RGB is written to a disk-backed NPY.
"""
from graph import np

def positions(length,core,stride):
    if length<core:raise ValueError('Image smaller than tile core')
    values=sorted(set(range(0,length-core+1,stride))|{length-core})
    if any(v%8 for v in values):raise ValueError('Tile schedule shifts Bayer lattice')
    return values

class StripeStitcher:
    def __init__(self,height,width,output,tile_native=256,guard_native=64,overlap_native=32):
        if tile_native%8 or guard_native%8:raise ValueError('Tile/guard must preserve Bayer lattice')
        self.guard=guard_native;self.core=tile_native-2*guard_native;stride=self.core-overlap_native
        if self.core<=0 or not 0<=overlap_native<self.core:raise ValueError('Invalid tile or overlap')
        self.h,self.w=height*2,width*2;self.core_h=self.core*2;self.tile_h=tile_native*2
        self.xs,self.ys=positions(width,self.core,stride),positions(height,self.core,stride)
        self.result=np.lib.format.open_memmap(output,mode='w+',dtype=np.float32,shape=(self.h,self.w,3))
        ramp=2*overlap_native;weights=np.ones(self.core_h,np.float32)
        if ramp:
            taper=np.sin((np.arange(ramp,dtype=np.float64)+.5)/ramp*np.pi/2)**2
            weights[:ramp]=taper;weights[-ramp:]=taper[::-1]
        self.window=np.outer(weights,weights).astype(np.float32)
        self.accum=np.zeros((self.core_h,self.w,3),np.float32);self.weight=np.zeros((self.core_h,self.w),np.float32)
        self.start=0;self.next_row=0
    def add(self,prediction,x,y):
        if x not in self.xs or y not in self.ys:raise ValueError('Off-schedule tile')
        if y*2!=self.start:raise ValueError('Flush prior stripe before adding row')
        if tuple(prediction.shape)!=(1,3,self.tile_h,self.tile_h):raise ValueError('Wrong prediction shape')
        g=2*self.guard;core=prediction[0,:,g:g+self.core_h,g:g+self.core_h].detach().cpu().numpy().transpose(1,2,0)
        a,b=x*2,x*2+self.core_h
        self.accum[:,a:b]+=core*self.window[:,:,None];self.weight[:,a:b]+=self.window
    def finish_row(self,y):
        idx=self.ys.index(y);end=self.ys[idx+1]*2 if idx+1<len(self.ys) else self.h
        count=end-self.start
        if count<0 or count>self.core_h:raise ValueError('Invalid stripe advance')
        weight=self.weight[:count]
        if (weight<=0).any():raise ValueError('Uncovered output pixels')
        self.result[self.start:end]=self.accum[:count]/weight[:,:,None]
        remain=self.core_h-count
        if remain:
            self.accum[:remain]=self.accum[count:].copy();self.weight[:remain]=self.weight[count:].copy()
        self.accum[remain:]=0;self.weight[remain:]=0
        self.start=end;self.next_row=end;self.result.flush()
