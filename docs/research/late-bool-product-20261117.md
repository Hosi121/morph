# Boolean matrix product on the cohomology producer, 2026-11-17

Adopt producer commit `494b61d` for the consistent direct-product gains.
Whole-cohomology benefit remains unresolved. Baseline libraries are
`a39f3234da50eb86e19d58583d5db5c2c99b62c1`; the identical final benchmark is
`dad0115`, following initial harness `49a064a`. This was one algorithm trial,
no follow-up and no threshold search. The pre-comparison count calibration
changes repetition counts only, after all six smoke cases passed.

## Implementation and actual call path

The existing public `gf2.multiply` previously delegated to generic
`matrix.multiply`. It had no external producer caller, though the GF2
certificate checker already used it. It now calls a private fixed-Boolean
implementation: direct AND/XOR dot recursion, column peeling, row construction
and outer row construction have no scalar dictionary or function callbacks.
The arithmetic operation and ordering remain exact GF(2). Handwritten
production code uses immutable ADTs, pattern matching and recursion, with no
machine numerics, arrays, mutation, FFI, new public API or state/cache fields.

`cohomology.compute` now calls this existing API for the one
`incoming_coordinates = inverse_basis * previous` producer product. All
other cohomology source behavior, reduction/solve logic and package imports
are unchanged. No unused product API was added.

Dimension compatibility is checked before any special empty result could be
returned. Column recursion fixes result width to the right matrix's stored
width, and row recursion retains the left matrix's height. Empty 0×n,
zero-inner-dimension and zero-output-width products therefore preserve full
shape; mismatched dimensions return None even when an operand has no rows.

The result uses the public `matrix.matrix` constructor. Unlike the original
private generic `multiply_known`, this constructor validates all output row
lengths. That additional traversal/allocation cost is retained in every
measurement; no trusted constructor or validation bypass was introduced.

## Checker boundaries and changed dependency

Checker **bodies** are byte-identical, but that alone does not imply arithmetic
independence. The audited current call paths are:

| Site | Product implementation after this change |
| --- | --- |
| `gf2.check_certificate` | Calls public `gf2.multiply`, sharing the new arithmetic kernel |
| Direct identities in `cohomology.check_result` | Continue to call generic `matrix.multiply` |
| `csscode.check_rank`, reached by the cohomology checker | Continues to call generic `matrix.multiply` directly |
| `cohomology.compute` incoming-coordinate generation | Calls the specialized `gf2.multiply` |

The changed GF2 checker dependency is intentional and tested against a frozen
old-generic checker oracle, including forged witness/result fields. The
current CSS rank-check path has no call to `gf2.check_certificate` or public
`gf2.multiply`. No blanket claim is made that every checker is independent of
the producer's arithmetic. Exact source-region hashes and API byte checks
are retained in [validation.json](late-bool-product-20261117-raw/validation.json).

## Independent correctness and frozen timing

New white-box tests cover all 499 Boolean product pairs for dimensions 0..2,
20 larger sparse/dense/zero/rectangular fixtures, and explicit mismatches.
Every complete result matches both indexed host Boolean multiplication and
the unchanged generic matrix implementation, including stored widths and
empty rows. A frozen generic GF2 checker compares valid and forged
certificates/results against the shared-dependency checker.

A second oracle retains the old generic cohomology producer. Across six
complexes and degrees 0..3 it compares complete Group/Certificate results,
including the empty complex, a point, circle, filled triangle, tetrahedron and
torus. Existing rank/nullspace and certificate-rejection fixtures remain.

The public CLI has six process cases. The first bundles nine fixed tiny,
empty/zero-width and mismatch fixtures; its time is an aggregate, not separate
per-shape timings. The remaining direct cases use sparse, dense and all-zero
operands. Circle and seven-vertex torus degree-one cohomology provide actual
consumer controls. Host face deletion, indexed Boolean RREF/nullspace and
matrix inversion independently construct expected cohomology bases, inverse
bases, incoming coordinates and representatives. Every repeated result
compares all fields and invokes the original generic cohomology result check;
its internal completion checks also remain in the timed producer.

Whole-process time includes startup, fixtures/oracles, repeated operations,
full result comparisons, original certificate checking and serialization.
The identical harness is built native release in each source tree. All heavy
jobs use shared `tools/measure --cpu 4` locking, compiler `-j 1`, and separate
build trees; info uses no `-j`. Baseline copies/builds occur inside that lock
without changing tracked baseline library files. Five independent-process
ABBA blocks give ten observations per binary per case, 120 total. Every
observation passed complete output checking; no checksum replaces equality.

## Measured decision

Native release complete-process medians, milliseconds:

| Public case | Repetitions | Before | Specialized | Before / after | Favorable blocks |
| --- | ---: | ---: | ---: | ---: | ---: |
| Tiny/shape/mismatch bundle, 9 fixtures | 100,000 | 105.466 | 98.933 | 1.066 | 5/5 |
| Sparse 24×32 by 32×16 | 5,000 | 183.403 | 157.852 | 1.162 | 5/5 |
| Dense 24×32 by 32×24 | 5,000 | 305.715 | 245.840 | 1.244 | 5/5 |
| Zero 24×32 by dense 32×24 | 5,000 | 286.311 | 236.963 | 1.208 | 5/5 |
| Circle cohomology + full checks | 5,000 | 119.657 | 120.801 | 0.991 | 2/5 |
| Torus cohomology + full checks | 200 | 232.801 | 224.067 | 1.039 | 3/5 |

All five blocks favor the candidate in each direct-product case, including
the small/empty/error controls despite constructor validation. Adopt on those
measured public-API gains and the actual producer connection. The circle has
about 1% worse pooled median and the torus about 4% better pooled median, with
mixed block directions. Both whole-consumer effects are unresolved; these
numbers establish neither a cohomology speedup nor absence of regression.
The changed product's share of consumer time was not separately profiled.
No memory, machine-wide or universal-shape performance claim is made.

The initial calibration uses smaller direct-case counts and is setup evidence
only. After calibration, both roots were rebuilt from exact `dad0115` harness
bytes, which passed `fmt --check`; no inputs or counts changed during A/B.
All raw values, stdout/stderr, full matrix/certificate payloads, compiler,
affinity, source manifest and ELF/harness hashes are losslessly retained in
[product-abba.json.gz](late-bool-product-20261117-raw/product-abba.json.gz).
[summary.json](late-bool-product-20261117-raw/summary.json) keeps readable
medians/ranges/block ratios, while
[artifacts.json](late-bool-product-20261117-raw/artifacts.json) records original
and compressed SHA-256/byte counts, build commands and source/ELF hashes.
Gzip decompression was verified byte-for-byte before deleting the duplicate
uncompressed raw file.

## Verification and handoff

Native correctness ran before the initial comparison. The combined
GF2/cohomology scope passes 192/192 tests on each of native, JavaScript and
wasm-gc, release with warnings denied. Scoped fmt/check/info pass, regenerated public
metadata has no diff, and the three changed production files pass the scoped
purity scan. Producer/test source hashes are unchanged throughout final
verification. Solve and both checker regions are byte-unchanged. This worker
does not claim a new whole-repository regression/purity run; root owns broader
checks after integration.

Baseline/candidate native ELFs, exact source snapshots and full generated C
are handed to the root artifact archive, with hashes matching the measured
artifacts. This worker performs no main/shared-index edits, push, deployment
or worktree removal. Root owns integration, broader regression and cleanup.
