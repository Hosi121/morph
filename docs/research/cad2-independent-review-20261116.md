# relativecad / cad2 の独立レビュー

[ドキュメント](../README.md) / [研究・探索記録](README.md)

レビュー対象は root 担当の `relativecad` と、その上の二変数 CAD。
本体は変更せず、既知の族の意味から先に oracle を固定し、API 凍結後に tests を接続する。
本 note の初期段階は 2026-11-16 09:28 UTC 時点、cad2 API の発行前。

## 先に凍結した期待値

`tools/generate_cad2_review.py` は implementation の source / 実行結果を読まない。
[固定 fixture](cad2-independent-review-20261116-fixtures.json) には以下を保存する。

- 35個の二変数族、手で導いた4種類の量化真偽と理由。
  順序は `exists x exists y`, `exists x forall y`, `forall x exists y`, `forall x forall y`。
- 族の根・係数が変わる既知の x 境界をまたぐ123本の exact fibre。
  SymPy の exact roots/signs から、全 y section/sector の原子 sign と formula truth を計算する。
- Q(√2) とその負の共役における19本の fibre。
  零剰余、次数低下、重根、共有根、基礎体外の三次/四次の y 根も含む。

circle、disk、parabola、xy=0、共有線、vertical leading coefficient、
(x²−2) による irrational nullification、厳密/非厳密端点、空 formula を扱う。
量化真偽は sampling だけから推測せず、各族の明示的な恒等式・反例・証人で導き、
exact fibre の集約とも一致することを generator が確認する。
これは任意の多項式に対する別実装の CAD solver ではなく、記載した有限族の oracle。

凍結 JSON の SHA-256:
`d165ee0c6d453b940c086d2e88b7611da8290dba70b89ca380cb5173b2585ca5`。
`tools/measure --cpu 6 python3 tools/generate_cad2_review.py --check` で再生成一致を確認できる。

## 数学的な条件と初期の静的所見

一次資料は [Jovanović–de Moura, IJCAR 2012, §4.1](https://dddejan.github.io/papers/jovanovic-ijcar2012.pdf)
の Definition 2 / Theorem 2 と Lemma 1。全係数と全 reducta の自己・対 PSC を含む
Collins projection が connected な base cell 上で sign invariant なら、上の根配置と
実現される sign patterns を移せる、という条件を使う。
ここで最終的な quantifier propagation や証拠 payload の検査まで定理が代行するわけではない。

初期 `relativecad` source では、零に specialization された atom を root product から
除外しつつ、sign=Equal として保持している。全ての非零 atom を含む product の
一根区間に対し、atom の distinct-root count が1なら Equal、0なら中点 sign とする
経路は整合的。重複・共有根を product の squarefree isolation で一度だけ切ることが前提。
根区間が半開である点は中点が内部にあることと矛盾しない。

cad2 の接続で特に確認する事項は次の通り。

- 実際の元 atom と、full Collins の係数・reducta PSC の source binding。
  disc/resultant だけへの置換は、degree drop・重複・共有因子で同じ定理の仮定を満たさない。
- 純 x atom の保持、base 点での全係数消滅、定数/零/空 formula の扱い。
- base sample → minimal normalization → Field → specialized formula の同じ選択共役への束縛。
- 全 base section/sector と、各 stack の全 y section/sector の順序付き被覆。
  一部の点で正しい sign を得るだけでは全平面の結論にならない。
- 内側 y の量化を各 stack ごとに行ってから外側 x を集約すること。
  `forall x exists y` と `exists x forall y` は全 sample の flatten では区別できない。
- checker が省略・重複・他の base cell / Field / formula の証拠流用を拒否すること。

初期段階で確定した本体バグは報告していない。API 凍結後の接続・変異証拠検査と
最終的な件数・限界は追記する。

## API 発行前の oracle 精度修正

09:32 UTC、fixture をテストへ描画する際に、Python 整数 cut 同士の midpoint が
`/` によって Float になる箇所を発見した。SymPy Rational に統一し、全 fibre sample・
root・coefficient・sector sample に `Float` 不在 assert を追加した。35族/123 fibre の
全量化真偽・sign/truth と19 relative case は元の凍結値と一致し、変更は根・sample の
文字列表現の厳密化のみである。旧 JSON と比較ログを専有 artifact に保持した。
新 SHA は上記の値。cad2 本体や API に合わせた期待値変更ではない。

描画器はこの同じ固定表から、19 relative case に加え plane の123 fibre を数体係数の
直接 test に展開できる（計142）。plane 35族の量化期待値は別 adapter へ描画する。
描画器の追加は固定 JSON を変更しない。

## 凍結 API への接続と最終結果

対象 source は `relativecad b6de99b` と `cad2 316a15d`。
本体を変更せず、各 package に `independent_review*_wbtest.mbt` だけを追加した。
API 発行前の35族/123 fibre/19 algebraic fibre の期待値は、精度修正後の同じ SHA のまま。
描画された19+123=142 fibre は、atom の列順に依存せず多項式の同一性で照合し、
全 section/sector の sign と formula truth を比較する。CAD2 は固定35族の4量化値を照合する。

- relativecad: native / JS / Wasm GC 各 **148/148**（独立144 + 既存4）。
- cad2: native / JS / Wasm GC 各 **47/47**（独立40 + 既存7）。
- 純粋性 gate **192 kernel files**、generated interface、format check を通過。
- 両 fixture test file を再生成・format して byte 一致。固定 JSON SHA も不変。

最終 snapshot の CAD2 native は、後述の higher-PSC case を強化した後に再確認した。
そのため途中の旧 case の実行結果だけを現 source の成功として扱っていない。

relativecad ではセル/section/sector の削除、並替、sign/holds/sample の改変、根リスト削除、
異なる relation の formula への流用、別の共役 Field の証拠流用を拒否した。
foreign Field の atom を prepare に渡す入力も拒否する。

cad2 では、base cell と stack を同時に省略して見かけの長さを揃える攻撃、
根リスト削除、別 sample の minimal certificate、別共役の fibre だけの流用、
空 stack、source formula の差替え、正規の ProductProjection 証拠への差替え、
full Collins の principal 欄の削除を拒否した。検査 budget 不足は受理しない。
NeedsBudget から rebudget して完了し、通常の構築と同じ証拠になることも確認した。

追加の手書き例では `(x²−2)y=0` の5 base cells に対して y-root count が
`[1,0,1,0,1]`、stack cell count が `[3,1,3,1,3]` となる。
二つの irrational point では atom が全 y で0となり、strict inequality の真偽と区別できる。
公開 specialize は係数 `x³, x²+3, x+1` を Q(√2) で正しく還元し、
leading coefficient の消滅による次数低下と全係数 nullification も確認した。

## 高次 PSC だけが必要な追加族

固定35族を変更せず、数学的な結合条件から別の手書き test を追加した。

`f=y(y−x−1)`, `g=y(y−2x−3)`, formula `f=0 and g=0 and y!=0`。

`f−g=(x+2)y` なので解は唯一 `(x,y)=(-2,-1)`。
全 nonzero reducta が y を共有し、cross-resultant はすべて恒等0となる。
元 atom の係数・自己 discriminant が与える cut は `-1,-3/2` であり、
pair の高次 `PSC_1`（非零定数倍の `x+2`）が別の base section `x=-2` を作る。
実装がその唯一の true fibre を **base section** として保持することを確認した。
projection を元 atom の disc/resultant だけへ弱める経路への具体的な境界例である。

## 静的レビューの結論と限界

凍結した実装は、元 formula に対する full Collins 再検査、全 base cell の順序付き照合、
各 sample の minimal normalization の結合、同じ Field での再 specialize、
relativecad の全 stack 検査、内側 y と外側 x の別集約という必要な結合を持っている。
ここで Theorem 2 / Lemma 1 を適用する際の top variable は実装の y、base region は x cell。
sign pattern の不変性から各 fibre で量化した真偽を base cell 全体へ移す。
この幾何的定理をモデル形式で証明した、というレビュー結果ではない。

検査した有限族と公開証拠の変異では、本体の確定した誤受理は見つからなかった。
任意入力の正しさ・一般の計算量・大次数の実用性を有限 test から証明したとは主張しない。
root 側の本体 fix は要求していない。レビュー側 generator の Float 混入だけを前述の通り修正した。

ログ: `.tools/cad2-independent-review-20261116/verification-review.json`。
backend ごとの出力、fixture 再生成結果、固定 SHA を記録している。
`oracle-rational-sample-fix.json` は精度修正前後の期待 sign/truth/quantifier 一致の記録。
旧 NumberField/FGLM/Blossom/Zassenhaus/realalgebraic/compositum の artifacts は保持した。
依存 source の cherry-pick は review-only commit と分離しており、本体の差分はゼロ。
