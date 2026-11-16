#!/usr/bin/env python3
"""Compare frozen native CAD test artifacts under tools/measure's CPU lock.

Build both artifacts with the same SDK, dependency versions and test selection.
The recorded historical comparison uses baseline a142a05 plus the archived
nested-radical test; the only production change is the smaller-root source patch.
"""
import argparse
import hashlib
import json
import os
from pathlib import Path
import subprocess
import time


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--before', type=Path, required=True)
    parser.add_argument('--after', type=Path, required=True)
    parser.add_argument('--output', type=Path, required=True)
    parser.add_argument('--selection', default='cad_wbtest.mbt:8-9')
    args = parser.parse_args()
    affinity = sorted(os.sched_getaffinity(0))
    if len(affinity) != 1:
        parser.error('Run under tools/measure --cpu N to serialize and pin execution.')
    executables = {'before': args.before.resolve(), 'after': args.after.resolve()}
    records = []
    for phase in ('before', 'after', 'after', 'before'):
        executable = executables[phase]
        digest = hashlib.sha256(executable.read_bytes()).hexdigest()
        start = time.perf_counter()
        result = subprocess.run([str(executable), args.selection], capture_output=True, text=True)
        elapsed = time.perf_counter() - start
        # Moon's standalone runner can report failures in its JSON protocol.
        results = [json.loads(line) for line in result.stdout.splitlines() if line.startswith('{')]
        outcomes = [entry for entry in results if entry.get('type') == 'result']
        if result.returncode or not outcomes or any(entry.get('message') != '' for entry in outcomes):
            raise RuntimeError(f'Failed frozen artifact: {result.returncode}\n{result.stdout}\n{result.stderr}')
        records.append({'phase': phase, 'seconds': elapsed, 'sha256': digest,
                        'exit': result.returncode, 'stdout': result.stdout, 'stderr': result.stderr})
    args.output.parent.mkdir(parents=True, exist_ok=True)
    args.output.write_text(json.dumps({'cpu': affinity, 'order': 'ABBA', 'selection': args.selection,
                                      'records': records}, indent=2) + '\n')
    print(json.dumps([{'phase': item['phase'], 'seconds': item['seconds']} for item in records]))


if __name__ == '__main__':
    main()
