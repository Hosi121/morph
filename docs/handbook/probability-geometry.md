# 確率と情報幾何

[ハンドブック](../../HANDBOOK.md) / [アルゴリズム一覧](../ALGORITHMS.md#probability-geometry)

実行例は `tools/moon run src/cmd/information`。出力全体は[ツアー](../INFORMATION_TOUR.txt)に保存し、
`tools/check_information_tour.py` で実行結果との一致を検査する。

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

## 確率核とBayesによる逆向きの計算

[channel.mbt](../../src/probability/channel.mbt) の `Channel` は、各入力標本に出力分布を対応させる。
入力側と出力側の大きさが異なる行列も扱い、分布の向きは行ベクトル `q=pK` とする。
`compose_channels(first,second)` は時間順に合成し、`first` の後に `second` を適用する。
同じ状態空間上の時間発展・累乗は、正方行列を検査する別の `markov.Kernel` が担当する。

`posterior` は、固定した事前分布と観測された出力から入力側の事後分布を返す。
`bayesian_inverse` は全出力に対する事後分布を並べ、逆向きの確率核を構築する。
これは固定した事前分布に依存するBayesの逆であり、通常の行列逆ではない。
確率0の出力では条件付き分布が一意に決まらないため、逆核全体の構築は `None` とする。

`infogeom.through` はパラメータに依存しない確率核を確率・勾配・Hessianへ同時に作用させる。
`through_family` は同じ操作を多項式モデルへ適用し、恒等的な正規化を再検査する。
添字はパラメータの座標を保ち、標本空間だけを変える。
粗視化後に確率0の標本があれば、開単体の `Model` は構築できない。

テストでは、粗視化によるFisher情報の損失を有理点と接ベクトルの有限列挙で確認する。
これは一般のデータ処理不等式の形式証明ではない。
同じ情報を一定の比率で二標本に分けたモデルでは、粗視化前後のFisher計量が一致し、
固定した事前分布で作ったBayes逆核が確率のjetも再構成する例を検査する。

## 確率の微分値から情報幾何へ

[infogeom](../../src/infogeom/model.mbt) は、各標本の確率 `p` と1階・2階の偏微分から、点での確率モデルを構築する。
型は値、勾配、Hessianをまとめた `SampleJet` と、検査済みの `Model` に分かれる。
正の確率・総和1・全微分の総和0・次元・Hessianの対称性を検査する。
これらは局所データの条件であり、呼び出し側の大域的な密度関数や座標変換の証明を意味しない。

対数を評価せず、`∂i log p = (∂i p)/p` を使う。
`a_i = ∂i p`、`b_ij = ∂i∂j p` とおくと、実装する量は次の有限和になる。

```text
g_ij       = Σ a_i a_j / p
T_ijk      = Σ a_i a_j a_k / p²
Γ^(α)_ij,k = Σ b_ij a_k / p − (1+α)/2 T_ijk
∂k g_ij    = Σ (b_ki a_j + a_i b_kj)/p − T_ijk
```

`alpha=+1` が指数接続、`alpha=-1` が混合接続、`alpha=0` がLevi-Civita接続。
接続係数は最後の添字を下げた形で返す。
`Tensor` のslice `i` は行 `j`・列 `k` の行列で、`metric_first` のみ外側を微分添字 `k` とする。
接続係数はテンソルではないため、座標を変えるときには確率の2階微分も必要になる。

Fisher行列の特異性は、正の確率とは別の条件である。
冗長なパラメータを含むモデルも構築し、`natural_gradient` は `g v = dL` が一意に解ける場合だけ返す。
特異な場合は `SingularInformation` とし、任意の擬似逆行列を選ばない。
自然勾配は点でのベクトルであり、有限幅の更新後にもパラメータ領域に残ることは保証しない。

## Amari–Chentsovテンソルを使う

`infogeom.amari_chentsov(model)` は、scoreの3次モーメント
`T_ijk = E[score_i score_j score_k]` を返す。
従来の `cubic` は同じ量を返す互換名として残す。
規約は `T = Γ^(-1) − Γ^(+1)` で、差に1/2を含めない。
対称な共変3階テンソルであり、接続係数とは座標変換の規則が異なる。
[Nielsenの定義と期待α接続](https://arxiv.org/abs/1808.08271)に従う。

[statgeometry.amari_chentsov](../../src/statgeometry/amari_chentsov.mbt) は、非退化なFisher計量と組み合わせ、
検査済みの `AmariChentsov` を構築する。

| API | 返す量 |
| --- | --- |
| `covariant()` | `T_ijk`、成分の軸順は `[i,j,k]` |
| `difference()` | `K^k_ij = g^(kl) T_ijl`、最後の添字を上げた形 |
| `contravariant()` | 全添字を上げた `T^(ijk)` |
| `evaluate(u,v,w)` | 接ベクトルに作用した有理数 `T(u,v,w)` |
| `product(u,v)` | `g(K(u,v),w) = T(u,v,w)` を満たす接ベクトル |
| `trace()` | 共変ベクトル `tau_i = Σjk g^(jk) T_ijk` |
| `norm_squared()` | scalar `Σijk T_ijk T^(ijk)` |

`Γ^(α) = Γ^(0) − α K/2` なので、双対接続の差を接ベクトルへ作用させられる。
`product` は対称な双線形演算だが、一般に結合法則を仮定しない。
たとえば標準Gaussianの自然座標 `(X, X²)` で `u=(1,0), v=(0,1)` とすると、
`K(u,u)=v, K(u,v)=2u, K(v,v)=4v`。
したがって `K(K(u,u),v)=4v` と `K(u,K(u,v))=2v` は異なる。
接ベクトルは同じ座標系の成分を渡す。APIは次元を検査するが、座標系の同一性を型で表さない。
計量の逆行列と添字上げを構築時に共有し、ノルムはrank 6のテンソル積を展開せず計算する。
特異なFisher行列は `Metric(SingularMetric)` とし、元の共変テンソルだけなら引き続き取得できる。
ベクトルの次元違反は拒否し、0次元ではノルム0・trace空列となる。

`pullback_amari_chentsov(model,J)` は長方形Jacobianによる共変テンソルの引き戻し。
可逆な座標変換ではノルムの二乗は不変、traceは共変ベクトルとして変換する。
固定比率で標本を分割する十分なMarkov埋込みについても、Fisher計量と3次テンソルの一致を検査している。
これは一般の粗視化に対する3次テンソルの単調性や、Chentsovの一意性定理の実装証明ではない。

Gaussianでは `gaussian.information(source)` から `fisher()` と `amari_chentsov()` を取得できる。
この経路は2・3次cumulantまでで止め、4次cumulantを必要としない。
統計量が2次式なので、3次cumulantを得るために元のGaussianの最大6次のraw momentは計算する。
`statgeometry.gaussian_amari_chentsov(source)` は同じ計量とテンソルから上記の演算を提供する。
自然座標の統計量は `X_i`、続いて `X_i X_j (i≤j)` の順。
1変量Gaussianの族では `norm_squared() = 14` を位置・scaleの異なる有理点で確認する。

[独立検証の記録](../research/amari-chentsov-independent-20261118.md)では、Gaussianのlog-partitionを直接微分した値と、
非自明な有限多項式モデルの一般α接続・曲率を、compiled MoonBitの全成分と照合する。
通常の検査は保存済み参照値とfixtureの一致を確かめ、SymPyによる数式の再導出とは区別する。

### Hessian由来の曲率を使う

[Nielsen §3.8](https://arxiv.org/abs/1808.08271)のHessian自然座標では、
`g = ∂²F, T = ∂³F` となり、接続行列は `Γ_i^(α) = (1−α) K_i/2`。
ここで `K_i` は `difference()[i,j,r]` を行 `r`・列 `j` の行列にしたもの。
双対接続の平坦性から `∂k K_l − ∂l K_k = −[K_k,K_l]` なので、
このリポジトリの曲率規約では `R^(α)_kl = (α²−1)[K_k,K_l]/4` と導ける。
Levi–Civitaのスカラー曲率は `S = (||T||² − ||trace(T)||²)/4` に縮約できる。
traceは共変ベクトルなので、そのノルムは逆計量で縮約する。
たとえば標準Gaussianでは `||T||²=14, ||trace(T)||²=18` から `S=−1` となる。

[HessianPoint](../../src/statgeometry/hessian.mbt) はこの構造を保持し、4次cumulantや計量2-jetを経由しない経路を提供する。
`exponential_hessian(family)` は `infogeom.ExponentialFamily`、`gaussian_hessian(info)` は `gaussian.Information` から構成する。
`curvature(alpha)` は作用素を返し、scalar・Ricciとベクトルへの作用には4階テンソルを展開しない。
座標成分が必要なら `riemann()`・`lowered_riemann()` を明示的に呼ぶ。
接ベクトルと共変ベクトルには[点・座標も保持する型](structure-modeling.md#接空間と双対空間を混同しない)を用意する。
一般の有限多項式モデルにはHessian・双対平坦という条件を仮定できない。
汎用の点の `(g,T)` をこの型へ変換する入口を設けず、構築過程を根拠に計算経路を選ぶ。

### 研究用の参照計算と次の検証課題

現行の情報幾何APIは、有理点のFisher計量・Amari–Chentsovテンソル・曲率を厳密に調べる入口になる。
小さなモデルで予想への反例を探す、座標変換の整合性を確かめる、別実装の検証用参照値を作る、という用途が候補になる。
対象モデルや規約を合わせた他ソフトとの照合は別途必要で、既存の独立fixture検証と同一視しない。

[Geomstatsの情報幾何モジュールの論文](https://arxiv.org/abs/2211.11643)は、分布族上の幾何計算と統計・学習への利用を扱う。
[Giacopelli・De Gaetanoの研究](https://arxiv.org/abs/2401.12270)では、2次元分布族の曲率・平坦性の条件を計算ツールも使って調べている。
これらの先行研究があるため、既知のHessian公式をMoonBitで実装したことだけで、本プロジェクトの研究上の新規性が示されたとは扱わない。

次の具体的な候補は、2パラメータ・4標本の特定の多項式確率モデルで、
確率が正かつFisher計量が非退化な領域のスカラー曲率の符号を、検査可能な証拠付きで分類すること。
点での照合に加え、パラメータに依存する曲率の有理式を生成し、分母の条件を保って多項式の符号判定・CADへ渡す接続実装が必要になる。
この接続と領域全体の分類は未実装で、有限個の点の成功を領域全体の証明として扱わない。
研究成果としての評価には、選んだモデル族の先行研究との比較や、計算・検査に何を新しく加えたかの確認が必要になる。

## 多項式モデルから微分を生成する

[polynomial.mbt](../../src/infogeom/polynomial.mbt) は、既存の疎多項式と記号微分を再利用する。
`family` は各標本の確率を表す多項式を受け取り、変数の数を揃え、総和が多項式として恒等的に1であることを検査する。
ある一点で総和が1になるだけの入力は受け付けない。
1・2・3階の偏微分を一度生成して保持し、`at` で有理点の `Model` とFisher行列の2階微分まで評価する。

正性は各評価点で検査する。多項式の連続性により、その点が正なら十分小さな近傍でも正になるが、
実装はパラメータ領域全体での正性を証明したり、近傍の半径を生成したりはしない。
`metric_second` は外側の添字を `k,l`、行列の添字を `i,j` とする `∂k∂l g_ij` を返す。
これを一般の計量jetに渡せば曲率計算へつながる。

## 指数型分布族の自然座標

[exponential_point](../../src/infogeom/exponential.mbt) は、正の基準分布と十分統計量から
`p_theta(x) ∝ base(x) exp(Σ theta_i statistic_i(x))` の `theta=0` における3-jetを生成する。
十分統計量の表は、標本を行、パラメータを列とする。
ここでは指数・対数の値を評価せず、統計量の中心化と有理数の有限和で微分を生成する。
任意のパラメータ値で密度を評価するAPIとは区別する。

自然座標ではFisher計量は十分統計量の共分散、cubicは3次中心モーメントとなる。
`exponential_family(base, statistics)` は、この生成元と2・3次cumulantを保持する。
Hessian経路ではそのまま利用し、一般の確率jetが必要なときだけ `family.point()` で展開する。
指数接続 `alpha=+1` の係数は0になる。
`ModelPoint` は確率の3-jetを保持する共通型で、手入力では3階微分の形状・置換対称性・総和0を検査する。
多項式経路もこの型を生成し、従来名 `PolynomialPoint` は型aliasとして残す。
これにより、計量微分と曲率の処理をモデルの作り方ごとに重複させない。

Bernoulliの自然座標では、2・3・4次cumulantに対応する計量・1階・2階計量微分を閉形式と照合する。
確率単体の自然座標でも断面曲率 `1/4` を確認し、混合座標の結果と一致する。
統計量が冗長な場合の特異性は、他の `Model` と同じ規則で扱う。

## Fisher計量から曲率まで

[statgeometry](../../src/statgeometry/geometry.mbt) は、確率3-jetのFisher計量とその2階までの微分を
[riemann](../../src/riemann) の検査済み `MetricJet` に渡す。
そこからLevi-Civita接続、Riemann曲率、Ricci曲率、スカラー曲率を計算する。
確率の3階微分まで必要になるので、Fisher行列の値だけから曲率を推測しない。

曲率の規約は `R^i_jkl = ∂k Γ^i_lj − ∂l Γ^i_kj + Γ^i_km Γ^m_lj − Γ^i_lm Γ^m_kj`、
`Ric_jl = Σi R^i_jil` とする。`riemann` は出力添字を先頭に置き、`infogeom.alpha_lower` は最後に置くため、
接続係数の比較では添字を明示的に入れ替える。

確率単体は平方根写像 `p ↦ 2√p` によって半径2の球面へ等長に写るため、断面曲率は `1/4` となる。
テストでは有理座標だけでこの結果を確認する。平方根写像そのものを数値評価する必要はない。
2次元単体のスカラー曲率は `1/2`、3次元では `3/2`、独立なBernoulli分布の積は平坦になる。
同じ空間でも座標に応じて計量や接続係数は変わるが、これらの曲率の結果は保たれる。

一般の `riemann.metric_jet` は可逆な対称計量を受け取り、不定符号の計量も許す。
`is_positive_definite` は別にSylvester判定を行う。正の有限分布から作るFisher行列は半正定値だが、
パラメータが冗長なら特異となり、幾何への接続は `SingularMetric` を含むエラーを返す。
これは点での局所計算であり、大域的な多様体・測地線の積分・測地距離の計算は含まない。

一般計量の独立Fraction参照と規約は[微分幾何の実装記録](../research/riemann-20261118.md)に保存する。
有限状態の時間発展は[Markov連鎖の実装記録](../research/markov-20261118.md)を参照。

`markov.stationary` は正規化された定常方程式のアフィン解全体を返し、
`stationary_member` がパラメータから得たベクトルの非負性を検査する。
可約な鎖で任意の定常分布を一つ選ばず、`unique_stationary` は一意な場合に限って返す。
周期性を定常分布の不存在と取り違えない。
目標状態集合への到達確率は最小の非負解として求め、到達確率が1未満なら無条件の平均到達時間を `Infinite` とする。
方程式だけで別の解を受け入れないよう、到達可能性の経路と到達不能部分の閉性も証拠として検査する。

## 高階テンソルの共通操作

[tensor](../../src/tensor) は `Tensor[A]` に軸の大きさとrow-majorの不変リストを保持する。
型パラメータが成分の型を表し、軸の大きさと成分数の一致は構築時に検査する。
rank 0は成分を一つ持つscalar、長さ0の軸を含むテンソルは成分を持たない。
軸の置換は全単射を検査し、縮約は異なる二軸とその大きさの一致を要求する。
`Semiring[A]` を渡すので、同じ演算を有理数・Bool・有限体などで使える。
演算辞書の半環法則自体を型が証明するわけではない。

`mode_product(t,axis,map,semiring)` は一軸へ `map[out,in]` を作用させる。
[statgeometry/tensors.mbt](../../src/statgeometry/tensors.mbt) では、逆計量による接続の添字上げ、
Jacobianによるcubicテンソルの引き戻し、Ricci曲率と逆計量の積からの二回の縮約に再利用する。
引き戻しは一般の長方形Jacobianも受け取り、cubicのような共変テンソルを扱う。
接続係数の非線形な座標変換には2階微分も必要なので、この操作だけでは済ませない。
初期実装は成分へのアクセスにリスト走査を含む。一般の高速なdense tensor runtimeを主張しない。
設計と有限検証は[テンソル部品の記録](../research/tensor-20261118.md)に残す。

## α接続の曲率

[infogeom/alpha.mbt](../../src/infogeom/alpha.mbt) は確率3-jetから接続係数の1階微分を生成する。
[statgeometry/alpha.mbt](../../src/statgeometry/alpha.mbt) は逆計量の微分も含めて上側添字の接続を微分し、
一般のαに対する曲率・Ricci縮約・scalarを計算する。
接続係数は `[i,j,r] = Γ^r_ij`、その微分は `[k,i,j,r] = ∂k Γ^r_ij`、曲率は `[r,j,k,l] = R^r_jkl`。
添字上げと縮約には共通のテンソル操作を使う。

検証例の確率単体では断面曲率が `(1−α²)/4` となり、`α=±1` は平坦、`α=0` はFisherのRiemann曲率に一致する。
自然座標と混合座標の両方で確認する。
一般の曲がった部分モデルでは、`α=0` を独立した計量2-jetの曲率経路と全成分で照合し、
双対な接続の関係 `R^(α)_ijkl = −R^(−α)_jikl` も確認する。
一般のα接続は計量接続ではないため、Levi-Civita曲率の全対称性をそのまま前提にしない。

## Gaussianのモーメントを代数的に計算する

[gaussian](../../src/gaussian) は、有理数の平均と対称正定値の共分散から連続Gaussianを表す。
Stein再帰と不変なmemoizationにより、生モーメントと疎多項式の期待値を正確に求める。
`Moments` を返すAPIでは、同じ分布に対する後続計算へ既知のモーメントを引き継げる。
数値積分や密度関数の評価を必要としない、連続確率への一つの経路である。

独立な参照計算は平均を分離した全展開とWick pairingを使う。
検査範囲と再帰式は[Gaussianの記録](../research/gaussian-20261118.md)にまとめた。

[gaussian.fisher_jet](../../src/gaussian/fisher.mbt) は十分統計量を `X_i` と `X_i X_j (i≤j)` の順に並べ、
中心モーメントから2・3・4次cumulantを構築する。
Gaussianの自然座標では、これらがFisher計量とその1・2階微分に対応する。
統計量の積は添字を並べ替えた不変cacheで共有し、その内部の期待値もモーメントplanを引き継ぐ。
返す `riemann.MetricJet` は局所の自然座標の値であり、平均と共分散の座標での値と混同しない。

1変量Gaussianの平均・分散を動かす2次元の族では、断面曲率 `−1/2`、スカラー曲率 `−1` を確認する。
2変量では自然座標が5次元となり、Fisher行列を共分散の直接公式と全成分で照合する。
これは一般の密度の数値積分や測地距離計算を導入せず、連続分布の幾何へ接続する例である。

## 微分形式と単体の積分

[forms](../../src/forms) は、有理多項式を係数とする微分形式を疎な正規形で表す。
外積は添字の置換符号と重複による消滅を処理し、外微分には既存の多項式微分を使う。
`ClosedForm` は検査済みの閉性、`ExactForm` は原始形式を保持する。和・外積・引き戻しで性質を維持し、閉性が既知なら外微分を再計算しない。
具体的な法則と構築の制限は[構造を保持する型の章](structure-modeling.md#微分形式の閉性と原始形式を保持する)にまとめる。
多項式vector fieldとの縮約、Cartanの式によるLie微分、多項式写像による引き戻しも扱う。
radial homotopyは係数の各斉次成分に作用し、閉じた正次数の形式にはprimitiveとその検査を返す。
対象は有理多項式を使うaffine空間であり、一般多様体のde Rhamコホモロジーを解くものではない。

[simplexforms](../../src/simplexforms) は、順序を持つ有理頂点から向き付き単体を構築し、微分形式を厳密に積分する。
標準単体へ引き戻し、多項式の各項をfactorial比で積分する。
Stokes証拠は入力形式・外微分・全ての向き付き境界と各積分値を束縛し、境界を落とした偽の証拠を拒否する。
退化した単体も扱うが、零になる前に次元と次数の不正を検査する。
独立な参照と現在の限界は[微分形式](../research/forms-20261118.md)と[単体積分](../research/simplexforms-20261118.md)の記録にある。
Whitney形式の草案は未完成として保存しており、現行APIには含めない。

## 検証と範囲

`distribution_wbtest.mbt` は3標本の整数重みを列挙し、分母を払った独立した整数計算と期待値・分散・条件付け・Bayes更新を照合する。
二値分布の独立積、両側の周辺分布、全変動距離、混合も照合する。
テストのホスト整数・配列は参照計算に限定し、計算核は不変ADTと再帰のみで実装する。

情報幾何では3標本の単体の小さな有理点について、Fisher行列と逆行列の閉形式を照合する。
scoreの平均0、cubicの対称性、双対関係 `∂i g_jk = Γ^(α)_ij,k + Γ^(-α)_ik,j`、
非線形なBernoulli座標 `p=t²` の2階微分、特異モデルと不正なjetの拒否を検査する。
多項式から生成する経路では、単体の全2階計量微分と、`p=t²`・`p=t³` の閉形式の微分を比較する。
特に `p=t³` は、確率の3階微分を取り落とした実装を検出するための例である。

有限分布の層には乱数生成器を含まない。Gaussianの多項式モーメントは扱うが、一般の連続分布の積分器は含まない。
一般の曲率計算は別の微分幾何の層へ接続する。
対数・指数関数の値が必要なエントロピーやKL距離は、有理数の四則演算だけで一般に閉じない。
その値の表現と局所的な微分幾何の計算を分けて設計する。

定義の参照先は [Nielsen, An elementary introduction to information geometry](https://arxiv.org/abs/1808.08271) と
[Pistone, Information Geometry of the Probability Simplex](https://arxiv.org/abs/1911.01876)。
上記の接続はNielsenの期待α接続の規約に従う。
