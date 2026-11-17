# Remainder-only Fp modular-power reduction, 2026-11-17

## Decision and measured scope

Adopt one quotient-discard mechanism. On the frozen native public workloads,
whole-process median baseline/candidate ratios are 1.172× for dense F2 powers,
1.223× for sparse F2 powers, 1.148× for actual irreducibility/certificate/Galois
setup, 1.112× for low-degree cases and 1.214× for one-shot setup. All five paired
blocks favored the candidate in each of those cases. The odd17 median is 1.049×,
but paired blocks span 0.994–1.147×; its modest effect remains unresolved. No
follow-up or additional implementation variant was needed.

The baseline is `905d23dc1a098359c28b4d9d7914c38d9a797c34`, which already includes
the characteristic-two known-square optimization. These are incremental results
against that baseline, not against an earlier generic-square implementation.
No whole-factorization/decoder, other-machine/backend timing or memory speed claim
is inferred.

Milestones:

- `85c0244`: freeze the six public cases and independent complete-result oracles.
- `a7141e5`: private remainder-only reduction and differential regression tests.
- Evidence commit: this report, compressed full runs and scoped verification.

Only announced fppoly/test/command/report paths changed. Root owns combined-source
verification, integration, publication and cleanup.

## Removed work and preserved contracts

Private modular-power product and square reductions previously called public
`divide`, then discarded the quotient. A new private `remainder_only` and its
cancellation loop compute the same remainder without constructing each quotient
term, shifting it, adding it to an accumulated quotient or returning an unused
Division record. The initial base and unit reductions in `power_mod` use the
same helper because those quotient values were also discarded.

The cancellation order, leading coefficient, inverse-leading calculation, scaled
divisor subtraction and canonical trimming path are unchanged. Compatibility is
checked first, then zero divisor, then zero dividend. Constant divisors retain
the original unit branch and nonunit modular-inverse check even though their
quotient is discarded. Nonconstant odd divisors still compute their leading
inverse before entering the loop, including when the dividend is already smaller.
Every remainder retains the original dividend's field context.

Public `divide`, `divide_loop` and `divide_by_constant` are byte-identical as the
oracle. Their gcd/Euclid callers remain unchanged. The existing F2 known-square
construction is unchanged. The exponent loop, final extra square, tuple/error
order, public signature and certificate algorithms are unchanged. Only the three
quotient-discard callers change their reduction operation. Raw constructor inputs,
zero/constant moduli, zero/one exponents, odd primes/F2 and mismatched-field errors
retain their prior exact results.

This duplicates a small cancellation loop so that public division remains an
unchanged independent oracle. Future changes must maintain both; exhaustive
public-division differential tests guard that drift. No cached inverse, exponent
schedule rewrite, equality dispatch, sparse-convolution change or checker shortcut
was added. There are no operand re-reductions to eliminate from modular.multiply;
that unrelated premise remains false.

All production state/control uses pure immutable ADTs. No primitive numerics,
arrays, mutation or FFI were introduced. The frozen full CLI ELF grew from 650928
to 651520 bytes (592 bytes); this is executable size, not a peak allocation/RSS
measurement. The share of time previously spent constructing quotients was not
profiled, so no larger-program speedup is projected from the local results.

## Correctness and checker independence

Initial native fppoly correctness passed 34/34 before the first source comparison.
New tests exhaust 3400 small raw coefficient-vector divisions over F2/F3/F5,
comparing every private result/error with unchanged public `divide.remainder` and
an independent host modular long-division oracle with trial inversion. Additional
odd-prime, constant/nonmonic, shorter-dividend, zero and foreign-field cases verify
context and error precedence. A retained baseline exponent schedule uses public
divide for every reduction, including known F2 squares, to check complete modular
powers independently of the new remainder helper.

Existing bitmask modular-power tests still cover 5952 small F2 powers using a
primitive carryless/remainder oracle, and the existing square tests compare with
generic multiplication. Public-division and host modular arithmetic are separate
from the optimized path. Host carryless benchmarks guard nonnegative Int64 inputs
and degree sums at most 62; degree-32 moduli give reduced operand degrees at most
31. The degree-eight certificate oracle also checks every actual product against
that guard, full Frobenius orbit/shape/closure and all Bezout polynomial identities.

Final fppoly plus actual Galois consumer tests passed 53/53 on each of native,
wasm-gc and JS, using release mode, `-j 1 --deny-warn`. Both generated public APIs
are byte-identical to baseline. Scoped purity passed for the two changed production
files. Root owns broad global checks; the worker did not repeat that graph.
[Exact verification](late-fp-remainder-20261117-raw/validation.json),
[API hashes](late-fp-remainder-20261117-raw/api-diff.json) and
[protected-source hashes](late-fp-remainder-20261117-raw/protected-source.json)
are retained.

The irreducibility/checker and Galois source text is unchanged, but those routines
share modular-power arithmetic. Passing the producer/checker pair alone is not an
independent arithmetic proof. The host convolution/remainder/power/Bezout oracles
and unchanged public division supply the independent bounded comparisons. No
whole-program independence or exhaustive correctness beyond these domains is
claimed.

## Frozen public comparison

The CLI uses only baseline-compatible public APIs. Each of six cases has five
independent ABBA blocks, giving ten baseline and ten candidate processes: 120
complete checked processes. Every canonical coefficient, returned certificate and
field metadata matched, and all independent/existing checks passed. Inputs, counts
and expected results stayed fixed after freezing. No checksum substitutes for
full equality. Baseline tracked libraries were never edited.

Native release executables were prebuilt with `-j 1 --deny-warn`; compilation is
excluded. All heavy commands use the shared `tools/measure --cpu 4` lock. Whole
processes include startup, setup, oracle preparation, one checked warm-up, operation
batch, checking and serialization. Inner `elapsed_us` covers the batch including
all per-iteration checks and complete serialization. One-shot repeats field and
raw-coefficient polynomial construction inside each iteration. Medians below are
milliseconds per full process, not per individual reduction. Ratios are
baseline/candidate; paired ranges show variation, not confidence intervals.

| Case | Iterations | Before ms | After ms | Process ratio | Five block ratios | Inner ratio |
| --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| dense-f2-power16 | 600 | 78.197 | 66.749 | 1.172× | 1.186–1.232× | 1.177× |
| sparse-f2-power32 | 320 | 63.896 | 52.239 | 1.223× | 1.158–1.272× | 1.223× |
| irreducibility-setup8 | 1200 | 81.215 | 70.771 | 1.148× | 1.046–1.199× | 1.156× |
| odd17-control | 50 | 120.059 | 114.498 | 1.049× | 0.994–1.147× | 1.042× |
| lowdegree-f2 | 40000 | 73.897 | 66.435 | 1.112× | 1.069–1.147× | 1.109× |
| setup-one-shot-f2 | 20000 | 88.641 | 73.002 | 1.214× | 1.180–1.325× | 1.229× |

The dense/sparse cases use degree-16/32 F2 moduli with fixed exponents 65535/65536.
The setup8 case generates the AES irreducibility certificate, independently checks
every orbit and Bezout identity, calls the existing checker, and constructs the
actual checked Galois extension. It measures that setup pipeline, not later field
arithmetic. Odd17 uses an independent host monic modular-power oracle. Low-degree
cases include zero/constant polynomials, exponent zero and zero/constant moduli.
One-shot constructs checked fields and polynomials from arbitrary raw coefficients.

The odd case is eligible for remainder-only reduction too; its frozen name is
retained, but it is not an unchanged arithmetic path. Its near-one paired blocks
and overlapping ranges leave that small effect unresolved. All negative block
values remain visible. No same-binary A/A control or further variant was run.
The larger F2/setup observations do not establish uniform gains for other
coefficient sizes, degrees, divisors, applications or environments.

## Artifacts and reproduction

Exact compiler, commit, per-file source and executable hashes are recorded in
`before-snapshot.json` and `after-initial-snapshot.json`. Versioned ignored ELFs
are `.tools/late-fp-remainder-20261117/{before,after-initial}.exe`; root must archive
them before cleanup. Both ELF hashes were rechecked after timing, and baseline
tracked library bytes still match 905d23d. Source/build directories are separate.

The [complete run archive](late-fp-remainder-20261117-raw/initial-abba.json.gz)
retains every duration, stdout/stderr, full checked result and provenance field.
The [readable summary](late-fp-remainder-20261117-raw/initial-abba-summary.json)
contains all statistics, full checked outputs, compressed and uncompressed SHA-256
values. Lossless decompression was verified before removing redundant plain JSON.
The old bitmask/odd-mod/AES host oracle fixtures were reused in the distinct frozen
CLI; no input was selected after observing candidate timing.

```sh
tools/measure --cpu 4 python3 /home/hosi/morph/tools/compare_field_kernels.py \
  --before .tools/late-fp-remainder-20261117/before.exe \
  --after .tools/late-fp-remainder-20261117/after-initial.exe \
  --before-root /home/hosi/morph-late-r2-before \
  --after-root /home/hosi/morph-late-fp \
  --harness src/cmd/lateremainderbench \
  --case dense-f2-power16 --case sparse-f2-power32 \
  --case irreducibility-setup8 --case odd17-control \
  --case lowdegree-f2 --case setup-one-shot-f2 --groups 5 \
  --output docs/research/late-fp-remainder-20261117-raw/initial-abba.json
```

Only local milestone commits are supplied. No push, merge, deployment, shared-index
edit or worktree removal was performed by this worker.
