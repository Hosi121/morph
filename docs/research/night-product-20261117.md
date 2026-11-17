# Balanced polynomial product rows, 2026-11-17 final night round

## 親による追加比較と現在の判断

担当停止時点では未計測でした。その後、親が実装・harness・実行ファイルを変えずに5分以内の初回比較を行い、120試行の完全一致を確認して採用しました。疎な多変数積1.420倍、不均衡な疎積1.504倍でした。密な単変数積・小入力の差は未確定、実メモリ削減は主張しません。

追加測定と最終検証は[夜間の統合記録](night-kernels-20261117.md)にまとめます。下記は担当停止時点の記録です。

Production baseline: `4795f875270eb026cda25b7e509a0e60e8e6abb2`.
One mechanism is evaluated: group the sorted term-times rows of ordinary public
`polynomial.multiply` into adjacent pairs and repeat those merges until one row
remains. Existing `add`/`merge_terms` already perform sorted merges and are
unchanged. The goal is to reduce repeated scans of a growing accumulated product,
especially when sparse multivariate rows have little overlap.

## Invariants and tradeoffs

A fixed monomial shift preserves lex order in every row; each row is canonical.
Existing `merge_terms` combines equal exponents and removes exact zero sums.
Balanced grouping changes rational addition order, but all arithmetic is exact
and canonical, so returned coefficients and monomials must remain identical.
The outer dimension check retains precedence even when either operand is empty.
Valid empty products avoid row materialization. With at most two left terms the
original sequential fold is retained. The asymmetry is intentional: the old
implementation folds over the left input; correctness tests also reverse inputs.

The candidate materializes all product rows before merging them. For inputs with
heavy cancellation, this can retain substantially more intermediate terms than
the old accumulator plus one row. Balanced rational additions can also increase
or decrease intermediate numerator/denominator bit sizes. No RSS/heap/peak-memory
measurement is performed, and no memory improvement is claimed. The rational
control uses denominators 2–5 and a cancellation-heavy convolution; it does not
establish behavior for large coprime denominators or arbitrary bit growth.

The original sequential fold is frozen as a white-box oracle. It still shares
monomial arithmetic, exact rational operations and merge helpers with the
candidate. An independent Python dictionary/`Fraction` full convolution supplies
28 committed fixtures over variable counts 0,1,2,3, empty/single/tiny/larger terms,
sparse/dense patterns, cancellation and unequal sizes. Every fixture compares
both input orders and the old sequential result with the entire expected product.
Explicit dimension errors cover empty operands in both orders. The generator has
a `--check` guard and retains the full direct-benchmark expectations.

All mapped functions, `merge_terms`, `term_times`, `monomial_product`, public
`divide`, `normal_form`, private `remainder_only`, and checker bodies are unchanged.
Protected source byte hashes, public API checks and formal drift guard are
retained. The balanced algorithm itself is not covered by the existing formal
translation correspondence. Checkers calling multiply share the optimized
dependency; their success is not an independent arithmetic oracle.

## Frozen public measurement

Harness/oracle milestone: `c94a2bd`; package `src/cmd/nightproductbench`.
Six frozen cases cover sparse 3-variable products, dense univariate products,
strongly unequal 2-variable sparse products, rational cancellation, combined
empty/single/tiny/error controls, and actual Buchberger generation with its
public verifier and an independent existing SymPy reduced-lex expected basis.
Every iteration checks the entire product/basis and serializes the full result;
verifier and check costs remain included. Setup and one checked warmup are
included in process time; the inner timer contains repeated operations, full
checks and serialization. Ratios must not mix those scopes or be generalized to
pure multiplication-only costs. No new optional plan API is benchmarked.

Own frozen CLI files were copied and built on the common baseline under the
shared CPU4 lock before candidate edits; 1,085 tracked baseline source/module/
tool files were byte-audited against `4795f87`. Original executable mode and bytes
were preserved in a saved ELF copy. Candidate and baseline builds use distinct
build trees. All heavy builds/tests/checks/timings use CPU4 affinity and the shared
flock, `-j 1` except `moon info` (which has no jobs option). Five independent
process ABBA blocks retain every full checked stdout and all outliers. Raw JSON
may be compressed losslessly; hashes cover both uncompressed and compressed data.

## Results and decision

**Not adopted: unmeasured at the worker deadline.** The locked validation batch
returned at 13:46:44 UTC, after the hard 13:45 worker stop. No ABBA comparison
was started, no speedup was measured, and no performance follow-up was used.
Correctness alone is not evidence of improvement. The frozen baseline smoke
results only establish executable fixtures; they are not a before/after result.
The prototype source and both ELF copies remain for root review/archival, not
for integration as an adopted performance change without a new measurement.

The six affected packages passed 444/444 tests on each of wasm, JS and native
with deny-warn. Global all-target check passed (774 tasks), API info passed
(38 tasks), purity passed 330 kernel files, formal drift passed 32 mapped regions,
and the independent 28-fixture Fraction check passed. All protected regions
retained byte hashes. These checks establish finite correctness evidence and
scope preservation, not performance or a formal translation proof.

Raw validation and source/ELF hashes are retained below. The bounded pass ended
because the schedule was exhausted, not because a measured speed or regression
was established. No universal claim, memory claim, rational-bit-growth claim,
or adopted threshold follows.

Artifacts:

- [Validation receipts and hashes](night-product-20261117-validation.json)
- [Full validation stdout](night-product-20261117-validation.txt)
- [Independent Fraction generator](night-product-20261117-oracle.py)
- [Full direct convolution expectations](night-product-20261117-oracle-cases.json)

Saved baseline/candidate ELF copies are
`.tools/night-product-20261117/baseline-4795f87.exe` and
`.tools/night-product-20261117/candidate-initial.exe`. No push, worktree removal,
checker/formal-map/shared-index edit was performed by this worker.
