#!/usr/bin/env python3
"""
hidden_features.py — audit + one-tap apply of DC-S5 settings that are valuable
but not visible in the normal menu flow.

Audited 2026-10-13 (all values verified with real readback on the camera):

  WORKS (genuinely usable)
  ---------------------------------------------------------------------------
  photostyle = vlog          V-Log (normally a paid DMW-SFU2 upgrade on the S5;
                             this camera has it enabled). Very flat/log output.
  photostyle = l_cla_neo     L.Classic Neo (an S5II-generation look).
  photostyle = cinelike_d2 / cinelike_v2 / l_bw_d / l_bw_s / 709like / flat ...
  videoformat = mp4ed        MP4 + LPCM, 1080p60, H.264 High ~96 Mbps
                             (verified by real recording; body menu greys while in it)
  videoformat = avchd        AVCHD
  videoformat = mp4hevc      MP4 HEVC (deprecated, 4:2:0 10-bit)
  6k4k_photo = 6k_start_stop + pictsize_burstspeed = 6k_18m_30p + aspectratio = 3:2
                             the ONLY way to get 6K open-gate content on the S5
                             (5184x3456 3:2, 30 fps, MP4, fixed settings)

  DOES NOT WORK (set returns ok but is silently ignored, or is rejected)
  ---------------------------------------------------------------------------
  photostyle = hlg / hlg_standard / hlg_bw     -> ignored (stays `standard`)
  photostyle = custom5..custom10               -> ignored
  photostyle = vlog_l                          -> err_param
  shtrspeed_angle = <angle>                    -> stored but NOT effective
                                                  (shtrspeed unchanged, menu stays disabled)
  4kcrop = 20 / 40                             -> rejected; caused an ~80 s camera hang
  videoquality = mov_*_5_9k_* / *_6k_*         -> accepted but records C4K, or err_param
  videoquality = mp4ed_*_400mbps_*             -> getter err_critical (invalid)

WARNING: settings written here are AUTO-PERSISTED by the camera to flash
(confirmed 2026-10-13). `restore` puts the safe defaults back.

Usage:
    python3 hidden_features.py status          # read-only
    python3 hidden_features.py vlog            # V-Log photo style
    python3 hidden_features.py 6kphoto         # 6K PHOTO (open gate) config
    python3 hidden_features.py lpcm            # MP4 + LPCM container
    python3 hidden_features.py avchd
    python3 hidden_features.py restore         # photostyle=standard, videoformat=mov,
                                               # videoquality=mov_60p_150mbps_c4k, 4kcrop=off
"""
import os
import re
import sys
import time
import urllib.parse
import urllib.request

IP = "192.168.1.131"
UA = {"User-Agent": "LUMIX Sync"}


def _get(path, timeout=15):
    try:
        r = urllib.request.Request("http://%s%s" % (IP, path), headers=UA)
        with urllib.request.urlopen(r, timeout=timeout) as x:
            return x.read().decode("utf-8", "replace")
    except Exception as e:
        return "EXC %s" % e


def g(t):
    x = _get("/cam.cgi?mode=getsetting&type=%s" % t)
    m = re.search(t + r'="([^"]*)"', x)
    return m.group(1) if m else "ERR"


def s(t, v):
    x = _get("/cam.cgi?mode=setsetting&type=%s&value=%s" % (t, urllib.parse.quote(v, safe="")))
    m = re.search(r"<result>([^<]*)</result>", x)
    return m.group(1) if m else "?"


def health():
    return "ok" if "ok" in _get("/cam.cgi?mode=getstate", 8) else "OFFLINE"


STATUS_FIELDS = ("videoformat", "videoquality", "ntsc_pal", "photostyle", "hlg",
                 "4kcrop", "aspectratio", "6k4k_photo", "pictsize_burstspeed",
                 "hrs_pictsize", "hrs_is_mode", "iso")


def status():
    print("health: %s" % health())
    for t in STATUS_FIELDS:
        print("  %-18s = %s" % (t, g(t)))


def apply(pairs, label):
    if health() != "ok":
        print("!! camera offline")
        return
    print("== %s ==" % label)
    for t, v in pairs:
        r = s(t, v)
        time.sleep(0.8)
        rb = g(t)
        flag = "OK" if rb == v else ("ignored" if r == "ok" else "rejected")
        print("  %-18s = %-24s -> %-10s readback=%-22s %s" % (t, v, r, rb, flag))


def main():
    mode = sys.argv[1] if len(sys.argv) > 1 else "status"
    if mode == "status":
        status()
    elif mode == "vlog":
        apply([("photostyle", "vlog")], "V-Log photo style")
        print("提示：V-Log 是 S5 的付费升级功能（DMW-SFU2），本机可用。")
        print("      录一段就能看出画面非常灰平；机身 Photo Style 里也应显示 V-Log。")
    elif mode == "6kphoto":
        apply([("6k4k_photo", "6k_start_stop"),
               ("pictsize_burstspeed", "6k_18m_30p"),
               ("aspectratio", "3:2")], "6K PHOTO (open gate)")
        print("提示：切到照片模式、drive 模式设为连拍，按住快门录一段；")
        print("      产物应为 MP4 5184x3456 30p（usb 卡需 UHS-3）。")
    elif mode == "lpcm":
        apply([("videoformat", "mp4ed")], "MP4 + LPCM (mp4ed)")
        print("注意：机身【录制文件格式】会变灰——切回用 restore。")
    elif mode == "avchd":
        apply([("videoformat", "avchd")], "AVCHD")
        print("注意：机身【录制文件格式】会变灰——切回用 restore。")
    elif mode == "restore":
        apply([("photostyle", "standard"),
               ("hlg", "off"),
               ("4kcrop", "off"),
               ("aspectratio", "3:2"),
               ("videoformat", "mov"),
               ("videoquality", "mov_60p_150mbps_c4k")], "restore safe defaults")
        print("已恢复：standard / mov / mov_60p_150mbps_c4k / ntsc")
    else:
        print(__doc__)


if __name__ == "__main__":
    main()
