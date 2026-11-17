# A reusable finite permutation-group kernel, 2026-11-17

## Question and outcome

Can a pure ADT kernel turn checked permutation generators into a completed
finite group and an exact, context-bound solvability decision, including a
non-solvable example? `src/permgroup` now provides that milestone. It enumerates
the concrete subgroup, computes every derived subgroup from all pair
commutators, and checks a record bound to the degree, canonical generators,
actual elements, complete derived series and conclusion.

The handwritten production code uses `core.Nat`, `core.Chain`, the persistent
`core.Queue`, and `avl.OrderedMap[Permutation, Unit]`. It uses no machine numeric
types, numeric literals or operators, arrays, mutable state, FFI, or external
group library. Machine arrays and integers appear only in independent tests.

## Invariants and reasoning

A checked degree-d permutation has exactly d distinct images, each below d.
This proves bijectivity of its finite point set. Composition is function
composition (left after right), and inversion searches for the unique preimage
of each point. Internal total lookup fallbacks are unreachable for the private
checked representation. The constructors and image lists are immutable and the
representation fields are private.

Closure starts with the identity. Each discovered element is a positive word in
the supplied generators, and processing it inserts its right products with
every generator. Thus every inserted element belongs to the generated monoid;
when the queue empties, induction on positive word length shows that every
positive word is present. For a finite permutation generator s, finiteness
gives a positive power equal to identity, so its inverse is a nonnegative
power of s. Therefore this monoid is exactly the generated subgroup. At most d!
permutations can be inserted. Canonical AVL ordering makes input generator
order and duplicate occurrences immaterial.

Only `Complete` constructs a public completed group handle. Processing one
queue entry consumes one unit of natural fuel; exhaustion returns the original
remaining queue as `Pending`. Resuming is exact. Processing |G| entries suffices
for a completed finite group. This budget counts group elements, not CPU work;
each entry is multiplied by every canonical generator.

For each completed group H, the derived subgroup H′ is the subgroup generated
by all x⁻¹y⁻¹xy with x,y in H. Computing only the raw set of commutators, or
assuming commutators of just the initial generators suffice without a normal
closure argument, was deliberately avoided. H′ is a subgroup of H. If H′ is
neither equal to H nor trivial, its finite element set strictly decreases.
Thus repeated derivation terminates. Reaching the identity subgroup is the
definition of solvability; a nontrivial stable subgroup is perfect, and all
later derived terms are equal, giving an exact negative decision.

The definition of the derived subgroup, its normality, and its largest abelian
quotient property are recorded in [GAP reference §39.12-3](https://docs.gap-system.org/doc/ref/chap39.html).
The solvability criterion and perfect-group definition are in §39.15-5/6 of
that same primary reference. §39.17-7 describes stopping the derived series
at a perfect subgroup. These definitions were verified against the official
online reference on 2026-11-17; the implementation is independent of GAP.
The [GAP Exercises §1.1](https://stefan-kohl.github.io/gap-exercises/chap1.html)
also explicitly points out why the commutator set itself need not be a group.

## Certificate boundary

The record contains `degree`, canonical `generators`, canonical `elements`,
`derived_series`, and `conclusion`. It is intentionally constructible and
editable by callers. The checker regenerates the group using the claimed
element count as the initial closure bound. A too-small claim causes `Pending`
and rejection; a wrong or extra element changes the exact canonical list and is
rejected. After successful closure the checker recomputes every derived stage,
including the terminal stable-stage test. It compares the entire record,
including the claimed conclusion. The actual returned group is bound by
`check_result`, which also compares its private concrete payload with the
record. This prevents a valid certificate for another group from justifying
an unrelated returned group.

This is replay verification, sharing the producer's permutation arithmetic and
derived-subgroup code. It is not a formal proof or an independently implemented
certificate checker. A generator-word witness checker would avoid repeating
closure search but require a larger witness format and separate provenance
invariants; it was not needed for this bounded, explicit-group milestone.
The separate array oracle detects shared arithmetic and series errors in the
tested cases. Proof conclusions read through `is_solvable` are claims until
the appropriate checker has accepted them.

## Independent verification

The tests implement permutations as ordinary integer arrays, composition by
array indexing, inversion by a separately filled array, closure by a mutable
array queue and linear set membership, and derived series by independently
closing all array-model commutators. They compare complete element sets at
every derived stage, rather than comparing only orders or trusting a named
group classification.

| Explicit fixture label | Degree | Order | Derived-stage orders | Decision |
| --- | ---: | ---: | --- | --- |
| Empty-degree trivial group | 0 | 1 | 1 | Solvable |
| C1 through C8 | 1 through 8 | 1 through 8 | 1, or n → 1 | Solvable |
| V4 | 4 | 4 | 4 → 1 | Solvable |
| S3 | 3 | 6 | 6 → 3 → 1 | Solvable |
| D4, square symmetry action | 4 | 8 | 8 → 2 → 1 | Solvable |
| A4 | 4 | 12 | 12 → 4 → 1 | Solvable |
| A5 | 5 | 60 | 60 | NonSolvable |
| S4 | 4 | 24 | 24 → 12 → 4 → 1 | Solvable |
| S5 | 5 | 120 | 120 → 60 | NonSolvable |

All named fixtures include a certificate replay, actual-result binding,
generator-order invariance, and independent element-set/derived-stage checks.
The A5 fixture supplies `(0 1 2)` and `(0 1 2 3 4)` as explicit image lists;
both kernel and independent model enumerate 60 elements and derive the same
60-element set. The S5 fixture adds an independent negative case with a proper
first derived subgroup before reaching a nontrivial perfect terminal group.
No lookup table or unverified group-name recognition is used.

Additional cases exhaustively check all permutation pairs at degrees zero
through four against the array model, verify both inverse equations and
out-of-range application, and check associativity on every triple of S3
permutations. Tests reject wrong permutation lengths, repeated or out-of-range
images, degree mismatches and privately forged malformed generators.
Subgroup tests distinguish normal A3 in S3 from a non-normal transposition
subgroup. Certificate attacks change degree, canonical generators, elements,
element ordering, derived stages, stage ordering and the conclusion; swap
valid contexts and results; forge an actual result membership cache; and
insert malformed elements.

The milestone passed 12 tests on each of wasm-gc, JavaScript and native (36
backend test executions). All CPU work ran via the shared `tools/measure
--cpu 4` lock and Moon test used `-j 1`. Each JavaScript/native test command
had an external 60-second timeout. Package `moon check`, formatting and public
interface generation passed; `moon info` and `moon fmt` do not expose a `-j`
option, and were package-limited under the same CPU lock. The repository purity
gate passed with 295 kernel files. No cross-implementation speed claim is made.

## Limits and next connection

This enumerating kernel targets small explicit groups. A derived step evaluates
|H|² commutators and performs subgroup closure against their deduplicated set.
Image lookup and comparisons use recursive unary naturals and immutable lists.
Neither scalability to large-degree groups nor a performance improvement over
Schreier–Sims, GAP, or machine-indexed algorithms has been measured or claimed.
`generate` can pause; `derived_subgroup`, `analyze`, and certificate replay run
to completion on an already completed finite group. They do not accept a
separate time or memory budget. Finite mathematical termination does not bound
practical resource consumption on arbitrary large inputs.

The decision concerns precisely the supplied permutation subgroup. Abstract
group isomorphism names are not certified. No general Galois group computation,
splitting-field construction, or radical expression is provided here. A later
adapter must bind a separately checked splitting-field automorphism action to
these exact permutations before drawing a field-theoretic conclusion.

The implementation milestone was committed on the isolated
`explore/permgroup-20261117` branch as `83a5104`; verification notes and formatting
are a follow-up commit. Integration and any push belong to the parent task.
