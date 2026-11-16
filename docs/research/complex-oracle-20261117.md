# Independent exact complex oracle (2026-11-17)

The finite oracle checks the complex-root milestone without importing producer code or using its real-variety/RUR construction. It uses pinned SymPy **1.14.0** and Python `Fraction`; decimal approximations and numerical roots are never correctness inputs.

## Evidence and schema

For each rational polynomial, sparse `Fraction` Horner arithmetic in pairs of bivariate polynomials computes `Re p(x+i*y)` and `Im p(x+i*y)`. SymPy's symbolic complex expansion independently checks every coefficient. `Poly.all_roots(multiple=False)` supplies exact algebraic expressions; exact substitution and derivatives establish each stated multiplicity. The multiplicities sum to the degree, and pairwise disjoint rational coordinate boxes distinguish all roots. This establishes completeness for these cases over the complex algebraic closure.

Each coordinate has an exact minimal polynomial, verified by substitution. Irrational coordinates use strict rational isolating intervals, with a single root of the minimal polynomial. All nonrational coordinates here have a binomial minimal polynomial `t^d-c`; their signs follow from products of positive rational powers. Comparing rational `d`th powers, with the selected sign branch, proves each endpoint inequality using `Fraction` alone. Rational coordinates use singleton intervals. Boxes are closed; all are pairwise disjoint within their source polynomial. The source squarefree degree also equals the distinct-root count.

The generated MoonBit helper receives ascending rational coefficients `(numerator, denominator)`, Cartesian terms `((numerator, denominator), [x_exponent, y_exponent])`, and boxes `(re_lower, re_upper, im_lower, im_upper, multiplicity)`. Bounds are rational pairs; denominators are positive. Expected equations refer to the original source polynomial, including repeated factors and nonmonic rational scaling. Root order is not an expectation. All twelve root/weight cases run through the factor-first kernel. The unfactored reference also checks eleven root cases; its mixed-multiplicity case checks Cartesian expansion only because full-degree F4 witness growth is a recorded performance stress. Full mixed-root and multiplicity checks remain enabled in the factor-first suite.

```json
{"coordinate_certificates": 42, "distinct_roots": 21, "finite_cases": 12, "nonconstant_cases": 11, "rational_arithmetic_pairs": 6, "total_multiplicity": 25, "zero_validation_cases": 1}
```

## Expected Cartesian equations

| Case | Source p(z) | Re p(x+i*y) | Im p(x+i*y) | Distinct roots | Multiplicities |
| --- | --- | --- | --- | ---: | --- |
| zero root | `z` | `x` | `y` | 1 | 1 |
| positive rational | `z - 2/3` | `x - 2/3` | `y` | 1 | 1 |
| negative rational | `z + 2/3` | `x + 2/3` | `y` | 1 | 1 |
| imaginary units | `z**2 + 1` | `x**2 - y**2 + 1` | `2*x*y` | 2 | 1, 1 |
| real quadratic | `z**2 - 2` | `x**2 - y**2 - 2` | `2*x*y` | 2 | 1, 1 |
| translated quadratic | `z**2 + 2*z + 2` | `x**2 + 2*x - y**2 + 2` | `2*x*y + 2*y` | 2 | 1, 1 |
| cube roots of unity | `z**3 - 1` | `x**3 - 3*x*y**2 - 1` | `3*x**2*y - y**3` | 3 | 1, 1, 1 |
| cube roots of two | `z**3 - 2` | `x**3 - 3*x*y**2 - 2` | `3*x**2*y - y**3` | 3 | 1, 1, 1 |
| mixed multiplicities | `z**5 - z**4 + 2*z**3 - 2*z**2 + z - 1` | `x**5 - x**4 - 10*x**3*y**2 + 2*x**3 + 6*x**2*y**2 - 2*x**2 + 5*x*y**4 - 6*x*y**2 + x - y**4 + 2*y**2 - 1` | `5*x**4*y - 4*x**3*y - 10*x**2*y**3 + 6*x**2*y + 4*x*y**3 - 4*x*y + y**5 - 2*y**3 + y` | 3 | 1, 2, 2 |
| triple zero | `z**3` | `x**3 - 3*x*y**2` | `3*x**2*y - y**3` | 1 | 3 |
| rational scaling | `-3*z**2/5 - 3/5` | `-3*x**2/5 + 3*y**2/5 - 3/5` | `-6*x*y/5` | 2 | 1, 1 |
| nonzero constant | `7/3` | `7/3` | `0` | 0 | none |

## Exact selected roots and coordinate certificates

Here `t` is a fresh variable in each coordinate minimal polynomial. Expressions use SymPy's exact syntax: `I` is the imaginary unit and rational powers are algebraic expressions.

| Case | Exact root | Multiplicity | Real box | Imaginary box | Real minimal polynomial | Imaginary minimal polynomial |
| --- | --- | ---: | --- | --- | --- | --- |
| zero root | `0` | 1 | `[0, 0]` | `[0, 0]` | `t` | `t` |
| positive rational | `2/3` | 1 | `[2/3, 2/3]` | `[0, 0]` | `t - 2/3` | `t` |
| negative rational | `-2/3` | 1 | `[-2/3, -2/3]` | `[0, 0]` | `t + 2/3` | `t` |
| imaginary units | `-I` | 1 | `[0, 0]` | `[-1, -1]` | `t` | `t + 1` |
| imaginary units | `I` | 1 | `[0, 0]` | `[1, 1]` | `t` | `t - 1` |
| real quadratic | `-sqrt(2)` | 1 | `[-17/12, -24/17]` | `[0, 0]` | `t**2 - 2` | `t` |
| real quadratic | `sqrt(2)` | 1 | `[24/17, 17/12]` | `[0, 0]` | `t**2 - 2` | `t` |
| translated quadratic | `-1 - I` | 1 | `[-1, -1]` | `[-1, -1]` | `t + 1` | `t + 1` |
| translated quadratic | `-1 + I` | 1 | `[-1, -1]` | `[1, 1]` | `t + 1` | `t - 1` |
| cube roots of unity | `1` | 1 | `[1, 1]` | `[0, 0]` | `t - 1` | `t` |
| cube roots of unity | `-1/2 - sqrt(3)*I/2` | 1 | `[-1/2, -1/2]` | `[-13/15, -6/7]` | `t + 1/2` | `t**2 - 3/4` |
| cube roots of unity | `-1/2 + sqrt(3)*I/2` | 1 | `[-1/2, -1/2]` | `[6/7, 13/15]` | `t + 1/2` | `t**2 - 3/4` |
| cube roots of two | `2**(1/3)` | 1 | `[5/4, 24/19]` | `[0, 0]` | `t**3 - 2` | `t` |
| cube roots of two | `-2**(1/3)/2 - 2**(1/3)*sqrt(3)*I/2` | 1 | `[-7/11, -5/8]` | `[-11/10, -12/11]` | `t**3 + 1/4` | `t**6 - 27/16` |
| cube roots of two | `-2**(1/3)/2 + 2**(1/3)*sqrt(3)*I/2` | 1 | `[-7/11, -5/8]` | `[12/11, 11/10]` | `t**3 + 1/4` | `t**6 - 27/16` |
| mixed multiplicities | `1` | 1 | `[1, 1]` | `[0, 0]` | `t - 1` | `t` |
| mixed multiplicities | `-I` | 2 | `[0, 0]` | `[-1, -1]` | `t` | `t + 1` |
| mixed multiplicities | `I` | 2 | `[0, 0]` | `[1, 1]` | `t` | `t - 1` |
| triple zero | `0` | 3 | `[0, 0]` | `[0, 0]` | `t` | `t` |
| rational scaling | `-I` | 1 | `[0, 0]` | `[-1, -1]` | `t` | `t + 1` |
| rational scaling | `I` | 1 | `[0, 0]` | `[1, 1]` | `t` | `t - 1` |

## Additional validation

The nonzero constant `7/3` has no roots. The zero polynomial has identically zero real and imaginary equations and infinitely many roots; it is deliberately excluded from the finite-root helper. The zero-polynomial API check belongs to the root-owned validation tests.

Direct `Fraction` complex addition, multiplication and division supply six further exact arithmetic cases. Independent SymPy substitution checks each result. Each pair `(a,b)` denotes `a+i*b`; every divisor is nonzero.

| Left | Right | Sum | Product | Quotient |
| --- | --- | --- | --- | --- |
| `(1/2, 2/3)` | `(-3/5, 7/11)` | `(-1/10, 43/33)` | `(-239/330, -9/110)` | `(2255/13884, -4345/4628)` |
| `(0, 1)` | `(0, 1)` | `(0, 2)` | `(-1, 0)` | `(1, 0)` |
| `(3, -4)` | `(3, 4)` | `(6, 0)` | `(25, 0)` | `(-7/25, -24/25)` |
| `(0, 0)` | `(-2/7, 5/3)` | `(-2/7, 5/3)` | `(0, 0)` | `(0, 0)` |
| `(-7/13, 0)` | `(0, -11/17)` | `(-7/13, -11/17)` | `(0, 77/221)` | `(0, -119/143)` |
| `(2/9, -5/8)` | `(1, 0)` | `(11/9, -5/8)` | `(2/9, -5/8)` | `(2/9, -5/8)` |

## Reproduction and limits

Run `python3 tools/generate_complex_fixtures.py --check` with `sympy==1.14.0` (see `tools/requirements-oracles.txt`). Without `--check`, it regenerates this report and the oracle fixtures under `src/complexroots` and `src/complexfactor`. The generator formats only those fixtures through the repository's pinned `moonfmt`. The check performs every exact oracle assertion before comparing generated artifacts byte for byte.

These are finite small-degree regression facts, not a proof of the general algorithm or a scalability result. The largest source degree is five, with squarefree degree three. Rational complex arithmetic is retained as independent reference data here; this fixture helper exercises root isolation and Cartesian expansion. Kernel purity and source-bound certificates remain separate implementation checks. Native and JavaScript execution of the generated fixture requires the root implementation and its helper; the integration owner records those test outcomes.
