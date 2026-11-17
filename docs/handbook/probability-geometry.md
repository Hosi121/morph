# 確率と情報幾何

[ハンドブック](../../HANDBOOK.md) / [アルゴリズム一覧](../ALGORITHMS.md#probability-geometry)

## 有限分布を正確に扱う

[probability](../../src/probability) は、順序を固定した有限標本空間上の有理数の確率ベクトルを扱う。
`Distribution` の構築時に、非空・非負・総和1を検査する。
境界のゼロ確率は許し、情報幾何で必要な全成分の正性は `is_interior` で別に調べる。
ラベルの同一性や並べ替えを暗黙に推測しないため、同じ長さでも標本の順序は呼び出し側が揃える。

| 操作 | 意味と境界 |
| --- | --- |
| `distribution` / `normalize` | 総和1の検査 / 非負の重みの正規化。ゼロ測度は拒否 |
| `expectation` / `variance` / `covariance` | 分布と同じ長さの観測値から、有理数で正確に計算 |
| `event_probability` / `condition` | Bool列で事象を指定。零確率の条件付けは `None` |
| `bayes` | 非負の尤度で再重み付け。証拠の確率がゼロなら `None` |
| `mixture` / `product` | 混合と独立積。積では右側の標本番号が先に変化 |
| `pushforward` | 各標本の行き先を指定し、周辺化・粗視化を行う |
| `total_variation` | 同じ順序の二分布についてL1差の半分を返す |

条件付けは元の標本空間を保ち、事象外の成分をゼロにする。
`pushforward` は、元の確率がゼロであっても不正な行き先を拒否する。
大きさ・添字は `Nat`、確率と観測値は `Rational` とし、確率計算のためにPeano数へ展開しない。

## 検証と範囲

`distribution_wbtest.mbt` は3標本の整数重みを列挙し、分母を払った独立した整数計算と期待値・分散・条件付け・Bayes更新を照合する。
二値分布の独立積、両側の周辺分布、全変動距離、混合も照合する。
テストのホスト整数・配列は参照計算に限定し、計算核は不変ADTと再帰のみで実装する。

これは有限の有理分布の計算であり、乱数生成器や連続分布の積分器は含まない。
Fisher計量、接続、曲率は別の層として追加する。
対数・指数関数の値が必要なエントロピーやKL距離は、有理数の四則演算だけで一般に閉じない。
その値の表現と局所的な微分幾何の計算を分けて設計する。

定義の参照先は [Nielsen, An elementary introduction to information geometry](https://arxiv.org/abs/1808.08271) と
[Pistone, Information Geometry of the Probability Simplex](https://arxiv.org/abs/1911.01876)。
後続実装で扱うFisher計量や接続の規約は、この章に追記する。
