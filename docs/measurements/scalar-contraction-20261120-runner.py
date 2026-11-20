"""Fixed five-block ABBA comparison of checked public scalar contractions.
Run from the repository under tools/measure --cpu 4 after freezing both ELFs.
"""
from pathlib import Path
from fractions import Fraction
from datetime import datetime, timezone
import gzip, hashlib, json, os, platform, statistics, subprocess, sys, time
sys.path.insert(0, 'tools')
from compare_field_kernels import provenance, normalized
from benchmark_information import decode
from check_evidence import comparison
root=Path.cwd(); task=root/'.tools/scalar-contraction'
config=json.loads((task/'task.json').read_text())
artifacts={v:task/f'{v}.exe' for v in ['before','after']}
roots={'before':Path('/home/hosi/morph-contraction-before'),'after':root}
report=dict(utc=datetime.now(timezone.utc).isoformat(),platform=platform.platform(),affinity=sorted(os.sched_getaffinity(0)),groups=5,order=['before','after','after','before'],argument_prefix=['--contraction'],scope='Whole native release process via GNU time, including startup, one curvature construction, fixed repetitions, exact formula assertions and JSON serialization; excludes compilation. Peak RSS is per-process KiB, not allocation volume or isolated contraction live space.',runs=[],summary={},memory_summary={},all_checked=False)
for v in artifacts:
    report[v]=provenance(roots[v],artifacts[v],'src/cmd/information')
assert report['before']['harness']==report['after']['harness']
report['runner_sha256']=hashlib.sha256(Path(__file__).read_bytes()).hexdigest()
report['independent_oracle']='Categorical simplex has constant sectional curvature 1/4; dimension d gives scalar d(d-1)/4. Every timed repetition checks exact QQ equality; Python separately decodes the complete canonical rational JSON.'
for case,iterations in config['cases'].items():
    d={'scalar0':0,'scalar3':3,'scalar5':5,'cached5':5}[case]
    wanted=Fraction(d*(d-1),4)
    for group in range(5):
        for position,variant in enumerate(report['order']):
            rss=task/'rss.txt'
            argv=['/usr/bin/time','-f','%M','-o',str(rss),str(artifacts[variant]),'--contraction',case]
            start=time.perf_counter_ns();p=subprocess.run(argv,capture_output=True,text=True,timeout=120);elapsed=time.perf_counter_ns()-start
            payload=json.loads(p.stdout);normalized(payload)
            assert p.returncode==0 and not p.stderr and set(payload)=={'case','iterations','checked','result'}
            assert payload['case']==case and payload['iterations']==iterations and decode(payload['result'])==wanted
            report['runs'].append(dict(case=case,group=group,position=position,variant=variant,process_ns=elapsed,peak_rss_kib=int(rss.read_text()),payload=payload,stdout=p.stdout,stderr=p.stderr,exit_code=p.returncode,checked=True))
            (task/'running.json').write_text(json.dumps(report,indent=2)+'\n')
    rows=[r for r in report['runs'] if r['case']==case]
    for metric,destination in [('process_ns','summary'),('peak_rss_kib','memory_summary')]:
        by_side={s:[r[metric] for r in rows if r['variant']==s] for s in artifacts}
        medians={s:statistics.median(v) for s,v in by_side.items()}
        blocks=[]
        for group in range(5):
            b={s:statistics.median(r[metric] for r in rows if r['group']==group and r['variant']==s) for s in artifacts}
            blocks.append(b['before']/b['after'])
        entry=dict(medians=medians,ranges={s:[min(v),max(v)] for s,v in by_side.items()},before_over_after=medians['before']/medians['after'],block_ratios=blocks)
        report[destination][case]={'process_ns':entry} if metric=='process_ns' else entry
    print(case,report['summary'][case],report['memory_summary'][case],flush=True)
for v,p in report.items():
    if v in artifacts:
        assert hashlib.sha256(artifacts[v].read_bytes()).hexdigest()==p['artifact_sha256']
report['all_checked']=True
prefix=root/'docs/measurements/scalar-contraction-20261120'
raw=(json.dumps(report,indent=2)+'\n').encode();compressed=gzip.compress(raw,mtime=0)
Path(str(prefix)+'.json.gz').write_bytes(compressed)
summary={k:v for k,v in report.items() if k!='runs'}
summary.update(run_count=len(report['runs']),lossless_full_record=dict(path=str(Path(str(prefix)+'.json.gz').relative_to(root)),sha256=hashlib.sha256(compressed).hexdigest(),uncompressed_sha256=hashlib.sha256(raw).hexdigest()))
Path(str(prefix)+'.json').write_text(json.dumps(summary,indent=2)+'\n')
comparison(root,summary)
