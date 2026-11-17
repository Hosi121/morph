# Number-field kernels, 2026-11-17

This bounded experiment evaluates two mechanisms against public baseline
`2e33ef5612940efa555c0a3380a0bb34190cd159` under the frozen algorithm-kernel
contract. Work base `93878f2` only exposes the old coordinate body as an additive
public API. The benchmark never calls that new API, so its source also builds on
the original baseline. No certificate checker is changed.

## Canonical add/subtract

`Element` is opaque. The constructor audit found every construction in
`src/numberfield/field.mbt`: `element` checks one variable and reduces modulo the
checked modulus, `rational` constructs a constant, and `negate` preserves degree.
Other APIs, including inverse, reconstruct through these functions. The checked
field has positive degree. Polynomial add/subtract preserve descending unique
terms and remove zero coefficients. Thus their output already has degree below
the modulus; no division is necessary. Multiplication still reduces. The full
root certificate equality, including selected-root interval, is retained before
both add/subtract.

The new finite test compares 75 rational polynomial pairs across degrees 1, 2,
and 4 with a machine-integer fraction oracle and the legacy reduction path. It
also covers cancellation, zero identities, high-degree constructor reduction,
and distinct/refined embeddings with the same modulus. Multiplication reduction
is checked separately.

## Coordinate scan

`Polynomial` guarantees lex-descending unique terms, no zeros, and matching
exponent-vector dimension. The univariate canonical residue additionally has
exponents below the checked field degree. `coordinates` now advances a term
cursor from the highest basis exponent while prepending coefficients and zeros;
this returns the same ascending, exactly degree-sized vector. It avoids the
old complete term scan and rational addition for every coordinate. Peano
exponent comparisons still have their own cost; this is not a claim of flat
machine-integer linear complexity. CF coordinates and each NF multiplication
matrix column reuse the NF conversion. The private `coefficient` signature and
body remain available unchanged for the incremental worker and evaluation.

New tests cover 15 zero/sparse/dense/high-degree inputs in ambient dimensions
1, 2, and 4, comparing the vectors and complete multiplication matrices with
independent dense machine-integer monic long division. They also compare the
frozen old coordinate fold, fractional vectors, complex basis concatenation,
roundtrip reconstruction, and wrong-dimension rejection.

## Frozen measurement contract

Harness commit: `a2b3655`; public calls: NF add/subtract, NF multiply, CF
coordinates, NF multiplication matrix, and CF square followed by coordinates.
Eight fixed cases cover degree-one zero/control, quartic sparse/dense vectors,
the coordinate consumer, unaffected multiply, and a joint complex consumer.
The quartic modulus is `t^4-10*t^2+1`, selected in `(3,4]`. Expected products and
matrix columns come from independent dense machine-integer schoolbook products
and monic long division, using `t^4=10*t^2-1`. Every repeated result is compared
in full; printed expected arrays disclose the full outputs.

Native release builds and all tests run under `tools/measure --cpu 4`, with the
shared worktree flock and `-j 1`. Five ABBA blocks use independent processes and
identical frozen harness sources. Whole-process timing includes startup, input
normalization, irreducibility/embedding verification, setup, operation, and all
output checks. The inner interval includes operation plus full output checks;
setup and one checked warmup are outside that interval. The two intervals must
not be interchanged. Raw JSON retains every sample, full output, source/exe/
harness hashes, compiler, CPU affinity, ranges, and block ratios. No universal
speed claim follows from these selected small exact-arithmetic cases.

## Validation and results

Both mechanisms are **adopted** for their directly measured paths. The pass ends
here; no additional optimization or parameter search was performed. Each of the
three comparisons contains five independent ABBA blocks for each of eight cases,
160 full-output checks per comparison (480 total), all successful. Ratios below
are before/after, so values above one favor the candidate. The three columns are
separate comparisons; their ratios must not be multiplied or their savings added.

Native release on Intel Core Ultra 7 255H (Microsoft/WSL virtualized Linux), CPU
4 affinity. Compiler: moonc v0.10.20+65efd5b93, moon 0.1.20261104. The raw reports
contain the complete compiler strings and machine platform.

| Case | A1 vs original | A2 vs A1 | Combined vs original | Original median ms | Combined median ms |
| --- | ---: | ---: | ---: | ---: | ---: |
| addsub-d4 | 1.264x | 0.992x | 1.274x | 96.418 | 75.687 |
| addsub-d1 | 1.447x | 0.988x | 1.456x | 643.906 | 442.264 |
| coords-sparse-d4 | 0.975x | 2.939x | 2.897x | 205.495 | 70.931 |
| coords-dense-d4 | 1.019x | 4.388x | 4.263x | 224.745 | 52.716 |
| coords-zero-d1 | 0.980x | 2.398x | 2.595x | 70.957 | 27.340 |
| matrix-d4 | 0.979x | 1.222x | 1.176x | 40.640 | 34.560 |
| multiply-control-d4 | 0.986x | 1.014x | 0.989x | 50.900 | 51.481 |
| complex-square-d4 | 1.036x | 1.011x | 1.055x | 89.239 | 84.558 |

A1 improves both targeted add/sub cases in every block. A2 improves sparse and
dense coordinate extraction, the zero/dimension-one boundary, and the matrix
consumer in every block. In the final comparison, the matrix's block ratios
range from 1.100 to 1.298. The complex-square upper consumer is only 1.055x by
process medians, with block ratios 0.997–1.106; this small upper effect is less
certain than the targeted gains. The unchanged multiplication control is
0.989x in the final comparison (about 1.1% slower), with mixed block ratios
0.944–1.039. This does not establish absence of small regressions. No extra
follow-up was needed for the two clear mechanism decisions; ambiguous upper and
control results remain reported as such. No certificate cost was removed.

The inner interval gives final ratios 1.294x/1.458x for add/sub, 2.964x/4.437x
for sparse/dense coordinates, 2.691x for the degree-one zero, 1.197x for the
matrix, 0.985x for multiply, and 1.066x for complex square. These exclude setup;
whole-process values above retain it. No memory claim or speed claim for other
field degrees, certificate distributions, hardware, or application totals is made.

| Source stage | Commit | Source manifest SHA-256 | Native executable SHA-256 |
| --- | --- | --- | --- |
| Original public baseline (A1 run) | `2e33ef5612940efa555c0a3380a0bb34190cd159` | `a92906353cdcd22c8103d6c27d1e8da3f75f8e1e77b3e37bad739d6980ace2ed` | `ca8e0279a10c583306fcc8c123cb33a48efd046830ffc54e3feebcf51bf863f4` |
| Original public baseline (final run) | `2e33ef5612940efa555c0a3380a0bb34190cd159` | `6e0ba7635dce0c061cea0fb519d48f8e575a8aa818c79b694746aebd18695401` | `ca8e0279a10c583306fcc8c123cb33a48efd046830ffc54e3feebcf51bf863f4` |
| A1 canonical add/sub | `48847aa5febd972329f4a4f6512e8c88633f8ac1` | `cc851ceffe5e52aac23093afde76b67f450c776f678dfc45a8adbb912781cab1` | `9622010031028d49d809ba5368eb7eef1cc076395e2a6a4312b15351da8cd7b1` |
| A1+A2 coordinate scan | `a1c3f3c14b49b030be07bf8a248d2059106f7430` | `91ca72757bf71c3d19e1bfb3465671bbe30d10a5640d6fa5173b0bdba9cff3b7` | `d286c1b4e7c425e24398236e745993db7af7c11aef6060094fa9e9d6831d8c54` |

The original baseline is `2e33ef5` with frozen CLIs copied as untracked additions.
Its global source manifest changed between first and final timing because the
root added another untracked CLI (`structuralbench`) alongside `nfkernelbench`
and `spanbench`. The baseline NF executable hash and frozen NF harness hashes
were identical, and both reports disclose the untracked paths; no tracked
baseline production change occurred. A1's saved ELF is
`.tools/nf-kernels-20261117/addsub.exe`; the combined ELF is
`.tools/nf-kernels-20261117/combined.exe`. Both remain for root archival. Source
manifests match between A1's after snapshot and A2's before snapshot, and between
A2's after snapshot and final combined after snapshot.

After A1, NF+CF passed 168/168 tests on each of wasm, JS and native; after A2,
170/170 passed on each. Global `moon check --target all --deny-warn -j 1` passed
after each mechanism (1,797 first-stage tasks, 234 incremental final-stage
tasks). The purity gate passed 326 production files each time. All heavy builds,
checks, tests and timings held the shared CPU4 lock; no builds overlapped timings.
The independent certificate checkers were unchanged and existing forging/context
rejection tests remained in the scoped suite.

Raw evidence: [A1](nf-kernels-20261117-addsub.json),
[A2 vs A1](nf-kernels-20261117-coordinate.json),
[combined vs original](nf-kernels-20261117-combined.json), and
[validation/cleanup receipt](nf-kernels-20261117-validation.json).

The detached A1 source snapshot at
`/home/hosi/morph-algo-numberfield/.tools/nf-stage1-source`, commit `48847aa`,
was used only to give the common comparison driver matching source provenance.
Its source manifest and saved ELF hash were verified against the initial raw
report. It was clean before removal; its artifacts remain in the saved paths
above. The primary worker worktree remains for root integration and archival;
this worker did not push or modify shared indexes.
