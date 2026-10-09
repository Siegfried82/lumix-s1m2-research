# Panasonic LUMIX S1M2 固件解包清单与说明

- 原始固件: `S1m2_V14.bin` (版本 V1.4, 大小 171,867,648 字节)
- 解包时间: 2026-10-07
- 解包目标目录: `analysis/unpacked/`

## 目录结构
- `headers/`: 固件外层头、安全签名头、内层头及原始 62 条目录表二进制
- `components/`: 全部 62 个组件独立镜像 (格式 `{index:02d}_{name}.bin`)
- `manifest.json` / `manifest.csv`: 完整元数据清单

## 组件统计
- 组件总数: 62
- 零长度占位组件: 4 (如 boot, loader2, loader3, storage)
- 明文擦除/占位组件 (Flags=2): 9 (全 0 或全 FF)
- 加密高熵组件 (Flags=3): 49 (含独立 128-bit IV)

## 关键业务组件指引
| 索引 | 组件名称 | 文件名 | 大小 | 业务说明 |
|---|---|---|---:|---|
| 01 | loader1 | `01_loader1.bin` | 128 KiB | 二级引导加载器候选 |
| 06 | compress_pr | `06_compress_pr.bin` | 16.00 MiB | 压缩 Linux 内核/SquashFS 根文件系统 |
| 25 | osdover | `25_osdover.bin` | 16.50 MiB | OSD 图形与界面资源 |
| 26 | osddata | `26_osddata.bin` | 19.37 MiB | 菜单与系统数据 |
| 44 | dsp_fstack_ | `44_dsp_fstack_.bin` | 64 KiB | 焦点堆叠 (Focus Stacking) 算法微码 A |
| 45 | dsp_fstack_ | `45_dsp_fstack_.bin` | 64 KiB | 焦点堆叠 (Focus Stacking) 算法微码 B |
| 46 | fstack_c_ex | `46_fstack_c_ex.bin` | 512 KiB | 焦点堆叠扩展模块 |
| 50-58 | hm_d_nw_1st~9th | `50~58_hm_d_nw_*.bin` | 各 1.375 MiB | AI 检测神经网络模型权重 (人/眼/动物/车) |
| 59 | hm_d_reid | `59_hm_d_reid.bin` | 3.00 MiB | AI 人物重识别 (Re-ID) 深度学习模型 |
| 60 | ai_awb_data | `60_ai_awb_data.bin` | 1.75 MiB | AI 自动白平衡权重数据 |
