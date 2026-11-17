# Exact GF(2) persistent homology — 2026-11-17

`src/persistence` extends the pure algebraic kernel from homology of one complex
to the inclusion maps of a finite simplicial filtration. The concrete question
is whether a persistent barcode can be computed with immutable algebraic data
and accompanied by a source-bound witness that can be checked without repeating
the reduction search. The implementation does this for exact rational grades
and GF(2) coefficients. Finite independent fixtures check the complete rank
invariant, including maps between different prefixes; this is stronger evidence
than agreement of each prefix's Betti numbers alone.

## Input and output contract

An `Entry` consists of a nonempty canonical `Chain[Nat]` simplex and an
`exact.Rational` grade. `validate` accepts the empty list and rejects repeated
vertices, descending vertices, duplicate simplices, missing faces, a nonempty
face that does not occur earlier, and decreasing grades. Negative rational
grades and equal grades are valid. It preserves the supplied simplex order.
The caller must supply all faces; validation does not implicitly close or sort
the complex.

Homology is unreduced, in nonnegative dimensions. For zero-based simplex indices
`b < d`, `Pairing { birth: b, death: d }` records an interval of the simplexwise
filtration, including a pair whose two grades are equal. `Bar` records dimension,
exact birth grade, optional death grade, and both simplex indices. `None` death
means an essential interval. Public `barcode` omits finite intervals with equal
birth and death grades. Thus a filled triangle supplied entirely at one grade
has three finite simplex pairs, but only its essential H0 bar is public.

`pairs` are ordered by death simplex. Bars are ordered by birth simplex. For
different valid orders inside a grade tie, indices and list order can change;
compare the multiplicities of `(dimension, birth grade, death grade)` to compare
grade barcodes. Zero-length simplex intervals remain available in the witness
for checking intermediate simplex prefixes that are absent from the grade
filtration.

The public entry points are:

- `validate(Chain[Entry]) -> Filtration?`, `entries`, and `boundary_columns`.
- `start(Filtration) -> State` and
  `run(State, operation_fuel: Nat, column_fuel: Nat) -> Computation`.
- `Done(Certificate)`, `Paused(State)`, or `InvalidWitness`.
- `barcode(Certificate)`, `pairs(Certificate)`, and
  `check_result(Filtration, Chain[Bar], Certificate) -> Bool`.

## Reduction and checkable invariants

Each sparse column is an increasing `Chain[Nat]` of its nonzero row indices.
GF(2) addition is the symmetric difference of two such lists. The actual
boundary `D` is reconstructed from simplex face incidences; its vertex columns
are empty. The producer performs the standard left-to-right column algorithm.
When an active column shares its highest nonzero row with an earlier completed
column, it adds that earlier column and the corresponding basis-change column.
It therefore maintains `R = D V`. Each XOR removes the active low pivot and
strictly lowers it. Committing a column preserves distinct nonzero lows.

`Certificate` has public fields `source`, `reduced`, `change`, `pairings`, and
`bars`, so an independent producer can submit a witness. The checker verifies:

1. The requested source is valid and equals the witness source; the requested
   returned barcode equals the witness barcode.
2. `R` and `V` have exactly one canonical sparse column per source simplex, with
   all row indices in range.
3. `V` is unit upper triangular: column `j` contains `j`, and has no entry after
   `j`. Its nonzero coordinates have the same simplex dimension as column `j`.
4. Every column satisfies the exact GF(2) identity `R_j = D V_j` for the boundary
   of the requested filtration. Nonzero columns have distinct low pivots.
5. Each low pivot pairs an earlier zero reduced column with a simplex one
   dimension higher. All simplex pairs and all finite and essential bars are
   exactly those extracted from this reduction and these exact source grades.

Unit upper triangularity makes `V` invertible and preserves the basis of every
prefix; dimension preservation ensures these are changes of basis in the
individual chain groups. Reduced boundary matrices determine persistence pairs.
This is the mathematical reason the identities checked above suffice without
repeating the producer's search. The published algorithm and uniqueness of its
pivot pairing are described in Edelsbrunner and Morozov, §24.4, pp. 650–651 of
the [2017 handbook chapter](https://www.csun.edu/~ctoth/Handbook/chap24.pdf).
The checker deliberately accepts valid alternative triangular witnesses: a test
adds an earlier vertex cycle to a later vertex's `V` column while leaving `R`
unchanged.

The handwritten production files use `Nat`, `Chain`, `Bool`, immutable records,
options, and exact rational operations. They contain no machine numerics,
arrays, mutation, FFI, or oracle imports. The numeric fixture adapters live only
in white-box tests. `tools/audit_purity.py` checks this syntactic boundary; it is
not a proof about compiler-generated code, runtime representation, or recursion
termination.

## Suspension and resource semantics

Each column initialization, whole sparse-column XOR, and column commit consumes
one operation unit. Each commit also consumes one column unit. Either exhausted
budget pauses the computation; fresh budgets may resume the same immutable
state. Tests resume with one operation at a time and with one column at a time,
and obtain the same final certificate as uninterrupted reduction. `Paused`
carries a state, never an accepted barcode. A complete empty filtration returns
`Done` even with zero fuel.

Fuel measures these algebraic transitions. Sparse-list traversals, filtration
validation, initial boundary construction, and final certificate checking are
outside these budgets. Consequently fuel is neither a wall-clock nor an
allocation limit. Suspension is an in-memory pure value; no file serialization
or external storage interface is supplied.

## Independent finite evidence

`tools/generate_persistence_fixtures.py` constructs the actual boundary spaces
using Python arrays and bitsets, without invoking MoonBit or a persistence
reduction. For every degree `k` and every prefix pair `0 <= p <= q <= n`, it
constructs a nullspace basis of the boundary on `K_p` using row RREF, embeds its
cycles into the final simplex coordinates, and constructs boundaries on `K_q`.
It computes

```text
rho_k(p,q) = dim Z_k(K_p) - dim (Z_k(K_p) intersect B_k(K_q))
           = rank([Z_k(K_p), B_k(K_q)]) - rank(B_k(K_q)).
```

Discrete differences of these ranks independently recover all finite and
essential simplex intervals. The MoonBit tests compare both those intervals and
every rank value against the certificate. For a simplex interval `(b,d)`, the
predicted map rank contribution is one exactly when `b < p` and `q <= d`; an
essential interval only requires `b < p`. This checks off-diagonal maps as well
as `p = q` Betti numbers. Grade bars are independently constructed from the
oracle intervals and exact rational grades, removing only equal endpoints.

The committed fixture contains 230 filtrations and 43,718 degree/prefix-pair
rank comparisons:

- Every one of the 167 complexes on subsets of four labelled vertices, ordered
  by dimension then lexicographically, with strictly increasing rational grades.
- All 48 face-compatible linear orders of the full triangle, including
  interleaved dimensions, with rational grade ties.
- Twelve deterministic randomized legal orders of a filled tetrahedron.
- Two filtrations of a six-vertex projective plane: dimensionwise equal grades
  and distinct rational grades.
- One triangle with all grades equal.

An additional test checks all 36 dimensionwise vertex/edge tie orders of the
triangle against the same grade-barcode multiset. The projective-plane fixture
has essential GF(2) H0, H1, and H2 ranks `(1,1,1)`. Its facets and the independent
GF(2) H1/H2 dimensions are documented in Sage's
[`RealProjectivePlane`](https://github.com/sagemath/sage/blob/develop/src/sage/topology/simplicial_complex_examples.py#L342).
This field result is intentionally different from integral projective-plane
homology; GF(2) persistence does not recover integer torsion factors.

Malformed input tests cover each validation condition. Tamper tests reject a
different source, altered return value, altered bars or pairings, wrong matrix
shapes, noncanonical sparse support, a missing unit diagonal, later support,
dimension-mixing changes that preserve `D V`, duplicate lows despite a valid
`R = D V`, and broken matrix identities.

Validation commands, scoped to this package and serialized with the shared
measurement lock:

```sh
python3 tools/generate_persistence_fixtures.py --check
python3 tools/audit_purity.py
tools/measure --cpu 4 tools/moon fmt --check src/persistence
tools/measure --cpu 4 tools/moon test --target js -p persistence -j 1
tools/measure --cpu 4 tools/moon test --target wasm-gc -p persistence -j 1
tools/measure --cpu 4 tools/moon test --target native -p persistence -j 1
tools/measure --cpu 4 tools/moon info -p persistence
```

The three targets pass seven tests each. `moon info` generates the public MBTI;
this command has no `-j` option. These finite fixtures and direct certificate
identities are reproducible evidence, not universal formal proofs. There is no
performance claim or comparison with array-based persistence libraries. The
current sparse linked-list implementation favors explicit immutable witnesses
over large-data throughput. Coefficients other than GF(2), relative or reduced
homology, zigzag persistence, representatives chosen canonically across grade
ties, and formal verification of the checker are outside this milestone.
