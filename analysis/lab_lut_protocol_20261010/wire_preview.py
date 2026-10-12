"""Offline-only reconstruction of Lab LUT read command. No USB/network imports."""
import struct,json,argparse
def build(index,tid):
 if isinstance(index,bool) or not isinstance(index,int) or not 0<=index<=40:raise ValueError('Only ordinary indices 0..40 supported in this preview')
 if not 0<=tid<=0xffffffff:raise ValueError('Invalid transaction ID')
 return struct.pack('<IHHIIB',17,1,0x9921,tid,0x53000012,index)
def main():
 assert build(0,1).hex()=='1100000001002199010000001200005300'
 assert len(build(40,0xffffffff))==17 and build(40,0xffffffff)[-1]==40
 for bad in (-1,41,65535):
  try:build(bad,1)
  except ValueError:pass
  else:raise AssertionError('Unsupported index accepted')
 p=argparse.ArgumentParser();p.add_argument('--index',type=int,default=0);p.add_argument('--tid',type=int,default=1);a=p.parse_args();print(json.dumps({'length':17,'command_hex':build(a.index,a.tid).hex(),'scope':'Static reconstruction only; no device-support or session validation.'},indent=2))
if __name__=='__main__':main()
