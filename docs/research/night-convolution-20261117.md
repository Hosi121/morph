# Odd-prime convolution row dispatch: incomplete trial, 2026-11-17

## 親による追加比較と現在の判断

担当停止時点では未計測でした。その後、親が凍結済み実行ファイルを5分以内で比較し、初回120試行と対照40試行すべての完全一致を確認して採用しました。疎積は初回1.197倍・再比較1.141倍、零積は初回4.363倍でした。GF(2)対照は初回0.955倍・再比較0.997倍で、回帰の可能性も残します。一般の密な積や上位powerの一律な改善は主張しません。

追加測定と最終検証は[夜間の統合記録](night-kernels-20261117.md)にまとめます。下記は担当停止時点の記録です。

This trial is not adoption-ready. The firm worker stop was 13:45 UTC; a clock
check at 13:46 UTC showed that the worker had exceeded it before performing the
required source comparison and final verification. Exploration/heavy work stopped.
No speed claim or measured adoption/rejection claim is made. Root should retain
the baseline unless it explicitly completes the missing gates within its remaining
integration budget.

The frozen baseline is `4795f875270eb026cda25b7e509a0e60e8e6abb2`.
`d6785fa` freezes the six-case public benchmark. `e7212b7` implements the candidate:
empty operands return Nil, a canonical zero coefficient skips its mapped/added
product row, a unit coefficient shares the existing right coefficient chain, and
nonunit rows retain the old map/add operation and argument order. Only the body
of `multiply_coefficients` changes in production. Public multiply's mismatch-first
check, trimming, GF2 dispatch, evaluate, scale, derivative and checker source are
unchanged; `callsite-audit.json` records exact protected-source evidence.

The six frozen public cases are sparse257, unit17-upper, dense65537, zero257,
tiny17 and gf2-control. The unit case combines direct multiplication and public
power_mod; it does not isolate factorization or modular-power speed. Independent
Int64 convolution and exact binomial coefficients supply expected complete outputs.
Both zero operand orders and wrong-field error precedence are covered by tests.
The new tests retain the original generic row function as a second oracle and
exercise exhaustive small residue pairs, large-prime boundaries and wide sparse,
unit and zero rows with arbitrary unreduced constructor inputs.

Completed checks: native fppoly 29/29 passed with -j1 --deny-warn, and the native
release CLI built successfully under the shared CPU4 lock. The pre-edit calibration
smoke checked all six fixtures; its original durations/full outputs are retained
in `calibration.json` and are not candidate performance evidence. Missing gates:
five-block ABBA; final wasm-gc/JS tests; global warning/purity checks; generated API
comparison. The existing generated public interface was not edited, but that is
not reported as a completed API verification.

Unchanged certificate algorithms still use shared production arithmetic; their
success alone would not independently prove the new convolution. Independent host
oracles are required. There is no operand re-reduction to remove in modular.multiply;
this candidate only removes mapped row allocation and addition of zero rows.

Untimed ELF copies and hashes are recorded in `untimed-artifacts.json`, under
ignored `.tools/night-convolution-20261117/{before,candidate-untimed}.exe`. Archive
these before removing the worktree. No ABBA run archive exists because comparison
was not run. No push, merge, shared-index change or worktree removal was performed.
