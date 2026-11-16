# Independent exact K(i) oracle (2026-11-17)

The oracle uses SymPy 1.14.0 algebraic expressions and independent Fraction arithmetic. No producer code, floating approximation, numerical root, or field-kernel output is an expectation.

For K=QQ(a), a^d=c with the selected positive real root (or QQ when d=1,c=0), the QQ basis is 1,a,...,a^(d-1),i,i*a,...,i*a^(d-1). Columns come from symbolic multiplication by each basis element. Fraction Gaussian determinants and SymPy determinants agree; conjugation gives relative trace/norm. SymPy minimal polynomials annihilate the exact value, and the characteristic polynomial is their ambient-degree power. Exact inverse coordinates satisfy the product identity under Fraction reduction modulo a^d-c.

Trace and norm below belong to the ambient K(i), not necessarily QQ(element). A primitive cube root of unity has minimum degree2 inside ambient degree4, with ambient trace-2 and norm1. The cubic and quartic real bases also exercise ambient degrees6 and8.

```json
{"ambient_degrees": [2, 4, 6, 8], "cases": 18, "smaller_minimum_cases": 10}
```

| Case | Ambient QQ degree | Exact value | Trace | Norm | Minimum |
| --- | ---: | --- | --- | --- | --- |
| Gaussian unit | 2 | `I` | `0` | `1` | `t**2 + 1` |
| Gaussian rational | 2 | `1/2 - 2*I/3` | `1` | `25/36` | `t**2 - t + 25/36` |
| rational subfield | 2 | `2/3` | `4/3` | `4/9` | `t - 2/3` |
| Gaussian zero | 2 | `0` | `0` | `0` | `t` |
| sqrt2 plus i | 4 | `sqrt(2) + I` | `0` | `9` | `t**4 - 2*t**2 + 9` |
| sqrt2 real subfield | 4 | `sqrt(2)` | `0` | `4` | `t**2 - 2` |
| imaginary sqrt2 subfield | 4 | `sqrt(2)*I` | `0` | `4` | `t**2 + 2` |
| sqrt2 fractions | 4 | `-sqrt(2)/3 + 3/2 - 5*I/2 + 2*sqrt(2)*I/3` | `6` | `17761/324` | `t**4 - 6*t**3 + 82*t**2/3 - 415*t/9 + 17761/324` |
| sqrt2 eighth power | 4 | `17 - 56*sqrt(2)*I` | `68` | `43046721` | `t**2 - 34*t + 6561` |
| cube root of unity | 4 | `-1/2 + sqrt(3)*I/2` | `-2` | `1` | `t**2 + t + 1` |
| conjugate cube root of unity | 4 | `-1/2 - sqrt(3)*I/2` | `-2` | `1` | `t**2 + t + 1` |
| sqrt3 plus i | 4 | `sqrt(3) + I` | `0` | `16` | `t**4 - 4*t**2 + 16` |
| sqrt5 mixed | 4 | `1 + 2*sqrt(5) - sqrt(5)*I + 3*I` | `4` | `1205` | `t**4 - 4*t**3 - 6*t**2 - 220*t + 1205` |
| nontrivial field zero | 4 | `0` | `0` | `0` | `t` |
| rational in quartic ambient | 4 | `-7/5` | `-28/5` | `2401/625` | `t + 7/5` |
| cubic real base plus i | 6 | `2**(1/3) + I` | `0` | `5` | `t**6 + 3*t**4 - 4*t**3 + 3*t**2 + 12*t + 5` |
| cubic real subfield | 6 | `2**(1/3)` | `0` | `4` | `t**3 - 2` |
| quartic real base plus i unit | 8 | `2**(1/4) + I` | `0` | `1` | `t**8 + 4*t**6 + 2*t**4 + 28*t**2 + 1` |

The explicit quartic example has a=2^(1/4). K(i) contains a,-a,i*a,-i*a, whose monic product is z^4-2. Conversely those roots generate a and i=(i*a)/a, so this chosen ambient degree8 field is the splitting field of that example. This is an explicit construction, not a generic splitting-field algorithm.

Run `python3 tools/generate_complexfield_fixtures.py --check` with the pinned SymPy environment. Regeneration formats only the generated fixture using the repository's moonfmt. These finite cases are independent regression evidence, not a proof of the whole MoonBit kernel or a scalability claim.
