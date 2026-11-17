# Exact rational elimination: 2026-11-17

This pass tests one mechanism: preserve an existing immutable row when its
elimination coefficient is exactly zero. The baseline is `4d9e6c4`; the implementation
milestone is `5edf9ad226cc89a2d8d5ba1b16449c016a07c765`.

## Scope and contract

The public `linear.rref`, `linear.solve`, and `linear.inverse` APIs select the new
path. `linear.determinant` continues to use Bareiss unchanged. The public rowreduce
`Field`, `Reduction`, and `Solution` shapes remain unchanged. Existing generic
`rref`, `solve`, and `inverse` preserve their inverse-driven handling of unreduced
field values; no `Eq` bound is added.

Three explicit rowreduce entry points, `rref_with_zero`, `solve_with_zero`, and
`inverse_with_zero`, accept an exact zero predicate. These require canonical field
values and canonical field operations. QQ satisfies that condition. Its predicate
checks the exact numerator's binary magnitude without constructing an inverse.
The ordinary generic entry points remain appropriate for unreduced finite-field
representations.

Previously, elimination built a complete zipped row, multiplied every pivot cell
by zero, subtracted the zero, and allocated the resulting Chain. The zero-aware
path returns that row directly. A nonzero row reads its coefficient once, then
uses the same multiply/subtract operations as the generic path. Pivot selection,
normalization, reduction order, signed pivot products, and free-variable ordering
are unchanged. The solver's contradiction check uses the same exact predicate.

A 2x2 identity operation-count test observes 10 multiplications in the generic
path and 6 in the zero-aware path. This is a reachability check, not an end-to-end
speed claim. The proportion of total execution time spent on redundant zero-row
arithmetic was not separately profiled.

A second optimization was not pursued in this bounded pass. Existing rational
multiplication already handles unit operands cheaply; a separate normalization
policy would add another contract and benchmark axis. No fraction-free rewrite,
mutable representation, machine numeric, approximation, or certificate shortcut
was introduced.

## Correctness

`tools/generate_rational_elimination_cases.py` implements an independent Python
`Fraction` Gauss-Jordan oracle. It exhausts the alphabet `{-1/2, 0, 2/3}` over
2x2, 2x3, and 3x2 matrices: 1,539 cases. Each checks exact canonical RREF, pivot
columns, and unique/affine/inconsistent solver results. The Fraction oracle uses
ordinary row swaps rather than the implementation's recursive pivot extraction.
Each case also compares the signed pivot factor and inverse result with the
original generic path. Existing tests cover empty/zero-width matrices, invalid
RHS lengths, nonsquare inverses, singular systems, and exhaustive integer 2x2
inverse checks in both multiplication orders.

`rowreduce/zero_wbtest.mbt` verifies that zero-factor rows perform fewer field
operations and that the generic path still canonicalizes unreduced mod-5 values.
The selected test scope also exercises `chainhomology.integer_inverse`, numberfield
minimal-polynomial solving and its independent rank/annihilation checker, and
existing prime/finite/complex-field callers of the unchanged generic APIs.

All 185 selected tests passed on each of wasm-gc, JS, and native. The final
global `moon check --deny-warn` passed. The purity gate passed for all 323 kernel
files. Compiler: moon 0.1.20261104 (`940aa18`), moonc
`v0.10.20+65efd5b93` (2026-11-05).

Commands use the common performance lock and CPU 4:

```sh
tools/measure --cpu 4 tools/moon test src/linear src/rowreduce src/chainhomology src/numberfield src/primefield src/finitefield src/complexfield --target wasm-gc -j 1
tools/measure --cpu 4 tools/moon test src/linear src/rowreduce src/chainhomology src/numberfield src/primefield src/finitefield src/complexfield --target js -j 1
tools/measure --cpu 4 tools/moon test src/linear src/rowreduce src/chainhomology src/numberfield src/primefield src/finitefield src/complexfield --target native -j 1
tools/measure --cpu 4 tools/moon check --deny-warn -j 1
python3 tools/audit_purity.py
```

## Measurement protocol

`src/cmd/rationalbench` uses only public APIs available unchanged at baseline.
The exact same harness is built with baseline and final sources, native release,
one build job. The timed body includes fresh input construction, public algorithm
calls, and exact witness validation on every iteration; one warm-up is outside the
timed body. No compiler or build work occurs during timing. Baseline and final
are separate frozen native artifacts and processes. Five ABBA groups provide
10 observations per artifact and fixture; body times and process wall times are
retained separately.

Fixtures cover identity RREF, sparse inverse, dense all-nonzero RREF and inverse,
small nonintegral rectangular solving, singular rectangular RREF, certified
integral inversion via chainhomology, and numberfield minimal-polynomial search
plus its exact checker. The numberfield fixture includes normalization, field
construction, solving, and result checking. Its small elimination share can mask
local improvements and is reported as its measured upper-caller total.

The harness is frozen at:

- `main.mbt`: SHA256 `6f6b490d4d82e83c693b3eadbad4146f526d38aac1fbcf63cec0cf7f358208d7`
- `moon.pkg`: SHA256 `3a230f1ad85ebe697d969472bc5fce1965460a22434007e18e25a8e804a44594`

The frozen benchmark milestone is `2e02abe`. All 160 source-to-source process
runs reported checked, identical outputs. Raw samples and full provenance are in
[`rational-elimination-20261117.json`](../measurements/rational-elimination-20261117.json).
Baseline ELF SHA256:
`89fe49d06a7983f92088527aa54e3d8729da0d204216a79b983f7b6dd335fab1`.
Final ELF SHA256:
`7eb2846ca5270637196cead1f66ef99e2a9ad209b49743d06a83dac2dc58dc34`.
The final source manifest SHA256 is
`11eb2bdc28d700e90f1338afd0b0939196c0650ea0b5e26d0fff24cfe2913863`.

Body medians divided by the fixed iteration count (microseconds per operation):

| Public workload | Baseline us | Final us | Before / after | Five ABBA block ratio range |
| --- | ---: | ---: | ---: | ---: |
| identity-rref | 83.827 | 27.916 | 3.003 | 2.925–3.218 |
| sparse-inverse | 100.050 | 52.773 | 1.896 | 1.665–2.076 |
| dense-rref | 361.783 | 349.137 | 1.036 | 0.952–1.093 |
| dense-inverse | 3722.541 | 3766.207 | 0.988 | 0.931–1.588 |
| fractional-solve | 693.658 | 680.674 | 1.019 | 0.861–1.029 |
| singular-rectangular | 9.662 | 10.061 | 0.960 | 0.959–1.040 |
| homology-inverse | 132.932 | 83.854 | 1.585 | 1.532–1.772 |
| numberfield-minpoly | 222.628 | 221.911 | 1.003 | 0.950–1.114 |

The identity, sparse inverse, and actual homology caller improve in every ABBA
block. Dense RREF/inverse, fractional solving, singular rectangular RREF, and
numberfield minimal-polynomial totals do not establish an improvement. The
singular median is about 4.1% slower; its block ratios cross one. The dense inverse
median is about 1.2% slower; one final sample took roughly half the time of other
samples, so its entire sample range must be considered. Those observations do not
justify a universal no-regression claim.

The same-final-ELF controls for these five ambiguous workloads are recorded
separately in `rational-elimination-control-20261117.json`; the two control labels
execute exactly the same file and source. Control results and the adoption
scope are discussed below.

| Same-final-ELF control | Median label ratio | Five ABBA block ratio range |
| --- | ---: | ---: |
| dense-rref | 0.986 | 0.912–1.069 |
| dense-inverse | 1.003 | 0.989–1.031 |
| fractional-solve | 1.016 | 0.974–1.151 |
| singular-rectangular | 0.955 | 0.762–1.085 |
| numberfield-minpoly | 1.038 | 0.910–1.213 |

All 100 control runs checked successfully, with identical executable hashes for
both labels. The singular control alone produces a 4.5% apparent slowdown between
identical files. This confirms that differences at the scale of its observed
source comparison cannot establish a regression here. The controls do not prove
that those source paths have zero overhead; their performance remains unresolved.

The row-reuse mechanism is retained for its repeatable measured benefit on the
identity, sparse inverse, and actual integer-homology caller. No speedup is claimed
for the five ambiguous workloads. This is one implementation mechanism; none of
the fixture gains are multiplied or added into an overall application estimate.
The large changes in some absolute samples limit claims beyond the robust
within-block sparse gains. Other hardware, larger dense inputs, allocator memory
usage, and whole applications are unmeasured.

The benchmark driver is `tools/compare_field_kernels.py` (root integration owns
that shared helper). The source comparison was run as:

```sh
tools/measure --cpu 4 python3 /home/hosi/morph/tools/compare_field_kernels.py \
  --before /home/hosi/morph-perf-baseline/_build/native/release/build/cmd/rationalbench/rationalbench.exe \
  --after /home/hosi/morph-perf-rational/_build/native/release/build/cmd/rationalbench/rationalbench.exe \
  --before-root /home/hosi/morph-perf-baseline \
  --after-root /home/hosi/morph-perf-rational \
  --harness src/cmd/rationalbench \
  --case identity-rref --case sparse-inverse --case dense-rref \
  --case dense-inverse --case fractional-solve --case singular-rectangular \
  --case homology-inverse --case numberfield-minpoly \
  --groups 5 --output docs/measurements/rational-elimination-20261117.json
```

The control uses the same command with both artifact/root arguments pointing to
the final source/artifact and the five ambiguous fixture names. Every raw sample,
normalized result, process duration, body duration, hash, source manifest, compiler
version, CPU affinity, and command-equivalent argument set is preserved in the two
JSON reports. Build commands were `tools/measure --cpu 4 tools/moon build --target
native --release -j 1 src/cmd/rationalbench` in each source tree. No push, PR, merge,
or deployment was performed by this worker. The temporary duplicate baseline
worktree created at the start was removed without changes; the shared baseline
and retained artifacts are owned by root integration.
