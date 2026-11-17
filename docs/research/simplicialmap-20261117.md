# Checked simplicial maps and induced integer homology maps

The question for this milestone was whether a finite vertex function can be
validated as a simplicial map and then transported through the existing integer
homology certificates, including orientations, collapsed simplices and torsion.
The implementation is `src/simplicialmap`; it does not introduce a new elimination
algorithm or change `homology` or `smith`.

## Mathematical source and scope

[Hatcher, *Algebraic Topology*, Chapter 2, §2.1, Proposition 2.9, p. 111](https://pi.math.cornell.edu/~hatcher/AT/ATch2.pdf)
gives the algebraic reason a chain map induces a homology homomorphism: the
boundary identity preserves cycles and boundaries. The adjacent identity and
composition properties motivate the functoriality checks here. The finite
abstract-complex representation and the Smith-coordinate transport below are
implementation choices, checked against exact matrix identities.

The complexes are the existing `homology.Complex`: distinct increasing `Nat`
vertices, nonempty simplices, complete face closure, and unreduced integer
homology in nonnegative degrees. The empty complex and degrees beyond dimension
retain their exact zero matrix shapes.

## Checked vertex functions and chain maps

`check(source, target, assignments)` accepts a `Chain[(Nat, Nat)]` and returns an
opaque `SimplicialMap` only when:

- Every source vertex has exactly one assignment; extra and repeated keys fail.
- Every assigned target vertex belongs to the target complex.
- The distinct image vertices of every source simplex form a target simplex.

The assignments are stored in increasing source order. Noninjective functions
are allowed. For a source oriented simplex, `chain_map(map, k)` maps its vertex
sequence, counts the parity of the sorting permutation, and places its signed
coefficient in the matching target simplex row. A repeated image vertex produces
a zero column in that original degree. It does not become a lower degree chain
column.

`chain_identity` verifies `d_target F_k = F_(k-1) d_source`; degree zero uses the
unreduced zero boundary. `check_chain_map` binds a supplied matrix to the map and
degree before checking this identity. `compose(after, before)` requires exactly
equal intermediate complexes and rechecks the composed vertex function.

## Integer homology coordinates

The existing certificate for degree `k` contains a checked Smith decomposition

```text
U d_k V = D,
V^-1 d_(k+1) = [0; C].
```

If `r = rank(d_k)`, then `Z = V[:, r:]` is a full integer cycle basis and `C`
presents boundaries in that basis. A second checked Smith decomposition is

```text
U_image C W_image = D_image.
```

For source and target certificates, this package constructs

```text
M = bottom(V_target^-1 F_k Z_source).
```

Its checker reconstructs those coordinates, requires the leading rows to be
zero, and checks the exact boundary descent identity

```text
M C_source = C_target F_(k+1).
```

The public class convention is **full ambient Smith coordinates**, after
`U_image`, including unit diagonal slots. Unit slots canonically equal zero;
torsion slots are positive residues; free slots remain signed integers. Their
length is the number of cycle basis vectors, which can exceed the number of
nontrivial homology generators.

Consequently an input class `q_source` must first be lifted by
`U_image_source^-1`. Its target class is

```text
class_coordinates(cokernel(target.image_form),
                  M U_image_source^-1 q_source).
```

The target `class_coordinates` applies `U_image_target` and reduces residues.
Omitting either coordinate change is incorrect. A dedicated test replaces the
source and target Smith bases of two isolated points by different nonidentity
unimodular bases. The identity simplicial map then has class matrix
`[[1, -1], [1, 0]]`, and the reverse coordinate map recovers the input.

`HomologyMap.classes` contains the canonical target class of every ambient
source Smith basis vector. Since torsion reduction is required after addition,
use `apply` to map vectors; multiplying this displayed matrix alone need not
produce canonical residues. For composition by successive `apply` calls, the
intermediate homology certificate must use the same coordinates. Alternatively,
compose the simplicial maps and call `induce` with the desired endpoint
certificates.

## Witness production and checking

`induce(map, degree, source_certificate, target_certificate)` rechecks both
homology certificates against the exact source, target and degree. It reuses
`linear.inverse` only to produce a candidate inverse of the source image Smith
left matrix. Denominators must all equal one, and both integer inverse products
must equal the identity.

`check_induced(map, degree, actual_matrix, witness)` performs no inversion and
no Smith search. It checks the exact map, degree and returned matrix bindings,
both existing homology certificates, the source inverse pair, both relevant
chain identities, cycle coordinates, boundary descent and canonical target
columns. Public witness fields permit independent producers and explicit
tampering tests. `apply` rechecks the witness before accepting a vector and
rejects wrong vector dimensions. It accepts any representative of a source
Smith class, including negative torsion representatives.

The production implementation uses immutable `Chain`, `Nat`, `Integer`, ADTs
and recursion. Machine numerics, arrays and mutation occur only in the fixture
generator and tests. The repository purity gate remains a conservative source
check, not a termination proof or a verification of the compiler/runtime.

## Evidence

The independently implemented Python finite-set and inversion-count model is
`tools/generate_simplicialmap_fixtures.py`. The checked-in generated data are
`src/simplicialmap/fixtures_wbtest.mbt`. Regeneration with `--check` checks both
the expected counts and exact reproducibility after `moonfmt`.

- All 19 finite complexes on three labelled vertices are enumerated. Every one
  of their 3,439 total vertex functions is checked: 2,449 are simplicial and 990
  fail simplex preservation. Every valid map matches the independent signed
  chain matrices in degrees zero through three, including zero shapes.
- All 256 tetrahedron endomaps match independent matrices through degree four,
  including all orientation permutations and collapses.
- All 729 pairs of triangle endomaps satisfy the chain-map composition identity.
- All 729 pairs of circle endomaps yield the product of their induced `H1`
  degrees. This includes reflection degree `-1` and constant maps of degree zero.
- Explicit cases cover circle identity, reflection squared, inclusion of a
  triangle boundary into its filling killing `H1`, and edge collapse acting by
  `1` on the free `H0` class.
- The existing six vertex real projective plane has `H1 = C2`; its induced
  identity sends both `1` and `-1` to canonical `1`, and `2` to zero.
- Empty complexes, high degrees, wrong domains, unknown vertices, missing image
  faces, incompatible composition, changed source/target certificates, changed
  degrees, false results, wrong inverses, wrong cycle maps, wrong class matrices,
  and wrong input vector lengths are checked.

Scoped tests pass on native, JavaScript and Wasm GC: 29 tests on each target.
The purity gate passes with 305 production kernel files. No full repository
test run, performance improvement, external publication or deployment is claimed.

Commands (all compiler and runtime work shares the repository CPU lock):

```sh
tools/measure --cpu 4 tools/moon test --target native -j 1 src/simplicialmap
tools/measure --cpu 4 tools/moon test --target js -j 1 src/simplicialmap
tools/measure --cpu 4 tools/moon test --target wasm-gc -j 1 src/simplicialmap
tools/measure --cpu 4 python3 tools/generate_simplicialmap_fixtures.py --check
python3 tools/audit_purity.py
tools/measure --cpu 4 tools/moon fmt --check src/simplicialmap
tools/measure --cpu 4 tools/moon info src/simplicialmap
```

## Remaining limits

This handles finite abstract simplicial maps on the exact supplied complexes.
It does not provide subdivision, homotopy witnesses, reduced or negative degree
homology, relative maps, cohomology operations or a separate compact generator
coordinate API. Invalid inputs and unavailable checked matrix constructions
return `None`; failure reasons are not classified. Existing homology computation
still uses its explicit Smith fuel budget; this package does not search for new
homology certificates. The fixtures establish small exact cases and do not
establish scaling or performance claims for large complexes.
