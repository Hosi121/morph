# Independent finite split-field automorphism oracle (2026-11-17)

The oracle fixes C2 for QQ(i), V4 for QQ(sqrt2,i), and D4 for QQ(2^(1/4),i), plus one D4 root-order permutation. These are conditional full automorphism groups of explicitly split K(i); this is not a generic QQ Galois-group or splitting-field search. For each degree-d real base, all d distinct roots of the real minimum are supplied inside K(i), and the two choices for the image of i produce the 2d maps.

Write a map as (k,s), with alpha -> i^k*alpha and i -> s*i. Map order is interleaved (+i,-i) for each supplied root. Left-after-right composition is (k,s)*(l,t)=(k+s*l mod 4,s*t), inverse=(-s*k mod 4,s), and a root with exponent q maps to exponent k+s*q mod 4. The standard quartic root order [a,-a,i*a,-i*a] has exponents [0,2,1,3]. The shuffled order [i*a,-a,-i*a,a] has exponents [1,2,3,0], so identity and conjugation occur at indices 6 and 7.

Python derives every table entry, inverse, and root-action index using finite integer arithmetic. It checks Latin rows, associativity, both inverse laws, permutation composition/inverses, and D4's rotation/conjugation relations. The root action is faithful for D4; for C2/V4 the image of i distinguishes maps in the root-action kernel. Rational sample images are independently computed by Fraction arithmetic in the quotient basis (1,a,...,i,i*a,...), with multiplication reduced modulo a^d-c and i^2+1. SymPy 1.14.0 exact simultaneous substitution crosschecks all sample images and the supplied splitting. No floats, numerical roots, MoonBit output, or producer implementation determine expected values. Shared external-oracle helpers provide only coordinate extraction, literal formatting, and Fraction base multiplication.

MoonBit compares all composition-table entries, compose results, inverses, generator images, root actions, and pinned sample sums/products. An independently populated certificate is checked and imported; source/result binding is checked against a different exact real field. The suite uses only the frozen public API despite residing in white-box test files.

```json
{"compositions": 148, "fixtures": 4, "group_orders": [2, 4, 8], "inverses": 22, "root_actions": 74, "sample_images": 88}
```

| Fixture | Root exponents | Order | Identity | Conjugation | Inverse indices |
| --- | --- | ---: | ---: | ---: | --- |
| C2 over QQ(i) | `[0]` | 2 | 0 | 1 | `[0, 1]` |
| V4 over QQ(sqrt2)(i) | `[0, 2]` | 4 | 0 | 1 | `[0, 1, 2, 3]` |
| D4 over QQ(fourthroot2)(i) | `[0, 2, 1, 3]` | 8 | 0 | 1 | `[0, 1, 2, 3, 6, 5, 4, 7]` |
| D4 with permuted root order | `[1, 2, 3, 0]` | 8 | 6 | 7 | `[4, 1, 2, 3, 0, 5, 6, 7]` |

The full table for D4 over QQ(fourthroot2)(i) (row after column):

| left/right | 0 | 1 | 2 | 3 | 4 | 5 | 6 | 7 |
| --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| 0 | 0 | 1 | 2 | 3 | 4 | 5 | 6 | 7 |
| 1 | 1 | 0 | 3 | 2 | 7 | 6 | 5 | 4 |
| 2 | 2 | 3 | 0 | 1 | 6 | 7 | 4 | 5 |
| 3 | 3 | 2 | 1 | 0 | 5 | 4 | 7 | 6 |
| 4 | 4 | 5 | 6 | 7 | 2 | 3 | 0 | 1 |
| 5 | 5 | 4 | 7 | 6 | 1 | 0 | 3 | 2 |
| 6 | 6 | 7 | 4 | 5 | 0 | 1 | 2 | 3 |
| 7 | 7 | 6 | 5 | 4 | 3 | 2 | 1 | 0 |

The full table for D4 with permuted root order (row after column):

| left/right | 0 | 1 | 2 | 3 | 4 | 5 | 6 | 7 |
| --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| 0 | 2 | 3 | 4 | 5 | 6 | 7 | 0 | 1 |
| 1 | 7 | 6 | 5 | 4 | 3 | 2 | 1 | 0 |
| 2 | 4 | 5 | 6 | 7 | 0 | 1 | 2 | 3 |
| 3 | 1 | 0 | 7 | 6 | 5 | 4 | 3 | 2 |
| 4 | 6 | 7 | 0 | 1 | 2 | 3 | 4 | 5 |
| 5 | 3 | 2 | 1 | 0 | 7 | 6 | 5 | 4 |
| 6 | 0 | 1 | 2 | 3 | 4 | 5 | 6 | 7 |
| 7 | 5 | 4 | 3 | 2 | 1 | 0 | 7 | 6 |

Run `python3 tools/generate_complexautomorphism_fixtures.py --check` with the pinned SymPy environment. Regeneration formats only the reserved generated fixture through the repository moonfmt. The small deterministic fields and samples are independent regression evidence, not a general field-theoretic proof or scalability claim.

Milestone validation: regeneration check passes, and `tools/measure --cpu 4 tools/moon test src/complexautomorphism --target native --release -j 1` passes 10 tests, including these four oracle cases. The shared measurement lock is used. JS and wasm-gc validation remains with the integrating root task.
