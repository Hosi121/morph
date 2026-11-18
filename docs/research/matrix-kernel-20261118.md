# 密行列の走査と Warshall 更新の融合（2026-11-18）

今回の問いは、`Matrix[A]` の `Chain[Chain[A]]` 表現が実際にどの処理を遅くしているか、公開 API・厳密な意味・純粋 immutable ADT の制約を保った小さな変更で改善できるか、である。基準は `193162547171f36b694e6b6e70c128ddc0b1ef14`、作業ブランチは `work/matrix-kernel`。候補調査、独立した変更一件、固定 5ABBA、意味の検査で区切った。

## 調査と判断

`multiply_known` は右行列を一度だけ転置し、各行と各列を `dot` で先頭から同時に走査する。m×n と n×p の積は転置 O(np)、積 O(mnp) であり、セルごとに `nth` で先頭から探し直す実装ではない。リストであることだけを理由に表現を変更する根拠は得られなかった。`Matrix` の格納形、`multiply`、右結合の `dot`、`power`、`transpose`、`column` は変更していない。

一方 `warshall` は各 pivot について列を取得し、`zip(current.rows, col)` の後に `map`、各行でも `zip(row, pivot)` の後に `map` を行っていた。出力とは別に、行ごとの pair リストと全セル分の pair リストができる。生成された release native C でも、セル用 `zip`、行ごとのクロージャ割り当て、`map` が残っていることを確認した。

採用した変更は、この二段の `zip` → `map` を `update_rows` / `update_row` の同時再帰に融合することだけである。列の取得方法やデータ表現の変更は行っていない。計算量 O(n³) は変わらない。中間 pair リストとその走査、行ごとのクロージャを除去する。

`matrix` が各行の長さを格納 width と照合し、既存の全生成関数がこの不変条件を保つため、行更新では両方の列を同時に消費できる。各 pivot では更新前の同じ行列から `pivot` と `col` を取り、全セルを `plus(aij, times(aik, akj))` で作る。左右の因子、括弧、行内と行間の callback 呼び出し順を維持する。正方形判定、空行列、Option の失敗、公開シグネチャに変更はない。

## 意味の検査

変更前 kernel に追加テストを適用した native テストが 6/6 通過した。その後、変更後 kernel の release native / JavaScript / wasm-gc は、対角可変の独立 DFS 検査を加えた最終 7/7 がそれぞれ通過した。

- 既存の三頂点の到達可能性走査、min-plus の最短路、Fibonacci 行列の冪、形・転置・単位行列を維持。既存の 512 mask は対角を true に固定しており 64 通りの重複だったため、全 512 通りの対角可変グラフを正長パスの DFS と比較する検査を追加した。
- F₇ 上の 2×2 係数行列を使い、次数 0〜4 × 8 seed の 40 行列を、各段階のスナップショットを使う配列参照計算と比較。係数の積が非可換であることも明示検査。
- 意図的に非結合な文字列 callback で `dot` の厳密な右結合と Warshall の式の括弧を確認。この probe は半環の法則を主張するものではない。
- 0×0、false / true の 1×1、2×3、0×3、2×0 の戻り値を確認。
- ベンチマーク各反復でも全行列を比較し、Python 側の別実装で最終 JSON の全セル・寸法・反復数を検査。Bool は DFS、min-plus は Dijkstra、非可換係数は汎用 2×2 行列積による段階更新を使用。
- 非可換ベンチマーク入力が、積の左右反転と、段階内の破壊的更新の両方を検出することを保存記録の検査時にも確認。

実行したコマンドは `tools/measure --cpu 4 tools/moon test src/matrix --target TARGET --release --deny-warn -j 1`（TARGET は native / js / wasm-gc）。変更前の native テストは `--release` なし。`moon fmt --check`、`moon info`、purity gate、interface drift gate も通過し、`src/matrix/pkg.generated.mbti` の Git 差分はゼロである。

## 固定比較

同一の frozen ベンチマークソースを使用し、before / after の依存ソースで異なるのは `src/matrix/matrix.mbt` だけである。native release の二つの ELF を固定し、CPU 4・共有排他ロック下で、各ケースを before / after / after / before の順に 5 ブロック実行した。全 140 process が成功した。表は各側 10 回の process 時間の中央値で、入力構築、参照計算、各反復の全行列比較、最後の全 JSON 出力も含む。

| ケース | 次数 | 反復 | before (ms) | after (ms) | before / after |
| --- | ---: | ---: | ---: | ---: | ---: |
| zero | 0 | 20,000 | 0.629 | 0.663 | 0.948 |
| tiny | 1 | 20,000 | 2.723 | 1.600 | 1.701 |
| bool24 | 24 | 300 | 114.582 | 50.942 | 2.249 |
| bool64 | 64 | 40 | 282.246 | 135.676 | 2.080 |
| multiply24（対照） | 24 | 300 | 15.908 | 15.734 | 1.011 |
| tropical12 | 12 | 80 | 15.193 | 12.483 | 1.217 |
| block12（非可換係数） | 12 | 80 | 5.666 | 3.964 | 1.429 |

Bool 24 次・64 次、min-plus、非可換係数は全 5 ブロックで改善した。0 次は kernel 更新がなく process 起動のばらつきが支配的であり、約 0.034 ms の中央値差を退行または改善の証拠として採用しない。乗算の対照も同等の範囲である。係数の算術が重い min-plus では相対効果が小さく、全係数型に 2 倍を主張しない。

## 成果物と再確認

- [比較 harness](../../tools/matrix-kernel-compare.py)、[保存記録 checker](../../tools/matrix-kernel-check.py)。保存記録の再確認は `python3 tools/matrix-kernel-check.py`。
- [集計・環境・ハッシュ](../measurements/matrix-kernel-20261118-summary.json)、[全 140 実行と全出力](../measurements/matrix-kernel-20261118.json.gz)。compiler version、affinity、各反復群の比、時間範囲も保存。
- [変更前依存ソース](../measurements/matrix-kernel-20261118-before-source.tar.gz)、[変更後依存ソース](../measurements/matrix-kernel-20261118-after-source.tar.gz)。ベンチマークを含む依存閉包であり、無関係な作業 tree 全体は保存していない。両 archive は同じ基準 commit を記録しており、実際の before / after の正本は archive 内のファイルハッシュである。
- [native C の確認箇所](../measurements/matrix-kernel-20261118-native-code.txt)、[検証記録](../measurements/matrix-kernel-20261118-validation.json)。

比較の再実行には各 source archive を別の空ディレクトリへ展開し、記録された compiler で `tools/measure --cpu 4 tools/moon -C DIRECTORY build src/cmd/matrixbench --target native --release --deny-warn -j 1` として個別に構築する。同じケース・反復数・5ABBA 順を使う。`--freeze before/after` は現在の worktree の構築済み ELF と依存ソースを保存するので、元の記録を上書きせず別の保存先へ保管して比較すること。

## 残る制約と到達点

これは Warshall の中間構築が測定条件下で有意なコストだったことを示す。全ての密行列処理における Chain の最適性、任意のサイズや実行環境での速度、ヒープ使用量・ピーク RSS の削減量は未検証である。計測は native のみであり、JavaScript / wasm-gc の速度は主張しない。メモリ割り当ての削減は生成コードとソース構造で確認し、動的な割り当て回数は計測していない。

本調査時点の通常 production package に `warshall` の呼び出しはなく、既存 benchmark と新しい matrixbench から使われる。Hodge や一般の密行列乗算がこの変更で高速化したという主張はしない。

成果は専用 branch のローカル commit までとし、push / PR / merge / deploy は行わない。再確認用の `.tools/matrix-kernel` と専用 `_build` は worktree 内に保持し、親エージェントによる統合確認後の worktree 削除とともに回収する。共有 `_build` や別 worktree は使用していない。
