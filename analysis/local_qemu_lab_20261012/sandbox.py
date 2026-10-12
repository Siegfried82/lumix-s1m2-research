#!/usr/bin/env python3
"""Local ARM64 Linux lab: fixed QEMU devices, serial console and QMP snapshots."""
import argparse
import fcntl
import gzip
import hashlib
import json
import os
from pathlib import Path
import re
import select
import shlex
import shutil
import socket
import subprocess
import sys
import tempfile
import time
import uuid

ROOT = Path(__file__).resolve().parent
SOURCE = ROOT.parent / "external_qemu_sandbox_20261012"
ACTIVE = ROOT / "active.json"
RAM_BASE = 0x40000000
RAM_SIZE = 1024 * 1024 * 1024


def save(path, value):
    path.write_text(json.dumps(value, ensure_ascii=False, indent=2) + "\n")


def digest(path):
    h = hashlib.sha256()
    with path.open("rb") as stream:
        for block in iter(lambda: stream.read(1024 * 1024), b""):
            h.update(block)
    return h.hexdigest()


class QMP:
    def __init__(self, state):
        self.sock = socket.socket(socket.AF_UNIX)
        self.sock.settimeout(60)
        self.sock.connect(state["qmp"])
        self.stream = self.sock.makefile("rwb", buffering=0)
        self.read()
        self.command("qmp_capabilities")
        if self.command("query-name").get("name") != state["name"]:
            self.close()
            raise RuntimeError("控制端口不属于本次虚拟机")

    def read(self):
        line = self.stream.readline()
        if not line:
            raise RuntimeError("QEMU 控制连接已关闭")
        return json.loads(line)

    def command(self, name, arguments=None):
        request = {"execute": name, "id": uuid.uuid4().hex}
        if arguments is not None:
            request["arguments"] = arguments
        self.stream.write((json.dumps(request) + "\n").encode())
        while True:
            reply = self.read()
            if reply.get("id") != request["id"]:
                continue
            if "error" in reply:
                raise RuntimeError(str(reply["error"]))
            return reply["return"]

    def close(self):
        self.stream.close()
        self.sock.close()

    def __enter__(self):
        return self

    def __exit__(self, *args):
        self.close()


def state():
    if not ACTIVE.exists():
        raise RuntimeError("沙箱尚未启动；先运行 start")
    return json.loads(ACTIVE.read_text())


def running(st):
    try:
        with QMP(st) as q:
            return q.command("query-status")
    except (OSError, RuntimeError):
        return None


def process_alive(st):
    try:
        os.kill(st["pid"], 0)
        return True
    except ProcessLookupError:
        return False


def verify_inputs():
    manifest = json.loads((SOURCE / "manifest.json").read_text())
    records = []
    for item in manifest:
        if item["path"] not in ("qemu_sandbox/Image", "qemu_sandbox/initramfs.cpio.gz"):
            continue
        p = SOURCE / item["path"]
        actual = digest(p)
        if actual != item["sha256"] or p.stat().st_size != item["bytes"]:
            raise RuntimeError(f"原始输入散列不匹配：{p}")
        records.append({"path": str(p), "bytes": p.stat().st_size, "sha256": actual})
    if len(records) != 2:
        raise RuntimeError("输入清单缺少内核或 initramfs")
    return records


def serial_command(st, command, timeout=30):
    token = uuid.uuid4().hex
    begin = "__LAB_BEGIN_" + token + "__"
    end = "__LAB_END_" + token + "__"
    # The complete markers never occur in the echoed command itself.
    wire = ("PS1='sandbox-linux:\\w# '; printf '\\n__LAB_BEGIN_%s__\\n' " + shlex.quote(token) +
            "; /bin/sh -c " + shlex.quote(command) +
            "; _lab_rc=$?; printf '\\n__LAB_END_%s__:%s\\n' " +
            shlex.quote(token) + ' "$_lab_rc"\n')
    with socket.socket(socket.AF_UNIX) as serial:
        serial.settimeout(5)
        serial.connect(st["serial"])
        serial.sendall(wire.encode())
        data = bytearray()
        deadline = time.monotonic() + timeout
        while time.monotonic() < deadline:
            if not select.select([serial], [], [], min(0.2, max(0, deadline-time.monotonic())))[0]:
                continue
            block = serial.recv(65536)
            if not block:
                break
            data.extend(block)
            text = data.decode(errors="replace").replace("\r", "")
            match = re.search(r"^" + re.escape(end) + r":(\d+)$", text, re.M)
            if match and ("\n" + begin + "\n") in text:
                output = text.split("\n" + begin + "\n", 1)[1].split("\n" + end, 1)[0]
                result = {"command": command, "exit_code": int(match.group(1)), "output": output}
                save(Path(st["run_dir"]) / ("command-" + token + ".json"), result)
                return result
        raise RuntimeError("等待客体命令完成超时；请查看 serial.log")


def start(timeout=90):
    if ACTIVE.exists():
        old = state()
        if running(old):
            if not old.get("shell_verified"):
                raise RuntimeError("上次启动未完成验证；请先 stop 再 start")
            print("沙箱已运行：" + old["run_dir"])
            return old
        if process_alive(old):
            raise RuntimeError("上次进程仍存在但控制端不可达；保留日志与端口供检查")
    config = json.loads((ROOT / "runtime/runtime.json").read_text())
    inputs = verify_inputs()
    binary = config["binary"]
    binary_hash = digest(Path(binary))
    if binary_hash != config["binary_sha256"]:
        raise RuntimeError("QEMU 程序散列与运行时清单不匹配")
    env = os.environ.copy()
    env.update(config.get("environment", {}))
    version = subprocess.check_output([binary, "--version"], env=env, text=True).splitlines()[0]
    token = uuid.uuid4().hex[:12]
    run_dir = ROOT / "runs" / (time.strftime("%Y%m%d-%H%M%S", time.gmtime()) + "-" + token)
    run_dir.mkdir(parents=True)
    sockets = Path(tempfile.mkdtemp(prefix="lumix-lab-"))
    sockets.chmod(0o700)
    st = {"name": "lumix-lab-" + token, "run_dir": str(run_dir),
          "qmp": str(sockets / "qmp.sock"), "serial": str(sockets / "serial.sock"),
          "socket_dir": str(sockets), "inputs": inputs, "ram_base": RAM_BASE,
          "ram_size": RAM_SIZE, "shell_verified": False, "time_basis": "UTC"}
    st["host_runtime"] = {"binary": binary, "sha256": binary_hash,
                          "source_records": config["source_records"]}
    command = [binary, "-name", st["name"], "-machine", "virt,gic-version=2",
               "-accel", "tcg", "-cpu", "cortex-a53", "-smp", "1", "-m", "1024",
               "-nodefaults", "-nic", "none", "-display", "none", "-monitor", "none",
               "-no-reboot", "-kernel", str(SOURCE / "qemu_sandbox/Image"),
               "-initrd", str(SOURCE / "qemu_sandbox/initramfs.cpio.gz"),
               "-append", "console=ttyAMA0 init=/init loglevel=7 sbox.shell=1",
               "-chardev", "socket,id=console,path=" + st["serial"] +
               ",server=on,wait=off,logfile=" + str(run_dir / "serial.log"),
               "-serial", "chardev:console", "-qmp", "unix:" + st["qmp"] + ",server=on,wait=off"]
    if config.get("share_directory"):
        command += ["-L", config["share_directory"]]
    st["qemu_version"] = version
    st["command"] = command
    proc = None
    try:
        with (run_dir / "qemu.log").open("wb") as log:
            proc = subprocess.Popen(command, stdin=subprocess.DEVNULL, stdout=log, stderr=log,
                                    cwd=run_dir, env=env, start_new_session=True)
        st["pid"] = proc.pid
        save(ACTIVE, st)
        save(run_dir / "session.json", st)
        deadline = time.monotonic() + timeout
        while time.monotonic() < deadline:
            if proc.poll() is not None:
                raise RuntimeError("QEMU 启动失败：" + (run_dir / "qemu.log").read_text(errors="replace"))
            log = (run_dir / "serial.log").read_text(errors="replace") if (run_dir / "serial.log").exists() else ""
            if "Kernel panic" in log:
                raise RuntimeError("客体内核 panic；详见 serial.log")
            if "sbox: ready" in log and Path(st["serial"]).exists():
                break
            time.sleep(0.2)
        else:
            raise RuntimeError("等待 Linux 启动超时；详见 serial.log")
        result = serial_command(st, "uname -r; cat /proc/cmdline; test -d /proc/self", timeout=10)
        if result["exit_code"] != 0 or "4.19.124" not in result["output"]:
            raise RuntimeError("Linux shell 验证失败")
        st["shell_verified"] = True
        st["boot_probe"] = result
        st["udc_bound"] = "sbox: udc bind rc=0" in log
        save(ACTIVE, st)
        save(run_dir / "session.json", st)
        print("Linux 沙箱已启动并通过命令执行验证。日志：" + str(run_dir))
        return st
    except BaseException as exc:
        # Only terminate the process we created, never a PID read from stale state.
        if proc is not None:
            proc.terminate()
            try:
                proc.wait(timeout=5)
            except subprocess.TimeoutExpired:
                proc.kill()
                proc.wait()
        st["boot_failure"] = str(exc)
        save(run_dir / "session.json", st)
        ACTIVE.unlink(missing_ok=True)
        shutil.rmtree(sockets, ignore_errors=True)
        raise


def dump_memory(st, address, size, compress=False):
    if size <= 0 or address < RAM_BASE or address + size > RAM_BASE + RAM_SIZE:
        raise RuntimeError("导出范围必须位于本虚拟机的 1 GiB RAM 内")
    path = Path(st["run_dir"]) / ("ram-" + uuid.uuid4().hex[:8] + ".bin")
    record = {"kind": "QEMU guest physical RAM", "address": address, "size": size,
              "camera_ram": False, "inputs": st["inputs"]}
    with QMP(st) as q:
        was_running = q.command("query-status")["running"]
        q.command("stop")
        try:
            record["memory_map"] = q.command("human-monitor-command", {"command-line": "info mtree"})
            q.command("pmemsave", {"val": address, "size": size, "filename": str(path)})
            if path.stat().st_size != size:
                raise RuntimeError("内存导出字节数不匹配")
            # Repeat the first-page read while paused to check capture consistency.
            probe = path.with_suffix(".probe")
            q.command("pmemsave", {"val": address, "size": min(4096, size), "filename": str(probe)})
            with path.open("rb") as stream:
                record["first_page_matches"] = stream.read(min(4096, size)) == probe.read_bytes()
            probe.unlink()
            if not record["first_page_matches"]:
                raise RuntimeError("暂停状态下两次内存读出不一致")
        finally:
            if was_running:
                q.command("cont")
    record["sha256_uncompressed"] = digest(path)
    record["paused_during_capture"] = True
    if compress:
        packed = path.with_suffix(".bin.gz")
        with path.open("rb") as source, gzip.open(packed, "wb", compresslevel=1) as target:
            shutil.copyfileobj(source, target)
        h = hashlib.sha256()
        count = 0
        with gzip.open(packed, "rb") as stream:
            for block in iter(lambda: stream.read(1024 * 1024), b""):
                count += len(block)
                h.update(block)
        if count != size or h.hexdigest() != record["sha256_uncompressed"]:
            raise RuntimeError("压缩后解压核验失败")
        record["compressed_roundtrip_verified"] = True
        path.unlink()
        path = packed
    record.update({"file": str(path), "file_bytes": path.stat().st_size, "file_sha256": digest(path)})
    save(path.with_suffix(path.suffix + ".json"), record)
    print(json.dumps({k: v for k, v in record.items() if k != "memory_map"}, ensure_ascii=False, indent=2))
    return record


def stop(st):
    if not running(st):
        if process_alive(st):
            raise RuntimeError("控制端不可达且原进程仍存在；无法确认已关机")
        print("原沙箱进程已退出。")
        shutil.rmtree(st["socket_dir"], ignore_errors=True)
        return
    events = []
    forced = False
    qmp_eof = False
    q = QMP(st)
    try:
        serial_command(st, "sync", 5)
        with socket.socket(socket.AF_UNIX) as serial:
            serial.connect(st["serial"])
            serial.sendall(b"exit\n")
        deadline = time.monotonic() + 10
        while time.monotonic() < deadline:
            if select.select([q.sock], [], [], 0.2)[0]:
                try:
                    reply = q.read()
                except RuntimeError:
                    qmp_eof = True
                    break
                if "event" in reply:
                    events.append(reply)
            if not process_alive(st):
                break
    finally:
        q.close()
        if process_alive(st) and running(st):
            forced = True
            with QMP(st) as control:
                control.command("quit")
        deadline = time.monotonic() + 3
        while process_alive(st) and time.monotonic() < deadline:
            time.sleep(0.1)
        exited = not process_alive(st)
        log = (Path(st["run_dir"]) / "serial.log").read_text(errors="replace")
        guest_event = any(e.get("event") == "SHUTDOWN" and
                          e.get("data", {}).get("guest") is True and
                          e.get("data", {}).get("reason") == "guest-shutdown" for e in events)
        graceful = guest_event and "Power down" in log and exited and not forced
        st["shutdown"] = {"guest_requested": graceful, "forced_qmp_quit": forced,
                          "process_exited": exited, "qmp_eof": qmp_eof,
                          "power_down_in_log": "Power down" in log, "events": events,
                          "exit_code": None}
        save(ACTIVE, st)
        save(Path(st["run_dir"]) / "session.json", st)
        if exited:
            shutil.rmtree(st["socket_dir"], ignore_errors=True)
    if not exited:
        raise RuntimeError("无法确认 QEMU 进程退出；保留控制端与记录")
    print("沙箱已关闭。" + ("客体正常关机。" if graceful else "详见 shutdown 记录。"))


def menu():
    result = subprocess.run([sys.executable, str(Path(__file__).resolve()), "start"])
    if result.returncode:
        input("启动未成功，按回车关闭窗口。")
        return result.returncode
    while True:
        print("\n相机 Linux 模拟实验环境\n"
              "1 进入 Linux 命令行\n2 执行基础演示\n3 保存全部虚拟内存（压缩）\n"
              "4 查看运行状态\n5 关闭沙箱\n0 退出菜单（保持沙箱运行）")
        choice = input("选择：").strip()
        commands = {"1": ["console"], "2": ["demo"], "3": ["dump", "--all", "--gzip"],
                    "4": ["status"], "5": ["stop"]}
        if choice == "0":
            return 0
        if choice in commands:
            subprocess.run([sys.executable, str(Path(__file__).resolve()), *commands[choice]])
            if choice == "5":
                return 0


def console(st):
    import termios
    import tty
    old = termios.tcgetattr(sys.stdin.fileno())
    print("进入 Linux 命令行。Ctrl+] 返回本机；输入 exit 会关闭虚拟机。")
    with socket.socket(socket.AF_UNIX) as serial:
        serial.connect(st["serial"])
        try:
            tty.setraw(sys.stdin.fileno())
            serial.sendall(b"\n")
            while True:
                readers, _, _ = select.select([serial, sys.stdin], [], [])
                if serial in readers:
                    block = serial.recv(65536)
                    if not block:
                        break
                    os.write(sys.stdout.fileno(), block)
                if sys.stdin in readers:
                    block = os.read(sys.stdin.fileno(), 1024)
                    if b"\x1d" in block:
                        break
                    serial.sendall(block)
        finally:
            termios.tcsetattr(sys.stdin.fileno(), termios.TCSADRAIN, old)


def number(text):
    match = re.fullmatch(r"(0x[0-9a-fA-F]+|[0-9]+)([KMG]?)", text)
    if not match:
        raise argparse.ArgumentTypeError("使用整数、0x地址或 K/M/G 大小")
    return int(match[1], 0) * {"": 1, "K": 1024, "M": 1024**2, "G": 1024**3}[match[2]]


def main():
    parser = argparse.ArgumentParser(description="相机公开 Linux 本地模拟实验环境")
    sub = parser.add_subparsers(dest="action", required=True)
    sub.add_parser("start")
    sub.add_parser("status")
    sub.add_parser("stop")
    sub.add_parser("console")
    sub.add_parser("demo")
    sub.add_parser("menu")
    p = sub.add_parser("exec")
    p.add_argument("command")
    p.add_argument("--timeout", type=float, default=30)
    p = sub.add_parser("dump")
    p.add_argument("--address", type=number, default=RAM_BASE)
    p.add_argument("--size", type=number, default=16 * 1024**2)
    p.add_argument("--all", action="store_true")
    p.add_argument("--gzip", action="store_true")
    args = parser.parse_args()
    if args.action == "menu":
        return menu()
    with (ROOT / ".control.lock").open("a") as lock:
        try:
            fcntl.flock(lock, fcntl.LOCK_EX | fcntl.LOCK_NB)
        except BlockingIOError:
            raise RuntimeError("另一个控制操作正在进行；请先退出交互控制台")
        if args.action == "start":
            start()
        elif args.action == "demo":
            st = start()
            proof = "LUMIX_LOCAL_LINUX_PROOF_" + uuid.uuid4().hex
            result = serial_command(st, "uname -a; cat /proc/meminfo | head -n 5; "
                                    "cat /proc/net/dev; mount; "
                                    "printf '%s\\n' " + shlex.quote(proof) +
                                    " > /tmp/lab-proof.txt; cat /tmp/lab-proof.txt; "
                                    "test -s /tmp/lab-proof.txt")
            print(result["output"])
            if result["exit_code"] or proof not in result["output"]:
                raise RuntimeError("普通 Linux 命令与文件读写验证失败")
            result["proof"] = proof
            save(Path(st["run_dir"]) / "demo.json", result)
        elif args.action == "status":
            st = state()
            print(json.dumps({"qemu": running(st), "shell_verified": st["shell_verified"],
                              "udc_bound": st.get("udc_bound"), "run_dir": st["run_dir"]},
                             ensure_ascii=False, indent=2))
        elif args.action == "exec":
            result = serial_command(state(), args.command, args.timeout)
            print(result["output"])
            return result["exit_code"]
        elif args.action == "dump":
            dump_memory(state(), RAM_BASE if args.all else args.address,
                        RAM_SIZE if args.all else args.size, args.gzip)
        elif args.action == "console":
            console(state())
        elif args.action == "stop":
            stop(state())
    return 0


if __name__ == "__main__":
    try:
        sys.exit(main())
    except (OSError, RuntimeError, ValueError) as exc:
        print("错误：" + str(exc), file=sys.stderr)
        sys.exit(1)
