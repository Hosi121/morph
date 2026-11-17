# Abelianization of finite group presentations

This package computes the finitely generated abelian quotient of a presentation
with finitely many generators and relator words. The presented group itself can
be finite or infinite. No presentation isomorphism or general word problem
algorithm is provided.

`Letter { generator, inverse }` is one signed generator occurrence; generator
IDs are zero-based ADT naturals. `checked_presentation(count, relators)` rejects
every out-of-range ID, including IDs inside freely cancelling pairs. It accepts
empty words, no relators, and zero generators. `inverse_word` reverses and
inverts a word. `reduce_word` performs free cancellation, without using the
presentation's relations. Neither helper decides equality in the presented
group.

`relation_matrix(source)` has one **row per generator** and one **column per
relator**. Entry `(i,j)` is the signed exponent sum of generator i in relator j.
Zero-height and zero-width dimensions are retained. `exponent_sums(source, word)`
checks the word's IDs and returns its integer exponent vector. Under
abelianization, the quotient is exactly `Z^count / image(relation_matrix)`.

`start(source)` and `run(state, fuel)` delegate to the existing resumable Smith
machine. The status is `Paused(state)`, `Fault(state)` or
`Done(abelianization, certificate)`. A paused state retains both the exact
source and accumulated Smith work. Fuel counts Smith steps, rather than total
CPU work or determinant operations; zero fuel always pauses.

`free_rank`, `torsion_factors`, and `finite_order` describe the resulting abelian
group. `torsion_factors` contains the invariant factors greater than one, in
divisibility order. `finite_order` returns `None` when the abelian quotient has a
free summand, and otherwise the product of its torsion factors (one for the zero
abelian group). These are properties of the abelian quotient. `cokernel` exposes
the existing Smith cokernel for `smith.class_coordinates` and
`smith.equivalent` on exponent vectors; `decomposition` exposes its checked
Smith witness.

The public untrusted `Certificate` records the generator count, literal relator
words, relation matrix, Smith matrices U/D/V, free rank and torsion factors.
`check(source, proof)` reconstructs the exponent matrix from the source words
and delegates matrix validity to `smith.check`: correct dimensions, unimodular
U and V, `U A V = D`, and the nonnegative diagonal divisibility chain. It then
recomputes and compares the claimed invariants. `from_certificate` constructs a
checked result; `check_result(source, actual_result, proof)` additionally binds
the actual source, stored witness, decomposition and cached cokernel.
Representation fields on the source, state and result are private.

Relator permutation, inversion, insertion of freely cancelling pairs and
duplication preserve the computed invariants. Certificates nevertheless bind
literal source words and their order. A certificate for different words is not
accepted merely because their exponent matrices happen to agree.

Examples tested against independent integer-array exponent sums and gcds of
minors are RP2 `⟨a | a²⟩ → C2`, the torus
`⟨a,b | a b a⁻¹ b⁻¹⟩ → Z²`, the Klein bottle
`⟨a,b | a b a⁻¹ b⟩ → Z ⊕ C2`, the S3 presentation
`⟨a,b | a²,b³,(ab)²⟩ → C2`, and the triangle presentation
`⟨a,b | a²,b³,(ab)⁵⟩ → 0`.

Zero abelianization does not assert that the presented group is trivial or
solvable. A test maps the triangle generators to explicit permutations satisfying
all relators and generating a nontrivial perfect group of order sixty. It
checks this concrete quotient through `permgroup`, without assuming an
isomorphism between the whole presentation and that quotient.

For a path-connected space with the supplied fundamental-group presentation,
the quotient describes first integer homology by the degree-one Hurewicz theorem.
This package does not derive a presentation from a space or certify a supplied
geometric identification. See [the reasoning and verification note](../../docs/research/presentation-20261117.md).
