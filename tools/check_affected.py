#!/usr/bin/env python3
"""Checkpointed affected-package verification for a fixed clean Git source.

Use a separate tools/measure invocation for each stage, so an interrupted long
run keeps completed targets. Examples:
  tools/measure --cpu 4 python3 tools/check_affected.py --record .tools/check/run.json --init --base HEAD~1
  tools/measure --cpu 4 python3 tools/check_affected.py --record .tools/check/run.json --stage next
Repeat `--stage next` until passed. `--status` never executes commands.
Existing API changes require explicit --allow-interface paths at initialization;
new packages are additive. This checks byte drift, not semantic compatibility.
"""
from pathlib import Path, PurePosixPath
import argparse
from contextlib import contextmanager
import fcntl
import datetime
import hashlib
import json
import os
import platform
import re
import resource
import subprocess
import time

STAGES = ('maintenance', 'check-js', 'check-native', 'tests-wasm-gc', 'tests-js', 'tests-native', 'formal')


def utc():
    return datetime.datetime.now(datetime.timezone.utc).isoformat()


def sha(path):
    return hashlib.sha256(Path(path).read_bytes()).hexdigest()


def imports(text):
    return set(re.findall(r'"Hosi121/morph/([^"\n]+)"', text))


def owner(path, packages):
    candidates = [p for p in packages if path.startswith('src/' + p + '/')]
    return max(candidates, key=len) if candidates else None


def affected(old, new, changed):
    graph = {p: old.get(p, set()) | new.get(p, set()) for p in old.keys() | new.keys()}
    roots = set()
    for path in changed:
        found = {p for p in (owner(path, old), owner(path, new)) if p is not None}
        if not found:
            raise ValueError('Changed source has no package: ' + path)
        roots.update(found)
    selected = set(roots)
    while True:
        expanded = selected | {p for p, deps in graph.items() if deps & selected}
        if expanded == selected:
            return sorted(roots), sorted(selected & new.keys())
        selected = expanded


# Conservative source proof AND cached compiler corroboration. No metadata-only skips.
TEST_INFO_KEYS = {'tests', 'no_args_tests', 'with_args_tests',
                  'with_bench_args_tests', 'async_tests', 'async_tests_with_args'}
MODULE_KEYS = {'name', 'version', 'source', 'preferred_target', 'description'}


def zero_test_command(root, package):
    """Return auditable proof or None. Unknown configurations always keep tests."""
    parts = PurePosixPath(package).parts
    if len(parts) < 2 or parts[0] != 'cmd' or any(p in {'.', '..'} for p in parts):
        return None
    directory = root / 'src' / package
    try:
        if not directory.is_dir() or directory.is_symlink():
            return None
        # Recognize only this repository's plain, generation-free module syntax.
        if (root / 'moon.mod.json').exists() or (root / 'moon.work').exists():
            return None
        module = (root / 'moon.mod').read_text()
        for line in module.splitlines():
            if not line.strip():
                continue
            match = re.fullmatch(r'\s*([a-z_]+)\s*=\s*("(?:[^"\\]|\\.)*")\s*', line)
            if not match or match[1] not in MODULE_KEYS:
                return None
            value = json.loads(match[2])
            if match[1] == 'source' and value != 'src':
                return None
        config = directory / 'moon.pkg'
        if (directory / 'moon.pkg.json').exists() or config.is_symlink():
            return None
        text = config.read_text()
        # Whitelist imports and executable declaration; any build hook, conditional
        # source setting, comments, or future option leaves residue and keeps tests.
        residue = re.sub(r'import\s*\{[^{}]*\}', '', text)
        residue, declarations = re.subn(r'pkgtype\s*\(\s*kind\s*:\s*"executable"\s*\)', '', residue)
        if declarations != 1 or residue.strip():
            return None
        sources = sorted(directory.rglob('*.mbt'))
        if not sources or any(p.is_symlink() or p.parent != directory for p in sources):
            return None
        if any(p.name.endswith(('_test.mbt', '_wbtest.mbt')) for p in sources):
            return None
        contents = {p: p.read_text() for p in sources}
        if any(re.search(r'\b(?:test|bench)\b|```|~~~', text) for text in contents.values()):
            return None
        # Metadata is an extra veto, never the source of the no-test conclusion.
        # Missing, stale-shape, unknown-schema, or nonempty records keep the package.
        metadata = []
        for kind in ('internal', 'blackbox'):
            path = root / '_build/native/release/test' / package / ('__' + kind + '_test_info.json')
            info = json.loads(path.read_text())
            if set(info) != TEST_INFO_KEYS:
                return None
            for tests in info.values():
                if not isinstance(tests, dict) or set(tests) != {p.name for p in sources}:
                    return None
                if any(not isinstance(entries, list) or entries for entries in tests.values()):
                    return None
            metadata.append({'path': str(path.relative_to(root)), 'sha256': sha(path)})
        return {'package': package, 'source_count': len(sources), 'test_file_count': 0,
                'test_keyword_count': 0, 'documentation_fence_count': 0,
                'source_sha256': {str(p.relative_to(root)): sha(p) for p in sources},
                'configuration_sha256': {str(p.relative_to(root)): sha(p) for p in (root / 'moon.mod', config)},
                'native_empty_metadata': metadata}
    except (OSError, UnicodeError, ValueError, TypeError, KeyError):
        return None


def runtime_selection(root, packages):
    runtime, skipped = [], []
    for package in packages:
        proof = zero_test_command(root, package)
        if proof is None:
            runtime.append(package)
        else:
            skipped.append(proof)
    return runtime, skipped


def verify_record(root, record, git):
    if record.get('runner_sha256') and sha(__file__) != record['runner_sha256']:
        raise ValueError('Verification runner changed; initialize a new record')
    if record['source_commit'] != git('rev-parse', 'HEAD'):
        raise ValueError('Git HEAD changed; initialize a new record for the new source')
    for path, expected in record['source_files'].items():
        if not (root / path).is_file() or sha(root / path) != expected:
            raise ValueError('Source drift: ' + path)
    for proof in record.get('skipped_zero_test_commands', []):
        if zero_test_command(root, proof['package']) != proof:
            raise ValueError('Runtime selection drift: ' + proof['package'])
    for command in record['commands']:
        if command['returncode'] != 0 or sha(root / command['log']) != command['sha256']:
            raise ValueError('Completed command/log drift: ' + command['name'])


def write_record(path, record):
    temporary = path.with_suffix(path.suffix + '.tmp')
    temporary.write_text(json.dumps(record, indent=2) + '\n')
    temporary.replace(path)


def initialize(root, path, base, allowed, git, full=False):
    if path.exists():
        raise ValueError('Record already exists; never overwrite evidence')
    if git('status', '--porcelain'):
        raise ValueError('Initialization requires a clean committed working tree')
    base = git('rev-parse', base)
    if not full and git('diff', '--name-only', base, '--', 'moon.mod', 'tools/moon'):
        raise ValueError('Module/compiler wrapper changed; use full repository regression')
    old_paths = [p for p in git('ls-tree', '-r', '--name-only', base, '--', 'src').splitlines()
                 if p.endswith('/moon.pkg')]
    old = {str(PurePosixPath(p).parent.relative_to('src')): imports(git('show', base + ':' + p))
           for p in old_paths}
    new = {str(p.parent.relative_to(root / 'src')): imports(p.read_text())
           for p in (root / 'src').rglob('moon.pkg')}
    changed = git('diff', '--name-only', '--no-renames', base, '--', 'src').splitlines()
    roots, packages = affected(old, new, changed)
    if full:
        packages = sorted(new)
    api_paths = [p for p in git('ls-tree', '-r', '--name-only', base, '--', 'src').splitlines()
                 if p.endswith('/pkg.generated.mbti')]
    api_changes = []
    for name in api_paths:
        current = root / name
        if not current.is_file() or current.read_text().strip() != git('show', base + ':' + name):
            api_changes.append(name)
            if name not in allowed:
                raise ValueError('Existing interface changed without review allowance: ' + name)
    if set(allowed) != set(api_changes):
        raise ValueError('Interface allowances must match actual reviewed changes exactly')
    paths = git('ls-files', 'src', 'tools', 'moon.mod', 'formal',
                ':(glob)docs/research/**/*.py', ':(glob)docs/research/**/*.json').splitlines()
    files = {p: sha(root / p) for p in paths if (root / p).is_file()}
    runtime_packages, skipped = runtime_selection(root, packages)
    record = dict(started_utc=utc(), source_commit=git('rev-parse', 'HEAD'), baseline=base,
                  runner_path=str(Path(__file__).resolve()), runner_sha256=sha(__file__),
                  scope=('Full repository package graph, with only proven empty CLI drivers omitted from runtime tests.' if full else
                         'Changed packages and reverse closure of old+new imports, including tests. Unrelated unchanged tests not rerun.'),
                  full_repository=full,
                  changed_files=changed, roots=roots, packages=packages,
                  runtime_packages=runtime_packages, skipped_zero_test_commands=skipped,
                  old_import_graph={p: sorted(v) for p, v in old.items()},
                  new_import_graph={p: sorted(v) for p, v in new.items()},
                  source_files=files,
                  source_manifest_sha256=hashlib.sha256(json.dumps(files, sort_keys=True).encode()).hexdigest(),
                  reviewed_interface_changes=api_changes, platform=platform.platform(),
                  affinity=sorted(os.sched_getaffinity(0)), python=platform.python_version(),
                  toolchain=subprocess.check_output([str(root / 'tools/moon'), 'version', '--all'], cwd=root, text=True),
                  commands=[], interruptions=[], status='running', inflight=None)
    path.parent.mkdir(parents=True, exist_ok=True)
    write_record(path, record)
    return record


def argv_for(stage, root, packages):
    if stage == 'maintenance':
        gates = [s for s in (root / 'tools/check').read_text().splitlines()
                 if s.startswith(('python3 ', 'tools/moon ')) and not s.startswith('tools/moon test ')]
        gates = [s.replace('tools/moon check --deny-warn', 'tools/moon check --deny-warn -j 1') for s in gates]
        return ['bash', '-c', 'set -euo pipefail\n' + '\n'.join(gates)]
    if stage.startswith('check-'):
        return ['tools/moon', 'check', '--target', stage[len('check-'):], '--deny-warn', '-j', '1']
    if stage.startswith('tests-'):
        if not packages:
            return ['python3', '-c', 'print("No changed source packages; no target tests selected")']
        target = stage[len('tests-'):]
        return ['tools/moon', 'test', *['src/' + p for p in packages], '--target', target,
                '--deny-warn', '-j', '1'] + (['--release'] if target == 'native' else [])
    return ['tools/check_formal']


def process_token(pid):
    try:
        # The executable name may contain spaces; field22 follows final ')'.
        fields = Path(f'/proc/{pid}/stat').read_text().rsplit(')', 1)[1].split()
        return None if fields[0] == 'Z' else fields[19]
    except (FileNotFoundError, ProcessLookupError):
        return None


def running_child(inflight):
    return inflight['child_token'] is not None and process_token(inflight['child_pid']) == inflight['child_token']


def run_stage(root, path, record, stage, git):
    verify_record(root, record, git)
    completed = [c['name'] for c in record['commands']]
    if stage in completed:
        print('Already passed, hashes verified:', stage)
        return
    if completed != list(STAGES[:len(completed)]) or stage != STAGES[len(completed)]:
        raise ValueError('Execute stages in order; use --stage next')
    inflight = record.get('inflight')
    if inflight:
        if running_child(inflight):
            raise ValueError('Previous child is still running; wait rather than duplicate it')
        old_log = root / inflight['log']
        partial = old_log.with_name(old_log.stem + '.partial-' + str(len(record['interruptions']) + 1) + '.log')
        old_log.replace(partial)
        record['interruptions'].append(dict(stage=inflight['name'], started_utc=inflight['started_utc'],
                                           partial_log=str(partial.relative_to(root)), sha256=sha(partial),
                                           note='No completion status was recorded; repeat only this incomplete stage.'))
    log = path.parent / (stage + '.log')
    packages = record.get('runtime_packages', record['packages']) if stage.startswith('tests-') else record['packages']
    argv = argv_for(stage, root, packages)
    start = time.perf_counter()
    with log.open('w') as output:
        child = subprocess.Popen(argv, cwd=root, stdout=output, stderr=subprocess.STDOUT)
        record['inflight'] = dict(name=stage, child_pid=child.pid, child_token=process_token(child.pid),
                                  started_utc=utc(), log=str(log.relative_to(root)))
        write_record(path, record)
        returncode = child.wait()
    if returncode:
        record['last_failed_attempt'] = dict(name=stage, returncode=returncode, argv=argv,
                                            log=str(log.relative_to(root)), sha256=sha(log))
        record['status'] = 'running' if returncode < 0 else 'failed'
        write_record(path, record)
        raise ValueError(f'{stage} failed with {returncode}; inspect {log}')
    verify_record(root, record, git)
    record['commands'].append(dict(name=stage, argv=argv, returncode=returncode,
                                   wall_seconds=time.perf_counter() - start,
                                   log=str(log.relative_to(root)), sha256=sha(log),
                                   test_totals=re.findall(r'Total tests: (\d+), passed: (\d+), failed: (\d+)', log.read_text())))
    record['inflight'] = None
    if len(record['commands']) == len(STAGES):
        record['status'] = 'passed'
        record['finished_utc'] = utc()
    write_record(path, record)
    print('PASSED', stage, record['commands'][-1]['test_totals'], flush=True)


@contextmanager
def checkpoint_lock(path):
    path.parent.mkdir(parents=True, exist_ok=True)
    with path.with_suffix(path.suffix + '.lock').open('a') as handle:
        try:
            fcntl.flock(handle, fcntl.LOCK_EX | fcntl.LOCK_NB)
        except BlockingIOError as error:
            raise ValueError('Another stage owns this record; wait rather than duplicate it') from error
        try:
            yield
        finally:
            fcntl.flock(handle, fcntl.LOCK_UN)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--record', type=Path, required=True)
    parser.add_argument('--init', action='store_true')
    parser.add_argument('--base')
    parser.add_argument('--full', action='store_true', help='initialize all current packages instead of only the affected closure')
    parser.add_argument('--allow-interface', action='append', default=[])
    parser.add_argument('--status', action='store_true')
    parser.add_argument('--stage', choices=['next', *STAGES])
    args = parser.parse_args()
    if not args.init and (args.base or args.allow_interface or args.full):
        raise ValueError('--base/--allow-interface/--full are initialization options')
    root = Path(subprocess.check_output(['git', 'rev-parse', '--show-toplevel'], text=True).strip())
    path = args.record.resolve()
    if not path.is_relative_to(root):
        raise ValueError('Record must be inside the repository (normally .tools/)')
    git = lambda *a: subprocess.check_output(['git', *a], cwd=root, text=True).strip()
    resource.setrlimit(resource.RLIMIT_CORE, (0, 0))
    if args.status:
        if args.init or args.stage:
            raise ValueError('--status cannot initialize or run a stage')
        record = json.loads(path.read_text())
        verify_record(root, record, git)
        print(json.dumps({'status': record['status'], 'source_commit': record['source_commit'],
                          'completed': [c['name'] for c in record['commands']],
                          'inflight': record.get('inflight'),
                          'remaining': list(STAGES[len(record['commands']):])}))
        return
    with checkpoint_lock(path):
        if args.init:
            if not args.base or args.stage or args.status:
                raise ValueError('--init requires --base and executes no heavy stage')
            record = initialize(root, path, args.base, args.allow_interface, git, full=args.full)
        else:
            record = json.loads(path.read_text())
            verify_record(root, record, git)
        if args.stage:
            if record['status'] != 'running':
                raise ValueError('Record is not running; preserve it and initialize a new record after a failure')
            stage = STAGES[len(record['commands'])] if args.stage == 'next' else args.stage
            run_stage(root, path, record, stage, git)
        print(json.dumps({'status': record['status'], 'source_commit': record['source_commit'],
                          'packages': len(record['packages']), 'completed': [c['name'] for c in record['commands']],
                          'remaining': list(STAGES[len(record['commands']):])}, ensure_ascii=False))


if __name__ == '__main__':
    try:
        main()
    except (ValueError, AssertionError) as error:
        raise SystemExit(str(error))
