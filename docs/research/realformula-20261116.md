# 一階実数式の束縛とprenex化（2026-11-16）

[任意変数の実閉体ソルバ](realclosed-20261116.md)の入力層として、
`src/realformula`を追加した。量化付きの有理係数多項式の式を受け、
自由変数・原式と結び付いたopaqueな`Prenex`を返す。
この層は量化消去やCADの正当性判定を行わない。

## 入力と変数順序

`normalize(free_count, source)`の原式は`Truth`、六関係の`Atom`、
`Negation`、`Conjunction`、`Disjunction`、`Exists`、`Forall`からなる。
六関係は既存の`@realcad.Relation`を共有する。

原式の束縛は局所slotで表す。量化子の深さを`d`とすると、各atomの
多項式の変数数は必ず`free_count+d`であり、先頭が自由変数、後続が
外側から内側の量化子に対応する。量化子は子の環境の末尾へ一つの
変数を追加する。未使用の変数もarityへ含め、zero多項式でも検査する。

たとえば自由変数`f`を一つ持つ
`(exists x. x=f) && (exists y. y!=f)`では、左右それぞれのatomは
局所的には`[f,bound]`の2変数である。正規化後は、prefixが
`[Exists,Exists]`、行列の変数順が`[f,x,y]`となる。
左右の局所slotを同じ全域変数へ写すと式の意味が変わるため、全原式の
量化子をpreorderで数え、各量化子へ別々の全域slotを割り当てる。

行列の全変数数は`free_count + length(quantifiers(prenex))`。
prefixは外側から内側であり、変数順は自由変数の後へprefix順に並ぶ。
`source`、`free_variables`、`variables`、`quantifiers`、`matrix`が公開取得API。

## 変換と検査

否定はDe Morgan則、六関係の補関係、`Exists`/`Forall`の双対で押し込む。
左右の量化子をhoistする前に、兄弟部分木も含めて新鮮なslotへrenameする。
hoistには実数領域が非空であることを使う。未使用のbinderも保持する。
出力行列は既存の`@realcad.Formula`で、`Negation`を残さない。
atomがなくても、自由変数やbinderがなくても変換できる。

`rename_polynomial(p,target_arity,mapping)`は、元の各変数から全域slotへの
単射を受け取る。全termの指数vectorを並べ替え、未使用slotへ零を補う。
mapping長の不一致、重複slot、範囲外slotは拒否する。多項式は既存の
正規化constructorで再構築する。

公開`Certificate`は原式、自由変数数、prefix、行列を持つ未信頼値。
`check(free_count,source,certificate)`は原式から変換を再実行し、全fieldを
比較してからopaqueな`Prenex`を返す。これは有限な構文変換の再検査であり、
意味保存の形式証明、RCF判定、実装言語全体の検証ではない。

`qf_atoms`は行列の多項式を左からの初出順に重複なく返す。
`relation_holds`は符号と六関係を解釈する。`evaluate_signs`はatom/sign数の
不一致、重複atom、行列に必要なatomの欠落を拒否し、両Boolean分枝を検査する。
追加の相異なるatomは許す。

## 独立照合と実測

専用packageの112テストがwasm-gc、js、nativeの各backendで成功した。
詳細は[検証記録](../measurements/realformula-validation-20261116.json)と
[fixture集計](../measurements/realformula-fixtures-20261116.json)。

- Pythonの`Fraction`による原式の直接interpreterから104式の期待値を生成した。
  4つの非空有限領域、956自由変数割当（真535、偽421）を照合した。
  MoonBit側は原式とprefix/行列をそれぞれ別に解釈し、両者をPython期待値と比較する。
  多項式の符号はtest専用の機械整数による有理数oracleで計算し、productionの
  多項式評価器・符号関数・関係関数を呼ばない。
- 量化交代7段/9変数、兄弟4binder、捕獲の回帰例、六関係と補関係、
  否定の双対、無使用binder、0自由変数、空atom族、arity違反を含めた。
- 0〜3元変数から0〜4先変数への全65単射について、3,805先割当で
  rename前後の多項式の符号を照合した。符号付き有理係数と非自明な指数を含む。
- 原式、入力arity、prefix、行列、別入力の結果の差替えをcheckerが拒否した。
- `moon check --deny-warn`、`moon fmt --check src/realformula`、fixtureの
  `--check`、`audit_purity.py`が成功した。手書きkernelには機械数値型・
  数値literal・数値演算子・array・mutation・FFIを含めない。

各build/testは`tools/measure --cpu 10`で共通Git lockを取得した。
測定値はこの検証実行の記録であり、性能向上やscalingの主張には使わない。
有限領域の照合が裏付けるのは束縛・構文変換の回帰例であり、有限領域の
真偽を実数上の真偽へ読み替えない。CAD・実根塔・実数上の量化消去の検査は統合層が担う。
