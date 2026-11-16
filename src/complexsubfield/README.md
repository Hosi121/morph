# Generated complex subfields

`generate(L, generators)` constructs the exact subfield `Q(generators)` inside
a checked `complexfield.Field`. Empty or rational generators give degree one;
the result need not have the ambient degree. The original CF context remains
the context for all returned elements. `coordinates` and `from_coordinates`
use the returned basis; its order is a presentation detail.

The producer starts with one and saturates its rational span under
multiplication by each generator. It appends only independent products, so at
most the ambient dimension many basis values are retained. A public certificate
records a generator-monomial exponent vector for every basis value. `check`
independently verifies the source and ordered generators, those monomials,
the occurrence of one, independence, and closure under multiplication by every
generator. Monomial provenance proves that the span lies in the generated
algebra; closure and one prove the reverse inclusion. A finite-dimensional
subalgebra of a field is a field. These checks therefore reject an oversized
ambient field even if it is closed and contains all generators.

`primitive_start` and `primitive_advance` search integer candidates
`theta(c) = sum_j c^j * basis_j`, starting at `c = 0`. Distinct embeddings differ
on some basis value, so each pair excludes only finitely many integer
candidates. The exact minimum of a successful candidate has the subfield
degree. The public primitive certificate binds the complete generated-field
certificate, candidate, element, minimum, and rectangular ambient-by-subfield
power matrix. Its checker verifies the true minimum and actual powers. A paused
search retains the next untried candidate. The budget counts complete candidate
trials; an individual CF minimum or rational linear solve runs to completion.
There is no fixed overall trial cap and no claim of polynomial running time.

`to_polynomial` solves that rectangular power system and returns the unique
polynomial of degree below the subfield degree. `from_polynomial` accepts any
univariate polynomial, reduces modulo the checked minimum, and evaluates in
the original context. Conversion checking separately binds the actual input,
returned polynomial, and complete primitive presentation, then evaluates the
polynomial directly. All proof records are public and tamperable; the checked
field, representation, and search handles have private fields.

The finite package tests cover ambient degrees two, four, and eight, proper
subfields, independent and redundant generators, rational and empty inputs,
rectangular coordinates, failed primitive candidates and exact resumption,
and source, rank, monomial, closure, oversized-basis, modulus, result, and
conversion tampering. They are executable checks, not a formal proof of the
kernel, compiler, or arbitrary input sizes.
