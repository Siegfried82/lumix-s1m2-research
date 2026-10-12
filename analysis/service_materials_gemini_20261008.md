# 原厂维修资料的历史来源记录

检索：2026-10-08；正文整理：2026-10-12。保留 [原机器检索记录](service_materials_gemini_20261008.json) 的来源与取得状态，不将访问失败写成资料不存在或所有渠道关闭。本轮仅整理文字，没有访问网站、运行软件或发送消息。

| 来源/目标 | 当时实际状态 | 保留信息与限制 |
|---|---|---|
| iFixit的DMC-TS2手册镜像 | 已下载 | 原厂格式参考，Order No. `DSC1002022CE`；不是S1M2兼容证据 |
| 松下用户说明书 | 可取得操作指南 | Operating Instructions与Service Manual不能混称 |
| remont-aud的DC-S1M2目录项 | 当时未取得正文 | 页面标称12.22MB、上传者Silnica、无原理图；下载有账号/测试门槛，这些是当时页面状态 |
| 松下TSN登录入口 | 看到了登录入口 | 登录页不定义全部账号资格、分发方式或其他取得渠道 |
| ManualsLib的初代S1条目 | 本次HTTP403/质询 | 不是必须注册账号的证据，也不能据此判定无公开正文 |
| LUMIX Repair Tool | 已辨认产品用途 | 用于修复未正常保存的`.mdt`视频，不是机身诊断/固件解码软件 |

原来源URL：`https://remont-aud.net/load/drugaja_apparatura/dc_s1m2_service_manual/147-1-0-97303`、`https://www.e-service.css.panasonic.co.jp/cshome/login`、`https://www.manualslib.com/download/2331010/Panasonic-Dc-S1p.html`。

## 已取得的旧型号参考

`analysis/sources/service_research_20261008/Panasonic_DMC_TS2_service_ifixit.pdf`（5,022,960 B）、对应TXT与页图保留不变。TS2手册有DIAS（DSC Integrated Assist Software）与TSN线索；具体页码按 [Codex检索核验](维修资料搜索结果_20261008.md) 的11、34、36、46、49、51页为准。旧型号工具名称、备份与调整程序不能直接用于S1M2；未经原件支持的其他机型文档编号不作为证据。

## 后来已取得的同型号资料

2026-10-09的 [S1M2维修手册核验](S1M2维修手册_Codex核验_20261009.md) 已登记同款原包与PDF、完整摘要及核验页码。它替代本稿早期“未取得同型号正文”的进度状态。手册提到ROM BACKUP等不定义导出范围、介质、程序/RAM覆盖或同款调整软件取得途径。未取得的软件不能被推成不存在；当前材料也不证明所有现代调整程序都封闭分发。
