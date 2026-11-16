# Stable basis complex number fields

`field(k)` constructs the exact ambient field `K(i)` from a checked
`numberfield.Field` with its selected real embedding. The real embedding makes
`t²+1` irreducible over `K`. If `K` has degree `d`, this field has degree `2d`
over `QQ`. `real_field` returns the original context. A field's identity includes
the selected real root and its isolating interval; different conjugates and
different interval representations cannot be mixed.

`element(f, a, b)` checks both real-field parents and constructs `a+i*b`.
`Field` and `Element` have private fields. Coordinates use the stable basis
`[1,t,...,t^(d-1),i,i*t,...,i*t^(d-1)]`. `rational`, `zero`, `one`, and
`imaginary_unit` embed `QQ` and `i`; the coordinate accessors, `parent`,
`same_field`, `equal`, and `is_zero` preserve exact context semantics.

`add`, `subtract`, `multiply`, `inverse`, `divide`, `negate`, and `conjugate`
reuse real-field residue arithmetic. There are no resultants or root-isolation
calls in these operations. `inverse` uses `(a-i*b)/(a²+b²)` and returns `None`
exactly at zero; mixed-context division fails before testing its divisor.
`inverse_with_certificate` returns a source/result-bound witness carrying the
real-field denominator's Bezout certificate. `check_inverse_result` checks
those bindings and contexts, the Bezout witness, and the product equal to one.
Public certificate fields are untrusted inputs.

`relative_trace` and `relative_norm` return `2a` and `a²+b²` in `K`.
`trace` and `norm` return the ambient invariants over `QQ`:
`2*Tr_K(a)` and `N_K(a²+b²)`. `multiplication_matrix` independently assembles
`[[M_a,-M_b],[M_b,M_a]]` from the real-field multiplication matrices.
`check_trace` and `check_norm` verify a supplied result using its diagonal and
determinant, respectively.

`minimal_polynomial` finds the first `QQ` linear dependence of
`1,z,...,z^(2d)` using the existing rational linear solver.
`check_minimal_polynomial` checks univariate monicity, annihilation, the ambient
degree bound, and rank independence of every earlier power using the existing
row-reduction kernel. Thus a padded higher-degree annihilator is rejected,
including one whose degree remains below `2d`.

The ambient field need not equal `QQ(z)`. For `K=QQ(sqrt(2))`,
`alpha=sqrt(2)+i` has minimum `t⁴-2t²+9`, trace `0`, and norm `9`. For
`K=QQ(sqrt(3))`, `zeta=(-1+i*sqrt(3))/2` has minimum `t²+t+1` but ambient
degree `4`, trace `-2`, and norm `1`. This construction does not automatically
find a minimal compositum or splitting field.

Fixed vector-space dimension does not bound coefficient bit growth. These
algorithms and executable checkers provide no formal proof, wall-clock bound,
or measured speed claim. This package does not yet realize its elements as
`complexalgebraic.Number`; arithmetic stays inside its checked ambient field.
