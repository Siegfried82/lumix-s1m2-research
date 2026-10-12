"""Offline ASCII-only reconstruction of Sync request parameters. No networking."""
from urllib.parse import quote
import argparse,json

def transform(text,challenge):
    if not text.isascii():raise ValueError('ASCII-only reconstruction; Java UTF-16 handling not implemented')
    k=(challenge or -1875740628)&0xffffffff
    data=text.encode('ascii');data+=b'\xff'*((-len(data))%4)
    return ''.join((int.from_bytes(data[i:i+4],'big')^k).to_bytes(4,'little').hex() for i in range(0,len(data),4))
def requests(uuid,name,challenge=None):
    typ='req_acc'
    if challenge is not None:uuid,name=transform(uuid,challenge),transform(name,challenge);typ='req_acc_e'
    return '/cam.cgi?mode=accctrl&type='+typ+'&value='+quote(uuid,safe='')+'&value2='+quote(name,safe='')
if __name__=='__main__':
    p=argparse.ArgumentParser();p.add_argument('--uuid',required=True);p.add_argument('--name',default='LUMIX Sync');p.add_argument('--challenge',type=lambda x:int(x,0));a=p.parse_args()
    print(json.dumps({'request_path':requests(a.uuid,a.name,a.challenge),'network_requests_sent':0}))
