本阶段针对 `.CAM`（相机配置导入/导出链 `SetupFilesConfigSetting`）在已解包反汇编中的静态调用流与数据边界进行证据审计，结果如下：

---

### 一、 字段与调用表（静态反汇编追踪）

| 流水线阶段 | 汇编文件与行号 | 关键指令与操作数 | 字段/行为审计说明 |
| :--- | :--- | :--- | :--- |
| **内存缓冲申请** | `tether_app` [148311-148319](file://<LOCAL_WORKSPACE>/analysis/tether_2_12_app_arm64_disassembly.txt#L148311-L148319) | `mov w0, #0xf00000; bl __Znam` | 分配 **15 MB**（`0xf00000` = 15,728,640 字节）固定缓冲区上限，**非**真实文件长度 |
| **文件原始读取** | `tether_app` [148377-148397](file://<LOCAL_WORKSPACE>/analysis/tether_2_12_app_arm64_disassembly.txt#L148377-L148397) | `fopen(..., "rb")`<br>`istream::read(buf, 0xf00000)` | 盲读至多 15MB；行 148396-148397 提取实际读取字节数存入栈 `[sp, #0x24]` |
| **Magic/头校验** | `tether_app` [148380-148410](file://<LOCAL_WORKSPACE>/analysis/tether_2_12_app_arm64_disassembly.txt#L148380-L148410) | **无任何头比对** | 仅比对模式字符串 `"ALL"`/`"SELECTED"`，**宿主端零 Magic、零格式头检查** |
| **校验和/计算** | `tether_app` [148390-148450](file://<LOCAL_WORKSPACE>/analysis/tether_2_12_app_arm64_disassembly.txt#L148390-L148450) | **无校验计算** | 宿主未计算 CRC32、SHA、MD5，亦无加解密逻辑 |
| **相机兼容性查询** | `tether_app` [148489](file://<LOCAL_WORKSPACE>/analysis/tether_2_12_app_arm64_disassembly.txt#L148489), [148501-148533](file://<LOCAL_WORKSPACE>/analysis/tether_2_12_app_arm64_disassembly.txt#L148501-L148533)<br>`tether_ptp` [37980](file://<LOCAL_WORKSPACE>/analysis/tether_2_12_ptp_arm64_disassembly.txt#L37980), [38026-38034](file://<LOCAL_WORKSPACE>/analysis/tether_2_12_ptp_arm64_disassembly.txt#L38026-L38034) | `bl Get_Compatible`<br>PTP Opcode `0x940a`（参数 `0x800a4`） | 兼容性由相机判定返回；宿主仅检查返回值 `[sp, #0x108] == 1` |
| **相机缓冲上限比对** | `tether_app` [148521-148540](file://<LOCAL_WORKSPACE>/analysis/tether_2_12_app_arm64_disassembly.txt#L148521-L148540) | `bl Get_MaxRecvBuff`<br>`cmp w9, w8; b.ls ...` | 读取相机最大接收限制，仅判定 `真实文件长度 <= MaxRecvBuff` |
| **PTP 数据打包下发** | `tether_app` [148753](file://<LOCAL_WORKSPACE>/analysis/tether_2_12_app_arm64_disassembly.txt#L148753), [148832](file://<LOCAL_WORKSPACE>/analysis/tether_2_12_app_arm64_disassembly.txt#L148832), [149032](file://<LOCAL_WORKSPACE>/analysis/tether_2_12_app_arm64_disassembly.txt#L149032)<br>`tether_ptp` [37553-37561](file://<LOCAL_WORKSPACE>/analysis/tether_2_12_ptp_arm64_disassembly.txt#L37553-L37561), [37720-37780](file://<LOCAL_WORKSPACE>/analysis/tether_2_12_ptp_arm64_disassembly.txt#L37720-L37780) | `LMX_CopyMemory`<br>PTP Opcode `0x9422` / `0x9423`<br>`Lmx_lib_wpdif_SendCommand` | 协议库在原始字节流前追加 12 字节控制头（Subcode `0x800a2`+长度），**全块盲透传**下发 |
| **配置保存导出链** | `tether_app` [147994](file://<LOCAL_WORKSPACE>/analysis/tether_2_12_app_arm64_disassembly.txt#L147994), [148048](file://<LOCAL_WORKSPACE>/analysis/tether_2_12_app_arm64_disassembly.txt#L148048), [148153-148156](file://<LOCAL_WORKSPACE>/analysis/tether_2_12_app_arm64_disassembly.txt#L148153-L148156)<br>`tether_ptp` [37199](file://<LOCAL_WORKSPACE>/analysis/tether_2_12_ptp_arm64_disassembly.txt#L37199), [37270](file://<LOCAL_WORKSPACE>/analysis/tether_2_12_ptp_arm64_disassembly.txt#L37270) | `Get_Data` -> `ostream::write` | 从 PTP 接收原始 buffer 后直接写入文件，无格式封装 |

---

### 二、 可证明结论

1. **电脑端为绝对“全透明透传管道”【实证】**：
   电脑端 Tether 软件（`tether_app` 及 `tether_ptp`）在导入 `.CAM` 时，**完全不解析文件结构、不验证 Magic、不校验 Checksum/签名、不转换任何配置字段**（行 148377-148397、37636）。电脑端不存在任何可离线逆向的“配置编码器/解析器”。
2. **15MB 仅为内存池上限，非配置镜像大小【实证】**：
   `0xf00000` 是宿主为防止大文件溢出而预先通过 `operator new[]` 分配的静态临时缓冲区（行 148311-148313）；传输与保存的实际载荷长度由 `read` 读取字节数与相机的 `Get_MaxRecvBuff` 动态裁决（行 148396、148539）。
3. **兼容性裁判权完全在机身内部【实证】**：
   `Get_Compatible`（行 37980）通过标准扩展 PTP 指令 `0x940a` 请求机身，机身返回标志位存入 `[sp, #0x108]`，电脑只做 `== 1` 的布尔判断（行 148501-148533）。

---

### 三、 未验证猜测（警惕逻辑伪证）

1. **整块传输 ≠ 绕过 UI 限制【未证实】**：
2. **整块传输 ≠ 全量机身内存镜像【未证实】**：
   载荷可能仅是机身特定 NVRAM 块、结构化 TLV 配置表或包含机身私有校验和的序列化数据，不能推断为直接映射的硬件物理寄存器镜像。
3. **电脑未加密 ≠ 机身无解密/校验机制【未证实】**：
   电脑未对 `.CAM` 施加密码学处理，仅证明电脑端无密匙介入；机身固件内部完全可能内置自身专用的 CRC32/散列校验甚至机身私钥校验。

---

### 四、 最小离线验证脚本思路（无需连机）

1. **熵值测定（Entropy Check）**：
   - 提取文件前 1KB 及全文件香农熵。若熵值接近 8.0 且全字节均匀，表明载荷高熵（机身加密/压缩）；若存在明显的 ASCII 字符串或大段 `0x00`/低熵分布，证明为明文结构体。
2. **头结构与静态特征提取**：
   - 检查偏移 `0x00-0x20` 是否含有固定 Magic（如机型编码、版本号、大端/小端声明）。
   - 检查文件末尾或头部固定偏移是否存在 4 字节/8 字节校验字段（比对 CRC32/Adler32/CRC16）。
3. **单变量机身差分比对（A/B Diff）**：
   - 在真实相机上仅修改一项设置（如仅开/闭高分辨率模式，或单项快门类型）分别导出两份 `.CAM`；
   - 离线按字节做 XOR 差分：若差异仅局限于极少数固定偏移量且无全局雪崩扩散，即实证为**局部固定偏移明文配置**，届时方可精确计算位字段（Bitfield）。
