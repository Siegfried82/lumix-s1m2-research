"""Portable v15.2 signed Bayer RAW contract, restored from static traces."""
from graph import np, torch
from pathlib import Path
import json
WHITE_HEADROOM_DN=5.

def normalize_sensor(sensor,black,declared_white):
    sensor=np.asarray(sensor)
    if sensor.ndim!=2 or min(sensor.shape)<64:raise ValueError('RAW must be 2D with minimum dimension 64')
    source_hw=list(sensor.shape);h,w=(n//8*8 for n in sensor.shape)
    black=np.broadcast_to(np.asarray(black,dtype=np.float32),(2,2))
    declared=np.broadcast_to(np.asarray(declared_white,dtype=np.float32),(2,2))
    effective=declared-np.float32(WHITE_HEADROOM_DN);denom=effective-black
    if not np.isfinite(denom).all() or not np.isfinite(black).all() or (denom<=0).any():raise ValueError('Invalid black/white range')
    out=sensor[:h,:w].astype(np.float32,copy=True)
    for y in range(2):
        for x in range(2):out[y::2,x::2]=(out[y::2,x::2]-black[y,x])/denom[y,x]
    if not np.isfinite(out).all():raise ValueError('Nonfinite RAW observations')
    return out,dict(source_hw=source_hw,native_hw=[h,w],crop_xywh=[0,0,w,h],black=black.tolist(),white=effective.tolist(),denominator=denom.tolist(),original_decoder_white=declared.tolist(),white_headroom_dn=5.)

def tags(path):
    import exifread
    with open(path,'rb') as stream:parsed=exifread.process_file(stream,details=False)
    def number(key):
        tag=parsed.get(key)
        try:return float(tag.values[0]) if tag else None
        except (TypeError,ValueError,IndexError,OverflowError,ZeroDivisionError):return None
    def text(key):return str(parsed[key]) if key in parsed else None
    return dict(camera_make=text('Image Make'),camera_model=text('Image Model'),iso=number('EXIF ISOSpeedRatings') or number('EXIF PhotographicSensitivity'),exposure_seconds=number('EXIF ExposureTime'),capture_time=text('EXIF DateTimeOriginal'),capture_subsec=text('EXIF SubSecTimeOriginal'))

def decode_raw(path):
    import rawpy
    with rawpy.imread(str(path)) as raw:
        pattern=np.array(raw.raw_pattern)
        if pattern.shape!=(2,2):raise ValueError('Only Bayer RAW supported')
        labels=raw.color_desc.decode('ascii').rstrip('\0')
        colours=[labels[int(i)] for i in pattern.ravel()]
        if sorted(colours)!=['B','G','G','R']:raise ValueError('Invalid Bayer layout')
        red,blue=colours.index('R'),colours.index('B')
        indices=[red,red^1,blue^1,blue]
        black=np.asarray(raw.black_level_per_channel,np.float32)[pattern]
        declared=np.asarray(raw.camera_white_level_per_channel or [raw.white_level]*4,np.float32)[pattern]
        declared=np.where(declared>black,declared,float(raw.white_level)).astype(np.float32)
        sensor,record=normalize_sensor(raw.raw_image_visible,black,declared)
        record.update(source=str(Path(path).resolve()),cfa_index=indices,camera_whitebalance=list(raw.camera_whitebalance),rgb_xyz_matrix=raw.rgb_xyz_matrix.tolist())
    record.update(tags(path))
    return sensor,record

def prepare_raws(paths,output,calibration,exposures=None,reference_index=0):
    if len(paths)!=7 or not 0<=reference_index<7:raise ValueError('Exactly seven RAW frames required')
    cal=np.asarray(calibration,np.float32)
    if cal.shape not in ((4,),(7,4)) or not np.isfinite(cal).all() or (cal<0).any():raise ValueError('Explicit nonnegative shot/read/quantization/PRNU variance parameters required')
    records=[tags(path) for path in paths]
    if exposures is None:
        if any(r['exposure_seconds'] is None or r['iso'] is None for r in records):raise ValueError('Missing tags: explicit relative exposures required')
        if len(set(r['iso'] for r in records))!=1:raise ValueError('Mixed ISO requires explicit exposures and per-frame calibration')
        times=np.asarray([r['exposure_seconds'] for r in records]);exposures=times/times[reference_index]
    if len(set(r['iso'] for r in records))>1 and cal.shape!=(7,4):raise ValueError('Mixed ISO requires per-frame calibration')
    exposures=np.asarray(exposures,np.float32)
    if exposures.shape!=(7,) or not np.isfinite(exposures).all() or (exposures<=0).any():raise ValueError('Seven positive exposures required')
    output=Path(output);output.mkdir(parents=True,exist_ok=True)
    frames=[];records=[]
    for i,(path,exposure) in enumerate(zip(paths,exposures)):
        raw,record=decode_raw(path)
        if records and record['source_hw']!=records[0]['source_hw']:raise ValueError('RAW source dimensions differ')
        name=f'raw_{i}.npy';np.save(output/name,raw,allow_pickle=False)
        phase=np.asarray(record['cfa_index'])
        under=(-np.asarray(record['black'])/np.asarray(record['denominator'])).ravel()[phase]
        frames.append(dict(raw=name,source_id=str(Path(path).resolve()),exposure=float(exposure),white=1.,underflow=under.tolist(),cfa_index=phase.tolist(),calibration=(cal if cal.shape==(4,) else cal[i]).tolist()))
        records.append(record)
    manifest=dict(schema='TRANSFORMER_JSR_INPUT_V1',frames=frames,reference_index=reference_index,raw_records=records,decoder='rawpy/LibRaw; signed normalization, no white balance')
    target=output/'input.json';target.write_text(json.dumps(manifest,ensure_ascii=False,indent=2)+'\n')
    return target

def frame_bank(raw,valid=None,origin=(0,0),shape=None):
    h,w=raw.shape;sh,sw=shape or (h,w);x,y=map(int,origin)
    bank=np.zeros((4,sh,sw),np.float32)
    x0,y0=max(0,x),max(0,y);x1,y1=min(w,x+sw),min(h,y+sh)
    if x1>x0 and y1>y0:
        dst=np.s_[y0-y:y1-y,x0-x:x1-x];part=raw[y0:y1,x0:x1]
        if not np.isfinite(part).all():raise ValueError('Nonfinite RAW')
        bank[0][dst]=part;bank[1][dst]=1 if valid is None else valid[y0:y1,x0:x1]
    return bank

def load_manifest(path,materialize=True):
    path=Path(path);data=json.loads(path.read_text());frames=data['frames']
    if data.get('schema')!='TRANSFORMER_JSR_INPUT_V1' or len(frames)!=7:raise ValueError('Invalid Transformer manifest')
    reference=data.get('reference_index',0)
    if not isinstance(reference,int) or not 0<=reference<7:raise ValueError('Invalid reference')
    # Explicit order retained; reference tracked, not silently reordered.
    banks=[];metadata=[];shape=None
    for frame in frames:
        raw=np.load(path.parent/frame['raw'],allow_pickle=False,mmap_mode='r')
        if raw.dtype!=np.float32 or raw.ndim!=2 or min(raw.shape)<64 or any(n%8 for n in raw.shape):raise ValueError('Invalid normalized RAW lattice')
        if shape is not None and raw.shape!=shape:raise ValueError('RAW dimensions differ')
        shape=raw.shape
        phase=frame['cfa_index']
        if sorted(phase)!=[0,1,2,3] or phase[1]!=(phase[0]^1) or phase[2]!=(phase[3]^1):raise ValueError('Invalid R/Gr/Gb/B phases')
        exposure=float(frame['exposure']);cal=np.asarray(frame.get('calibration',data.get('calibration')),np.float32)
        white=np.broadcast_to(np.asarray(frame.get('white',1),np.float32),(4,));under=np.broadcast_to(np.asarray(frame.get('underflow',-1e30),np.float32),(4,))
        if cal.shape!=(4,) or not np.isfinite(cal).all() or (cal<0).any():raise ValueError('Invalid calibration')
        if not np.isfinite(exposure) or exposure<=0 or not np.isfinite(white).all() or not np.isfinite(under).all() or (white<=under).any():raise ValueError('Invalid radiometry')
        valid=np.load(path.parent/frame['valid'],allow_pickle=False) if frame.get('valid') else None
        if valid is not None and (valid.shape!=shape or not np.isin(valid,[0,1]).all()):raise ValueError('Invalid validity mask')
        banks.append(frame_bank(raw,valid) if materialize else raw);metadata.append(np.r_[exposure,phase,white,under,cal].astype(np.float32))
    return (torch.from_numpy(np.stack(banks,axis=1)) if materialize else banks),torch.from_numpy(np.stack(metadata)),data
