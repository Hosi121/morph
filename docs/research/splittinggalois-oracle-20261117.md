# Independent finite splitting-field Galois oracle (2026-11-17)

This oracle fixes finite root-permutation groups using pure host integer permutations, independent of the MoonBit traversal, map order, root order, primitive choice, or producer certificates. It reuses the independent SymPy 1.14.0/Fraction ambient model of generate_complexsubfield_fixtures.py for exact field coordinates. Rational-power inequalities bind each selected real source; no floating approximation or producer output supplies an expectation.

C1 covers constant and rational linear polynomials. C2 covers real and Gaussian quadratics. Each cubic t^3-2 and t^3+2 has all six permutations: on roots c*omega^j, the affine actions j -> k+s*j modulo 3, k=0,1,2 and s=+1,-1, are exactly S3. The quartic root order [a,-a,i*a,-i*a] has phase exponents [0,2,1,3]. Exactly eight of its 24 permutations are the D4 affine actions e -> k+s*e modulo 4. The complete accepted permutation SET is compared after reindexing returned roots to these independent canonical values.

Composition is left after right, computed directly as left[right[j]]. Python independently derives every table entry and inverse, then checks group laws using integer arithmetic. Cycle types, center sizes, and derived-subgroup sizes below are independently computed finite diagnostics. Exact ambient action matrices substitute c->c*omega^k, sqrt3->s*sqrt3, i->i for S3, and a->i^k*a, i->s*i for D4. Each matrix is checked on every root and by Fraction products; exact SymPy substitution independently checks sample images. The selected S3 extensions fix i in the degree-12 ambient, while apply must reject i and sqrt3 because neither belongs to the minimal degree-6 splitting field.

MoonBit obtains linear/quadratic/cubic Splitting handles through solve, and supplies the four exact quartic roots to solve_from_roots. For cubic sources it reconstructs positive cbrt(2) and sqrt3 from the actual ordered roots using exact sign realization and division, yielding the independent real primitive a=cbrt(2)+sqrt3 even if the producer selected another real generator. An exact rational change of coordinates expresses any returned primitive in this independent ambient basis. Applying the external action matrix then pins generator_image without assuming a producer candidate or basis order. Independently populated MapCertificates and the host table are imported as a separate full group certificate. Every map's root action, inverse, composition, sum/product preservation, and externally fixed sample images are checked. Source/result binding and zero-budget pause/resume are included.

```json
{"accepted_permutations": 26, "cases": 7, "compositions": 146, "inverses": 26, "orders": [1, 2, 6, 8], "root_actions": 77, "sample_images": 104}
```

| Case | Splitting degree / group order | All root permutations | Accepted | Center order | Derived order | Cycle-type counts |
| --- | ---: | ---: | ---: | ---: | ---: | --- |
| constant C1 | 1 | 1 | 1 | 1 | 1 | `{'()': 1}` |
| linear C1 | 1 | 1 | 1 | 1 | 1 | `{'(1,)': 1}` |
| real quadratic C2 | 2 | 2 | 2 | 2 | 1 | `{'(1, 1)': 1, '(2,)': 1}` |
| Gaussian C2 | 2 | 2 | 2 | 2 | 1 | `{'(1, 1)': 1, '(2,)': 1}` |
| S3 for t^3-2 | 6 | 6 | 6 | 1 | 3 | `{'(1, 1, 1)': 1, '(1, 2)': 3, '(3,)': 2}` |
| S3 for t^3+2 | 6 | 6 | 6 | 1 | 3 | `{'(1, 1, 1)': 1, '(1, 2)': 3, '(3,)': 2}` |
| quartic D4 | 8 | 24 | 8 | 2 | 2 | `{'(1, 1, 1, 1)': 1, '(1, 1, 2)': 2, '(2, 2)': 3, '(4,)': 2}` |

Regenerate with `python3 tools/generate_splittinggalois_fixtures.py`, or pass `--check` for exact reproduction. The source math and previously validated generated-field oracles support these bounded fixtures; this is finite regression evidence, not an arbitrary-field proof or a scalability result. Root owns JS/wasm-gc, full-suite validation and cleanup.

Milestone validation: exact regeneration passes, and `tools/measure --cpu 4 tools/moon test src/splittinggalois --target native --release -j 1 --deny-warn` passes all seven independent oracle fixtures. Scoped fmt/check/info and the repository purity gate pass. Native tests and fixture generation use the shared measurement lock.
