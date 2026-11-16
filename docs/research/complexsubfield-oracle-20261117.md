# Independent exact generated complex subfield oracle (2026-11-17)

This finite oracle uses SymPy 1.14.0 and Python Fraction arithmetic. No MoonBit output, producer basis order, producer primitive trial order, numerical root, or floating approximation supplies an expectation. All polynomial arrays use increasing powers. The source ambient basis is (1,a,...,a^(d-1),i,i*a,...,i*a^(d-1)).

For each generator its independent SymPy minimum bounds its exponent. The complete Cartesian set of bounded monomials therefore spans the generated algebra. SymPy rational rref selects an independent subset, computes a rectangular left inverse and the full annihilator, and independently verifies the rank of the whole set. Fraction quotient multiplication modulo the real minimum and i^2+1 is checked against SymPy QQ[t] remainders. Every basis product with every generator is in the resulting span, as is every pairwise basis product. This establishes the exact generated degree and excludes a larger ambient field which merely contains the inputs.

MoonBit tests import independently populated monomial certificates and primitive certificates; they do not assume generate returns the same basis order. Returned bases are checked against the independent span, and both basis dimensions agree. Independent left inverses pin imported basis coordinates and inclusion boundaries. Each input generator's minimum is compared with its independent SymPy minimum. Primitive certificates use the independently chosen monomial basis and an independently searched small integer candidate. Their modulus, ambient power matrix, canonical conversions, and unreduced polynomial evaluation are externally computed. Returned producer primitives are checked for degree, field binding, and reconstruction; the independent imported representation supplies the pinned quotient expectations.

```json
{"ambient_degrees": [2, 4, 8, 12], "cases": 10, "conversions": 57, "exhaustive_monomials": 55, "generated_degrees": [1, 2, 4, 6, 8], "independently_populated_field_certificates": 10, "independently_populated_primitive_certificates": 10}
```

| Case | Ambient degree | Generated degree | Complete monomials | Independent candidate | Primitive minimum |
| --- | ---: | ---: | ---: | ---: | --- |
| empty generators | 2 | 1 | 1 | 0 | `t - 1` |
| rational generators | 2 | 1 | 1 | 0 | `t - 1` |
| Gaussian unit | 2 | 2 | 2 | 1 | `t**2 - 2*t + 2` |
| real sqrt2 | 4 | 2 | 2 | 1 | `t**2 - 2*t - 1` |
| dependent sqrt2 generators | 4 | 2 | 4 | 1 | `t**2 - 2*t - 1` |
| independent sqrt2 and i | 4 | 4 | 4 | 1 | `t**4 - 4*t**3 + 8*t**2 + 8*t + 4` |
| cube root of unity | 4 | 2 | 2 | 1 | `t**2 - t + 1` |
| sqrt2 plus i sqrt3 | 8 | 4 | 4 | 1 | `t**4 - 2304*t + 16128` |
| independent sqrt2 sqrt3 and i | 8 | 8 | 8 | 1 | `t**8 - 8*t**7 + 32*t**6 + 288*t**5 + 992*t**4 + 1152*t**3 + 512*t**2 - 512*t + 256` |
| all roots of t^3-2 | 12 | 6 | 27 | 1 | `t**6 + 15*t**4 + 48*t**3 + 63*t**2 + 36*t + 9` |

The degree-12 source uses a=cbrt(2)+sqrt(3), selected by the exact interval (2,3]. SymPy primitive_element independently returns multipliers [1,1] and the irreducible real minimum `t^6-9*t^4-4*t^3+27*t^2-36*t-23`. Exact root counting gives one root in the chosen interval. Selected values are bound algebraically: (5/4)^3<2<(63/50)^3 and (17/10)^2<3<(26/15)^2 imply 59/20<a<449/150<3. The other source intervals use the same rational-power method, never an approximate radical sign comparison. MoonBit normalizes this single real root to a verified number field; the oracle needs no compositum producer to build the source.

The cbrt(2) image in QQ[a] is `-2*t**5/51 - t**4/102 + 20*t**3/51 + 13*t**2/51 - 38*t/51 + 91/102`; the sqrt(3) image is `2*t**5/51 + t**4/102 - 20*t**3/51 - 13*t**2/51 + 89*t/51 - 91/102`. SymPy to_number_field verifies both identities exactly. The three roots c, c*omega, c*omega^2 of t^3-2 have complete monomial rank 6 inside ambient rational dimension 12. They generate c and omega because c is nonzero and omega=(c*omega)/c; conversely c and omega express all three roots. Thus the generated field is the S3 splitting field of degree 6, while the degree-12 source is oversized. In particular sqrt(3) and i are excluded individually, whereas i*sqrt(3)=2*omega+1 is included.

Regenerate with `python3 tools/generate_complexsubfield_fixtures.py`; check reproducibility with `--check`. Only the generated fixture and this document are rewritten; moonfmt formats the fixture through the pinned repository SDK. These bounded cases are regression evidence and make no performance or arbitrary-field correctness claim. Integration owns JS/wasm-gc validation and the full-suite checks.

Milestone validation: the regeneration check passes, and `tools/measure --cpu 4 tools/moon test src/complexsubfield --target native --release -j 1` passes all 10 independent oracle cases, including degree 12 to degree 6. Scoped MoonBit formatting/checking and the repository purity gate pass. The shared performance lock is used for native tests and fixture generation.
