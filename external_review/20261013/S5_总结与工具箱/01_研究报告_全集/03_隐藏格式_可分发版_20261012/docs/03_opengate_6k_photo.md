> **Codex核验评论（2026-10-13）**：以下正文是外部作者材料的公开副本。收录不等于证实；作者说法与本项目核验分开。原稿 SHA-256：`5373cebac6436077d958580bf44d4dcdf484c5926ccd1422630fea1650202f02`。原稿行号仍按未注释原件计算。
> 参见[该包纠错总评](../../../CODEX_REVIEW.md)；未在本轮执行其脚本、设备请求或录像实验。

# 6K PHOTO（片门全开 / Open-Gate）

> **结论先行**：S5 **原生就支持 6K PHOTO（片门全开）功能**，固件里是**完全声明存在的可写 setter**，
> 不是隐藏功能。通过 cam.cgi 的 `setsetting` 接口即可激活（需相机处于**照片模式** + 用户实拍核对）。
> 原始采集数据见 [../reference/OPENGATE_FINDINGS.md](../reference/OPENGATE_FINDINGS.md) 与
> [../reference/curmenu.xml](../reference/curmenu.xml)。

---

## A. 核心可写域（cmd_type）与取值

| cmd_type | 取值 | 含义 |
|---|---|---|
| `6k4k_photo` | `6k_burst` / `6k_start_stop` / `6k_pre_burst` / `4k_burst` / `4k_start_stop` / `4k_pre_burst` | 6K/4K 拍照驱动模式 |
| `pictsize_burstspeed` | `6k_18m_30p` / `6k_14m_30p` / `6k_15m_30p` / `4k_8m_60p` / `ex_4k_8m_60p` / `4k_8m_30p` / `ex_4k_8m_30p` | 6K/4K 连拍尺寸+帧率 |
| `focusselect` | `6k_18m` / `6k_14m` / `6k_15m` / `4k_8m` / `ex_4k_8m` / `off` | 6K/4K 对焦选帧 |
| `aspectratio`（=片门/画幅） | `4:3` / `3:2` / `16:9` / `1:1` / `65:24` / `2:1` | 满幅/裁切画幅 |
| `hlg` | `full` / `4k` / `off` | HLG 照片 |

---

## B. "片门全开"的物理含义

- **满幅全幅 still** = `aspectratio 3:2`（或 4:3）+ `pictsize 24m` → 满幅 6000×4000 = 24MP，
  即**原生全分辨率满幅照**。
- **6K PHOTO burst** = `6k_burst` 驱动模式：内部录 6K 帧再取帧出图，
  输出 18m/15m/14m（2:1 系裁切）。

---

## C. 只读基线（激活前对照，本机采集）

```
6k4k_photo=6k_burst（记忆值，视频模式下未生效）
aspectratio=3:2   pictsize=24m   quality=fine   hlg=off   drivemode=normal
ntsc_pal=pal（采集时）→ 后续已切 NTSC
视频域：videoformat=mp4   videoquality=mp4_60p_28mbps（NTSC 基线，未动）
```

---

## D. 激活配方（受控、可逆；需照片模式 + 用户 go-ahead + 实拍核对）

```bash
# 前置：相机切到【照片模式】，确认未录像（rec=off）；接交流电源

# 1) 开 6K PHOTO
curl -H "User-Agent: LUMIX Sync" "http://$S5_IP:80/cam.cgi?mode=setsetting&type=6k4k_photo&value=6k_burst"
curl -H "User-Agent: LUMIX Sync" "http://$S5_IP:80/cam.cgi?mode=setsetting&type=pictsize_burstspeed&value=6k_18m_30p"

# 2) 片门/画幅（可选，满幅 3:2）
curl -H "User-Agent: LUMIX Sync" "http://$S5_IP:80/cam.cgi?mode=setsetting&type=aspectratio&value=3:2"

# 3) 读回核对（写后 sleep ~1s 再读）
curl -H "User-Agent: LUMIX Sync" "http://$S5_IP:80/cam.cgi?mode=getsetting&type=6k4k_photo"    # 期望 6k_burst
curl -H "User-Agent: LUMIX Sync" "http://$S5_IP:80/cam.cgi?mode=getsetting&type=pictsize_burstspeed"

# 4) 用户机身菜单核对 + 实拍一张 6K，取文件解码确认

# 5) 恢复：6k4k_photo 与 aspectratio 回基线
curl -H "User-Agent: LUMIX Sync" "http://$S5_IP:80/cam.cgi?mode=setsetting&type=6k4k_photo&value=6k_burst"
curl -H "User-Agent: LUMIX Sync" "http://$S5_IP:80/cam.cgi?mode=setsetting&type=aspectratio&value=3:2"
```

> 注：以上为**手动 curl 配方**用于说明机制；若想脚本化，可参照 `scripts/hidden_test_hlg.py`
> 的"基线→写→读回→回滚→健康"模板改一个 `6k4k_photo` 版（本包未内置 6K 写脚本，
> 因为 6K 是**原生声明功能**、非隐藏，且激活后必须实拍核对，脚本化收益低）。

---

## E. 与"隐藏功能"的关系

6K PHOTO 相关 setter（`6k4k_photo` / `pictsize_burstspeed` / `focusselect`）在 allmenu 中**均有声明**，
属于**原生功能**，**不要**把它当"隐藏功能去解锁"。真正"启用但未声明"的隐藏档是
`hlg_photo_8k`（见 [02](02_隐藏功能.md)）与 `mp4ed`/`mp4hevc` 系列。

> 用户已明确：6K 片门全开**原生已支持，不需要测试**。本文仅归档配方与证据，供后续实机核对使用。
