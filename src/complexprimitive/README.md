# Absolute coordinates for a checked complex field

`prepare(source)` builds the single generator `theta = alpha + i` for the
existing checked `complexfield.Field` `K(i)`. For a real base of degree `d`, the
absolute modulus has degree `2d`. A `Representation` keeps its certificate in a
truly private field; clients obtain data through `source`, `degree`, `generator`,
`modulus`, `basis_matrix`, `inverse_basis_matrix`, `real_generator_image`, and
`imaginary_unit_image`.

Columns of the basis matrix are `1,theta,...,theta^(2d-1)` in the source basis
`1,alpha,...,alpha^(d-1),i,i*alpha,...,i*alpha^(d-1)`. The existing exact
`linear.inverse` kernel produces its inverse. Coefficient extraction uses the
source number-field representatives; this package adds no elimination engine.

`certificate` exposes a public, untrusted `Certificate`. `check(source, proof)`
binds the exact selected source context and expected `alpha+i`, checks the actual
minimum with `complexfield.check_minimal_polynomial` and its degree, reconstructs
every basis column, verifies both inverse equations, and evaluates the canonical
claimed images of `alpha` and `i`. `from_certificate` checks before constructing;
`check_result` also binds the separately returned representation. Source fields
and complex elements are compared explicitly, without derived equality.

`to_polynomial(rep, input)` returns a `Conversion` with a canonical univariate
rational polynomial of degree below `2d` and a public `ConversionCertificate`.
`check_conversion_for(rep, input, polynomial, proof)` binds all caller-supplied
arguments, rechecks the primitive presentation, and evaluates the claimed
polynomial at theta. Equal residues padded by the modulus are rejected as
noncanonical conversion results. `from_polynomial(rep, polynomial)` accepts any
univariate polynomial, reduces it modulo the modulus, and evaluates in the
original source field. Other variable counts return `NotUnivariate`; conversion
of an element from another source context returns `DifferentField`.

For `Q(i)` with real generator zero, theta is `i`, its modulus is `t^2+1`, and the
images of alpha and i are zero and t. For `Q(sqrt(2),i)`, the modulus is
`t^4-2t^2+9`, alpha maps to `(5t-t^3)/6`, and i maps to `(t+t^3)/6`. Tests also
include independently computed exact SymPy modulus and generator maps for the
degree-six and degree-eight fields obtained from `alpha^3=2` and `alpha^4=2`.
They check arbitrary rational coordinates, inverses, round trips, products,
high-degree input reduction, and forged source, theta, matrix, minimum, image,
and conversion payloads.

The generator is mathematically appropriate because the real field and `Q(i)`
are linearly disjoint: the shifts of the real generator's irreducible polynomial
by `+i` and `-i` remain distinct irreducible factors over `Q(i)`. Here the exact
minimality, dimension, and matrix checks certify each constructed presentation;
this rationale is not a separate formal proof of a general primitive-element
theorem. The finite basis operations need no search fuel. Coefficient sizes and
runtime are unbounded. This is an absolute presentation of an existing `K(i)`,
not a compositum search or general splitting-field algorithm. Quotient
arithmetic wrappers are deferred; clients can use polynomial arithmetic plus
normal form or the existing source-field operations.
