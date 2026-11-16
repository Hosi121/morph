# 任意変数CAD・QEの独立検査（2026-11-16）

対象は `bacdea9` のCAD/一階式entry、二次符号最適化 `aedec4f`、入力束縛修正 `d99cead`。
実装担当とは別の担当が、productionを独自変更せず、有限の独立例と証明差し替えを検査した。
既存のsphere→disk、4変数量化交代、正の入れ子8乗根のテストを、そのまま追加件数に数えない。

## 独立な閉形式と実際のQQ出力

[生成器](../../tools/generate_cad_review.py) は、数式を展開するSymPyと、期待値を計算するFractionを使う。
期待する量化消去結果は実装から生成せず、係数・判別式・共通因子と量化の意味から次のように導く。

| 元の条件・量化 | 独立に導いた結果 |
| --- | --- |
| `∃y: xy=1` | `x≠0` |
| `∃y: xy²=1` | `x>0` |
| `∃y: xy²+y+1=0` / `<0` | `x≤1/4` / `x<1/4` |
| `∀y: (y-x)²≥0` / `>0` | true / false |
| `∃y: y²=x ∧ y≠0`、または `y<x` | `x>0` |
| `∃y: y(y-1)=y(y-x)=0 ∧ y≠0` | `x=1` |
| `∀y: y²≠x ∨ y≥0` | `x≤0` |
| `∃y: (x²-2)y=1` | `x²≠2` |
| `∀y: (x²-2)y²≥0` | `x²≥2` |
| `∃y∀z: (x²-2)z+y=0` | `x²=2` |
| `∃z: h(z-1)=h(z+1)=0`, `h=y²-x` | `h=0` |
| 前行に `h≠0` を追加 | false |
| `∀z: h(z-1)=0 ∨ h(z+1)=0` | `h=0` |
| `∃y∃z∀w: (xy-1)w+z=0` | `x≠0` |
| `∃z∀w: (x²-y)w+z=0` | `y=x²` |

18件のCAD/QE例と6件のscoped一階式例を追加した。
後者は逆元の存在条件、否定された平方根の存在、非線形の独立した兄弟束縛、
`∀x: x=0 ∨ ∃y xy=1`、`∃x∀y: (y²+1)x=1`、否定下の量化交代を含む。

各例はCADの再計算検査を通し、返された量化なしの有理係数多項式Boolean式を評価する。
その全atomのarityも自由変数数に一致することを確認する。
Fractionで導いた327個の有理点の期待値を比較し、さらに `x=±sqrt(2)` の両共役で、
上表の穴・非負係数・零係数へのnullificationという三つの出力を評価する。
後者によって、有理点では見えない孤立した無理数sectionを取り逃さない。

## 旧二変数経路との照合

4個の二変数族について既存 `cad2` と比較する。
旧CADの全base cellごとに `∃y` と `∀y` の結果を新しいQQ出力と照合し、
全4通りの閉じた量化対も両実装と独立な真偽期待値に照合する。
旧CAD自身の証明検査も通す。これらは新実装だけで期待値を作る自己照合ではない。

生成器は `.tools/cad-review-20261116/` に隔離workspaceと比較プログラムを作る。
`moon.pkg` 等のproduction設定を変更せず、両パッケージを同じsource snapshotから読み込む。

```sh
tools/measure --cpu 8 python3 tools/generate_cad_review.py --check
tools/measure --cpu 8 .tools/moon/bin/moon -C .tools/cad-review-20261116 run comparison --target native
```

## 証人と証明の束縛

負の `z` を選ぶ `z⁸=3` の証人を作り、8乗が3、符号が負、元の式が真であることを厳密に検査する。
符号を反転した共役は同じ8乗を持つが証人として拒否する。
座標の欠落、ambient fieldの差し替え、無関係な `sqrt(2)` contextからの座標埋め込みも拒否する。
これは入れ子の正の8乗根とは異なる、単一の8次定義と負の実埋込みの経路である。

同じprojectionを持つ `x-1>0` と `x-1≥0` の全treeを差し替える検査を加えた。
根での真偽だけが異なるため、metadataの一致に加えてterminal truthも検査する必要がある。
両方の閉じた存在量化結果がtrueでも、その異なるtreeに束縛されたencoding全体の差し替えを拒否する。
返されたEliminationのdecompositionまたはencodingを有効な別結果と交換する検査も含む。

private Problemの反例では、元のformulaを `x²-2=0` に保ち、atoms/projectionだけを `x²+1` のものに交換した。
旧checkerはこの不整合な入力と、存在量化の結果がfalseとなる証明を受理した。
`282add6` で再現し、実装担当による `d99cead` の `qf_atoms(formula)==atoms` guard後は拒否することを確認した。
公開constructorからこの不整合なProblemを作ることはできない。opaque内部の強い入力束縛を検査するwhite-box反例である。

## 検査結果と制約

新規28件に、filter名が一致する既存のsibling-binder検査1件が加わり、native / wasm-gc / JSで各29/29成功した。
旧cad2の4族比較も3 backendで成功した。警告禁止check、生成整合性、purity gateも成功した。
詳細なsource SHA、実行条件、期待値、ログは [検査記録](../measurements/cad-review-20261116.json) に保存する。

元の共有因子例 `y(y-x-1)=y(y-2x-3)=0 ∧ y≠0` は、現snapshotの個別検査で10秒の診断上限を超えた。
未完了から真偽やUNSATを推定しない。通常corpusでは上表の同じ共有零因子を持つ小さい例を使い、
元例は生成器の `comparison/stress` に、期待するQQ出力 `x=-2` とともに保存した。
`--build-only --deny-warn` は成功し、任意実行で再現できる。これは通常の全testには含めない。
この記録から性能改善や一般の計算上限は主張しない。

検査は有限のセル・根数証明・厳密な算術例に対する再計算であり、任意のRCF式についてのLean等による形式証明ではない。
