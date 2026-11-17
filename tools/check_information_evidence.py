#!/usr/bin/env python3
"""Verify retained complete information-geometry measurements without rerunning them."""
from pathlib import Path, PurePosixPath
import gzip
import hashlib
import io
import json
import math
import tarfile

from benchmark_information import CASES, decode, expected_outputs, summarize

ROOT=Path(__file__).resolve().parent.parent
PREFIX='information-tensor-consumers-20261118'


def sha(value):
    return hashlib.sha256(value).hexdigest()


def validate(record, expected):
    assert record['schema']==1 and record['blocks']==5
    rows=record['rows']
    assert len(rows)==len(CASES)*record['blocks']*4
    assert set(record['summary'])==set(CASES)
    for case,iterations in CASES.items():
        all_outputs=[]
        for block in range(record['blocks']):
            selected=[r for r in rows if r['case']==case and r['block']==block]
            assert [(r['slot'],r['side']) for r in selected]==list(enumerate(['baseline','candidate','candidate','baseline']))
            for row in selected:
                assert row['full_checked'] is True
                assert math.isfinite(row['wall_seconds']) and row['wall_seconds']>0
                result=json.loads(row['stdout'])
                assert result['case']==case and result['iterations']==iterations
                assert decode(result['result'])==expected[case]
                all_outputs.append(row['stdout'])
        assert len(set(all_outputs))==1
    assert summarize(rows)==record['summary']


def main():
    measurements=ROOT/'docs/measurements'
    raw=measurements/(PREFIX+'.json.gz')
    summary=json.loads((measurements/(PREFIX+'-summary.json')).read_text())
    compressed=raw.read_bytes();payload=gzip.decompress(compressed)
    assert sha(compressed)==summary['compressed_sha256']
    assert sha(payload)==summary['uncompressed_sha256']
    record=json.loads(payload)
    validate(record,expected_outputs())
    assert summary['summary']==record['summary'] and summary['processes']==len(record['rows'])
    assert sha((measurements/(PREFIX+'-harness.py')).read_bytes())==record['script_sha256']
    for side in ['baseline','candidate']:
        source=record['provenance'][side]
        archive_path=PurePosixPath(source['archive'])
        assert not archive_path.is_absolute() and '..' not in archive_path.parts
        archive=(ROOT/source['archive']).read_bytes()
        assert sha(archive)==source['archive_sha256']
        with tarfile.open(fileobj=io.BytesIO(archive),mode='r:gz') as tar:
            files=tar.getmembers()
            assert len(files)==len(source['files'])
            assert {m.name for m in files}==set(source['files'])
            for member in files:
                assert member.isfile() and not PurePosixPath(member.name).is_absolute() and '..' not in PurePosixPath(member.name).parts
                assert sha(tar.extractfile(member).read())==source['files'][member.name]
    before=record['provenance']['baseline']['files'];after=record['provenance']['candidate']['files']
    changed=sorted(p for p in before.keys()|after.keys() if before.get(p)!=after.get(p))
    assert changed==record['provenance']['differing_dependency_files']
    assert changed and all(p.startswith('src/tensor/') for p in changed)
    print(f'Information evidence: {len(record["rows"])} complete native outputs, all slots, summaries and dependency archives verified.')


if __name__=='__main__':
    main()
