# 本机 QEMU 运行时

此目录供应 ARM64 macOS 主机所需的 QEMU 11.1.2 及动态依赖。所有文件只在此目录内，不需要 Homebrew、sudo 或系统安装。

主线程读取 `runtime.json` 的 `binary` 和 `environment`，合并环境变量后直接启动主程序。`share_directory` 是 QEMU 固件数据目录，启动参数使用 `-L` 指定它。运行时本身不定义 guest、设备通信或联网设置，控制器负责这些参数。

## 验证结果

- 实际 `--version` 返回 QEMU emulator version 11.1.2，完整输出见 `version.txt`。
- 实际 `-machine help` 返回 `virt`，它是 `virt-11.1` 的别名，完整输出见 `machine_help.txt`。
- 实际 `-accel help` 包含 `tcg`，完整输出见 `accel_help.txt`。
- 从 Homebrew 官方 GHCR registry 取得的 30 个 bottle 都与官方 formula API 的 SHA256 完全匹配。
- 二进制和动态库保持 bottle 中的原始内容。通过局部 `DYLD_LIBRARY_PATH` 解决依赖，无需修改代码签名或动态库路径。

以上验证仅覆盖主机程序可启动及机器/加速器存在，guest 是否可启动由沙箱控制器另行验证。

## 来源与重现

QEMU 软件介绍：[Homebrew QEMU formula](https://formulae.brew.sh/formula/qemu)。精确包来源、标签、版本、URL、SHA256 和本地 archive 路径见 `bottle_sources.json`。下载时的完整 API 响应保存在 `metadata/`，原始 archive 保存在 `downloads/`。

QEMU 主包来源：

```text
https://ghcr.io/v2/homebrew/core/qemu/blobs/sha256:a399faaf2f8fb45d3b1f35704041a9104f7f717e9fda1b12d4deac9e919d0d33
```

主包 SHA256：`a399faaf2f8fb45d3b1f35704041a9104f7f717e9fda1b12d4deac9e919d0d33`。

提取后主程序 SHA256：`e769ac053ba90f78237c634e07f580e3c88cf833c22adbfe47d0d47477abf222`。

在此目录执行以下步骤可重新取得、验证和准备相同 runtime。已有 metadata 优先复用，避免默默切换版本。

```sh
/usr/bin/python3 fetch_bottles.py
/usr/bin/python3 prepare_runtime.py
```

Homebrew bottle 的说明参见 [Homebrew Bottles](https://docs.brew.sh/Bottles)。本运行时使用本机环境变量供应依赖，不声称这是 Homebrew 管理的安装。
