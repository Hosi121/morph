#!/usr/bin/env python3
"""Validate stored matrix ABBA evidence without rerunning measurements."""
import gzip
import io
import json
from pathlib import Path
import runpy
import statistics
import tarfile

ROOT = Path(__file__).resolve().parent.parent
MODEL = runpy.run_path(str(ROOT / 'tools/matrix-kernel-compare.py'))
STEM = MODEL['STEM']
PUBLIC = ROOT / 'docs/measurements'
sha = MODEL['sha']


def main():
    summary = json.loads((PUBLIC / f'{STEM}-summary.json').read_text())
    full = summary['full_record']
    compressed = (ROOT / full['path']).read_bytes()
    raw = gzip.decompress(compressed)
    assert sha(compressed) == full['sha256']
    assert sha(raw) == full['raw_sha256']
    record = json.loads(raw)
    assert record['harness_sha256'] == sha((ROOT / 'tools/matrix-kernel-compare.py').read_bytes())
    assert record['groups'] == 5 and record['order'] == ['before', 'after', 'after', 'before']
    assert record['all_checked'] and record['affinity'] == [4]
    assert record['changed_frozen_sources'] == ['src/matrix/matrix.mbt']
    for side, manifest in record['source_and_elf'].items():
        archive = (ROOT / manifest['archive']).read_bytes()
        assert sha(archive) == manifest['archive_sha256']
        with tarfile.open(fileobj=io.BytesIO(gzip.decompress(archive))) as tar:
            actual = {item.name: sha(tar.extractfile(item).read()) for item in tar.getmembers()}
        assert actual == manifest['source_sha256'], side
    sources = record['source_and_elf']
    before, after = (sources[side]['source_sha256'] for side in ('before', 'after'))
    assert set(before) == set(after)
    assert [name for name in before if before[name] != after[name]] == ['src/matrix/matrix.mbt']
    cases = MODEL['CASES']
    assert len(record['runs']) == len(cases) * 5 * 4
    for case in cases:
        expected = MODEL['expected'](case)
        assert record['references'][case] == expected
        rows = [row for row in record['runs'] if row['case'] == case]
        assert len(rows) == 20
        for group in range(5):
            group_rows = [r for r in rows if r['group'] == group]
            assert [(r['position'], r['side']) for r in group_rows] == list(enumerate(record['order']))
        for row in rows:
            assert row['checked'] and row['exit_code'] == 0 and not row['stderr']
            assert json.loads(row['stdout']) == expected
        medians = {side: statistics.median(r['process_ns'] for r in rows if r['side'] == side)
                   for side in ('before', 'after')}
        measured = record['summary'][case]
        assert medians == measured['process_ns_median']
        assert measured['before_over_after'] == medians['before'] / medians['after']
    assert summary['run_count'] == len(record['runs'])
    assert {k: v for k, v in summary.items() if k not in ('run_count', 'full_record')} == {
        k: v for k, v in record.items() if k not in ('runs', 'references')}

    # Confirm this fixture detects the two errors that Bool cannot expose.
    n = cases['block12'][0]
    initial = [[[(i + j * 2) % 7, (i * 3 + j + 1) % 7,
                 (i + j + 2) % 7, (i * 2 + j * 3) % 7]
                for j in range(n)] for i in range(n)]
    swapped = initial
    in_place = [[entry.copy() for entry in row] for row in initial]
    plus, times = MODEL['block_plus'], MODEL['block_times']
    for k in range(n):
        old = swapped
        swapped = [[plus(old[i][j], times(old[k][j], old[i][k])) for j in range(n)] for i in range(n)]
        for i in range(n):
            for j in range(n):
                in_place[i][j] = plus(in_place[i][j], times(in_place[i][k], in_place[k][j]))
    correct = MODEL['expected']('block12')['result']
    assert swapped != correct and in_place != correct
    print('Matrix evidence passed: 140 complete outputs, 5 ABBA blocks/case, frozen source hashes, noncommutative mutation probes.')


if __name__ == '__main__':
    main()
