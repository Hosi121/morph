# Symbolic Berlekamp–Zassenhaus, 2026-11-16

This package implements exact factorization of nonzero univariate integer and rational polynomials. It combines existing finite-field Berlekamp and rational-polynomial GCD packages with new primitive normalization, characteristic-zero square-free decomposition, simultaneous Hensel lifting, and exhaustive Zassenhaus recombination. All production arithmetic uses immutable symbolic ADTs. Numeric conversion, arrays, and external CAS calls occur only in tests and the fixture generator.

The package has 454 tests passing on native, JS, and WasmGC, including independent SymPy fixtures and a complete small coefficient grid. This is an executable algorithm and certificate checker, not a machine-checked proof of the implementation or a performance improvement claim.

## API and supported domain

- [Generated API](../../src/zassenhaus/pkg.generated.mbti), [integer polynomial operations](../../src/zassenhaus/polynomial.mbt), [lifting](../../src/zassenhaus/hensel.mbt), [factorization and checking](../../src/zassenhaus/factorization.mbt).
- `polynomial` takes ascending integer coefficients and removes trailing zeros. Integer outputs have a signed content and distinct primitive, positive-leading factors with positive multiplicities. Nonmonic factors are supported directly.
- `factor_rational` accepts ascending rational coefficients, clears denominators, and returns a rational unit with the same primitive integer factors. This also supports nonintegral monic normalizations.
- The zero polynomial returns `Err(ZeroPolynomial)`. Nonzero constants return their content/unit and no factors. There is no machine-word coefficient limit; practical time, memory, and recursion limits remain.
- The caller supplies a finite ordered prime-candidate list. Composite candidates, primes dividing the leading coefficient, and primes for which the square-free component becomes nonsquarefree are skipped. The first suitable candidate is used; the driver does not optimize the number of modular factors.
- `lift_fuel` bounds **additional linear lifting steps per square-free component**, starting at exponent one. `subset_fuel` bounds **subset leaves per component**, including the empty and full subsets; complete enumeration of `r` modular factors costs exactly `2^r` leaves. Exhaustion returns `Incomplete(NoGoodPrime | LiftBudget | RecombinationBudget)` and never `Complete`.
- These are operation-count bounds for the specified loops, not a wall-clock bound on primality testing, Berlekamp splitting, GCD, or integer arithmetic.
- The irreducibility checker separately takes a subset budget **per claimed integer factor**. Exhaustion returns `Undecided`; invalid data or an exhibited proper factor returns `Refuted`; only completed exhaustion returns `Proven`.
- Hensel seeds need only be monic, positive-degree and pairwise coprime. They need not be irreducible. The factorization certificates additionally require checked finite-field irreducibility certificates.

## Mathematical invariants and completeness boundary

Let `F` be a primitive square-free component with positive leading coefficient `a`, degree `n`, and supplied prime `p` not dividing `a`. Factor its reduction as `a * product(f_i)` with distinct monic irreducible `f_i`.

For current monic lifts `g_i` at `m=p^k`, the invariant is `F = a*product(g_i) mod m`, `g_i=f_i mod p`, and `degree(g_i)=degree(f_i)`. The correction is

```text
E = (F - a*product(g_i))/m mod p
c_i = inverse(a*product(j != i, f_j)) mod f_i
delta_i = E*c_i mod f_i
g_i' = g_i + m*delta_i mod (m*p)
```

The integer division defining `E` is checked exactly. Pairwise coprimality makes every `c_i` exist. The sum of correction terms equals `E`: the difference vanishes modulo each `f_i` and has degree below their product. Thus the update preserves the product at `mp` and each monic degree. The producer checks the next invariant before returning. `Lift` is opaque, and `lift_above` can return a resumable `Suspended(Lift)`.

The precision uses `B = 2^n * sum(abs(coeff(F)))`. Landau's inequality bounds Mahler measure by the Euclidean coefficient norm; multiplicativity and the fact that a nonzero integer polynomial has Mahler measure at least one give `abs(coeff(g)) <= 2^degree(g)*||F||_2 <= B` for every integer divisor `g`. The source correspondence is §7 of [Divasón et al., *A Verified Implementation of the Berlekamp–Zassenhaus Factorization Algorithm*](https://link.springer.com/content/pdf/10.1007/s10817-019-09526-y.pdf); its §8 describes linear prime-power lifting and uniqueness, and §9 describes subset reconstruction.

For a primitive positive-leading divisor `g` with leading coefficient `b`, `b` divides `a`, and `g mod p` corresponds to a subset of the modular factors. Uniqueness of monic coprime lifts gives

```text
a*product(subset(g_i)) = (a/b)*g mod m.
```

Each coefficient on the right is at most `a*B` in magnitude. Therefore the strict precision requirement `m > 2*a*B` makes symmetric residue reconstruction unique. Taking the primitive part recovers exactly `g`, including its nonmonic leading coefficient. This is the recovery lemma in the official [FLINT integer polynomial factorization documentation](https://fredrikj.net/fdoc/html/algorithms/polynomials/factoring-integers.html#bounds-and-precision). The implementation uses a looser coefficient bound to avoid floating point, logarithms, square roots, or hidden rounding assumptions.

Every possible true divisor therefore appears among the recovered subset candidates. The producer enumerates all subsets before success and recursively splits by recovered exact divisors. A final unsplit leaf is irreducible because a proper divisor would have appeared. This deliberately uses full subsets instead of the degree/cardinality pruning in faster Zassenhaus implementations. The checker independently traverses all subsets and rejects any recovered proper divisor of the claimed factor. Its certificate root may be the larger square-free component: every divisor of a claimed factor also divides that root, so the same bound and complete modular factors suffice.

## What certificates do and do not establish

`check_product` only expands the proposed factors with multiplicities and checks integer equality. A deliberately forged factorization with the entire reducible input as one factor passes that function and fails `check_factorization`.

`check_lift` validates primality, positive exponent, exact prime-power modulus, coefficient residue ranges, monic degree-preserving lifts, reductions, pairwise coprimality and the product congruence. It does not claim integer irreducibility and need not re-execute the lifting history: coprime monic lifting uniqueness identifies the verified residues.

`check_irreducible` additionally requires primitive normalization, exact divisibility of the certificate root by the claimed factor, sufficient computed precision, a complete list of finite-field irreducibility certificates, and exhaustive recombination without a proper divisor. Neither a caller-supplied bound nor a caller assertion of exhaustion is trusted. `check_factorization` adds distinct factors, nonzero multiplicities, and full reconstruction. `check_rational_factorization` checks the scaled unit is integral before invoking the integer checker.

Trusted implementation dependencies include symbolic binary/exact arithmetic, prime-field primality checking, and the finite-field irreducibility verifier. No Isabelle/Lean theorem about this MoonBit code is claimed. The algorithm's expected exponential recombination cost remains; LLL, early termination, quadratic lifting, degree pruning, and prime-selection heuristics are deliberately absent.

## Independent fixtures and validation

The [generator](../../tools/generate_zassenhaus_fixtures.py) uses SymPy 1.14.0's integer/rational `factor_list` and its **quadratic divide-and-conquer** `dup_zz_hensel_lift`, independently of this package's linear simultaneous corrections. The official [SymPy factorization source](https://github.com/sympy/sympy/blob/1.14.0/sympy/polys/factortools.py) specifies the nonmonic lifting contract. Generated [fixture data](zassenhaus-20261116-fixtures.json) and [MoonBit tests](../../src/zassenhaus/fixtures_wbtest.mbt) are retained.

Targeted set: 5 Hensel fixtures, 19 integer factorizations and 5 rational factorizations. A further **412 cases** exhaust every primitive degree-two or degree-three polynomial with leading coefficient 1–3 and all lower coefficients in −2–2: **259 irreducible and 153 reducible**. SymPy factorizations are cross-checked independently by native integer rational-root enumeration (which is complete for degrees two and three). Every generated MoonBit case also checks its factorization certificate. Cases cover repeated factors, nontrivial signed content, rational denominators, nonmonic factors, irreducible polynomials that split modulo the selected prime, and lifts through consecutive prime powers up to exponent five. Additional handwritten tests cover zero/constants, degree-losing and repeated-root primes, incompatible fields, repeated modular seeds, altered target/modulus/exponent/factor lists, insufficient reconstruction precision, both exhausted budgets, exact subset-leaf exhaustion, a precision exactly equal to the threshold, noncanonical lift residues, corrupted finite-field witness payloads, and product-only forgery.

Commands (all compilation/testing is serialized by the repository's shared lock and pinned to CPU 8):

```sh
python3 tools/generate_zassenhaus_fixtures.py --check
tools/measure --cpu 8 .tools/moon/bin/moon test src/zassenhaus --target native
tools/measure --cpu 8 .tools/moon/bin/moon test src/zassenhaus --target js
tools/measure --cpu 8 .tools/moon/bin/moon test src/zassenhaus --target wasm-gc
python3 tools/audit_purity.py
tools/measure --cpu 8 .tools/moon/bin/moon info src/zassenhaus
```

Result: **454 passed, 0 failed on each backend**. The first verified commit was `df66e93` (36 tests); the later grid and boundary cases expand that coverage. The [validation transcript](zassenhaus-20261116-validation.json) records commands, exit codes and output; its command wall times include build/runner overhead and are not an algorithm benchmark. Purity audit: **125 kernel files passed**. Interfaces were generated by `moon info`, not handwritten. Root integration owns repository inventories, documentation navigation, and complete integrated checks; only the namespaced package, generator, and research artifacts are changed here.
