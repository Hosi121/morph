#!/usr/bin/env python3
"""Check stored benchmark/log integrity, without rerunning historical jobs."""
from pathlib import Path
import gzip
import hashlib
import json
import statistics

from compare_field_kernels import normalized


def digest(data):
    return hashlib.sha256(data).hexdigest()


def require(condition, message):
    if not condition:
        raise ValueError(message)


def local(root, name):
    path = (root / name).resolve()
    require(path.is_relative_to(root.resolve()), 'Evidence path escapes repository')
    return path


def comparison(root, record):
    reference = record['lossless_full_record']
    compressed = local(root, reference['path']).read_bytes()
    require(digest(compressed) == reference['sha256'], 'Compressed evidence hash mismatch')
    raw = gzip.decompress(compressed)
    require(digest(raw) == reference['uncompressed_sha256'], 'Raw evidence hash mismatch')
    full = json.loads(raw)
    for key, value in full.items():
        if key != 'runs':
            require(record.get(key) == value, 'Summary differs from full record: ' + key)
    require(full['all_checked'] is True, 'Comparison did not pass')
    runs, groups, order = full['runs'], full['groups'], full['order']
    require(type(groups) is int and groups > 0, 'Invalid ABBA group count')
    require(order == ['before', 'after', 'after', 'before'], 'Invalid ABBA order')
    require(record['run_count'] == len(runs) and bool(runs), 'Wrong run count')
    expected, slots = {}, set()
    for run in runs:
        require(run['checked'] is True and type(run['exit_code']) is int and run['exit_code'] == 0,
                'Unchecked or failed run')
        require(json.loads(run['stdout']) == run['payload'], 'Stored stdout/payload differ')
        value = normalized(run['payload'])
        require(value == expected.setdefault(run['case'], value), 'Unequal complete results')
        group, position = run['group'], run['position']
        require(type(group) is int and 0 <= group < groups, 'Invalid group')
        require(type(position) is int and 0 <= position < len(order), 'Invalid position')
        require(run['variant'] == order[position], 'Variant differs from ABBA slot')
        slot = (run['case'], group, position)
        require(slot not in slots, 'Duplicate ABBA slot')
        slots.add(slot)
        require(type(run['process_ns']) is int and run['process_ns'] >= 0, 'Invalid duration')
    require(set(expected) == set(full['summary']), 'Missing case summary')
    require(len(slots) == len(expected) * groups * len(order), 'Missing ABBA slot')
    for case, summary in full['summary'].items():
        samples = [r for r in runs if r['case'] == case]
        timers = {'process_ns'}
        if all('elapsed_us' in r['payload'] for r in samples):
            timers.add('elapsed_us')
        require(set(summary) == timers, 'Missing or unexpected timer summary')
        for timer in timers:
            value = lambda r: r[timer] if timer == 'process_ns' else r['payload'][timer]
            by_side = {s: [value(r) for r in samples if r['variant'] == s] for s in ['before', 'after']}
            medians = {s: statistics.median(v) for s, v in by_side.items()}
            blocks = []
            for group in range(groups):
                block = {s: statistics.median(value(r) for r in samples
                         if r['variant'] == s and r['group'] == group) for s in by_side}
                blocks.append(block['before'] / block['after'] if block['after'] else None)
            recomputed = {'medians': medians, 'ranges': {s: [min(v), max(v)] for s, v in by_side.items()},
                          'before_over_after': medians['before'] / medians['after'] if medians['after'] else None,
                          'block_ratios': blocks}
            require(summary[timer] == recomputed, 'Timing summary differs from samples')


def validation(root, record):
    require(record['status'] == 'passed' and bool(record['commands']), 'Validation did not pass')
    commands = record['commands']
    require(len({c['name'] for c in commands}) == len(commands), 'Duplicate validation command')
    name = commands[0]['published_log']['path']
    data = local(root, name).read_bytes()
    require(digest(data) == record['published_log_sha256'], 'Published log hash mismatch')
    end = 0
    for command in commands:
        span = command['published_log']
        offset, length = span['offset_bytes'], span['length_bytes']
        require(type(command['returncode']) is int and command['returncode'] == 0, 'Failed validation command')
        require(span['path'] == name and type(offset) is int and type(length) is int,
                'Invalid published span')
        require(offset >= end and length >= 0 and offset + length <= len(data), 'Overlapping/out-of-bounds log')
        require(digest(data[offset:offset + length]) == command['sha256'], 'Command log hash mismatch')
        end = offset + length
    if 'harness_published_path' in record:
        require(digest(local(root, record['harness_published_path']).read_bytes()) == record['runner_sha256'],
                'Published runner hash mismatch')


def check(root):
    counts = [0, 0]
    for path in sorted((root / 'docs/measurements').glob('*.json')):
        record = json.loads(path.read_text())
        if not isinstance(record, dict):
            continue
        try:
            if 'lossless_full_record' in record:
                comparison(root, record)
                counts[0] += 1
            if 'published_log_sha256' in record:
                validation(root, record)
                counts[1] += 1
        except (ValueError, KeyError, OSError, TypeError) as error:
            raise ValueError(str(path.relative_to(root)) + ': ' + str(error)) from error
    return counts


if __name__ == '__main__':
    counts = check(Path(__file__).resolve().parent.parent)
    print(f'Evidence integrity gate passed: {counts[0]} lossless comparisons, {counts[1]} byte-indexed logs; no historical jobs rerun.')
