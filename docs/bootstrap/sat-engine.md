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
tautological lemmas are sound and accepted. Proof checking currently uses the
same clause normalization and unit-status evaluator as the solver; its search
and conflict-analysis logic are independent, but this is not an independently
implemented trusted kernel or a formal soundness proof.

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
