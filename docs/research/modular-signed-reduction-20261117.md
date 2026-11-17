# signed_reduce: rejected known-residue negation trial

The trial was rejected and production bytes restored to `a63dcbc`. The frozen
negative-reduced case improved by 1.041× initially and 1.077× on repetition, with
all ten paired block ratios above one. The positive-control repetition was
0.909×, with all five paired block ratios below one. That adverse control cannot
be dismissed as noise. A small local gain does not justify this unresolved
tradeoff. No further source variant was tried.

## Mechanism and protected behavior

Baseline `a63dcbca9a07a5c875400c4305bf2b15585b3aa3` first computes
`r = reduce(m, magnitude(a))`. For a negative integer it calls generic
`subtract(m, zero(), r)`, which reduces both operands again, attempts `0-r`,
then computes `(0+m)-r` for nonzero r. Trial
`d926e01c86f044c956e5b1f9509a349ac167d087` changed only that negative branch:
return r when zero, otherwise use `binary.subtract(m.value,r)` with the existing
zero fallback. For a public Modulus, 0<=r<m establishes the same canonical result.
Unreduced public inputs still pass through the original reduction once.

Public subtract/reduce/extended_gcd/inverse and all checkers remained byte-identical
during the trial. There was no new API, helper, machine arithmetic, array or mutable
state in production. The positive branch was semantically unchanged; this fact
alone does not invalidate its measured adverse result. Full candidate source and
the [minimal rejected patch](modular-signed-reduction-20261117-raw/rejected-trial.patch.gz)
are retained as evidence. Restoration commit `547cbb2` restored the whole modular
source file, with [zero production diff/API/purity proof](modular-signed-reduction-20261117-raw/restoration-proof.json).

## Frozen public workloads and checks

Harness commit `65a3e52` introduced `src/cmd/conversionmodularbench`; its main/pkg
bytes were identical on both sides and did not change after the first build.
There are six cases: negative reduced residues (8000 iterations), negative
unreduced magnitudes including 256/512-bit values (600), zero/tiny/multiple and
public invalid-modulus boundaries (5000), positive reduced inputs (8000), direct
modular inverse plus the actual odd-prime `primefield.arithmetic.inverse` caller
and composite inverse failures (300), and a 1024-bit one-shot input with a
255-bit modulus (one timed iteration).

Every iteration compares the complete canonical Binary/Option arrays against
independent Python integer `%` / `pow(a,-1,m)` expectations and serializes every
result. There is no checksum-only validation. Each process has one checked warm-up
operation before the stated timed iterations; therefore one-shot executes a
warm-up and one timed operation. Field/modulus/input preparation is outside the
inner interval and inside whole-process timing. The inverse case measures a
combined direct/field/composite workload, not a whole Fp polynomial algorithm.

The retained WB tests compare 33,475 signed integer cases (m=0..64,
a=-257..257) with host machine integer arithmetic and the exact old signed_reduce
logic, plus 13 full Python bigint fixtures. Public Modulus rejects 0 and 1;
those two internal WB modulus values are defensive test strengthening, not
reachable public inputs or an API extension. The legacy oracle shares unchanged
reduce/subtract with the candidate and is not a whole-program independent oracle;
the host/Python arithmetic provides separate result evidence.
`tools/generate_signed_residue_n04.py --check` checks the Python fixture JSON and
its numerical/sign binding to the WB payload, independently of formatter layout.
It does not regenerate or approve arbitrary WB test control flow.

## Measurements

Native release, CPU4 shared `tools/measure` lock, one build job, separate build
trees; compilation excluded. Five ABBA blocks per case. Both ELF/source manifests
were frozen before comparison. Ratios are baseline/candidate, so values below one
are adverse. Process times include startup, setup, warm-up, full checks and
serialization. Inner elapsed_us values and every individual duration remain in the
linked summaries and lossless full runs; block ranges are not confidence bounds.

| Case | Initial before/after ms | Initial ratio (five-block range) | Repeat before/after ms | Repeat ratio (five-block range) |
| --- | ---: | ---: | ---: | ---: |
| negative-reduced | 28.924 / 27.773 | 1.041× (1.014–1.095) | 27.451 / 25.498 | 1.077× (1.021–1.138) |
| negative-unreduced | 99.280 / 97.334 | 1.020× (0.974–1.112) | 98.614 / 98.560 | 1.001× (0.969–1.017) |
| zero-tiny-boundaries | 10.124 / 9.854 | 1.027× (0.937–1.057) | 10.171 / 9.798 | 1.038× (0.878–1.125) |
| positive-control | 7.217 / 7.322 | 0.986× (0.613–1.139) | 6.930 / 7.623 | 0.909× (0.677–0.998) |
| inverse-field | 15.867 / 15.482 | 1.025× (0.893–1.111) | 15.316 / 15.005 | 1.021× (1.002–1.107) |
| one-shot | 1.291 / 1.370 | 0.942× (0.891–1.212) | 1.366 / 1.307 | 1.045× (0.996–1.546) |

The negative-unreduced and zero/tiny results remain small and inconsistent. The
inverse repetition had all five ratios above one, but its initial blocks included
negative values. One-shot changed from 0.942× to 1.045×. No generic inverse,
unreduced-input or whole-application speedup is established.

A same-before-ELF A/A control used the frozen negative-reduced, positive-control
and one-shot cases: process ratios were 0.991×, 1.051× and 0.936× respectively.
This demonstrates variation in this measurement, without explaining away the
candidate's positive-control result. All negative values are preserved. Exactly
one frozen repetition plus this A/A diagnostic was run; no code correction or
workload/count retuning followed the first comparison.

## Evidence, validation and handoff

All 300 measured process outputs passed full comparisons: 120 initial, 120 repeat,
60 A/A. Complete stdout/stderr, exit codes, every raw value and provenance are in
[initial runs](modular-signed-reduction-20261117-raw/initial-abba.json.gz),
[repeat runs](modular-signed-reduction-20261117-raw/frozen-repeat-abba.json.gz), and
[A/A runs](modular-signed-reduction-20261117-raw/before-aa-control.json.gz).
Their readable `*-summary.json` companions retain all statistics, block ratios,
full outputs and compressed/uncompressed SHA256 values. Lossless decompression
was verified before redundant plain JSON removal.

The trial's initial native correctness passed 13 tests. After restoration,
modular+primefield passed **13 tests on each of native, JS and wasm-gc**. Scoped
format/API/purity checks and the independent fixture guard passed. No generated
API diff exists for modular or primefield. Logs and hashes are in
[validation.json](modular-signed-reduction-20261117-raw/validation.json).
Root owns broader global validation and integration.

Versioned artifacts for root archival before cleanup are in the candidate tree:
`.tools/modular-signed-reduction-20261117/{before.exe,after-initial.exe,before.c.gz,after-initial.c.gz}`.
The after artifact is the rejected trial, not the restored current source.
[Before](modular-signed-reduction-20261117-raw/before-snapshot.json) and
[trial](modular-signed-reduction-20261117-raw/after-initial-snapshot.json) snapshots
retain exact per-file and aggregate source hashes, compiler, ELF hash and commits;
[generated C metadata](modular-signed-reduction-20261117-raw/generated-c-artifacts.json)
retains compressed/uncompressed hashes for both native generated sources.

Root already integrated the harness. The standalone
[retained tests patch](modular-signed-reduction-20261117-raw/retained-tests.patch.gz)
is relative to harness commit 65a3e52 and contains only the new WB file and unique
fixture guard update. Apply that support patch and this evidence commit without
cherry-picking the rejected production trial or restoration commit. Production
bytes stay unchanged. No push, shared index edit, shared tools/check edit, new
worktree creation or worktree cleanup was performed by this worker.

To reproduce the initial comparison, run under CPU4:

```sh
tools/measure --cpu 4 python3 tools/compare_field_kernels.py \
  --before .tools/modular-signed-reduction-20261117/before.exe \
  --after .tools/modular-signed-reduction-20261117/after-initial.exe \
  --before-root /home/hosi/morph-conversion-modular-before \
  --after-root /home/hosi/morph-conversion-modular \
  --harness src/cmd/conversionmodularbench \
  --case negative-reduced --case negative-unreduced --case zero-tiny-boundaries \
  --case positive-control --case inverse-field --case one-shot --groups 5 \
  --output initial-abba.json
```

The current candidate source is restored; use the recorded rejected commit/source
snapshot if rebuilding the trial. Frozen binaries preserve the measured program.
