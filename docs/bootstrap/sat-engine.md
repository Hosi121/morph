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

At propagation quiescence the engine scans for a decision and reports
`InvariantViolation` if any unit or false clause was missed by the watch index.
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
has not been adopted into `atom`: the root task is also improving the shared
Binary increment/conversion, which must be compared before selecting one.

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
