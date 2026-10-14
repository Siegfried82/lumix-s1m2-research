"""Execute only our own offline tools; record real logs, times and exit status."""
import argparse
import hashlib
import json
import os
import platform
import subprocess
import sys
from datetime import datetime,timezone
from pathlib import Path
HERE=Path(__file__).resolve().parent
def main():
    p=argparse.ArgumentParser()
    p.add_argument("--roots",type=Path,required=True)
    p.add_argument("--output",type=Path,required=True)
    args=p.parse_args()
    out=args.output.resolve();out.mkdir(parents=True,exist_ok=False)
    env={**os.environ,"PYTHONUTF8":"1","PYTHONDONTWRITEBYTECODE":"1"}
    commands=[("01_unit_tests",[sys.executable,"-X","utf8","-m","unittest","-v","test_corpus"]),
              ("02_corpus",[sys.executable,"-X","utf8",str(HERE/"corpus_audit.py"),
                            "--roots",str(args.roots.resolve()),"--output",str(out/"data")]),
              ("03_result_verification",[sys.executable,"-X","utf8",str(HERE/"verify_results.py"),
                                          "--results",str(out/"data"),"--roots",str(args.roots.resolve())]),
              ("04_existing_archive",[sys.executable,"-X","utf8",str(HERE.parent.parent/"evidence"/"verify_public.py")])]
    record={"python":platform.python_version(),"steps":[],"all_passed":False,
            "device_communication":False,"firmware_executed":False,"github_write":False}
    for name,cmd in commands:
        started=datetime.now(timezone.utc).isoformat()
        r=subprocess.run(cmd,cwd=HERE,env=env,capture_output=True,text=True,encoding="utf-8")
        log="STDOUT\n"+r.stdout+"\nSTDERR\n"+r.stderr
        with (out/(name+".log")).open("x",encoding="utf-8",newline="\n") as f:f.write(log)
        record["steps"].append({"name":name,"started_utc":started,
            "finished_utc":datetime.now(timezone.utc).isoformat(),"exit_code":r.returncode,
            "log":name+".log","log_sha256":hashlib.sha256(log.encode()).hexdigest()})
        print(json.dumps({"step":name,"exit_code":r.returncode}),flush=True)
        if r.returncode:break
    record["all_passed"]=len(record["steps"])==4 and all(s["exit_code"]==0 for s in record["steps"])
    with (out/"execution.json").open("x",encoding="utf-8",newline="\n") as f:json.dump(record,f,indent=2);f.write("\n")
    return 0 if record["all_passed"] else 1
if __name__=="__main__":raise SystemExit(main())
