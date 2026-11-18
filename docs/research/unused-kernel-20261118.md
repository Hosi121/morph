# 未使用公開経路の分類と runbinary 展開の prefix 融合

対象は `1931625` の `core.gcd` / `core.interleave` / `runbinary`。
内部参照がない公開 API の削除と、実際に冗長な中間列の除去を分けて判断した。
今回採用した変更は `runbinary.expand` の同値な prefix 構築の融合 1 件であり、公開 API は変更していない。

## 呼出しと維持判断

既存の `tools/audit_paths.py.inventory()` を再実行した結果は次のとおり。
コメント・文字列・自己再帰を除いた字句参照で、外部ユーザーの利用や動的な到達可能性は分からない。
再集計方法と結果は [report.py](../../tools/unused-kernel-report.py) と
[report.json](../../tools/unused-kernel-report.json) に保存した。

| 対象 | 本体からの参照 | test/demo | 判断と根拠 |
| --- | ---: | ---: | --- |
| `core.gcd` | 0 | 1 | 公開の単項 Nat 上の Euclid を維持。`core_wbtest.mbt` が 48/18 の値を検査する。Binary の GCD は別表現の算法であり、Nat/Binary の変換費用を伴う統合に利用側の根拠がない。Lean の対応領域には含まれない。 |
| `core.interleave` | 0 | 1 | 公開の generic Chain 操作を維持。`alternating` で分割した列の復元則を検査する教育的な基礎例でもある。短い構造再帰で、今回除去すべき中間表現はない。Lean の対応領域には含まれない。 |
| `runbinary` | 他 package の本体から 0 ファイル | 13 通常テスト・既存 3 benchmark | 圧縮表現の公開実装を維持。長い同一ビット列を展開せず扱う能力があり、per-bit Binary の既定 backend への全面統合は行わない。今回 benchmark を 1 件追加した。 |

`runbinary` の維持は現在の通常経路の高速化という主張ではない。
[既存測定](../bootstrap/runbinary.md)では、2048bit 全 1 の加算は Binary 20.10 µs / runbinary 1.18 µs、
256bit 交互列の加算は 3.01 / 39.11 µs だった。
これは当時の CPU 固定なしの測定で、今回の数値と比較・合成しないが、全面置換を避ける根拠になる。
また `2^(2^1000)` 幅の算術は少数の run のまま検査でき、幅に比例する Binary 列を作る方式とは能力が異なる。

[独立レビュー](../bootstrap/review-runbinary.md)には raw run 10,000 列、UInt64、per-bit Binary の照合がある。
`runbinary.digit` は `binary.full_adder` を使うため、表現・block 処理が独立していることと、
算術核が完全に独立した oracle であることを混同しない。
Lean で検査済みなのは均質 block の carry/borrow の局所安定性であり、run 算術全体の正しさではない
（[対応領域](../../formal/README.md)、[台帳 RUN-1](../../formal/drift-ledger.md)）。

## 採用した変更と意味

各 run を展開するときの
`reverse_onto(replicate(n, bit), reversed)` を
`replicate_onto(n, bit, reversed)` に置き換えた。
同じ値を n 個並べた列は反転しても同じ列なので、既存の末尾を保って同じ結果になる。
旧経路は `replicate` が n 個の Cons を作り、その列を `reverse_onto` が再度 n 個の Cons へ作り直す。
新経路はその 1 本の中間 Chain と走査を省く。展開する総幅 W に対し、ソース上は W 個の追加 Cons 構築を省く。
コンパイラの割当て削減や GC を含む実メモリ量は計測していない。

幅と caller の上限を比較し、超えれば `None` を返して展開へ入らない分岐はそのまま保持した。
各 run 長の `Binary -> Nat` は、許可された有限幅を実際の bit 列へ変える境界として残した。
`from_binary` からの往復も、圧縮表現と per-bit 表現の明示的な境界であり、恒等変換の除去対象にはしない。

[Core.lean](../../formal/Core.lean) の `replicateOnto_eq_append` は、任意型・任意 n・任意 tail の prefix 法則を扱う。
今回使う helper 自体は変更せず、同値な定数列の反転を除去した。
`expand` は source lock の対象ではなく、この変更全体を Lean で機械証明したという主張はしない。
`digit` を含む既存 32 対応領域の drift 検査は通過した。

## 同一条件の直接比較

JS release、Node v24.13.0、Moon `0.1.20261104 (940aa18 2026-11-04)`、CPU4。
`tools/measure` による共通ロックを使い、同一 artifact に `1931625` の旧 `expand` と変更後の公開 `expand` を同居させた。
report は、benchmark の旧関数の本体が基準とコメント・空白を除いて一致することも検査する。
各入力 5 組の ABBA（旧・新・新・旧）、各 group 5 標本。
幅の判定、run 長の Nat 化、最終正規化、結果保持を含む。入力・上限構築と事前の等値検査は含めない。
事前に旧新の Binary の等値と、再圧縮して入力へ戻ることも検査した。

| 入力 | 旧 µs | 新 µs | 旧/新 | 改善した組 |
| --- | ---: | ---: | ---: | ---: |
| 全 1・4096bit・1run | 88.83 | 77.05 | 1.153 | 5/5 |
| 4096bit・4run（長さ 1023/1025/1025/1023） | 85.33 | 71.46 | 1.188 | 5/5 |
| 交互・2048bit・2048run | 103.96 | 92.52 | 1.145 | 5/5 |

時間は ABBA の旧 2 group / 新 2 group の平均を取り、5 組で中央値を取った。
倍率は各組の旧/新の中央値であり、表示した二つの時間の比とは一致しない場合がある。
[生ログ](../../tools/unused-kernel-js-bench.txt) と [各組の値・ソース hash](../../tools/unused-kernel-report.json) を保存した。
入力構築を含むアプリ全体、native/Wasm の速度、未測定の入力、実メモリ量の改善は主張しない。
共通ロックは同 repository の測定競合を防ぐが、外部プロセスや周波数変動は排除しない。

```sh
tools/measure --cpu 4 tools/moon bench src/runbinary/expansion_bench_wbtest.mbt --target js --release -j 1 > tools/unused-kernel-js-bench.txt 2>&1
python3 tools/unused-kernel-report.py --output tools/unused-kernel-report.json
```

## 検証と残る候補

JS / Wasm GC の通常テストが各 13/13 通過した。
既存の整数・Python 任意精度 fixture・raw run 正規化・上限ちょうど/不足・巨大幅拒否の検査を含む。
型・warning・format・純粋性・形式モデルの差分検査も通過した。
`moon info src/core src/runbinary` の再生成後、両公開インターフェースは基準と byte 単位で同一だった。
[検証ログ](../../tools/unused-kernel-validation.txt) を参照。
native の冷ビルドと native 実行は今回の範囲では行っていない。

次に扱うなら、`expand` の run 長を Nat にする中間 spine が具体的な候補になる。
ただし二進カウンタの減算を各 bit で行う実装は別の費用を増やし得るため、
上限の先行検査と値を保持した旧新比較で採否を決める必要がある。
`core.gcd` では各 Euclid 遷移で捨てる商を作る経路が候補だが、現在の通常 caller はなく、
公開 API の直接性能を改善する目的と測定を別に定めてから扱う。
`interleave` に参照実績を作るためだけの caller は追加しない。

この成果物は専用 branch の commit として親へ渡す。統合・push と worktree の片付けは親が担当する。
