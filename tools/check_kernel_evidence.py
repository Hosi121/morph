#!/usr/bin/env python3
"""Check retained tensor/runbinary measurements without replaying benchmarks."""
from pathlib import Path
import hashlib
import importlib.util
import json
import statistics
import tarfile

from check_evidence import require, local


ROOT = Path(__file__).resolve().parent.parent


def sha(data):
    return hashlib.sha256(data).hexdigest()


def tensor(root, record=None):
    directory = root / 'docs/measurements/tensor-kernel-20261118'
    record = record or json.loads((directory / 'abba.json').read_text())
    harness = root / 'tools/tensor-kernel-compare.py'
    require(sha(harness.read_bytes()) == record['script_sha256'], 'Tensor harness hash mismatch')
    spec = importlib.util.spec_from_file_location('_stored_tensor_oracle', harness)
    model = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(model)
    require(record['all_checked'] and record['blocks'] == 5 and record['affinity'] == [4], 'Invalid tensor run')
    require(record['order'] == ['baseline', 'candidate', 'candidate', 'baseline'], 'Invalid tensor ABBA order')
    require(record['cases'] == json.loads(json.dumps(model.CASES)), 'Tensor case definition differs')
    for side in ['baseline', 'candidate']:
        provenance = directory / (side + '-provenance.json')
        require(sha(provenance.read_bytes()) == record['provenance_sha256'][side], 'Tensor provenance hash mismatch')
        manifest = json.loads(provenance.read_text())
        require(sha((directory / (side + '.exe')).read_bytes()) == manifest['artifact_sha256']
                == record['artifacts'][side]['sha256'], 'Tensor artifact hash mismatch')
        with tarfile.open(directory / (side + '-source.tar.gz')) as archive:
            members = archive.getmembers()
            require(len(members) == len({m.name for m in members}), 'Duplicate tensor source')
            require(all(m.isfile() for m in members), 'Non-file tensor source')
            for member in members:
                local(root, member.name)
            actual = {m.name: sha(archive.extractfile(m).read()) for m in members}
        require(actual == manifest['files'], 'Tensor source archive differs')
    rows = record['rows']
    require(len(rows) == len(model.CASES) * 20, 'Missing tensor run')
    require(set(record['summary']) == set(model.CASES), 'Tensor case summary differs')
    for case in model.CASES:
        expected = model.expected(case)
        selected = [r for r in rows if r['case'] == case]
        require(len(selected) == 20, 'Missing tensor case run')
        ratios = []
        for block in range(5):
            group = [r for r in selected if r['block'] == block]
            require([(r['position'], r['side']) for r in group] == list(enumerate(record['order'])), 'Tensor ABBA slot differs')
            for row in group:
                require(row['full_checked'] and row['exit_code'] == 0, 'Failed tensor row')
                require(json.loads(row['stdout']) == row['payload'] == expected, 'Tensor complete output differs')
                require(type(row['process_ns']) is int and row['process_ns'] > 0, 'Invalid tensor duration')
            values = {s: statistics.median(r['process_ns'] for r in group if r['side'] == s) for s in record['order']}
            ratios.append(values['baseline'] / values['candidate'])
        medians = {s: statistics.median(r['process_ns'] for r in selected if r['side'] == s) for s in record['order']}
        expected_summary = dict(median_ns=medians, before_over_after=medians['baseline'] / medians['candidate'],
                                block_ratios=ratios, positive_blocks=sum(r > 1 for r in ratios),
                                ranges_ns={s: [min(r['process_ns'] for r in selected if r['side'] == s),
                                               max(r['process_ns'] for r in selected if r['side'] == s)] for s in medians})
        require(record['summary'][case] == expected_summary, 'Tensor timing summary differs')


def runbinary(root):
    report = json.loads((root / 'tools/unused-kernel-report.json').read_text())
    log = (root / 'tools/unused-kernel-js-bench.txt').read_bytes()
    require(sha(log) == report['measurement_log_sha256'], 'Runbinary measurement hash mismatch')
    for file, key in [('src/runbinary/runbinary.mbt', 'candidate_source_sha256'),
                      ('src/runbinary/expansion_bench_wbtest.mbt', 'bench_source_sha256')]:
        require(sha((root / file).read_bytes()) == report[key], 'Runbinary frozen source differs')
    batches = [json.loads(line) for line in log.decode().splitlines() if line.startswith('[{"name":')]
    require(len(batches) == 1 and len(batches[0]) == 60, 'Runbinary benchmark slots differ')
    results = {}
    for offset in range(0, 60, 4):
        block = batches[0][offset:offset + 4]
        case, name, _ = block[0]['name'].split('/')
        require([r['name'] for r in block] == [f'{case}/{name}/{s}' for s in ['reference', 'candidate', 'candidate', 'reference']], 'Runbinary ABBA order differs')
        require(all(r['runs'] == 5 for r in block), 'Runbinary sampling differs')
        before = statistics.mean(r['mean'] for r in (block[0], block[3]))
        after = statistics.mean(r['mean'] for r in (block[1], block[2]))
        results.setdefault(case, []).append(dict(block=name, reference_mean_us=before,
            candidate_mean_us=after, reference_over_candidate=before / after))
    require(set(results) == set(report['results']), 'Runbinary cases differ')
    for case, blocks in results.items():
        require([b['block'] for b in blocks] == [f'block{i}' for i in range(5)], 'Runbinary groups differ')
        expected = dict(blocks=blocks, reference_median_block_mean_us=statistics.median(b['reference_mean_us'] for b in blocks),
                        candidate_median_block_mean_us=statistics.median(b['candidate_mean_us'] for b in blocks),
                        median_reference_over_candidate=statistics.median(b['reference_over_candidate'] for b in blocks),
                        improved_blocks=sum(b['reference_over_candidate'] > 1 for b in blocks))
        require(report['results'][case] == expected, 'Runbinary summary differs')


if __name__ == '__main__':
    tensor(ROOT)
    runbinary(ROOT)
    print('Kernel evidence passed: tensor 120 complete outputs/source archives and runbinary 60 benchmark groups; no benchmarks replayed.')
