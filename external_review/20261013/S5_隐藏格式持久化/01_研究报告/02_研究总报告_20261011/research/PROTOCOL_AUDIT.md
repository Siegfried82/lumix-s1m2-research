> **Codex核验评论（2026-10-13）**：以下正文是外部作者材料的公开副本。收录不等于证实；作者说法与本项目核验分开。原稿 SHA-256：`c0613f7e3012ec2f49a445c1094349688f8662b408bf16c463b25584dbc03142`。原稿行号仍按未注释原件计算。
> 参见[该包纠错总评](../../../CODEX_REVIEW.md)；未在本轮执行其脚本、设备请求或录像实验。

# LUMIX 相机 HTTP 协议审计（cam.cgi / 传输层 / 下载）

> 审计依据：`jadx_out/sources/p168v5/a.java`（相机 API 门面，全部 cam.cgi 命令）、`p168v5/n.java`（URL 构建）、`p168v5/m.java` + `p094l5/*`（HTTP 传输层）、`p133q5/a.java`（评分调用方）、`com/panasonic/jp/service/*`（握手调用方）。
> 结论分级：✅ = 源码逐行核实；⚠️ = 部分核实或与 README 表述不同；❌ = 官方 app 中不存在。

---

## 1. 传输层（✅）

- 基址 `http://<ip>`，命令统一为 GET：
  `http://<ip>/cam.cgi?mode=<mode>&type=<type>&value=<value>&value2=<value2>`
  其中 `type`/`value`/`value2` 为 null 时**不拼接**该参数（`n.c()`，见下）。
- **User-Agent 固定为 `LUMIX Sync`**（`p094l5/e.java:39`；文件下载类 `d` 继承 `e`，同样带此 UA）。
- **`X-SESSION_ID` 请求头**：仅当会话令牌非空时附加（`p094l5/b.java:89`）。S5 不签发令牌（见 §2.6），因此 app 从不发此头；S5Monitor 忽略会话是正确的。
- 超时：默认 10000 ms；`camcmd`/`camctrl`/`getstate`/`get_content_info` 用 3000 ms；`playcmd` 用 10000 ms。
- 重试：每命令最多 5 次；`err_busy` 时退避 1000 ms 重试（`err_busy`/`err_reject`/`wait` 等语义不同命令略有差异）。
- 响应解析：按 `Content-Type` 判定——`text/xml` 走 XML 解析，否则按 CSV/纯文本。

### URL 构建（`p168v5/n.java`，✅）

门面统一调用 `n.c(mode, type, value, value2)`，源码（原样）：

```java
public static String c(String str, String str2, String str3, String str4) {
    String str5 = "/cam.cgi?";
    if (str != null)  str5 = "/cam.cgi?" + String.format("mode=%s", str);
    if (str2 != null) str5 = str5 + String.format("&type=%s", str2);
    if (str3 != null) str5 = str5 + String.format("&value=%s", str3);
    if (str4 == null) return str5;
    return str5 + String.format("&value2=%s", str4);
}
```

参数顺序恒为 `mode → type → value → value2`，为 null 的字段整体跳过（不拼接空参数）。

---

## 2. 命令面（mode 全集，✅ 逐行核实自 `a.java`）

| mode | type（实参） | value / value2 | 说明 |
|---|---|---|---|
| `camcmd` | 调用方传入（`poweroff`/`recmode`/`playmode`/`pictmode`/…） | — | 电源/模式切换 |
| `camctrl` | `focus`、`af_ae_lock`、`touch`、`touch_trace`、`pinch`、`asst_disp`、`change_disp_mag`、`frame_ctrl`、`fw_update_mode`、`lens_fw_update_mode`、`hrs`、`interval`、`livecomp`、`program_shift`、`shtrspeed_syncro`、`stop_motion`、`touchae_ctrl`、`touchaf_chg_area`、`touchaf_chg_pos`、`touchcapt_ctrl` | value/value2 | 实时控制（对焦/触摸/放大/直播等） |
| `setsetting` | `device_name`、`photostyle`、`photostyle2`、`peaking`、`colormode`、`current_sd`、`overlay`、`raw_img_send` | value=新值 | 写设置（门面 `L`） |
| `getsetting` | `photostyle`、`photostyle2`、`colormode`、… | — | 读设置（门面 `E`/`y`） |
| `getstate` | `keep_alive` / 空串 | — | 状态轮询（门面 `F`） |
| `getinfo` | `curmenu`、`lens`、`allmenu`、`camsetting`、`capability` | — | 菜单/镜头/能力；`camsetting` 走二进制通道（要求响应 `application/octet-stream`） |
| `get_content_info` | **空**（type 缺省） | `value=dir_id_*` | 目录内容（见 §2.4） |
| `getprogress` | **空串** | — | 传输进度（见 §2.5） |
| `accctrl` | `req_acc`、`req_acc_g`、`req_acc_e`、`req_acc_can` | value=设备名、value2=网络名 | 会话握手（见 §2.6） |
| `notify` | `transfer` | — | 传输通知 |
| `playcmd` | `start`、`stop`、`pause`、`restart`、`setplayscene` | — | 回放控制 |
| `editcmd` | `rating` | value=文件、value2=1–5 | 照片评分（`p133q5/a.java:430` 实调 `t("rating", file, "5")`） |
| `startstream` | — | value=UDP 端口（49152–65535） | 取景流 |
| `stopstream` | — | — | 停止取景流 |
| `startsenddata` | `camsetting`、`fw` | — | 上传会话（见 §3） |
| `senddata` | —（multipart body） | — | 上传数据块 |
| `requestsenddata` | — | — | 请求下一块 |
| `endsenddata` | — | — | 结束上传 |
| `abortsenddata` | — | — | 中止上传 |

### 2.1 目录 ID（`get_content_info`，✅）

`dir_id` 是**字面令牌**，直接放进 `value`，app 内无 `/DCIM/...` 路径映射（路径由相机内部解析）。实际出现的令牌：

```java
"dir_id_sd_auto_upload"   // 自动上传目录（com/panasonic/jp/view/play/browser/e.java:397）
"dir_id_mark_list"        // 标记列表（J5/f.java:253）
"dir_id_sd_mp4_only"      // 仅 SD 上的 MP4（p140r5/u.java:40）
"dir_id_mem_mp4_only"     // 仅内存卡上的 MP4（p140r5/u.java:40）
```

### 2.2 设置键（`setsetting`/`getsetting`，✅）

`photostyle` / `photostyle2` 是 LUT/照片风格选择，**不是** LUT 文件传输；传输面见 §3.2。

### 2.3 评分（`editcmd rating`，✅）

```java
// p133q5/a.java:430
this.f24894T.t("rating", file, Integer.toString(1..5));
// → /cam.cgi?mode=editcmd&type=rating&value=<file>&value2=<1-5>
```

### 2.4 `get_content_info` 的 dir_id 位置（⚠️ 关键修正）

门面 `z(str, str2)` = `n.c("get_content_info", str, str2, null)`，调用为：

```java
z(null, "dir_id_sd_auto_upload");  // type=null, value=字面令牌
```

→ 正确 URL：`/cam.cgi?mode=get_content_info&value=dir_id_sd_auto_upload`（**dir_id 令牌在 `value`，`type` 缺省**）。
若实现把 dir_id 放 `type`（`get_content_info&type=dir_id_sd_auto_upload`），与官方不符，需修正。

### 2.5 `getprogress`（⚠️ 修正）

门面 `W(str, ...)` 用 `this.f27240s`（默认空串）作 type，即 `/cam.cgi?mode=getprogress`（无 type/value）。响应为 CSV：`状态,百分比`（`err_busy` → 重试；`exec`/`finish` → 带百分比；`error` → 带错误码）。

### 2.6 握手 `accctrl`（✅，与 README 结论一致）

```java
m(stringBuffer, "req_acc"|"req_acc_e", 设备名, 网络名);
// → /cam.cgi?mode=accctrl&type=req_acc&value=<设备名>&value2=<网络名>
```

- S5 回 4 字段 `ok_under_research_no_msg,<型号>,remote,encrypted`，**无第 5 字段（令牌）**。
- app 仅当首字段 `ok` 且 ≥5 字段时才存令牌；S5 不满足 → app 从不存会话、从不发 `X-SESSION_ID`。
- `req_acc_g`（加密握手）→ `err_param`；`req_acc_e`（加密请求）→ `err_param`。本机不支持。
- 响应第 3 字段（权限）判定：`upload`/`upload_bt`/`transfer` 才视为可上传；S5 返回 `remote` → 上传路径也走不通（与固件上传 `err_critical` 实测一致）。

---

## 3. 上传（`startsenddata` 时序，✅）

`a.java` 门面 `N`/`O` + `J`（senddata）+ `I`（requestsenddata）+ `u`（endsenddata）+ `l`（abortsenddata）。

时序：`startsenddata` →（`senddata` × N 块）→ `requestsenddata`（续块确认）→ `endsenddata`；失败 `abortsenddata`。

- `startsenddata` 响应含 `h()` 字段：`once` = 单块整包、`separate` = 分块、`a()` = 相机上报的最大块长。
- 分块大小 = 相机上报 max − multipart 开销 `V()`（`Content-Length: 61460` → 数据块 61460 B + 边界头开销）。
- `senddata` 为 multipart/form-data：`filename="send"`，`Content-Type: application/octet-stream`。

### 3.1 `startsenddata` 的 type 白名单（⚠️ 关键）

```java
// 设置备份：com/panasonic/jp/view/bluetooth/CameraSettingActivity.java:219
N("camsetting", 版本号, null, 数据, 长度);
// 固件：com/panasonic/jp/view/setting/FwUpdateActivity.java:2228 / InformationContentActivity.java:2298
N/O("fw", ...);
```

源码中 `startsenddata` 的 type **只有 `camsetting` 与 `fw` 两种**。

### 3.2 LUT / 照片风格上传（❌ 官方无此协议）

- 全源码无 `.vlt`/`.cube`/`lut` 文件传输；LUT 相关匹配只有 UI 资源 `lvf_image_ctrl_lut_1..10`（取景 UI 上显示当前 LUT 的图标），以及 `setsetting photostyle/photostyle2`（选择机内已装载的照片风格）。
- LUT 文件装载在 S5 上走 SD 卡（机内读取），LUMIX Sync **不通过 HTTP 上传 LUT**。
- **结论：S5Monitor 若用 `startsenddata&type=photo_style`（或自定义 type）传 LUT，属于无依据的自创协议，需改成机内装载或标注「未验证」。**

---

## 4. 下载 / 文件访问（⚠️ 与 README 表述需修正）

官方 app **不用** `http://<ip>/DCIM/...` 拉文件，而是 DLNA ContentDirectory：

- 控制端点（SOAP `Browse`）：`http://<ip>:60606/Server0/CDS_control`（`p154t5/a.java:213`）
  - `SOAPAction: urn:schemas-upnp-org:service:ContentDirectory:1#Browse`（`p168v5/m.java:84`）
  - `User-Agent: Panasonic MIL DLNA CP UPnP/1.0`（`p168v5/m.java:85`）
- 数据端点：`http://<ip>:60606/Lumix/Server0/ddd`（`p168v5/a.java:882` `T()`）
- 缩略图：请求头 `X-CONVERT: MediumSize|SmallSize`（`p094l5/d.java:109-111`）。
- 大小：响应头 `X-FILE_SIZE`；剩余空间不足时回 `notRemain` 并抛 `LargeData`。

S5Monitor 用的 `http://<ip>/DCIM/<path>` 是另一条**未见于官方 app** 的路径（若经实测可用，属相机额外暴露的静态 HTTP，不属 LUMIX Sync 协议）。

---

## 5. 与 S5Monitor 相关的结论清单

| 项 | 结论 |
|---|---|
| 删除照片 | ❌ 官方无任何删除命令（无 `delimage`/`delete`/`camcmd delimage`）；`delete` 字符串只出现在 DLNA 能力解析（云自动上传相关），不删除相机文件。S5Monitor 的删除功能无协议依据。 |
| LUT 上传 | ❌ 无协议依据（§3.2）。 |
| 文件下载 | ⚠️ 官方走 DLNA 60606；`http://ip/DCIM` 为旁路（§4）。 |
| `get_content_info` | ⚠️ dir_id 在 `value`，不在 `type`（§2.4）。 |
| `getprogress` | ⚠️ 无 type 参数（§2.5）。 |
| User-Agent | ✅ 必须 `LUMIX Sync`。 |
| X-SESSION_ID | ✅ S5 不签发、可不发。 |
| 握手 | ✅ `accctrl&type=req_acc` 4 字段、无令牌（§2.6）。 |
| 上传 type | ✅ 仅 `camsetting`/`fw`（§3.1）。 |
