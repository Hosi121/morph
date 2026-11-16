# 研究・探索記録

[ドキュメント](../README.md) / [探索・改善記録](../bootstrap/README.md)

実装、独立レビュー、性能比較、未採用の試作をテーマ別に探すための索引です。
各ページは開発時点の判断と証拠を保存しています。現在の設計は[ハンドブック](../../HANDBOOK.md)、
採用状況は[基礎部品の最適化](../KERNELS.md)、確認済みの範囲は[検証ガイド](../VALIDATION.md)を参照してください。
性能の数値と比較条件は[計測記録](../MEASUREMENTS.md)から辿れます。

## 実数制約・CAD・非線形SMT

現在の入力・出力・探索経路は[実数制約の章](../handbook/real-constraints.md)にまとめています。
下表では、実装の記録と対応する独立検査を並べています。

| テーマ | 実装・設計の記録 | 独立検査・比較の記録 |
| --- | --- | --- |
| 一変数の実数制約 | [符号不変分割と証人](realcad-20261116.md) | [独立符号・境界検査](realcad-independent-review-20261116.md) |
| 多段実代数塔 | [選択根を係数とする順序体](realtower-20261116.md) | [可約・従属拡大と証拠の差し替え検査](realtower-independent-review-20261116.md) |
| 数体係数の実根 | [相対Sturm・全根被覆](orderedsturm-20261116.md) | 同記録に独立Fraction・SymPyとの照合 |
| 二変数CAD | [相対符号分割](relativecad-20261116.md)・[二変数CAD・量化文](cad2-20261116.md) | [独立レビュー](cad2-independent-review-20261116.md) |
| 量化結果の区間表現 | [厳密な区間集合](semialgebraic-20261116.md) | 同記録に真偽列・境界・所属判定の検査 |
| 射影 | [Collins射影](projection-20261116.md)・[任意変数の射影](cadprojection-20261116.md) | 各記録に定義と独立オラクルとの照合 |
| 一階実数式 | [変数捕獲を避ける正規化](realformula-20261116.md)・[符号木から量化なしの式へ](signcad-20261116.md) | 各記録に独立参照・真偽表との照合 |
| 任意変数のCAD・量化消去 | [再帰liftingと式出力](cad-20261116.md) | [CAD・量化消去の独立レビュー](cad-independent-review-20261116.md) |
| CADの根集合 | [小さい次数を保つ根集合の構成](cad-root-union-20261116.md) | 同記録に除算恒等式と従属座標の比較 |
| 非線形実数SMT | [厳密モデル・CAD理論補題・RUP反証](realnlsmt-20261116.md) | [独立Z3照合と証拠の差し替え検査](realnlsmt-independent-review-20261116.md) |
| CADの早期終了・枝刈り | [必要なセルから探索するCAD](incremental-cad-20261117.md) | 同記録に独立Z3照合と同条件比較 |
| CDCL状態の保持 | [理論衝突の後もCDCLの状態を使う](retained-cdcl-20261117.md) | 同記録に独立真理値表と同条件比較 |
| 理論衝突節の削減 | [既存被覆から小さな理論衝突節へ](theory-core-20261117.md) | 同記録に独立Z3照合・部分式の証拠検査と同条件比較 |

## 多項式・厳密代数

部品の接続を先に読む場合は[厳密代数の計算経路](../handbook/algebraic-solving.md)を参照してください。

| テーマ | 実装・設計の記録 | 独立検査・採用の記録 |
| --- | --- | --- |
| 整数・有理多項式の分解 | [Berlekamp・Hensel・Zassenhaus](zassenhaus-20261116.md) | [独立レビュー](zassenhaus-independent-review-20261116.md) |
| 実代数的数 | [resultant・共役選択・厳密演算](realalgebraic-20261116.md) | [独立レビュー](realalgebraic-independent-review-20261116.md) |
| 複素代数的数と全根 | [因数分解・厳密演算・全根の接続と比較](complex-algebra-20261117.md) | [Fraction・SymPyの厳密な参照値](complex-oracle-20261117.md) |
| 複素数体と絶対一生成元 | [K(i) の固定基底と α+i への変換](complex-fields-20261117.md) | [数体の参照値](complexfield-oracle-20261117.md)・[変換の参照値](complexprimitive-oracle-20261117.md) |
| 自己同型と固定体 | [全自己同型・部分群・固定される体の接続](complex-galois-20261117.md) | [有限群の参照](complexautomorphism-oracle-20261117.md)・[不変部分空間の参照](fixedfield-oracle-20261117.md) |
| 最小多項式への正規化 | [不要な因子を除く](realminimal-20261116.md) | 同記録に既約性の確認と採用条件 |
| 数体Q(α) | [剰余演算・Bézout逆元・実埋込み](numberfield-20261116.md) | 同記録に独立Fractionとの照合 |
| 共通の実数体 | [primitive elementへの埋込み](compositum-20261116.md) | [独立レビュー](compositum-review-20261116.md) |
| 有限な実解集合 | [一変数表現から元座標へ](realvariety-20261116.md) | [shape・座標の独立レビュー](realvariety-independent-review-20261116.md) |
| Gröbner基底 | [F4と元入力への証拠](f4-20261116.md)・[FGLMによる順序変換](fglm-20261116.md) | 各記録に証拠検査・独立SymPyとの照合 |
| 環上の線形代数 | [Berkowitzの特性多項式](berkowitz-20261116.md)・[Bareiss行列式](bareiss-20261116.md) | [Bareissの通常経路への採用](bareiss-adoption-20261116.md)、各記録の独立照合 |
| 疎Horner評価 | [一変数の通常経路と実数制約](sparse-horner-20261116.md) | [独立QQ・Leanレビュー](sparse-horner-independent-review-20261116.md) |
| 根上の符号 | [Sturm–Tarskiの符号判定](tarski-20261116.md) | 同記録に独立オラクルとの照合 |
| 環上の消去 | [resultant・判別式・Bézout証拠](elimination-20261116.md)・[principal subresultants](elimination-principal-20261116.md) | 各記録に独立行列式・gcd・SymPyとの照合 |

## グラフ・モデル検査・符号

| テーマ | 記録と検査 |
| --- | --- |
| 一般グラフのマッチング | [Blossom](blossom-20261116.md)：奇数サイクルの縮約・展開、Tutte–Berge証拠 |
| パリティゲーム | [Zielonka法と位置戦略](parity-20261116.md)：独立した閉路検査 |
| μ-calculus | [パリティゲームへのコンパイル](mucalc-20261116.md)：独立な集合反復との比較 |
| 二進BCH符号 | [構成・系統符号化・代数的訂正](bch-20261116.md) |
| GSリスト復号 | [多重度補間とRoth–Ruckenstein](listdecode-20261116.md) |

## 横断的な探索と未採用の試作

| 記録 | 保存している内容 |
| --- | --- |
| [任意変数の実閉体ソルバ](realclosed-20261116.md) | 多段の実代数拡大からCAD・量化消去・非線形SMTをつないだ経緯 |
| [複雑な算法への挑戦](advanced-algorithms-20261116.md) | 実数制約・計算代数・ゲーム・符号の探索と統合の経緯 |
| [探索とリファクタリングの履歴](HISTORY.md) | 初期の動機、実装、表現コストの見直し、検証の経緯 |
| [長語除算・剰余の試作](wide-kernels/README.md) | 逆順fold、末尾再帰、有限prefix、unrollの比較。通常経路へ未採用 |

記録中の期限・作業場所・テスト数は当時の条件です。
テストや独立オラクルとの照合は、各記録の有限な入力に対する結果です。
形式証明のモデル・前提・実装との対応は、各記録と[検証ガイド](../VALIDATION.md)を参照してください。
試作の成功例を、通常のライブラリ経路の成果や性能として読み替えないでください。
