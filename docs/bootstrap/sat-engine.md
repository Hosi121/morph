# SAT engine bootstrap

## Scan CDCL milestone

Historical first milestone: commit `e52f521`. The current `start` selects the
watched engine described below; `start_scanning` retains this milestone.

`src/cdcl` adds an independent immutable CDCL solver over the existing
`@sat.Cnf`, `@sat.Literal`, and `@sat.Model` boundary. It uses first UIP
resolution, learned clauses, and nonchronological backjumping. The first
milestone deliberately scans the clause database for propagation. It does not
yet have watched literals or a branching activity heuristic.

Public entry points:

```text
start(Cnf) -> Search
run(Search, Nat) -> Status
run_measured(Search, Nat) -> (Status, Statistics)
statistics(Search) -> Statistics
check_refutation(Cnf, Proof) -> Bool
Status = Satisfiable(Model) | Unsatisfiable(Proof) | Paused(Search)
       | InvariantViolation
Proof = Rup(Chain[Clause])
```

`Search` is a persistent continuation. A fuel unit charges one decision,
propagation, conflict analysis/backjump, or terminal transition. Input
normalization and recursive traversals within a transition are finite but not
separately fuel bounded. A caller requiring a wall-clock interruption bound
cannot infer one from this fuel counter.

Input clauses are deduplicated and tautologies discarded. Variable identities
are converted from unary `Nat` to cached `Binary` keys once at entry. Returned
models also assign variables occurring only in discarded tautologies, because
the existing partial-model checker requires an explicit satisfied literal in
each input clause. Assignments are currently looked up by a linear trail scan.

The proof is the ordered list of learned RUP clauses and a final empty clause.
For every addition, the checker assumes the negation of its literals and runs
deterministic unit propagation over the input plus earlier additions. It does
not call the solver, make decisions, or perform conflict analysis. It rejects
missing final empty clauses and non-RUP additions. Repeated valid lemmas and
tautological lemmas are sound and accepted. This milestone's checker used the
same clause normalization and unit-status evaluator as the solver; its search
and conflict-analysis logic are independent, but this is not an independently
implemented trusted kernel or a formal soundness proof. The current checker is
separated further in the indexed-checker milestone below.

Validation on MoonBit v0.10.20, native, JavaScript, and Wasm GC:

- All 19,683 ordered triples of the 27 non-tautological three-variable clauses,
  compared with truth-table enumeration and the old DPLL, including model and
  proof checks.
- All 256 subsets of the eight full three-variable clauses.
- 3,000 deterministic four-variable formulas with 12 clauses, compared with
  both independent outcomes.
- Duplicate literals, tautologies, empty formulas/clauses, and sparse variable
  IDs; resumed execution and continuation persistence; forged and truncated
  certificates.
- An explicit satisfiable formula whose first UIP backjump skips an irrelevant
  decision level.
- Pigeonhole refutations for two through five pigeons into one through four
  holes, with RUP checks. Five into four uses 355 transitions, 29 decisions,
  296 propagations, and 30 conflicts, adding 29 learned clauses.

These are finite checks, not a proof for all CNFs. `tools/audit_purity.py` passes:
the production package contains no machine numerics, mutation, arrays, or FFI.

## First measurements

Command: `tools/moon bench src/cdcl --target native --release`.
Both solvers receive the same prebuilt external CNF. CDCL includes `start`,
normalization, and proof production; DPLL includes its proof production.
Certificate validation and CNF fixture construction are outside the timed
closures. Fuel is prebuilt and sufficient for these inputs.

| Input | Old DPLL | Scan CDCL |
| --- | ---: | ---: |
| Pigeonhole 5 into 4 | 734.04 µs ± 31.26 µs | 2.54 ms ± 98.98 µs |
| Pigeonhole 6 into 5 | 8.25 ms ± 2.02 ms | 44.63 ms ± 3.27 ms |

Each value is the MoonBit benchmark runner's mean and standard deviation over
ten samples. These measurements give no speedup claim: scan CDCL is slower on
both small inputs. The next comparison should retain this scan implementation
as well as old DPLL while adding an immutable watch index and faster assignment
lookup. Larger circuit miters are needed before choosing a default engine.

No push or deployment is part of this work.

## Watched-literal milestone

The current `start` adds two watched literals per non-unit clause, an immutable
watch-bucket index, and an indexed assignment map. All three indices are
persistent tries over structural Bool words: clause ID to watch state, signed
variable key to watching clause IDs, and variable key to assignment. Pending
assignments and an unfinished bucket traversal remain inside `Search` when the
fuel runs out. `start_scanning` retains the earlier implementation for direct
comparisons. The external CNF, model, proof, and status types are unchanged.

A learned clause watches its asserting literal and a highest-level remaining
literal. Backjumping preserves valid watch moves, clears propagation work from
the abandoned decision level, rebuilds the surviving assignment index, and
enqueues the asserting literal. Decisions still scan clauses, and conflict
analysis still searches the reverse trail. There is no activity heuristic,
restart policy, or learned-clause deletion.

At this milestone, propagation quiescence scanned the entire database for a
decision and reported `InvariantViolation` for a missed unit or false clause.
The later first-open optimization below retains that full diagnostic in tests.
White-box tests additionally check both directions of watch membership, absence
of duplicate bucket membership, assignment-index correspondence to the trail,
and the unit justification of every stored implication. These checks run after
every single-transition pause for pigeonhole families through six into five and
1,000 six-variable three-SAT formulas. The latter formulas are also compared
with truth tables, scan CDCL, and old DPLL. All earlier small-CNF checks now run
both CDCL engines. The package has eleven tests passing native, JS, and Wasm GC.

Same-process native release comparison, Intel Core Ultra 7 255H under WSL2,
MoonBit v0.10.20; benchmark scope is the same as the first measurements:

| Input | Old DPLL | Scan CDCL | Watched CDCL |
| --- | ---: | ---: | ---: |
| Pigeonhole 5 into 4 | 812.81 µs ± 93.15 µs | 2.82 ms ± 554.14 µs | 1.14 ms ± 98.71 µs |
| Pigeonhole 6 into 5 | 7.56 ms ± 737.68 µs | 44.53 ms ± 3.39 ms | 12.72 ms ± 616.95 µs |

The watched version is faster than scan CDCL on these inputs but still slower
than old DPLL. Propagation ordering also changes: five into four now takes 267
transitions, 24 decisions, 221 propagations, 22 conflicts, 21 learned clauses,
and three nonchronological backjumps. Consequently the timings measure the
whole engine change, rather than isolating the index's cost on an identical
search trace. These tiny pigeonhole inputs do not establish performance on
larger circuit-equivalence problems.

## Startup diagnosis before changing key conversion

The propagation-only contradiction `[v0]`, `[¬vi, v(i+1)]` for 256 links,
`[¬v256]` gives a different cost profile. The complete watched solve took
15.75 ms ± 643.70 µs, old DPLL 18.94 ms ± 1.15 ms, and scan CDCL
72.42 ms ± 1.38 ms. Startup alone took 15.39 ms ± 227.78 µs. Separate
stage benchmarks then measured:

| Stage | Native release time |
| --- | ---: |
| Database normalization | 7.36 ms ± 324.66 µs |
| Variable collection | 7.45 ms ± 228.54 µs |
| Watch-index construction, normalized database prebuilt | 189.65 µs ± 7.58 µs |
| Watched search, complete initial state prebuilt | 171.56 µs ± 12.68 µs |
| Atom/key conversion over every input literal occurrence | 7.81 ms ± 252.52 µs |

These are separate benchmark closures rather than an additive in-process
profiler, but identify repeated unary-to-binary conversion as the dominant
startup operation. Renaming the twenty variables in the five-into-four input
by adding 1024 changes watched startup from 124.83 µs ± 9.36 µs to
33.85 ms ± 703.71 µs, without changing its Boolean problem. The old
`@binary.from_nat` recursively calls general addition at every unary successor.
The unchanged scanning RUP checker takes 63.00 ms ± 2.29 ms on the chain.

A private, test-only candidate structurally halves the unary number, records
the remainder as a Bool bit, and recursively converts the quotient. It agrees
with the old conversion for every ID from zero through 2048 and with the numeric
test oracle at 4095, 4096, 4097, 10000, and 16384. In a direct same-run comparison
on all chain literal occurrences, the old conversion measured
7.46 ms ± 298.98 µs and the candidate 513.90 µs ± 20.89 µs. This candidate
was not adopted into `atom` at this stage: the root task was also improving the
shared Binary increment/conversion, which needed comparison before selection.

Reproduction commands:

```sh
tools/moon bench src/cdcl/bench_test.mbt --target native --release
tools/moon bench src/cdcl/stages_wbtest.mbt --target native --release
```

## Independent indexed RUP checker

The current checker has its own clause evaluator and unit-propagation loop,
with an immutable `Index[Bool]` assignment map. It does not use the solver's
clause evaluator, watch states, propagation queue, decision selection, trail,
reasons, or conflict analysis. It shares the generic key/index functions and
input clause normalization. The previous scan checker is retained only in
white-box tests as an additional differential oracle.

All 19,683 combinations of two three-variable clauses and one candidate RUP
lemma agree between the two checkers. Every accepted lemma also passes a
truth-table entailment check. Another 1,458 ordered two-lemma-plus-empty
certificates over satisfiable and unsatisfiable three-variable cubes agree
between checkers; accepted complete certificates are truth-table unsatisfiable.
Every generated proof in the existing exhaustive solver comparison is checked
by both implementations. Fourteen package tests pass native, JS, and Wasm GC.

On the same prebuilt 256-link-chain certificate, native release comparison:

| Checker | Mean ± standard deviation |
| --- | ---: |
| Previous trail-scanning checker | 62.06 ms ± 2.30 ms |
| Independent indexed checker | 8.80 ms ± 536.43 µs |

This reduces checker cost on that input while leaving the certificate format
and checked property unchanged. Input key conversion still accounts for most
of the new checker's time. No learned-proof compression or external proof
format has been introduced.

## Ripple-adder miter integration

The root task's `@circuit.adder_miter(width, Propagate, Multiplexer)` supplies
the same external Tseitin CNF to all engines. The two implementations retain
the final carry, and the asserted miter asks whether any output bit differs.
Watched CDCL refutes widths 2, 4, 8, and 16 within a 20,000-transition budget;
every resulting RUP certificate passes the independent checker. These are
specific finite-width certificates, not an arbitrary-width equivalence theorem.

| Width | Gates | CNF clauses | Transitions | Decisions | Conflicts | Learned |
| --- | ---: | ---: | ---: | ---: | ---: | ---: |
| 2 | 15 | 54 | 145 | 15 | 15 | 14 |
| 4 | 33 | 118 | 382 | 30 | 27 | 26 |
| 8 | 69 | 246 | 1,040 | 84 | 58 | 57 |
| 16 | 141 | 502 | 2,680 | 252 | 118 | 117 |

Same-run native release benchmark for the prebuilt **width-four** miter,
including CDCL startup and each solver's proof production, excluding circuit
construction and certificate checking:

| Engine | Mean ± standard deviation |
| --- | ---: |
| Old DPLL | 85.18 ms ± 1.82 ms |
| Scan CDCL | 9.87 ms ± 491.62 µs |
| Watched CDCL | 2.49 ms ± 55.13 µs |

The watched engine is about 34 times faster than old DPLL on this input. The
pigeonhole results above favor old DPLL, so this is a workload-specific result.
No larger-width DPLL timing is inferred from it.

Separate **width-sixteen** stage benchmarks:

| Stage | Mean ± standard deviation |
| --- | ---: |
| Circuit construction and Tseitin compilation | 383.49 µs ± 6.17 µs |
| Watched startup on prebuilt CNF | 24.75 ms ± 652.44 µs |
| Watched search on prebuilt continuation | 29.09 ms ± 540.28 µs |
| Independent RUP checker on prebuilt certificate | 92.72 ms ± 876.57 µs |

The single-transition watch-invariant tests now also check each newly learned
clause immediately with both RUP evaluators, including learned clauses from
eventually satisfiable runs.

## Clause-count stack regression

A separate JavaScript failure was reproduced without large variable IDs:
20,000 identical positive unit clauses overflowed the call stack in recursive
database construction. After that construction was repaired, 20,000 identical
binary clauses overflowed the decision scan while all clauses were open.

Database construction now folds into a reversed accumulator and restores input
order once. Both engine decision scans carry the first candidate through a tail
recursive traversal, preserving the previous unit/conflict priority and branch
order. The regression covers satisfiable repeated units, opposite units with a
checked RUP refutation, and repeated binary clauses for both scan and watched
engines. It passes native, JS, and Wasm GC. Existing miter and search-statistics
snapshots remain unchanged. This addresses stack growth with CNF clause count;
it does not establish a resource bound for every nested input representation.

## Structural key conversion selection

After the root's shared Binary improvement (`c379435`), direct same-run atom
conversion over the 256-link chain measured 1.38 ms ± 32.07 µs for the shared
tail-recursive `from_nat`, against 506.00 µs ± 14.96 µs for structural halving.
The private `binary_key` implementation is therefore now used by CDCL input
conversion. The shared Binary package remains unchanged by this task, and the
stage benchmark retains both conversion candidates.

The private conversion removes pairs of unary successors to form a quotient,
emits the Bool remainder, and recurses on that quotient. Quotient construction
is tail recursive, and bit construction recurses with logarithmic depth. It
agrees with the shared conversion on all IDs through 2048 and with independent
integer-built Binary values at the larger test IDs listed above. A new end-to-end
regression checks both a satisfiable model and an unsatisfiable certificate with
source variable ID 65535 on all three backends.

Native release before/after, both after the root Binary improvement:

| Stage | Shared converter | Private halving converter |
| --- | ---: | ---: |
| Chain 256 normalization | 1.42 ms ± 33.79 µs | 546.70 µs ± 19.80 µs |
| Chain 256 variable collection | 1.71 ms ± 57.26 µs | 814.74 µs ± 23.60 µs |
| Chain 256 indexed certificate checker | 2.85 ms ± 72.37 µs | 1.92 ms ± 31.05 µs |
| Width-16 miter startup | 6.10 ms ± 411.15 µs | 2.99 ms ± 294.69 µs |
| Width-16 search without startup | 28.68 ms ± 567.17 µs | 29.64 ms ± 1.16 ms |
| Width-16 certificate checker | 74.11 ms ± 1.11 ms | 72.00 ms ± 1.65 ms |

The startup benefit is clear on these inputs; search is unchanged by design and
its measurements overlap. The larger certificate-checker difference is small
relative to variation, so the adoption is based on startup and direct conversion
results. This does not make the full width-16 check twice as fast.

A separate equality microbenchmark over 16,384 normalized key pairs measured
ordering equality at 339.59 µs ± 29.54 µs and structural `Eq` at
315.43 µs ± 14.46 µs. That small, overlapping result did not justify changing
production key equality.

## 32- and 64-bit scaling checkpoint

Native release benchmarks after the shared Binary and private key changes
checked every measured miter's certificate before timing. The larger benchmark
uses an explicit 200,000-transition budget, outside the timed closure.

| Width | Clauses | Transitions | Decisions | Conflicts | Learned | Solve including start | RUP checker |
| --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| 32 | 1,014 | 7,304 | 876 | 238 | 237 | 198.27 ms ± 4.64 ms | 463.73 ms ± 15.68 ms |
| 64 | 2,038 | 21,928 | 3,276 | 478 | 477 | 1.61 s ± 22.96 ms | 3.66 s ± 126.85 ms |

These means and standard deviations use ten single-run samples per case. CNF
generation and the correctness check are outside the solve timing; the checker
timing receives the same prebuilt certificate on every sample. The environment
was the same WSL2/native toolchain above, without CPU pinning. The growth shows
that propagation/decision scans and repeated RUP propagation remain material
costs after input conversion; no linear-scaling claim is made.

The larger cases are benchmark tests, so ordinary `moon test` does not repeat
these measurements. Reproduce with:

```sh
tools/moon bench src/cdcl/scaling_test.mbt --target native --release
```

A separate ordinary regression builds a wrong 32-bit adder by replacing its
initial carry with false. The solver returns a SAT model, the old CNF model
checker accepts it, projection to source variables succeeds, the source miter
re-evaluates to true, and the projected initial carry is true. This covers a
larger counterexample path as well as the larger UNSAT certificate path.

## Shared conversion cleanup

Root commit `e717649` moved structural halving into the shared
`@binary.from_nat`. CDCL's production `binary_key` now delegates to that
function, removing its duplicate halving implementation. The original private
prototype remains only in white-box tests and the conversion benchmark. The
key tests now compare both implementations with the numeric test oracle rather
than describing the shared implementation as repeated increment.

After delegation, a same-run direct comparison on all chain-256 occurrences
measured shared conversion at 522.58 µs ± 20.64 µs and the retained private
prototype at 518.57 µs ± 21.43 µs. These measurements overlap. Width-16 startup
measured 2.58 ms ± 111.62 µs, search 29.78 ms ± 1.63 ms, and certificate checking
73.21 ms ± 2.46 ms. No performance regression was detected relative to the
private implementation's checkpoint above. All normalization, model/proof,
large-ID, resumption, and trace-statistics tests are retained.

## Indexed-value candidate retained only as an experiment

A polarity-only lookup prototype avoids comparing the Binary key a second time
after the assignment trie has already found it. On 256 assigned queries the
same-run microbenchmark measured the existing lookup at 6.40 µs ± 373.06 ns and
the prototype at 4.28 µs ± 161.57 ns. The prototype agrees on assigned positive,
assigned negative, and absent-variable values in the test fixture.

However, temporarily using it in the complete width-16 engine gave search time
29.55 ms ± 1.91 ms, compared with the preceding 29.78 ms ± 1.63 ms. The unchanged
certificate checker measured 72.48 ms ± 2.47 ms. An engine-level improvement was
not established, so production lookup remains unchanged. The test-only prototype
and microbenchmark remain available for a later profile-led investigation.

## Native CDCL phase profile

The environment has no `perf` executable. A test-only sampler therefore times
`watch_inspect` and `transition` separately with the native monotonic clock,
classifies every transition, and checks the resulting proof with `ruplog`.
No clocks or mutable counters enter production code.

One CPU-10-pinned instrumented 64-bit miter run, before the next optimization:

| Transition kind | Count | Inspection | Transition handling |
| --- | ---: | ---: | ---: |
| Propagation | 18,174 | 56.15 ms | 15.36 ms |
| Decision | 3,276 | 1,403.31 ms | 8.54 ms |
| Conflict | 478 | 1.12 ms | 269.05 ms |

The decision inspection accounts for about 80% of this sampled run. It scans
the entire database to diagnose a unit clause missed by the watch index, even
after finding the first open clause. A correct quiescent watch index already
guarantees no pending unit/conflict. This identifies the full diagnostic scan
as the first candidate, ahead of conflict-analysis trail lookup.

The separate uninstrumented search benchmark measured 2.83 s ± 657.11 ms over
ten runs, range 1.85–3.40 s. The instrumented breakdown is one observation,
not a statistical timing claim. The next comparison will retain the full
diagnostic helper in the same executable and validate quiescent fast decisions
against it in white-box tests.

```sh
taskset -c 10 tools/moon bench src/cdcl/profile_wbtest.mbt --target native --release -i 1
```

## Stop decision inspection at the first open clause

The normal watched engine now scans the satisfied prefix and stops at the first
open clause after its propagation queue and active watch bucket are exhausted.
The earlier full-database diagnostic remains as `watch_decision_checked` and
can be selected in the same executable. A correct quiescent watch index excludes
pending units and conflicts; the optimization uses that invariant. It still
reports an unexpected unit/conflict in the inspected prefix. Detection beyond
the selected open clause is performed by the full white-box diagnostic.

The existing per-transition invariant families additionally compare every fast
quiescent candidate with the full diagnostic. A separate pigeonhole regression
compares the complete `Status`, including every immutable paused `Search`,
between both modes and the public one-transition runner. On the 64-bit miter,
both modes return the exact same complete proof, and the independent hinted
checker accepts it. Original decisions, learned clauses, and backjump behavior
are preserved.

CPU 10, native release, shared Binary fixed at `e717649`, same ELF for both
selectors, ten samples per case under the repository measurement mutex:

| Mode | Mean ± standard deviation | Range |
| --- | ---: | ---: |
| Full quiescence diagnostic | 3.60 s ± 80.40 ms | 3.46–3.70 s |
| First open clause | 862.97 ms ± 25.49 ms | 807.61–886.28 ms |

The test-only deterministic counter records 3,276 decisions, with 7,663,873
clause inspections for the full diagnostic and 680,556 for the first-open
prefix. These counts establish an 11.26-fold reduction in decision clause
visits; the measured complete search is about 4.17 times faster in this run.
The timed closures include search from the same prepared initial state and
prebuilt 200,000-transition fuel, excluding CNF generation, startup, and proof
checking. Proof equality, work counting, and hinted checking occur before the
timing. This does not estimate the speedup of the complete query pipeline.
Host scheduling and CPU-frequency variation remain possible; older unpaired
measurements above must not be compared as if they used these conditions.

The same batch passes all 21 CDCL tests on native, JS, and Wasm GC and the
73-file purity gate. The benchmark ELF SHA-256 was
`55d511a79432d5a39f1759323e69a6f3f0c853920ce5a86b86170b7553d8cf74`.

```sh
/home/hosi/morph/tools/measure --cpu 10 tools/moon bench src/cdcl/profile_wbtest.mbt --target native --release -i 3
```

## Phase profile after first-open decisions

With the first-open decision mode, the next CPU-10/mutex sample was:

| Transition kind | Count | Inspection | Transition handling |
| --- | ---: | ---: | ---: |
| Propagation | 18,174 | 93.99 ms | 28.37 ms |
| Decision | 3,276 | 206.23 ms | 8.94 ms |
| Conflict | 478 | 1.67 ms | 508.81 ms |

Conflict handling is now about 60% of this instrumented observation. The
uninstrumented search measured 947.56 ms ± 45.85 ms, range 894.80 ms–1.03 s.
An unchanged prepared hinted-checker control on the resulting certificate
measured 43.57 ms ± 3.03 ms, range 40.33–49.87 ms. These are ten samples, with
three checker calls per sample. The source has not yet changed shared Binary
from `e717649`; the different absolute phase times above are separate runs and
must not be interpreted as the before/after comparison by themselves.

The next experiment separates two conflict costs: linear reverse-trail
assignment lookup versus the already maintained assignment trie, and recounting
the unchanged conflict clause while skipping irrelevant trail entries versus
recounting only after resolving a pivot. Both operations preserve assignments,
resolution order, and the learned clause; the comparison checks those claims
against the complete resumable state and proof.

## Reuse the assignment trie during conflict analysis

Conflict analysis now obtains assignments from the watched engine's existing
persistent trie. Scan mode keeps reverse-trail lookup. The same lookup callback
is passed to conflict-level selection, current-level counting, first-UIP
resolution, asserting-literal selection, and backjump-level selection. No
assignment index is rebuilt for analysis. Normalization, resolution order,
learned clauses, and the public API are unchanged.

A separate candidate avoids recounting an unchanged clause when scanning past
an irrelevant trail entry. It remains a private selectable ablation. The normal
engine keeps the original recounting algorithm because a complete-search gain
for that candidate was not established.

The four modes below used one native release ELF, CPU 10, the measurement mutex,
the same prepared 64-bit miter and 200,000-transition budget, and shared Binary
`e717649`. Ten samples per case:

| Assignment lookup | Clause count policy | Mean ± standard deviation | Range |
| --- | --- | ---: | ---: |
| Reverse trail | Recount on every visited entry | 950.83 ms ± 52.89 ms | 878.61 ms–1.02 s |
| Existing trie | Recount on every visited entry | 517.81 ms ± 27.17 ms | 482.41–558.07 ms |
| Reverse trail | Recount only after a resolved pivot | 927.72 ms ± 46.36 ms | 870.64 ms–1.03 s |
| Existing trie | Recount only after a resolved pivot | 535.63 ms ± 27.59 ms | 504.00–586.40 ms |

The lookup change improves complete search in this comparison; the count-policy
intervals overlap and do not establish an additional improvement. The baseline
uses the same callback interface as the indexed path. The immutable initial
state, proof checking, work counters, CNF generation, and startup are outside
the timed closures.

Deterministic work counters cover analysis lookup, excluding learned-watch
selection and final SAT model construction:

| Count policy | Queries | Reverse-trail entries examined | Trie nodes examined |
| --- | ---: | ---: | ---: |
| Original recount | 79,907 | 9,483,200 | 821,337 |
| Pivot-only recount | 66,694 | 8,556,638 | 687,648 |

Every counted query compares the actual trail and trie results. All four modes
return the exact same final `Status` and `Statistics`, including the complete
proof, on the 64-bit miter. A separate regression compares all four complete
paused states and final statistics at every transition of pigeonhole 4/3 and a
four-bit miter. The independent hinted checker accepts the shared proof.

The unchanged prepared hinted-checker control measured 43.37 ms ± 3.93 ms,
range 37.18–49.39 ms, compared with the immediately preceding 43.57 ms ±
3.03 ms. The benchmark invocation, including untimed setup and counters, used
38.91 s elapsed, 39.51 s user, and 0.05 s system time. This aggregate process
control does not remove CPU-frequency variation or provide per-case CPU time.
The four-mode ELF SHA-256 was
`5025dca38ed19fbc333752a4b2e965e4f2e96468d43988bb9df8db80aba1d639`.

```sh
/home/hosi/morph/tools/measure --cpu 10 tools/moon bench src/cdcl/analysis_wbtest.mbt --target native --release -i 1
```

## Complete hinted-query comparison

The complete pipeline benchmark uses one native release executable and the same
prebuilt 64-bit miter for all three selectors. It includes solver startup,
search, RUP-to-hinted-certificate building, and independent hinted checking.
`ruplog.prepare` is shared by the builder and checker inside each query. CNF
generation and the prebuilt 200,000-transition fuel are outside timing. Every
selector returns identical final statistics and proof before timing.

CPU 10, shared measurement mutex, shared Binary still `e717649`, ten samples:

| Query mode | Mean ± standard deviation | Range |
| --- | ---: | ---: |
| Full decision diagnostic, reverse-trail analysis | 4.39 s ± 136.69 ms | 4.18–4.55 s |
| First-open decision, reverse-trail analysis | 1.34 s ± 55.33 ms | 1.28–1.43 s |
| First-open decision, indexed analysis | 825.91 ms ± 18.90 ms | 789.86–850.90 ms |

The combined changes improve this complete query by about 5.31 times in this
run. The result applies to this formula family, not all SAT inputs. Unchanged
controls in the same executable measured solver startup at 78.11 ms ± 4.31 ms,
prepared hinted building at 168.58 ms ± 6.42 ms, and prepared hinted checking at
44.41 ms ± 2.59 ms. Their ranges were 73.24–85.83 ms, 157.60–176.43 ms, and
40.93–48.62 ms respectively. The full benchmark invocation used 86.25 s elapsed,
86.43 s user, and 0.05 s system time, including correctness setup and controls.

The next phase sample with indexed analysis recorded 84.45 ms propagation
inspection, 192.80 ms decision inspection, and 150.54 ms conflict handling.
Uninstrumented search measured 513.19 ms ± 34.92 ms, range 482.52–583.69 ms;
the unchanged prepared checker control was 43.51 ms ± 1.43 ms. This profile
identifies decision evaluation and residual conflict work as the next costs;
it does not support treating every source-level operation reduction as a
complete-query improvement.

After both changes, freshly generated certificates again passed both pinned
LRAT-TRIM and DRAT-trim for all 16 positive exports, and all seven negative
controls were rejected. The 64-bit occurrence certificate still has 478
additions and 21,132 hints. Its CNF and erased DRUP hashes remain exactly the
pre-optimization hashes recorded in `ruplog.md`:

- CNF: `81791c0eaf39a0faa927490662747272f98213455eb61fa011dd30ef303184b8`
- DRUP: `17d3c80302c403309b2a5a6159d3ea7ebc443fccbc3df24219474f06ff88f7ec`

```sh
/home/hosi/morph/tools/measure --cpu 10 tools/moon bench src/cdcl/pipeline_wbtest.mbt --target native --release
/home/hosi/morph/tools/measure --cpu 10 python3 tools/generate_ruplog.py --check --miter64 --cpu 10
```

## Direct decision-value lookup remains an experiment

The polarity-only value lookup considered earlier was re-evaluated after the
larger scan and analysis costs were removed. This experiment changes only
quiescent decision evaluation. Propagation and replacement retain their
existing value checks. The trie path already establishes variable identity;
its candidate reads the assigned polarity directly.

A deterministic 64-bit count records 1,413,663 decision literal queries,
including 1,073,212 assigned queries where the original helper also compares
the already matched Binary key. Both versions return identical complete final
statistics/proof and all paused states in the transition regressions. The
independent hinted checker accepts the shared proof.

One CPU-10/mutex/native release executable, ten samples per ABBA block:

| Search block | Mean ± standard deviation | Range |
| --- | ---: | ---: |
| Key verification, first control | 532.03 ms ± 30.89 ms | 488.84–571.97 ms |
| Direct polarity | 482.85 ms ± 20.70 ms | 453.73–505.89 ms |
| Direct polarity, repeated control | 480.64 ms ± 18.28 ms | 459.34–510.04 ms |
| Key verification, repeated control | 570.44 ms ± 50.60 ms | 499.72–654.83 ms |

The unchanged prepared checker control was 43.55 ms ± 2.96 ms. The process used
25.77 s elapsed, 25.85 s user, and 0.05 s system time.

A follow-up alternates execution order across 20 complete-query pairs, including
startup, preparation, hinted building, and independent checking. The checked
mode averaged 843.36 ms ± 36.27 ms, and direct polarity 814.93 ms ± 43.83 ms.
Direct polarity was quicker in 16 of 20 pairs. The average paired difference
was 28.42 ms, with paired standard deviation 51.07 ms; the ratio median was
1.039, range 0.862–1.147. Both execution-order groups had the same mean direction.
The unchanged checker control was 42.54 ms ± 2.37 ms, and the process used
35.09 s elapsed, 34.90 s user, and 0.11 s system time. Shared Binary and Core
were fixed throughout these comparisons.

The observed complete-query mean improvement is about 3.4%, with substantial
variation. Under the current policy of holding small effects under host noise,
production retains key verification. The candidate and whole-engine selectors
are isolated in `key_values_wbtest.mbt` for future investigation. This preserves
the earlier negative width-16 result and the modest width-64 observation instead
of treating the eliminated comparisons as a proven general pipeline speedup.

```sh
/home/hosi/morph/tools/measure --cpu 10 tools/moon bench src/cdcl/key_values_wbtest.mbt --target native --release -i 0
/home/hosi/morph/tools/measure --cpu 10 tools/moon bench src/cdcl/key_values_wbtest.mbt --target native --release -i 2
```

## Split residual conflict maintenance

A test-only sampler replays the same analysis helpers around each actual
conflict transition. One CPU-10/mutex 64-bit observation recorded 477 learned
clauses, 169,747 assignment entries reinserted into fresh watch-value tries,
and 21,659 abandoned entries. Analysis took 48.04 ms, trail backjump filtering
32.79 ms, and watch learning 69.00 ms. Separately timing second-watch selection
measured 5.13 ms; it is a subset of watch learning and must not be added again.
The unchanged prepared hinted-checker control was 41.17 ms ± 1.54 ms.

The sampler repeats helper work to separate these regions and is not a
statistical complete-query measurement. It checks the actual final proof with
the independent hinted checker. The result prioritizes sharing the surviving
trail suffix and updating only abandoned assignment-index paths. Changing
second-watch lookup is a lower priority under this observation.

The experiment isolation and sampler pass all 23 ordinary CDCL tests on native,
JS, and Wasm GC, the warning-denying check, and the unchanged purity gate.

```sh
/home/hosi/morph/tools/measure --cpu 10 tools/moon bench src/cdcl/maintenance_wbtest.mbt --target native --release
```

## Share backjump suffixes and surviving assignment paths

The reverse trail has nonincreasing decision levels. Backjumping can therefore
return the unchanged suffix as soon as it reaches a surviving level. Watch
learning now removes only abandoned assignments from its existing value trie,
prunes empty paths, and inserts the new asserting assignment. The trie remains
canonical, so the full paused state still equals the rebuilding version
structurally. Watch positions, propagation order, and second-watch selection
are preserved. The old filtering/rebuilding path remains a private selector.

The trail-order invariant is checked after every paused transition in the
existing pigeonhole and thousand-instance three-SAT invariant families. New
regressions compare every paused state and final statistics/proof for all
three maintenance modes in both scan and watch engines. Trie removal is checked
against fresh construction for all 256 subsets of eight prefix-related keys
and nine possible removed keys, including an absent key. Sparse sequential
removal includes Binary keys 255, 256, 257, and 65535, and the fully removed trie
must be exactly `Empty`. Sorted-trail cutoff regressions compare suffix sharing
with the previous filter at every tested level.

Same native release ELF, CPU 10, shared mutex, fixed `e717649` Binary and old
Core, ten samples per search case:

| Maintenance | Mean ± standard deviation | Range |
| --- | ---: | ---: |
| Filter trail and rebuild value trie | 501.18 ms ± 20.43 ms | 478.48–545.97 ms |
| Share trail suffix and rebuild value trie | 487.10 ms ± 40.32 ms | 423.51–547.50 ms |
| Share trail suffix and value trie | 423.63 ms ± 31.64 ms | 390.46–492.86 ms |

The isolated suffix-only effect overlaps variation; the combined change is
selected. The unchanged prepared hinted-checker control was 43.17 ms ± 3.72 ms.
For the measured proof, fresh rebuilding inserts 169,747 assignment entries;
the incremental path instead removes 21,659 abandoned entries and inserts
477 asserting entries. This reduces assignment-index update calls from 169,747
to 22,136, about 7.67 times. This is an operation count, not an allocation or
complete-query speedup claim.

A second experiment alternates execution order across 20 complete-query pairs,
including startup, preparation, hinted building, and independent checking:

| Mode | Mean ± standard deviation |
| --- | ---: |
| Filter and rebuild | 892.05 ms ± 40.38 ms |
| Shared suffix and trie | 796.96 ms ± 35.96 ms |

Sharing is quicker in all 20 pairs. The paired difference averages 95.09 ms,
standard deviation 46.89 ms; the speed ratio median is 1.1208, range
1.0195–1.2497. Each execution-order group has ten wins in ten pairs. This
establishes about 10.7% lower complete-query mean for this miter experiment.
The unchanged checker control was 43.90 ms ± 2.81 ms. The invocation used
35.86 s elapsed, 35.65 s user, and 0.06 s system time.

Other complete-query families return identical final statistics, models, and
proofs between the selectors, and every timed query also checks its model or
hinted certificate:

| Family | Rebuild | Shared |
| --- | ---: | ---: |
| Pigeonhole six into five | 34.74 ms ± 1.45 ms | 35.73 ms ± 2.62 ms |
| Fixed thousand six-variable three-SAT cohort | 112.13 ms ± 3.80 ms | 113.48 ms ± 5.88 ms |

Those intervals overlap. No improvement or regression is established on these
small families. Their input generation is outside timing; the cohort uses the
same seed 31415 and generator as the invariant test. The comparison ELF hash was
`4b4e8fc46aab8a086052d44ac57261dad86c1df8aeeb9c17cb5642400578f970`.

```sh
/home/hosi/morph/tools/measure --cpu 10 tools/moon bench src/cdcl/maintenance_modes_wbtest.mbt --target native --release -i 0
/home/hosi/morph/tools/measure --cpu 10 tools/moon bench src/cdcl/maintenance_modes_wbtest.mbt --target native --release -i 4
/home/hosi/morph/tools/measure --cpu 10 tools/moon bench src/cdcl/maintenance_modes_wbtest.mbt --target native --release -i 5
```

After selecting sharing by default, all 26 CDCL tests pass native, JS, and
Wasm GC, together with the warning-denying check and purity gate. Fresh exports
again pass both pinned external checkers for all 16 positive cases, and all
seven negative controls reject. The 64-bit CNF/DRUP hashes above are unchanged.
