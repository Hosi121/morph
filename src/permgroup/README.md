# Finite permutation groups

`checked_permutation(degree, images)` checks that `images` is a bijection of the
ADT natural points below `degree`. The empty chain is the unique permutation
of degree zero. `compose(left, right)` means left after right; different
degrees return `None`. `inverse`, `identity`, `apply`, `images`, `degree` and
lexicographic `compare` provide the basic checked permutation operations.
`Permutation` fields are private.

`generate(degree, generators, fuel)` enumerates the generated subgroup using a
persistent AVL membership index and a persistent breadth-first queue. It returns
`InvalidGenerators` for incompatible degrees, `Pending(state)` when fuel runs
out, or `Complete(group)` only when the frontier is empty. One unit of ADT natural
fuel processes one discovered element against all canonical generators.
`resume_generation(state, more_fuel)` preserves completed work. Degree-zero and
empty-generator groups still process the identity once. Fuel equal to the
actual group order suffices. Fuel counts queue work, not time or allocations.

`FiniteGroup` and `GenerationState` fields are private. Complete groups expose
`group_degree`, `group_generators`, lexicographically sorted `group_elements`,
`order`, `contains`, `same_group`, `is_subgroup(subgroup, ambient)`,
`is_normal(subgroup, ambient)` and `is_abelian`. Generator order and duplicates
are ignored; different generating sets still form different certificate
contexts even when they generate the same element set.

`derived_subgroup` generates a subgroup from every pair commutator
`x⁻¹ y⁻¹ x y`. It computes the generated subgroup, because the raw set of
commutators need not itself be a subgroup. `analyze(group)` iterates this exact
operation until the subgroup becomes trivial (`Solvable`) or nontrivial and
perfect (`NonSolvable`). The derived series includes the input group and records
the terminal subgroup once. `series_orders(proof)` summarizes its cardinalities.
These operations run to completion on an already enumerated finite group; only
initial generation has a pausing API. They target small explicit groups.

`Certificate` is public, untrusted data containing the actual degree,
canonical generators, canonical elements, canonical derived series and claimed
conclusion. `verify_certificate(degree, generators, proof)` replays closure with
the claimed element count as a closure bound, recomputes the entire derived
series, and compares every field. This is a replay checker sharing the producer
arithmetic, not an independent proof assistant or a generator-word proof
checker. `check_result(group, proof)` additionally binds the actual returned
group's degree, generators and elements. `is_solvable(proof)` reads a claim;
external certificates must first pass a checker.

The API determines solvability of the concrete finite permutation subgroup. It
does not certify an abstract group name, isomorphism type, Galois interpretation,
or expression of roots by radicals. Tests use familiar group names only as
labels for explicit supplied permutations. The mathematical reasoning,
independent array-model coverage, and measured verification scope are recorded
in [the research note](../../docs/research/permgroup-20261117.md).
