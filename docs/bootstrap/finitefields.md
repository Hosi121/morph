# 素数体上の多項式

`src/fppoly` は、チェック済みの `primefield.Field` を係数体とする一変数多項式を構成する。
`primefield` の正式実装 `2d7e1c0` と検証追補 `3e6b190` に依存する。
既存の `finitefield.Field` はTonelli–Shanks用の奇標数体なので、標数2を含むこの境界とは分ける。
`primefield.field` の試し割り、または `primefield.from_prime` の検査済みPrimeから体を作る。
fppoly自身は素数判定を繰り返さない。

## 正規形と多項式算術

係数は昇冪順の独自 `Chain[Binary]`。各係数を `mod p` に正規化し、末尾のゼロを除去する。
空列が一意なゼロ多項式であり、ゼロの次数・先頭係数は `None`。
`Polynomial` の構築は `polynomial(field, coefficients)` に限る。
`primefield.Field` 自体が法だけを保持する正規形なので、生成元が試し割り由来かPrime証明由来かによらず
同じ標数・係数列の多項式は構造的に等しい。

- `zero`・`one`・`constant`・`indeterminate`：基本的な多項式を構成する。
- `field_of`・`characteristic`・`coefficients`・`degree`・`leading`：正規形を読み取る。
- `add`・`subtract`・`negate`・`scale`・`multiply`：係数ごとの加減算と畳み込み。
- `divide`：長除算で `quotient` と `remainder` を返す。
- `monic`・`gcd`・`extended_gcd`：monic GCDとBézout係数を求める。
- `derivative`・`evaluate`：標数に従う形式微分とHorner評価。
- `power_mod`：独自Binaryによる二乗反復と多項式剰余。

異なる標数の混合を `FieldMismatch`、ゼロ多項式による除算・剰余を `ZeroDivisor` とする。
`power_mod` は指数0でもゼロの法を拒否する。非ゼロ定数を法とする剰余は常にゼロ。
`gcd(0,0)=0` とし、この場合のBézout係数も二つともゼロとする。
`monic(0)=0`。非ゼロGCDは先頭係数1に正規化する。

## 基盤の独立検証

2026-11-15、MoonBit v0.10.20で次を実行した。

```sh
python3 tools/audit_purity.py
tools/moon fmt --check src/fppoly
tools/moon check --deny-warn src/fppoly
tools/moon test src/fppoly --target wasm-gc
tools/moon test src/fppoly --target js
tools/moon test src/fppoly --target native
tools/moon info src/fppoly
```

最初の完成単位は4テスト。各バックエンドで成功した。

- `GF(2)` の次数3以下、`GF(3)` の次数2以下、`GF(5)` の次数1以下の全多項式を各々全対で比較：合計1,610組。
- 加減乗・商余は機械整数の係数配列で独立に計算。
  GCDオラクルはEuclidを使わず、可能なmonic除数の全列挙で求める。
- 拡張Euclidが返したBézout等式を、機械整数の多項式積・和で検算。
- 標数2/3/5/7の正規化・評価・微分、特にp冪の導関数ゼロを確認。
- 剰余冪を機械整数の反復乗算と比較。混合・ゼロ除数・定数の法も確認。

有限の全小例であり、すべての次数に対する形式証明ではない。
密な係数列を用いるため、大きな指数だけが少数現れる疎多項式には向かない。
GCD・長除算・素数体算術を独自不変データで組み立てることが目的で、機械数値実装への速度優位は主張しない。

## 決定的Berlekamp分解

`factor` は非ゼロ多項式を、先頭係数 `unit` と相異なるmonic既約因子・正の多重度に分解する。
因子は次数、続いて昇冪の係数列の辞書順に整列する。
ゼロ多項式は有限な一意分解がないため `ZeroPolynomial` で拒否し、非ゼロ定数は空の因子列を持つ。

まず `gcd(f,f')` で重複因子を分ける。導関数がゼロの場合は、指数がpの倍数の係数だけを取り出し
p乗根を作る。素数体上では係数のp乗根は係数自身であり、得た因子の多重度をp倍する。
これを再帰するため、`(x+1)^16` in `GF(2)` や `(x−1)^9` in `GF(3)` も扱う。

平方因子のない多項式では、列jを `x^(p*j) mod f` とするBerlekamp行列Qを作り、
既存の `rowreduce.solve` で `ker(Q−I)` の基底を求める。
非定数の基底元bがあれば、`a=0,...,p−1` を決まった順序で列挙し、
`gcd(f,b−a)` が真の因子になるところで分割する。
ランダムな分裂候補、外部ライブラリ、数値近似は使わない。
`berlekamp_basis` はこの核の基底を独立した入口として公開する。

## 既約性と因数分解の証拠

`irreducibility(f)` は**monic・正次数の既約多項式**にだけ証拠を返す。
ゼロ・定数・非monic・可約な入力は `Ok(None)`。
`IrreducibilityCertificate` は検査可能な公開recordで、次を保持する。

- `frobenius`：`x^(p^i) mod f` の列、`i=1,...,n`、`n=degree(f)`。
- `coprime`：`i=1,...,floor(n/2)` に対する `gcd(f,x^(p^i)−x)=1` のBézout等式。

`check_irreducible(f, certificate)` は列の長さ・体・各Frobenius遷移・最後にxへ戻ることを再計算し、
互いに素の各等式を直接の多項式積和で検査する。因数分解器・GCD・拡張Euclidは呼ばない。
次数nの素因数分解も信用せず、半次数まで**すべてのi**を検査する。
可約な次数nの多項式は半次数以下の既約因子を持つため、この範囲の互いに素の条件がそれを排除する。

`check_bezout` は与えたBézout等式そのものを検査する入口。
それだけで一般のGCDの最大性まで証明する入口ではない。
既約性の検査では右辺が1であることも要求するため、互いに素の証拠として使える。

`check_factorization(f, result, certificates)` は、各因子と一対一に対応する既約性証拠、
正の多重度、monic条件、整列と相異性、正規化した非ゼロunit、最後の積の一致を確認する。
証拠の生産者やBerlekampの分裂経路は信用しない。
どちらの証拠も別の多項式や体へ流用する際は、再度checkerを通す必要がある。

## 分解の検証と限界

上のコマンドで、追加後は17テストがWasm GC・JS・nativeすべて成功した。
基盤の4テストに加え、以下を含む。

- monic多項式の全小例：`GF(2)` の次数1〜6、`GF(3)` の次数1〜4、`GF(5)` の次数1〜3、合計401個。
  独立した機械整数の**全monic除数の試行**による分解と、因子・多重度・既約判定を比較した。
- すべての基底元がFrobeniusで固定されることと、核の次元が相異なる既約因子数に等しいこと。
- 非monicな定数倍、重複因子、導関数ゼロ、標数2・3・5での入れ子になったp冪。
- 証拠列の切断・延長・値改変・別の体の混入、Bézout係数の偽造、因子の省略・並べ替え・多重度改変・unit改変。
- Pythonの独立な試行除算で既約性を確認した因子を積み上げた、標数2/3/5/7の10 fixture。
  次数16まで、複数の非線形因子、非monic、導関数ゼロ、多重度16・9・5を含む。

fixtureの再生成：

```sh
python3 tools/generate_fppoly.py
tools/moon fmt src/fppoly
```

追加のPython依存はない。決定的な分裂ではp個のスカラーを列挙し、
Berlekamp行列を密に構成するため、大きな標数・次数への高速実装ではない。
返却する証拠とcheckerも通常の実装として有限例で検証したもので、形式検証済みcheckerという主張はしない。
