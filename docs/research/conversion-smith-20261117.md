# Reuse Smith cokernel metadata across canonical columns

S01 tests one mechanism: prepare an immutable Smith `Cokernel` once for a
nonempty list of output columns, then pass it through the existing normalization.
The public chain helper improves on the two measured multi-column cases. The
whole simplicial and relative consumers remain unresolved; this is not a claim
that every homology computation is faster.

The baseline is `a63dcbca9a07a5c875400c4305bf2b15585b3aa3`. Candidate work started
at `8287a9e` (the same production bytes), froze the baseline-compatible CLI in
`30068c4`, and froze production plus old-helper tests in `72a75dc`. There was one
candidate and no performance follow-up. The initial local compilation exposed a
missing type context for `Nil`; that syntax fix preceded the sole measured build.

## Mechanism and preserved behavior

Only `canonical_columns` in `src/chainhomology/chainhomology.mbt` and
`src/simplicialmap/induced.mbt` change. Previously each column rebuilt the same
cokernel, including rank/invariant-factor traversals and torsion metadata. For
`c > 0` output columns the new path prepares it once, rather than `c` times.
The product and transpose still occur first. Zero output columns prepare none.
A zero-height product with nonzero width still has columns and follows the
nonempty path. The recursive tuple evaluates both the current coordinate and
the tail before deciding whether their pair is `Some`; no early return was added.
Unit, torsion, signed free-coordinate, column order, shape and `None` behavior
are preserved. No fuel, Smith core, arithmetic, or public API changes occur.

All bytes outside those two function bodies, including checker bodies, match the
baseline. `smith` and `relativehomology` source bytes also remain unchanged.
The checker dependency boundary matters: `simplicialmap.check_induced` calls its
canonical helper, and `relativehomology.check_connecting` calls the public chain
helper. Their bodies are unchanged but those calls share the optimized helper.
They are not wholly independent oracles for this mechanism. The frozen old
helpers, host small-integer product/residue oracle, and full baseline/candidate
output comparison supply additional independent checks; the underlying generic
matrix and Smith certificate operations remain unchanged.

## Frozen measurements

Pinned MoonBit native release, CPU 4, shared performance lock, serial compilation
(`-j 1`). `tools/compare_field_kernels.py` ran five ABBA blocks for each of six
cases: 120 fresh processes. Every repetition checks complete matrices or complete
certificates and the original public checker as appropriate. Each process emits
a losslessly escaped full ADT representation; all non-timing outputs matched.
Timing includes process startup, setup, the stated iterations, checks, complete
representation construction, and output. Compilation is excluded.

| Case | Iterations | Baseline median ms | Candidate median ms | Before / after | Blocks above 1 |
|---|---:|---:|---:|---:|---:|
| empty / invalid dimensions | 5,000 | 6.048 | 6.337 | 0.954× | 2/5 |
| one column, diagonal 4 | 1,000 | 3.241 | 3.083 | 1.051× | 3/5 |
| eight columns, diagonal 8 | 1,000 | 32.205 | 29.633 | 1.087× | 5/5 |
| eight columns, changed Smith/source bases | 1,000 | 16.472 | 14.277 | 1.154× | 5/5 |
| simplicial identity, four H0 generators | 40 | 7.306 | 7.086 | 1.031× | 2/5 |
| relative edge connecting map | 40 | 3.403 | 3.455 | 0.985× | 3/5 |

The stable measured benefit is confined to multi-column helper workloads. The
single-column and consumer results mix signs across blocks. Empty control median
regresses by about 4.8% in elapsed time; its blocks span 0.806–1.084×, so this
short measurement does not establish the source of that penalty. Empty inputs
still perform no cokernel preparation. The direct cases take only 3–32 ms per
process, so startup and system variation limit precision. No extra shapes,
threshold search, count changes, or second variant were tried after the freeze.

The direct fixtures use independent host integer multiplication followed by
nonnegative residues for the nonzero diagonal entries. The unit/torsion/free
patterns are `[1,2,6,0]` and `[1,1,2,2,6,6,0,0]`, including negative coefficients.
The changed-base case uses an independently inverted triangular unimodular left
basis and a changed source inverse. The actual consumers check the full
`HomologyMap` or `ConnectingMap`, known identity/oriented boundary matrices, and
invalid-degree `None`, with original checkers in every repetition. Their full
certificates are compared between the two builds, not reduced to checksums.

## Validation and provenance

Native correctness preceded initial A/B timing. Final scoped tests for
chainhomology, simplicialmap and relativehomology pass **44/44 on each of native,
wasm-gc and JS**. Native `--deny-warn`, scoped format checks and generated-interface
checks pass. Public package interface diffs are empty. The purity gate passes
333 production kernel files. New white-box tests retain the exact old helper
logic (verified identical after removing whitespace and renaming the helper),
covering changed bases, negative torsion/free coordinates, mismatched products,
wrong column heights, zero width, and zero-height/nonzero-width products. The
simplicial test also covers the projective-plane torsion fixture. Existing
certificate mutation, fuel and consumer tests continue to run.

The candidate source edit happened before root's independent baseline build had
finished; the messages crossed. No candidate library bytes were copied into the
baseline. Before timing and again after comparison, all **2,211 baseline tracked
blobs** were verified against the Git object bytes at `a63dcbc`; every byte
matched. Root additionally froze its baseline before/after build hashes. The
only baseline overlay was the three frozen CLI files from `30068c4`. Candidate
source edits, builds and comparison were performed in the separate candidate
tree; all heavy jobs used the shared lock.

[Raw and validation records](conversion-smith-20261117-raw/README.md) retain all
120 complete runs in lossless gzip, all sample values and block ratios, source
manifests, exact ELF/generated-C hashes, checker boundary hashes, baseline byte
checks and final test logs. Full source tarballs, both native ELFs and both full
generated C files are handed to root for archival before worktree cleanup.
