# storage_exfat_20261011 — 存储面实验文件映射

本目录随 PR「S1M2 存储面私有 exFAT 驱动实测报告」（docs/S1M2-存储面exFAT实测报告-中文.md）发布。文件来自作者本机 `usb_fuzz/` 工作区，映射如下：

| 本目录路径 | 本机原路径 | 说明 |
| --- | --- | --- |
| `camera_ref/make_cam_template.py` | `usb_fuzz/camera_ref/` 同名 | 相机亲笔格式模板重建（seed） |
| `camera_ref/make_cam_cve4273*.py` | 同上 | CVE-2023-4273 三张复现卡生成（根目录/DCIM/100_PANA） |
| `gen_images.py` | `usb_fuzz/gen_images.py` | 早期 Apple 模板阶段生成器（macOS newfs_exfat/newfs_msdos） |
| `TEST_PROTOCOL.md` / `KASAN_RESULTS.md` | `usb_fuzz/` 同名 | 盲测规程与结果（含 v5.7 祖先差分指纹） |
| `manifest.txt` | `usb_fuzz/images_cam/manifest.txt` | 派生镜像前 40MB SHA-256（镜像本体为稀疏文件，不随仓库分发） |
| `kasan_harness/` | `usb_fuzz/kasan_vm/` 的脚本子集 | QEMU aarch64 + linux-5.7 + KASAN harness |

**不随仓库分发的输入**（散列与方法见报告 §6）：

- 相机卡原始捕获四段（camera_head_4m.bin / camera_part16m.bin / camera_heap1m.bin / camera_100pana.bin）；
- linux-5.7 / busybox 源码与构建产物、QEMU 磁盘镜像（上游来源自行取得）；
- 全部 128GB 稀疏镜像本体（由上述脚本 + 捕获重新生成，用 manifest.txt 散列核对）。

复现顺序：按报告 §6.2 捕获 → 按 §6.3 重建 → 前 40MB 刷写 → 按 §6.5 只读观察。
