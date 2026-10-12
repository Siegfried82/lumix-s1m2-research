from pathlib import Path
import json,subprocess
root=Path(__file__).resolve().parents[2];p=root/'analysis/object_metadata_full_20261010';p.mkdir(exist_ok=True)
r=json.loads((root/'analysis/object_inventory_live_20261010/parsed_inventory.json').read_text());values=[int(x,16) for x in r['all_object_handles']['values_hex']];done={int(x['handle'],16) for x in json.loads((root/'analysis/object_metadata_sample_20261010/parsed_metadata.json').read_text())};values=[x for x in values if x not in done]
for i in range(0,len(values),100):
 batch=p/f'batch_{i//100:02d}';plan=p/f'plan_{i//100:02d}.json';items=[{'opcode':0x1008,'params':[x],'name':f'info_{x:08x}'} for x in values[i:i+100]]
 if (batch/'capture_log.json').exists():
  log=json.loads((batch/'capture_log.json').read_text());ok=[x for x in log if x.get('event')=='plan_read_response' and x.get('ok')]
  if len(ok)==len(items):continue
  raise RuntimeError('Partial batch requires inspection: '+str(batch))
 plan.write_text(json.dumps(items,indent=2));c=subprocess.run([str(root/'analysis/object_route_preparation_20261009/capture_object_metadata'),str(batch),'--read-plan',str(plan)],capture_output=True,text=True)
 print('batch',i//100,'requests',len(items),'exit',c.returncode,flush=True)
 if c.returncode:print(c.stdout,c.stderr);break
