# MN10300 / AM33 离线反汇编工具构建与验证

日期：2026-10-11。状态：本地构建成功，以下正对照全部通过。所有下载、源码、构建、测试与报告均位于本目录；没有系统安装，没有执行相机固件或目标架构对象，也没有访问设备。

## 1. 可直接使用的工具

GNU objdump 2.44：

```text
<LOCAL_WORKSPACE>/analysis/ultra_mn10300_tool_20261011/build-system-zlib/binutils/objdump
```

配套官方汇编器与字节提取工具：

```text
<LOCAL_WORKSPACE>/analysis/ultra_mn10300_tool_20261011/build-system-zlib/gas/as-new
<LOCAL_WORKSPACE>/analysis/ultra_mn10300_tool_20261011/build-system-zlib/binutils/objcopy
```

`objdump -m` 已实测支持 `mn10300`、`am33`、`am33-2`。`-i` 的格式列表只显示主架构 `mn10300`，这不代表其子变体不可用。BFD 主架构/变体关系见官方源码 `binutils-2.44/bfd/cpu-m10300.c:43-50`。

无需安装即可静态读取原始文件的一个窗口：

```sh
'<LOCAL_WORKSPACE>/analysis/ultra_mn10300_tool_20261011/build-system-zlib/binutils/objdump' \
  -D -b binary -m am33 --prefix-address --show-raw-insn --insn-width=7 \
  --start-address=0x600 --stop-address=0x800 \
  '<LOCAL_WORKSPACE>/analysis/legacy_corpus_20261011/G3___V12.bin.plaintext'
```

此处地址是文件偏移。`--adjust-vma=BASE` 会改变显示地址，也会改变 `--start-address` / `--stop-address` 的地址坐标，必须成套调整。`--insn-width=7` 避免长指令的原始字节拆成附加行。

## 2. 源码来源与完整性

源码来自 [GNU 官方发布目录](https://ftp.gnu.org/gnu/binutils/binutils-2.44.tar.xz)。[GNU 2.44 发布公告](https://lists.gnu.org/archive/html/info-gnu/2025-02/msg00001.html) 公布了同一 SHA256：

```text
ce2017e059d63e67ddb9240e9d4ec49c2893605035cd60e92ad53177f4377237
```

本地下载的 `binutils-2.44.tar.xz` 的 SHA256 完全一致。校验之后才解压和构建；没有下载或运行预编译的第三方工具。没有修改官方源码。未做独立 GPG 签名验证；这里的校验边界是通过 HTTPS 获取官方源包，并与官方发布公告的摘要一致。

本次 objdump 二进制 SHA256：

```text
a2d70ddcd641aa9f88b4b4b8896bf33b86677279dca21d6b5c74274d6e06d0da
```

具体源码、工具、编译器和宿主链接记录见 `tool_manifest.json`。该工具是本机 Apple Clang 编译的 arm64 宿主程序；只链接系统 `libSystem.B.dylib` 与 `libz.1.dylib`。这个摘要记录本次构建产物，不构成跨机器可重复二进制哈希的主张。

## 3. 构建配置与复现

在本目录中创建独立 `build-system-zlib` 目录，在该目录执行：

```sh
../binutils-2.44/configure \
  --target=mn10300-elf \
  --prefix='<LOCAL_WORKSPACE>/analysis/ultra_mn10300_tool_20261011/local' \
  --with-system-zlib --disable-nls --disable-werror --disable-shared \
  --disable-gprofng --disable-gprof --disable-ld --disable-gdb --disable-sim \
  --disable-libctf --disable-debuginfod --without-zstd \
  CC=clang CXX=clang++ MAKEINFO=true
make -j4 all-binutils all-gas MAKEINFO=true
```

没有执行 `make install`。`--prefix` 只指定了未使用的本目录安装目的地。`MAKEINFO=true` 跳过文档重新生成，因为本机没有 `makeinfo`。

首次构建使用源码内置 zlib，在 `fdopen` 宏与当前 macOS SDK 头文件冲突处失败；原始日志保存在 `logs/build.log`。随后用新的构建目录及 `--with-system-zlib` 成功构建，未改动任何 opcode/disassembler 表。成功配置、构建日志在 `logs/configure-system-zlib.log` 和 `logs/build-system-zlib.log`。

在本目录复现正对照：

```sh
python3 validate_official.py
```

脚本仅调用已构建的汇编器、objcopy 和 objdump，生成和解析静态对象；不执行目标对象。

## 4. 验证结果

| 验证 | 证据来源 | 结果 |
| --- | --- | --- |
| 基础 MN10300 与 AM33 汇编字节检查 | 官方 `gas/testsuite/gas/mn10300/basic.exp`，29 个 `.s` 文件 | 1,024 / 1,024 个官方字节正则匹配 |
| AM33/2.0 反汇编预期 | 官方 `am33-2.s` 与 `am33-2.d` | 1,310 行严格按顺序匹配，无额外非空行 |
| PR11973 反汇编回归样例 | 官方 `pr11973.s` 与 `pr11973.d` | 6 个预期行通过，按原样例的 `#...`/`#pass` 通配规则 |
| `-m mn10300` 原始二进制与 ELF 对照 | 官方 `add.s` | 14 条指令，46 / 46 字节完全一致 |
| `-m am33` 原始二进制与 ELF 对照 | 官方 `am33.s` | 44 条指令，136 / 136 字节完全一致 |
| `-m am33-2` 原始二进制与 ELF 对照 | 官方 `am33-2.s` | 1,294 条指令，5,694 / 5,694 字节完全一致 |
| AM30 `mulqu` 编码别名正对照 | 官方 opcode 表派生的额外短样例 | 两条指令生成指定候选片段的精确字节 |

正对照详情与输出在 `validation/official_fixture_results.json`、`validation/summary.log`、各 `.listing`、`.objdump`、`.o`、`.raw.bin` 文件。验证脚本是一个针对官方样例的轻量适配器，**没有运行完整 DejaGnu 测试套件**。原始二进制/ELF 对照只去除符号标签，以及 BFD 在原始二进制地址前增加的 `0x`；保留地址、原始字节、助记符和数值操作数比较。

## 5. 对固件研究的实质边界

这个工具提供可靠的静态解码依据，不能单独确认相机的具体 CPU 型号，也不能证明某段固件属于代码、已经解密、能够运行，或某个密码算法的运行语义成立。原始文件没有 ELF 元数据，必须由研究者选择模式与起始地址。对数据或错位的指令窗口，仍可能译出合法助记符。

官方 AM33/2.0 样例字节 `f9 a6 00` 在 `-m am33-2` 下译为 `dcpf (r0)`，在 `-m mn10300` / `-m am33` 下译为 `udfu10 0,d2`。因此“合法指令多”或者“unknown 少”不足以确认变体。

### AM30 乘法编码为何显示为 UDF

官方 `opcodes/m10300-opc.c:1243-1245` 把 `f914` / `fb14` / `fd14` 相应格式定义为通用 `udfu01`。该表的 `:1296-1298` 又将这些编码定义为 AM30 的 `mulqu`；与本次候选对应的 32 位立即数形式具有相同 opcode、mask 和 `IMM32, DN0` 操作数。8 / 16 位形式的有符号操作数描述存在差别，本报告不据此推断其语义。`include/opcode/mn10300.h:165` 定义 AM30 = 300，BFD 的 `bfd_mach_mn10300` 同样为 300；反汇编器按 opcode 表的顺序找首个匹配项（`opcodes/m10300-dis.c:31-83`），所以更早的 `udfu01` 名称会覆盖后面的 `mulqu` 别名。不能仅由这个显示名称否定乘法语义。

额外正对照源 `validation/am30_mulqu_alias.s`：

```asm
.text
.am30
mulqu 1664525,d1
mulqu 1566083941,d1
```

未改动的官方汇编器生成：

```text
fd 15 0d 66 19 00 fd 15 65 8b 58 5d
```

对应反汇编仍显示 `udfu01 1664525,d1` 和 `udfu01 1566083941,d1`。这确认了候选字节与官方 AM30 `mulqu` 编码别名吻合；算法上下文、手册或运行证据仍用于判断实际语义，不据此声称具体硬件型号或专有扩展已确认。
