from pathlib import Path
import sys,subprocess,re,json,hashlib
out=Path(__file__).resolve().parent
sys.path.insert(0,str(out/'media_tools'))
import imageio_ffmpeg
ff=imageio_ffmpeg.get_ffmpeg_exe(); results=[]
for p in sorted((out/'original_media').glob('*.MP4')):
 log=out/'original_media'/ (p.stem+'.independent_decode.log')
 cmd=[ff,'-nostdin','-v','info','-xerror','-i',str(p),'-map','0:v:0','-map','0:a?','-vf','showinfo','-f','null','-']
 with log.open('wb') as f:r=subprocess.run(cmd,stdout=f,stderr=subprocess.STDOUT)
 s=log.read_text(errors='replace'); frames=[]
 for l in s.splitlines():
  m=re.search(r'\bn:\s*(\d+).*?pts:\s*(-?\d+).*?fmt:(\S+).*?s:(\d+x\d+).*?iskey:(\d+) type:(\S+)',l)
  if m:frames.append({'n':int(m[1]),'pts':int(m[2]),'format':m[3],'size':m[4],'key':int(m[5]),'type':m[6]})
 results.append({'file':p.name,'bytes':p.stat().st_size,'sha256':hashlib.sha256(p.read_bytes()).hexdigest(),'decode_exit_code':r.returncode,'full_video_audio_decode_passed':r.returncode==0,'decoded_frames':len(frames),'contiguous_indices':[f['n'] for f in frames]==list(range(len(frames))),'pixel_formats':sorted({f['format'] for f in frames}),'geometries':sorted({f['size'] for f in frames}),'frame_types':sorted({f['type'] for f in frames}),'all_intra_keyframes':bool(frames) and all(f['key']==1 and f['type']=='I' for f in frames),'pts_steps':sorted({frames[i+1]['pts']-frames[i]['pts'] for i in range(len(frames)-1)}),'stream_lines':[l.strip() for l in s.splitlines() if 'Stream #0:' in l][:3],'input_duration_line':next((l.strip() for l in s.splitlines() if 'Duration:' in l),None),'decoder':ff,'command':cmd})
(out/'original_media/independent_results.json').write_text(json.dumps(results,ensure_ascii=False,indent=2)+'\n');print(json.dumps(results,ensure_ascii=False,indent=2))
