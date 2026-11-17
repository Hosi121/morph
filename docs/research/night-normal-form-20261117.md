# Polynomial remainder-only reduction, 2026-11-17 night round 2

Baseline is `a9604b1270270b6edf9c10a6e0ef2a6d81c852ec`. This pass evaluates
one change: `polynomial.normal_form` computes a lex remainder without building
the quotient polynomials that it previously obtained from `divide` and discarded.
The public `divide` implementation and mapped `compare_monomial`, `insert`,
`polynomial`, and `evaluate_generic` functions remain byte-identical. No public
function signature changes. The prior NF/FP/GF2 work remains unchanged.

## Mechanism and scope

The new private loop selects the same highest pending term and the first divisor
whose leading monomial divides it, in the exact supplied divisor order. It
computes the same rational multiplier and uses the existing `term_times` and
`merge_terms` arithmetic. Irreducible terms enter the same reversed accumulator,
which is reversed once on return. Only quotient state, discarded quotient
insertions, and divisor indices used to address that state are removed.
The complete dimension check still precedes the zero-divisor result, including
zero dividends; empty divisor lists, zero polynomials, and zero-variable constant
polynomials keep their old values and errors. No approximation or primitive
machine arithmetic is introduced into the kernel.

This is a shared arithmetic dependency. Groebner/F4/FGLM and other certificate
checker source routines are unchanged, but a checker that calls `normal_form`
now uses the candidate dependency. Its success is **not an independent oracle**
for the new reduction loop. The unchanged public `divide(...).remainder` gives
an additional algorithm path, but both paths still share canonical insertion,
monomial arithmetic, exact rational operations, term products and merges. The
independent Fraction/dictionary oracle avoids those shared implementation helpers.
Finite tests and unchanged formal fingerprints are not a translation proof of
the new loop.

## Frozen independent evidence and public harness

Harness/oracle milestone: `5777395`. Thirty deterministic Python `Fraction`
fixtures cover dimensions 0, 1, 2 and 3, rational coefficients, nonmonic and
negative divisors, cancellation, constants, no divisors, and divisor-order
dependence for a list that is not a Groebner basis. Each expected remainder is
checked against both public `normal_form` and unchanged public `divide`.
Additional boundary tests check dimension-before-zero precedence in both divisor
orders, zero dividends/divisors, empty lists, and dimension-zero constant division.
The generator's `--check` guard verifies the committed fixture values and the
four independent direct-benchmark Fraction expectations.

The baseline-compatible six-case CLI is `src/cmd/nightnormalbench`:

- Dense univariate division with repeated leading cancellations.
- Rational nonmonic division.
- Multivariate ordered divisors.
- Irreducible/no-reduction control.
- Zero/no-divisor/error-precedence control.
- Actual Buchberger generation and public verification of the exact reduced lex
  basis for `<x^2-y,xy-1>`, compared in full with an existing independently
  generated SymPy 1.14.0 QQ basis.

Direct cases validate their static Fraction expectations with unchanged public
division during setup. The Buchberger case also validates input ideal membership
using unchanged public division by the independent expected basis. Every timed
iteration compares complete canonical polynomials/basis and serializes the full
result; Buchberger verification is included on each iteration. Serialization and
verification costs are retained, so no pure-producer-only speed claim follows.

The baseline CLI is copied and built under the shared CPU4 lock before candidate
source edits. Baseline tracked source/module/tool bytes are audited against
`a9604b1`. Both executables are saved before any rebuild. All heavy builds, tests,
checks and timings use CPU4 affinity, the shared worktree flock and `-j 1`
(`moon info` has no jobs option). Five independent-process ABBA blocks retain all
full checked stdout and outliers. Whole-process timing includes setup, generic
oracle checks, warmup, operations and output checks; the explicit inner interval
contains the repeated checked operation and full serialization. No different
intervals are subtracted or combined.

## Results and decision

**Adopted**, source commit `fe37b70`. Five ABBA blocks completed for each of six
frozen public cases, 120/120 full checked outputs successful. No experimental
follow-up, parameter search, or second implementation variant was needed.
Targeted univariate and multivariate cases improved in every block; the actual
Buchberger producer with verification also improved in every block. The
no-reduction control has a block near/slightly below parity, so its improvement
is uncertain. These small fixed inputs do not establish universal speedups.

Native release on Intel Core Ultra 7 255H under Microsoft/WSL virtualized Linux,
CPU4 affinity. Compiler: moonc v0.10.20+65efd5b93 and moon 0.1.20261104; raw data
contains complete compiler/platform metadata. Ratios below are baseline/candidate.
Process medians include startup/setup/warmup/old-division oracle and all full
checks; inner medians include repeated complete operations, checks, serialization
and, in the upper case, public Buchberger verification.

| Case | Baseline process ms | Candidate process ms | Process ratio | ABBA block range | Inner ratio | Repeats/process |
| --- | ---: | ---: | ---: | ---: | ---: | ---: |
| univariate-dense | 127.874 | 111.403 | 1.148x | 1.056–1.223 | 1.148x | 12000 |
| rational-nonmonic | 132.931 | 128.961 | 1.031x | 1.023–1.074 | 1.031x | 12000 |
| multivariate-order | 143.370 | 122.733 | 1.168x | 1.133–1.203 | 1.170x | 20000 |
| no-reduction | 144.144 | 138.284 | 1.042x | 0.999–1.098 | 1.044x | 150000 |
| edge-errors | 21.411 | 17.639 | 1.214x | 1.091–1.241 | 1.256x | 100000 |
| buchberger | 55.095 | 50.412 | 1.093x | 1.008–1.126 | 1.085x | 4000 |

The rational nonmonic improvement is only about 3% by process medians, despite
all block ratios being positive. The actual Buchberger case is 1.093x with a
minimum block ratio of 1.008x, so its benefit is less robust than the targeted
multivariate path. Its verifier shares the modified dependency and is included
in cost; no independent-checker-only or pure-producer speed attribution is made.
No memory measurement or large-degree/application-wide/other-machine claim is
made. The single zero/error-control case combines successful empty reductions
with errors; its ratio cannot be attributed to error handling alone.

The first attempted launch failed before any sample because `shutil.copyfile`
did not preserve the baseline saved ELF's executable bit. The failed zero-sample
report is retained. Restoring mode from the original executable changed no ELF
bytes or harness/source hashes; the same fixed comparison then completed. No
performance samples or outliers were dropped.

## Validation and provenance

The six affected packages (polynomial, groebner, f4, fglm, numberfield,
complexfield) passed **415/415** tests on each of wasm, JS and native, all with
`--deny-warn`. Global all-target check passed (786 incremental tasks); scoped
all-target API info passed (38 tasks); purity passed 329 production files;
formal drift passed 32 reviewed regions; the independent Fraction regeneration
check passed all 30 fixtures and four benchmark expectations. `git diff --check`
passed. Public polynomial API bytes match the unified baseline. Public divide
and all four mapped functions retain exact byte hashes, not merely equivalent
results. The new loop itself is outside the existing formal model correspondence.

| Variant | Source commit | Global source manifest SHA-256 | Saved executable SHA-256 |
| --- | --- | --- | --- |
| Unified baseline plus frozen CLI | `a9604b1270270b6edf9c10a6e0ef2a6d81c852ec` | `3ab00b0da9a82a6fdd06055a5f805063053a1643abbb4bfe309d5cfec92c33f1` | `dfeacfc84f6614dc0afe1f734352016faa97ce16972594972d2cf37591fbb1d5` |
| Remainder-only candidate | `fe37b700496bf9f0a734a8c2f76e0a3900cb00ee` | `6c0f04c27b5e6fd76f241a134e461e25b69f7bcb9c172d04a2ff5bf428782698` | `93496e81de4dc68be93e887870fab128efb82066e75647c8877e012aed182809` |

The baseline audit compared 1071 tracked source/module/tool files byte-for-byte
with `a9604b1`, then rechecked a clean tracked diff after measurement. Frozen
CLI additions are untracked in the baseline and disclosed in raw provenance.
No baseline tracked library was edited. The exact protected-region hashes and
tracked-source audit hash are in the validation receipt.

Artifacts:

- [Initial five-block comparison, all samples/full stdout](night-normal-form-20261117-initial.json)
- [Zero-sample launch failure](night-normal-form-20261117-launch-error.json)
- [Validation, hashes, baseline audit](night-normal-form-20261117-validation.json)
- [JS/native/global validation stdout](night-normal-form-20261117-validation.txt)
- [Independent Fraction generator](night-normal-form-20261117-oracle.py)
- [Direct benchmark Fraction expectations](night-normal-form-20261117-oracle-cases.json)

Saved ELF copies for root archival are
`.tools/night-normal-form-20261117/baseline-a9604b1.exe` and
`.tools/night-normal-form-20261117/candidate-initial.exe`. Wasm was run separately
and its successful count is recorded in the receipt. The primary worktree is
retained for root integration/archival; this worker did not push, remove the
worktree, or modify shared indexes/formal maps/checker bodies.
