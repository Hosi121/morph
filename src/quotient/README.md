# Monic finite quotient algebras

`Context[A,K]` describes the commutative K-algebra `K[X]/(f)` for a monic,
positive-degree polynomial. Coefficients are canonical field values stored in
ascending `core.Chain[A]` order. The zero polynomial is `Nil`; high zero
coefficients are removed. `Residue[A,K]` is opaque and always has degree below
`degree(context)`. No constructor here claims that the modulus is irreducible,
and there is no `Field` promotion in this package.

`context(arithmetic, key, is_zero, valid, modulus)` reuses the existing
`rowreduce.Field[A]` dictionary. It rejects coefficients for which `valid` is
false, zero or constant moduli, and nonmonic moduli. It also checks that the
dictionary's zero and one are valid, zero is observed as zero, and one is
observed as nonzero. These checks do not verify the field laws. The dictionary,
exact zero test, validity predicate, and consistency of their arithmetic are
trusted interface requirements. Valid coefficients must contain zero and one and
be closed under the field operations (including inversion of nonzero values);
the zero predicate must agree with the field dictionary. A predicate selecting
an arbitrary non-closed subset is not a coefficient field. For coefficients with a parent context, the
validity predicate must authenticate that parent and the canonical coefficient
representation. `normalize` reduces a polynomial; it does not repair invalid
coefficient values.

The caller supplies an explicit base/context key. Equal keys must denote the
same coefficient field and consistent operations, including the zero test.
`same_context` compares that key and the canonical modulus using coefficient
subtraction and the exact zero predicate. It does not compare function closures,
preparation data, or execution policy. Distinct presentations of isomorphic
fields remain distinct. Wrappers with a selected root or embedding must include
that identity in their key or authenticate it before calling this kernel.

Addition and subtraction preserve the degree bound, so they do not reduce the
modulus again. Generic multiplication constructs a convolution and performs
monic remainder-only cancellation. Input coefficients are checked before
normalization, and generated coefficients and degree bounds are checked before
returning a residue. Binary operations reject different contexts before doing
arithmetic, including multiplication by zero.

`unit_inverse` solves the multiplication action in the power basis against
one, using `rowreduce.solve_with_zero`. It returns `Ok(None)` for zero and
nonzero nonunits, including nilpotents in reducible quotients. A unique solution
is normalized and its product with the input is checked to equal one. A
solvable square multiplication operator cannot have an affine solution space:
an inverse makes it surjective and hence injective in finite dimension. Such a
solver result is therefore `InternalInvariant`, as is a failed product check.
This matrix-based inverse is a small correctness prototype; no performance
advantage over polynomial Euclid is claimed.

`gf2_context(key, modulus, policy)` fixes the coefficient type to `Bool` and
uses the existing `gf2.field()` dictionary. `Generic` selects the generic
convolution/remainder path. `Carryless` selects a fused Bool-Chain loop that
shifts, XORs, and reduces at each step, keeping partial products below the
modulus degree. Both policies implement the same context identity and can be
mixed in operations; the left operand chooses the execution policy. The
specialization uses no casts, runtime recognition of an arbitrary coefficient
type, or machine-word packed bits. Characteristic two alone would not justify
replacing arbitrary field coefficients with Bool.

The tests compare QQ products and normalization against bounded integer long
division and include rational coefficients, nilpotents, nonunits, dimension-one
quotients, input rejection, and different parents. Every monic F2 modulus
through degree four, including reducible ones, is checked against independent
integer full-convolution/long-division and brute-force inverse oracles. This is
finite executable evidence, not a proof for arbitrary dictionaries or degrees.

```sh
tools/measure --cpu 4 tools/moon test src/quotient --target js --deny-warn -j 1
tools/measure --cpu 4 tools/moon test src/quotient --target wasm-gc --deny-warn -j 1
tools/measure --cpu 4 tools/moon test src/quotient --target native --deny-warn -j 1
```
