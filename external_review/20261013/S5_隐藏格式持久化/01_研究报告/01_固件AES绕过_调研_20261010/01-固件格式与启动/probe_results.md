> **Codex核验评论（2026-10-13）**：以下正文是外部作者材料的公开副本。收录不等于证实；作者说法与本项目核验分开。原稿 SHA-256：`1ae668069e0e5dfa1642f8d90584276b0b8f28a78ab98ad19dd610abaa619955`。原稿行号仍按未注释原件计算。
> 参见[该包纠错总评](../../../CODEX_REVIEW.md)；未在本轮执行其脚本、设备请求或录像实验。

# 相机只读隐藏命令探测结果（DC-S5, 192.168.1.131）

探测时间：2026-10-09（约 22:32–22:34）。全部为 GET 请求，无任何写操作。

## 1. 可达性

- `ping 192.168.1.131`：可达（2/2 包，RTT 5.9~232ms）。
- `GET /cam.cgi?mode=getstate`：首次返回 `<result>err_reject</result>`；后续变为 `<result>err_unsuitable_app</result>`。
- 结论：相机在线，但探测过程中状态发生变化（见第 5 节），部分命令由可用变为拒绝。

## 2. getinfo type 枚举

逐类发送 `curl -s http://192.168.1.131/cam.cgi?mode=getinfo&type=<T>`，完整响应存于 `fw_fetch/probe_results/getinfo_type_<T>.xml`。

### 返回真实数据的 type

| type | 大小 | 结果 |
|---|---|---|
| allmenu | 307714 B | `ok` + 完整菜单树（`<menuset model="S5" version="2.0" date="20201027">`），多语言 UI 标签。存盘 `getinfo_type_allmenu.xml`。 |

### 返回 `err_unsuitable_app` 的 type（探测后期相机进入拒绝状态）

capability、curmenu、camsetting、lens —— 这四类在早期会话（camera_api/ 目录已有存档）都能返回真实数据（能力声明、当前菜单、当前设置、镜头 CSV），本次实测因相机状态变化返回 `err_unsuitable_app`（94 B）。

### 返回 `err_param` 的 type（全部其余候选）

menu, version, battery, setting, info, sysinfo, status, state, firm, firmware, fw, log, debug, diag, dump, memory, flash, key, otp, serial, sn, model, all, lensinfo,
allmenu2, cursetting, currentmenu, current, camera, camerasetting, camera_info, camerainfo, sysinfo2, system, systeminfo, version2, fwversion, firmver,
serialnumber, serial_no, serialno, mac, macaddr, wifi, network, uuid, camsn, modelname, productname, shutters, shuttercount, sscount, err, errcode, error,
errorlog, errlog, history, power, batteryinfo, temperature, temp, media, sdinfo, slot, cardlist。

（deviceinfo 一次请求超时/连接中断，未返回，属瞬态。）

## 3. mode 枚举

逐模式发送 `curl -s http://192.168.1.131/cam.cgi?mode=<M>`，完整响应存于 `fw_fetch/probe_results/mode_<M>.xml`。

| mode | 结果 |
|---|---|
| getsetting, getstate | `err_reject`（首次）→ `err_unsuitable_app`（后期），模式存在但当前被拒 |
| get, read, dump, diag, debug, sysinfo, log, getlog, getfirm, getfw, download, backup, mem, memory, flash, key, otp, info, version, status, getinfo, getshot, getphoto, list | 全部 `err_param` |

## 4. 非标准响应的完整内容

唯一超出「标准结果 XML」的响应是 `getinfo&type=allmenu`（307714 B）。开头：

```
<?xml version="1.0" encoding="utf-8"?>
<camrply>
<result>ok</result>
<menuset model="S5" version="2.0" date="20201027">
<home_menu><menu></menu></home_menu>
<play_menu><menu></menu></play_menu>
<record_top><menu><item id="menu_item_id_f_and_ss" title_id="title_f_and_ss" ...>
```

全文存盘：`fw_fetch/probe_results/getinfo_type_allmenu.xml`（与 camera_api/lumix_allmenu.xml 内容一致，可复现）。

## 5. 相机状态变化（重要）

探测开始：getstate → `err_reject`，getinfo&type=version → `err_param`，camcmd → `err_reject`。
探测后期：getstate、getinfo&type=capability/curmenu/camsetting/lens 全部 → `err_unsuitable_app`。

即：相机在探测期间从「部分拒绝」进入「app 不适配」状态。此前（camera_api/ 存档）getstate 返回 ok 且 `<cammode>play</cammode>`，capability/curmenu/lens 均返回数据；本次这些读接口被 `err_unsuitable_app` 拒绝，属于相机当前运行模式（疑似非 LUMIX Sync 可用模式/另一客户端占用/待机变化）导致，不是命令不存在。

## 6. 结论

- 未发现任何能读回内存/固件/密钥/诊断数据的隐藏命令。
- 唯一的非标准数据是 `getinfo&type=allmenu` 的菜单树转储（307 KB）：内容为 UI 菜单结构 + 多语言标签，模型 S5、菜单树版本 2.0、日期 20201027。它不含固件映像、加密密钥或内存数据。
- 所有 memory/flash/key/otp/firmware/dump/log/diag 类候选（type 与 mode 两层）均返回 `err_param` 或 `err_reject`/`err_unsuitable_app`，无数据泄露。
- `lens` 类接口（存档 camera_api/lumix_lens.xml）返回镜头参数 CSV（焦距/光圈/镜头名/序列号 3997），属正常镜头信息，非固件/密钥数据。

存盘文件：`fw_fetch/probe_results/` 下 97 个 `.xml`（每个被探测命令/type 一份），以及本报告 `fw_fetch/probe_results.md`。
