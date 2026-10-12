"""Dispatch isolated AGY tasks through the skill's auto-detecting helper.

Credentials remain in memory. Each received conversation ID is saved immediately.
The observer can be restarted with --collect-only without creating new tasks.
"""
import argparse
from concurrent.futures import ThreadPoolExecutor, as_completed
from datetime import datetime, timezone
import importlib.util
import json
from pathlib import Path
import sys
import threading
import time

sys.dont_write_bytecode = True
OUT = Path(__file__).resolve().parent
ROOT = OUT.parents[1]
HELPER = Path('<LOCAL_USER>/.codex/skills/gemini-delegate/scripts/gemini_delegate.py')
STATUS = OUT / 'dispatch_status.json'
lock = threading.Lock()


def now():
    return datetime.now(timezone.utc).isoformat()


def save(data):
    with lock:
        data['updated_utc'] = now()
        tmp = STATUS.with_suffix('.tmp')
        tmp.write_text(json.dumps(data, ensure_ascii=False, indent=2) + '\n')
        tmp.replace(STATUS)


def main():
    args = argparse.ArgumentParser()
    args.add_argument('--collect-only', action='store_true')
    options = args.parse_args()
    spec = importlib.util.spec_from_file_location('gemini_skill_helper', HELPER)
    helper = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(helper)
    env = helper.get_resolved_env()
    model, thinking = 'gemini-3.8-flash', 'high'
    catalog = helper.available_models(env)
    selected = catalog[model + '-' + thinking]
    selected_id = selected['model']
    print(json.dumps({'catalog_model': selected.get('displayName'), 'model_id': selected_id,
                      'thinking_level': thinking}, ensure_ascii=False), flush=True)
    tasks = json.loads((OUT / 'tasks.json').read_text())['tasks']
    if STATUS.exists():
        state = json.loads(STATUS.read_text())
        if not options.collect_only:
            raise RuntimeError('Existing batch: use --collect-only, do not duplicate conversations.')
    else:
        if options.collect_only:
            raise RuntimeError('No previous batch to collect.')
        state = {'created_utc': now(), 'requested_model': model, 'thinking_level': thinking,
                 'catalog_model_id': selected_id, 'catalog_display_name': selected.get('displayName'),
                 'authorization': 'User explicitly requested many concurrent AGY research sessions.',
                 'tasks': tasks}
        save(state)

        def start(task):
            task['state'] = 'dispatching'
            save(state)
            try:
                prompt = (ROOT / task['prompt']).read_text()
                full = helper.build_full_prompt(prompt, str(ROOT))
                cid, variant, mid, display = helper.start_exact(env, model, thinking, full)
                task.update(conversation_id=cid, resolved_model=variant, model_id=mid,
                            display_name=display, sent_utc=now(), state='running',
                            finished=False, model_verified=False, execution_models=[])
                save(state)
                print(json.dumps({'task': task['id'], 'state': 'sent', 'conversation_id': cid},
                                 ensure_ascii=False), flush=True)
            except Exception as error:
                task.update(state='dispatch_failed', error_type=type(error).__name__)
                save(state)
                print(json.dumps({'task': task['id'], 'state': 'dispatch_failed',
                                  'error_type': type(error).__name__}), flush=True)

        with ThreadPoolExecutor(max_workers=12) as pool:
            for future in as_completed([pool.submit(start, task) for task in tasks]):
                future.result()
        cids = [t['conversation_id'] for t in tasks if t.get('conversation_id')]
        if len(set(cids)) != len(cids):
            raise RuntimeError('Nonunique conversation IDs; dispatch cannot be reported as independent.')
        print(json.dumps({'dispatch_complete': True, 'sent': len(cids),
                          'failed': sum(t['state'] == 'dispatch_failed' for t in tasks)}), flush=True)

    # Persist model metadata early, then observe completion without restarting tasks.
    cycle = 0
    terminal = {'completed_unreviewed', 'finished_needs_attention', 'dispatch_failed'}
    while any(t['state'] not in terminal for t in state['tasks']):
        for task in state['tasks']:
            if task['state'] in terminal or not task.get('conversation_id'):
                continue
            cid = task['conversation_id']
            try:
                done = helper.is_conversation_finished(cid)
                if not done and cycle % 3 == 0:
                    done = helper.is_trajectory_finished(env, cid)
                if not task.get('model_verified') or done:
                    actual = helper.execution_models(env, cid)
                    task['execution_models'] = actual
                    task['model_verified'] = bool(actual == [task['model_id']])
                if done:
                    actions, content = helper.read_transcript(cid)
                    # Transcript and model metadata may lag idle by a few seconds.
                    if not content:
                        time.sleep(2)
                        actions, content = helper.read_transcript(cid)
                    task['finished'] = True
                    task['finished_utc'] = now()
                    folder = ROOT / task['output']
                    report_ok = (folder / 'report.md').exists() and (folder / 'report.md').stat().st_size > 0
                    try:
                        result_ok = bool(json.loads((folder / 'results.json').read_text()))
                    except (OSError, ValueError):
                        result_ok = False
                    result = {'conversation_id': cid, 'finished': True, 'content': content or '',
                              'model': task['resolved_model'], 'model_id': task['model_id'],
                              'display_name': task['display_name'], 'thinking_level': thinking,
                              'execution_models': task['execution_models'], 'model_verified': task['model_verified'],
                              'tool_actions_taken': actions, 'report_present': report_ok,
                              'results_present': result_ok, 'codex_reviewed': False}
                    (folder / 'agent_result.json').write_text(json.dumps(result, ensure_ascii=False, indent=2) + '\n')
                    task['state'] = ('completed_unreviewed' if content and task['model_verified']
                                     and report_ok and result_ok else 'finished_needs_attention')
                    print(json.dumps({'task': task['id'], 'state': task['state'],
                                      'model_verified': task['model_verified']}, ensure_ascii=False), flush=True)
                task['last_checked_utc'] = now()
                task.pop('observer_error_type', None)
            except Exception as error:
                task['observer_error_type'] = type(error).__name__
            save(state)
        cycle += 1
        if any(t['state'] not in terminal for t in state['tasks']):
            time.sleep(15)
    print(json.dumps({'batch_finished': True,
                      'completed_unreviewed': sum(t['state'] == 'completed_unreviewed' for t in state['tasks']),
                      'needs_attention': sum(t['state'] != 'completed_unreviewed' for t in state['tasks'])}), flush=True)


if __name__ == '__main__':
    main()
