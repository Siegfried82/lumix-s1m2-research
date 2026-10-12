"""Read only normal named user LUT slots over an existing authenticated session."""
import subprocess,json,shlex,hashlib,re,math
from pathlib import Path
ROOT=Path(__file__).resolve().parents[2];OUT=Path(__file__).resolve().parent
adb=str(ROOT/'analysis/android_connection_tools/platform-tools/adb')
token=json.loads((ROOT/'analysis/android_lab_live_20261012/auth_response_private.json').read_text())['Data']['AuthToken']
slots=json.loads((ROOT/'analysis/android_lab_live_20261012/lut_info_response.json').read_text())['Data']['DataList'];log=[]
for slot in slots:
 if slot['LutType']!=3 or not slot['LutName']:continue
 ident=slot['LutId'];file=OUT/f'slot_{ident:02}.cube'
 cmd='curl --noproxy "*" --interface wlan0 -ksS --connect-timeout 4 --max-time 12 -X POST -H '+shlex.quote("Authorization: 'Bearer "+token+"'")+' -H "Content-Type: application/json" --data '+shlex.quote(json.dumps({'LutId':ident}))+' https://192.168.54.1/lut/file'
 r=subprocess.run([adb,'shell',cmd],capture_output=True,timeout=16);file.write_bytes(r.stdout)
 row={**slot,'file':file.name,'curl_exit':r.returncode,'bytes':len(r.stdout),'sha256':hashlib.sha256(r.stdout).hexdigest()}
 try:
  text=r.stdout.decode();size=int(re.search(r'^LUT_3D_SIZE\s+(\d+)',text,re.M)[1]);values=[]
  for line in text.splitlines():
   parts=line.split()
   if len(parts)==3:
    try:v=list(map(float,parts))
    except ValueError:continue
    values.append(v)
  row.update(cube_size=size,rows=len(values),valid=len(values)==size**3 and all(math.isfinite(x) for v in values for x in v),photostyle=re.findall(r'^#LUMIXPHOTOSTYLE.*',text,re.M))
 except Exception as e:row.update(valid=False,error=str(e))
 log.append(row);(OUT/'manifest.json').write_text(json.dumps(log,ensure_ascii=False,indent=2))
 print(ident,row.get('valid'),row['bytes'],flush=True)
 if r.returncode or not row['valid']:break
