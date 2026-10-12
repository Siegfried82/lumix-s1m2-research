#!/usr/bin/env python3
"""S1M2 隐藏录制格式只读检查。

只发送只读 GET 请求（capability / getstate / allmenu / curmenu /
getsetting videoformat / getsetting videoquality / getsetting camsetting），
不发送任何 setsetting 或控制命令。

用法（相机与电脑在同一 Wi-Fi 内网）:
    python3 s1m2_inspect.py            # 自动扫描当前 /24 网段
    python3 s1m2_inspect.py 192.168.x.y  # 已知相机 IP

结果保存到本目录下 captures/时间戳/ 并打印摘要。仅 Python 标准库。
"""
import concurrent.futures
import datetime as dt
import json
import os
import re
import socket
import subprocess
import sys
import urllib.request
import xml.etree.ElementTree as ET

HERE = os.path.dirname(os.path.abspath(__file__))
MAX_BODY = 4 * 1024 * 1024
UA = {"User-Agent": "Mozilla/5.0"}

READS = [
    ("capability", "getinfo", "capability", ".xml"),
    ("state", "getstate", None, ".xml"),
    ("allmenu", "getinfo", "allmenu", ".xml"),
    ("curmenu", "getinfo", "curmenu", ".xml"),
    ("videoformat", "getsetting", "videoformat", ".xml"),
    ("videoquality", "getsetting", "videoquality", ".xml"),
    ("camsetting", "getsetting", "camsetting", ".bin"),
]


def local_ip():
    try:
        s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
        s.connect(("8.8.8.8", 80))
        ip = s.getsockname()[0]
        s.close()
        if ip and ip != "127.0.0.1":
            return ip
    except Exception:
        pass
    for dev in ("en0", "en1", "en2"):
        try:
            out = subprocess.check_output(["ipconfig", "getifaddr", dev], text=True,
                                          stderr=subprocess.DEVNULL).strip()
            if out:
                return out
        except Exception:
            pass
    return None


def http_get(url, timeout=2.5):
    req = urllib.request.Request(url, headers=UA)
    opener = urllib.request.build_opener(urllib.request.ProxyHandler({}))
    with opener.open(req, timeout=timeout) as r:
        body = r.read(MAX_BODY + 1)
    if len(body) > MAX_BODY:
        raise RuntimeError("response exceeds 4MiB cap")
    return body.decode("utf-8", "replace")


def find_camera():
    ip = local_ip()
    if not ip:
        print("无法确定本机 IP，请直接用: python3 s1m2_inspect.py <相机IP>")
        sys.exit(2)
    base = ".".join(ip.split(".")[:3]) + "."
    print(f"本机 {ip}，扫描 {base}1-254 寻找 cam.cgi …")

    def probe(n):
        addr = f"{base}{n}"
        try:
            body = http_get(f"http://{addr}/cam.cgi?mode=getinfo&type=capability", timeout=1.2)
            if "camrply" in body or "capability" in body.lower():
                return addr, body
        except Exception:
            pass
        return None

    hits = []
    with concurrent.futures.ThreadPoolExecutor(24) as ex:
        for res in ex.map(probe, range(1, 255)):
            if res:
                hits.append(res)
                print("找到候选相机:", res[0])
    if not hits:
        print("未找到响应 cam.cgi 的相机。确认: 1) 相机已连接且与本电脑同一 Wi-Fi 网络; "
              "2) 录像已停止; 3) 必要时先按原厂流程用 Tether App 完成一次配对。")
        sys.exit(3)
    return hits[0]


def text_of(tag, root):
    if root is None:
        return None
    el = root.findtext(tag)
    return el.strip() if el else None


def parse_setting(root):
    """从 <settingvalue xxx="yyy"/> 或 <value>yyy</value> 提取值。"""
    if root is None:
        return None
    for el in root.iter():
        if el.tag.endswith("settingvalue") or el.tag == "settingvalue":
            return el.attrib.get("videoquality") or el.attrib.get("videoformat") or next(iter(el.attrib.values()), None)
    el = root.find(".//value")
    if el is not None and (el.text or "").strip():
        return el.text.strip()
    return None


def parse_xml(body):
    try:
        return ET.fromstring(body)
    except ET.ParseError:
        return None


def declared_values(allmenu_body, kind):
    root = parse_xml(allmenu_body)
    out = set()
    if root is not None:
        for el in root.iter():
            if el.tag.endswith("menuitem") or "cmd_type" in el.attrib:
                if el.attrib.get("cmd_mode") == "setsetting" and el.attrib.get("cmd_type") == kind:
                    v = el.attrib.get("cmd_value")
                    if v:
                        out.add(v)
    if not out:
        pat = re.compile(r'cmd_type="%s"[^>]*cmd_value="([^"]+)"' % re.escape(kind))
        pat2 = re.compile(r'cmd_value="([^"]+)"[^>]*cmd_type="%s"' % re.escape(kind))
        out = set(pat.findall(allmenu_body) + pat2.findall(allmenu_body))
    return out


def enabled_items(curmenu_body, kind):
    root = parse_xml(curmenu_body)
    out = set()
    if root is not None:
        prefix = "menu_item_id_v_%s_" % kind
        for el in root.iter():
            ident = el.attrib.get("id", "")
            if ident.startswith(prefix) and el.attrib.get("enable") == "yes":
                out.add(ident[len(prefix):])
    if not out:
        pat = re.compile(r'id="menu_item_id_v_%s_([^"]+)"[^>]*enable="yes"' % re.escape(kind))
        pat2 = re.compile(r'enable="yes"[^>]*id="menu_item_id_v_%s_([^"]+)"' % re.escape(kind))
        out = set(pat.findall(curmenu_body) + pat2.findall(curmenu_body))
    return out


def token_family_strings(body, kind):
    pats = {
        "videoquality": r"\b(?:mp4ed|mp4hevc|mp4|mov|avchd)_[a-z0-9_]+?\b",
        "videoformat": r"\b(?:mp4ed|mp4hevc|mp4|mov|avchd)\b",
    }
    return set(re.findall(pats[kind], body or ""))


def main():
    ip = sys.argv[1] if len(sys.argv) > 1 else None
    capability_body = None
    if not ip:
        ip, capability_body = find_camera()
    stamp = dt.datetime.now().strftime("%Y%m%d_%H%M%S")
    outdir = os.path.join(HERE, "captures", stamp)
    os.makedirs(outdir, exist_ok=True)

    results = {}
    for name, mode, kind, ext in READS:
        url = f"http://{ip}/cam.cgi?mode={mode}"
        if kind:
            url += f"&type={kind}"
        try:
            body = capability_body if (name == "capability" and capability_body) else http_get(url, timeout=4.0)
        except Exception as e:
            results[name] = {"error": str(e)}
            print(f"  [失败] {name}: {e}")
            continue
        with open(os.path.join(outdir, name + ext), "w", encoding="utf-8") as f:
            f.write(body)
        results[name] = {"ok": True, "bytes": len(body)}
        print(f"  [OK] {name} ({len(body)} bytes)")

    summary = {"ip": ip, "utc": dt.datetime.now(dt.timezone.utc).isoformat(),
               "camera": ip, "outdir": outdir}
    cap = parse_xml(results.get("capability", {}).get("raw", "")) if "raw" in results.get("capability", {}) else None
    if "ok" in results.get("capability", {}):
        body = open(os.path.join(outdir, "capability.xml"), encoding="utf-8").read()
        root = parse_xml(body)
        model = text_of("modelname", root) or ""
        m = re.search(r'modelname[^>]*>\s*([^<]+)', body)
        model = (m.group(1).strip() if m else model)
        summary["modelname"] = model
        summary["is_s1m2"] = "S1M2" in model.upper()
        if not summary["is_s1m2"]:
            print(f"注意: 机型字段为 {model!r}，不是 S1M2；仍保存只读结果，请人工确认。")

    if "ok" in results.get("videoformat", {}):
        summary["current_videoformat"] = parse_setting(parse_xml(open(os.path.join(outdir, "videoformat.xml"), encoding="utf-8").read()))
    if "ok" in results.get("videoquality", {}):
        summary["current_videoquality"] = parse_setting(parse_xml(open(os.path.join(outdir, "videoquality.xml"), encoding="utf-8").read()))

    for kind in ("videoquality", "videoformat"):
        allmenu_body = ""
        curmenu_body = ""
        if "ok" in results.get("allmenu", {}):
            allmenu_body = open(os.path.join(outdir, "allmenu.xml"), encoding="utf-8").read()
        if "ok" in results.get("curmenu", {}):
            curmenu_body = open(os.path.join(outdir, "curmenu.xml"), encoding="utf-8").read()
        declared = declared_values(allmenu_body, kind)
        enabled = enabled_items(curmenu_body, kind)
        declared_str = token_family_strings(allmenu_body, kind)
        enabled_str = token_family_strings(curmenu_body, kind)
        summary[kind] = {
            "declared": sorted(declared),
            "enabled": sorted(enabled),
            "enabled_not_declared": sorted(enabled - declared),
            "declared_not_enabled": sorted(declared - enabled),
            "declared_token_strings": sorted(declared_str),
            "enabled_token_strings": sorted(enabled_str),
            "enabled_token_strings_not_in_declared": sorted(enabled_str - declared_str),
        }
        if not declared and not enabled:
            summary[kind]["note"] = "未能按 S1H/S5 结构解析出条目；原始 XML 已保存，需人工查看 allmenu.xml / curmenu.xml"

    with open(os.path.join(outdir, "inspection.json"), "w", encoding="utf-8") as f:
        json.dump(summary, f, ensure_ascii=False, indent=1)

    print("\n===== 摘要 =====")
    print("机型:", summary.get("modelname"))
    print("当前格式:", summary.get("current_videoformat"))
    print("当前质量:", summary.get("current_videoquality"))
    vq = summary.get("videoquality", {})
    print(f"质量候选: declared={len(vq.get('declared', []))} enabled={len(vq.get('enabled', []))} "
          f"enabled_not_declared={len(vq.get('enabled_not_declared', []))}")
    for t in vq.get("enabled_not_declared", [])[:20]:
        print("  候选:", t)
    if not vq.get("enabled") and not vq.get("declared"):
        for t in vq.get("enabled_token_strings_not_in_declared", [])[:20]:
            print("  候选(字符串级):", t)
    vf = summary.get("videoformat", {})
    print(f"格式候选: enabled_not_declared={vf.get('enabled_not_declared', [])}")
    print("结果目录:", outdir)
    print("本脚本只发送了只读 GET 请求，未写入任何设置。")


if __name__ == "__main__":
    main()
