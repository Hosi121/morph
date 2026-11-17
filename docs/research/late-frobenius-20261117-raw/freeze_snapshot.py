"""Freeze one prebuilt ELF and record all source hashes without altering libraries."""
from pathlib import Path
from hashlib import sha256
from argparse import ArgumentParser
import json
import shutil
import subprocess
parser=ArgumentParser()
parser.add_argument('label')
parser.add_argument('root',type=Path)
parser.add_argument('artifact',type=Path)
args=parser.parse_args()
root=args.root.resolve()
output=Path(__file__).resolve().parent
archive=output.parents[2]/'.tools'/'late-frobenius-20261117'
archive.mkdir(parents=True,exist_ok=True)
artifact=archive/(args.label+'.exe')
shutil.copyfile(args.artifact,artifact)
artifact.chmod(0o755)
def git(*args):return subprocess.check_output(['git','-C',str(root),*args],text=True).strip()
paths=sorted([root/'moon.mod',root/'tools/moon']+list((root/'src').rglob('*.mbt'))+list((root/'src').rglob('moon.pkg')))
manifest={str(p.relative_to(root)):sha256(p.read_bytes()).hexdigest() for p in paths}
library_manifest={p:h for p,h in manifest.items() if p.startswith('src/') and not p.startswith('src/cmd/')}
data=dict(root=str(root),commit=git('rev-parse','HEAD'),status=git('status','--short').splitlines(),artifact=str(artifact),artifact_sha256=sha256(artifact.read_bytes()).hexdigest(),sources=manifest,library_sources=library_manifest,compiler=subprocess.check_output([str(root/'tools/moon'),'version','--all'],text=True))
if args.label=='before':
 diff=git('diff','a39f3234da50eb86e19d58583d5db5c2c99b62c1','--','src',':!src/cmd')
 assert not diff,'baseline tracked libraries changed'
 data['baseline_tracked_library_diff']=''
(output/(args.label+'-snapshot.json')).write_text(json.dumps(data,indent=2)+'\n')
print(args.label,artifact,data['artifact_sha256'],len(manifest),'source files')
