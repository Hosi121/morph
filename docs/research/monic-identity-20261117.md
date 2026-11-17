# Sharing an already-monic canonical QQ polynomial

Adopt the leading-coefficient +1 identity path in `polynomial.monic`. The sparse
frozen public workload observed a 1.136× process ratio and 1.119× inner ratio;
all five inner block ratios exceeded one, while one process block was 0.987×.
Other monic cases had small positive medians with negative paired blocks. These
are limited workload observations, not a general speedup or a no-regression claim.
The higher-level resultant observation remains uncertain. There was one initial
comparison only, with no source variant, repeat or A/A follow-up.

## One mechanism

Baseline `a63dcbca9a07a5c875400c4305bf2b15585b3aa3` maps every nonempty polynomial
through reciprocal(leading coefficient) and constructs a new Term/Chain spine.
For a canonical leading coefficient +1 the arithmetic multiplier is the identity,
but that map still rebuilds the polynomial structure.

Source commit `3831050` adds one private `monic_positive_one` helper and a monic
entry branch. The helper views canonical QQ numerator sign, numerator magnitude
bits and denominator bits. Positive sign and exactly the one-bit magnitude and
denominator denote +1. Getters and these fixed shape matches take constant
structural work; no Nat/Binary conversions, numeric compare or exponent traversal
is introduced. When recognized, monic returns the existing opaque immutable
Polynomial. The leading monomial can have any exponent vector; it need not be a
constant or have exponent one.

Nil returns the same zero polynomial. Every nonunit, including negative one,
continues through the original nonzero/reciprocal/map procedure. Public results,
errors and APIs are unchanged. `unit_product.mbt`, exact arithmetic and all
checker source files are untouched. The complete production change consists only
of `polynomial.mbt`'s monic body and the new private helper, as recorded in the
[source/API/purity proof](monic-identity-20261117-raw/protected-source-proof.json).
The [minimal source patch](monic-identity-20261117-raw/monic-source.patch) and exact
before/after/helper source archives are preserved with
[source SHA metadata](monic-identity-20261117-raw/source-artifacts.json).

## Frozen workloads and independent expectations

Harness commit `901236c` includes its generated public interface. Identical
main/pkg/interface bytes build against baseline and candidate public APIs:

- `dense-monic`: 49 univariate terms, leading x^48 with coefficient +1; 3000 iterations.
- `sparse-monic`: six terms through degree240 with rational lower coefficients; 4000.
- `rational-multivar`: 37 terms in three variables, leading exponent [7,2,4]; 3000.
- `fallback-dense`: 26 two-variable terms, leading coefficient 2/3; 1500.
- `zero-tiny-controls`: zero/zero variables, +1, -1, 2/3 constants, x^7 and a
  multivariate nonconstant leading monomial with coefficient +1; 5000.
- `resultant-caller`: actual `realalgebraic.resultant_start` and advance/checker
  on x²-2 and x-1 under Sum; 500.

Every iteration compares full canonical polynomials, including variables and all
ordered terms, with independent Fraction-generated expectations and serializes
the full result. There is no checksum-only test. The actual resultant case checks
all certificate fields and the unchanged public checker. Its independent complete
expected polynomial is (t-1)²-2 = t²-2t-1, with all three samples [-1,-2,-1].
The frozen workload contains one higher-level consumer, not a field construction
or a general resultant survey.

Two new WB tests compare ten complete Fraction fixtures against the exact legacy
monic algorithm, and exhaust 153 small numerator/denominator pairs for +1
recognition and legacy monic equality. The Fraction oracle independently combines,
orders and normalizes rational coefficient values. Inputs/expected values are then
built through the unchanged public Polynomial constructor; this does not provide
whole-program independence from constructor canonicalization. The old monic WB
oracle bypasses the new recognizer but shares unchanged exact rational arithmetic.

Checker source preservation also does not make the checker independent of the
changed shared `monic` operation. Producers and checkers can both call monic. Full
Fraction expectations, the legacy oracle, and independent resultant polynomial
and sample values are therefore retained alongside the existing checker results.

`tools/generate_monic_identity_n05.py --check` independently recomputes all JSON
expected terms with Fraction and checks full numerical input/expected binding in
both the WB fixtures and frozen CLI. It does not approve arbitrary test control
flow. Its standalone guard is commit `741847c`; shared tools/check integration
belongs to root.

## Measurement and limits

Native release on CPU4 under the shared tools/measure lock; -j1 builds in separate
worktrees. Five ABBA blocks per case, 120 process runs. Both artifacts, generated C,
full per-file source manifests and compiler information were saved before timing.
Baseline tracked libraries remain at a63; its earlier inactive modular benchmark
CLI was retained as requested and is included in provenance, outside this build's
dependency graph. Inputs/counts and harness bytes did not change after freezing.

Ratios are baseline/candidate; values below one are adverse. Each process includes
input preparation, one checked warm-up, all iterations and full output checks and
serialization. Inner elapsed_us excludes preparation and the warm-up. Paired
ranges show variation, not confidence intervals or isolated monic-only cost.

| Case | Before ms | After ms | Process ratio | Five process-block range | Inner ratio |
| --- | ---: | ---: | ---: | ---: | ---: |
| dense-monic | 36.200 | 34.472 | 1.050× | 0.973–1.137× | 1.067× |
| sparse-monic | 10.380 | 9.135 | 1.136× | 0.987–1.175× | 1.119× |
| rational-multivar | 28.258 | 26.911 | 1.050× | 0.988–1.108× | 1.058× |
| fallback-dense | 11.956 | 11.696 | 1.022× | 0.981–1.127× | 1.027× |
| zero-tiny-controls | 13.792 | 12.582 | 1.096× | 1.000–1.127× | 1.109× |
| resultant-caller | 9.671 | 9.092 | 1.064× | 0.948–1.069× | 1.055× |

The dense, multivariate and fallback cases include process blocks below one.
Sparse inner blocks were all above one, but its process blocks were not. Tiny
controls combine identity and fallback operations, so their median is not an
isolated negative-one or zero result. Fallback's 1.022× median does not establish
an improvement to nonunit inputs, nor prove absence of regressions elsewhere.
The resultant median was 1.064× with three of five process blocks below one;
no higher-level resultant improvement is claimed. No timing data were discarded.

## Validation and artifacts

Initial native correctness and final native/JS/wasm-gc checks each passed **294
polynomial+realalgebraic tests**. All 120 measured processes passed complete output
checks. Format, scoped production purity, independent fixture binding, unchanged
public interfaces, exact protected source bytes and post-timing ELF hashes passed.
Full logs and SHA values are in
[validation.json](monic-identity-20261117-raw/validation.json). Root owns broader
combined validation and global warnings/purity gates.

The [full lossless run archive](monic-identity-20261117-raw/initial-abba.json.gz)
retains every duration, stdout/stderr, full payload, exit code and provenance.
The [readable summary](monic-identity-20261117-raw/initial-abba-summary.json)
retains all block ratios, negative observations, full results and compressed/
uncompressed SHA256. Decompression was checked before removing redundant JSON.
[Before](monic-identity-20261117-raw/before-snapshot.json) and
[after](monic-identity-20261117-raw/after-initial-snapshot.json) snapshots retain
per-file source hashes, exact commits and ELF/compiler identity.

Root-archivable frozen binaries and generated C are in the candidate worktree's
`.tools/monic-identity-20261117/{before.exe,after-initial.exe,before.c.gz,after-initial.c.gz}`.
Generated C hashes are in
[artifact metadata](monic-identity-20261117-raw/generated-c-artifacts.json).
Exact old/new monic source files are committed as lossless gzip alongside the
source SHA metadata, and the harness is committed at 901236c. Archive ignored
ELFs/C before root removes worktrees. This worker did not push, edit shared
indexes/tools/check, create additional worktrees or perform cleanup.

```sh
tools/measure --cpu 4 python3 tools/compare_field_kernels.py \
  --before .tools/monic-identity-20261117/before.exe \
  --after .tools/monic-identity-20261117/after-initial.exe \
  --before-root /home/hosi/morph-conversion-modular-before \
  --after-root /home/hosi/morph-conversion-modular \
  --harness src/cmd/conversionmonicbench \
  --case dense-monic --case sparse-monic --case rational-multivar \
  --case fallback-dense --case zero-tiny-controls --case resultant-caller \
  --groups 5 --output initial-abba.json
```
