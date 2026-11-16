# Exact real algebraic numbers, 2026-11-16

This package represents a real number by a nonzero rational univariate polynomial and a rational half-open interval `(lower, upper]` containing exactly one distinct real root. Construction checks that condition with the existing Sturm package; repeated and reducible defining polynomials are allowed and normalized to a monic square-free definition. No floating point or external CAS occurs in production code. This is executable exact arithmetic and certificate checking, not a formal proof of the MoonBit implementation or an asymptotic performance claim.

## First verified milestone

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

Initial comparison/resultant milestone: **18 tests passed on native, JS and WasmGC**. Tests include invalid/empty/reversed/multiple-root intervals, excluded lower and included upper endpoints, repeated-root definitions, equality across different definitions, close unequal roots, pausing/resumption, altered comparison proofs, missing sample lists, wrong resultant polynomials, and exact `m*n` versus `m*n+1` point fuel boundaries.

```sh
python3 tools/generate_realalgebraic_fixtures.py
tools/measure --cpu 8 .tools/moon/bin/moon test src/realalgebraic --target native
tools/measure --cpu 8 .tools/moon/bin/moon test src/realalgebraic --target js
tools/measure --cpu 8 .tools/moon/bin/moon test src/realalgebraic --target wasm-gc
tools/measure --cpu 8 .tools/moon/bin/moon check src/realalgebraic --deny-warn
python3 tools/audit_purity.py
```

Arithmetic selection and unary operations are the next milestone; this first commit establishes the representation, exact comparison, and resultant building blocks. Root integration owns shared inventories and documentation navigation.
