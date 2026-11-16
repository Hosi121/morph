# Independent exact primitive-coordinate oracle (2026-11-17)

This finite regression oracle uses SymPy 1.14.0 exact algebraic expressions, rational matrices, QQ[t] polynomial remainders, and Python Fraction arithmetic. It does not use MoonBit output, producer internals, numerical roots, or floating approximations as expectations. The only shared code is the external complexfield oracle's exact coordinate extraction, rational literal formatting, and Fraction reduction modulo a^d-c.

For K=QQ(a), a is the positive real root of a^d=c; for QQ, d=1,c=0,a=0. The selected primitive is theta=a+i. Coordinates use the ordered QQ basis (1,a,...,a^(d-1),i,i*a,...,i*a^(d-1)). Each power-basis column comes from expanding the algebraic expression (a+i)^j. SymPy inverts that matrix exactly and both matrix products are checked against identity. Independently computed minimal polynomials have degree 2d and vanish under exact substitution. The resulting alpha and i image polynomials and every sample conversion also recover their exact algebraic expressions by substitution. Polynomial coefficient arrays use increasing powers of t; matrix literals contain rows.

Each product is checked three ways before emission: direct algebraic-expression multiplication, QQ[t] remainder modulo the independent minimum, and Fraction multiplication in the original real/imaginary quotient basis. MoonBit tests compare prepare's basis and inverse matrices, modulus, generator images, canonical conversions, and product coefficients against these external values. They also pass an independently populated representation certificate to check and from_certificate, and bind each conversion with check_conversion_for.

```json
{"ambient_degrees": [2, 4, 6, 8], "conversions": 23, "exact_basis_matrices": 5, "exact_inverse_matrices": 5, "fields": 5, "products": 12}
```

| Field | Degree | Minimum of theta | Alpha image | i image | Samples | Products |
| --- | ---: | --- | --- | --- | ---: | ---: |
| QQ(i) | 2 | `t**2 + 1` | `0` | `t` | 4 | 2 |
| QQ(sqrt2)(i) | 4 | `t**4 - 2*t**2 + 9` | `-t**3/6 + 5*t/6` | `t**3/6 + t/6` | 6 | 3 |
| QQ(sqrt3)(i) | 4 | `t**4 - 4*t**2 + 16` | `-t**3/8 + t` | `t**3/8` | 4 | 2 |
| QQ(cbrt2)(i) | 6 | `t**6 + 3*t**4 - 4*t**3 + 3*t**2 + 12*t + 5` | `6*t**5/11 - 9*t**4/22 + 20*t**3/11 - 39*t**2/11 + 50*t/11 + 91/22` | `-6*t**5/11 + 9*t**4/22 - 20*t**3/11 + 39*t**2/11 - 39*t/11 - 91/22` | 4 | 2 |
| QQ(fourthroot2)(i) | 8 | `t**8 + 4*t**6 + 2*t**4 + 28*t**2 + 1` | `5*t**7/24 + 19*t**5/24 + 5*t**3/24 + 151*t/24` | `-5*t**7/24 - 19*t**5/24 - 5*t**3/24 - 127*t/24` | 5 | 3 |

The sqrt2 case fixes the nontrivial high-power reduction (sqrt2+i)^8 = 17-56*sqrt2*i = 45-28*t^2. The product of the fourth power with itself must return that same canonical polynomial, not an unreduced degree-eight expression.

The quartic-real-base case fixes theta^(-1) as `-t**7 - 4*t**5 - 2*t**3 - 28*t`. Its original quotient expression is `-2**(1/4) + 2**(3/4) - sqrt(2)*I + I` after rationalization; direct exact substitution and an independent QQ[t] modular inverse agree. Multiplying theta by this element has the pinned canonical polynomial 1.

Run `python3 tools/generate_complexprimitive_fixtures.py --check` in the pinned SymPy environment. Regeneration formats only its generated MoonBit fixture with the repository SDK's moonfmt. The fixtures cover five specified real bases and small deterministic samples; they are regression evidence, not a proof for arbitrary fields or a scalability result.

Milestone validation: regeneration check passes, and `tools/measure --cpu 4 tools/moon test src/complexprimitive --target native --release -j 1` passes 11 tests, including these five oracle cases. The shared measurement lock is used. JS and wasm-gc validation remains with the integrating root task.
