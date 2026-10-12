"""Explicit read-only USB capture. Does not run on import."""
import argparse
import hashlib
import json
import threading
from pathlib import Path
from client import Client

def main():
    a=argparse.ArgumentParser(description=__doc__)
    a.add_argument('--pid',required=True,type=lambda s:int(s,0))
    a.add_argument('--query',choices=['clock','config','usb-speed','wb-adjust','lut-info','lut-file'],required=True)
    a.add_argument('--output',required=True,type=Path)
    a.add_argument('--lut-index',type=int)
    a.add_argument('--libusb-dir')
    args=a.parse_args()
    if args.query == 'lut-file' and (args.lut_index is None or not 0 <= args.lut_index <= 40):
        a.error('lut-file requires --lut-index 0..40')
    if args.query != 'lut-file' and args.lut_index is not None:
        a.error('--lut-index is only used by lut-file')
    if args.libusb_dir:
        import os
        dll_handle=os.add_dll_directory(args.libusb_dir)
    import usb1
    if args.output.exists() or args.output.with_suffix(args.output.suffix+'.json').exists():
        raise FileExistsError('choose new output filenames')
    stop=threading.Event();events=[];thread=None;h=None;interface=None;c=None
    with usb1.USBContext() as ctx:
        devices=[d for d in ctx.getDeviceList(skip_on_error=True) if d.getVendorID()==0x04da and d.getProductID()==args.pid]
        if len(devices)!=1:raise RuntimeError('expected exactly one matching device')
        settings=[s for cfg in devices[0].iterConfigurations() for intf in cfg.iterInterfaces() for s in intf.iterSettings() if s.getClass()==6 and s.getAlternateSetting()==0]
        if len(settings)!=1:raise RuntimeError('ambiguous or missing Still Image interface')
        s=settings[0];interface=s.getNumber();ins=[];outs=[];interrupts=[]
        for ep in s.iterEndpoints():
            addr=ep.getAddress();kind=ep.getAttributes()&3
            if kind==2:(ins if addr&128 else outs).append(addr)
            if kind==3 and addr&128:interrupts.append(addr)
        if len(ins)!=1 or len(outs)!=1 or len(interrupts)!=1:raise RuntimeError('unexpected endpoints')
        class USB:
            def read(self, timeout):return bytes(h.bulkRead(ins[0],1<<20,timeout=max(1,int(timeout*1000))))
            def write(self, data, timeout):
                n=h.bulkWrite(outs[0],data,timeout=max(1,int(timeout*1000)))
                if n!=len(data):raise IOError('short USB write')
        try:
            h=devices[0].open();h.claimInterface(interface)
            def drain():
                while not stop.is_set():
                    try:events.append(bytes(h.interruptRead(interrupts[0],512,timeout=300)).hex())
                    except usb1.USBErrorTimeout:continue
                    except Exception as exc:
                        events.append({'error':str(exc)});return
            thread=threading.Thread(target=drain,daemon=True);thread.start()
            c=Client(USB(),timeout=60)
            c.transact(0x1002,[1]);c.transact(0x9102,[0x10001])
            queries={'clock':(0x940a,0x08000010),'config':(0x9421,0x080000a2),'usb-speed':(0x9414,0x18000010),'wb-adjust':(0x9414,0x02000055),'lut-info':(0x9414,0x53000011),'lut-file':(0x9921,0x53000012)}
            opcode,tag=queries[args.query];r=c.read_lut(args.lut_index) if args.query=='lut-file' else c.transact(opcode,[tag])
            if r.data is None:raise RuntimeError('OK response without requested data')
            args.output.parent.mkdir(parents=True,exist_ok=True)
            with args.output.open('xb') as f:f.write(r.data)
            info={'pid':hex(args.pid),'opcode':hex(opcode),'tag':hex(tag),'bytes':len(r.data),'sha256':hashlib.sha256(r.data).hexdigest(),'transactions':c.audit,'events':events,'writes_enabled':False,'lut_index':args.lut_index,'data_is_raw_payload':True}
            with args.output.with_suffix(args.output.suffix+'.json').open('x') as f:json.dump(info,f,indent=2)
            print(json.dumps({'output':str(args.output),'bytes':len(r.data),'sha256':info['sha256']}))
        finally:
            if c and not c.failed:
                try:c.transact(0x9103);c.transact(0x1003)
                except Exception:pass
            stop.set()
            if thread:thread.join(timeout=1)
            if h:
                try:h.releaseInterface(interface)
                finally:h.close()

if __name__=='__main__':main()
