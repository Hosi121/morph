# Exact GF(2) cohomology and cup rings

The question for this milestone was whether the immutable ADT kernel can retain
enough cocycle information to distinguish spaces whose integer homology agrees.
The answer is yes for the checked finite examples: the torus and
`S¹ ∨ S¹ ∨ S²` both have free integer ranks `(1,2,1)` with no torsion, while their
positive-degree cup products differ. The projective plane additionally checks
that a degree-one square over GF(2) need not vanish.

## Domain and public operations

`src/cohomology` consumes the existing, unchanged `homology.Complex`. These are
finite abstract simplicial complexes on globally ordered `Nat` vertices, with
canonical increasing simplices and complete nonempty face closure. Cochains
are `Chain[Bool]` in `homology.simplices(source, degree)` order. Addition is XOR;
multiplication is AND. The Boolean reachability semiring is not used.

- `compute(source, degree)` returns an opaque checked `Cohomology`.
- `result`, `certificate`, `check_result`, and `validate_certificate` expose and
  independently validate explicit degree results and witnesses.
- `coordinates` accepts exactly the correctly sized cocycles and returns their
  quotient coordinates. `representative` chooses the stored representative of
  a class; `equivalent` compares cocycles modulo coboundaries.
- `cup` computes a raw Alexander–Whitney cochain product. `cup_product` retains
  the actual input cocycles, input classes, raw output cochain, and output class
  in a source-bound `ProductCertificate`; `check_product` checks all of them.
- `compute_ring` computes every degree from zero through the source dimension,
  including zero groups. `ring_result`, `ring_certificate`, and `check_ring`
  provide the complete ordered basis multiplication table. `multiply` extends
  it bilinearly to arbitrary homogeneous class coordinates.

Degrees above the dimension have the zero vector space; their class coordinate
vector is `Nil`. All pairs of stored basis classes are present in the ring
table, including products above the dimension. Empty complexes have ordinary
cohomology zero in every degree and the zero ring with empty unit coordinates.
This is ordinary, unreduced cohomology, not augmented cohomology.

## Complete degree certificates

Write `D = δ_k = (d_(k+1) mod 2)^T`, `P = δ_(k-1)`, and `n = dim C^k`.
The degree certificate stores the following exact binary matrices:

```text
T = [ B | H | L ],    S = T^(-1),    Q = S P
```

Here `B` contains a coboundary basis, `H` contains cocycle representatives of a
quotient basis, and `L` completes these to an ambient cochain basis. The result
stores `B`, `H`, and `h = number of columns of H`. Independent CSS rank
certificates provide `b = rank P` and `r = rank D`.

The checker binds the requested source, degree, and actual result, then checks
both rank certificates, exact shapes, `TS = ST = I`, `DP = 0`,
`D[B|H] = 0`, `b+h+r=n`, `TQ=P`, and that every row of `Q` after its first `b`
rows is zero. It also checks that the actual `B` and `H` are the corresponding
columns of `T`.

These identities establish completeness, rather than just checking a proposed
Betti number. Invertibility makes the first `b+h` columns independent; their
annihilation by `D` and the rank equality show that they span `ker D`. The image
identity puts `im P` inside `span B`; both have dimension `b`, so they agree.
For a queried cochain `x`, the coordinates `Sx` therefore decompose it into a
coboundary, a cohomology representative, and a complement. `coordinates` rejects
`x` exactly when its complement component is nonzero and otherwise returns its
`H` component.

Construction uses the existing generic row-reduction engine. Independent
columns of `P` are extended with nullspace vectors and then with standard
coordinate vectors. Rank witnesses reuse `csscode.field`, `csscode.scalars`,
and the independently checkable CSS transform/inverse certificates. None of
`check_result`, `check_product`, or `check_ring` reruns elimination or inverse
search. A regression transports the basis and inverse under an explicit
noncanonical representative change and confirms that this equally valid
certificate is accepted.

## Cup multiplication and quotient checks

For a globally ordered simplex the implemented formula is

```text
(a cup b)[v0,...,v(p+q)] = a[v0,...,vp] b[vp,...,v(p+q)].
```

The front and back faces overlap at `vp`. Raw cochains need not commute: on the
filled triangle, the elementary cochains supported on edges `01` and `12`
multiply to the triangle cochain in one order and zero in the other. The code
checks commutation on cohomology classes, where the graded sign is one over
GF(2).

For every pair of degree spaces, `check_ring` checks that products of their
complete cocycle bases remain cocycles, that the table entries equal the actual
Alexander–Whitney products modulo coboundaries, and that `B*Z` and `Z*B` vanish
in the quotient on complete bases. Bilinearity makes these last tests sufficient
for representative independence throughout the returned finite spaces. The
global degree-zero unit is the cochain taking value one on every vertex;
disconnected spaces can have several degree-zero basis classes. The checker
checks the unit on basis classes, commutation on basis pairs, and associativity
on basis triples. Bilinearity and trilinearity extend those identities to all
class coordinates of the particular checked ring.

`ProductCertificate` binds its source, both input degrees, both actual input
cocycles, and the actual `Product`. Verification independently recomputes the
raw product and validates all three class coordinate vectors. Tests reject
paired forgeries in which both the supplied actual result and the certificate's
result are changed together.

## Independent finite evidence

`tools/generate_cohomology_fixtures.py` uses Python machine bitmasks and finite
XOR-set closure, with no Gaussian elimination. It enumerates kernel masks by
simplex-face constraints, builds images and quotient cosets by set spans, and
constructs cup tensors by joining pairs of supported input faces. This differs
from production, which evaluates the front and back faces of each output
simplex. Generated fixtures and their finite counts are recorded in
`src/cohomology/fixtures_wbtest.mbt` and `src/cohomology/fixtures.json`.

| Check | Count |
| --- | ---: |
| All complexes on four labelled vertices | 167 |
| Additional torus, RP², wedge, disjoint-circle examples | 4 |
| Exhaustive small cochain membership checks | 5,351 |
| Kernel vectors checked against independent quotient coordinates | 20,652 |
| Ordered independent-basis products | 670 |
| Exhaustive small raw cochain cup pairs, including noncocycles | 269,883 |
| Exhaustive small cocycle cup pairs compared with the class table | 49,923 |
| Elementary cochain pairs checked for the Leibniz identity | 13,226 |

The four-vertex enumeration includes the empty complex, isolated and disjoint
vertices, circle boundaries, the tetrahedral sphere, and filled simplices.
Membership checks cover every cochain in every included degree on these small
complexes. Focused examples additionally enumerate all their kernel vectors.

| Space | GF(2) ranks in degrees 0,1,2 | Degree-one products |
| --- | --- | --- |
| Seven-vertex torus | `(1,2,1)` | `a²=b²=0`, `ab=ba` is nonzero |
| `S¹ ∨ S¹ ∨ S²` | `(1,2,1)` | All products are zero |
| Six-vertex RP² | `(1,1,1)` | `a²` is nonzero |

The torus and wedge integer groups are also computed and independently checked
by the existing integral homology certificate checker in degrees zero through
two: both are `Z`, `Z²`, `Z`, with no torsion. The torus and RP² facets are the
same fixtures already used by `homology`; the wedge shares vertex zero between
two three-edge circles and the boundary of a tetrahedron. Degree-zero tests
check orthogonal idempotents and the global unit for two disconnected points.
Adversarial tests cover wrong sources/degrees, wrong actual groups, false bases
and inverses, invalid image coordinates, forged raw products/classes, and
missing, duplicated, reordered, or altered ring entries.

The final package has 180 tests passing independently on `wasm-gc`, `js`, and
`native`. Commands, scoped to this package and the required single-CPU lane:

```sh
python3 tools/generate_cohomology_fixtures.py --check
python3 tools/audit_purity.py
tools/measure --cpu 4 tools/moon info -p cohomology
tools/measure --cpu 4 tools/moon test -p cohomology --target wasm-gc -j 1
tools/measure --cpu 4 tools/moon test -p cohomology --target js -j 1
tools/measure --cpu 4 tools/moon test -p cohomology --target native -j 1
```

## Limits and decisions

The finite oracle tests are evidence on the stated domains, not a universal
machine-checked proof of algebraic topology or of this implementation. The
certificate argument uses ordinary finite-dimensional linear algebra; its
implementation has not been proved in a proof assistant. The purity gate is a
conservative source audit and excludes tests, compiler-derived code, and runtime
internals.

The implementation deliberately retains dense exact matrices and explicit
representatives. It makes no new performance or scalability claim and has no
caller-supplied fuel mechanism; large complexes can consume substantial memory
or recursive stack depth. The Python oracle is exponentially enumerative and
is used only for finite fixtures, not production computation.

This milestone does not implement other coefficient rings, relative cohomology,
cap products, Steenrod operations, or pullback/naturality certificates. In
particular it makes no claim of strict Alexander–Whitney cochain naturality for
arbitrary simplicial vertex maps that do not preserve the global vertex order.
Delta-complexes or CW complexes with identified simplex occurrences require a
different input model.

## Primary reference

[Hatcher, *Algebraic Topology*, revised §3.2](https://pi.math.cornell.edu/~hatcher/AT/ATch3.2.pdf),
pp. 206–210: the cup formula and coboundary identity (Lemma 3.6), the induced
cohomology multiplication and unit, orientable-surface products (Example 3.7),
the RP² square (Example 3.8), and graded commutation (Theorem 3.11). The reference
motivates the mathematical definitions; the source-bound finite certificates
and independent fixtures described above are this repository's implementation
and validation choices.
