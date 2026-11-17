# 検証ガイド

[ドキュメント](README.md) / [開発・検証環境](ENVIRONMENT.md)

実行テスト、証拠検査、Leanモデルは、それぞれ異なる性質を確かめます。
このページでは検証済みのコード、変更時のコマンド、各検査の保証範囲を案内します。

## Fp多項式の正規形を使う演算

コード `7749ddc` を固定し、基準 `03d6584` からの変更と旧・現のimport graphの逆依存を検査しました。
対象は36 packageで、テスト専用importも含みます。全repositoryの無変更テストを再実行した記録とは区別します。

| バックエンド | 結果 |
| --- | --- |
| wasm-gc | 1,392テスト成功 |
| js | 1,392テスト成功 |
| native | 1,392テスト成功 |

全体のPython 27テスト・144公開API・型・整形・生成物・325核ソースの純記号制約が通過しました。
既存Lean全モデルと32対応領域の差分検査も通過しました。新しいhelper全体の形式証明ではありません。
fppoly・modular・primefieldを含む既存公開APIは変更していません。
独立した425係数対・54積/除算ケースを追加し、未還元constructor・相殺・幅違い・零・field mismatchも検査しました。

[環境・ソース・選択graph・全コマンド](measurements/canonical-fp-20261117-validation.json)、
[全出力](measurements/canonical-fp-20261117-validation.txt)、[実行harness](measurements/canonical-fp-20261117-harness.py)を保存しました。
前回の84 packageの検証記録と、それ以前の全体検証は下に残しています。
設計と比較の範囲は[正規形の再利用](research/canonical-fp-20261117.md)を参照してください。
今回の3 worktree・2作業branchは、全パッチ反映・Git bundle・harnessと実行ファイルの保存を確認して削除しました
（[片付け](measurements/canonical-fp-20261117-cleanup.json)、[担当範囲と経緯](measurements/canonical-fp-20261117-orchestration.json)）。

## 体のカーネルの影響範囲検証

コード `af279b4` を固定し、基準 `4d9e6c4` からの変更と旧・現のimport graphの逆依存を検査しました。
対象は84 packageで、テスト専用importも選択に含みます。全repositoryの無変更なテストを再実行した記録とは区別します。

| 検査 | 結果 |
| --- | --- |
| WasmGC / JS / native release | 対象の各3,545テスト成功 |
| 全体の保守・型・API | Python 27テスト、143公開API、警告なし型検査、生成fixtureが通過 |
| 純記号制約 | 325核ソース。機械数値型・配列・可変状態・FFIなし |
| 既存のAPI | linear・primefield・modular・CSS・cohomology・homologyの公開スナップショットは変更なし。rowreduceには零判定付き入口を追加 |
| 既存Leanモデル | 全モデルと32対応領域の差分検査が通過。新規GF(2)核全体の形式証明ではない |
| 独立参照 | 全689の小GF(2)行列と5,054右辺、Fractionの1,539系、未還元素体入力、既存証拠の改変検査 |
| 旧比較の保守 | 元の四hashを維持したBareiss参照ゲート、11種類の意図的変更を拒否 |

[ソース・選択graph・全コマンド](measurements/field-kernels-20261117-validation.json)、
[全出力](measurements/field-kernels-20261117-validation.txt)、[実行harness](measurements/field-kernels-20261117-harness.py)、[再開harness](measurements/field-kernels-20261117-resume-harness.py)、
[参照ゲートの改変検査](measurements/field-kernels-20261117-reference-mutations.json)を保存しました。
途中の実行セッション中断は[保存時点の記録](measurements/field-kernels-20261117-interrupted.json)に残しています。
nativeの完了記録がなかったため、ソースと完了ログのhashを照合してnative・Leanだけを再開しました。
[環境の補足](measurements/field-kernels-20261117-environment.json)は再開時点のホスト情報です。
検証の範囲に関する正本はJSONのpackage一覧・実行成功数で、宣言数を成功数に数えたものではありません。
[採否・計測条件](research/field-kernels-20261117.md)と
[共通算法・専用化の設計](handbook/field-kernels.md)も参照してください。
今回の4 worktreeと3作業branchは、全パッチ反映・Git bundle・必要な実行ファイルの保存を確認して削除しました
（[片付け](measurements/field-kernels-20261117-cleanup.json)、[担当範囲と経緯](measurements/field-kernels-20261117-orchestration.json)）。

## 積・相対群・崩壊の影響範囲検証

コード `72f166a` で、変更した7 packageと旧・現のimport graph上の逆依存を検査しました。
対象は11 package、各バックエンド255テストです。無変更の数体・CAD等を全件再実行した記録ではありません。
前回の全4,142テストの記録は下に残しています。今回の追加宣言は207で、現在の全宣言数と今回の実行成功数は別です。

| 検査 | 結果 |
| --- | --- |
| WasmGC / JS / native release | 影響範囲の各255テスト成功。旧homology、simplicialmap、CSSと新規核を含む |
| 全体の保守・型・ソース制約 | Python 24テスト、323核ソース、138公開API、全体の警告なし型検査が通過 |
| 共通化の互換性 | 既存homologyの公開APIスナップショットは変更なし |
| 既存Lean・対応差分 | 既存全モデルと32対応領域が通過。新しい核全体の形式証明ではない |
| cup積の独立照合 | 167小複体、269,883 cochain対、49,923 cocycle対、トーラス・wedge・RP2の積 |
| 相対群の独立照合 | 315小対の境界・rank・連結写像、整数minorとRP2のねじれ |
| 崩壊の独立照合 | 167複体・9,781候補・340収縮、整数I/P/Hの各成分と恒等式、改変拒否 |
| filtered adapter・ツアー | 同grade・全非零成分のgradeを検査。ツアー3バックエンド・21起動ケースが一致 |

正本は[ソース・選択graph・コマンド・生値](measurements/topology-rings-20261117-validation.json)、
[全出力](measurements/topology-rings-20261117-validation.txt)、
[実行したharness](measurements/topology-rings-20261117-harness.py)です。
対象は `chainhomology`, `cmd/connections`, `cmd/topology`, `cmd/topologyrings`, `cohomology`, `collapse`, `csscode`, `filteredcollapse`, `homology`, `relativehomology`, `simplicialmap`。
全体の型検査で見つけたテスト補助型のtrait宣言を修正し、失敗した二試行も同データに保存しています。
使い方は[コホモロジー環・相対群・崩壊](handbook/cohomology-relative-collapse.md)、
判断理由は[探索記録](research/topology-rings-20261117.md)にまとめました。
3作業用worktreeは全パッチ反映とGitアーカイブを確認して削除しました
（[片付け記録](measurements/topology-rings-20261117-cleanup.json)）。

## 全体検証済みスナップショット（前回）

2026-11-17（JST）にコード `93a2913` を固定して統合検証しました。
有理点群のVietoris–Rips filtration、GF(2)持続ホモロジー、整数誘導準同型、
CSS符号の論理商・最小重みと、従来の全算法を含みます。
以後の文書編集を、新しい計算核の検証として数えるものではありません。

| 検査 | 結果 |
| --- | --- |
| native（release） / JS / WasmGC | 各4,142テスト成功。前回から51宣言を追加 |
| Pythonの保守ゲート | 24テスト成功 |
| 純記号制約 | 312核ソースが通過 |
| 公開API | 132生成スナップショットが一致 |
| Lean | 既存の全モデルと32対応領域の差分検査が通過。新しい位相・符号核全体の形式証明ではない |
| 持続性の独立照合 | 230 filtrations、43,718の全次数・prefix対rank。tie-order・入力と証拠の改竄も検査 |
| 単体写像の独立照合 | 19複体、3,439頂点関数、四面体の256写像、729ずつのchain/H1合成 |
| CSSの独立照合 | 小部分空間の82可換組・204拒否組、583ベクトル、RP2とトーラスの全bitmask最小重み |
| 有理点群 | 121入力×3次元上限を独立部分集合・直接距離と照合。二乗距離、座標の重複、打ち切りを検査 |
| 位相ツアー | 3バックエンドで掲載出力と一致。既定・モード・不正引数の全21起動ケースも通過 |

正本は[環境・ソース・実行記録](measurements/topology-20261117-validation.json)と
[全出力](measurements/topology-20261117-validation.txt)、
再実行した[検証harness](measurements/topology-20261117-harness.py)です。
現在の入口は[位相と符号](handbook/topology.md)、設計と独立参照は[探索記録](research/topology-20261117.md)から辿れます。
探索燃料は実時間の上限ではなく、CSS距離の最小性検査も指数時間の再列挙です。
今回の3作業用worktreeは全パッチの反映・Gitアーカイブを検査して削除しました
（[片付け記録](measurements/topology-20261117-cleanup.json)）。

前回の群・不等式・整数ホモロジーの統合では、計算核 `6cf0f28` で各4,091テストを確認し、
ツアー起動引数だけを `9bccd5a` で修正しました。
当時の[環境と集計](measurements/connections-20261117-validation.json)・
[全出力](measurements/connections-20261117-validation.txt)と
[片付け記録](measurements/connections-20261117-cleanup.json)も保存しています。

## 変更したときに実行する

すべてリポジトリのルートで実行します。

| 変更 | コマンド |
| --- | --- |
| 文書 | `python3 tools/check_docs.py` |
| 計算核・探索・検査器 | `tools/check` と `tools/moon test --target native` |
| 対応するLeanモデルやソース | `tools/check_formal` |
| 独立fixture | [実閉体・SMT](ENVIRONMENT.md#実閉体非線形smtの独立fixtureを再生成する)・[複素代数](ENVIRONMENT.md#複素代数の独立fixtureを再生成する) |

`tools/check` は保守テスト、ソース制約、整形、型、生成物、WasmGC・JSテスト、公開APIの差分を検査します。
文書のリンク検査にはMoonBitやLeanは不要です。Leanの初回準備は[形式検証](../formal/README.md)を参照してください。
共有のLinux環境では、重い処理を `tools/measure --cpu N COMMAND...` で直列化できます。
CPU番号は環境に合わせて指定します。

## 検査が示すもの

| 方法 | 確認する性質 | 信頼する部分・限界 |
| --- | --- | --- |
| ソース検査 | 核への数値型・配列・可変状態・FFIの混入、代表的な変換往復の再導入 | 保守的な字句検査。停止性やコンパイラの正しさは証明しない |
| 総当たり・独立オラクル | 有限の入力集合で、整数・配列・別実装の期待値と一致すること | 入力範囲とオラクルに依存する。任意長への一般化は別に必要 |
| 問題ごとの証拠検査 | SAT反証、最大流のカット、LPの双対解などが元の問題の根拠を満たすこと | 検査器と共有算術を信頼する。探索と別の検査器もプログラムである |
| 外部チェッカー | SAT核の出力をLRAT/DRAT形式でも受理できること | 選んだ問題とチェッカーに対する確認。偽造例の拒否も併せて調べる |
| Leanモデル | 加算、半分化、二進変換、比較、fold、疎Horner、条件付きBoolean評価などの全称命題 | 手で対応付けたモデルの証明。原子観測の健全性など明示的な仮定がある。複素代数・CAD・SMT・コンパイラ全体の証明ではない |
| 対応差分・公開API検査 | レビューしたソース領域や公開型の変更の検出 | 差分を検出する仕組み。変更後の意味の正しさは別途確認する |

定理とソースの対応は[形式検証](../formal/README.md)、主張ごとの根拠は
[検証台帳](bootstrap/verification-ledger.md)、個別の独立レビューは[研究記録](research/README.md)にあります。
パッケージ一覧の「テスト宣言数」、実行成功数、一つのテスト内の比較例数は異なる集計です。

## 過去の検証記録

履歴の値は、その時点のコードと条件に対する結果です。

| コード | 段階 | 記録 |
| --- | --- | --- |
| `701e789` | 最小分解体・共通体・完全Galois作用、各4,041テスト | [集計](measurements/complex-splitting-20261117-validation.json)・[出力](measurements/complex-splitting-20261117-validation.txt) |
| `0c79742` | K(i)・一生成元・明示自己同型と固定体、各3,976テスト | [集計](measurements/complex-galois-20261117-validation.json)・[出力](measurements/complex-galois-20261117-validation.txt) |
| `060a66f` | K(i) と一生成元表示の追加範囲、各38テスト | [集計](measurements/complex-fields-20261117-validation.json)・[出力](measurements/complex-fields-20261117-validation.txt) |
| `4aa8668` | 複素代数の演算・全根・因数分解の接続、各3,920テスト | [集計](measurements/complex-algebra-20261117-validation.json)・[出力](measurements/complex-algebra-20261117-validation.txt) |
| `b8e5ff3` | 理論衝突節の削減、各3,871テスト | [集計](measurements/theory-core-20261117-validation.json)・[出力](measurements/theory-core-20261117-validation.txt) |
| `de2a892` | CDCL状態保持、各3,835テスト | [集計](measurements/retained-cdcl-20261117-validation.json)・[出力](measurements/retained-cdcl-20261117-validation.txt) |
| `8fe68f0` | 円柱の枝刈り、各3,817テスト | [集計](measurements/incremental-20261117-validation.json)・[出力](measurements/incremental-20261117-validation.txt) |
| `37d82f5` | 多段実代数体・任意変数CAD・量化消去、各3,775テスト | [集計](measurements/realclosed-20261116-validation.json)・[出力](measurements/realclosed-20261116-validation.txt) |
| `9880edf` | 複雑な算法の仕上げ、各3,311テスト | [出力](measurements/advanced-20261116-final-validation.txt) |
| `12db9d8` / `6934453` | 複雑な算法の第二段階 / 最初の段階 | [第二段階](measurements/advanced-20261116-second-validation.txt)・[最初の段階](measurements/advanced-20261116-first-validation.txt) |

`b8e5ff3` の六関係・共有被覆18組の照合は[衝突節削減の記録](research/theory-core-20261117.md)、
当時の資料の保管先は[片付け記録](measurements/theory-core-20261117-cleanup.json)を参照してください。

<details>
<summary>前段階の基礎kernel検証とSAT反証の外部検査</summary>

2026-11-16のコード `c331d0c` に対する記録です。

| 検査 | 結果 |
| --- | --- |
| native / JS / WasmGC | 各499テスト成功 |
| Python / 純記号制約 / 公開API | 12テスト / 122核ソース / 69生成スナップショット |
| Leanとの対応 | 24領域の差分検査と全モデルが通過 |
| SAT反証の外部検査 | 16証拠をLRAT/DRAT両方が受理、7偽造例を拒否 |

[核・テスト・Lean](measurements/final-kernels-validation.txt)・
[外部反証検査](measurements/final-proof-validation.txt)・
[証拠マニフェスト](measurements/final-proof-manifest.json)を保存しています。

</details>

## 資源と性能の限界

値の一致、再帰の深さ、割当量、実行速度は別々に確認します。
燃料付き探索の一歩にも、リスト走査や有理数演算が含まれ、一定実時間を保証しません。

JSの通常の長語除算・剰余には、`2^20000 mod 3` で確認したスタック制約が残ります。
20,000bitは耐久試験の入力で、上位アルゴリズムに必要な桁数を示すものではありません。
[末尾再帰化の試作](research/wide-kernels/README.md)は値とスタックの検査を通過しましたが、
nativeの剰余が遅くなるため採用していません。

性能の比較条件は[計測記録](MEASUREMENTS.md)、通常経路への採否は[基礎部品の最適化](KERNELS.md)を参照してください。
異なる測定系列の倍率は掛け合わせません。
