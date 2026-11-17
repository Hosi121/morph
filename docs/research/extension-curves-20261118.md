# Elliptic curves over checked finite extensions

Base `7389c7f37f45ca6c1db4380fac226ce8ea4ece95`. The first runnable milestone is `7a7dac6`.
This adds `extensioncurve`; existing `elliptic`, `galois` and all shared kernels
are unchanged. Production uses immutable ADTs, Result and structural recursion,
without machine numbers, arrays, mutation, FFI or literals.

## Contract and arithmetic

A Curve contains one checked `galois.Field` presentation and coefficients a,b.
Construction checks coefficient context first, then characteristic greater than
three, then nonzero discriminant. Isomorphic fields with different modulus
presentations remain different contexts. Opaque Points contain their exact Curve
and private Jacobian X,Y,Z. Affine construction checks contexts and the curve
equation. Curve mismatch is rejected before identity branches, including infinity.

The arithmetic follows EFD's general-coefficient `add-1998-cmo-2` and
`dbl-1998-cmo-2` formulas. Identity, inverse/equal-point and zero-y doubling
branches precede the generic formulas. Addition, doubling and Binary scale do
not invert field elements. `coordinates` is the affine inversion boundary;
infinity avoids inversion. `normalize` returns a checked affine-scale Point.
The projection is `x=X/Z², y=Y/Z³`, with nonzero Z for finite points.
[EFD Jacobian formulas](https://hyperelliptic.org/EFD/g1p/auto-shortw-jacobian.html).

Point deliberately has no structural Eq instance: `equal` compares projective
values within exactly the same Curve and returns an error across curves.
`check_point` rechecks field binding, curve validity and the projective equation;
it also enforces canonical infinity. A nonzero rescaling changes private
coordinates but preserves equality, normalization and arithmetic. Public data
cannot forge Point or Curve constructors.

The API consists of curve/point constructors; infinity, parent, field,
coefficients, same_curve and is_infinity; add/double/negate/Binary scale;
projective equal, coordinates, normalize and check_point. The generated interface
is retained beside the source. Errors distinguish field context, curve context,
unsupported characteristic, singular curve, invalid point and underlying field
failures.

## Independent evidence

The Python generator implements affine group arithmetic over ordinary integer
polynomial residues; it executes no morph code. It enumerates every point and
full addition tables for GF(25), modulus x squared plus two, on two curves:
a=b=one (27 points) and extension-valued a=t,b=one plus t (28 points). GF(49),
modulus x squared plus one, uses a=b=one and has 55 points. Their complete
4538 point pairs agree, and the two GF(25) curves exercise
all 41635 triples directly with projective intermediate
sums. GF(49) triples are not exhaustive in this pass.

Every candidate affine coordinate pair is checked against each enumerated point
set. Native tests compare exact normalized field coefficients, validate every
sum, identity/inverse/doubling, each point's independently computed order,
9186 small scalar cases and three scalars 2^200+17.
All 625 GF(25) coefficient pairs are independently classified as singular or
nonsingular. Degree-one presentations compare every accepted point and all
3792 point pairs on all 62 nonsingular curves over five and
seven against the existing prime-field affine elliptic implementation.

Adversarial tests cover different equal-cardinality field presentations,
different coefficients, characteristic two/three, mismatch error precedence,
invalid affine coordinates, forged white-box field/curve payloads, noncanonical
infinity and arbitrary nonzero Jacobian scales. Existing galois arithmetic is a
shared dependency of operations and check_point; checker success alone is not
independent evidence. The separate host arithmetic and old affine implementation
supply additional comparisons. These finite tests do not constitute a formal
proof for every finite field or all Jacobian formula substitutions.

## Validation and boundary

Native, wasm-gc and JS each pass **7/7**, with deny-warn. The all-target scoped
static check passes; public API generation and formatting pass. Global purity
passes 337 production kernel files; formal drift passes 32 previously reviewed
regions and explicitly is not a translation proof of this new package. Generator
`--check` compares all fixture tokens while allowing formatter whitespace, plus
exact decompressed oracle JSON bytes. Hashes and full logs are in the validation
receipt. Builds/tests use CPU4 through the shared measurement lock and -j 1;
only the compiler directory is symlinked, with an independent _build tree.

This stage implements exact group arithmetic and observations. It does not add
point compression, subgroup selection, cryptographic parameters, constant-time
execution or a cryptosystem. No timing or memory improvement is claimed. Miller
and a shifted-divisor Tate evaluation are a separate dependent package with their
own parameter, support and quotient-domain contract.

Evidence: [independent oracle](extension-curves-20261118-oracle.json.gz),
[validation receipt](extension-curves-20261118-validation.json),
[generator](../../tools/extension-curves-20261118-oracle.py),
[source/interface](../../src/extensioncurve).
