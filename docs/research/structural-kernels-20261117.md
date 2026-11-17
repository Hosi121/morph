# Structural kernel trials, 2026-11-17

Two independent mechanisms were bounded to one initial implementation and at
most one follow-up each. The reference is public baseline
`2e33ef5612940efa555c0a3380a0bb34190cd159`; the implementation worktree starts
from `93878f2fb57ad965e3cd73f2dd2ce1aaf2b1882d`. That workbase's numberfield
coordinate boundary does not affect either measured call path.

## Frozen comparison

`031efaf` adds the identical public-only `src/cmd/structuralbench` harness to
both source trees. It has six cases total. Native release builds and all heavy
verification run through the common Git-directory lock with
`tools/measure --cpu 4`, with Moon build/test/check `-j 1` and no `-j` on info.
`tools/compare_field_kernels.py` runs five independent-process ABBA blocks per
case (ten measurements of each binary), checks `checked=true`, compares all
non-timing output, and retains every stdout, stderr, duration, exit status,
source manifest, compiler version, harness hash, binary hash, and affinity.

The timer covers the whole process: startup, host-oracle setup, source setup,
all repetitions, producer completion checks, and an additional public
certificate check on **every** repetition. No production certificate cost is
removed, and a checksum never substitutes for complete result equality.
There is no separately claimed inner-loop timing. The initial smoke file is
pre-freeze calibration with smaller repetition counts, not comparative data.

Smith expected U/D/V use a separate mutable machine-integer implementation of
the legacy Euclidean operation schedule. Persistence expected R/V, pairings,
and bars use dense Boolean sets, a newest-first owner scan and direct simplex
face construction; neither sparse XOR nor the candidate owner map is used by
the oracle. These finite host fixtures are regression evidence, not proofs for
all inputs. Grades in the persistence fixtures are exactly simplex index / 1;
full endpoint/dimension/index fields are compared within each execution.

## Smith: direct immutable column updates

Adopted source commit: `c50caea`.

The public path `smith.run -> step -> column_swap/column_add` previously
transposed the entire matrix, performed a row operation, and transposed back.
It now traverses stored rows, reads both original column cells, and replaces
only the affected immutable row prefixes. The ordinary matrix constructor
checks the resulting shape. Both column indices are checked against retained
width before row traversal, including zero-by-n matrices. Reading both values
before replacing preserves `source == target` behavior. The state machine,
Euclidean choices, arithmetic order, fuel steps, and independent U*A*V=D and
unimodularity checker are unchanged.

The direct operation regression covers heights 0..4, widths 0..5, both indices
through the first invalid column, and factors -2, 0 and 3, against the frozen
transpose route. A second test compares complete `Status` on every step of
empty, rectangular, negative and dense examples, plus a
malformed state. The existing 625 two-square determinantal-divisor oracle and
all independent certificate rejection cases remain in place.

Final-source native release ABBA (`3674953`, with rejected persistence code
removed), milliseconds per complete process:

| Case | Repetitions | Before | Direct rows | Before / after | Block ratio range |
| --- | ---: | ---: | ---: | ---: | ---: |
| 2×2 small | 30,000 | 178.414 | 171.339 | 1.041 | 0.916–1.113 |
| 2×6 rectangular | 6,000 | 330.300 | 207.622 | 1.591 | 1.366–1.639 |
| 4×4 dense | 4,000 | 499.932 | 465.969 | 1.073 | 1.034–1.133 |

All 60 final outputs passed. All five blocks improve for the rectangle and
dense matrix; the small case has a modest median gain and one losing block,
so its benefit is less stable. Adopt the change for these call paths, chiefly
on the consistent rectangular gain. This is total API time on this CPU, not a
memory measurement or a claim about all matrix shapes. There was no second
Smith implementation trial.

The initial measurement (same Smith source, linked with the subsequently
rejected eager persistence trial) also passed all 60 outputs, with ratios
1.113, 1.620 and 1.104 and all blocks favorable. It remains historical evidence;
the final-source comparison above is the adoption result. Raw:
[smith-final-abba.json](structural-kernels-20261117-raw/smith-final-abba.json),
[initial smith-abba.json](structural-kernels-20261117-raw/smith-abba.json).

## Persistence: immutable pivot owner index

Initial source commit: `9359c7d`. The eager trial adds an AVL map from a
committed nonempty column's pivot to its shared (R column, V column). Each
active column's last entry is computed once for lookup and commit. Zero
columns have no owner. The invariant is one owner per committed pivot, with
the exact same R/V columns as the legacy newest-first scan. Public functions
and certificates are unchanged; the permitted opaque State cache and its AVL
import were regenerated with `moon info`.

The pure-list implementation repeatedly scans every old column and traverses
its last entry. AVL lookup removes that repeated search after indexing, but
AVL updates allocate paths and recompute height/count metadata. This cost is
real on collision-free and tiny inputs. Boundary construction, sparse XOR,
final R=D V checking and barcode construction are all unchanged and remain in
the timing. Their time fraction was not separately profiled.

The initial eager result fails the adoption criterion:

| Case | Repetitions | Before ms | Eager ms | Before / eager | Blocks favoring eager |
| --- | ---: | ---: | ---: | ---: | ---: |
| 2 vertices + 1 edge | 40,000 | 141.330 | 150.137 | 0.941 | 1/5 |
| 12-vertex path | 4,000 | 361.561 | 389.456 | 0.928 | 0/5 |
| Complete 7-vertex 2-skeleton | 600 | 589.769 | 571.644 | 1.032 | 3/5 |

All 60 complete certificates agree, but the controls regress by about 6–8%
and the collision case does not improve consistently. Raw:
[persistence-abba.json](structural-kernels-20261117-raw/persistence-abba.json).

The one bounded follow-up (`b2fcb3c`) constructs the AVL only at the first
actual collision. Before that it retains the legacy scan and allocates no
tree; after that it indexes existing nonempty owners once and maintains the
map on commits. This adds no algebraic operation/column-budget steps. The same
six observable State fields and exact final certificates agree with the
frozen legacy route over 230 filtrations with mixed fuel partitions. Trial
tests checked cache-owner consistency at every pause, and an intentionally
incomplete cache failed the untouched independent certificate checker.

| Case | Before ms | Lazy ms | Before / lazy | Blocks favoring lazy |
| --- | ---: | ---: | ---: | ---: |
| 2 vertices + 1 edge | 140.344 | 141.188 | 0.994 | 2/5 |
| 12-vertex path | 349.244 | 357.928 | 0.976 | 2/5 |
| Complete 7-vertex 2-skeleton | 539.776 | 542.554 | 0.995 | 2/5 |

All 60 full certificates agree, but no case has a consistent benefit. Reject
both eager and lazy indexing. Commit `3674953` restores production
`reduction.mbt`, opaque State API and `moon.pkg` byte-for-byte to the workbase. The final test
suite retains the frozen mixed-budget trace corpus and malformed suspended
state rejection; cache-only tests remain with historical trial snapshots.
There is no third trial or machine-specific threshold. Raw:
[persistence-lazy-abba.json](structural-kernels-20261117-raw/persistence-lazy-abba.json).

This result does not prove that pivot indexing can never help. The bounded
public workloads include all original certificate costs; no separate profile
established a large share for owner search. A future proposal would need an
independently justified workload where search dominates and a new explicit
experiment budget. Neither this rejected trial nor its operation-count
reduction establishes a public-API performance gain.

## Verification and limits

Initial source (Smith direct + eager AVL): native Smith 15/15 and persistence
9/9 tests pass, and combined JavaScript 24/24 and wasm-gc 24/24 tests pass, all
release with warnings denied. `moon info` confirms no Smith API change and
only the allowed opaque persistence State field/import addition. Repository
purity passes 326 kernel files, and repository-wide `moon check --deny-warn
-j 1` passes. The raw command output for those last two gates is retained in
[global-checks.json](structural-kernels-20261117-raw/global-checks.json).

The lazy trial passes native persistence 10/10 before rejection. Final
production restores the original persistence API; the independently useful
new regressions cover all 230 mixed-budget traces and two malformed suspended
states. Final native counts are Smith 15/15 (unchanged adopted source) and
persistence 9/9 (restored production plus useful regressions). Final JavaScript
24/24 and wasm-gc 24/24 pass, the purity gate again passes 326 kernels, and
repository-wide `moon check --deny-warn -j 1` passes. The final gate output is
[final-checks.json](structural-kernels-20261117-raw/final-checks.json). Production
persistence source/API/import byte identity was also asserted against the
workbase after verification.

Historical candidate code remains in Git commits; eager, lazy and final
native ELFs and exact source snapshots/manifests are retained for the
integrating agent's artifact archive. No push, merge, deployment, shared-index changes, or worktree removal
is performed by this worker.
