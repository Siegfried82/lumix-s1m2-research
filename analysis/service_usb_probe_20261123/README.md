# svc_probe — S1M2 服务模式 USB 只读客户端

配套报告：`../S1M2服务模式USB探测_20261123.md`

只实现 `0x35`、`0x38`、`0x3A`、`0x75`、`0x9B`、`0x5C` 六个读 opcode。
源码中没有 `0x9C`（写）和 `0x70`（已知会冻机）的构造路径。

## 依赖

- libusb 1.0（macOS: `brew install libusb`；Linux: `libusb-1.0-0-dev`）
- 服务模式：关机，按住 `回放 + AF-ON`，再按电源开机；机身枚举 `04DA:2370`
- macOS 上需要在允许访问 USB 的环境运行（命令行沙箱内 libusb 可能枚举不到设备）
- Windows 可用 WinUSB（Zadig）绑定接口 0 后移植同一套帧协议

## 构建与自检

```sh
make
./svc_probe selftest
```

`selftest` 只校验帧构造与校验和，不打开设备。

## 只读命令

```sh
./svc_probe identify                   # 0x38, area 0x20, index 0x3F80..0x3F8F
./svc_probe raw 0x3a                   # 元数据查询（262 字节回复）
./svc_probe raw 0x35 000010            # index 0, selector 0x10
./svc_probe raw 0x35 000020            # index 0, selector 0x20
./svc_probe raw 0x38 000022            # index 0, selector 0x22
./svc_probe sweep 0x38 0x22 0 0xFF     # 有界字扫描（不涉及绝对地址）
```

以下命令涉及绝对地址。**S1M2 上已在 `0x40000000`、`0x80000000`、`0x03700000`
三个地址实测冻机**；除非有新的地址映射证据，不要运行：

```sh
./svc_probe word 0x80000000            # 0x9B 2 字节读
./svc_probe read 0x80000000            # 0x5C 1 KiB 读
./svc_probe dump <addr> <len> --out f  # 连续 1 KiB 读
```

## 冻机恢复

拔 USB → 长按电源关机 → 按 `回放 + AF-ON` 重进服务模式。报告中的三次冻机均如此恢复。
