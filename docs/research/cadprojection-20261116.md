# 任意変数のCollins射影と導関数閉包（2026-11-16）

目的は、有理係数の有限変数CADで再利用できる射影階層と、その入力に束縛された検査器を作ること。
実根のlifting、全セル被覆、量化消去の実行はこのパッケージの担当ではない。
既存の二変数専用 `projection` は変更せず、回帰検査の比較対象に残した。

## 射影の定義

[Jovanović–de Moura, Solving Non-Linear Arithmetic, §4.1 Definition 2 / Theorem 2](https://dddejan.github.io/papers/jovanovic-ijcar2012.pdf)
に従う full Collins を使う。全係数、各非零sparse reductumとその導関数の全PSC、
異なる入力多項式の全reducta対の全PSCを含める。零、多重因子、content、共有因子を除去しない。
同論文の規約で終端 `PSC_min=1` とし、一般の固定次数Sylvester行列における
`lc(smaller)^abs(degree gap)` と区別する。各出力多項式の変数数は必ず入力変数数より一つ少ない。
有理係数への適用では正の整数分母を払えるため、符号不変性と零点集合の条件は整数係数の定理に帰着する。

`full_collins(arity, atoms)` は明示された `arity` の最終変数を消去する。
`reducta`、全係数、各PSC行の左右入力と全値を `ProjectionCertificate` に保持する。
`check_projection` は外部のarityと元の入力列からこれらを再計算して一致を調べる。

## 導関数閉包と階層

`prepare(arity, atoms)` は、各段でまず最終変数の全導関数を追加し、それからfull Collinsを適用する。
`levels(plan)` は `0, ..., arity` の昇順で、空入力でも全段を持つ。各段の変数順は元の順序の接頭辞。
変数を消去するときに残りの順序を入れ替えない。arityゼロも有理定数の入力を受け付ける。

各段の `family` は、元の非定数入力を先に置き、その後で各入力の導関数列を追加した安定順。
係数倍の正規化、monic化、因数分解を行わず、多項式として完全に等しい重複と真の有理定数だけを除く。
最終変数に依存しないが下位変数に依存する係数は真の定数ではないので残す。
生の射影証明から零・定数・重複は取り除かず、その全出力を同じ規則で整理して次の下位段の入力にする。
この整理は、真の定数の符号が全空間で既知で、等しい多項式の符号条件は同じであることに基づく。
この変更について速度改善は主張しない。

`Level.bindings` は `Level.source` の順に `Constant(Ordering)` または `Member(Nat)` を持つ。
添字は `family` のゼロ始まり。元の零・定数・重複・係数の符号を保持する。
`Level.derivatives` は `family` と同じ長さで、その各導関数の同じ対応を保持する。
`source_signs(level, signs)` は族の符号列から元の入力順の符号を復元し、族と長さの違う符号列を拒否する。
外部から作成可能な `Level` 単体を信頼するためのAPIではなく、検査済みPlanの段に使う。

[Chen–Moreno Maza, Quantifier Elimination by CAD Based on Regular Chains, §3 Lemma 1 / 2、§4 Lemma 3](https://www.csd.uwo.ca/~mmorenom/Publications/Quantifier_Elimination_by_Cylindrical_Algebraic_Decomposition_Based_on_Regular_Chains.JSC_version.pdf)
は、導関数で閉じた一変数族の符号条件が空集合・点・開区間になり、適切なdelineability条件の下で
セルの符号定義を得られる根拠を与える。このパッケージは因数分解による閉包より強い、導関数そのものの閉包を作る。
係数を特殊化して零・定数になる多項式を除いても微分と特殊化は交換するため、残りの一変数族はこの条件を満たす。
異なる兄弟セルの符号列を区別する根拠と、Collins射影による基底上のdelineabilityの根拠は別である。
regular chainsのCADアルゴリズムを実装したという意味ではない。

## 検査と反例

`Certificate` は元のarity・元のatoms・全段のsource/family/対応・射影の生データを持つ。
`check(arity, atoms, proof)` は全階層を外部入力から再計算する。
`check_result` はさらに提示されたPlanとCertificateの一致を調べる。
別の正しいPlanの貼り付け、段の脱落、導関数の脱落、PSCの脱落、元のatomsの順序変更も拒否する。
この有限構成の再計算検査は、CADの一般定理や停止性の形式証明ではない。

共有因子の回帰例は `f=y(y-x-1), g=y(y-2x-3), y!=0`。
元のf,gのresultantは恒等的に零だが、`PSC_1(f,g)=-(x+2)` を保持する。
厳密な恒等式 `g-f=-(x+2)y` と証人 `(-2,-1)` によって、非零の共有根には `x=-2` が必要であることも検査する。
単に元の多項式対のresultantを残す実装とは区別する。

## 検証結果と制約

独立生成器 [generate_cadprojection.py](../../tools/generate_cadprojection.py) は、
SymPyの厳密 `Matrix.det` と別の順列展開でPSCを相互照合し、15個の1〜4変数の全射影データと、
10個の0〜4変数の導関数閉包階層を生成する。二変数の生射影は既存APIとも完全一致を確認する。
その他、空の7変数階層、3/4変数のsparse reductaと終端出力arity、nullification、degree drop、
元の符号の復元、証明改竄を検査する。

計算核は既存の `Nat` / `Chain` / 有理数・多項式・eliminationを使い、機械数値・配列・変更可能状態・FFIを導入しない。
PSCの行列式計算、全reducta対の列挙、導関数の追加には大きな計算量と証明サイズがあり、実用的な最大次数や変数数は主張しない。
全係数・全PSCを省略しないため、局所射影や縮約Collinsの性能を代替するものでもない。

実行条件と3 backendの結果は [検査記録](../measurements/cadprojection-20261116.json) に保存する。
