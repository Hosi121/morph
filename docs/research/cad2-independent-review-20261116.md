# relativecad / cad2 の独立レビュー

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
