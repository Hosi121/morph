#!/usr/bin/env python3
"""Freeze matrix-only source/ELFs and compare five fixed ABBA blocks on CPU 4.

Invoke through tools/measure --cpu 4. References use graph search, Dijkstra,
and generic 2x2 modular matrix arithmetic, independently of the MoonBit kernel.
"""
from pathlib import Path
import argparse
import gzip
import hashlib
import io
import json
import os
import platform
import re
import shutil
import statistics
import subprocess
import tarfile
import time

ROOT = Path(__file__).resolve().parent.parent
STEM = 'matrix-kernel-20261118'
SCRATCH = ROOT / '.tools/matrix-kernel'
PUBLIC = ROOT / 'docs/measurements'
CASES = {'zero': (0, 20000), 'tiny': (1, 20000), 'bool24': (24, 300),
         'bool64': (64, 40), 'multiply24': (24, 300),
         'tropical12': (12, 80), 'block12': (12, 80)}


def sha(data):
    return hashlib.sha256(data).hexdigest()


def freeze(side):
    SCRATCH.mkdir(parents=True, exist_ok=True)
    files = {'moon.mod': (ROOT / 'moon.mod').read_bytes()}
    todo = ['cmd/matrixbench']
    seen = set()
    while todo:
        package = todo.pop()
        if package in seen:
            continue
        seen.add(package)
        directory = ROOT / 'src' / package
        pkg = directory / 'moon.pkg'
        files[str(pkg.relative_to(ROOT))] = pkg.read_bytes()
        for body, suffix in re.findall(r'import\s*\{(.*?)\}([^\n]*)', pkg.read_text(), re.S):
            if not suffix.strip().startswith('for'):
                todo.extend(re.findall(r'"Hosi121/morph/([^"\n]+)"', body))
        for path in sorted(directory.glob('*.mbt')):
            if not path.name.endswith(('_test.mbt', '_wbtest.mbt')):
                files[str(path.relative_to(ROOT))] = path.read_bytes()
    raw = io.BytesIO()
    with tarfile.open(fileobj=raw, mode='w') as tar:
        for name, data in sorted(files.items()):
            info = tarfile.TarInfo(name)
            info.size = len(data)
            info.mode = 0o644
            tar.addfile(info, io.BytesIO(data))
    archive = PUBLIC / f'{STEM}-{side}-source.tar.gz'
    archive.write_bytes(gzip.compress(raw.getvalue(), mtime=0))
    original = ROOT / '_build/native/release/build/cmd/matrixbench/matrixbench.exe'
    target = SCRATCH / f'{side}.exe'
    shutil.copyfile(original, target)
    target.chmod(0o755)
    shutil.copyfile(original.with_suffix('.c'), SCRATCH / f'{side}.c')
    manifest = {
        'side': side, 'commit': subprocess.check_output(['git', 'rev-parse', 'HEAD'], cwd=ROOT, text=True).strip(),
        'archive': str(archive.relative_to(ROOT)), 'archive_sha256': sha(archive.read_bytes()),
        'source_sha256': {k: sha(v) for k, v in files.items()},
        'executable': str(target.relative_to(ROOT)), 'executable_sha256': sha(target.read_bytes()),
        'c_sha256': sha(target.with_suffix('.c').read_bytes()),
    }
    (SCRATCH / f'{side}.json').write_text(json.dumps(manifest, indent=2) + '\n')
    print(json.dumps(manifest, indent=2))


def block_plus(a, b):
    return [(x + y) % 7 for x, y in zip(a, b)]


def block_times(a, b):
    return [sum(a[i * 2 + k] * b[k * 2 + j] for k in range(2)) % 7
            for i in range(2) for j in range(2)]


def expected(case):
    n, iterations = CASES[case]
    if case == 'block12':
        result = [[[(i + j * 2) % 7, (i * 3 + j + 1) % 7,
                    (i + j + 2) % 7, (i * 2 + j * 3) % 7]
                   for j in range(n)] for i in range(n)]
        for k in range(n):
            previous = result
            result = [[block_plus(previous[i][j], block_times(previous[i][k], previous[k][j]))
                       for j in range(n)] for i in range(n)]
    elif case == 'tropical12':
        values = [[0 if i == j else ((i * 17 + j * 11) % 23 + 1)
                   if (i * 13 + j * 7) % 5 < 2 else None
                   for j in range(n)] for i in range(n)]
        result = []
        # Dijkstra, independently of Floyd-Warshall's intermediate-vertex recurrence.
        for start in range(n):
            distance = [None] * n
            distance[start] = 0
            visited = set()
            while True:
                candidates = [(d, v) for v, d in enumerate(distance) if d is not None and v not in visited]
                if not candidates:
                    break
                d, v = min(candidates)
                visited.add(v)
                for w, edge in enumerate(values[v]):
                    if edge is not None and (distance[w] is None or d + edge < distance[w]):
                        distance[w] = d + edge
            result.append(distance)
    else:
        values = [[i == j or (i * 17 + j * 7) % 11 < 2 for j in range(n)] for i in range(n)]
        if case == 'multiply24':
            result = [[any(values[i][k] and values[k][j] for k in range(n))
                       for j in range(n)] for i in range(n)]
        else:
            result = []
            # Reachability by DFS, independently of the intermediate-vertex recurrence.
            for start in range(n):
                visited = {start}
                todo = [start]
                while todo:
                    v = todo.pop()
                    for w, edge in enumerate(values[v]):
                        if edge and w not in visited:
                            visited.add(w)
                            todo.append(w)
                result.append([v in visited for v in range(n)])
    return {'case': case, 'dimension': n, 'iterations': iterations, 'result': result, 'checked': True}


def compare():
    assert sorted(os.sched_getaffinity(0)) == [4], 'use tools/measure --cpu 4'
    manifests = {side: json.loads((SCRATCH / f'{side}.json').read_text()) for side in ('before', 'after')}
    before_sources = manifests['before']['source_sha256']
    after_sources = manifests['after']['source_sha256']
    assert set(before_sources) == set(after_sources)
    source_changes = [name for name in before_sources if before_sources[name] != after_sources[name]]
    assert source_changes == ['src/matrix/matrix.mbt'], source_changes
    for manifest in manifests.values():
        assert sha((ROOT / manifest['executable']).read_bytes()) == manifest['executable_sha256']
    runs = []
    summary = {}
    references = {case: expected(case) for case in CASES}
    for case in CASES:
        for group in range(5):
            for position, side in enumerate(('before', 'after', 'after', 'before')):
                argv = [str(ROOT / manifests[side]['executable']), case]
                start = time.perf_counter_ns()
                process = subprocess.run(argv, capture_output=True, text=True, cwd=ROOT)
                elapsed = time.perf_counter_ns() - start
                assert process.returncode == 0, (case, side, process.returncode, process.stderr)
                payload = json.loads(process.stdout)
                assert payload == references[case], (case, side, 'independent full output mismatch')
                runs.append({'case': case, 'group': group, 'position': position, 'side': side,
                             'process_ns': elapsed, 'exit_code': process.returncode, 'checked': True,
                             'stdout': process.stdout, 'stderr': process.stderr})
        samples = {side: [r['process_ns'] for r in runs if r['case'] == case and r['side'] == side]
                   for side in manifests}
        medians = {side: statistics.median(xs) for side, xs in samples.items()}
        blocks = []
        for group in range(5):
            block = {side: statistics.median(r['process_ns'] for r in runs
                                            if r['case'] == case and r['group'] == group and r['side'] == side)
                     for side in manifests}
            blocks.append(block['before'] / block['after'])
        summary[case] = {'process_ns_median': medians,
                         'process_ns_range': {side: [min(xs), max(xs)] for side, xs in samples.items()},
                         'before_over_after': medians['before'] / medians['after'], 'block_ratios': blocks}
        print(case, json.dumps(summary[case]), flush=True)
    for manifest in manifests.values():
        assert sha((ROOT / manifest['executable']).read_bytes()) == manifest['executable_sha256']
    record = {'schema': 'matrix-kernel-abba-v1', 'groups': 5,
              'order': ['before', 'after', 'after', 'before'], 'all_checked': True,
              'measurement': 'Full release native process; identical frozen benchmark; complete matrix checked every iteration; includes oracle/setup, equality and one final JSON output.',
              'affinity': sorted(os.sched_getaffinity(0)), 'platform': platform.platform(),
              'compiler': subprocess.check_output(['tools/moon', 'version', '--all'], cwd=ROOT, text=True),
              'source_and_elf': manifests, 'changed_frozen_sources': source_changes, 'references': references,
              'harness_sha256': sha(Path(__file__).read_bytes()), 'runs': runs, 'summary': summary}
    raw = (json.dumps(record, indent=2) + '\n').encode()
    path = PUBLIC / f'{STEM}.json.gz'
    path.write_bytes(gzip.compress(raw, mtime=0))
    short = {k: v for k, v in record.items() if k not in ('runs', 'references')}
    short['run_count'] = len(runs)
    short['full_record'] = {'path': str(path.relative_to(ROOT)), 'sha256': sha(path.read_bytes()), 'raw_sha256': sha(raw)}
    (PUBLIC / f'{STEM}-summary.json').write_text(json.dumps(short, indent=2) + '\n')


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--freeze', choices=['before', 'after'])
    args = parser.parse_args()
    if args.freeze:
        freeze(args.freeze)
    else:
        compare()
