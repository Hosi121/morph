# Independent review of sparse univariate Horner evaluation

[ドキュメント](../README.md) / [研究・探索記録](README.md)

The frozen candidate's algebraic transformation is correct under its canonical-polynomial representation invariant. The review found no failure on valid public inputs. It adds a Lean proof, a separate source correspondence lock, and an independent rational oracle without modifying any `src/*` file or the candidate worktree.

The source of truth for this review is `/home/hosi/morph-evaluation-20261116/src/polynomial/evaluation.mbt` and `polynomial.mbt`, while that worktree is at base `6934453` with uncommitted candidate changes. Exact reviewed file and function hashes are in [the review source map](../../formal/reviews/sparse-horner-source-map.json). The original generic evaluator is retrieved from `6934453`; its complete token sequence equals the candidate's `evaluate_generic` after changing only its declaration name and visibility.

## Essential premise and implementation correspondence

The Horner scanner maintains a previous exponent `degree` and accumulator `a`. On the next coefficient `c` and exponent `next`, it computes

```text
a := a * x^(degree-next) + c
degree := next
```

and finally returns `a*x^degree`, with a direct return when the final degree is zero. Its subtraction is saturating natural subtraction. Thus `next <= degree` is essential. The implementation does not recheck this condition during scanning; it follows from the opaque `Polynomial` representation and the public constructor's lexicographically descending insertion. In one variable that order is descending exponent order. All exponent vectors must also have length one on this path.

The proof only needs **weak** descent. Duplicate exponents, a zero exponent gap, zero coefficients, and duplicate cancellation need no stronger algebraic assumption. Public construction imposes stricter canonical form, removes zeros, and combines duplicates. The proof therefore covers the reachable canonical input and some additional raw lists.

Dropping descent is observably wrong: the forged ascending list `[(0,1),(1,1)]` at `x=2` gives Horner value 4 whereas its polynomial sum is 3. Both Lean and the compiled MoonBit boundary test check this witness. It is a negative control for the precondition, not a counterexample to the public constructor's contract; canonicalizing that list restores value 3. Future constructors or internal transformations must preserve descent before routing to this helper.

`evaluate` selects Horner only for `variables=1` and exactly one supplied value. Every other dimension or value-list shape reaches the unchanged generic evaluator. Malformed private exponent vectors make the Horner helper return `None` and trigger generic fallback. The isolated tests exercise these private malformed boundaries as well as public constructor dimension rejection. The public constructor prevents those malformed vectors from being normal polynomial values.

## Machine-checked algebraic statement

[SparseHorner.lean](../../formal/reviews/SparseHorner.lean) is checked with the existing [Lean 4.19.0 release](https://github.com/leanprover/lean4/releases/tag/v4.19.0) and `Std.Tactic`, without Mathlib. Its explicit `Laws R` structure assumes additive associativity and a two-sided zero identity, multiplicative associativity and a two-sided one identity, and `(a+b)*c=a*c+b*c`. Every semiring satisfies these laws. Additive commutativity, multiplicative commutativity, additive inverses, cancellation, and division are not required. Coefficients multiply powers on the left throughout.

The main invariant is universal over the carrier, algebra operations, base, accumulator, previous exponent, and every finite weakly descending tail:

```text
scan(rest, degree, a) = a*x^degree + sum_{(e,c) in rest} c*x^e.
```

Its inductive step uses right distribution and `(degree-next)+next=degree` under the descent premise. `horner_eq_sum` then identifies the full sparse algorithm with the direct monomial sum. `genericSum_eq_sum` identifies the original left-fold summation order with that same sum, and `horner_eq_genericSum` joins the two models. These are statements for unbounded exponents and lists, rather than finite test claims.

`bitsPower_sound` proves the recursive little-endian exponentiation-by-squaring operation computes the corresponding natural power. `optimizedPower_sound` includes the production helper's explicit exponent-zero and exponent-one branches, with the natural-to-bit encoding's semantic correctness stated as an explicit hypothesis. The proof does not silently replace the production binary converter with a host implementation. A concrete natural-number algebra instantiates the laws, and the ascending negative control and a duplicate-degree/zero-coefficient example are also checked.

All twelve reported theorem dependencies are either empty or `[propext]`; there is no `sorryAx`, `Classical.choice`, or user-defined axiom. `-DwarningAsError=true` succeeds. This is a machine proof of the explicit mathematical model. It is not an automatically verified translation of MoonBit, a proof of its compiler, or a proof that actual `@exact.Rational` implementations satisfy every stated law. Natural representation and conversion, actual arithmetic, canonical-form preservation by all internal producers, and compiler execution remain trust boundaries. The source correspondence has been manually reviewed and locked so a changed source requires renewed review.

The abstract dispatch theorem preserves its supplied generic result whenever the univariate route is not selected. Actual route conditions, `Option` fallback for malformed terms, and unchanged generic source are additionally checked against the implementation and in executable tests; they are not hidden inside that abstraction.

## Independent QQ oracle and finite boundaries

[The review tool](../../tools/review_sparse_horner.py) generates **184 exact Fraction cases plus one compiled boundary test**. The expected result is calculated directly as a sum of independent monomial powers and products in Python's standard-library `Fraction`, without calling either MoonBit evaluator or implementing Horner in the oracle.

The fixture cases comprise 30 zero/one/empty/constant/duplicate/cancellation boundaries, 30 sparse large-gap cases, 72 seeded rational-coefficient cases, 36 zero-/two-/three-variable controls, and 16 wrong-value-arity cases. Large exponents include `127,128,129,255,256,257,1023,1024,1025,4096` at bases `0,1,-1`; nontrivial positive and negative rational bases exercise degrees through 64. Fraction coefficients have nonbinary denominators and both signs. The boundary test additionally covers raw weak descent with zero coefficients, gap zero, power exponents zero and one, malformed private vectors, and the ascending countermodel.

The tool copies the candidate's production source and its `core`, `binary`, `exact`, and `testsupport` dependencies into `.tools/sparse-horner-review-20261116/harness`. It generates review tests only there. Original tests and benchmarks are excluded; their now-unused test-only benchmark imports are removed from the copied package metadata. Production `.mbt` source is copied intact. Each fixture compares both the actual public `evaluate` and actual private `evaluate_generic` with the independent expected value. No root or review worktree `src` directory is edited.

Native, JS, and WasmGC each pass **185/185** executed tests. The driver checks the exact nonzero test count and exit status. These checks support the reviewed actual Rational implementation on this finite range; they do not turn the abstract algebra proof into a whole-stack correctness theorem, and they make no performance claim.

## Correspondence lock and reproducibility

The dedicated source map records the Lean file hash, seven relevant MoonBit function token hashes, both full polynomial source-file hashes, the original generic-evaluator hash, and a human-readable function correspondence. Normal validation rejects any map mismatch before compiling. A negative control mutates the gap expression in an artifact copy and confirms the drift gate detects it. These hashes detect changed correspondence; they do not prove translation. At the review commit, this model lived under `formal/reviews` with a dedicated source map. After adoption in `00b220e`, integration commit `d15b936` also registered its seven source regions in the ordinary 31-region drift gate and added this model to `tools/check_formal`. The dedicated command additionally reruns the independent QQ oracle.

```sh
tools/measure --cpu 10 python3 tools/review_sparse_horner.py \
  --source-root .
```

After a real source/model change has been reviewed, `--record` explicitly renews the lock. Recording alone never performs a proof or a test. The `--lean` option can select another copy of the pinned Lean 4.19.0 checker. If the candidate is integrated into a different worktree, pass that path as `--source-root`; unchanged source hashes remain valid.

Retained artifacts are `.tools/sparse-horner-review-20261116/validation.json`, `lean.log`, `lean-version.log`, `test-native.log`, `test-js.log`, `test-wasm-gc.log`, `fraction-fixtures.json`, `copied-source.json`, `drift-control.json`, and the complete isolated harness. Validation uses the shared CPU 10 lock; recorded incremental wall times are not benchmarks. The review commit itself made no adoption or performance decision. The later integration adopted the implementation; its [performance evidence](sparse-horner-20261116.md) is separate. Review artifacts and frozen executable hashes were preserved before removing the completed candidate worktree.
