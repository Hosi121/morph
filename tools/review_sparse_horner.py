#!/usr/bin/env python3
"""Review a frozen sparse-Horner candidate without writing its src directory.

Run under tools/measure --cpu 10. --record records reviewed source/model locks;
it does not prove translation. Ordinary runs reject any locked source drift.
"""
from __future__ import annotations
import argparse
import datetime
from fractions import Fraction as F
import hashlib
import json
from pathlib import Path
import random
import re
import shutil
import subprocess
import time

from check_model_drift import function_tokens

ROOT = Path(__file__).resolve().parent.parent
ARTIFACT = ROOT / '.tools/sparse-horner-review-20261116'
MODEL = ROOT / 'formal/reviews/SparseHorner.lean'
LOCK = ROOT / 'formal/reviews/sparse-horner-source-map.json'
REGIONS = {
    'src/polynomial/evaluation.mbt': ['univariate_power', 'univariate_horner', 'evaluate'],
    'src/polynomial/polynomial.mbt': ['compare_monomial', 'insert', 'polynomial', 'evaluate_generic'],
}


def sha(data): return hashlib.sha256(data).hexdigest()


def source_map(source):
    regions = {f'{path}::{name}': sha(function_tokens(source/path, name))
               for path, names in REGIONS.items() for name in names}
    old = subprocess.check_output(['git', '-C', str(source), 'show',
                                  '6934453:src/polynomial/polynomial.mbt'], text=True)
    generic = function_tokens(source/'src/polynomial/polynomial.mbt', 'evaluate_generic')
    # Compare the complete old evaluator, changing only name and visibility.
    old_file = ARTIFACT/'original-polynomial.mbt'
    old_file.parent.mkdir(parents=True, exist_ok=True)
    old_file.write_text(old)
    old_evaluate = function_tokens(old_file, 'evaluate')
    assert old_evaluate.replace(b'pubfnevaluate(', b'fnevaluate_generic(', 1) == generic, \
        'generic evaluator changed beyond its declaration'
    return dict(
        lean_version='4.19.0', model_sha256=sha(MODEL.read_bytes()),
        source_regions=regions,
        source_files={p: sha((source/p).read_bytes()) for p in REGIONS},
        generic_reference=dict(base='6934453', path='src/polynomial/polynomial.mbt',
                               function='evaluate', sha256=sha(old_evaluate)),
        correspondence={
            'power': 'univariate_power; bitsPower, optimizedPower; converter soundness is an explicit hypothesis',
            'scan': 'univariate_horner.scan; natural subtraction; singleton exponent vectors; weak descending invariant',
            'horner': 'univariate_horner initial Nil/Cons dispatch after valid singleton shape',
            'genericSum': 'evaluate_generic final fold_left; univariate term coefficient times power',
            'dispatch': 'evaluate; only variables=1 and exactly one value select Horner; malformed terms fall back',
            'precondition': 'Polynomial is opaque externally; polynomial/insert canonicalize lex descending',
        })


def oracle(variables, terms, values):
    if len(values) != variables: return None
    out = F(0)
    for coefficient, exponents in terms:
        assert len(exponents) == variables
        product = coefficient
        for value, exponent in zip(values, exponents): product *= value**exponent
        out += product
    return out


def fixtures():
    out = []
    def add(name, n, terms, values):
        out.append((name, n, terms, values, oracle(n, terms, values)))
    # Public constructor sees deliberately unsorted terms, zeros and duplicates.
    seeds = [[], [(F(7,11),(0,))], [(F(-3,7),(1,))],
             [(F(2,3),(0,)),(F(-5,13),(31,)),(F(7,11),(2,))],
             [(F(4,9),(9,)),(F(-4,9),(9,)),(F(0),(27,))],
             [(F(1,7),(5,)),(F(-2,11),(5,)),(F(3,13),(0,)),(F(4,17),(1,))]]
    for i, terms in enumerate(seeds):
        for x in map(F, [0,1,-1,F(-2,3),F(3,5)]): add(f'boundary_{i}_{x}',1,terms,[x])
    for e in [127,128,129,255,256,257,1023,1024,1025,4096]:
        terms=[(F(-7,19),(e,)),(F(5,23),(e//2,)),(F(-3,29),(0,))]
        for x in map(F,[0,1,-1]):add(f'large_gap_{e}_{x}',1,terms,[x])
    rng=random.Random(0x5A175E)
    for i in range(72):
        count=rng.randrange(1,9)
        terms=[(F(rng.randrange(-9,10),rng.choice([3,5,7,11,13,17])),
                (rng.randrange(0,65),)) for _ in range(count)]
        rng.shuffle(terms)
        x=F(rng.choice([-3,-2,-1,0,1,2,3]),rng.choice([1,2,3,5]))
        add(f'random_QQ_{i}',1,terms,[x])
    for n in [0,2,3]:
        for i in range(12):
            terms=[(F(rng.randrange(-5,6),rng.choice([3,7,11])),
                    tuple(rng.randrange(0,5) for _ in range(n))) for _ in range(5)]
            values=[F(rng.choice([-2,-1,0,1,2]),rng.choice([1,2,3])) for _ in range(n)]
            add(f'multivariate_{n}_{i}',n,terms,values)
    for n in [0,1,2,3]:
        terms=[(F(2,7),tuple([1]*n))]
        for count in range(0,5):
            if count != n:add(f'wrong_arity_{n}_{count}',n,terms,[F(2,3)]*count)
    return out


def rat(q):
    q=F(q)
    return f'horner_review_rat({str(q<0).lower()}, "{abs(q.numerator):x}", "{q.denominator:x}")'


HELPERS = '''///|
fn horner_review_rat(negative : Bool, numerator : String, denominator : String) -> @exact.Rational {
  let n = @exact.positive(@oracle.binary_from_hex(numerator))
  @exact.ratio(if negative { @exact.negate(n) } else { n }, @oracle.binary_from_hex(denominator)).unwrap()
}

///|
fn horner_review_terms(values : Array[(@exact.Rational, Array[Int32])]) -> @core.Chain[Term] {
  @oracle.chain(values.map(fn(entry) { Term::{coefficient:entry.0,exponents:@oracle.chain(entry.1.map(@oracle.nat))} }))
}
'''


BOUNDARIES = '''
///|
test "independent sparse Horner raw weak-descending and malformed boundaries" {
  let x = @oracle.rational(-2, 3)
  let raw = horner_review_terms([
    (@oracle.rational(3,7), [5]),
    (@oracle.rational(0,1), [5]),
    (@oracle.rational(-2,11), [5]),
    (@oracle.rational(4,13), [0]),
  ])
  let forged : Polynomial = { variables:@oracle.nat(1), terms:raw }
  assert_eq(univariate_horner(raw,x),evaluate_generic(forged,@core.Cons(x,@core.Nil)))
  assert_eq(univariate_horner(@core.Nil,x),Some(@exact.rational_zero()))
  for exponent in [0,1,2,3,31,32,33] {
    let p = polynomial(@oracle.nat(1),horner_review_terms([(@exact.rational_one(),[exponent])])).unwrap()
    assert_eq(Some(univariate_power(x,@oracle.nat(exponent))),evaluate_generic(p,@core.Cons(x,@core.Nil)))
  }
  for exponents in [[],[1,2]] {
    let bad = horner_review_terms([(@oracle.rational(7,11),exponents)])
    let p : Polynomial = { variables:@oracle.nat(1), terms:bad }
    assert_eq(univariate_horner(bad,x),None)
    assert_eq(evaluate(p,@core.Cons(x,@core.Nil)),evaluate_generic(p,@core.Cons(x,@core.Nil)))
    assert_true(polynomial(@oracle.nat(1),bad) is Err(DimensionMismatch))
  }
  // Negative control: truncated subtraction cannot repair ascending exponents.
  let ascending = horner_review_terms([(@exact.rational_one(),[0]),(@exact.rational_one(),[1])])
  let bad : Polynomial = { variables:@oracle.nat(1), terms:ascending }
  let two = @oracle.rational(2,1)
  assert_eq(univariate_horner(ascending,two),Some(@oracle.rational(4,1)))
  assert_eq(evaluate_generic(bad,@core.Cons(two,@core.Nil)),Some(@oracle.rational(3,1)))
  let normalized = polynomial(@oracle.nat(1),ascending).unwrap()
  assert_eq(evaluate(normalized,@core.Cons(two,@core.Nil)),Some(@oracle.rational(3,1)))
}
'''


def generate_tests(cases):
    lines=[HELPERS]
    for i,(name,n,terms,values,expected) in enumerate(cases):
        raw='['+', '.join('('+rat(c)+', '+str(list(e))+')' for c,e in terms)+']'
        value='@oracle.chain(['+', '.join(rat(v) for v in values)+'])'
        want='None' if expected is None else 'Some('+rat(expected)+')'
        lines.append(f'''///|
test "independent sparse Horner QQ {i} {name}" {{
  let p = polynomial(@oracle.nat({n}),horner_review_terms({raw})).unwrap()
  let values = {value}
  let expected = {want}
  assert_eq(evaluate(p,values),expected)
  assert_eq(evaluate_generic(p,values),expected)
}}
''')
    return '\n'.join(lines)+BOUNDARIES


def check_drift_control(source, expected):
    control=ARTIFACT/'drift-control'
    (control/'src/polynomial').mkdir(parents=True,exist_ok=True)
    for path in REGIONS:
        (control/path).write_bytes((source/path).read_bytes())
    candidate=control/'src/polynomial/evaluation.mbt'
    original=candidate.read_text()
    changed=original.replace('@core.subtract(degree, next)', 'next', 1)
    assert changed!=original,'negative-control mutation no longer maps to source'
    candidate.write_text(changed)
    mutated=source_map(control)
    assert mutated!=expected,'source drift control failed to detect altered gap'
    (ARTIFACT/'drift-control.json').write_text(json.dumps(dict(
        mutation='replace gap subtract(degree,next) by next in artifact copy',
        detected=True,
        changed_regions=[name for name in expected['source_regions']
                         if expected['source_regions'][name]!=mutated['source_regions'][name]]),indent=2)+'\n')


def run(command, label, cwd, records):
    began=time.perf_counter()
    result=subprocess.run(command,cwd=cwd,text=True,stdout=subprocess.PIPE,stderr=subprocess.STDOUT)
    elapsed=time.perf_counter()-began
    log=ARTIFACT/f'{label}.log';log.write_text(result.stdout)
    record=dict(command=command,cwd=str(cwd),returncode=result.returncode,
                elapsed_seconds=elapsed,log=str(log.relative_to(ROOT)),
                completed_utc=datetime.datetime.now(datetime.timezone.utc).isoformat())
    if 'test' in command:
        found=re.search(r'Total tests: (\d+), passed: (\d+), failed: (\d+)\.',result.stdout)
        assert found and int(found[1])==len(fixtures())+1,result.stdout
        record.update(total=int(found[1]),passed=int(found[2]),failed=int(found[3]))
    records.append(record)
    (ARTIFACT/'validation.json').write_text(json.dumps(records,indent=2)+'\n')
    print(label,f'rc={result.returncode} wall={elapsed:.3f}s',flush=True)
    print(result.stdout.rstrip(),flush=True)
    assert result.returncode==0,record
    if label=='lean':assert 'sorryAx' not in result.stdout,result.stdout


def main():
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--source-root',required=True,type=Path)
    parser.add_argument('--record',action='store_true')
    parser.add_argument('--lean',type=Path,default=ROOT/'.tools/lean/bin/lean')
    args=parser.parse_args();source=args.source_root.resolve()
    ARTIFACT.mkdir(parents=True,exist_ok=True)
    version=subprocess.check_output([str(args.lean),'--version'],text=True)
    assert version.startswith('Lean (version 4.19.0,'),version
    (ARTIFACT/'lean-version.log').write_text(version)
    current=source_map(source)
    if args.record:
        LOCK.write_text(json.dumps(current,indent=2,sort_keys=True)+'\n')
        print('Recorded reviewed source/model correspondence; not a translation proof.')
        return
    assert current==json.loads(LOCK.read_text()),'Sparse Horner source/model drift; review before recording a new lock.'
    check_drift_control(source,current)
    project=ARTIFACT/'harness'
    project.mkdir(exist_ok=True)
    (project/'moon.mod').write_text((source/'moon.mod').read_text())
    manifest={}
    for package in ['core','binary','exact','testsupport','polynomial']:
        destination=project/'src'/package
        if destination.exists():shutil.rmtree(destination)
        destination.mkdir(parents=True)
        for path in sorted((source/'src'/package).iterdir()):
            if path.name=='moon.pkg' or (path.suffix=='.mbt' and not path.name.endswith(('_test.mbt','_wbtest.mbt'))):
                data=path.read_bytes()
                # Benchmark source files are intentionally excluded. Remove only
                # their test-only import in this isolated harness's metadata.
                copied=data.replace(b'  "moonbitlang/core/bench",\n',b'') if path.name=='moon.pkg' else data
                (destination/path.name).write_bytes(copied)
                manifest[str(path.relative_to(source))]=sha(data)
    assert source_map(source)==current,'Source changed while copying.'
    (ARTIFACT/'copied-source.json').write_text(json.dumps(manifest,indent=2)+'\n')
    cases=fixtures()
    (project/'src/polynomial/independent_horner_review_wbtest.mbt').write_text(generate_tests(cases))
    records=[dict(name=name,variables=n,terms=[dict(coefficient=str(c),exponents=e) for c,e in terms],
                  values=list(map(str,values)),expected=None if expected is None else str(expected))
             for name,n,terms,values,expected in cases]
    (ARTIFACT/'fraction-fixtures.json').write_text(json.dumps(records,indent=2)+'\n')
    commands=[]
    run([str(args.lean),'-DwarningAsError=true',str(MODEL)],'lean',ROOT,commands)
    moon=str(ROOT/'tools/moon')
    run([moon,'fmt','src/polynomial'],'format-harness',project,commands)
    run([moon,'check','src/polynomial','--deny-warn'],'check-harness',project,commands)
    for target in ['native','js','wasm-gc']:
        run([moon,'test','src/polynomial','--target',target],f'test-{target}',project,commands)
    assert source_map(source)==current,'Source changed during validation; candidate must be re-reviewed.'
    print(f'Independent QQ fixtures: {len(cases)} plus one boundary test; source and model locks unchanged.')


if __name__=='__main__':main()
