# DC-S1M2 及当代无反机型原厂维修资料免登录检索报告（2026-10-09）

## 1. 检索任务与执行边界
- **目标**：排查 Panasonic DC-S1M2 同型号维修手册无需登录的公开来源，以及含明确当代调整软件名称/编号/官方获取入口的 S1RM2、S1M2ES、GH7、G9M2 原厂维修资料。
- **边界约束**：不注册账号、不等待/依赖账号审核、不付款、不发邮件、不机身操作、不执行厂商程序、不绕过权限/质询；目录条目与卖家宣称不计为正文证据；旧型号 DIAS 不预设支持 S1M2。
- **存储规范**：新增下载文件限定保存于 `analysis/sources/service_alternatives_20261009/`。

---

## 2. 各目标机型检索与下载核验状态

| 目标机型 | 资料类别 | 检索渠道与状态 | 实际下载状态 | 正文页码 / 证据说明 |
| :--- | :--- | :--- | :--- | :--- |
| **DC-S1M2** | 维修手册 (SM) | - `remont-aud.net` 目录项标称 12.22MB、无电路图，但下载账号仍需人工审核并需答题，按受控边界不等待审核、不绕过权限；<br>- Elektrotanya、Archive.org、iFixit 等公开库检索无同型号条目；<br>- ManualsLib 访问受 HTTP 403 质询拦截。 | **未取得** (`downloaded: false`) | 无正文页码。本轮未找到无需登录、可直接下载同型号维修手册正文的公开来源。 |
| **DC-S1M2ES** | 维修手册 / 调整资料 | 松下欧洲技术数据存储 (`tda.panasonic-europe-service.com`) 存在 `dvqp3359za.pdf`，经核验为 1038 页完整使用说明书（OI），非维修手册（SM）。 | **未取得** (`downloaded: false`) | 无正文页码。公开渠道未取得维修手册正文。 |
| **DC-S1RM2** | 维修手册 / 调整资料 | 官方技术支持渠道仅见操作使用说明书（OI）；公开技术文档站点未发现维修手册正文。 | **未取得** (`downloaded: false`) | 无正文页码。本轮未取得原厂维修资料正文。 |
| **DC-GH7** | 维修手册 / 调整资料 | 公开检索仅见官方操作指南（HTML/PDF），技术手册库无该型号原厂 Service Manual。 | **未取得** (`downloaded: false`) | 无正文页码。本轮未取得原厂维修资料正文。 |
| **DC-G9M2** | 维修手册 / 调整资料 | - Elektrotanya 仅收录初代 DC-G9（Order No. DSC1801001CE）；<br>- ManualsLib 受 HTTP 403 质询拦截；此前流传的编号 `DSC2310016RE` 经检索未获得公开原件证据支持。 | **未取得** (`downloaded: false`) | 无正文页码。本轮未取得原厂维修资料正文。 |

---

## 3. 当代调整软件名称、编号与官方获取入口核查

1. **正文依据缺失**：
   - 因上述当代机型（S1M2、S1RM2、S1M2ES、GH7、G9M2）本轮均未取得原厂维修手册正文，目前无法从一手正文页码中确认当代机型配套调整软件的具体独立名称或订购编号。
2. **已知参考资料边界**：
   - 2010 年 DMC-TS2 原厂维修手册（`analysis/sources/service_research_20261008/Panasonic_DMC_TS2_service_ifixit.pdf`，Order No. `DSC1002022CE`，第 11、34、36、46、49、51 页）明确载明旧版软件名称为 **DIAS (DSC Integrated Assist Software)**；
   - 2019 年初代 DC-S1 手册（Order No. `DSC1903002CE`，第 37、60、61 页）仅统称为“Adjustment software”并提及随附 Adjustment Manual；
   - 旧版 DIAS 不能直接假定支持 S1M2。
3. **官方获取入口**：
   - 松下官方 TSN 门户（`https://www.e-service.css.panasonic.co.jp/cshome/login`）经实测需要输入账号与密码，未提供匿名公开下载入口。

---

## 4. 本地新增文件清单
- `analysis/sources/service_alternatives_20261009/`：**新增文件 0 项**（因各目标机型正文均未取得免登录可下载原件）。
- 机器可读核验清单已同步记录至 `analysis/service_alternatives_gemini_20261009.json`。
