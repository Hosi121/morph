# GF(2) fused elimination trial, 2026-11-17 night sprint, round 2

Adopt the borrowed-tail follow-up `73a67ee` for its direct RREF gains, accepting
the measured tiny/factor control costs. No CSS or whole-consumer gain is
claimed. Baseline: `a9604b1270270b6edf9c10a6e0ef2a6d81c852ec`, including the
adopted round-one monotone nullspace walk. Frozen public CLI: `d231aea`. This
was one producer mechanism and one bounded follow-up. It changes no
`solve.mbt` code and no independent certificate-checking algorithm.

## Mechanism and ordinary callers

`gf2.rref` and `gf2.factor` use the private `reduce` routine. In `above`, the
baseline looks up the same pivot with `nth` twice, then walks the prefix again
in `xor_suffix` if an addition occurs. In `below`, it performs one `nth`
lookup and another prefix walk for a nonzero pivot.

The initial implementation (`750fbf2`) replaces these paths with
`eliminate_once`. The helper returns None when the pivot is absent or false,
so the caller shares the complete original row. Some carries the row obtained
by XORing only the active suffix and rebuilding the untouched prefix; it also
drives the original Add operation-log entry. The first-pivot selection,
adjacent-swap log, forward/below and backward/above ordering, transform rows,
public result/error contracts and all generic checkers are unchanged. GF2
reduction has no fuel parameter; no new work-budget behavior is introduced.

An ordinary RREF caller already exists at `cohomology.compute -> cycle_rank`
(`cohomology/cohomology.mbt:273`); this trial does not benchmark that whole
consumer. The separate ordinary-consumer control is
`csscode.validate -> rank_witness -> gf2.factor`, with its original
commuting/rank/parameter checkers still included. No unused public API or
external integration is introduced.

## Frozen public comparison

`src/cmd/nighteliminatebench` is identical in baseline and candidate. Its six
cases cover tiny, sparse, dense and wide direct RREF, complete factorization,
and CSS validation. Dense fixtures are host products of unit triangular
matrices, guaranteeing full row rank. Thus the complete transform U producing
the canonical RREF is uniquely determined; independent indexed Boolean
Gauss-Jordan on an augmented matrix supplies RREF, pivots and U, and host
inversion supplies U inverse. Every repeated factor/CSS result compares all
matrix entries and witness fields to these expected values and calls the
unchanged original public checker. Direct RREF compares the entire matrix,
pivot list and factor flag. No checksum replaces equality.

Every process includes startup, fixture/oracle setup, all declared repetitions,
result comparisons, original certificate checks and full serialization. Five
independent-process ABBA blocks give ten observations per binary per case,
120 observations per trial. Builds are native release, CPU4, `-j 1`. All heavy
commands run under the common Git-directory `tools/measure --cpu 4` lock;
`moon info` has no `-j`. The raw comparison records compiler and source/harness/
ELF hashes, affinity, every duration, payload, stdout, stderr and exit status.
The initial calibration is not comparative evidence.

## Initial result

All 120 observations passed complete output checks, but this source is not
adoptable on its initial measured performance:

| Case | Repetitions | Before ms | Initial ms | Before / initial |
| --- | ---: | ---: | ---: | ---: |
| RREF tiny 2×3 | 400,000 | 127.951 | 135.575 | 0.944 |
| RREF sparse 24×24 identity | 5,000 | 160.608 | 152.615 | 1.052 |
| RREF dense 24×24 | 2,000 | 214.308 | 215.349 | 0.995 |
| RREF wide 12×48, 20 leading zero columns | 2,000 | 105.560 | 106.495 | 0.991 |
| Dense factor + complete certificate | 400 | 249.213 | 250.176 | 0.996 |
| CSS validation + complete parameter certificate | 400 | 124.310 | 127.241 | 0.977 |

Some process durations are noisy, especially the tiny case (baseline range
123–489 ms). The all-sample median and block-ratio summaries are both retained;
neither supports claiming a general speedup. Raw:
[fused-abba.json](night-gf2-elimination-20261117-raw/fused-abba.json).

## One bounded follow-up

Generated native C shows that Option[Chain] uses a null pointer for None and
the row pointer for Some: the option itself adds no heap allocation. It also
shows that the intermediate `let tail = match basis` in the initial helper
inserts an incref/decref pair for each prefix level. This is concrete generated
code, not a measured attribution of all runtime variation. The exact excerpt
and full generated-C hash are preserved with
[initial-artifact.json](night-gf2-elimination-20261117-raw/initial-artifact.json).

The sole follow-up (`73a67ee`) pattern-matches column, row and basis together,
recursing directly on matched borrowed tails. A separate Nil-basis branch
retains the old structural result and nonzero/log behavior even for malformed
private row shapes. The producer algorithm and fixed benchmark are unchanged.
Generated C for the follow-up confirms that the ordinary Cons-tail recursive
path no longer retains/releases an intermediate tail. The Nil-basis branch
remains separate to preserve private malformed-input behavior. There was no
further variant or threshold search.

Final five-block native release comparison, complete-process medians:

| Case | Before ms | Borrowed-tail ms | Before / after | Block ratio range | Favorable blocks |
| --- | ---: | ---: | ---: | ---: | ---: |
| RREF tiny 2×3 | 120.446 | 121.512 | 0.991 | 0.985–1.031 | 1/5 |
| RREF sparse 24×24 | 140.390 | 108.690 | 1.292 | 1.232–1.300 | 5/5 |
| RREF dense 24×24 | 201.669 | 188.039 | 1.072 | 0.973–1.097 | 4/5 |
| RREF wide 12×48 | 104.887 | 97.687 | 1.074 | 1.022–1.124 | 5/5 |
| Dense factor + certificate | 233.456 | 238.384 | 0.979 | 0.922–1.031 | 2/5 |
| CSS validation + certificate | 113.799 | 111.530 | 1.020 | 0.984–1.072 | 4/5 |

All 120 follow-up observations passed complete output checks. The sparse and
wide RREF gains are consistent in all blocks. Dense RREF has one losing
block; tiny RREF and checked factorization have about 1% and 2% worse median
time respectively. Those control costs are accepted explicitly for the
established direct RREF gains. The CSS difference is small and uncertain;
there is no CSS/end-to-end speedup claim, no blanket faster claim, and no
measured whole-cohomology result for this round. Raw:
[borrowed-abba.json](night-gf2-elimination-20261117-raw/borrowed-abba.json).

These are separate baseline-paired trials; their absolute milliseconds are
not subtracted to attribute a precise cost to reference counting. The
compiler excerpts establish the removed operations, while the final paired
measurement establishes the accepted API tradeoff. No memory measurement or
universal-shape performance guarantee is implied.

## Correctness and boundaries

The new white-box suite retains the entire baseline reduction route. It
compares exact reduced/augmented rows, pivots and reverse operation logs over
32 empty, zero-width, tall/wide, sparse, dependent and dense cases, with both
tracked and untracked reduction; public factor transforms and certificates
are also checked. A separate exhaustive helper test covers every Boolean row
and basis through length five, different row/basis lengths, and columns
through the first two absent positions. It preserves old behavior when a
pivot is absent and when a true pivot produces a structurally unchanged row
against an empty/zero basis.

The existing exhaustive public binary-matrix/RHS tests, generic row-reduction
oracle and forged-certificate rejection tests remain intact. Initial scoped
GF2/cohomology/CSS suites pass 197/197 on native, JavaScript and wasm-gc, all
release with warnings denied. Initial purity passes 328 kernel files and
repository-wide deny-warn passes; `moon info` leaves GF2 public metadata
unchanged. The checker region of `kernel.mbt` and all of `solve.mbt`,
cohomology and CSS source are asserted byte-identical to baseline.

Final follow-up scoped GF2/cohomology/CSS suites again pass 197/197 on native,
JavaScript and wasm-gc. Public API info, purity (328 kernels) and repository
`moon check --deny-warn -j 1` pass. Checker-region, solve and public metadata
hashes are preserved in
[environment.json](night-gf2-elimination-20261117-raw/environment.json); command
output is in [final-validation.json](night-gf2-elimination-20261117-raw/final-validation.json).

Both 120-observation trials, all individual raw values, source manifests,
baseline/initial/final ELFs and both generated-C excerpts are preserved. Exact
ELF/source copies are handed to the root archive; artifact hashes are in
[baseline-artifact.json](night-gf2-elimination-20261117-raw/baseline-artifact.json),
[initial-artifact.json](night-gf2-elimination-20261117-raw/initial-artifact.json)
and [borrowed-artifact.json](night-gf2-elimination-20261117-raw/borrowed-artifact.json). This worker does not push, merge, deploy, edit shared indexes
or remove worktrees. The integrating root owns final integration and cleanup.
