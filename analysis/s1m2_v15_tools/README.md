# 复现工具（对应 `analysis/s1m2_v15_container_ptp_2370_20261123.md`）

仅用于**只读**分析与本地校验。全部脚本只读固件文件与相机 USB 的读通道；
不包含任何写入、擦除、升级触发或恢复类命令。

## 依赖

```
Python 3.10+
pip install pycryptodome   # 仅 reduced-round AES 检验（可选）
pip install capstone       # 仅反汇编（可选）
```

Windows 上 USB 访问走 `winusb.dll`（ctypes，无需额外包），需先把目标接口绑定 WinUSB。

## `upd_tool.py` — UPD 容器

```bash
python tools/upd_tool.py info    S1m2_V15.bin                     # 头 + 62 项目录 + 熵
python tools/upd_tool.py verify  S1m2_V15.bin                     # CRC32 + 逐项摘要语义
python tools/upd_tool.py extract S1m2_V15.bin -o out              # 解包
python tools/upd_tool.py version S1m2_V15.bin                     # 读版本门 0x1C/0x1E（BCD）
python tools/upd_tool.py version S1m2_V15.bin --to 0x0151 -o x.bin # 抬版本门（仅改 2 字节）
python tools/upd_tool.py keystream S1m2_V15.bin -i 8 -o ks.bin     # 已知填充项反推密钥流
python tools/upd_tool.py flat    S1m2_V15.bin -o flat.bin          # 按 dest 拼扁平镜像（明文段）
```

## `ptp.py` / `dump9421.py` — PTP（`04DA:2382`）

先用 Zadig 把 `2382` 替换为 WinUSB（原 WPD/MTP 驱动会占住接口）。

```bash
python tools/ptp.py info                                 # 端点枚举 + OpenSession + GetDeviceInfo
python tools/dump9421.py --tag 0x080000a2 -o config.bin   # 0x9421 配置 dump（9,197,673 B）
```

只读 opcode：`0x1001/0x1002/0x1004/0x9104/0x9421/0x1003`。
**不发送** `0x9406` 子码、`0x9422/0x9423`、`0x940d` 等任何写入/副作用命令。

## `svc2370.py` — 服务接口（`04DA:2370`）

关机 → 按住 `PLAY` + `AF-ON` → 开机（依 PR #2，驱动拨盘需在 `[Single]`）。

```bash
python tools/svc2370.py                      # 等设备 + 自检 + 窗口别名扫描
python tools/svc2370.py --window 0x8000000 0x40000 out/win.bin   # dump 指定窗口
```

实测要点（详见文档 §3.4）：

- 端点 **`0x01` bulk OUT / `0x81` bulk IN / `0x82` interrupt**（与 S5 的 `0x82` bulk IN 不同）；
- 门铃 `ctrl(0x40, bRequest=0, wIndex=0)` → 写 → `ctrl(…, wIndex=1)` → 读；
- `0x5C` 帧 1030 B，成功头 `01 00 FF 05`；**`end` 字段必须非零**，否则只是 ping；
- `end` 越界会让固件崩、USB 掉线（`err=31/433`），需重启相机；
- 可读窗口：`0x8400000`(=`0x0` 别名, 192 KB)、`0x8000000`(256 KB)、`0x8200000`(128 KB)。

## 数据与脱敏

文档与脚本中不含机身序列号、网络凭据、机身照片。
固件输入仅以官方分发 ZIP + SHA-256 指认，仓库内不附带厂商二进制。
