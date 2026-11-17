# Constant-unit QQ polynomial multiplication, final extended round

Baseline: `905d23dc1a098359c28b4d9d7914c38d9a797c34`. One mechanism is evaluated:
ordinary `polynomial.multiply` recognizes a single constant monomial `+1` or
`-1`, shares the other immutable polynomial for `+1`, and uses unchanged
`negate` for `-1`. Subtract, add, negate, generic balanced product helpers,
remainder/division, mapped functions and checker bodies remain byte-identical.

## Exact preconditions and cost boundaries

Polynomial is opaque. Its constructor canonicalizes sorted unique nonzero terms
and checks exponent-vector dimension. The singleton guard runs before numeric
inspection. Every exponent must be Nat.Zero; a monomial with coefficient one and
a nonzero exponent is not a scalar identity. Existing exact getters expose the
numerator sign/magnitude and positive denominator. Binary's opaque canonical
little-endian bits use Nil for zero and Cons(true,Nil) for one; Rational ratio
normalization reduces public constructor inputs such as 2/2 to 1/1. The helper
checks those two one-bit shapes and reads the sign. No new Rational/Binary factory allocation,
whole-polynomial equality, arbitrary-precision equality scan, or primitive numeric
operation is used for identity classification.

The dimension check remains first, including empty products and differently
dimensioned units. Both singleton operands are considered in order, so a nonunit
constant on the left does not hide a right-hand unit. For multi-term × multi-term
inputs only the constant-size singleton shape dispatch runs: no coefficient
getter or exponent traversal occurs. This is not a guarantee of literally zero
instruction/layout overhead; controls measure the public fallback path.
The generic balanced implementation and its arithmetic order are unchanged.
Sharing is valid because polynomial/term/number ADTs are immutable and carry no
context beyond variable count and terms. Negative-unit output uses the existing
canonical negate function and shares its exponent vectors.

Independent evidence comprises 37 Python Fraction/dictionary complete-product
fixtures and a dimension-error test. They cover both orders/signs, variable
counts 0–3, zero/small/larger inputs, normalized unit constructors, nonconstant
monomials with coefficient one, nonunit scalars and dense controls. White-box
oracles retain both the old generic balanced product and old sequential fold.
These share existing monomial/rational/merge helpers; host Fraction convolution
avoids that arithmetic dependency, although expected polynomial construction
uses the unchanged canonical constructor. The generator has a --check guard.
No formal source-translation proof of this new dispatch is claimed.

## Frozen public benchmark

Frozen harness/oracle commit `3af66a6`, package `src/cmd/lateunitbench`, uses six
cases: large +1 and -1 products in both operand orders, nonunit-singleton
controls in both orders, dense multi-term fallback in both orders, combined
tiny/zero/0-variable/nonconstant/dimension controls, and actual checked NF
multiplication by units in both signs/orders. Each primary product is checked
in full and serialized in full; the combined tiny case checks all component
results and serializes its constant result. NF setup verifies the selected root
and irreducibility once per process; every NF product checks the representative
and retained field context. Whole-process timing retains this setup; the inner
interval contains repeated operations, all result checks and serialization.
No verifier cost is dropped or separate timing scopes combined.

Native correctness and initial timing precede final broader checks. All heavy
jobs use the common CPU4 flock, -j1 (moon info has no jobs option), native release
for timing, and separate build trees. Baseline copying/build occur under the
lock before candidate edits. All tracked baseline source/module/tool bytes are
audited, saved ELF modes/hashes and frozen harness hashes retained, and all five
independent-process ABBA blocks preserve full stdout and every sample. Lossless
raw gzip and readable summaries retain compressed/uncompressed SHA-256 hashes.

## Results and decision

**Adopted**, source `458dcfd`. The +1, -1 and actual NF paths improve in every
ABBA block. The combined tiny/zero/error case also has positive block ratios.
The nonunit and dense controls are uncertain/near parity; this does not prove
zero overhead or absence of small regressions. No follow-up or further source
variant was needed. The pass ends with this single identity-sharing mechanism.

Native release, CPU4, Intel Core Ultra 7 255H under Microsoft/WSL virtualized
Linux; compiler moonc v0.10.20+65efd5b93 and moon 0.1.20261104. Complete compiler
and platform strings are retained in the raw report. Ratios are before/after;
above one favors the candidate. Process timing retains startup/setup/warmup,
full validation and serialization, including NF field verification/setup.

| Frozen public case | Baseline ms | Candidate ms | Process ratio | ABBA block range | Inner ratio |
| --- | ---: | ---: | ---: | ---: | ---: |
| unit-plus | 301.901 | 186.489 | 1.619x | 1.531–1.637 | 1.625x |
| unit-minus | 305.635 | 198.041 | 1.543x | 1.441–1.775 | 1.548x |
| nonunit-controls | 103.709 | 104.051 | 0.997x | 0.946–1.030 | 0.994x |
| dense-control | 91.056 | 89.816 | 1.014x | 0.840–1.201 | 1.014x |
| tiny-zero-errors | 32.323 | 30.815 | 1.049x | 1.025–1.196 | 1.039x |
| nf-upper | 57.532 | 47.785 | 1.204x | 1.181–1.291 | 1.214x |

The direct sign/order cases each execute both operand orders, so the case ratio
is their combined checked cost rather than a separate estimate per order.
The actual NF case executes all four sign/order combinations and checks exact
representatives/context. Its 1.204x process median is an ordinary public caller
result, not a whole-application claim. The small mixed case cannot identify the
benefit of each individual zero/error/constant operation. Dense control block
ratios span 0.840–1.201, and nonunit ratios span 0.946–1.030; their medians alone
must not be treated as a no-regression proof. No speed claim extends to arbitrary
sizes, coefficient bit lengths, variable counts, hardware or application totals.

Positive-unit sharing and negative-unit exponent sharing are source-level facts.
Peak RSS, retained heap, allocator counts and actual memory reductions were not
measured. No memory improvement is claimed from those facts alone. This pass
introduces no prepared field data, optional plan API or setup cost that is moved
out of only one variant. The existing field/checker code bodies remain unchanged;
their arithmetic can depend on optimized multiply, so checker success alone is
not independent correctness evidence. Old generic/sequential oracles and host
Fraction convolution supply separate arithmetic comparisons.

## Validation and provenance

Initial native polynomial+numberfield passed **279/279** before timing. Final
wasm and JS suites also passed **279/279** each, with deny-warn. Global all-target
static check passed (839 incremental tasks); API info passed (90 tasks); purity
passed 332 production files; formal drift passed 32 reviewed regions; the
independent generator checked 37 full fixtures. All protected source functions/
files and public polynomial API bytes match the baseline. The new multiply
helper itself is outside the existing formal source correspondence, so this is
not a translation proof. Root owns the broader integration regression; this
worker did not rerun the whole 84-package runtime graph.

The baseline's tracked source/module/tool bytes were audited before timing and
its tracked diff rechecked afterwards. Its frozen added CLI directories and
working-tree state are disclosed in raw provenance. Baseline was built before
candidate edits under the same lock; source and executables remained frozen
during all 120 successful full checked runs. Gzip roundtrip and both raw/compressed
SHA-256 hashes were verified. No samples, verifier costs or negative controls
were discarded.

| Variant | Source commit | Source manifest SHA-256 | Saved executable SHA-256 |
| --- | --- | --- | --- |
| Baseline plus frozen CLI | `905d23dc1a098359c28b4d9d7914c38d9a797c34` | `d60e06c90f70b495ad6228ea794e74fd54ad23ea97c497e9d94e382397230181` | `109e19766141d0accdfba4a2a11ae121217e3a543300a84b80a4e4d4789b5c11` |
| Adopted unit dispatch | `458dcfdbc708b345c29f713d5fe055dbeae77065` | `c6ab8f51f6e85b6cd1acc219dbcd3775ee632e7ac6aa203355270e3a96ae453a` | `90020d91d99b3867a6090823e7b1b538b0aa423c9cf6a1a155c5bde9cc1dbbb6` |

Public reproduction uses the frozen `src/cmd/lateunitbench` files and the six
case names above. Build/save baseline and candidate native release executables
from their respective source snapshots, preserve executable mode, and run
`tools/compare_field_kernels.py` with five ABBA groups under `tools/measure --cpu 4`.
The readable summary records the exact original driver arguments and audit.

Evidence:

- [Full raw checked runs, lossless gzip](late-poly-unit-20261117-initial.json.gz)
- [Readable case summary, raw/gzip hashes, driver command and baseline audit](late-poly-unit-20261117-summary.json)
- [Validation/hashes](late-poly-unit-20261117-validation.json), [initial native log](late-poly-unit-20261117-native.txt), [final validation log](late-poly-unit-20261117-final-validation.txt)
- [Independent Fraction generator](late-poly-unit-20261117-oracle.py), [full direct expectations](late-poly-unit-20261117-oracle-cases.json)

Saved artifacts for root archival:
`.tools/late-poly-unit-20261117/baseline-905d23d.exe` and
`.tools/late-poly-unit-20261117/candidate-initial.exe`. The worker leaves its clean
worktree for root integration/archive and does not push, remove worktrees or edit
main/shared indexes.
