# 固定した複素数体で計算する

[ハンドブック](../../HANDBOOK.md) / [厳密代数の計算経路](algebraic-solving.md)

同じ代数的数を使って計算を繰り返すなら、各結果を別々の根として表すほかに、
一つの有限次元の体へ置く方法がある。
[complexfield](../../src/complexfield) は検査済みの実数体 `K=QQ(α)` に `i` を加え、
[complexprimitive](../../src/complexprimitive) はその体を一つの生成元の剰余表示へ写す。

## 二つの座標からなる体

`complexfield.field(k)` の入力は、選択した実埋込みを持つ `numberfield.Field`。
`K` が次数 `d` なら、`K(i)` の次数は `2d` で、基底は

\[
1,\alpha,\ldots,\alpha^{d-1},\quad
i,i\alpha,\ldots,i\alpha^{d-1}
\]

となる。`element(f,a,b)` は `a+i b` を作り、両座標が同じ `K` に属することを確認する。
`real_part`、`imaginary_part`、`real_field` で元の表現へ戻れる。
体と元の内部フィールドは非公開であり、異なる実共役や異なる一根区間を持つ context は混ぜない。

ここでいう「実数体」は、選択した埋込みで `K⊂R` であるという意味である。
すべての共役が実数である必要はない。たとえば `QQ(∛2)` も入力にできる。
`i∉K` なので `x²+1` は `K` 上既約となり、二つの座標は一意に定まる。

加減乗算は `K` の剰余演算を再利用する。逆元は

\[
(a+i b)^{-1}=\frac{a-i b}{a^2+b^2}
\]

で求める。非零元では分母が零にならず、零の逆元と零除算は `Ok(None)` を返す。
`conjugate` は `a-i b`、`imaginary_unit` は `i` を返す。
これらの演算は resultant や根隔離を繰り返さない。
基底の長さは固定されるが、有理係数のビット長は増え得る。

## 体の不変量と元の最小多項式

`trace` と `norm` は、元が属する **ambient field `K(i)` から `QQ` への**不変量である。

\[
\operatorname{Tr}_{K(i)/\mathbf Q}(a+i b)=2\operatorname{Tr}_{K/\mathbf Q}(a),
\qquad
N_{K(i)/\mathbf Q}(a+i b)=N_{K/\mathbf Q}(a^2+b^2).
\]

`relative_trace` と `relative_norm` は `K` の元として `2a` と `a²+b²` を返す。
乗法行列は、実数体での乗法行列 `M_a,M_b` から

\[
M_{a+i b}=\begin{pmatrix}M_a&-M_b\\M_b&M_a\end{pmatrix}
\]

を組み立てる。`check_trace` は対角和、`check_norm` は行列式で別渡し結果を検査する。

一方、`minimal_polynomial(z)` は元 `z` 自身の最小多項式を求め、その次数は `[QQ(z):QQ]` となる。
`1,z,z²,...` の最初の有理線形従属を使い、checker は消滅に加えて先行する冪の rank を確認する。
消えるだけの高次数多項式では最小性の証拠にならない。

| 元と ambient field | 元の最小多項式 | ambient 次数 | `trace` | `norm` |
| --- | --- | ---: | ---: | ---: |
| `√2+i ∈ QQ(√2,i)` | `t⁴−2t²+9` | 4 | 0 | 9 |
| `√2 ∈ QQ(√2,i)` | `t²−2` | 4 | 0 | 4 |
| `ζ₃=(-1+i√3)/2 ∈ QQ(√3,i)` | `t²+t+1` | 4 | −2 | 1 |

`ζ₃` の最小多項式から得る `QQ(ζ₃)/QQ` の trace は `−1` だが、
この API の ambient trace は有理数 `−2` である。
一般に `r=[K(i):QQ(z)]` とすると、ambient trace は最小体の trace の `r` 倍、
ambient norm は最小体の norm の `r` 乗になる。

## 一つの生成元へ写す

`complexprimitive.prepare(f)` は `θ=α+i` を選び、
`K(i) ≅ QQ[t]/(mθ)` という検査済みの表示を作る。
`basis_matrix` の列は元の基底で表した `1,θ,...,θ^(2d−1)`。
その逆行列で任意の元を `θ` の多項式へ変換する。

`to_polynomial(rep,z)` は次数 `2d` 未満の正規剰余と変換証拠を返す。
`from_polynomial(rep,h)` は一変数多項式を `mθ` で簡約し、元の `K(i)` へ戻す。
たとえば `α=√2` では

\[
m_\theta(t)=t^4-2t^2+9,\qquad
\alpha=\frac{5\theta-\theta^3}{6},\qquad
i=\frac{\theta+\theta^3}{6}.
\]

したがって `real_generator_image` は `(5t−t³)/6`、
`imaginary_unit_image` は `(t+t³)/6` となる。
同じ商体では `t⁴=2t²−9` から `t⁸=45−28t²` と簡約できる。

証拠は元の field context、固定した `α+i`、真の最小多項式と次数、
基底行列と逆行列の両積、`α` と `i` の像を検査する。
`check_conversion_for(rep,z,h,proof)` は呼び出し元の `z` と返された `h` も束縛し、
`h(θ)=z` を元の体で確認する。法の倍数を足した同値な多項式も、正規出力としては受理しない。

## 明示的に作れる分解体

正の実数 `α=⁴√2` を選ぶと、`QQ(α,i)` は `z⁴−2` の分解体になる。
四つの根 `α,−α,iα,−iα` を含み、逆にそれらから `i=(iα)/α` を取り出せるからである。
ambient 次数は `8`。同じ固定生成元 `θ=α+i` の最小多項式は

\[
t^8+4t^6+2t^4+28t^2+1
\]

であり、単一の剰余表示にも移せる。
これは指定した例の明示的な構成である。
任意の複素代数的数の共通体探索、一般多項式の分解体の自動構成、Galois 群計算は未実装である。
実装の根拠と独立検証は[研究記録](../research/complex-fields-20261117.md)を参照。
