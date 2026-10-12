# -*- coding: utf-8 -*-
import json
import pathlib
import subprocess
import concurrent.futures

ROOT = pathlib.Path('<LOCAL_WORKSPACE>')
OUT = ROOT / 'analysis/parallel_routes_20261009'
HELPER = '<LOCAL_USER>/.codex/skills/gemini-delegate/scripts/gemini_delegate.py'
COMMON = '''你是并行离线研究中的一个独立工作者。目标是 Panasonic DC-S1M2 国行 V1.4 的可执行固件逆向，最终目标为机内HDR、机械快门高分辨率拍摄或输入RAW导出；桌面合成不是替代交付。当前无相机，用户绝不拆机。项目根目录 <LOCAL_WORKSPACE>。先读取 S1M2固件逆向_阶段结果汇总.md 以及本任务相关 Codex核验报告；不要照抄旧“终局/100%排除”结论。所有旧报告只作索引，关键判断须核验原始文件或可执行检查。禁止连接设备、USB/PTP/Wi-Fi探测、改相机状态、刷写、运行下载的EXE/DLL/APK、发布GitHub或联系他人。可运行自己编写的离线解析脚本。不得修改既有材料，只在指定输出目录写报告、脚本和证据；不得扫描无关用户目录。不要输出密钥、口令、令牌或个人机身标识。其他工作者同时运行，避免共享输出。报告必须包含：本轮实际做了什么、候选路径与结果、原始证据路径/偏移/来源链接、观察/推论/未知、最小下一步和停止原因。成功标准是可验证的程序明文、明确加载/解码调用链、或可定位的未验证读取入口；高熵、字符串、函数名字及失败搜索不能单独证明结论。若无进展直说，勿写虚假突破。返回摘要最多300中文字符，完整结果写 report.md。'''
TASKS = {
 '01_container': '''路线1：重新检查UPD受保护组件。输入 S1m2_V14.bin、analysis/inventory.json、analysis/unpacked/components/、已有GH2/PTool和V1.3/SL3比较脚本与原始样本。只做与既有实验不同且可证伪的结构假设：目录hash/尾字段、分块/对齐/压缩或变换边界、已知填充与跨版本对照；先列已有实验，避免同一密钥/模式重复盲测。检查是否存在能得到明文的未处理加载器或嵌套段。每个新检查保存脚本、参数、输出及阳性对照；没有理由不要暴力枚举密码。禁止把目标字段当运行时地址。''',
 '02_host': '''路线2：Windows/Mac官方Tether中的维护/诊断/数据读取路径。输入 analysis/sources/tether_windows_2_12/、analysis/tether_windows_review_20261009/、analysis/tether_2_12_*、analysis/tether_aw_*、analysis/Windows_Tether初步_Codex核验_20261009.md、analysis/Tether应用维护审计_Codex核验_20261008.md。重点复核仅查导出函数可能遗漏的内部调用、动态API、资源/消息/诊断路径。离线追踪读操作的opcode/参数/返回长度/地址含义，区分媒体对象offset与物理RAM。不重新执行已审计的普通更新传输。可静态分析PE/MachO，禁止加载执行这些二进制。至少给出一条具体调用链或解释为何缺工具/入口。''',
 '03_flow': '''路线3：LUMIX Flow/Sync HTTP/TLS面，评估是否存在真实固件获取或诊断读取入口。输入 analysis/github_pr_review_input_20261009.txt（脱敏PR内容）及本项目已有APK/反编译文件。最小搜索定位本地样本，禁止把TLS凭据当固件解密密钥。从代码调用链区分普通遥控、LUT/媒体传输、更新传输、日志/诊断读取。核验PR3单引号Bearer静态拼接及机型适用范围，审计是否有未被现有PTP覆盖的只读接口。若只有报告无APK必须明确未核验，不能编造源码定位。不得输出任何凭据。''',
 '04_backup': '''路线4：S1M2 ROM BACKUP及EEPROM导出。输入 analysis/github_pr_review_input_20261009.txt、analysis/ROMBACKUP_SD路径_证据边界_20261009.md、analysis/sources/s1m2_service_manual/、analysis/s1m2_config_0x9421.bin、analysis/051f结构_Codex核验_20261009.md。优先对照维修手册核验PR2的菜单/Single条件/导出格式及卡槽证据。不能执行菜单或获取机身数据。六区样本若未实际提交，制作严格只读格式检查器和合成阳性/阴性测试，明确合成数据不能证明真机格式。分析参数转储是否存在指向固件加载/平台/版本的潜在线索，不能从文件名断言包含程序。用户只有CFexpress Type B；给出CFB是否可用的真实证据或明确未知。''',
 '05_sources': '''路线5：仅公开资料查找原厂维修/升级工具与平台加载链。先检查本地 analysis/sources/ 和现有原厂开源报告避免重复；必要时用可用搜索/网页工具查官方Panasonic/Leica/Fujitsu-Socionext开源包、维护工具说明、UPD/MC8243平台支持、公开专利/技术文档。可下载公开文档/源码到自己的输出目录，但不得注册账号、过审核/验证码、付费、索取泄露凭据、下载或运行未知工具。优先一手来源，保存发布日期和具体链接。重点找解码/验签/加载职责、维修软件到底能导出什么、无需拆机的程序读取证据。没有原始证据不得把SL3或旧Lumix类比升级为S1M2事实。必须给去重清单和仍可获取的新材料。''',
 '06_gaps': '''路线6：既有采集与研究的遗漏审计，只读。输入 S1M2研究当前状态.md（含可能夸大附录，勿盲信）、analysis/vendor_capability_inventory_20261008_10/、analysis/vendor_current_inventory_20261008_09/、analysis/baseline_20261008_01/、analysis/tether_client_transport_paths.json、analysis/antigravity_ram_entry_review_20261008.json、analysis/antigravity_ptp_entry_review.json。对已测试/仅静态发现/未验证/被误排除的读取路线建立矩阵，明确完整RAM获取究竟缺哪个先决条件。不得执行设备枚举或命令探测。把以后拿到机身时最有信息量的少量验证写为分阶段方案，包含预期响应、能排除什么、停止条件；未知写命令只能标记不执行。不要泛泛列漏洞名字，应给可定位的数据或调用证据。'''
}

def run(item):
    name, task = item
    folder = OUT / name
    folder.mkdir(parents=True, exist_ok=True)
    prompt = COMMON + '\n本任务唯一输出目录：' + str(folder) + '\n' + task
    (folder / 'task.txt').write_text(prompt)
    command = ['python3', HELPER, '--model', 'gemini-3.8-flash', '--thinking-level', 'high', '--cwd', str(ROOT), '--prompt', prompt, '--json']
    with (folder / 'result.json').open('w') as stdout, (folder / 'runner.stderr').open('w') as stderr:
        proc = subprocess.Popen(command, stdout=stdout, stderr=stderr)
        (folder / 'pid.txt').write_text(str(proc.pid))
        print(json.dumps({'task':name,'status':'started','pid':proc.pid}), flush=True)
        code = proc.wait()
    try:
        result = json.loads((folder / 'result.json').read_text())
        status = {key:result.get(key) for key in ['finished','model_verified','model_id','thinking_level']}
        status.update(task=name, exit_code=code, report_exists=(folder / 'report.md').exists())
    except Exception as exc:
        status = {'task':name,'exit_code':code,'parse_error':str(exc)}
    (folder / 'status.json').write_text(json.dumps(status, ensure_ascii=False, indent=2))
    print(json.dumps(status, ensure_ascii=False), flush=True)

if __name__ == '__main__':
    with concurrent.futures.ThreadPoolExecutor(max_workers=6) as pool:
        list(pool.map(run, TASKS.items()))
