# 研究・探索記録

[ドキュメント](../README.md) / [探索・改善記録](../bootstrap/README.md)

実装、独立レビュー、性能比較、未採用の試作をテーマ別に探すための索引です。
各ページは開発時点の判断と証拠を保存しています。現在の設計は[ハンドブック](../../HANDBOOK.md)、
採用状況は[基礎部品の最適化](../KERNELS.md)、確認済みの範囲は[検証ガイド](../VALIDATION.md)を参照してください。
性能の数値と比較条件は[計測記録](../MEASUREMENTS.md)から辿れます。

## 数学的構成と表現

| 記録 | 保存している内容 |
| --- | --- |
| [数学的構成の共有監査](mathematical-constructions-20261118.md) | 6領域の共通原理・固有条件・実重複、既存の構造利用との区別 |
| [商構成の試作と採否](quotient-prototype-20261118.md) | 商環構成の設計・保持判断、厳密結果・純増LOC・140プロセスの時間とRSS |

## 確率・微分幾何

現在の部品の接続は[確率と情報幾何](../handbook/probability-geometry.md)を参照。

| 記録 | 保存している内容 |
| --- | --- |
| [確率・情報幾何と拡大体の接続](probability-geometry-20261118.md) | 全体の計算経路、共通テンソル、実際のモデルを含む全100出力の比較 |
| [Amari–Chentsovと一般α接続の独立検証](amari-chentsov-independent-20261118.md) | Gaussianのlog-partition微分、有限モデル4点・20接続/曲率、3targetでの厳密な成分比較 |
| [拡大体上の楕円曲線](extension-curves-20261118.md) | Jacobian座標、体と曲線の文脈、独立affine参照の全点対・三つ組 |
| [拡大体上のTate評価](extension-pairings-20261118.md) | shifted divisor、Millerの中間零/極、全商群・双線形性・独立有限体参照 |
| [点での微分幾何](riemann-20261118.md) | 計量jetの検査、接続と曲率、独立Fraction参照 |
| [高階テンソルの共通部品](tensor-20261118.md) | shape・置換・縮約・mode product、零次元と演算辞書 |
| [多項式の微分形式](forms-20261118.md) | 外積と外微分、次数と符号、縮約とCartanのLie微分 |
| [微分形式と単体の積分](simplexforms-20261118.md) | 向き付き単体、厳密積分、全境界を束縛するStokes証拠 |
| [Gaussianの厳密モーメント](gaussian-20261118.md) | Stein再帰・不変memoization、独立Wick pairingとの照合 |
| [有限Markov連鎖](markov-20261118.md) | 確率核・時間発展の規約、検査と独立参照 |

## 体の算法とカーネル

| 記録 | 保存している内容 |
| --- | --- |
| [変換監査からの基礎改善](conversion-kernels-20261117.md) | monicとSmith情報の共有、定数・剰余の見送り、証拠の通常lint |
| [数値とwordの表示の分離](numeric-serialization-20261118.md) | 二進数の可変bit幅とbig-endian wordの誤用、往復テストとlint、旧stdoutの限界 |
| [表現変換と準備の重複の監査](conversion-audit-20261117.md) | 関数をまたぐNat往復、重複正規化・索引再構築、必要な境界との区別 |
| [26時枠の共通部品改善](late-kernels-20261117.md) | 前の検証済み版からの採否、検証再開の通常化 |
| [減算融合の見送り](late-subtraction-20261117.md) | 限定的な相殺の改善、二案の一般入力・上位処理と再現パッチ |
| [既知のFrobenius平方](late-frobenius-20261117.md) | 係数の零挿入、modular powerと体の構築、奇標数対照 |
| [Bool行列積と生成側の接続](late-bool-product-20261117.md) | callbackを省く積、shape、generic検査と共有依存の区別 |
| [Fpの余り専用power](late-fp-remainder-20261117.md) | 捨てていた商を作らず、公開divideと全出力を照合 |
| [QQ多項式の単位積](late-poly-unit-20261117.md) | 正規な±1の判定、immutableな結果共有、独立Fraction参照 |
| [係数列の準備の見送り](late-basis-20261117.md) | GF(2)の全基底・affine solveの一致と小・疎・密の回帰 |
| [積の平衡merge](night-product-20261117.md) | 期限時点の未計測記録と、親による凍結比較・採用判断 |
| [Fp畳み込みの行共有](night-convolution-20261117.md) | 零・単位係数の行分岐、初回比較とGF(2)対照の再測定 |
| [未採用の行cursor](night-cursors-20261117.md) | 密・幅広の改善と、小・疎行列の回帰で見送ったADT試作 |
| [商を作らない正規形](night-normal-form-20261117.md) | 余り専用の多変数還元、独立Fraction・旧divideと上位Buchbergerの比較 |
| [Fpの正規化済みHorner](night-evaluation-20261117.md) | 任意長の評価点・定数・listdecodeと共有検査の限界 |
| [GF(2)消去の走査融合](night-gf2-elimination-20261117.md) | 最初の不採用、参照カウントを調整した再試作と小さい回帰 |
| [夜間の共通部品改善](night-kernels-20261117.md) | 固定法乗算、Fpスカラー、GF(2)零空間の採否と反証された前提 |
| [固定法の余り専用計算](night-nf-20261117.md) | 数体の準備費用・一回利用・複素平方の比較 |
| [正規係数の積とスカラー共有](night-fp-20261117.md) | 任意のpublic scalarを保つ内部境界と有限体の対照 |
| [単調なGF(2)零空間](night-gf2-20261117.md) | pivot走査、再利用solveとコホモロジーの完全出力照合 |
| [数体・線形従属・Smithの算法改善](algorithm-kernels-20261117.md) | 五候補の採否、統合後440試行、逆依存検証と片付け |
| [数体の加減算と座標](nf-kernels-20261117.md) | 正規形の再利用・一回の項走査と段階別比較 |
| [増分の有理線形従属](incremental-span-20261117.md) | 不変状態と元列への係数、最小多項式・FGLM、独立Fraction参照 |
| [Smithと持続性の構造改善](structural-kernels-20261117.md) | 直接列操作の採用、pivot索引二案の不採用、遷移と証拠の照合 |
| [体の専用化と再利用](field-kernels-20261117.md) | 三担当の採否、CSS・コホモロジーへの接続、複素積の不採用案 |
| [GF(2)専用核](gf2-kernel-20261117.md) | Bool消去、再利用分解、変換の逆再生、独立oracleと30比較 |
| [Fp多項式の正規形](canonical-fp-20261117.md) | opaqueな係数の界限、Optionによる補正、独立oracleと公開API比較 |
| [有理数の零行共有](rational-elimination-20261117.md) | 正規形の条件、Fraction参照、疎・密と上位callerの比較 |
| [素体の標数2](prime-arithmetic-20261117.md) | 未還元入力のparity辞書、一般剰余の不採用、未変更対照の揺れ |

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
| 最小分解体とGalois群 | [共有座標から最小体・完全な根置換群への接続](complex-splitting-20261117.md) | [共通体](complexcohort-oracle-20261117.md)・[生成体](complexsubfield-oracle-20261117.md)・[返却値の独立レビュー](complexsplitting-review-20261117.md)・[置換群](splittinggalois-oracle-20261117.md) |
| 箱上の多項式の包囲と正性 | [Bernstein基底と細分証明](bernstein-20261117.md) | 同記録に独立Fraction基底展開・二変数細分・証拠改竄の照合 |
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
| CSS符号 | [GF(2)のrank証拠・論理商・最小距離](csscode-20261117.md)：単体境界、Steane符号、独立bitmaskとの接続 |
| GSリスト復号 | [多重度補間とRoth–Ruckenstein](listdecode-20261116.md) |

## 群・位相

| テーマ | 記録と検査 |
| --- | --- |
| 有限置換群 | [閉包・導来列・可解性](permgroup-20261117.md)：C1〜C8、V4、S3、D4、A4、S4、A5、S5を独立置換モデルと照合 |
| 整数ホモロジー | [向き付き境界とSmith基底](homology-20261117.md)：小複体の全列挙、射影平面のねじれ、トーラス、独立な最大minorのgcd |
| 持続ホモロジー | [疎なGF(2)還元と変換証拠](persistence-20261117.md)：すべてのprefix対のrank invariantを独立計算 |
| 単体写像・誘導準同型 | [向き・退化・整数の商への下降](simplicialmap-20261117.md)：整数Smith基底と頂点写像の独立照合 |
| コホモロジー環 | [商基底・cup積・全積表](cohomology-20261117.md)：トーラスとwedgeの区別、167小複体の独立set-span参照 |
| 相対群・連結写像 | [整数の持ち上げと境界](relativehomology-20261117.md)：315小対、RP2のねじれ、基底変換と下降 |
| 通常・filteredな崩壊 | [整数のI/P/Hと自由面](collapse-20261117.md)：167複体・340収縮。[持続性への接続](topology-rings-20261117.md)でgradeを検査 |
| 群表示の可換化 | [関係式の指数和からSmith余核へ](presentation-20261117.md)：独立な小行列式モデル、位相との対応、可換化0を持つ非自明な群 |

## 横断的な探索と未採用の試作

| 記録 | 保存している内容 |
| --- | --- |
| [任意変数の実閉体ソルバ](realclosed-20261116.md) | 多段の実代数拡大からCAD・量化消去・非線形SMTをつないだ経緯 |
| [複雑な算法への挑戦](advanced-algorithms-20261116.md) | 実数制約・計算代数・ゲーム・符号の探索と統合の経緯 |
| [群・不等式・位相の接続](cross-domain-20261117.md) | 独立した三分野の作業契約、Galois作用と導来列への接続、共通部品の検証 |
| [位相・写像・持続性・符号の接続](topology-20261117.md) | 三分野の作業契約、有理点群からのRips filtration、係数変更と次元打ち切り |
| [積・相対群・崩壊の接続](topology-rings-20261117.md) | 同じ加法的ホモロジーを積で区別し、整数共通核とfiltered contractionへつなぐ |
| [探索とリファクタリングの履歴](HISTORY.md) | 初期の動機、実装、表現コストの見直し、検証の経緯 |
| [長語除算・剰余の試作](wide-kernels/README.md) | 逆順fold、末尾再帰、有限prefix、unrollの比較。通常経路へ未採用 |

記録中の期限・作業場所・テスト数は当時の条件です。
テストや独立オラクルとの照合は、各記録の有限な入力に対する結果です。
形式証明のモデル・前提・実装との対応は、各記録と[検証ガイド](../VALIDATION.md)を参照してください。
試作の成功例を、通常のライブラリ経路の成果や性能として読み替えないでください。
