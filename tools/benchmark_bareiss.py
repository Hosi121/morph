#!/usr/bin/env python3
"""Paired frozen-reference/Bareiss cohort runs; invoke under shared CPU10 lock."""
import argparse,datetime,hashlib,json,re,statistics,subprocess,time
from pathlib import Path
from check_model_drift import function_tokens

ROOT=Path(__file__).resolve().parent.parent
ART=ROOT/'.tools/bareiss-20261116'
COHORTS=['small','integer6','integer8','rational6','rational8','singular8','pivot8','earlyzero8']
UNITS={'ns':1e-9,'µs':1e-6,'μs':1e-6,'us':1e-6,'ms':1e-3,'s':1}


def check_reference():
 lock=json.loads((ROOT/'docs/measurements/bareiss-20261116-reference.json').read_text())
 assert lock['schema_version']==1,'unknown frozen-reference lock schema'
 reference=ROOT/lock['sources']['wb_reference']
 rref=ROOT/lock['sources']['rref_dependency']
 def body(name):return function_tokens(reference,name).split(b'{',1)[1]
 actual={
  'arithmetic_body':hashlib.sha256(body('bareiss_reference_arithmetic')).hexdigest(),
  'normalized_determinant_body':hashlib.sha256(body('bareiss_reference_field_determinant').replace(b'@rowreduce.rref(',b'rref(')).hexdigest(),
  'rref_wholefile':hashlib.sha256(rref.read_bytes()).hexdigest(),
  'wrapper_body':hashlib.sha256(body('bareiss_frozen_reference')).hexdigest(),
 }
 assert actual==lock['sha256'],'frozen Bareiss reference drift; review before updating its lock'
 return dict(provenance=lock['provenance'],sha256=actual,reference_source_sha256=hashlib.sha256(reference.read_bytes()).hexdigest())


def parse(output):
 rows={}
 pattern=r'^(reference|Bareiss)_([a-z0-9]+)\s+([0-9.]+)\s+(ns|µs|μs|us|ms|s)\s+±\s+([0-9.]+)\s+(ns|µs|μs|us|ms|s)'
 for line in output.splitlines():
  match=re.match(pattern,line)
  if match:
   algorithm,cohort,mean,unit,sd,sdunit=match.groups()
   rows[algorithm+'_'+cohort]=dict(mean_seconds=float(mean)*UNITS[unit],stddev_seconds=float(sd)*UNITS[sdunit],raw=line)
 assert set(rows)=={algorithm+'_'+cohort for algorithm in ['reference','Bareiss'] for cohort in COHORTS},output
 assert 'Total tests: 16, passed: 16, failed: 0.' in output,output
 return rows


def preserve(target):
 folder=ROOT/'_build'/target/'release/bench/bareiss';manifest=[]
 for path in sorted(folder.glob('*')):
  if path.is_file() and path.suffix in ['.exe','.c','.js','.wasm','.json']:
   data=path.read_bytes();destination=ART/'executables'/target/path.name
   destination.parent.mkdir(parents=True,exist_ok=True);destination.write_bytes(data)
   manifest.append(dict(path=str(path.relative_to(ROOT)),copy=str(destination.relative_to(ROOT)),sha256=hashlib.sha256(data).hexdigest(),bytes=len(data)))
 assert any('whitebox_test' in row['path'] and row['path'].endswith(('.exe','.js','.wasm')) for row in manifest),manifest
 return manifest


def main():
 parser=argparse.ArgumentParser(description=__doc__)
 parser.add_argument('--check-reference-only',action='store_true',help='verify the frozen baseline without running benchmarks or requiring Git history')
 args=parser.parse_args()
 ART.mkdir(parents=True,exist_ok=True)
 (ART/'frozen-reference.json').write_text(json.dumps(check_reference(),indent=2)+'\n')
 if args.check_reference_only:
  print('Bareiss frozen reference matches its reviewed lock; no Git history or benchmark run needed.')
  return
 frozen={}
 for folder in ['src/bareiss','src/linear','src/rowreduce','src/berkowitz']:
  for path in sorted((ROOT/folder).glob('*')):
   if path.is_file():frozen[str(path.relative_to(ROOT))]=hashlib.sha256(path.read_bytes()).hexdigest()
 (ART/'benchmark-source.json').write_text(json.dumps(frozen,indent=2)+'\n')
 records=[];artifacts={}
 for target in ['native','js','wasm-gc']:
  artifact_hash=None
  for iteration in range(2):
   log=ART/f'bench-{target}-{iteration}.log'
   command=['tools/moon','bench','src/bareiss','--target',target,'--release','--no-parallelize','--verbose']
   began=time.perf_counter()
   result=subprocess.run(command,cwd=ROOT,text=True,stdout=subprocess.PIPE,stderr=subprocess.STDOUT)
   output=result.stdout;returncode=result.returncode;log.write_text(output)
   assert returncode==0,output
   measurements=parse(output)
   manifest=preserve(target)
   current={row['path']:row['sha256'] for row in manifest if row['path'].endswith(('.exe','.js','.wasm'))}
   if artifact_hash is not None:assert current==artifact_hash,'benchmark artifact changed between repetitions'
   artifact_hash=current;artifacts[target]=manifest
   record=dict(target=target,iteration=iteration,command=command,command_wall_seconds=time.perf_counter()-began,completed_utc=datetime.datetime.now(datetime.timezone.utc).isoformat(),log=str(log.relative_to(ROOT)),measurements=measurements,artifact_sha256=current)
   records.append(record);(ART/'benchmark-runs.json').write_text(json.dumps(records,indent=2)+'\n')
   (ART/'benchmark-artifacts.json').write_text(json.dumps(artifacts,indent=2)+'\n')
   print(target,iteration,'complete; paired cohort speedups:',{cohort:round(measurements['reference_'+cohort]['mean_seconds']/measurements['Bareiss_'+cohort]['mean_seconds'],3) for cohort in COHORTS},flush=True)
 summary=[]
 for target in ['native','js','wasm-gc']:
  runs=[record for record in records if record['target']==target]
  for cohort in COHORTS:
   reference=[run['measurements']['reference_'+cohort]['mean_seconds'] for run in runs]
   candidate=[run['measurements']['Bareiss_'+cohort]['mean_seconds'] for run in runs]
   summary.append(dict(target=target,cohort=cohort,reference_median_seconds=statistics.median(reference),candidate_median_seconds=statistics.median(candidate),speedup=statistics.median(reference)/statistics.median(candidate),conservative_speedup=min(reference)/max(candidate)))
 for name,expected in frozen.items():assert hashlib.sha256((ROOT/name).read_bytes()).hexdigest()==expected,'source changed: '+name
 (ART/'benchmark-summary.json').write_text(json.dumps(summary,indent=2)+'\n')
 print(json.dumps(summary,indent=2),flush=True)


if __name__=='__main__':main()
