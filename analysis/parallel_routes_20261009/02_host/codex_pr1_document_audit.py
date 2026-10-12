"""Read PR1 archive from a local Git object, not executable content."""
import subprocess,zipfile,io,json,hashlib,collections,re,xml.etree.ElementTree as ET
from pathlib import Path
ROOT=Path(__file__).resolve().parents[3];REPO=ROOT/'outputs/lumix-s1m2-research-public';OUT=Path(__file__).resolve().parent
ref='refs/review/split-pr1'
blob=subprocess.run(['git','show',ref+':camera_api.zip'],cwd=REPO,capture_output=True,check=True).stdout
z=zipfile.ZipFile(io.BytesIO(blob));md=[];xml=[]
for name in z.namelist():
    if name.startswith('__MACOSX/'):continue
    data=z.read(name)
    if name.endswith('.md'):
        s=data.decode('utf-8')
        md.append({'path':name,'bytes':len(data),'sha256':hashlib.sha256(data).hexdigest(),'lines':len(s.splitlines()),'headings':[{'line':i,'text':l} for i,l in enumerate(s.splitlines(),1) if l.startswith('#')], 'review_scope':'heading and evidence-claim review; menu generated lists crosschecked structurally, not every explanatory sentence'})
    if name.endswith('.xml'):
        try:r=ET.fromstring(data)
        except ET.ParseError:continue
        models=[{'tag':e.tag,'model':e.attrib['model']} for e in r.iter() if 'model'in e.attrib]
        if name.endswith('capability.xml'):
            models += [{'tag':e.tag,'model':e.text} for e in r.iter('modelname')]
        modes=collections.Counter(e.attrib.get('cmd_mode') for e in r.iter() if 'cmd_mode'in e.attrib)
        tuples=sorted({(e.attrib.get('cmd_mode',''),e.attrib.get('cmd_type',''),e.attrib.get('cmd_value',''),e.attrib.get('cmd_value2','')) for e in r.iter() if 'cmd_mode'in e.attrib})
        xml.append({'path':name,'elements':sum(1 for e in r.iter()),'model_labels':models,'command_mode_counts':dict(modes),'unique_command_tuples':tuples})
s=z.read('camera_api/lumix_key_method.md').decode('utf-8').splitlines()
# No response bodies, identifiers, private keys or credentials copied.
claims=[{'line':3,'kind':'author revised model-specific observation: no token and unsupported encrypted handshake'}, {'line':27,'kind':'unreconciled claim: this firmware requires encrypted handshake'}, {'line':102,'kind':'broad control/security conclusion without control test'}, {'line':106,'kind':'section marks following items real-camera plus source proven'}, {'line':109,'kind':'unreconciled claim: key request yields key'}, {'line':112,'kind':'explicitly says encrypted handshake response still untested'}, {'line':113,'kind':'explicitly says control-command token enforcement untested'}]
assert 'req_acc_e'in s[26] and 'req_acc_g'in s[108]
result={'scope':'local submitted archive evidence audit; no requests sent and no downloaded program executed','git_ref':ref,'git_commit':subprocess.run(['git','rev-parse',ref],cwd=REPO,capture_output=True,text=True,check=True).stdout.strip(),'archive_sha256':hashlib.sha256(blob).hexdigest(),'documents':md,'xml_structures':xml,'auth_claim_boundary':claims,'limitations':['source classes cited in authentication document are not bundled in this archive','no independent raw HTTP trace accompanies claims','S5/MC801 input does not prove S1M2 behavior','menu commands describe existing controls, not executable implementations']}
(OUT/'codex_pr1_document_audit.json').write_text(json.dumps(result,ensure_ascii=False,indent=2)+'\n')
print(json.dumps({'documents':len(md),'xml':len(xml),'models':[(x['path'],x['model_labels']) for x in xml],'command_modes':[(x['path'],x['command_mode_counts']) for x in xml]},ensure_ascii=False))
