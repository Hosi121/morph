#!/usr/bin/env python3
"""Run the checked probability/geometry tour and compare its complete output."""
from pathlib import Path
import argparse
import subprocess
import sys

ROOT = Path(__file__).resolve().parent.parent
SNAPSHOT = ROOT / 'docs/INFORMATION_TOUR.txt'


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--target', choices=['wasm-gc','js','native'], default='wasm-gc')
    parser.add_argument('--update', action='store_true')
    args = parser.parse_args()
    completed = subprocess.run([str(ROOT/'tools/moon'), 'run', 'src/cmd/information',
                                '--target', args.target, '--release', '-j','1'],
                               cwd=ROOT, text=True, capture_output=True)
    if completed.returncode:
        sys.stderr.write(completed.stderr)
        return completed.returncode
    if args.update:
        SNAPSHOT.write_text(completed.stdout)
        print('Updated', SNAPSHOT.relative_to(ROOT))
    elif not SNAPSHOT.exists() or SNAPSHOT.read_text() != completed.stdout:
        print('Information tour output differs from the committed complete snapshot.', file=sys.stderr)
        print(completed.stdout, file=sys.stderr)
        return 1
    else:
        print(f'Information tour: {args.target} complete output matches.')
    return 0


if __name__ == '__main__':
    sys.exit(main())
