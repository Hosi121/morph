# Independent exact fixed-field oracle (2026-11-17)

This finite oracle covers every subgroup of the explicitly certified C2, V4, and D4 examples: 2+5+10=17 fixed fields. The ambient fields are QQ(i), QQ(sqrt2,i), and QQ(2^(1/4),i). These are finite instances of the Galois correspondence conditional on the supplied splitting and existing exact field certificates, not a general splitting-field or primitive-element search.

A host finite-integer model independently enumerates subgroups by identity, multiplication closure, and inverse closure using (k,s)*(l,t)=(k+s*l mod4,s*t). Map order is (+i,-i) per supplied root, with quartic root exponents [0,2,1,3]. Fraction substitution produces every action on the ambient rational quotient basis (1,a,...,i,i*a,...). Each action is encoded compactly as signed target rows for its columns, using one-based rows and a sign. SymPy 1.14.0 computes the exact nullspace and rank of the stacked M_sigma-I constraints. The nullspace basis is independently checked for rank, fixedness, completeness, and [L^H:QQ]*|H|=[L:QQ].

For every subgroup, an explicitly selected fixed generator has an independent SymPy minimal polynomial of degree equal to that nullity. This identifies the complete fixed field in each example, including the reflection generator a*(1+i) with minimum t^4+8. No floating approximation, numerical root, MoonBit producer output, or producer implementation supplies an expectation. The only shared Python code comes from the earlier external finite-group/Fraction oracles.

MoonBit need not produce SymPy's particular basis order or normalization. Its returned basis must have the independently expected rank and span every independent nullspace vector, and its certificate must have the pinned action/constraint matrices and rank. A second field is imported from the independently populated certificate: all specified generator/sample coordinates in that explicit basis are compared coefficient by coefficient. Produced/imported fields also roundtrip their fixed values; sample nonmembers and different ambient sources are rejected. Group setup is reused within three field-level tests.

```json
{"ambient_fields": 3, "fixed_sample_coordinates": 49, "independent_basis_vectors": 49, "primitive_identifications": 17, "sample_memberships": 118, "subgroups": 17}
```

| Ambient group | Subgroup indices | Fixed degree | Explicit fixed generator | Independent minimum |
| --- | --- | ---: | --- | --- |
| C2 over QQ(i) | `[0]` | 2 | `I` | `t**2 + 1` |
| C2 over QQ(i) | `[0, 1]` | 1 | `1` | `t - 1` |
| V4 over QQ(sqrt2)(i) | `[0]` | 4 | `sqrt(2) + I` | `t**4 - 2*t**2 + 9` |
| V4 over QQ(sqrt2)(i) | `[0, 1]` | 2 | `sqrt(2)` | `t**2 - 2` |
| V4 over QQ(sqrt2)(i) | `[0, 2]` | 2 | `I` | `t**2 + 1` |
| V4 over QQ(sqrt2)(i) | `[0, 3]` | 2 | `sqrt(2)*I` | `t**2 + 2` |
| V4 over QQ(sqrt2)(i) | `[0, 1, 2, 3]` | 1 | `1` | `t - 1` |
| D4 over QQ(fourthroot2)(i) | `[0]` | 8 | `2**(1/4) + I` | `t**8 + 4*t**6 + 2*t**4 + 28*t**2 + 1` |
| D4 over QQ(fourthroot2)(i) | `[0, 1]` | 4 | `2**(1/4)` | `t**4 - 2` |
| D4 over QQ(fourthroot2)(i) | `[0, 2]` | 4 | `sqrt(2) + I` | `t**4 - 2*t**2 + 9` |
| D4 over QQ(fourthroot2)(i) | `[0, 3]` | 4 | `2**(1/4)*I` | `t**4 - 2` |
| D4 over QQ(fourthroot2)(i) | `[0, 5]` | 4 | `2**(1/4) + 2**(1/4)*I` | `t**4 + 8` |
| D4 over QQ(fourthroot2)(i) | `[0, 7]` | 4 | `2**(1/4) - 2**(1/4)*I` | `t**4 + 8` |
| D4 over QQ(fourthroot2)(i) | `[0, 1, 2, 3]` | 2 | `sqrt(2)` | `t**2 - 2` |
| D4 over QQ(fourthroot2)(i) | `[0, 2, 4, 6]` | 2 | `I` | `t**2 + 1` |
| D4 over QQ(fourthroot2)(i) | `[0, 2, 5, 7]` | 2 | `sqrt(2)*I` | `t**2 + 2` |
| D4 over QQ(fourthroot2)(i) | `[0, 1, 2, 3, 4, 5, 6, 7]` | 1 | `1` | `t - 1` |

Run `python3 tools/generate_fixedfield_fixtures.py --check` with the pinned SymPy environment. Regeneration formats only the reserved fixture with the repository moonfmt. These bounded cases are independent regression evidence, not a formal proof of the general theorem or a scalability claim.

Milestone validation: regeneration check passes, and `tools/measure --cpu 4 tools/moon test src/fixedfield --target native --release -j 1` passes 8 tests, including these three oracle cases covering all 17 subgroups. The shared measurement lock is used. JS/wasm-gc, full-suite validation, and documentation-index integration remain with the root task.
