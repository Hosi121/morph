# Automorphisms of an explicitly split K(i)

`prepare(source, roots)` takes an existing checked `complexfield.Field` `K(i)`
and all `d` roots of the real generator alpha's minimal polynomial, already
represented inside that source field. It requires exactly `d` distinct roots,
all in the exact source context, and verifies annihilation of the real minimum.
No root search or splitting-field construction is performed.

Each root gives two maps, interleaved in the supplied order:
`(alpha -> root, i -> +i)` and `(alpha -> root, i -> -i)`. `automorphisms` returns
all `2d` maps. `apply` evaluates the source number-field residues
`a(alpha)+i*b(alpha)` at the selected images, using existing exact complex-field
arithmetic. It rejects foreign contexts. `real_image`, `imaginary_image`, and
`equal` expose and compare the checked maps without derived field equality.

`compose(group, left, right)` means **left after right**. It substitutes left
into both images of right and looks up the resulting image pair among the
checked maps. `composition_table` uses the same convention: the entry in row
left, column right is the resulting map's zero-based ADT natural index.
`identity`, `conjugation`, and `inverse` return the corresponding checked maps.
Both inverse equations are verified during group construction. A different
ordering of the same supplied roots gives the same maps with a different table
indexing; source contexts and maps remain explicit.

`Group` and `Automorphism` fields are truly private. `certificate` exposes the
public untrusted `Certificate`: source, actual roots, generator image pairs,
composition table, identity/conjugation indices, and inverse indices. The checker
`check(source, proof)` validates the splitting and expected image ordering, then
rederives every table entry by actual substitution and both-sided inverses.
An arbitrary associative abstract group table is insufficient.
`from_certificate` checks before constructing; `check_result` also binds every
actual private group payload, including its cached identity and conjugation.

The result is the full `Gal(K(i)/Q)`, conditional on the real minimum splitting
in this supplied field. In particular, `Gal(Q(sqrt(2),i)/Q)` is V4, while the
polynomial group `Gal(t^2-2/Q)` is C2. For the quartic example, the supplied roots
`alpha,-alpha,i*alpha,-i*alpha` generate i via `(i*alpha)/alpha`. Thus
`Q(fourthroot(2),i)` is the minimal splitting field and its group D4 really is
`Gal(t^4-2/Q)`.

Tests cover `Q(i)` with group C2, `Q(sqrt(2),i)` with group V4, and that quartic
splitting field with group D4 of order eight. They check representative
sum/product preservation under every map, semantic composition, inverse
round-trips, the permutation action on the quartic roots, and the D4 relations
`r^4=1`, `tau^2=1`, `tau*r*tau=r^-1`. Adversarial cases include missing,
duplicate, foreign and wrong roots, nonsplit cubic candidates, swapped images,
valid abstract tables with incorrect substitution semantics, forged special
indices and inverse lists, and source/result/proof swaps.

The conditional field-theory reason is that a real field and `Q(i)` are linearly
disjoint, so its `d` real-generator root choices and two signs of i describe all
`2d` rational embeddings. If all roots lie in the supplied field, these are
automorphisms. The code checks the exact roots, generator substitutions, closure,
and inverse equations; it does not provide a separate formal proof of the
general theorem. Runtime and coefficient sizes are unbounded. A failed supplied
root list is not a general certificate of nonsplitting, and no classification of
arbitrary Galois groups is claimed.
