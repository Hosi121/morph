# Exact complex algebraic arithmetic

`Number` stores a pair of validated `realalgebraic.Number` values. `number`,
`real_part`, and `imaginary_part` form the integration boundary with root
isolation. Construction preserves each coordinate's exact representation.

`add`, `subtract`, `multiply`, `divide`, `negate`, and `conjugate` return
`Result[ArithmeticProgress, realalgebraic.AlgebraError]`. Resume
`ArithmeticPaused(state)` with `arithmetic_advance(state, more_fuel)`;
`ArithmeticReady(value, proof)` is the only numeric success. Division by the
selected complex zero returns `ZeroDivisor`, including at zero fuel.

The operations use fixed straight-line formulas on the coordinates. Division
shares the denominator `c*c+d*d` between its two quotient coordinates. Every
completed instruction and the active real-algebraic continuation survive a
pause. Fuel counts instruction startups plus the sample/refinement units of
the underlying real operations. Rational instructions consume one startup
unit. Polynomial setup, gcds, a resultant sample, and proof verification can
each do substantial exact work within one unit; fuel is not a wall-clock or
bit-complexity bound.

The rational path applies when the complete defining polynomial of an operand
has degree one. It extracts the unique rational root from all coefficients,
computes with exact rationals, and constructs the canonical real rational
result. The checker independently repeats these coefficient and rational
computations. It never assumes that an algebraic result with a rational value
has a linear defining polynomial.

`check_arithmetic` validates the fixed recipe, every real witness, all
intermediate connections, both source coordinate certificates, and the result.
It rejects missing, extra, reordered, or misbound steps. This is an executable
certificate checker built on the existing real-algebraic checkers, not a formal
proof of the implementation. `check_arithmetic_result` also binds a separate
result payload. `check_arithmetic_for` binds both external operands, operation,
and payload. Unary recipes use the left operand; their convenience functions
record the same input as the right operand as well.

Representation binding deliberately compares the exact normalized defining
polynomial and isolating interval. For numeric equality, use `equal`, resume
`EqualityPaused` with `equality_advance`, and accept only `EqualityReady`.
Coordinate comparisons use exact gcd/common-root certificates. Interval
overlap alone cannot establish equality or inequality. The equality checker
family similarly binds embedded sources, a separate boolean result, or both.
`is_zero` is a total exact predicate on valid numbers: each coordinate is zero
precisely when its half-open isolating interval contains zero and its defining
polynomial vanishes at zero.

Resultants retain conjugate roots; the representation does not compute minimal
polynomials or share a primitive field. Nested arithmetic can therefore grow
polynomial degrees, coefficients, certificates, and checking cost substantially.
The degree-one rational path and shared division denominator address specific
avoidable work but carry no measured speed claim. No floating-point
approximation or machine numeric is used in the kernel.

The package tests compare 60 Gaussian rational operations against independent
integer formulas, verify `i*i=-1`, exercise `sqrt(2)` and `sqrt(3)` arithmetic
and division, distinguish equality from representation binding, resume both
rational and algebraic jobs, check selected-root zero behavior, and reject
forged sources, formulas, intermediate witnesses, results, and booleans.
