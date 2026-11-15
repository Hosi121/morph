# 2冪次数の円分体

`src/cyclotomic` は既存の `exact.Rational` と `polynomial.Polynomial`
から、2冪次数 `N` の `QQ(ζ_N)` を構成する。浮動小数点、近似根、組み込みの複素数を使わない。

## 正規形とAPI

`field(N)` は正の2冪だけを受理する。法多項式は次の通り。

| N | Φ_N(x) | 正規形 | generator |
| --- | --- | --- | --- |
| 1 | x − 1 | 有理定数 | 1 |
| 2 | x + 1 | 有理定数 | −1 |
| 4以上の2冪 | x^(N/2) + 1 | 次数N/2未満の有理係数多項式 | xの剰余類 |

`Field` と `Element` のコンストラクターは非公開。`element(field, polynomial)`
は既存の多項式除算で剰余化する。疎多項式の係数は既約有理数、項の順序と同類項も既存APIが正規化するため、
同じ体に属する元の構造的 `Eq` がそのまま厳密な等値判定になる。

- `rational`・`zero`・`one`・`generator`：元を構成する。
- `add`・`subtract`・`multiply`・`divide`：体の四則演算。
- `inverse`：法多項式との拡張Euclidにより逆元を得る。
- `power`：独自 `Binary` による非負整数冪。`0^0 = 1` とする。
- `conjugate`：`ζ_N` を `ζ_N^(N−1)` に置換し、有理係数を固定する。
- `representative`・`field_of`・`order`・`degree`・`defining_polynomial`：読み取り。

演算結果は `Result[..., CyclotomicError]`。異なる `Field` の混合を `FieldMismatch`、
ゼロ逆元を `ZeroDivisor` とする。多変数・0変数の多項式入力は既存の `DimensionMismatch` を包んで返す。
`InternalInvariant` は既存の単一除数による多項式除算が単一の商を返すという内部不変条件の防御的検査。
有効な公開コンストラクターから到達することは想定しない。

`N=1` と `N=2` はどちらも有理数体と同型だが、異なる根と法を持つ**別の提示**として扱う。
同じ有理数を埋め込んでもこの二つの `Field` の元は混合できない。
他の次数間の包含・自動昇格・埋め込みはまだ実装していない。

## 検証

2026-11-15、MoonBit v0.10.20で次を確認した。

```sh
python3 tools/audit_purity.py
tools/moon fmt --check src/cyclotomic
tools/moon check --deny-warn src/cyclotomic
tools/moon test src/cyclotomic --target wasm-gc
tools/moon test src/cyclotomic --target js
tools/moon test src/cyclotomic --target native
tools/moon info src/cyclotomic
```

各バックエンドで10テストが通る。確認範囲は以下。

- 0から33の次数に対する受理・拒否、`N=1/2` の特例、混合・ゼロ除算・次元不一致。
- `N=1,2,4,8,16,32` の生成元の厳密な位数、法多項式がゼロになること、高次数単項式の正規形。
- `N=4` の2係数を `−1,0,1` とした全81組の積を独立したGaussian有理数の組演算と比較。
- Python標準の `fractions.Fraction` と密な係数配列で生成した20組の積・逆元・共役。
  逆元のオラクルは有理数の乗算行列をGauss–Jordanで解くため、核の拡張Euclidとは算法が異なる。
- 分配則・除算の往復・共役の加法性と乗法性・共役の二重適用。

fixtureの再生成は次で行う。

```sh
python3 tools/generate_cyclotomic.py
tools/moon fmt src/cyclotomic
```

生成器は固定seed `20261115`、追加依存なし。fixtureを検証済みの有限例として扱い、
すべての入力に対する形式証明や性能向上を主張しない。
疎多項式の汎用除算とPeano指数を使うので、大きな次数への高速な数値FFTの代替は目的としていない。
