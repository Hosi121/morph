# Bivariate full Collins and product projection plans

[ドキュメント](../README.md) / [研究・探索記録](README.md)

The new `src/projection` package prepares exact projection polynomials for two-variable QQ atom lists. It does not isolate base roots, construct stacks, evaluate a Boolean formula, or return a satisfiability conclusion. Its preferred `full_collins` entry point follows the full reducta-based Collins family. A separately named `product_projection` retains the full nonzero-atom product as an alternative with explicitly stated applicability conditions.

The implementation is [plan construction and product projection](../../src/projection/projection.mbt), [all-reducta Collins construction](../../src/projection/collins.mbt), [query/payload checkers](../../src/projection/check.mbt), and the [compiler-generated API](../../src/projection/pkg.generated.mbti). It consumes only the public elimination API. The dependency snapshot is `4d1170e` for elimination and root `1f067d2`, local `9db352a`, for Berkowitz; neither implementation is changed by this package.

## Full Collins family

The primary reference is [Jovanović–de Moura, *Solving Non-Linear Arithmetic*, §4.1, Definition 2 and Theorem 2, PDF pages 9–10](https://dddejan.github.io/papers/jovanovic-ijcar2012.pdf). It uses all coefficients of each atom, principal subresultants of every reductum with its derivative, and principal subresultants of every reductum pair from distinct atoms. Sign invariance of that family on a connected region supplies delineability. Its terminal PSC convention is explicitly **one**.

`full_collins(atoms,selected)` constructs those three families. A reductum removes successive nonzero leading terms in the selected variable; missing coefficient powers do not create duplicate reducta. Each nonzero constant reductum is retained, and zero reducta are omitted. No content, shared factor, repeated factor, primitive part, or square-free factor is removed. Rational coefficients can be related to the integer-coefficient source theorem by multiplying each atom by a positive common denominator; the relevant coefficient/minor polynomials then change by nonzero constant factors, preserving the required sign/zero invariance.

The underlying generic elimination API retains its determinant convention at the top PSC index: `lc(smaller)^abs(n-m)`, or one for equal degrees. The **full Collins adapter replaces only that terminal entry by one**, exactly matching the cited projection definition. All lower entries remain the fixed-degree truncated determinants. The separate product entry point retains the generic determinant terminal values. The convention difference is deliberate and tested; consumers must not compare their raw lists as identical PSC sequences.

Output is an ordered chain rather than a deduplicated mathematical set. All nominal coefficient cells, zeros, constants, repeated polynomials and duplicate atom occurrences are retained. Such additional sign-invariant zero/constant entries do not weaken the source projection conditions. Order is deterministic: all original atom coefficient lists first; then, for each atom in order, its reducta/derivative PSCs followed by its reducta pairs with later atoms. Within each PSC sequence the index increases from zero. `polynomials(plan)` concatenates the coefficient and PSC chains. Every output polynomial has exactly one variable, in the order of the unselected source variable.

No high-degree product is built in full Collins mode: `product(plan)` is `None`. The determinant orders follow individual reductum degrees. This can avoid the much larger determinant of a complete atom product, but no performance comparison or optimality claim is made.

## Separate product entry point and its conditions

`product_projection` multiplies every nonzero original atom, including all nonzero constants, content, shared factors and multiplicities. Only identically zero source atoms are excluded from multiplication; they remain in the stored original atom list. An empty list or a list containing only zero atoms has product one. The plan returns every descending coefficient of `F` and the complete fixed-degree PSC sequence of `(F,F_y)`, including identically zero entries. A constant product and its zero derivative use the explicit constant-pair convention `[1]`.

The applicable mathematical implication is conditional. On one connected base interval where `F` is nonzero, its actual degree is constant, and the actual degree of `gcd(F,F_y)` is constant, the number of distinct complex roots is constant: in characteristic zero it equals `degree(F)-degree(gcd(F,F_y))`. With nonvanishing leading coefficient, the delineability criterion of [Chen–Moreno Maza–Xia–Yang, *Computing Cylindrical Algebraic Decomposition via Triangular Decomposition*, Theorem 1](https://math.pku.edu.cn/teachers/xiabc/html/papers/issac09.pdf) gives continuous ordered real-root sections. This is a use of that criterion, not a machine proof of this package's root geometry.

The field/gcd inference from PSCs requires actual degrees to match the chosen nominal ones. On an open interval avoiding all roots of the nonzero coefficient and PSC projection polynomials, the generic leading coefficient of a nonconstant product stays nonzero and the PSC vanishing signature stays constant. At an isolated point where leading coefficients vanish, original nominal PSC determinants still specialize correctly but must not automatically be interpreted as the actual specialized gcd degree. The fixture oracle marks such points ineligible for that inference. A generic identically-zero resultant caused by repeated/shared factors is retained; later PSCs can still carry the gcd information. Merely checking the first resultant would lose that information.

Full Collins is the preferred entry point for subsequent CAD integration because its all-reducta/pair conditions are directly covered by the cited theorem. The product shortcut is not substituted for that theorem in this implementation.

## Nullification and preserved atom provenance

Every plan stores the complete original atom list and selected variable. It has no `NoSolutions` result. For atoms `x` and `y+1`, their product `x*(y+1)` nullifies at `x=0` while the second atom remains `y+1`. The correct lift must specialize **each original atom**, retain nonnull atoms and their signs, and treat null atoms according to the surrounding Boolean formula. It cannot replace all atoms by the nullified product or infer an empty fiber. Point cells with degree loss likewise need per-atom specialization before root counting. The package keeps enough provenance for that lift but does not implement it.

Inputs must have exactly two declared variables, including zero and constant atoms, and the selected index must be zero or one. Invalid variable and source arity are explicit errors. Empty atom lists are valid: full Collins has an empty projection family, while the product plan stores one. Neither case decides a Boolean formula's truth.

## Certificates and trust boundaries

`Certificate` binds the projection mode, exact ordered original atom list, selected variable, optional full product, every coefficient cell and every PSC. `check(mode,atoms,selected,certificate)` reconstructs the specified plan and compares the full representation. `checked` returns a plan only after that check. `check_result` additionally binds a separately supplied opaque plan to the exact certificate representation. Changed atom problems, a different mode or variable, altered coefficients/PSCs, foreign product metadata and other valid plan payloads are rejected.

These are exact recomputing checks. They share elimination, sparse polynomial and Berkowitz arithmetic with the producer. They do not certify that a caller's base interval is connected, that it avoids every relevant root, or that sign invariance has been checked; those are obligations of root isolation and later CAD integration. No whole-stack formal proof, lifting correctness theorem, general CAD solver, quantifier elimination or real-feasibility decision is claimed here. Construction is synchronous and has no fuel counter or resumable state; large degrees and coefficient growth require caller budgeting.

## Independent oracle and reproduction

[The generator](../../tools/generate_projection.py) independently forms sparse reducta, coefficient lists, and the complete three-part Collins family. It expands every required PSC directly by symbolic permutation determinants, then applies the documented full-Collins terminal convention. It does not invoke Berkowitz or a characteristic-polynomial oracle. Fourteen source families produce **28 plans**, covering both modes, both selected-variable positions, rational coefficients, sparse reducta, content, shared/repeated factors, duplicate atoms, zero/constant/empty inputs, and irrational leading-coefficient zeroes such as `x^2-2`.

The product fixtures add **70 rational specialization checks**. Specialized nominal PSCs agree with independent Fraction determinants. A separate Fraction Euclidean algorithm supplies gcd degrees, and the first nonzero PSC is compared with that gcd only when the actual degree/nonnull hypotheses hold. Four adversarial groups check complete source/query binding, fabricated coefficients/PSCs/product metadata, foreign payloads, sparse reducta, input dimensions and nullified-product provenance.

All **32 tests pass on native, JS and WasmGC**. Formatting, `moon check --deny-warn`, API generation, fixture drift and the strict symbolic-purity gate pass. The driver requires exactly 32 executed tests and a zero exit code. Earlier elimination tests remain 330/330 per backend and their source snapshot is unchanged.

```sh
tools/measure --cpu 10 python3 .tools/projection-20261116/validate.py
```

The retained `.tools/projection-20261116/oracle.json` records full plans and specialization eligibility. `validation.json` and `validation-00.log` through `validation-07.log` retain commands, exit status, UTC completion times and test totals. `frozen-dependencies.json` confirms byte equality with the elimination/Berkowitz snapshots. All heavy work uses the shared CPU 10 lock; incremental wall times are not benchmarks. Root owns shared documentation/catalog navigation and any later CAD integration. Previous branches and artifacts remain preserved; this milestone is a local commit without push or deployment.
