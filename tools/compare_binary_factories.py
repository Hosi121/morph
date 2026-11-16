#!/usr/bin/env python3
"""Replay frozen native benchmark ELFs in ABBA order; run under tools/measure."""
import argparse
import hashlib
import json
import os
from pathlib import Path
import platform
import resource
import subprocess
import time


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--before', type=Path, required=True)
    parser.add_argument('--after', type=Path, required=True)
    parser.add_argument('--filter', required=True)
    parser.add_argument('--rounds', type=int, default=2)
    parser.add_argument('--output', type=Path, required=True)
    args = parser.parse_args()
    executables = {'before': args.before.resolve(), 'after': args.after.resolve()}
    result = {'environment': {'platform': platform.platform(),
                            'affinity': sorted(os.sched_getaffinity(0)),
                            'filter': args.filter}, 'runs': []}
    for cycle in range(args.rounds):
        for label in ['before', 'after', 'after', 'before']:
            binary = executables[label]
            prior_cpu = resource.getrusage(resource.RUSAGE_CHILDREN)
            start = time.monotonic()
            process = subprocess.run([str(binary), args.filter],
                                     capture_output=True, text=True, check=True)
            wall = time.monotonic() - start
            current_cpu = resource.getrusage(resource.RUSAGE_CHILDREN)
            rows = []
            for line in process.stdout.splitlines():
                if line.startswith('{"type":"result"'):
                    item = json.loads(line)
                    if item['message'].startswith('@BATCH_BENCH '):
                        rows.append({'index': item['index'], **json.loads(item['message'][13:])})
                    else:
                        raise RuntimeError(item['message'])
            if not rows:
                raise RuntimeError('No benchmark summaries: '+process.stdout+process.stderr)
            result['runs'].append({'label': label, 'cycle': cycle, 'summaries': rows,
                                   'wall_seconds': wall,
                                   'child_cpu_seconds': current_cpu.ru_utime + current_cpu.ru_stime - prior_cpu.ru_utime - prior_cpu.ru_stime,
                                   'sha256': hashlib.sha256(binary.read_bytes()).hexdigest()})
            args.output.write_text(json.dumps(result, indent=2)+'\n')
            print(label, cycle, [(r['index'], [round(s['mean'], 3) for s in r['summaries']]) for r in rows], flush=True)


if __name__ == '__main__':
    main()
