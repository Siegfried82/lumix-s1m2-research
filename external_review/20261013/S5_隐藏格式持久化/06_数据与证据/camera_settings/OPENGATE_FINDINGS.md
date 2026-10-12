> **Codex核验评论（2026-10-13）**：以下正文是外部作者材料的公开副本。收录不等于证实；作者说法与本项目核验分开。原稿 SHA-256：`dc1bd0e1f71b9f136a8ba97f5972736345f331d7b60d4ef3688bce96c422a918`。原稿行号仍按未注释原件计算。
> 参见[该包纠错总评](../../CODEX_REVIEW.md)；未在本轮执行其脚本、设备请求或录像实验。

# S5 Open-Gate / 6K PHOTO 可行性 + cam.cgi RCE 面测绘

日期 2026-10-12 · 相机 192.168.1.131 · DC-S5 (modelname=S5) · 状态 VD4.30 · cammode=rec(视频模式)

## A. Open-Gate / 6K PHOTO 结论
S5 **原生就支持 6K PHOTO(片门全开)功能**,且固件里是完全声明存在的可写 setter,不是隐藏功能。
通过 cam.cgi 的 setsetting 接口即可激活(需相机处于照片模式 + 用户实机核对/实拍)。

### 核心可写域(cmd_type)与取值
| cmd_type | 取值 | 含义 |
|---|---|---|
| 6k4k_photo | 6k_burst / 6k_start_stop / 6k_pre_burst / 4k_burst / 4k_start_stop / 4k_pre_burst | 6K/4K 拍照驱动模式 |
| pictsize_burstspeed | 6k_18m_30p / 6k_14m_30p / 6k_15m_30p / 4k_8m_60p / ex_4k_8m_60p / 4k_8m_30p / ex_4k_8m_30p | 6K/4K 连拍尺寸+帧率 |
| focusselect | 6k_18m / 6k_14m / 6k_15m / 4k_8m / ex_4k_8m / off | 6K/4K 对焦选帧 |
| aspectratio(=片门) | 4:3 / 3:2 / 16:9 / 1:1 / 65:24 / 2:1 | 满幅/裁切画幅 |
| hlg | full / 4k / off | HLG 照片 |

### 当前只读基线(激活前对照)
6k4k_photo=6k_burst(记忆值,视频模式下未生效) · aspectratio=3:2 · pictsize=24m · quality=fine · hlg=off · drivemode=normal · ntsc_pal=pal
视频域:videoformat=mp4 · videoquality=mp4_50p_28mbps(未动)

### "片门全开"物理含义
- 满幅全幅 still = aspectratio 3:2(或 4:3)+ pictsize 24m => 满幅 6000x4000 = 24MP,即原生全分辨率满幅照。
- 6K PHOTO burst = 6k_burst 驱动模式,内部录 6K 帧再取帧出图,输出 18m/15m/14m(2:1 系裁切)。

### 激活配方(受控、可逆,需照片模式+用户 go-ahead+实拍核对)
```
# 1) 相机切到照片模式(机身操作),确认 rec=off
# 2) 开 6K PHOTO
GET /cam.cgi?mode=setsetting&type=6k4k_photo&value=6k_burst
GET /cam.cgi?mode=setsetting&type=pictsize_burstspeed&value=6k_18m_30p
# 3) 片门(可选,满幅)
GET /cam.cgi?mode=setsetting&type=aspectratio&value=3:2
# 4) 读回核对(写后 sleep ~1s 再读)
GET /cam.cgi?mode=getsetting&type=6k4k_photo   # 期望 6k_burst
# 5) 用户机身菜单核对 + 实拍一张 6K,取文件解码
# 6) 恢复:6k4k_photo 与 aspectratio 回到基线
```

### S1H 同款"启用但未声明"隐藏档(可受控试写)
- **hlg = 8k**(curmenu `hlg_photo_8k` enable=yes,但 allmenu hlg 只声明 full/4k/off)
- **v_quality = mp4hevc_25p_72mbps_4k_10bit**(HEVC 视频隐藏档)
这两条是"有本机证据"的隐藏值,不是盲猜;写入前需记录原值、写后读回、异常即回滚。

## B. cam.cgi RCE 面测绘结论
完整 mode 面 = getstate / getsetting / setsetting / getinfo / accctrl / camcmd / camctrl。
- getinfo 子类型仅:capability / allmenu / curmenu / camsetting(其余 ~110 个候选全部 err/reject)。
- mode 枚举 ~90 个候选:除已知 7 个外全部 err/reject,无 file-op / exec / dynamic-load / 系统信息泄漏。
- 之前 GoAhead buffer overflow、LD_PRELOAD(EV-43360/CVE-2017-17562)均已失败,本表面为 Panasonic 定制 CGI(err_critical 行为 + XHTML 错误页指纹)。
结论:**网络层 RCE 极难/很可能不可行**;已证明的可控原语是 setsetting 状态写(47 个可写域),可作状态变更/取证,但非代码执行。
