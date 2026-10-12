"""Fully detach the firmware-upload run from any controlling session.

Double-fork + setsid so the upload keeps running even after the launching
shell / exec session is torn down (nohup alone does not survive the
process-group cleanup). Writes the grandchild PID to out/upload.pid and the
upload stdout/stderr to the log path given as argv[1].
"""
import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
LOG = sys.argv[1] if len(sys.argv) > 1 else "out/phaseI_run11_fast.log"
PIDFILE = os.path.join(HERE, "out", "upload.pid")


def main():
    os.chdir(HERE)
    # First fork: parent returns immediately so the caller is not blocked.
    pid = os.fork()
    if pid > 0:
        os.waitpid(pid, 0)
        sys.exit(0)
    # First child: become session leader, then fork again.
    os.setsid()
    pid2 = os.fork()
    if pid2 > 0:
        with open(PIDFILE, "w") as f:
            f.write(str(pid2))
        os._exit(0)
    # Grandchild: fully detached, in its own session. Redirect stdio.
    os.chdir(HERE)
    sys.stdout.flush()
    sys.stderr.flush()
    out = open(LOG, "wb")
    devnull = open(os.devnull, "rb")
    os.dup2(out.fileno(), 1)
    os.dup2(out.fileno(), 2)
    os.dup2(devnull.fileno(), 0)
    os.execv(sys.executable,
             [sys.executable, "upload.py", "--ip", "192.168.1.131",
              "--phase", "I", "--fast", "--confirm", "--out-dir", "out"])


if __name__ == "__main__":
    main()
