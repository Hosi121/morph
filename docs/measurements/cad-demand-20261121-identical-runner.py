"""Compare frozen native CAD/SMT CLIs using five fixed ABBA blocks per case.
Run at the repository root under tools/measure --cpu 4. All 40 runs must
complete within 3 seconds with checked results. All non-timing output including proof-tree sizes and search transitions
must be identical. Both variants run the SAME baseline ELF. This diagnoses noise, not a source improvement.
"""
from pathlib import Path
from datetime import datetime,timezone
import hashlib,json,math,os,platform,statistics,subprocess,sys,time
sys.path.insert(0,'tools')
from compare_field_kernels import provenance
root=Path.cwd();folder=root/'.tools/cad-demand/control'
artifacts={s:root/'.tools/cad-demand/before.exe' for s in ['before','after']}
roots={'before':Path('/home/hosi/morph-demand-before'),'after':Path('/home/hosi/morph-demand-before')}
cases=[
 ('smt','retained','diagonal-sat3',True,False,False),
 ('cad','pruned','circle-sat2',True,False,False),
]
clocks=['preparation_us','search_us','verification_us','total_us']
report=dict(kind='identical-artifact-control',utc=datetime.now(timezone.utc).isoformat(),platform=platform.platform(),affinity=sorted(os.sched_getaffinity(0)),groups=5,order=['before','after','after','before'],timeout_seconds=3,scope='Whole native release process including startup, fixture construction, prepare, search, independent result checker invocation and output; excludes compilation. CLI clock intervals exclude fixture creation. One input per process.',case_specs=[dict(layer=l,mode=m,case=c,expected=expected,baseline_timeout_allowed=hard,may_change_tree=change) for l,m,c,expected,hard,change in cases],runs=[],summary={},status='running',runner_sha256=hashlib.sha256(Path(__file__).read_bytes()).hexdigest())
for s in artifacts:report[s]=provenance(roots[s],artifacts[s],'src/cmd/incrementalbench')
assert report['before']['harness']==report['after']['harness']
report['compiler_binary_sha256']={n:hashlib.sha256((root/'.tools/moon/bin'/n).read_bytes()).hexdigest() for n in ['moon','moonc','moonrun']}
report['oracle']='Diagonals: mandatory coordinate aliases and x^2=2 imply the final squared equality, contradicting its disequality. SAT counterpart has a sqrt(2) branch. Quadratic nullification: x=0,y=1 gives -1=0. Prefix x=0 makes xy-1=-1. Circle x^2+y^2=1 SAT. Every CLI exit checks its model or complete refutation against the original input.'
out=folder/'comparison.json'
def save():out.write_text(json.dumps(report,ensure_ascii=False,indent=2)+'\n')
for layer,mode,case,expected,hard,change in cases:
 key='/'.join([layer,mode,case]);fixed=None
 for group in range(5):
  for position,variant in enumerate(report['order']):
   argv=[str(artifacts[variant]),layer,mode,case];start=time.perf_counter_ns()
   try:
    p=subprocess.run(argv,capture_output=True,text=True,timeout=3);elapsed=time.perf_counter_ns()-start
    payload=json.loads(p.stdout)
    assert p.returncode==0 and not p.stderr and payload['layer']==layer and payload['mode']==mode and payload['case']==case
    assert payload['satisfiable'] is expected
    assert all(isinstance(payload[t],(int,float)) and math.isfinite(payload[t]) and payload[t]>=0 for t in clocks)
    normalized={k:v for k,v in payload.items() if k not in clocks}
    if not change:
     if fixed is None:fixed=normalized
     assert normalized==fixed,(key,variant)
    row=dict(key=key,group=group,position=position,variant=variant,argv=argv,process_ns=elapsed,censored=False,exit_code=p.returncode,payload=payload,stdout=p.stdout,stderr=p.stderr,checked=True)
   except subprocess.TimeoutExpired as e:
    assert hard and variant=='before',(key,variant)
    row=dict(key=key,group=group,position=position,variant=variant,argv=argv,process_ns=time.perf_counter_ns()-start,censored=True,exit_code=None,payload=None,stdout=(e.stdout or b'').decode() if isinstance(e.stdout,bytes) else (e.stdout or ''),stderr=(e.stderr or b'').decode() if isinstance(e.stderr,bytes) else (e.stderr or ''),checked=False)
   report['runs'].append(row);save()
 rows=[r for r in report['runs'] if r['key']==key];summary={}
 for side in artifacts:
  chosen=[r for r in rows if r['variant']==side];complete=[r for r in chosen if not r['censored']]
  summary[side]=dict(completed=len(complete),censored=len(chosen)-len(complete),medians_completed_only={t:statistics.median(r[t] if t=='process_ns' else r['payload'][t] for r in complete) for t in ['process_ns',*clocks]} if complete else None)
 if all(not r['censored'] for r in rows):
  summary['process_before_over_after']=summary['before']['medians_completed_only']['process_ns']/summary['after']['medians_completed_only']['process_ns'];ratios=[]
  for group in range(5):
   values={s:statistics.median(r['process_ns'] for r in rows if r['variant']==s and r['group']==group) for s in artifacts};ratios.append(values['before']/values['after'])
  summary['process_block_ratios']=ratios
 report['summary'][key]=summary;save();print(key,json.dumps(summary),flush=True)
for variant in artifacts:assert hashlib.sha256(artifacts[variant].read_bytes()).hexdigest()==report[variant]['artifact_sha256']
assert len(report['runs'])==len(cases)*20
report['status']='completed; all solver runs and result checks passed';save()

print("@@CAD_IDENTICAL_RECORD",flush=True)
print(json.dumps(report,ensure_ascii=False,indent=2),flush=True)
