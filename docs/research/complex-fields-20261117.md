# K(i) の固定基底と絶対 primitive element

[ドキュメント](../README.md) / [研究・探索記録](README.md) / [利用ガイド](../handbook/complex-fields.md)

検査済みの実数体 `K=QQ(α)` を再利用し、複素演算を固定次元の厳密線形代数へ落とす。
`complexfield` が `K(i)` の座標演算を、`complexprimitive` が
`θ=α+i` による一生成元表示と両方向の写像を担当する。
既存の `numberfield`、有理行列、線形方程式と行簡約を使い、汎用消去エンジンは追加しない。

## 固定する対象

入力の `numberfield.Field` は、既約な最小多項式と選択実根の証拠を検査して作られた体である。
この実埋込みにより `K⊂R` なので `i∉K`、従って `[K(i):QQ]=2d`。
元 `a+i b` の座標を

\[
B=(1,\alpha,\ldots,\alpha^{d-1},i,i\alpha,\ldots,i\alpha^{d-1})
\]

に固定する。選択実根を持つことと、すべての共役が実数であることは別である。
たとえば `α=∛2` では非実共役を持つが、この構成を使える。

体の同一性には最小多項式と選択根の一根区間を含める。
同じ抽象体の別共役や同じ値の別区間も暗黙には同一視しない。
`Field`、`Element`、primitive `Representation` の内部フィールドを非公開にし、
公開 constructor と checker がこの境界を保つ。

## 演算と検査の分離

乗算は `(a+i b)(c+i e)=(ac−be)+i(ae+bc)`、逆元は `(a−i b)/(a²+b²)`。
零除算は `Ok(None)`、異なる context は零判定より先に `DifferentField` となる。
逆元証拠は入力、返却値、実数体における分母逆元の Bézout 証拠を持つ。
`check_inverse_result` は実際の両引数との一致、context、Bézout 恒等式、
元の体での積が `1` であることを確認する。

| 量 | 生産側 | 検査側 |
| --- | --- | --- |
| relative trace / norm | `2a` / `a²+b²` を `K` で計算 | 返却値を通常の体演算で照合可能 |
| ambient trace | `2 Tr_K(a)` | ブロック乗法行列の対角和 |
| ambient norm | `N_K(a²+b²)` | ブロック乗法行列の行列式 |
| 元の最小多項式 | 冪列の最初の線形従属を `linear.solve` で解く | monic・消滅・次数上限・先行冪の `rref` rank |

ブロック行列は `[[M_a,−M_b],[M_b,M_a]]` を実数体の乗法行列から組み立てる。
trace と norm の checker はこの行列を使い、上記の短い公式を再実行するだけにはしない。

最小次数を `k` とすると、checker は `1,z,...,z^(k−1)` の rank が `k` であることを確認する。
これは次数 `k` 未満の非零消滅多項式を排除する。
単なる消滅条件や ambient 次数以下という条件だけでは不十分であり、
たとえば `z=√2` に対する `(t²−2)(t−1)` は ambient 次数 `4` 未満でも拒否する。

ambient field と `QQ(z)` の次数を区別することも契約に含める。
`ζ₃=(-1+i√3)/2` の最小多項式は `t²+t+1` だが、`QQ(√3,i)` の次数は `4`。
この field の API が返す trace は `−2`、norm は `1` である。
最小多項式の根の和 `−1` をそのまま ambient trace として返してはならない。

## なぜ固定した α+i でよいか

`p∈QQ[t]` を `α` の monic な既約多項式、次数を `d` とする。
`i∉K` から `[K(i):K]=2`、次数の塔から `[K(i):QQ(i)]=d`。
従って `p` は `QQ(i)` 上でも既約であり、変数を平行移動した

\[
p(t-i),\qquad p(t+i)
\]

も `QQ(i)` 上既約である。両者の `t^(d−1)` 係数は `2di` だけ異なるので一致しない。
積 `q(t)=p(t−i)p(t+i)` は複素共役で不変であり、`QQ[t]` に属する。
`QQ(i)` 上の二つの既約因子は共役によって交換されるため、
`QQ` 上の因子は片方だけを含めず、`q` は `QQ` 上既約となる。
`q(α+i)=0`、次数は `2d` なので `QQ(α+i)=K(i)` を得る。

この議論は固定生成元を選ぶ数学的根拠である。
実装はこの一般論を仮定して未検査の商体を作らない。
`prepare` は元の体で `θ=α+i` の真の最小多項式を求め、次数が実際に `2d` であることを検査する。
この導出や MoonBit 実装全体を定理証明器で証明したとは主張しない。

## 両表示を結ぶ行列と証拠

行列 `S` の第 `j` 列を、`B` で表した `θ^j` とする。
`S⁻¹` は既存の `linear.inverse` で求める。
元の座標 `v` に `S⁻¹` を掛ければ、`QQ[t]/(mθ)` における一意な次数 `2d` 未満の代表が得られる。

primitive の `check(source,proof)` は、外部から渡された source と証拠の source、
指定どおりの `θ=α+i`、最小多項式と次数、すべての冪列、
`SS⁻¹=S⁻¹S=I`、`α` と `i` の像を元の体で再評価して検査する。
`check_result` は別渡し `Representation` も束縛する。
真の最小多項式を共有する別の `α−i` の表示も、固定生成元との不一致で拒否する。

`check_conversion_for(rep,input,h,proof)` は表示全体、実際の入力、実際の出力を束縛する。
正規性を確認してから `h(θ)=input` を元の体で評価するため、
正しい証拠に別の元や別の返却多項式を組み合わせても受理しない。
`from_polynomial` は高次数入力を簡約して読めるが、
`to_polynomial` の結果に法の倍数を足した、正規形でない多項式は変換証拠の出力として拒否する。

## 具体的な剰余表示

`α=√2` なら `θ=α+i` に対して

\[
m_\theta=t^4-2t^2+9,\qquad
\alpha\longmapsto\frac{5t-t^3}{6},\qquad
i\longmapsto\frac{t+t^3}{6}.
\]

両式を足すと `t` になり、それぞれを `θ` に代入すると元の `α` と `i` に戻る。
また `t⁴=2t²−9` なので

\[
t^8=(2t^2-9)^2\equiv45-28t^2\pmod{m_\theta}.
\]

元の座標では `θ⁸=17−56i√2`。この元の最小多項式は `t²−34t+6561` であり、
ambient trace は `68`、ambient norm は `6561²` となる。
剰余次数の上限が固定されても、元の最小次数がその上限に等しいとは限らない。

`α=⁴√2` の場合、`QQ(α,i)` は `z⁴−2` の根 `±α,±iα` をすべて含む。
逆に根から `α` と `i=(iα)/α` が生成されるので、この次数 `8` の体は同多項式の分解体である。
その primitive modulus は `t⁸+4t⁶+2t⁴+28t²+1`。
これは明示的に選んだ入力の構成であり、一般の分解体探索を実装したことにはならない。

## 独立検証と残る範囲

[K(i) の独立 oracle](complexfield-oracle-20261117.md) は、SymPy の厳密代数式と
Python `Fraction` の独立な座標演算・行列式を用いて、演算、逆元、行列、最小多項式と不変量を照合する。
[primitive 座標の独立 oracle](complexprimitive-oracle-20261117.md) は、
絶対最小多項式、生成元の像と座標変換を照合する。
公開証拠には source、返却値、context、行列、最小多項式、像、正規性を改変する検査を加える。
有限の外部事例と実行時の証拠検査は役割が異なり、どちらも実装全体の形式証明には代わらない。

通常の体演算に resultant と根隔離を使わず、基底の長さを維持できることが今回の表現上の到達点である。
比較計測は次節の入力と環境に限る。
係数のビット長、線形計算の中間式、実行時間とメモリは無制限に増え得る。
任意の複素代数的入力からの自動 compositum、一般の分解体構成、Galois 群計算、
最大整環・整数基底、`complexalgebraic.Number` への変換は、この二つの package の範囲外である。

## 同じ入力・最終検査での比較

一般の二座標演算と固定基底演算を、同じ native release artifact 内で比較した。
どちらも `√2` の根証拠と実数体の準備、反復平方、数としての最終等号検査を含む。
一般経路は各乗算の演算証拠を検査し、固定基底経路は既知の厳密値を体内で照合した後、
`numberfield.realize` の両座標と選択埋込みの証拠を検査する。
測る処理の違いは、この表現と検査経路の違いを含む。乗算関数だけの比較ではない。

Linux/WSL2、Core Ultra 7 255H、CPU 4 に固定し、各入力の同じ artifact を ABBA 順で3巡、各方式6回実行した。
MoonBit は `moonc v0.10.20+65efd5b93`、native release、GCC 13.3。
コンパイルは除外し、プロセス起動は含む。

| 入力 | 二座標の一般演算 | K(i) の固定基底 |
| --- | ---: | ---: |
| `(√2+i)² = 1+2i√2` | 6/6完了、中央値1.752ms | 6/6完了、中央値1.109ms |
| `(√2+i)⁸ = 17−56i√2` | 6/6を各5秒で打切り | 6/6完了、中央値1.168ms |

小さい例にはプロセス起動と測定の揺れも占めるため、一般的な速度比を主張しない。
八乗の二座標経路には完了時間がないので、倍率は計算しない。
固定基底では各平方後も二つの `K` の剰余に収まる一方、一般の座標演算では定義多項式と証拠が増え得る。
今回の八乗は、その表現の選択が反復計算の費用へ大きく影響する具体例となった。

ソース commit、artifact hash、全試行、打切りを
[平方の生データ](../measurements/complex-field-square-native-20261117.json)と
[八乗の生データ](../measurements/complex-field-native-20261117.json)に保存した。
両入力の artifact は別の commit で生成しており、入力をまたいだ絶対時間の比較には使わない。

```sh
tools/measure --cpu 4 tools/moon build src/cmd/complexfieldbench --target native --release
tools/measure --cpu 4 python3 tools/compare_complex_roots.py \
  --case field-square --abba-repetitions 3 --timeout-seconds 5 \
  --artifact _build/native/release/build/cmd/complexfieldbench/complexfieldbench.exe \
  --output .tools/complex-field-square.json
```

八乗は `--case field-power` で再現する。
