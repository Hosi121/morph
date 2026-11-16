# 研究・探索記録

[ドキュメント](../README.md) / [探索・改善記録](../bootstrap/README.md)

設計上の考察、複雑な算法への挑戦、通常経路へ採用しなかった試作を保存します。
現行の設計説明は[ハンドブック](../../HANDBOOK.md)、採用状況は[基礎部品の最適化](../KERNELS.md)を参照してください。

| 記録 | 内容 | 状態 |
| --- | --- | --- |
| [理論衝突の後もCDCLの状態を使う](retained-cdcl-20261117.md) | 単調な節追加・学習履歴・trail・watchの保持 | 独立真理値表・3 backend検査・432回の検査込み比較 |
| [必要なセルから探索するCAD](incremental-cad-20261117.md) | 厳密な早期SAT終了・親セル全体の偽を検査する枝刈り | 独立Z3・3 backend照合、検査込みの同条件比較 |
| [符号木から量化なしの式へ](signcad-20261116.md) | 任意深さの量化fold・有理多項式によるセルの式化 | 全512真偽表・3 backendで検査 |
| [多段実代数塔](realtower-20261116.md) | 親の選択根を係数とする順序体と相対実根 | 演算・相対実根の初期検査、独立レビュー中 |
| [任意変数の射影](cadprojection-20261116.md) | 導関数で閉じた全Collins射影の階層 | 独立PSC・3 backendで検査 |
| [一階実数式の正規化](realformula-20261116.md) | 変数捕獲を避けたprenex化と量化の否定 | 独立Fraction・112テスト×3 backend |
| [任意変数のCADと量化消去](cad-20261116.md) | 再帰lifting、全木検査、複数自由変数のQQ式出力 | CAD・一階式15テスト×3 backend |
| [実代数塔の独立レビュー](realtower-independent-review-20261116.md) | 可約・従属拡大・Fraction/SymPy・coherent証拠改竄 | opaque payload反例を修正し3 backend確認 |
| [非線形実数SMT](realnlsmt-20261116.md) | CAD理論補題・厳密モデル・最終RUP反証 | 独立Fraction・126テスト×3 backend |
| [CAD・量化消去の独立レビュー](cad-independent-review-20261116.md) | 327有理出力・代数的section・負の8次証人・旧cad2と照合 | 3 backendで検査 |
| [非線形SMTの独立レビュー](realnlsmt-independent-review-20261116.md) | 2〜4変数の正確なZ3照合・coherent証拠差替え | 通常38例＋改竄4例を3 backendで検査 |
| [CADの根集合を小さい次数で保つ](cad-root-union-20261116.md) | 除算恒等式で検査したmonic LCMと従属座標の比較 | 元の時間超過例を通常回帰へ復帰 |
| [任意変数の実閉体ソルバ](realclosed-20261116.md) | 多段の実代数拡大から量化消去・非線形SMTへ | 目標の実装・3 backend検証・片付け完了 |
| [複雑な算法への挑戦](advanced-algorithms-20261116.md) | 実数制約・計算代数・ゲーム・符号をつなぐ4時間の探索 | 全3 backend・公開同期・片付け完了 |
| [一変数の実数制約](realcad-20261116.md) | 符号不変分割、無理数の証人、存在・全称と証拠検査 | 統合済み |
| [一般グラフのマッチング](blossom-20261116.md) | 奇数サイクルの縮約・展開、Tutte–Berge証拠 | 統合済み |
| [整数・有理多項式の分解](zassenhaus-20261116.md) | Berlekamp・Hensel・Zassenhaus | [独立レビュー](zassenhaus-independent-review-20261116.md)済み |
| [二進BCH符号](bch-20261116.md) | 共役根からの構成、系統符号化、代数的訂正 | 統合済み |
| [GSリスト復号](listdecode-20261116.md) | 多重度補間、Roth–Ruckenstein、複数候補 | 統合済み |
| [実代数的数](realalgebraic-20261116.md) | resultants、共役選択、厳密な演算 | [独立レビュー](realalgebraic-independent-review-20261116.md)・返却値の束縛を補強 |
| [F4 Gröbner基底](f4-20261116.md) | Macaulay行列、元入力へのideal witness | 統合済み |
| [実数制約の独立レビュー](realcad-independent-review-20261116.md) | Fraction・二次体の独立符号と境界検査 | 検査範囲で反例なし |
| [パリティゲーム](parity-20261116.md) | Zielonka法、位置戦略、独立した閉路検査 | 統合済み |
| [有限な実解集合の表現](realvariety-20261116.md) | 分離線形形式を探し、全実根を元座標へ射影する | [shape・座標の独立レビュー](realvariety-independent-review-20261116.md)済み |
| [μ-calculusモデル検査](mucalc-20261116.md) | 最小・最大不動点と様相演算をパリティゲームへコンパイル | 独立な集合反復と比較 |
| [FGLMによる順序変換](fglm-20261116.md) | 零次元商空間の線形従属から目標順序の基底を構成 | 独立SymPyの3順序と比較 |
| [最小多項式への正規化](realminimal-20261116.md) | QQ既約分解と一根区間で不要な因子を除く | 既約性Provenを必須にして統合 |
| [数体Q(α)](numberfield-20261116.md) | 剰余演算、Bézout逆元、trace/norm、要素の最小多項式と実埋込み | 独立Fractionと比較 |
| [除算不要の特性多項式](berkowitz-20261116.md) | 環上のBerkowitzと随伴行列 | Fractionの順列展開・余因子と比較 |
| [疎Horner評価](sparse-horner-20261116.md) | 一変数の通常経路と実数制約の計測 | [独立QQ・Leanレビュー](sparse-horner-independent-review-20261116.md)後に採用 |
| [Sturm–Tarskiの符号判定](tarski-20261116.md) | 半開端点のTaylor jetsと負剰余列で根上の符号を求める | 独立oracle356 query＋40根符号 |
| [環上の消去](elimination-20261116.md) | 固定次数resultant、discriminant、Bézout証拠とQQ projection | 独立置換展開・SymPyと比較 |
| [共通の実数体](compositum-20261116.md) | 原入力の選択根をprimitive elementの剰余へ埋め込む | [独立レビュー](compositum-review-20261116.md)済み |
| [principal subresultants](elimination-principal-20261116.md) | 固定次数のPSCとQQ変数消去への接続 | 独立determinant/gcd oracle |
| [Collins projection](projection-20261116.md) | 全reducta・導関数・atom対のPSCを投影する | 一次資料の定義と独立oracle |
| [数体係数の実根](orderedsturm-20261116.md) | 相対Sturm・半開根数・tower rootと全根cover | 3 backend、独立Fraction/SymPy |
| [数体係数の符号分割](relativecad-20261116.md) | 相対SturmからBoolean制約の全セルへ | [独立レビュー](cad2-independent-review-20261116.md)済み |
| [二変数CAD・量化文](cad2-20261116.md) | full Collinsと代数的lifting、量化順序どおりの集約 | [独立35族・142 fibre](cad2-independent-review-20261116.md)と一致 |
| [厳密な区間集合](semialgebraic-20261116.md) | 量化結果を代数的端点の区間・点の集合へ | 全170 truth列と境界・membershipを検査 |
| [Bareiss行列式](bareiss-20261116.md) | 整数保存・分母払い・任意精度oracle・同一artifact比較 | [通常経路へ採用](bareiss-adoption-20261116.md) |
| [探索とリファクタリングの履歴](HISTORY.md) | 初期の実装、表現コストの見直し、検証と統合の経緯 | 当時の記録を保存 |
| [長語除算・剰余](wide-kernels/README.md) | 逆順fold、末尾再帰、有限prefix、unrollの比較 | 通常経路へ未採用 |

履歴にある期限・作業場所・テスト数は当時の条件です。
試作の成功例を、通常のライブラリ経路の成果や性能として読み替えないでください。
