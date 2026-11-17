# Exact modular and prime-field arithmetic, 2026-11-17

This bounded pass examines two mechanisms against baseline `4d9e6c4`: an early
canonical-residue return in `modular.reduce`, and a parity-based `primefield`
arithmetic dictionary for characteristic two. Every public operation continues
to accept arbitrary unreduced `Binary` values. Prime construction, checked
`Prime` boundaries, and certificate APIs are unchanged.

## Mechanisms and exactness

The first trial compares a reduction input with the modulus before calling the
existing remainder implementation. A smaller input is already canonical; an
equal input reduces to zero; larger inputs retain the original remainder path.
`Binary` has opaque fields and canonical public constructors, so returning the
input preserves its representation invariant. This mechanism can duplicate
ordering work already performed by `binary.remainder`, including on unreduced
inputs. Trial source: `cf38549`.

The second trial recognizes exactly the canonical bit representation of two
when constructing the field dictionary. The low bit is reduction modulo two
for every nonnegative integer, so addition and subtraction use parity XOR,
multiplication uses parity AND, and negation returns parity. Inversion returns
`None` for an even input and `Some(one)` for an odd input. This follows the
existing dictionary's canonical-result and inverse-existence contracts without
constructing discarded arithmetic intermediates. General modular arithmetic,
including composite moduli, keeps its original implementation. Trial commit:
`5c8577a`; isolated measurement restores `modular.reduce` to baseline.

## Measurement protocol

The identical baseline-compatible source in `src/cmd/primebench` is built with
the pinned SDK, native target, release optimization, and `-j 1`. The raw JSON
records compiler versions, source manifests, harness and executable hashes,
CPU affinity, order, every sample, outputs, and ranges. The parent-owned
`tools/compare_field_kernels.py` driver runs five ABBA blocks per case: ten
independent processes per implementation, twenty samples per case. All runs
hold the repository-wide `tools/measure --cpu 4` lock; compilation is excluded.
The comparison driver's SHA-256 at measurement time is
`0adfc65a691c980b44645150d511ee01549b65d1117b50525744debc303b928f`.

Times cover the whole process: startup, input/field construction, symbolic
operations, independent machine-oracle work, output conversion, and checking.
No internal timer is reported. Small cases have larger fixed repetition counts
to reduce process-startup noise. Input construction and expected-output work
are identical in both sources. Every process checks an independent integer or
schoolbook polynomial oracle and emits an identical checked checksum. The
reported ratios therefore describe these public-API workloads, rather than a
claim about an isolated arithmetic instruction or every application.

The reduction controls cover canonical small residues, values immediately
below/equal/above the modulus and its double, ordinary unreduced values, and
256-/1024-bit unreduced values. Field dictionary controls cover characteristic
two, unreduced operands, inverse existence, and odd characteristics 17 and
65537. The upper workload repeatedly computes `(state + base)^3 mod divisor`
with actual degree-eight `fppoly` operations and checks all coefficients against
an independent machine polynomial implementation. `fppoly` already specializes
characteristic-two addition and multiplication, limiting the work this new
dictionary can remove in that caller.

## Results and acceptance

Times are median whole-process milliseconds. A ratio above one favors the
trial. Each row has ten samples per variant; the raw block ratios and ranges
are retained rather than treating these medians as uncertainty bounds.

### Rejected: canonical reduction comparison

| Case | Baseline ms | Trial ms | Baseline / trial |
| --- | ---: | ---: | ---: |
| reduce-small | 361.239 | 223.140 | 1.619× |
| reduce-near | 111.043 | 115.872 | 0.958× |
| reduce-unreduced | 1220.241 | 1246.762 | 0.979× |
| reduce-256 | 225.765 | 226.978 | 0.995× |
| reduce-1024 | 261.158 | 258.624 | 1.010× |
| field2 | 292.506 | 339.160 | 0.862× |
| field2-unreduced | 308.860 | 355.759 | 0.868× |
| inverse2 | 516.498 | 527.102 | 0.980× |
| field17 | 327.958 | 323.001 | 1.015× |
| field65537 | 1200.957 | 1208.372 | 0.994× |
| add17 | 301.175 | 312.410 | 0.964× |
| add65537 | 371.009 | 393.407 | 0.943× |
| poly2 | 136.767 | 137.522 | 0.995× |
| poly17 | 470.193 | 437.237 | 1.075× |

All 280 processes produced checked equal outputs. The small canonical reduction
gain is consistent across all five blocks (1.559–1.730×), but both GF(2) mixed
cases regress in every block (0.791–0.911× across the two cases). The broad extra
comparison is rejected and `modular.reduce` is restored to its baseline source.
The isolated polynomial result does not justify imposing those dictionary
regressions. The two mechanisms are not combined because this trial is rejected.

Raw samples: `src/cmd/primebench/results/canonical-return-abba.json`.

### Retained: characteristic-two dictionary

| Case | Baseline ms | Trial ms | Baseline / trial |
| --- | ---: | ---: | ---: |
| field2 | 271.195 | 185.670 | 1.461× |
| field2-unreduced | 291.246 | 164.686 | 1.768× |
| inverse2 | 474.693 | 60.283 | 7.874× |
| poly2 | 133.018 | 135.721 | 0.980× |
| field17 | 297.918 | 314.693 | 0.947× |
| field65537 | 1155.681 | 1139.408 | 1.014× |
| add17 | 297.678 | 305.484 | 0.974× |
| add65537 | 389.294 | 387.472 | 1.005× |
| poly17 | 420.590 | 426.644 | 0.986× |

All 180 processes produced checked equal outputs. All five paired blocks favor
the trial on the three direct GF(2) workloads. Their respective block-ratio
ranges are 1.042–1.880×, 1.549–1.845×, and 6.665–8.442×. The largest gain comes
from avoiding extended Euclid for inverse existence in characteristic two.
The small, exact specialization is retained for these direct workloads.

There is no demonstrated upper-level `fppoly` gain: the measured characteristic
two case is 2.0% slower. Odd-characteristic controls range from 5.6% slower to
1.4% faster, with block ratios on both sides of parity. Those measurements are
reported as limitations, rather than claiming unchanged odd-field performance.
A same-executable control is recorded separately to characterize timing noise.

Raw samples: `src/cmd/primebench/results/characteristic-two-abba.json` and
`src/cmd/primebench/results/baseline-noise-abba.json`.

The same baseline ELF was then measured as both variants in another five ABBA
blocks per control (100 processes, all checked). Its artificial before/after
ratios are 0.987× for `poly2`, 1.027× for `field17`, 1.022× for `add17`, 1.002×
for `add65537`, and 1.015× for `poly17`. Individual block ratios span
0.951–1.078×. This demonstrates percent-scale drift in unchanged-code timings;
it does not establish that the candidate's 5.6% odd-field control slowdown is
absent. The accepted claim remains the three measured direct GF(2) workloads.

The canonical trial's temporary source-only worktree was checked clean and
removed after sampling. Its source commit, manifest, and executable hash remain
in the raw report. The retained production source changes only the
characteristic-two dictionary; the added signed/modulus boundary tests remain
useful independent correctness coverage after the reduction trial is reverted.

## Validation

- `modular`, `primefield`, and `fppoly`: 31 tests passed on each of native,
  JavaScript, and Wasm GC. These include exhaustive small prime/composite
  modular operations and inverses, signed reduction, unreduced GF(2) values,
  polynomial machine oracles, and malformed-certificate rejection.
- Added modular tests cover the canonical, modulus, and twice-modulus boundary
  ranges for every modulus 2 through 39, plus signed inputs -128 through 128.
- Added dictionary tests cover unreduced even/odd values through 256 bits;
  addition, subtraction, multiplication, negation, and inverse outputs are
  compared with independent parity expectations.
- Global `moon check --deny-warn -j 1` passed; `moon info` regenerated the selected
  interfaces without public-API differences. The purity gate passed all 323
  production files, rejecting machine numerics, mutation, arrays, and FFI.

No claim is made about peak memory, other CPUs, other backends' speed, prime
construction speed, or a full Galois computation. Correctness tests, rather than
native timing results, provide the evidence for JavaScript and Wasm GC.
