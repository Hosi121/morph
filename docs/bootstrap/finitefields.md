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
