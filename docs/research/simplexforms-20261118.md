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

This API-freeze milestone makes no implementation/test claim. Planned validation
uses a dedicated independent Fraction polynomial-integration oracle for all
monomials/faces, complete Stokes certificates, degeneracy/mismatch/point cases,
Whitney normalization and full polynomial cochain identities. Production remains
pure immutable ADT recursion. Root owns integration, shared gates and cleanup.
