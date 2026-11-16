# Fixed fields inside a certified split complex field

`prepare(group, members)` computes the complete rational vector space fixed by
the supplied subgroup of a checked `complexautomorphism.Group`. The result stays
inside the original `complexfield` context. It provides its rational dimension,
an exact basis, direct membership by substitution, and coordinate conversion in
both directions. Existing complex-field arithmetic operates on its elements.

The input member indices are sorted and deduplicated. The set must be nonempty,
in range, contain the actual identity, and be closed under the actual inverse
and composition tables. A list of generators is not accepted as a subgroup:
the implementation never silently takes its generated closure. Certificates
store only the canonical ascending member set.

For the ambient rational basis `[1,alpha,...,i,i*alpha,...]`, each automorphism
matrix has the substituted ambient basis vectors as columns. `actions` follows
the canonical member order. `constraints` stacks `M_sigma-I` in that order.
The shared exact linear solver supplies a nullspace basis, which is converted
back into actual complex-field elements. Its dimension is `[L^H:Q]`.

The public, untrusted certificate contains the ambient source, full group
certificate, subgroup members, claimed dimension, actual basis, action matrices,
constraint matrix, and constraint rank. `check` binds the caller's actual group
with `complexautomorphism.check_result`, recomputes each substitution matrix and
the exact constraints, and checks all of the following:

- Each basis value belongs to the source and is fixed by every supplied member.
- The basis columns are independent over the rationals.
- `rank(constraints) + basis_count = [L:Q]`, so no invariant is omitted.
- `basis_count * subgroup_order = [L:Q]`.

`from_certificate` accepts any basis satisfying these checks. `check_result`
additionally binds the actual returned field's group, member set, basis, and
all certificate metadata. Swapping a different valid basis therefore changes
the coordinate system and fails validation against the original returned field.
Wrong ambient contexts give `false` from `contains` and `DifferentField` from
`coordinates`; a same-context nonmember gives `NotFixed`. Reconstruction requires
exactly the fixed-field dimension in coefficients.

The finite examples use the splitting field `L=Q(alpha,i)`, `alpha^4=2`, with
root order `[alpha,i*alpha,-alpha,-i*alpha]`. Its maps have interleaved signs for
the image of `i`; rotation has index 2 and conjugation index 1.

| Members | Fixed field | Rational dimension |
| --- | --- | --- |
| `{0}` | `L` | 8 |
| `{0,1,2,3,4,5,6,7}` | `Q` | 1 |
| `{0,2,4,6}` | `Q(i)` | 2 |
| `{0,1}` | `Q(alpha)` | 4 |
| `{0,4}` | `Q(sqrt(2),i)` | 4 |
| `{0,1,4,5}` | `Q(sqrt(2))` | 2 |
| `{0,3}` | `Q(alpha*(1+i))`, minimum `t^4+8` | 4 |

The trusted field-theory fact that invariants of automorphisms form a field,
and the general Galois correspondence, are not formalized here. The executable
checker certifies the exact complete invariant vector space for an already
certified explicit splitting group. Generic splitting-field search, primitive
generators, relative arithmetic wrappers, and trace/norm APIs are out of scope.
