from pathlib import Path
import sys,json,hashlib
sys.path.insert(0,str(Path('analysis').resolve()))
from parse_ptp_device_info import parse
from decode_acquired_capabilities import decode
sys.path.insert(0,str(Path('analysis/video_quality_consumer_20261011').resolve()))
from analyze import parse_tags
p=Path(__file__).resolve().parent;r=p/'paired'
info=parse((r/'device_info.bin').read_bytes());info.pop('serial_number',None)
tags=parse_tags((r/'video_1.bin').read_bytes());ql=next(x['quality_list'] for x in tags if x['tag']=='0x0600001a')
cap=decode((r/'capability_1.bin').read_bytes());ids=next(x for x in cap['subtags'] if x['tag']=='0x06000013')['parameters'][0]['enum_values_raw']
extra=[x for x in ql['records'] if x['video_quality_id'] not in ids]
stable={n:(r/f'{n}_1.bin').read_bytes()==(r/f'{n}_2.bin').read_bytes() for n in ['mode','video','capability']}
result={'device_info_redacted':info,'stable':stable,'detail_count':ql['count'],'capability_count':len(ids),'current_quality_id':ql['current_quality_id'],'current_record':[x for x in ql['records'] if x['video_quality_id']==ql['current_quality_id']],'extra_records':extra,'tags':tags,'capability':cap,'hashes':{x.name:hashlib.sha256(x.read_bytes()).hexdigest() for x in r.glob('*.bin')}}
(p/'results.json').write_text(json.dumps(result,ensure_ascii=False,indent=2))
report=f'''# S1M2 USB 同会话配对采集

采集时间：2026-10-11 22:16:50 UTC（当地 2026-10-12 01:16:50）。

机型：{info['model']}；设备报告版本：{info['device_version']}。

## 实际结果

- 七个请求均返回 PTP OK 0x2001；会话正常关闭。
- 两轮模式、录像详情、能力响应逐字节一致：{stable}。
- 录像详情表 {ql['count']} 条；当前能力枚举 {len(ids)} 个；差集 {len(extra)} 个。
- 当前录像质量编号：{ql['current_quality_id']}。
- 全部原始数据及响应保存在 paired/；完整解析与 SHA-256 保存在 results.json。

## 结论边界

此次消除了旧数据分开采集的时间差：同一会话、未主动改变设置，仍可对比两个列表。详情表中的额外编号仅证明相机报告了这些描述，不证明当前可选、可录制或属于隐藏功能。仍需核验格式过滤、模式条件以及实录结果。

## 操作与采集器说明

先退出 Tether 释放 USB；通过 macOS ImageCaptureCore 打开、关闭相机会话。显式请求仅 GetDeviceInfo、0x9402[0x02000010]、0x9408[0x06000010]、0x9108[0x06000010,0,0]，outData 始终为空；未发送设置写入、快门、升级指令。未验证框架自动发出的所有底层请求，亦未做前后全配置校验。

第一次尝试因提交事务号与返回事务号不同而主动停止，见 raw/。第二次记录了双方事务号：返回号连续为 2–8，比提交号大 1。回调由 ImageCaptureCore 关联；不再宣称应用提交号与线上事务号相同。没有抓包独立验证框架内部映射。

采集器源码 capture.m、计划 plan.json、解析 analyze_capture.py 已保留；解析脚本只读取文件。Tether 当前已退出，可重新打开。
'''
(p/'采集报告.md').write_text(report)
print(json.dumps({k:result[k] for k in ['device_info_redacted','stable','detail_count','capability_count','current_quality_id','current_record']},ensure_ascii=False))
