# Polynomial forms on oriented rational simplices

## Frozen contract

This separate package connects affine polynomial differential forms to finite
oriented simplices. It does not modify existing homology/cohomology packages or
claim a global manifold/de Rham theorem.

`simplex(ambient, vertices)` validates a nonempty ordered list of rational
vertices, all with the declared ambient dimension. Intrinsic dimension is the
vertex count minus one. Vertex order carries orientation; repeated or affinely
dependent vertices are allowed. This also permits k>ambient as a degenerate
parameterized simplex, whose matching form integral is zero after full validation.
`standard`, `ambient`, `dimension`, `vertices`, `face` and `parameterization` expose
the standard-coordinate/ambient-vertex relation. Face indices are validated
before repetition or degeneracy can cancel an expression.

`integrate(simplex, form)` requires the form's variable count and exterior degree
to match ambient/intrinsic dimensions, including zero forms. It pulls the form
back by the ordered affine parameterization to the standard simplex and evaluates
each monomial moment alpha!/(|alpha|+k)!. A 0-simplex integral is point evaluation,
with unit mass. No absolute determinant or Euclidean volume is substituted for
orientation-sensitive form integration.

`boundary` returns the whole ordered list of omitted-vertex faces with signs
(-1)^i. A point has empty boundary. `boundary_integral` and `stokes` require
form.degree+1=dimension; therefore a point has no representable Stokes input and
returns DegreeMismatch. StokesCertificate retains the source simplex/form, its
exact differential, interior integral, every oriented face integral and their
boundary sum. The checker validates omission, order, parity, all moments and the
original Stokes equation. Its moment recurrence differs from the producer's
factorial formula; pullback and exact arithmetic are shared dependencies.

The next bounded milestone adds normalized Whitney forms in intrinsic standard
N-simplex coordinates. For a nonempty ordered face I of degree k, use
`k! sum_j (-1)^j lambda_Ij d(lambda_I0) wedge ... omit ... wedge d(lambda_Ik)`.
Permutations retain orientation and repeated indices give zero, after all range
checks. Empty face lists have no nonnegative exterior degree and are rejected.
Face integrals give the signed Kronecker pairing and exterior differentiation
matches oriented cochain incidence. No global complex assembly is implied.

Primary formulas were checked against
[Lasserre's author manuscript](https://arxiv.org/pdf/1908.06736), Section 2, and
[Arnold–Falk–Winther](https://www-users.cse.umn.edu/~arnold/papers/acta.pdf),
Section 4.3. The latter uses unnormalized phi with integral 1/k!; this package's
Whitney form is k! times phi so its own oriented face integral is one.

## Milestone 1: exact integration and checked Stokes data

Simplex construction, ordered faces/standard simplex, affine parameterization,
integration, boundary integration, and complete Stokes certificates are
implemented. `check_parameterization` verifies both degree-at-most-one and every
standard vertex image. In particular, a nonlinear map with the right endpoint
values is rejected. Dimension and degree errors precede any zero shortcut.

The producer evaluates factorial-quotient moments. `check_integral` instead starts
at mass 1/k! and applies the increment recurrence for each exponent using rational
products. The Stokes checker verifies the exact source differential, each original
omission and parity, every face value by this recurrence, the complete ordered
face list, the boundary sum and the original equality. It does not call the
boundary builder, integral producer, factorial or Stokes producer. Parameterization,
polynomial pullback/d and exact arithmetic are shared dependencies, not a
whole-program independent proof.

`tools/generate_simplexforms_fixtures.py --check` uses independent Fraction/indexed
polynomial dictionaries and Jacobian-minor pullback from the host forms oracle.
It integrates by repeatedly expanding the bound `0<=x_last<=1-sum(others)` and
performing exact univariate polynomial integration. It never uses the production
factorial or checker moment formulas. The corpus has 224 complete oriented
integrals, including standard monomials through four variables and rational,
embedded/degenerate affine examples. Another 48 cases compare the full Stokes
differential, every face geometry/sign/integral, and the total. Handwritten tests
cover malformed vertices/faces, 0-dimensional cases, nonlinear parameterization,
and certificate tampering by dropped/reordered faces, sign, value and differential.

Milestone 1 passes **275 tests on each of native, JS and wasm-gc with deny-warn**,
generated API, generator --check, format, and the full repository purity gate.
Production remains pure immutable ADT recursion. Whitney normalization and full
polynomial cochain identities are the next bounded milestone. No performance or
global manifold-cohomology claim is made. Root owns integration, shared gates and
cleanup; existing homology/cohomology sources remain unchanged.
