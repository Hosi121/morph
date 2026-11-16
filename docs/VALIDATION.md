# 検証ガイド

[ドキュメント](README.md) / [開発・検証環境](ENVIRONMENT.md)

実行テスト、証拠検査、Leanモデルは、それぞれ異なる性質を確かめます。
このページでは検証済みのコード、変更時のコマンド、各検査の保証範囲を案内します。

## 検証済みスナップショット

2026-11-17（JST）に、コード `0c79742` を固定して統合検証しました。
複素代数的数の演算・全複素根に加え、K(i)、α+i による一生成元表示、
明示分解した体の全自己同型、部分群の固定体の完全な基底と座標を含みます。
以後の文書編集を、新しいコードの実行検証として数えるものではありません。

| 検査 | 結果 |
| --- | --- |
| native（release） / JS / WasmGC | 各3,976テスト成功 |
| Pythonの保守ゲート | 24テスト成功 |
| 純記号制約 | 276核ソースが通過 |
| 公開API | 114生成スナップショットが一致 |
| Lean | 32対応領域の差分検査と全モデルが通過 |
| 独立照合・証拠検査 | 全複素根、2・4・6・8次の複素数体と座標、C2/V4/D4の群作用、全17部分群の固定体、source・返却物の改竄検査が通過 |
| 実行例 | 複素代数・D4と全10中間体のツアーが各3バックエンドで掲載出力と一致 |

正本は[条件・コマンド・集計](measurements/complex-galois-20261117-validation.json)と
[全出力](measurements/complex-galois-20261117-validation.txt)です。
[複素数体と一生成元](research/complex-fields-20261117.md)、
[自己同型と固定体](research/complex-galois-20261117.md)に独立参照・検査の根拠をまとめています。
一般の分解体探索や、共有算術とプログラム全体の形式証明までは含みません。
作業用worktreeは全パッチの反映とGitアーカイブを確認して削除しました
（[片付け記録](measurements/complex-galois-20261117-cleanup.json)）。

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
