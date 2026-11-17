# Incremental exact rational span, 2026-11-17

## Decision and scope

Adopt one shared immutable exact rational span for number-field minimal polynomials,
complex-field minimal polynomials and FGLM. On the eight frozen public workloads,
all 160 comparison processes produced identical complete canonical results and
passed the existing independent checks. The larger tested dimensions improved;
the CF dimension-two control had only a small difference. These measurements do
not establish a speed guarantee for other fields, quotient bases, coefficient
sizes, backends or machines.

The original baseline is `2e33ef5612940efa555c0a3380a0bb34190cd159`. The implementation
work base is `93878f2fb57ad965e3cd73f2dd2ce1aaf2b1882d`; its preparatory NF coordinate
exposure preserves the original computation. Implementation milestones are:

- `0e20768`: baseline-compatible public benchmark, independent expected results.
- `cf78f53`: calibrate repetitions by 40 before the first comparison; then freeze.
- `871cdb6`: shared incremental rational span and independent oracle tests.
- `3d32908`: all three consumers, FGLM pause/cache tests and generated interfaces.

No other kernel optimization is present in this candidate. No corrective algorithm
or ablation was needed after comparison. This report is local evidence; the parent
integration owns combined-source verification, publishing and worktree cleanup.

## Removed work and preserved checks

Previously, each new power/normal-form column rebuilt a rational matrix and solved
against all preceding independent columns. `linearspan.State` now retains exact
normalized residual columns. Only the new vector is reduced. NF and CF retain the
same power order and first-dependence result; FGLM retains its heap, monomial order,
source normal forms, cap, fuel accounting, statistics and relation ordering.

The NF/CF monicity, annihilation and independent preceding-power rank checkers are
byte-for-byte unchanged, including their existing `linear.rref` calls. FGLM still
independently reconstructs each dependent vector from its original columns before
creating a relation; `src/fglm/certificate.mbt` is byte-for-byte unchanged. The old
one-shot FGLM `span` solver moved intact to a white-box test file as a legacy oracle.
The hash evidence is in `incremental-span-20261117-raw/unchanged-checkers.json`.

Public consumer function signatures and error cases are preserved. The permitted
opaque FGLM state extension stores one `linearspan.State`. The additive span API is
`empty(dimension)`, `dimension`, `rank` and `insert`; insertion returns either a new
independent state or unique coefficients relative to the ORIGINAL independent
column insertion order. A wrong input-vector length returns `DimensionMismatch`.
No public benchmarking path calls the new span API directly.

## State invariant

For original independent columns V, every cached column E has a triangular witness
W satisfying `E = V*W`, with omitted trailing zero coefficients. Each E is normalized
to one at its pivot and zero at all preceding cached pivots. Pivot positions need
not increase: inserting a vector whose first nonzero coordinate precedes an older
pivot is supported without rearranging the original coefficient order.

During reduction, `residual = incoming - V*coefficients` is preserved by subtracting
a pivot multiple of E and adding the same multiple of W. A zero residual returns
the unique dependence coefficients. For a nonzero residual with pivot q, the new
column is `residual/q` and its witness is `(-coefficients/q, 1/q)` in the extended
original order. Existing columns do not change. Every successful independent
insertion creates a distinct pivot; rank is bounded by dimension. Zero dimension,
zero vectors and full-rank insertion therefore require no special approximate or
fallback solver.

All state, vectors, coefficients and dimensions use immutable symbolic ADTs; there
are no machine numerics, arrays, mutation or FFI in production. The persistent
states can be reused, paused, resumed or branched independently. Retained state is
O(d*r + r²) rational entries for ambient dimension d and rank r; FGLM also retains
its original O(d*r) vector data for witness reconstruction. Peak memory and rational
bit-growth were not measured. Maintaining a full reduced basis would update older
columns on each insertion; the triangular witnesses avoid that unnecessary work.

## Validation

All affected tests passed on `native`, `wasm-gc` and `js`: 273/273 on each target,
with `-j 1 --deny-warn`. The targeted packages are `linearspan`, `numberfield`,
`complexfield` and `fglm`. Tests include:

- Every three-vector sequence from `{-1,0,1}²` (729 sequences, 2187 insertions),
  independently classified by 2x2 determinants and Cramer's rule, also compared
  against the existing full `linear.solve` for every step.
- Fifteen reproducible Python `fractions.Fraction` full-system Gauss-Jordan fixtures
  (120 decisions, dimensions one through five), including fractions, reversed pivot
  positions, dependent combinations, repeats and zero vectors. Generator and full
  oracle records are retained beside the raw report.
- Zero dimension, invalid dimensions, zero vectors, rank saturation, earlier pivot
  positions, persistent branches and unchanged older states after failed insertions.
- FGLM cached classifications and coefficients compared with the legacy full solver
  over paused snapshots; zero fuel and separate resume branches yield identical
  complete certificates, ordering and statistics.
- Existing NF/CF minimality/rank/annihilation rejection tests, independent algebraic
  fixtures, and existing SymPy FGLM order/dimension fixtures remain enabled.

`tools/moon check --target all --deny-warn -j 1` passed (1808 tasks). The purity gate
passed for 327 kernel files. The native release executable built with `-j 1
--deny-warn`. Exact commands, exit codes and outputs are retained in
`incremental-span-20261117-raw/validation.json` and `scoped-targets.json`.

## Frozen public measurement

Builds, tests and comparative timings used the shared `tools/measure --cpu 4` lock;
other workers' heavy commands did not overlap this measurement. Executables were
prebuilt with native release mode. Five independent ABBA blocks per case give ten
baseline and ten candidate processes per case (160 total). Both benchmark source
hashes match. The comparison retained every stdout/stderr, result, duration,
executable/compiler/harness hash and complete source-manifest hash in
`incremental-span-20261117-raw/public-abba.json`.

`elapsed_us` measures the fixed iteration batch, including public computation,
existing independent checks, canonical serialization and full-result equality on
every iteration. NF/CF public minimal-polynomial functions keep their internal
minimality check, and the harness also calls the independent checker explicitly.
FGLM validates the source in conversion and checks the final certificate on every
iteration. Setup and one checked warm-up are outside the inner interval; the
separately recorded whole-process interval includes them and process startup.
Every input is fixed and nonzero except the deliberate zero scalar used to build
Q(i). Host integer serialization is confined to the bounded benchmark fixtures.

Medians below are milliseconds per full checked batch, not per operation. Ratios
are baseline/candidate; block ranges retain variation without implying statistical
confidence intervals.

| Case | Iterations | Before ms | After ms | Inner ratio | Five block ratios | Process ratio |
| --- | ---: | ---: | ---: | ---: | ---: | ---: |
| nf2 | 4000 | 56.574 | 52.182 | 1.084× | 1.049–1.110× | 1.081× |
| nf6 | 1200 | 130.087 | 98.476 | 1.321× | 1.188–1.481× | 1.309× |
| nf6-subfield | 1200 | 26.478 | 19.629 | 1.349× | 1.259–1.483× | 1.295× |
| cf2-tiny | 4000 | 94.696 | 92.615 | 1.022× | 1.010–1.122× | 1.023× |
| cf4 | 2000 | 145.133 | 133.015 | 1.091× | 1.053–1.195× | 1.090× |
| cf8 | 400 | 108.414 | 83.885 | 1.292× | 1.216–1.350× | 1.278× |
| fglm3 | 600 | 30.548 | 25.554 | 1.195× | 1.121–1.246× | 1.168× |
| fglm8 | 120 | 35.805 | 24.139 | 1.483× | 1.374–1.535× | 1.431× |

NF2/NF6 use `a+1` in `Q(a), a^d=2`; NF6-subfield uses `a²` and stops at degree
three within a degree-six field. CF2 uses i over Q, CF4 uses sqrt(2)+i, and CF8 uses
the real fourth root of 2 plus i. Their expected full monic polynomials are fixed
independently in the harness (the CF8 polynomial is the resultant of `t^4-2` and
`(x-t)^2+1`). FGLM3 converts `<x²-y, xy-1>`; FGLM8 converts
`<x-z⁴, y-z³, z⁸-1>` to grevlex. Complete expected canonical polynomial bases are
fixed from direct elimination, and the complete certificate, standard monomials,
source standard monomials and statistics are serialized for cross-source equality.

All measured case medians and all paired block medians favored this candidate.
CF2's approximately 2% median difference is small relative to the sample ranges;
no A/A noise control was run, so it should be read as a tiny-control observation,
not a reliable universal improvement. The measurements include arithmetic and
independent checking costs, so they do not isolate the elimination kernel's time.
No broader workloads, memory measurements or backend timing claims are made.

Reproduce after building the same frozen CLI in both source trees:

```sh
tools/measure --cpu 4 python3 /home/hosi/morph/tools/compare_field_kernels.py \
  --before /home/hosi/morph-algo-before/_build/native/release/build/cmd/spanbench/spanbench.exe \
  --after /home/hosi/morph-algo-incremental/_build/native/release/build/cmd/spanbench/spanbench.exe \
  --before-root /home/hosi/morph-algo-before \
  --after-root /home/hosi/morph-algo-incremental \
  --harness src/cmd/spanbench \
  --case nf2 --case nf6 --case nf6-subfield --case cf2-tiny \
  --case cf4 --case cf8 --case fglm3 --case fglm8 --groups 5 \
  --output docs/research/incremental-span-20261117-raw/public-abba.json
```

Only local commits are supplied by this worker; no push, merge, deployment or
worktree removal was performed. The parent retains responsibility for those
integration stages and the final combined-source measurement.
