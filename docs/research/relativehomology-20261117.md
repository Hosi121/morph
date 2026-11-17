# Integral relative homology and a checked connecting morphism

This milestone asks whether the existing integer Smith machinery can compute
finite simplicial relative homology, including torsion, and the connecting
homomorphism with integral representative independence. The answer is supported
by executable certificates and independent finite fixtures. The implementation
uses `Chain`, unary `Nat`, exact signed binary integers and recursion throughout
production code. Machine numerics, arrays and mutation occur only in tests and
the independent Python generator.

The mathematical convention follows [Hatcher, Algebraic Topology, Chapter 2,
section 2.1, pp. 115–118](https://pi.math.cornell.edu/~hatcher/AT/ATch2.pdf): the
relative chain complex is the quotient by chains in the subcomplex, and a
connecting class is represented by the boundary of a lifted relative cycle.
This implementation handles finite abstract simplicial pairs and the positive
degree connecting morphism. It does not implement all maps or all exactness
statements of the long exact sequence, and adds no universal formal proof.

## Checked pairs and actual quotient boundaries

`relativehomology.pair(K,A)` checks both existing `homology.Complex` inputs and
requires every simplex of `A` to occur in `K`. Its readonly `Pair` type cannot be
constructed unchecked by another package. The simplex orientations and
lexicographic basis order are inherited from `homology`.

`relativehomology.simplices(pair,k)` is the ordered basis consisting of the
k-simplices in `K` that are absent from `A`. The canonical lift matrix `L_k`
embeds this basis in `C_k(K)` with zero coefficients on A-simplices. The matrix
`I_k` embeds `C_k(A)` in `C_k(K)`. Thus the quotient projection is `L_k^T` and

\[
 d_k^{rel}=L_{k-1}^{T}d_k^K L_k.
\]

The boundary function constructs these products from the actual ambient
boundary. Equivalently, it deletes the A-simplex columns and A-face rows. In
degree zero it retains the precise zero-row boundary with one column per
relative vertex. `boundary_squared_zero` multiplies the actual consecutive
matrices and tests every entry and the product's shape.

The empty pair, `A=K`, `A=empty`, isolated vertices and degrees above the top
simplex are supported. Homology is unreduced in nonnegative degrees. In
particular `H_0(K,empty)=H_0(K)`. `connect` accepts positive degrees; degree zero
returns `None` because the unreduced sequence ends with `H_0(K,A) -> 0` and this
API has no negative-degree homology type.

These are quotient **chain groups**. The construction does not identify vertices
of an abstract simplicial complex to pretend to construct the topological
quotient space. No arbitrary quotient-space homology assertion is used.

## One common integer engine

`src/chainhomology` extracts the existing two-Smith computation from
`src/homology`. It receives actual matrices `B=d_k` and `N=d_(k+1)`, rejects
noncomposable inputs or a nonzero product `BN`, and uses checked unimodular
coordinates to compute `ker(B)/im(N)`:

\[
 U B V=D,\qquad
 V^{-1}N=\begin{pmatrix}0\\C\end{pmatrix},\qquad
 H\cong \operatorname{coker}(C).
\]

The final columns of `V` give the complete integral cycle lattice. A second Smith
form of `C` determines the free rank and invariant torsion factors. This is the
same algorithm as before, shared by absolute and relative homology. Rational
inversion is used only to produce candidate inverses of integer unimodular
matrices; every denominator must be one and both integer inverse identities are
checked. No rational nullspace is substituted for the integral cycle lattice.

`chainhomology.Certificate` records both input matrices, the actual result, both
Smith decompositions, the inverse of `V`, and boundary coordinates. Its checker
runs no Smith search or matrix inversion. Each of the two producer Smith searches
has at most the supplied unary fuel transitions. A paused search returns
`BudgetExhausted`, never an incomplete answer.

`homology` delegates its producer and shared checking calculations to this
engine while retaining its exact public API: `ResultGroup`, `Certificate` fields,
`Computation` constructors and derived equality semantics are unchanged. The
regenerated `src/homology/pkg.generated.mbti` has no diff from the baseline.
The `homology.Certificate` still records its own complex and degree; no new
field is added to it.

`relativehomology.Certificate` records the actual pair, degree, an existing
`homology.ResultGroup`, and the common matrix certificate. `check_result` first
binds these values, rebuilds the two quotient boundaries from that pair, and
checks the common certificate against those matrices and the actual result.
A certificate for a different pair with coincidentally equal homology is rejected.

## Connecting lifts and representative independence

A caller supplies a checked relative certificate `s` for degree `k>0` and a
checked absolute certificate `t` for `H_(k-1)(A)`. Let `Z_s` be the integral source
cycle basis. `connect` constructs and witnesses

\[
 E=L_k Z_s,\qquad
 F=I_{k-1}^{T}d_k^K E,\qquad
 I_{k-1}F=d_k^K E.
\]

The last equality verifies that the lifted boundary lies entirely in A. The
`ConnectingMap` stores `E` as `lifted_cycles` and `F` as `boundary_cycles`. Target
cycle coordinates are the bottom rows of `V_t^-1 F`, with zero leading rows
checked explicitly; these bottom rows form `cycle_map = M`.

Writing `C_s` and `C_t` for the source and target image presentations, the
explicit boundary descent witness is

\[
 W=-I_k^{T}d_{k+1}^K L_{k+1}.
\]

It is stored as `boundary_descent`. The checker rebuilds it from the actual pair
and checks both well-shaped equalities

\[
 F C_s=d_k^A W,\qquad M C_s=C_t W.
\]

The sign comes from the chain decomposition
`d_K L_(k+1) = L_k d_rel_(k+1) - I_k W` and `d_K^2=0`. Hence changing a source
relative cycle by a relative boundary changes its connecting image by a target
boundary. Changing the chosen ambient lift by an A-chain also changes its
boundary by an A-boundary; the implementation chooses the canonical zero-A lift.

Source Smith coordinates are not raw source cycle coordinates. If the source
image form is `U_s C_s V_s=D_s`, a Smith vector `q_s` lifts via `U_s^-1 q_s`.
The target form `U_t C_t V_t=D_t` then reduces the image using `U_t`. Therefore
`classes` is the columnwise target canonical reduction of

\[
 M U_s^{-1},
\]

including the `U_t` action inside `smith.class_coordinates`. Both inverse
identities for `U_s^-1` are checked. Full Smith-coordinate vectors retain unit
slots, whose canonical values are zero; torsion slots have positive residues and
free slots retain signed integers. `apply_connecting` accepts any source Smith
representative, including negative torsion representatives, verifies the entire
public witness and returns canonical target coordinates.

`check_connecting(pair,k,actual,witness)` binds the pair, degree, both homology
certificates and actual result matrix, then rechecks lifts, boundaries in A,
source inverse, descent and target canonical reduction. The checker invokes
neither Smith search nor rational inversion. Public fields allow independent
witness producers and adversarial mutations in tests.

## Independent evidence

`tools/generate_relativehomology_fixtures.py` uses no production MoonBit code,
Smith reduction or external numerical library. It encodes simplices as bitmasks,
derives boundary signs with bit operations, computes rational ranks and kernel
bases with Python `Fraction`, and computes integer determinants with Bareiss
elimination. The checked-in generated fixtures cover:

- All **148** pairs `(K,A)` on three labelled vertices.
- All **167** subcomplexes A of the full tetrahedron K.
- Exact boundary entries and widths in degrees zero through three for all 315
  pairs, plus independent boundary-square products.
- Four relative homology groups per pair from rational ranks. Gcds of **all**
  maximal-rank minors of the incoming boundaries equal one, independently
  establishing the absence of integral torsion in this cohort.
- Three positive-degree connecting ranks per pair. These are computed by lifting
  independent rational relative kernels, taking ambient boundaries, and measuring
  their span modulo A-boundaries. They are compared with the rank of the actual
  returned Smith-coordinate matrix.

Separate tests cover the triangle disk/boundary pair
`H_2(D^2,S^1)=Z -> H_1(S^1)=Z` with connecting entry of magnitude one; an interval
and its endpoints with matrix `[-1,1]^T`; a subdivided interval with disconnected
A-arcs and a nontrivial target Smith basis; a disk relative its vertices with
nontrivial `U_s^-1` and an annihilated source unit slot; a sphere relative a point;
empty targets; and a nonzero boundary-descent witness.

For the verified six-vertex triangulation of RP2 used by the existing homology
fixtures, relative homology against a point or a spanning tree has `H_1=Z/2`.
The independent generator computes the actual relative `d_2`: its rank is ten,
and all 3003 maximal minors for the point case have gcd two; the tree case is a
square matrix with determinant of magnitude two. Since the quotient of
`coker(d_2)` by homology is `im(d_1)`, which is free, these establish the homology
torsion product without computing Smith form. The product is prime, so the
nontrivial torsion is exactly `Z/2`.

For RP2 relative its **full triangulated 1-skeleton**, `H_2(K,A)=Z^10` and
`H_1(A)=Z^10`. The returned connecting matrix has determinant of magnitude two,
matching the independent maximal-minor lattice index. This example does not
pretend the triangulated skeleton is a rank-one circle or report a scalar map
from the distinct CW model of RP2.

Adversarial tests change the pair, degree, actual result, common matrix
certificate, source or target homology certificate, lifted cycles, boundaries in
A, cycle map, source inverse, boundary descent and returned matrix. They also
reject mismatched vector dimensions, exhausted producer fuel, noncomposable
matrix pairs and matrices with a nonzero chain product.

## Reproduction and limits

From the repository root, using the frozen local SDK and shared CPU lock:

```bash
python3 tools/generate_relativehomology_fixtures.py --check
python3 tools/audit_purity.py
tools/measure --cpu 4 tools/moon test src/chainhomology src/relativehomology src/homology src/simplicialmap src/csscode --target wasm-gc -j 1
tools/measure --cpu 4 tools/moon test src/chainhomology src/relativehomology src/homology src/simplicialmap src/csscode --target js -j 1
tools/measure --cpu 4 tools/moon test src/chainhomology src/relativehomology src/homology src/simplicialmap src/csscode --target native -j 1
tools/measure --cpu 4 tools/moon info src/homology src/chainhomology src/relativehomology
git diff --exit-code -- src/homology/pkg.generated.mbti
```

All **61 tests pass on each target** in this scoped suite: the new relative and
matrix-pair tests together with the directly checked existing homology,
simplicial-map and CSS-code consumers. Fixture freshness and the production
purity gate pass. The gate finds 316 production kernel files in this isolated
milestone checkout. Regenerating the old homology interface produces no change.
The integration owner separately checks the complete affected reverse dependency
closure.

These checks establish finite reproducibility and result-bound witness behavior;
they are not a universal formal verification of the implementation or runtime.
There is no scalability or performance-improvement claim. The finite dense
matrices, unary indices, recursive matrix multiplication and existing Smith and
rational inverse procedures remain practical limitations. This milestone adds
only the connecting map of a pair, not relative functorial maps, a complete long
exact sequence API, exactness certificates, excision or general singular homology.
