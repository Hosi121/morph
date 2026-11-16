# 検証ガイド

[ドキュメント](README.md) / [開発・検証環境](ENVIRONMENT.md)

morphは、ソース検査、実行テスト、証拠検査、Leanモデルを組み合わせて確認します。
それぞれが確かめる性質と、信頼する部分は異なります。

## 変更したときに実行する

```sh
python3 tools/check_docs.py           # 文書のリンク・節・コードブロック
tools/check                          # ソース制約・生成物・Wasm GC/JSテスト
tools/moon test --target native       # nativeテスト
tools/check_formal                    # Leanモデルを変更・再確認するとき
```

Leanの初回準備は[形式検証](../formal/README.md)を参照してください。
共有の開発環境で重い処理を並べるときは、`tools/measure --cpu N COMMAND...`で
共通ロックとCPU固定を使います。文書のリンク検査にはMoonBitやLeanは不要です。

## 検査が示すもの

| 方法 | 確認する性質 | 信頼する部分・限界 |
| --- | --- | --- |
| ソース検査 | 計算核へ数値型・配列・可変状態・FFIが混入しないこと、代表的な変換往復の再導入 | 保守的な字句検査。停止性やコンパイラの正しさは証明しない |
| 総当たり・独立オラクル | 有限の入力集合で、整数・配列・別実装の期待値と一致すること | テスト範囲とオラクルに依存する。任意長への一般化は別に必要 |
| 問題ごとの証拠検査 | SAT反証、最大流のカット、LPの双対解などが元の問題に対する根拠を満たすこと | 検査器と共有算術を信頼する。探索を再実行しない検査も、プログラムである |
| 外部チェッカー | 実際のSAT核が出力した反証をLRAT/DRAT形式でも受理できること | 選んだ問題とチェッカーに対する確認。偽造例の拒否も併せて調べる |
| Leanモデル | 加算、半分化、二進変換、比較、fold、疎Hornerなどの全称命題 | 手で対応付けたモデルの証明。MoonBitへの変換器・コンパイラ全体の証明ではない |
| 対応差分・公開API検査 | レビューしたソース領域や公開型の変更を見逃さないこと | 変更を検出する仕組みであり、変更後の意味の正しさは別途確認する |

定理とソースの対応は[形式検証](../formal/README.md)、個別の主張と根拠は
[検証台帳](bootstrap/verification-ledger.md)に記録しています。

## 検証済みスナップショット

2026-11-17（JST）の統合検証は、ソース`b8e5ff3`を固定して実行しました。
既存CAD被覆からの理論衝突節の削減、CDCL状態保持、早期SAT終了と証拠検査まで含みます。
[全出力](measurements/theory-core-20261117-validation.txt)と
[条件・コマンド・集計](measurements/theory-core-20261117-validation.json)を保存しています。

| 検査 | 結果 |
| --- | --- |
| native / JS / Wasm GC | 各3,871テスト成功 |
| Pythonの保守ゲート | 24テスト成功 |
| 純記号制約 | 251核ソースが通過 |
| 公開API | 103生成スナップショットが一致 |
| Leanモデル | 32対応領域の差分検査と全モデルが通過。CAD・衝突節削減全体の形式証明を追加したものではない |
| 共有被覆の独立照合 | 元式/部分式の18組・36件の厳密Z3照合、SAT弱化と5種類の証拠攻撃を全3 backendで検査 |
| 算術・SMTの回帰 | 六関係の30個の解析例、共同で矛盾する2原子、短い式と最終RUPの元問題への束縛を検査 |
| 独立fixture | 新規subset参照、既存Z3 16/41入力、真理値表スケジュール、CAD 19例・一階式6例の生成物が一致 |
| 実行ツアー | 実閉体のツアーが3 backendで掲載例と一致 |
| 同条件の性能比較 | 36比較・432回の検査付き計測。各方式6回、削減できない対照と遅い中央値も保存 |

[小さな理論衝突節の設計と計測](research/theory-core-20261117.md)に、通常経路への採用理由と保守的な失敗を記録しています。
担当用作業木をmain一つへ戻し、12資料のバイト一致、研究branchのbundle、重複したビルド出力の削除を
[片付け記録](measurements/theory-core-20261117-cleanup.json)へ残しました。

前回の`de2a892`は、CDCL状態保持まで含む
[各3,835テストの統合検証](measurements/retained-cdcl-20261117-validation.json)と
[出力](measurements/retained-cdcl-20261117-validation.txt)を保存しています。

前回の`8fe68f0`は、円柱の枝刈りまで含む
[各3,817テストの統合検証](measurements/incremental-20261117-validation.json)と
[出力](measurements/incremental-20261117-validation.txt)を保存しています。
前段階の[設計・計測](research/incremental-cad-20261117.md)では、完全CADとの比較と未完了の追加stressを区別しています。

前回の`37d82f5`は[各3,775テストの統合検証](measurements/realclosed-20261116-validation.json)
と[出力](measurements/realclosed-20261116-validation.txt)を保存しています。
多段実代数体・任意変数CAD・一階実数式の量化消去からの接続は、その記録も参照してください。

前段階は、`9880edf`の[3,311テストの仕上げ検証](measurements/advanced-20261116-final-validation.txt)、
`12db9d8`の[第二段階](measurements/advanced-20261116-second-validation.txt)、
`6934453`の[最初の検証](measurements/advanced-20261116-first-validation.txt)として保存しています。

追加算法については[個別の検証・独立レビュー](research/README.md)を参照してください。
既存のLean定理が、新しく追加した算法全体の証明へ広がったわけではありません。

<details>
<summary>前段階の基礎kernel検証とSAT反証の外部検査</summary>

次の数値は2026-11-16、計算核のソース`c331d0c`を基準に実行した記録です。
以後の文書やテストの数が同じであることを保証する値ではありません。

| 検査 | 記録された結果 |
| --- | --- |
| native / JS / Wasm GC | 各499テスト成功 |
| Pythonの保守ゲート | 12テスト成功 |
| 純記号制約 | 122核ソースが通過 |
| 公開API | 69生成スナップショットが一致 |
| Leanとの対応 | 24領域の差分検査と全モデルが通過 |
| SAT反証の外部検査 | 16証拠をLRAT/DRAT両方が受理、7偽造例を拒否 |

出力: [核・テスト・Lean](measurements/final-kernels-validation.txt) ·
[外部反証検査](measurements/final-proof-validation.txt) ·
[証拠マニフェスト](measurements/final-proof-manifest.json)

パッケージ一覧の「テスト宣言数」は実行成功数ではありません。
一つのテストに総当たりを含む場合もあるため、比較例の総数とも異なります。

</details>

## 資源と性能の限界

値の一致、再帰の深さ、割当量、実行速度は別々に確認します。
燃料付き探索の一歩にも、リスト走査や有理数演算が含まれるため、一定実時間を保証しません。

JSの通常の長語除算・剰余には、`2^20000 mod 3`で確認したスタック制約が残ります。
20,000bitは耐久試験の入力であり、上位アルゴリズムで必要な桁数を示すものではありません。
[末尾再帰化の試作](research/wide-kernels/README.md)は値とスタックの検査を通過しましたが、
nativeの剰余が遅くなるため採用していません。

性能は[同条件の比較](KERNELS.md)で判定します。異なる測定系列の倍率は掛け合わせません。
