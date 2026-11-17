"""Losslessly archive complete comparison runs with a readable summary and hashes."""
from pathlib import Path
from hashlib import sha256
import gzip,json,sys
path=Path(sys.argv[1]);raw=path.read_bytes();data=json.loads(raw)
assert data['all_checked'] and len(data['runs'])==4*data['groups']*len(data['summary'])
assert all(r['checked'] and r['exit_code']==0 for r in data['runs'])
compressed=gzip.compress(raw,mtime=0)
target=path.with_suffix(path.suffix+'.gz');target.write_bytes(compressed)
assert gzip.decompress(target.read_bytes())==raw
summary={k:v for k,v in data.items() if k!='runs'}
summary['run_count']=len(data['runs'])
summary['checked_outputs']={r['case']:{k:v for k,v in r['payload'].items() if k!='elapsed_us'} for r in data['runs']}
summary['archive']={'filename':target.name,'uncompressed_sha256':sha256(raw).hexdigest(),'compressed_sha256':sha256(compressed).hexdigest(),'uncompressed_bytes':len(raw),'compressed_bytes':len(compressed)}
path.with_name(path.stem+'-summary.json').write_text(json.dumps(summary,indent=2)+'\n')
path.unlink()
print(summary['archive'])
