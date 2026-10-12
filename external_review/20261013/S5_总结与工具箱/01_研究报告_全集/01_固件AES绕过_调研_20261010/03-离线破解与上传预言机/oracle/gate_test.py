#!/usr/bin/env python3
"""fw_update_mode 门禁测试：已接受的 req_acc 会话能否解锁 camctrl&type=fw_update_mode

新文件，不修改任何原有程序；仅 import 复用 lumix_handshake.py 的函数。
相机需已连接同一 Wi-Fi（2401），IP 默认 192.168.1.131。

用法: python3 gate_test.py
"""
import http.client
import sys
import time
import urllib.parse

sys.path.insert(0, "<LOCAL_USER>/Downloads/com.panasonic.jp.lumixsync_b0834c31")
import lumix_handshake as lh

IP = "192.168.1.131"
UA = "LUMIX Sync"
VALUES = ("V2.90", "V3.00")


def new_conn():
    return http.client.HTTPConnection(IP, lh.CAM_PORT, timeout=5)


def gate_query(conn, value, ua):
    path = "/cam.cgi?" + urllib.parse.urlencode(
        {"mode": "camctrl", "type": "fw_update_mode", "value": value})
    conn.request("GET", path, headers={"User-Agent": ua})
    resp = conn.getresponse()
    body = resp.read().decode("utf-8", "replace").strip()
    print("  fw_update_mode(%s) UA=%r -> %r" % (value, ua, body))


def main():
    uuid = lh.new_uuid()
    print("UUID: %s（每次运行都是新客户端身份）" % uuid)
    print("阶段 A：在一条持久 TCP 连接上完成 req_acc 握手（轮询到 ok）...")

    conn = new_conn()
    accepted = False
    for i in range(1, 25):
        path = "/cam.cgi?" + urllib.parse.urlencode(
            {"mode": "accctrl", "type": "req_acc", "value": uuid, "value2": "LUMIX Sync"})
        try:
            conn.request("GET", path, headers={"User-Agent": UA})
            resp = conn.getresponse()
            body = resp.read().decode("utf-8", "replace").strip()
        except Exception as e:
            print("  [%d] 连接出错: %s（重建连接重试）" % (i, e))
            try:
                conn.close()
            except Exception:
                pass
            conn = new_conn()
            time.sleep(1.5)
            continue
        parts = lh.parse_csv(body)
        print("  [%d] req_acc -> %r" % (i, body))
        if parts and parts[0].lower() == "ok":
            accepted = True
            print("  会话已接受（%d 个字段）" % len(parts))
            break
        if parts and parts[0].lower() == lh.RESULT_OTHERS:
            print("  有其它客户端挂起 -> 发 req_acc_can 取消后重试")
            try:
                c2 = new_conn()
                c2.request("GET", "/cam.cgi?mode=accctrl&type=req_acc_can",
                           headers={"User-Agent": UA})
                print("  req_acc_can ->", c2.getresponse().read().decode().strip())
                c2.close()
            except Exception as e:
                print("  req_acc_can 出错:", e)
        time.sleep(1.5)

    if not accepted:
        print()
        print("未获相机接受。若相机屏幕上出现连接请求提示，请在相机上按 OK 确认，然后重跑本脚本。")
        sys.exit(1)

    print()
    print("阶段 B：同一持久连接上（握手后立刻）查询版本门禁:")
    for v in VALUES:
        try:
            gate_query(conn, v, UA)
        except Exception as e:
            print("  fw_update_mode(%s) 出错: %s（重建连接重试）" % (v, e))
            try:
                conn.close()
            except Exception:
                pass
            conn = new_conn()
            try:
                gate_query(conn, v, UA)
            except Exception as e2:
                print("  重试仍失败: %s" % e2)
        time.sleep(0.5)
    try:
        conn.close()
    except Exception:
        pass

    print()
    print("阶段 C（对照）：全新连接 + UA 'LUMIX Sync':")
    for v in VALUES:
        try:
            c3 = new_conn()
            gate_query(c3, v, UA)
            c3.close()
        except Exception as e:
            print("  fw_update_mode(%s) 出错: %s" % (v, e))
        time.sleep(0.5)

    print()
    print("阶段 D（对照）：全新连接 + 普通 UA（模拟之前的 curl）:")
    try:
        c4 = new_conn()
        gate_query(c4, VALUES[0], "curl/8.0")
        c4.close()
    except Exception as e:
        print("  出错:", e)


if __name__ == "__main__":
    main()
