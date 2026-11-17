# Prepared coefficient columns for nullspace, 2026-11-17

Reject candidate `7544b65`. Restore production to unified baseline
`905d23dc1a098359c28b4d9d7914c38d9a797c34` in `c64fa04`; no layout helper or
Factorization cache remains. Frozen public CLI: `7b097be`. This was one trial
with no follow-up, larger-case search or empirical threshold.

The round-one monotone pivot walk still called `nth(row, free_column)` for
each pivot/free-variable coefficient. The trial prepared all source-width
coefficient columns once using the frozen private `product_columns`, then
merged those columns with ascending free indices and emitted each vector
with aligned pivot/coefficient cursors. It reused the existing index chain,
returned before preparation when there were no free variables, and retained
the direct unit-vector route at rank zero. Preparation stopped at source
width, explicitly excluding a consistent augmented solve's RHS. No eager
opaque-Factorization cache, public API, reduction/product/checker or
cohomology algorithm change was introduced.

The canonical RREF rows and sorted pivot invariants are existing internal
contracts of factor/solve. The full ordered basis remains identical. Native
candidate GF2/cohomology tests passed 194/194 before comparison, including the
frozen old row-nth route, larger rank/sparsity boundaries and all Boolean
systems through two rows/three variables with every RHS. Existing exhaustive
public tests and independent indexed-Boolean CLI RREF/solve oracles remain.

Five native release ABBA blocks use six identical public process cases. Each
repeated basis compares every coefficient and its ascending order with the
host oracle; complete factor matrices, transforms, inverses and pivots are
checked. The actual torus cohomology consumer compares complete Group and
certificate fields and calls its original result checker on every repetition.
All original producer completion checks remain included. Every one of the
120 processes passed full output checks; a checksum does not replace equality.

All heavy jobs use shared `tools/measure --cpu 4` locking, separate build
trees and compiler `-j 1`; info has no `-j`. Baseline library files remain
unchanged. Whole-process time includes startup, fixtures/oracles, setup,
per-call layout preparation, operations, original checks and output.

| Public case | Repetitions | Baseline ms | Prepared ms | Before / after | Favorable blocks |
| --- | ---: | ---: | ---: | ---: | ---: |
| Tiny rank-one 1×3 | 500,000 | 96.825 | 152.988 | 0.633 | 0/5 |
| Sparse/gapped rank-eight 8×32 | 2,000 | 75.348 | 83.085 | 0.907 | 0/5 |
| Dense rank-sixteen 16×32 | 2,000 | 66.450 | 83.462 | 0.796 | 0/5 |
| Full-rank 16×16, no free variables | 30,000 | 32.108 | 33.260 | 0.965 | 1/5 |
| Rank-zero 8×16 | 10,000 | 62.101 | 61.953 | 1.002 | 2/5 |
| Torus cohomology + full checks | 200 | 255.571 | 267.714 | 0.955 | 0/5 |

The lookup-heavy tiny/sparse/dense cases and actual consumer lose in every
block. Tiny elapsed time rises about 58%, sparse about 10%, dense about 26%
and torus about 5%. Rank-zero is noisy/neutral. Even the no-free path shows a
small negative control difference. There is no measured profitable path for
a general rank/free guard to retain, so no follow-up was warranted.

Preparing O(rank×width) column cells also requires temporary peel/tail list
structure. At these measured sizes that representation fails to amortize its
cost against repeated traversal of existing immutable rows. No allocation
profile or isolated instruction attribution was run; bookkeeping and compiled
layout can also affect controls, so timings do not assign exact cost shares.
No larger-size, persistent-cache, memory or universal-performance claim is
made. The original direct row-nth producer remains in use.

The existing GF2 checker still shares the previously adopted Boolean product;
that dependency is unchanged in this round. Kernel/product/checker and
cohomology source stayed byte-identical during the trial. After rejection,
solve and regenerated public metadata are byte-identical to baseline too.
Restored production plus the retained regression tests passes 194/194 on each
of native, JavaScript and wasm-gc; scoped fmt/check/info and the solve purity
scan pass. These final cross-target checks apply to the restored source, not
the discarded coefficient-layout helper. Broader final checks belong to root.
[validation.json](late-basis-20261117-raw/validation.json) retains command
output and restoration assertions.

All individual values, full outputs, compiler/affinity/source/harness/ELF
provenance and block ratios are losslessly retained in
[prepared-abba.json.gz](late-basis-20261117-raw/prepared-abba.json.gz).
[summary.json](late-basis-20261117-raw/summary.json) is readable;
[artifacts.json](late-basis-20261117-raw/artifacts.json) records compressed and
uncompressed SHA-256/byte counts and artifact hashes. Gzip decompression was
verified byte-for-byte before removing the duplicate raw JSON.

[candidate.patch.gz](late-basis-20261117-raw/candidate.patch.gz) reproduces the full
trial source/harness/test change from clean baseline `905d23d`; it is
historical evidence and is not for production adoption.
[retained-tests.patch](late-basis-20261117-raw/retained-tests.patch) adds only
the useful old-nth/augmented-RHS regression tests for evidence-only integration.
Both native ELFs, exact source snapshots and full generated C are handed to
the root archive. Root owns integration, broader regression, push and cleanup;
this worker makes no main/shared-index changes or worktree removals.
