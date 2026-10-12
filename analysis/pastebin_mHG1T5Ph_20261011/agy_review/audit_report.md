# Pastebin `mHG1T5Ph` (GX9 `videoquality`) 离线证据边界审计报告

审计日期：2026-10-11  
工作目录：`<LOCAL_WORKSPACE>`  
范围声明：严格离线静态审计。仅作为纯文本读取 `analysis/pastebin_mHG1T5Ph_20261011/source.txt`（SHA-256: `74a293fa97fd0bf14c5673991773d620f7d386e4742abea0f77ecdd25a1b285a`），未打开或请求任何 `192.168.54.1` 链接，未与相机通信，未执行任何供应商二进制或脚本，未修改任何既有文件。

---

## 1. 来源作者主张（Source Author Claims）与原始材料缺口

`analysis/pastebin_mHG1T5Ph_20261011/source.txt`（共 109 行，4347 字节）是一份静态 HTML 页面（标题 `High Bitrate Video Deployer`，第 7、44 行），作者单方面主张如下：

1. **目标机型与固件**：声称适用于 Lumix GX9（第 47 行），在 FW 1.5 测试（第 51 行）。
2. **连接与切换序列（第 60–64 行）**：
   - 连续两次请求 `/cam.cgi?mode=accctrl&type=req_acc&value=4D454930-0100-1000-8001-020000025AD6&value2=iPhone`（第 60、62 行）；
   - 请求 `/cam.cgi?mode=camcmd&value=recmode`（第 64 行）。
3. **隐藏视频参数设置（第 82–90 行）**：通过 `/cam.cgi?mode=setsetting&type=videoquality&value=<val>` 发送 8 个未在 GX9 机身菜单公开的 MOV 参数值：
   - PAL 组（第 82–85 行）：`mov_25p_100mbps_4k`、`mov_50p_50mbps`、`mov_50p_100mbps`、`mov_50p_200mbps`；
   - NTSC 组（第 87–90 行）：`mov_24p_100mbps_4k`、`mov_60p_50mbps`、`mov_60p_100mbps`、`mov_60p_200mbps`。
4. **响应与效果主张（第 79–80、92–94、101–103 行）**：
   - 声称请求成功时相机返回 `"ok"`，且因机身 UI 不正式支持 `*.mov` 而不显示画质图标（第 92–94 行）；
   - 声称最高 100mbps 录制稳定，且文件分析显示 `100mbps` 档位实际码率高于 `200mbps` 档位（第 79–80 行）；
   - 声称可保存到机身自定义模式 `C1`/`C2`/`C3` 持久化，或在 Q-Menu 点选标准画质恢复（第 101–103 行）。

**来源材料本身证实的缺口**：该文件仅有 HTML 超链接与作者文字叙述，**没有任何原始 HTTP 响应抓包、前后状态/配置读回文件，也没有任何实际录制的 MOV 样本或媒体流元数据证明**。

---

## 2. 已确认事实（Confirmed）：本仓库客户端、菜单与能力材料核对

### 2.1 解析器（Parser）与发送器（Sender）的严格区分

在 LUMIX Sync 2.0.17 静态反编译代码（`analysis/sources/lumix_sync_static/decompiled/sources/`）及 DEX CGI 调用索引（`analysis/sources/lumix_sync_static/dex_cgi_references.jsonl`）中，**客户端对 `"videoquality"` 字面量的直接引用全部位于 XML 解析器（且解析结果均无外部消费），不存在硬编码 `"videoquality"` 或 `mov_*` 的发送器**：

1. **`B5/o.java`（仅 XML 响应解析器，且字段悬空未消费）**：
   - `B5/o.java:381-382`：在 `private void U(XmlPullParser)`（第 371–412 行，由 `q(XmlPullParser)` 第 530–531 行在遇到 `<settingvalue>` 标签时调用）中读取属性 `videoformat`（写入 `this.f828F`，第 32 行）与 `videoquality`（写入 `this.f829G`，第 35 行）。
   - **关键定位**：`B5/o.java:667-756` 的全部公开 getter 方法中，**不存在**返回 `f828F` 或 `f829G` 的方法；在整个 `decompiled/sources/` 中，`f829G` 仅在 `B5/o.java:35, 181, 382, 790` 出现（声明、初始化 `null`、解析赋值），**零外部读取**。
   - 当客户端发送 `setsetting`（`B5/a.java:561-562, 588-589`）后构造 `new B5.o(strC, Y(strC))` 时，仅调用 `oVar2.o()`（`B5/o.java:749-751`）检查 `<result>ok</result>` 或 CSV 首字段 `"ok"`，以及 `oVar2.g()`（第 702–704 行）检查错误码，**并不从 `B5.o` 读取设置生效值**。
   - 另：`B5/a.java:376-409`（`E(String)`）与 `:1472-1502`（`y(String)`）发送 `mode=getsetting&type=<str>` 并用 `p188x5/D.java:34-35, 51-53` 读取 `<settingvalue>` 对应属性；按 `dex_cgi_references.jsonl`（第 111, 113, 154, 198, 260, 275 行），全库仅对 `"ex_tele_conv"`（`com/panasonic/jp/service/c.java:238`）、`"touch_type"`（`c.java:247`）、`"qmenu_disp_style"`（`com/panasonic/jp/view/liveview/i.java:3284`）、`"mf_asst"`（`i.java:9033` -> `B5/k.java:8`）和 `"play_sort_mode"`（`com/panasonic/jp/view/play/browser/j.java:311`、`PlaybackSettingActivity.java:204`）调用过 `E()`，从未请求 `"videoquality"`。

2. **`p188x5/o.java`（仅 `capability` XML 延时摄影子项解析器，且结果未导出）**：
   - `p188x5/o.java:353`：在 `private M P(XmlPullParser)`（第 347–366 行）中匹配 `<videoquality>` 子元素，调用 `R(XmlPullParser)`（第 390–414 行）提取 `name` 和 `value` 属性构造 `p188x5.L`（`p188x5/L.java:18-21`）及 `<framerate>` 子元素（`O(XmlPullParser, boolean)`，第 333–345 行），由 `Q(XmlPullParser)`（第 368–388 行，对应 `v(XmlPullParser)` 第 749–750 行 `<stopmotiontset>` -> 第 376–377 行 `<stopmotionlist>`）存入 `this.f30168c.put("stopMotionDirInfo", P(xmlPullParser))`（第 377 行）。
   - **关键定位**：`p188x5/o.java:860-870` 返回的包装类 `p188x5/C2211j.java`（第 1–360 行）**没有任何方法读取 `"stopMotionDirInfo"`**；且 `p188x5/L.java:16, 20` 中保存 `value` 属性的 `private String f30085c` **没有 getter 方法**（`L.java:31-33` 仅提供返回 `name` 的 `b()`）。

3. **CGI 发送器（`B5/n.java`、`B5/a.java`、`G5/a.java`、`com/panasonic/jp/view/setting/c.java`）**：
   - URL 拼接器：`B5/n.java:15-30` 的 `c(mode, type, value, value2)` 生成 `/cam.cgi?mode=%s&type=%s&value=%s&value2=%s`。
   - 握手与模式切换对应：`source.txt:60-64` 的 `mode=accctrl&type=req_acc&value=...&value2=...` 与 `mode=camcmd&value=recmode` 分别对应客户端发送器 `B5.a.m()`（`B5/a.java:976-1014`，由 `com/panasonic/jp/service/c.java:686` 和 `com/panasonic/jp/service/a.java:420` 在 `Normal` 模式下传入 `"req_acc"`）以及 `B5.a.n(null, "recmode", null)`（`B5/a.java:1016-1041, 1192`）。
   - 直接 `setsetting` 发送器 `B5.a.L(type, value, value2)`（`B5/a.java:582-606`）：在 `dex_cgi_references.jsonl` 中共有 20 处调用（第 93, 94, 102, 107, 108, 115, 123, 124, 138–142, 151–153, 160, 163, 241, 258 行），实参固定为 `raw_img_send`（`ImageAppTotalService.java:603, 605`、`service/a.java:446, 448`、`service/c.java:857, 859`）、`device_name`（`service/a.java:339`、`service/c.java:557`）、`focal`/`shtrspeed_angle`/`shtrspeed`（`liveview/b.java:120, 175, 194, 198`）、`sensitivity_db`（`liveview/c.java:49, 108`）、`iso`（`liveview/d.java:49, 108`）、`whitebalance`（`liveview/e.java:50, 114`）、`exposure`（`liveview/f.java:55, 141`）、`photostyle`/`photostyle2`/`colormode`/`peaking`/`overlay`（`liveview/i.java:3208, 3241, 3272, 3440, 3483`）、`creativectrl`/`filter_setting`/`sceneguide`（`liveview/k.java:46, 119, 123, 127`）、`current_sd`（`play/browser/j.java:241`），**无一处传入 `"videoquality"`**。
   - 通用菜单命令发送器 `B5.a.K(mode, type, value, value2)`（`B5/a.java:555-580`）：在 `dex_cgi_references.jsonl` 中仅有 `G5/a$a.run` 的 5 处调用（第 62–66 行，对应 `G5/a.java:82, 84, 106, 108`）。其上游入口 `G5.a.l`/`m`（`G5/a.java:284-301`）由 `com/panasonic/jp/view/setting/c.java:734, 741, 749, 754` 调用（另有 `PlaybackSettingActivity.java:156` 传 `"play_sort_mode"`），所传四元组 `(f30140f, f30141g, f30142h, f30143i)` 完全来自 `p188x5/C2203b.java:47-63` 解析相机 `/cam.cgi?mode=getinfo&type=allmenu` 响应（`B5/a.java:1387-1414`、`com/panasonic/jp/service/c.java:871`）得到的 `<item cmd_mode="..." cmd_type="..." cmd_value="..." cmd_value2="...">`。**即客户端不会自行生成隐藏 `videoquality` 参数，只回传相机 `allmenu` 已声明的菜单项**；且在 `oVarK.o()` 返回真后，立即调用 `B5.a.A()`（`G5/a.java:110-111, 122-124` -> `B5/a.java:297-324` `getinfo&type=curmenu` -> `p188x5/t.java:81-91, 244-250`）刷新当前菜单状态。

4. **静态原生库证据核对**：
   - `analysis/sources/lumix_sync_static/native_methods.jsonl`（42 个 native 声明）与 `native_inventory.json`（6 个 arm64 共享库，含 `libdlnaCore.so` 等）及 `原生接口核验_20261010.md`、`JNI导出对应核验_20261010.md` 确认：原生层仅涵盖 DLNA/UPnP（设备发现、订阅、媒体浏览/删除）、G711 音频、丢包补偿、Barhopper 与图像转换，**不包含 `cam.cgi` 的 `setsetting/videoquality` 发送或视频画质控制逻辑**。

### 2.2 S5 菜单样本对照（`PR1鉴权与菜单资料复核.md`、`codex_pr1_document_audit.json`）

- `codex_pr1_document_audit.json:388-402` 记录 `camera_api/lumix_allmenu.xml`（标注机型 `S5`，非 S1M2）共有 666 个 `cmd_mode="setsetting"` 菜单项，其中包含 `videoformat`（`mov`/`mp4`/`mp4hevc`，第 2907–2923 行）与 44 条 `videoquality` 四元组（第 2925–3187 行；另 `lumix_capability.xml` 含 `stopmotiontset` 下 `videoquality` 列表，第 332–338、360–363 行）。
- 将 GX9 `source.txt:82-90` 的 8 个 `mov_*` 值与 S5 `allmenu.xml`（`codex_pr1_document_audit.json:2925-3187`）逐项比对：
  - **4 项在 S5 `allmenu` 中完全一致存在**：
    - `["setsetting", "videoquality", "mov_24p_100mbps_4k", ""]`（第 2937–2941 行，对应 `source.txt:87`）
    - `["setsetting", "videoquality", "mov_25p_100mbps_4k", ""]`（第 2979–2983 行，对应 `source.txt:82`）
    - `["setsetting", "videoquality", "mov_50p_100mbps", ""]`（第 3051–3055 行，对应 `source.txt:84`）
    - `["setsetting", "videoquality", "mov_60p_100mbps", ""]`（第 3081–3085 行，对应 `source.txt:89`）
  - **其余 4 项不在 S5 `allmenu` 中**：`mov_50p_50mbps`、`mov_50p_200mbps`、`mov_60p_50mbps`、`mov_60p_200mbps`（S5 对应位置为 `mov_50p_150mbps_4k` 第 3065 行、`mov_50p_200mbps_4k_10bit` 第 3077 行、`mov_60p_150mbps_4k` 第 3095 行、`mov_60p_200mbps_4k_10bit` 第 3107 行等）。

### 2.3 PTP 能力整数边界（`acquired_capabilities_decoded_20261008.json`、`curated_vendor_capabilities_20261008.json`）

- `curated_vendor_capabilities_20261008.json`（第 1–506 行）定位自 `analysis/tether_2_12_ptp_arm64_disassembly.txt` 的 PTP opcode `37128`（`0x9108`）及 32 位整型参数（如 `0x02000010` 对应 `33554448`，第 399–414 行）；`acquired_capabilities_decoded_20261008.json`（第 1–200 行）解码的是二进制 PTP 响应中的无符号整数枚举（`enum_values_raw`，第 3 行明确注明 `semantic enum mapping pending`）。
- **边界结论**：这些是 USB/PTP 协议层的整数枚举值，**不是 HTTP `cam.cgi` 的字符串参数（如 `mov_25p_100mbps_4k`），不能作为 S1M2 支持相同 HTTP `videoquality` 字符串或存在隐藏 MOV 档位的证据**。

---

## 3. 有限推断（Bounded Inferences）与对 S1M2 当前研究的参考价值

对照 `研究推进_20261011_Ultra.md` 当前状态，对该 GX9 经验的判断如下：

1. **绝不等同于固件解密、任意写或 S1M2 原生支持**：
   - `source.txt` 的机制是：松下多代机型共用 `cam.cgi?mode=setsetting&type=videoquality&value=mov_...` 命名规范（S5 `allmenu` 已证实其中 4 个字符串为松下真实协议枚举）；若某机型（如作者声称的 GX9）固件内部命令表保留了对应分支、仅在机身 UI/`allmenu` 中隐藏，则发送该 HTTP 请求可切换到固件已有的表项并被自定义模式（`C1`–`C3`）随配置保存。
   - 这属于**调用机身固件内已编译存在的配置表项**，与 S1M2 固件容器解码（`header+0x08=0x200`、`selector +0x34=3`，见 `研究推进_20261011_Ultra.md:5-11, 58-61`）完全无关，既不提供 S1M2 程序明文，也不能写入固件原本不存在的功能；且官方 LUMIX Sync 2.0.17 支持列表未包含 S1M2（`取得与鉴权链核验.md:17`）。

2. **对“把‘请求 ok’推进到‘真实功能改变’验收”的具体方法学价值**：
   - **为什么单看 `"ok"` 不可验收**：无论在 `source.txt:79-80, 92-94`（作者自述 `200mbps` 同样返回 `"ok"` 但实际码率反而低于 `100mbps`，且屏幕无图标），还是在客户端 `B5/a.java:562, 589` -> `B5/o.java:749-751`（只检查 `<result>ok</result>`），`"ok"` 仅代表 HTTP/PTP 接口语法接受请求，不代表机内编码器/功能按字面参数生效（正如 `研究推进_20261011_Ultra.md:7, 84` 中电子快门声音实验仅切换了内置选项而非导入自定义音频）。
   - **可复用的三级独立验收链（替代盲目枚举写命令）**：
     1. **公开菜单与能力基线对照**：先通过只读接口（如 `getinfo&type=allmenu`、`getinfo&type=capability`、`getinfo&type=curmenu`，对应 `B5/a.java:1387-1414, 1438-1470, 297-324`）建立目标机型自身公开的 `(cmd_mode, cmd_type, cmd_value)` 集合，区分“公开菜单已存在选项”与“菜单未公开项”，禁止无限盲猜陌生写命令。
     2. **持久化配置前后读回差分（Config Readback Diff）**：`source.txt:101-103` 提示有效设置变更可进入自定义模式存储；对应到本仓库已核实的只读配置通道，即机身正式导出的设置文件或 `/cam.cgi?mode=getinfo&type=camsetting`（`B5/a.java:1416-1436`，见 `配置读回链核验_20261010.md:5-9` 与 `研究推进_20261011_Ultra.md:93, 96`）。正常官方操作前后的配置二进制差分可独立证明某设置位是否真实落盘，而无需凭 `"ok"` 主观断言。
     3. **输出产物与固件消费者双向验证**：对媒体参数类宣称，必须用实际生成文件的容器/码流元数据（如 `.mov` 封装结构、帧率、位深、实测码率）验收；对固件内部机理，仍必须定位到固件中实际消费该配置字段的分支（`研究推进_20261011_Ultra.md:90-93`）。

---

## 4. 证据缺口（Gaps）与下一步可独立验证的输入

| 类别 | 当前缺口 | 下一步可独立验证的只读/受控输入（不枚举陌生写命令） |
|---|---|---|
| GX9 外部案例本身 | 缺少 `source.txt` 声称的原始 HTTP 响应、C 模式保存前后配置及 `.mov` 样本 | 若需核实该外部案例本身，需提供实际录制前后的媒体样本元数据与只读状态读回，不作为 S1M2 主线阻塞项 |
| S1M2 HTTP/菜单基线 | 仅有 S5/MC801 的 `allmenu`/`curmenu`/`capability` 样本，无 S1M2 对应只读样本 | 正常官方连接下只读保存的 S1M2 `allmenu`、`curmenu`、`capability` 响应（若该接口在目标机可用），先做静态结构对照 |
| S1M2 配置落盘与真实功能验收 | 尚无正常官方操作前后的机内配置导出对照（如自定义模式 C1–C3 或 LUT 导入前后配置） | 用户已规划的正常官方操作**修改前/修改后机身配置导出文件**（SD 卡保存设置或只读 `camsetting` 响应，见 `研究推进_20261011_Ultra.md:93, 96`），用于离线字节差分定位真实配置存储偏移 |
| S1M2 固件消费者主线 | `S1m2_V14.bin` 的 49 个编码组件（`header+0x08=0x200`, `selector=3`）仍未解密 | 严格按 `研究推进_20261011_Ultra.md:90-93` 优先获取可读的新代升级器/前级消费者代码或只读运行日志 |
