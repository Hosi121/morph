"""Verify structure-modeling reports against their frozen exact oracles."""
import hashlib
import importlib.util
import sys
import tarfile


KINDS = {'positive-form-gaussian-v1', 'hessian-derived-geometry-v1', 'exterior-structure-v1'}


def check_reference(root, record):
    from check_evidence import local, require

    def checked_file(name, expected):
        path = local(root, name)
        require(hashlib.sha256(path.read_bytes()).hexdigest() == expected,
                'Frozen reference/source hash mismatch: ' + name)
        return path

    for archive in record['source_archives'].values():
        path = checked_file(archive['path'], archive['sha256'])
        with tarfile.open(path, 'r:gz') as source:
            members = source.getmembers()
            require(len(members) == len({m.name for m in members}), 'Duplicate source member')
            require({m.name for m in members} == set(archive['files']), 'Source manifest differs')
            for member in members:
                require(member.isfile(), 'Non-file source member')
                local(root, member.name)
                require(hashlib.sha256(source.extractfile(member).read()).hexdigest()
                        == archive['files'][member.name], 'Source member hash mismatch')

    for name, sha in record.get('reference_files', {}).items():
        checked_file(name, sha)
    harness = checked_file(record['harness_path'], record['harness_sha256'])
    name = '_frozen_structure_' + record['schema_kind'].replace('-', '_')
    spec = importlib.util.spec_from_file_location(name, harness)
    oracle = importlib.util.module_from_spec(spec)
    sys.modules[name] = oracle
    try:
        spec.loader.exec_module(oracle)
        if record['schema_kind'] == 'hessian-derived-geometry-v1':
            stem = harness.name.removesuffix('-harness.py')
            references = {str(harness.parent / (stem + '-' + kind + '-reference.py'))
                          for kind in ('moments', 'curvature')}
            require(references == {str(local(root, p)) for p in record['reference_files']},
                    'Missing frozen geometry reference')
            expected = {case: oracle.expected(case, harness.parent) for case in oracle.CASES}
        else:
            expected = {case: oracle.expected(case) for case in oracle.CASES}
        require(expected == record['reference_payloads'], 'Independent reference payload differs')
        require({run['case'] for run in record['runs']} == set(expected), 'Reference cases differ')
        for run in record['runs']:
            require(run['payload'] == expected[run['case']], 'Independent reference result differs')
    finally:
        sys.modules.pop(name, None)
