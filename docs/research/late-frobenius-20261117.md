# Known binary Frobenius squares in modular powers, 2026-11-17

## Decision and limits

Adopt the private characteristic-two known-square path. On the frozen public
modular-power cases, whole-process median baseline/candidate ratios were 1.169×
for dense degree-16 inputs and 1.426× for degree-32 sparse inputs. All five paired
blocks favored the candidate for each. Actual irreducibility generation, full
certificate checking and checked Galois-extension setup improved 1.069× on the
fixed degree-eight fixture, again with all five blocks above one.

The odd-prime control is unresolved: its initial ratio was 0.960×, the one allowed
repeat was 1.023×, and a same-before-ELF A/A control was 1.006× with paired ratios
0.963–1.067×. These observations do not prove absence of an odd-prime regression;
the initial negative values are retained. No generic multiplication, entire
factorization/decoding, memory, other-machine or other-backend timing gain is claimed.
No code variant or correction followed the initial implementation.

Baseline: `a39f3234da50eb86e19d58583d5db5c2c99b62c1`. Milestones:

- `7a14823`: freeze the six public cases after calibration and format verification.
- `5c92b50`: known-square implementation and independent regression tests.
- Evidence commit: this report, complete compressed runs and verification records.

Only the worker's announced fppoly/test/command/report scope changes. Root owns
combined-source global regression, integration, publication and cleanup.

## Mechanism and invariant

For canonical coefficients over F2, `(sum c_i*x^i)^2 = sum c_i*x^(2i)`: cross terms
cancel and each coefficient is its own square. `char_two_square` therefore inserts
one zero between successive coefficients. Nil stays Nil and a one-coefficient
chain is shared directly. The highest canonical nonzero coefficient stays at the
highest output position, so no trailing zero is introduced. Raw public Binary
constructor inputs are still canonicalized at the existing opaque boundary.

A private `square_remainder` uses this linear construction only for characteristic
two, then calls the unchanged polynomial division and returns its remainder. Odd
primes add a characteristic dispatch before calling the original
`product_remainder(base, base, modulus)`; that dispatch is not assumed cost-free.
The sole caller
change is the statically known base/base square in `power_loop`. Arbitrary public
multiplication and accumulator/base products keep their original kernels; no
polynomial equality dispatch was added.

The exponent loop, its final extra square, tuple evaluation/error order and public
`power_mod` guards are unchanged. No second mechanism removes work from the
exponent schedule. Public signatures, context binding, mismatch precedence,
zero/constant-modulus behavior, exponent-zero results, derivative, evaluate, scale
and all certificate algorithms are preserved.

The removed work is generic binary-polynomial shift/XOR row construction for a
known square. There are no nonexistent operand reductions to remove from
`modular.multiply`, and no such claim is made. Remainder computation remains the
existing generic division. Its cost and other accumulator multiplications remain
inside the public timing; the fraction formerly spent squaring was not profiled.

All production storage and control remain pure immutable ADTs, with structural
recursion and no primitive numerics, arrays, mutation or FFI. Square construction
is linear in coefficient-chain length. No peak allocation/RSS measurement was
made. The frozen full CLI ELF grew from 650856 to 650920 bytes; this 64-byte
executable difference is not a memory-use result.

## Independent evidence and checker dependency

Initial native fppoly correctness passed 32/32 before any comparison. New tests
cover all 1024 binary polynomials through degree nine after arbitrary raw
coefficient canonicalization, comparing the private square to both unchanged
public multiplication and an independent host carryless product. Another 5952
modular powers cover every small nonzero binary modulus (including constant and
reducible moduli), base values below 32 and exponents 0,1,2,3,8,13. They compare
complete canonical outputs with both a host bitmask modular-power oracle and the
retained original generic-multiply exponent loop. Further tests compare odd
primes and zero/constant/foreign-field modulus error behavior with the old loop.

Final scoped fppoly plus Galois tests passed 51/51 on each of native, wasm-gc and
JS using release mode, `-j 1 --deny-warn`. Selected-package interface generation
confirmed byte-identical fppoly/Galois APIs. Scoped purity checks passed for both
changed production files. Root owns the broad global compiler/test graph; the
worker did not repeat it. Exact commands and outputs are in `validation.json`,
`initial-native.json`, `api-diff.json` and `scoped-purity.json` in the raw folder.

`audit_protected.py` confirms all old polynomial function bodies are identical
apart from normalizing the single known-square call replacement. Original
characteristic-two source remains an exact prefix. Irreducibility/factorization
and Galois source files are byte-identical; source hashes are in
`protected-source.json`.

Those checker algorithms share `power_mod`, so their success is not an independent
arithmetic implementation check. The benchmark independently replays every
Frobenius orbit with host carryless arithmetic, checks the full shape and closing
orbit, and verifies every supplied Bezout polynomial identity by independent
host products/XOR. It then runs the unchanged public checker and checked Galois
constructor and serializes the complete certificate and field metadata.

The host Int64 oracle is range guarded: a degree-32 modulus yields reduced operand
degrees at most 31 and product degree at most 62. Negative inputs and larger degree
sums abort. Even the unused final multiply-loop shift avoids the sign bit. Setup
and degree-eight Bezout intermediates pass the same dynamic guard. Host odd-prime
control products are bounded small integers. `oracle-fixtures.json` also records
an independent Python carryless reproduction and the AES orbit
[4,16,27,94,228,77,250,2]. None of these expected values calls the optimized square.

## Frozen public comparison and negative controls

Native release executables were prebuilt with `-j 1 --deny-warn`. The shared
`tools/measure --cpu 4` lock covers builds, tests and measurements. Each initial
case has five independent ABBA blocks: ten baseline and ten candidate processes,
120 complete checked processes total. The single bounded follow-up adds twenty
odd-prime repeat processes and twenty same-before-ELF A/A processes. All 160
process outputs matched fully and every independent oracle/check passed.

Whole-process time includes startup, setup, oracle preparation, one checked
warm-up and the complete batch with checks/serialization. `elapsed_us` covers the
batch, also including every complete output/certificate check and serialization.
The one-shot case repeats field and public raw-coefficient construction inside
each iteration. Values below are median milliseconds per complete process, not
per individual square. Ratios are baseline/candidate; paired block ranges show
variation rather than statistical confidence intervals.

| Case | Iterations | Before ms | After ms | Process ratio | Five block ratios | Inner ratio |
| --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| dense-f2-power16 | 300 | 45.375 | 38.804 | 1.169× | 1.137–1.202× | 1.186× |
| sparse-f2-power32 | 80 | 24.737 | 17.345 | 1.426× | 1.341–1.739× | 1.499× |
| irreducibility-setup8 | 1200 | 84.918 | 79.430 | 1.069× | 1.031–1.109× | 1.073× |
| odd17-control | 50 | 122.038 | 127.110 | 0.960× | 0.924–1.049× | 0.962× |
| lowdegree-f2 | 40000 | 70.205 | 68.107 | 1.031× | 1.004–1.049× | 1.033× |
| setup-one-shot-f2 | 20000 | 85.501 | 81.847 | 1.045× | 1.014–1.100× | 1.039× |

`dense-f2-power16` uses a degree-16 modulus, dense input and exponent 65535.
`sparse-f2-power32` uses a degree-32 modulus, sparse input and exponent 65536.
`irreducibility-setup8` generates the complete certificate for the AES polynomial,
independently checks every orbit value/Bezout identity, runs the existing checker,
and constructs the actual checked Galois extension. This measures that setup
pipeline, not later field arithmetic. `odd17-control` retains generic products
for all squares. `lowdegree-f2` includes zero/constant inputs, exponent zero and
zero/constant modulus checks. `setup-one-shot-f2` includes checked prime-field
and arbitrary raw-coefficient construction on each call.

The actual setup fixture's gain is smaller than isolated modular powers because
it also performs Euclid, certificate checks and setup. Low-degree and one-shot
observations are modest and do not imply general gains for all such inputs.
The odd control changed direction on its one repeat; the same-ELF control also
varied across blocks. Its effect remains unresolved and the initial slowdown
must not be erased or called proven noise. All follow-up raw data are retained,
and no additional tuning or variants were run.

## Retained artifacts and reproduction

`before-snapshot.json` and `after-initial-snapshot.json` record exact compiler,
commits, per-file source hashes and frozen ELF hashes. Ignored ELF copies are in
`.tools/late-frobenius-20261117/{before,after-initial}.exe`; root must archive them
before worktree removal. Baseline tracked library bytes match a39f323 before and
after timing; only frozen CLI sources were copied. Source/build directories are
separate. ELF hashes were rechecked after all comparisons.

Complete stdout/stderr, every duration/full result and source/artifact/harness
metadata are losslessly stored in the [initial archive](late-frobenius-20261117-raw/initial-abba.json.gz),
[odd repeat archive](late-frobenius-20261117-raw/odd-repeat-abba.json.gz) and
[A/A control archive](late-frobenius-20261117-raw/odd-aa-abba.json.gz). The
[initial readable summary](late-frobenius-20261117-raw/initial-abba-summary.json)
and [validation log](late-frobenius-20261117-raw/validation.json) are plain JSON. Their corresponding
`*-summary.json` files are readable, retain all statistics/full checked outputs,
and include compressed and original SHA-256 values. `compress_runs.py` verifies
byte-exact decompression before removing the redundant plain JSON. Calibration,
protected-source audit, selected verification and post-comparison artifact checks
are retained beside them.

```sh
tools/measure --cpu 4 python3 /home/hosi/morph/tools/compare_field_kernels.py \
  --before .tools/late-frobenius-20261117/before.exe \
  --after .tools/late-frobenius-20261117/after-initial.exe \
  --before-root /home/hosi/morph-late-before \
  --after-root /home/hosi/morph-late-fp \
  --harness src/cmd/latefrobeniusbench \
  --case dense-f2-power16 --case sparse-f2-power32 \
  --case irreducibility-setup8 --case odd17-control \
  --case lowdegree-f2 --case setup-one-shot-f2 --groups 5 \
  --output docs/research/late-frobenius-20261117-raw/initial-abba.json
```

Only local milestone commits are supplied. No push, merge, deployment, shared-index
edit or worktree removal was performed by this worker.
