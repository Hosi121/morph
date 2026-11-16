# Exact real algebraic numbers, 2026-11-16

This package represents a real number by a nonzero rational univariate polynomial and a rational half-open interval `(lower, upper]` containing exactly one distinct real root. Construction checks that condition with the existing Sturm package; repeated and reducible defining polynomials are allowed and normalized to a monic square-free definition. No floating point or external CAS occurs in production code. This is executable exact arithmetic and certificate checking, not a formal proof of the MoonBit implementation or an asymptotic performance claim.

## Representation, comparison, and resultants

[Number construction and comparison](../../src/realalgebraic/number.mbt), [resultant construction/checking](../../src/realalgebraic/resultant.mbt), and [generated public API](../../src/realalgebraic/pkg.generated.mbti).

`Number` is opaque, and deliberately has no structural `Eq` interface that could be mistaken for numeric equality. `compare` returns an exact ordering with a `ComparisonCertificate`, or a resumable `ComparisonPaused`. Fuel counts paired rational bisections. If the input intervals are separated, their ordering is certified immediately. Otherwise the gcd of the two definitions is used: a gcd root in their half-open intersection must be the unique selected root of both numbers. Interval overlap alone never proves equality. Distinct roots with overlapping intervals are refined until separated; exhausting fuel preserves a paused state. `check_comparison` rechecks input root certificates, contained one-root refinements, and the ordering argument without replaying the refinement search.

For monic definitions of degrees `m,n`, resultant construction targets

```text
Sum:     Res_y(P(y), Q(x-y))
Product: Res_y(P(y), y^n Q(x/y))
```

Each is a monic polynomial of degree `m*n`, whose roots are all pairwise sums or products of the complex input roots (with multiplicity). In particular the desired real operation result is a root; these polynomials generally are not minimal polynomials. The resultant root identities are established in §3 of [Joosten, Thiemann and Yamada, *A Verified Implementation of Algebraic Numbers in Isabelle/HOL*](https://link.springer.com/content/pdf/10.1007/s10817-018-09504-w.pdf). The associated [Archive of Formal Proofs development](https://isa-afp.org/entries/Algebraic_Numbers.html) separates resultants, Sturm theory, real representations, and interval arithmetic.

`resultant_start` normalizes the two input definitions to monic form. `resultant_advance` evaluates exact Sylvester determinants at the rational integers `0,...,m*n` and incrementally interpolates. One fuel unit completes one determinant/interpolation point; exhaustion returns `ResultantPaused`, and `m*n+1` points suffice. Its checker independently recomputes every determinant sample and evaluates the claimed polynomial there, imposing degree at most `m*n`; it does not replay interpolation. The finite sample equality therefore identifies the unique resultant polynomial, using the mathematical degree bound.

The Sylvester matrix always retains the original nominal degrees and zero padding, including at samples where `y^n Q(x/y)` loses degree or becomes zero. This avoids the specialization trap described in the official [FLINT evaluation/interpolation resultant documentation](https://flintlib.org/doc/algorithms/multivariate/modp-bivariate-resultant.html). The fixed-degree determinant is itself a polynomial in `x`; the first monic input also eliminates leading-coefficient scaling ambiguity when the second specialization drops degree.

The current standalone resultant API requires nonconstant, nonzero univariate inputs. The budgets count high-level steps, not bit operations or wall time inside exact determinants, GCDs, or Sturm construction.

## Validation

The [independent generator](../../tools/generate_realalgebraic_fixtures.py) uses SymPy 1.14.0's symbolic resultant, while production uses rational determinants and interpolation. Its [fixtures](realalgebraic-20261116-fixtures.json) include nonmonic rational input normalizations, shared roots, both inputs zero at the selected specialization, and polynomial product transforms with permanently or transiently dropped leading terms. All 14 resultant polynomials match exactly, including multiplicities.

The initial comparison/resultant commit `7a33d59` passed **18 tests** on native, JS and WasmGC. The complete arithmetic package now passes **70 tests on all three backends**, with a further **494 arithmetic cases** inside the independent signed-rational grid test. Tests include invalid/empty/reversed/multiple-root intervals, excluded lower and included upper endpoints, repeated-root definitions, equality across different definitions, close unequal roots, pausing/resumption, altered comparison proofs, missing sample lists, wrong resultant polynomials, and exact `m*n` versus `m*n+1` point fuel boundaries.

```sh
python3 tools/generate_realalgebraic_fixtures.py --check
tools/measure --cpu 8 .tools/moon/bin/moon test src/realalgebraic --target native
tools/measure --cpu 8 .tools/moon/bin/moon test src/realalgebraic --target js
tools/measure --cpu 8 .tools/moon/bin/moon test src/realalgebraic --target wasm-gc
tools/measure --cpu 8 .tools/moon/bin/moon check src/realalgebraic --deny-warn
python3 tools/audit_purity.py
```

## Arithmetic and conjugate selection

[Binary arithmetic](../../src/realalgebraic/arithmetic.mbt), [unary arithmetic](../../src/realalgebraic/unary.mbt), and [division](../../src/realalgebraic/division.mbt) provide sum, product, negation, reciprocal, and quotient. All return either a checked `Number` and operation certificate or a resumable `Paused` state; reciprocal and quotient with a zero selected denominator return `Err(ZeroDivisor)`. Unary/binary/quotient checkers recheck algebraic identities and selected-root enclosures independently of the search.

The polynomial identity and real conjugate selection are separate obligations. A valid resultant establishes existence of the intended operation root. The closed relaxation `[l,u]` of each input interval contains its selected number. Addition uses endpoint sums; multiplication uses the minimum and maximum of all four endpoint products. For binary operations these raw closed ranges are padded at both ends by `width(left)+width(right)`. Thus the intended result lies strictly inside the padded interval even if it attained the raw minimum. A single-root Sturm count in the resulting half-open interval identifies precisely that root.

If several resultant roots occur in the enclosure, both inputs are bisected and the enclosure recomputed. Input widths halve, and the product range and padding shrink to the true operation value; the resultant has finitely many distinct roots, so sufficient fuel eventually isolates the desired root. No dependency assumption between the two inputs is needed. In particular identical operands, opposite roots, and repeated resultant roots are supported. Sturm square-free normalization counts repeated roots once. The output definition need not be minimal or irreducible.

For negation the polynomial becomes `P(-x)`, and the reversed closed interval `[-u,-l]` is padded by the input width. For reciprocal the polynomial is `x^degree(P)*P(1/x)` with zero trailing coefficients removed; this is valid for a selected nonzero root even if another root of `P` is zero. The selected root is tested for zero by exact polynomial evaluation and half-open membership. A nonzero selected root is refined until the **closed** interval avoids zero, then its reciprocal range `[1/u,1/l]` is padded by its own positive width. This deals with the case where the transformed target root is exactly the raw lower endpoint. Padding tends to zero under refinement, so no root is lost through a half-open boundary.

The result certificate checks that refined input intervals are contained one-root intervals, that resultant input definitions match the selected inputs, that the output definition is the monic square-free transformed polynomial, and that the returned interval is the recomputed padded enclosure with exactly one root. The proof-only `check_arithmetic`, `check_unary`, `check_quotient`, and `check_comparison` functions validate the result/input/ordering claims embedded in their certificate. Since the public progress constructors can be reconstructed by callers, these functions do **not** bind a separately supplied `Number` or `Ordering` payload. Call `check_arithmetic_result(value, proof)`, `check_unary_result(value, proof)`, `check_quotient_result(value, proof)`, or `check_comparison_result(order, proof)` to validate such a pair. These additionally require the payload's exact normalized defining polynomial and interval to equal the certificate's recorded result (or exact ordering equality). A numerically equal root with a different valid interval or defining polynomial is deliberately rejected by this representation-binding check; use the numeric comparison API for equivalence of different representations. Tests combine a genuine proof with an unrelated, valid number/ordering and verify rejection, as well as binding acceptance for producer outputs.

The raw `check_root` check by itself only proves that a representation denotes a number; it does not establish that it is the result of an operation. Tests deliberately replace an arithmetic result by a different, individually valid conjugate and confirm that the operation checker rejects it.

Binary fuel covers one determinant/interpolation point or one paired bisection. Unary fuel covers one source bisection. Division composes a checked reciprocal and product, sharing one budget across reciprocal bisections, product sample points, and product bisections. Phase changes and already-determined one-root checks do not consume fuel. The paused states are opaque and retain completed interpolation/refinement work. No unfinished stage returns a number.

## Extended independent validation and limitations

SymPy generates another **30 sum/product/quotient fixtures** and **11 negation/reciprocal fixtures**, using `minpoly`, exact rational root-isolating intervals, and exact sign checks to select the expected conjugate. Cases include square and cube roots, negative inputs, rational nonmonic definitions, zero results, and close roots. Production is compared against these minimal-polynomial/root-interval pairs by exact gcd/root comparison; it is not required to return the same nonminimal definition.

The independent native rational grid uses 13 distinct rationals of both signs (including zero) and checks all 169 sums, all 169 products, and all 156 nonzero-denominator quotients against native integer numerator/denominator formulae: **494 operations**. Each returned operation proof is checked. Extra adversarial tests cover exact point-budget boundaries, resultants forged by adding a degree-`m*n+1` polynomial vanishing at every sample (rejected by the degree check), wrong conjugates, altered input normalization, invalid refinements, and changed result intervals.

The [validation transcript](realalgebraic-20261116-validation.json) records commands, outputs and exit codes. Command wall times include incremental compilation and test runners; they are not algorithm benchmarks. All compilation/testing is under the shared `tools/measure --cpu 8` lock. The handwritten source passes the repository purity gate.

Practical limits include resultant degree growth under repeated operations, exact rational coefficient growth, repeated determinant work in certificate checking, and no specialized rational or minimal-polynomial fast path. There is no approximate fallback, general root-extraction operator, factorization-based minimal-polynomial reduction, or global bit-operation/time budget. Existing symbolic rational arithmetic, polynomial GCD, exact determinant, and Sturm correctness are implementation dependencies. Root integration owns shared inventories and documentation navigation.
