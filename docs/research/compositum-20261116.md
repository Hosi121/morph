# 選択された二つの実代数的数の共通体

[ドキュメント](../README.md) / [研究・探索記録](README.md)

`src/compositum/` は二つの `realalgebraic.Number` a,b を、同じ検査済み
`numberfield.Field = Q(theta)` に写す。`theta = a + s*b` の整数係数 s を有限回試し、
共通体の二つの `Element` と、外部入力から実埋込みまでを束縛する証拠を返す。
既存ライブラリの source は変更しない。

## API と計算経路

`compose(a,b,budget) -> Result[Progress,CompositumError]` は一回の明示的な構築。
結果は `Composed(Common,Certificate)` または `Unresolved(StopReason)`。
`Common` は opaque で、`common_field/left_element/right_element` が公開 accessor。

1. a,b の現在の定義多項式を `m_a(x),m_b(y)` に lift し、順序付き Cartesian
   Problem を作る。定義が非minimalでも受け付ける。
2. 凍結した `realvariety` の separation search を使い `t=x+s*y` の整数 seed を試す。
   F4 の証拠・shape・全実根の被覆が検査された `SeparatedSet` が必要。
3. 全 projected point の両座標を Number 化する。各座標を外部の a,b と exact compare
   し、両方 Equal の点がちょうど一つであることを確認する。
   一根区間の端点を直接包含比較して選ぶ方法には依存しない。
4. 選択された t の Number を `realminimal.normalize` で明示的に正規化する。
   完全因数分解・選択因子の既約性が `Proven` の場合だけ Field を作る。
5. その点の RUR 座標 `h_x(t),h_y(t)` を最小因子で剰余に落とし、二つの Element にする。
6. 両 Element を `numberfield.realize` で Number に写し、外部入力との等値証拠を得る。

## checker の結合条件

`check(a,b,proof,verification_fuel)` は `Proven/Refuted/Undecided` を返す。
`check_result(a,b,common,proof,fuel)` は別渡しの返却 payload も検査する。
checker は次を独立に確かめる。

- 外部 Number の厳密 root certificate と証拠の a,b が一致する。
- 外部入力から再構成した元の Problem に separation の source、lift、graph relation、
  F4 ideal witness、shape、全根被覆、projection dimension が束縛される。
- 全点の順序と同じ長さの selection rows があり、各座標証拠はその点・正しい index に
  束縛される。全 exact comparison を検査し、Equal/Equal の唯一の index が selected と一致する。
- 選択 parameter の厳密 root certificate が minimal normalization の input と一致する。
  Field は `numberfield.field` を通じて `realminimal.check=Proven` の場合のみ再構成する。
- `h_x,h_y mod m_theta` を再構成し、それぞれの実数変換証拠と a,b への等値証拠を検査する。
- 剰余体の中でも **`generator = x + s*y`** が成り立つ。
- payload checker は Field の完全な minimal certificate、各 Element の parent context、
  正規剰余を一致させる。正しい証拠と別 Field/別共役の同じ形の剰余を組み合わせても拒否する。

`h_x,h_y` の実埋込みが a,b なので `Q(a,b) subset Q(theta)`。
一方、検査された線形関係から `theta=a+s*b` であり `Q(theta) subset Q(a,b)`。
既約 m_theta が与える忠実な実埋込みのもとで、返す体は選択された a,b の実 compositum
と一致する。Cartesian algebra 全体の次数を compositum の次数と取り違えない。

例えば同じ √2 と −√2 の Cartesian eliminant は次数4でも、選択された theta の因子は
次数2となる。rational/zero では次数1の Q を返す。

## budget と未証明の範囲

Budget の各欄は、既存入口の fuel に対応する。
`attempts/work` は separating seed の新規試行数と F4/Sturm の段階、`coordinate` は各座標の
norm 補間・隔離、`comparison` は各 Number 比較の refinement、`primes/lift/subset/verification`
は最小因子の Zassenhaus 生産・検査、`realization` は返却 Element の実根隔離である。

有限 budget で一般入力が必ず成功するとは主張しない。部分成功を Common として返さない。
Unresolved は途中状態を保存しないため、budget を増やして再実行すると前段も再計算する。
各欄は全体の CPU/メモリ上限ではなく、個別の exact 算術・線形計算・checker の費用も
一律の一単位として数えていない。Cartesian 次数は定義次数の積になり、非minimal 定義の
不要因子は途中の F4・行列・証拠を大きくし得る。性能改善の実測は主張しない。
複素埋込み、任意の抽象数体間の全同型列挙、最大整環は対象外。

## 一次資料と独立 oracle

primitive element と元の生成元の座標を返す契約は
[SymPy primitive_element / to_number_field の公式文書](https://docs.sympy.org/latest/modules/polys/numberfields.html#sympy.polys.numberfields.subfield.primitive_element)
で確認した。選択した実埋込みを保存して共通体と両写像を返す意味は
[SageMath composite_fields の公式文書](https://doc.sagemath.org/html/en/reference/number_fields/sage/rings/number_field/number_field.html#sage.rings.number_field.number_field.NumberField_generic.composite_fields)
に対応する。production kernel は両ライブラリを呼ばない。

`tools/generate_compositum_fixtures.py` は、独立に SymPy primitive_element から共通体次数を得て、
各 `theta=a+s*b` の minimal_polynomial と、to_number_field による a,b の多項式表示を作る。
定義多項式を座標へ代入した剰余が0であること、`h_x+s*h_y=t mod m_theta`、
元の exact algebraic expression への代入等式も検査する。

native / JS / Wasm GC 各 **29/29** test が `--deny-warn` で成功。
うち独立 SymPy fixture は22組、seed 0〜5に対する123組の exact primitive maps を生成した。
実装が選んだ seed に対し、共通体次数1〜6・最小多項式の全係数・両 Element の全剰余係数を照合する。
各 fixture で Common の値付き checker、両実数埋込みの exact equality も確認した。

手書き7 test は √2/√3 の次数4、同じ/逆符号 √2 の次数2への縮小、rational/zero、
同じ値の異なる非minimal定義、∛2/√2 の次数6、全段階 budget 不足、変異証拠を扱う。
特に **同じ最小多項式・同じ剰余を持つ別共役の Field から Element を混入**する攻撃を拒否した。
元 Problem・seed・全点列の省略/順序・選択 index・比較 order・実変換・外部 Number・
返却 Field/Element の差替えも拒否する。
9種類の段階不足を Unresolved とし、検査 fuel 不足を Undecided とすることを確認した。

純粋性 gate は **157 kernel files**、generated `.mbti`、format check、fixture 再生成
byte 一致を通過。ログは `.tools/compositum-20261116/verification-milestone1.json`、
oracle 全データは同ディレクトリ `sympy-fixtures.json`。有限の検証範囲を超えた速度・
大次数の実用性・全入力の有限 budget 内成功は主張しない。

専有 branch の依存 cherry-pick は `b0aa543 -> 0d5e140`, `fe5699b -> 54d7c0a`,
`c0aedef -> 9e55ad0`。これは realvariety の既存検証済み source を読むための依存導入であり、
本成果 commit の変更とは分離している。旧 package と旧 artifact は凍結保持した。
