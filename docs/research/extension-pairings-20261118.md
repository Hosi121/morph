# Partial Miller and shifted-divisor reduced Tate evaluation

The source/API freeze is `0661128`, dependent on curve milestones `7a7dac6` and `9d1e516`, from base `7389c7f37f45ca6c1db4380fac226ce8ea4ece95`. This adds only `pairing` and its dedicated oracle/report. Existing arithmetic packages and curve implementations are unchanged.

## Mathematical and API contract

All points retain one exact checked extensioncurve.Curve, including the galois field presentation and coefficients. Parameters retain that Curve, a Binary annihilator l, actual field cardinality M, and final exponent (M−1)/l. Here M=p^d is the cardinality of the already supplied GF(p)[t]/(f). If notation q^k is used for the complete target field, M denotes that whole quantity, not the characteristic p or another exponentiation of the supplied field.

The constructor enforces l>one, gcd(l,p)=one and divisibility of M−one by l. Curves already enforce characteristic greater than three and nonsingularity. The evaluator enforces [l]P=O; this means order dividing l, and includes the identity. It does not assert exact order l, primality of l, a curve group order, an embedding degree or a complete rational torsion basis. Those are distinct conditions. The API computes the specified evaluation under its checked domain; it does not assert nondegeneracy for every curve accepted by the parameter constructor.

The second point Q is a representative of E(F)/lE(F), and need not satisfy [l]Q=O. The caller supplies S. Evaluation uses f_l(P) on the degree-zero divisor (Q+S)−(S), which represents (Q)−(O), then takes the final exponent. It uses no simplified single-point shortcut requiring extra base-field hypotheses. Context and torsion checks precede identity branches. If P=O or Q=O the relevant divisor is zero, so the result is one without evaluating a function at a support point.

The reference gives the Miller recurrence, line/vertical quotient and divisor formulation: [Ben Lynn, Computing the Tate Pairing](https://crypto.stanford.edu/pbc/notes/elliptic/tate.html). Its presentation considers an extension containing the rational torsion. The finite examples below independently enumerate the complete rational l-torsion for their selected orders. This implementation does not infer that theorem hypothesis or a minimum extension degree from the field alone.

## Generic functions and partial support

`line_quotient(P,R,T)` returns the sum P+R and the nonzero value of the tangent/secant divided by the vertical line through the sum. An infinity summand gives the unit function. Opposite points, including a zero-y tangent, use a vertical line with denominator one. Tangents and secants use the ordinary exact slope. The evaluator normalizes points through the curve coordinate boundary; thus Miller line evaluation performs inversions even though underlying point addition/doubling use Jacobian coordinates. No speed claim is made.

`miller(P,m,T)` is generic in nonnegative Binary m and returns mP and f_m(T). Zero and one scalars use the unit function, and infinity P remains trivial. It has no Tate torsion/divisibility requirements. Binary recursion combines a squared prior value with a doubling line quotient, followed by an optional addition quotient.

The evaluation domain intentionally excludes zero numerators, zero denominators, zero-over-zero factors and infinity evaluation of a nonconstant line quotient. Errors distinguish ZeroEvaluation, PoleEvaluation, IndeterminateEvaluation and EvaluationAtInfinity. These describe intermediate factors: a factor pole or zero-over-zero may be removable after algebraic cancellation in the final Miller function. Such points are still rejected; no cancellation, regularization or silent replacement by one is attempted. Domain tests explicitly include a cancelling intermediate pole for the order-three flex. The returned value, when evaluation succeeds, is the exact stated function evaluation.

`reduced_tate(parameters,P,Q,S)` computes the two nonzero Miller values at Q+S and S, divides them, applies (M−one)/l and checks that the result raised to l is one. DifferentCurve is returned before identity shortcuts, and NotTorsion before a trivial Q shortcut. Field and curve arithmetic failures are propagated. Explicit S is the only shift API; there is no unbounded automatic search or global existence promise for other finite fields.

## Independent finite evidence

The host oracle uses integer polynomial field arithmetic and a separate affine group law. Its iterative Miller implementation starts at P and skips the leading bit, while production uses a recursive bit chain from infinity. No production executable is called to obtain expected values. Pure host results are memoized for bounded check cost; the complete raw JSON is byte-identical to the uncached mathematical enumeration. Fixture checking compares all semantic tokens while allowing whitespace, comments and optional trailing commas, and compares exact decompressed JSON bytes.

On the six-point curve y²=x³+one over the degree-one GF(5) presentation, all 216 point triples for line quotients and all 324 P/scalar/evaluation triples for scalars zero through eight are compared, including every exceptional category. A nonconstant extension evaluation also checks raw Miller at scalar 2^200+17, including the full field element and the independently computed multiple.

On y²=x³+one over GF(25), modulus t²+two, every one of the 625 affine candidate pairs is classified and the complete set has 36 points. The following orders exercise two-torsion, odd torsion and a composite annihilator.

| l | Final exponent | Rational l-torsion points | Point pairs | Right image lE | Quotient size | Minimum admissible S |
|---:|---:|---:|---:|---:|---:|---:|
| 2 | 12 | 4 | 144 | 9 | 4 | 32 |
| 3 | 8 | 9 | 324 | 4 | 9 | 30 |
| 6 | 4 | 36 | 1296 | 1 | 36 | 26 |

All 1764 P/Q pairs are compared against the host result at three seeded-shuffled admissible shifts each (5292 native Tate evaluations). Every nontrivial selected case separately checks both raw Miller values and the final exponent. The host tests all 63504 shifts, records the admissible sets and confirms shift independence; the native test samples three of those valid shifts per pair and tests representative failures.

The cached matrix contains actual native results, not oracle-only constants. All 50148 left and 63504 right bilinear equations are checked against the independently enumerated group table, plus 3888 representative-invariance equations. For each nonzero left point there is at least one nontrivial partner. The right kernel equals exactly lE, also independently constructed by native scalar multiplication. Thus nondegeneracy is checked on the quotient of sizes four, nine and 36; it is not incorrectly required for every nonzero representative Q. Accepted non-l-torsion Q with nontrivial values are explicitly observed for orders two and three.

Raw field coefficients, complete tables, admissible shifts, exceptional examples and quotients are retained in the compressed oracle. Production operations and checks share galois/extensioncurve dependencies, so their agreement alone is not independent evidence. The host affine integer-polynomial code supplies the separate comparison. These exhaustive tiny examples do not constitute a formal proof of the general software or pairing theory.

## Validation and limits

Native, wasm-gc and JS each pass **8/8**, with deny-warn. Scoped all-target check passes (60 tasks), API generation passes (56 tasks), formatting and independent oracle guards pass. Global purity passes 341 production kernel files; formal drift passes 32 previously reviewed regions and explicitly is not a source-translation proof of these new functions. All builds/tests use the shared CPU4 lock, -j 1 and a separate _build directory.

Production is immutable ADT/Result/recursion code without machine numbers, arrays, mutation, FFI or literals. This is exact arithmetic with variable execution paths, not a cryptosystem or a constant-time implementation. There are no serialization standards, secret-key operations, security parameter selection, automatic field embeddings, cancellation-complete Miller evaluation or automatic shift search. No time or memory improvement is claimed.

Evidence: [full independent raw oracle](extension-pairings-20261118-oracle.json.gz), [hashes and complete validation logs](extension-pairings-20261118-validation.json), [generator](../../tools/extension-pairings-20261118-oracle.py), [source/API](../../src/pairing).
