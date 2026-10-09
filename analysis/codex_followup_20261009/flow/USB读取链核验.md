# Flow 1.6.0 USB/PTP 读取链核验

日期：2026-10-09。由 Codex 直接执行离线源码与 DEX 检查。没有安装 APK、执行相机请求或更改机身状态。

## 本轮实际完成

1. 定位通用 PTP 序列化、任务派发及异步 USB 传输链。
2. 列出 82 个操作码枚举，区分声明、源码引用、直接构造调用。
3. 对五个原始 DEX 遍历 29,265 个类、186,134 个带实现的方法、2,781,297 条指令，检查命令枚举字段引用，绕过 Java 反编译错误造成的遗漏。
4. 生成 USB 控制器类 `p038q0.X` 与 `RemoteUDPPacketManager` 的低级指令表示。前者输出文件名为 `USBWorker_instructions.java`，但实际主体是控制器复合类，不应按文件名误认成唯一 USB 传输任务。

## 真实调用链与参数编码

### 构造至 USB 发送

`p054w1/a.java` 是通用容器构造器：

- `a(int)` 分配小端参数缓冲区。
- `f(int)` 将一个 32 位整数写入参数缓冲区。
- `i(V)` 设置操作码，`j(c)` 设置容器类型。
- `l()` 构造 12 字节头部：长度、类型、操作码、transaction ID，后接完整参数缓冲区。

`p062z0/C1086a.java:211-245` 分配 transaction ID，将构造器结果写入 `p040r1/e`，并对取景、回放及 LUT 读取设置大块接收标志。

`p056x0/f.java` 的 `c(e)` 调用 `p020h1/q.java:120` 的 `g(e, TimeUnit)`，后者创建 `T/t` 任务。

`T/t.java:98-176` 的任务使用 Android `UsbRequest.queue` 发出容器、可选数据阶段，再用 `requestWait` 接收并交给 `p040r1/d.c(ByteBuffer)` 重组数据/响应。这是实际 USB 路径，不应仅搜索 `bulkTransfer` 就判定没有传输。

### 已定位的大块读取

| 操作码 | 调用证据 | 参数与接收用途 |
| --- | --- | --- |
| `0x9706` LuxGetLiveViewData | `p057x1/d.java:322-342` | 分配 4 字节命令参数区，所列调用片段未写入地址/长度，随后把返回交给 `onLiveViewVideoReceive` |
| `0x9906` LuxFlowGetMoviePlayData | `N0/j.java:53-70`，`ui/activity/replay/S.java:79-90` | 同样为 4 字节参数区，应用于回放数据获取；所列调用未构造任意地址参数 |
| `0x9907` LuxFlowGetMoviePlayAudioData | `p057x1/d.java:375-391` | 4 字节参数区，返回交给 `onLiveViewAudioReceive` |

这里只确定这些具体调用的业务方向，不宣布相机端对所有参数组合的语义已知。

## 命令表声明不等于使用

原始 DEX 指令中的 `Ls1/V;` 字段引用扫描结果（排除枚举类自身的初始化）：

| 操作码 | 枚举项 | 其他类中的字段引用数 |
| --- | --- | ---: |
| `0x1007` | StdGetObjectHandles | 0 |
| `0x101b` | StdGetPartialObject | 0 |
| `0x9112` | LuxGetPartialObject | 0 |
| `0x9421` | LuxExportConfigFile | 0 |
| `0x9706` | LuxGetLiveViewData | 4 |
| `0x9906` | LuxFlowGetMoviePlayData | 8 |
| `0x9907` | LuxFlowGetMoviePlayAudioData | 3 |

其中四个零引用命令虽然出现在共用枚举表，尚未定位到 Flow 使用它们的路径。三个非零读取命令的 DEX 与源码扫描计数一致。直接构造调用分别为 3、7、2，剩余引用用于接收分类判断。

这个检查涵盖所有已提供 DEX 的字段引用，不是对运行时反射、直接数值操作码、外部动态代码或相机服务器的穷尽证明。不能从零引用推断机身不支持该命令，也不能把枚举中的对象读取命令当作 RAM 读取。

## 另一个容易误认的可变整数

`p056x0/f.b(long)` 调用 `q2/c.A(long)` 与 `q2/c.z(long)`。

二者构造的是 `LuxGetCapabilityInfoSize`（`0x9107`）与 `LuxGetCapabilityInfo`（`0x9108`），把该 long 截断为整数后放入参数区；调用方随后解析能力数据。存在可变整数参数并不意味着存在内存地址参数。这两个函数已经有明确的能力信息操作码，不应从参数类型猜成物理读取原语。

## 产物与边界

- `audit_usb_commands.py` / `usb_command_inventory.json`：枚举、源码引用与直接构造位置，序列化关键语句检查通过。
- `ScanCommandRefs.java` / `dex_command_references.jsonl`：基于项目已有 dexlib2 的全 DEX 字段引用检查；执行的是本地扫描器，不是 APK 内代码。
- `USBWorker_instructions.java`、`RemoteUDPPacketManager_instructions.java`：两次定点 fallback 均正常退出，保留无法正常还原的方法的低级表示。

尚未定位 Flow 中接收物理地址与长度的读取调用，未得到固件明文或 RAM dump。下一步继续分析 UDP/TLS 请求字典及 XML 通道的实际数据方向，避免把 USB 的局部结论推广到整个 Flow。
