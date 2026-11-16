# 厳密Rationalによる証拠付きLLL

[ドキュメント](../README.md) / [探索・改善記録](README.md)

`src/lll` は行vectorを格子基底として、整数のrow basis Bをδ=3/4でLLL簡約する。
対象はfull row rankの矩形行列で、依存行は初期境界で厳密に拒否する。
空のrow basisはrank 0として任意のambient dimensionで扱う。

```moonbit
pub fn start(@matrix.Matrix[@exact.Integer]) -> Machine?
pub fn step(Machine) -> Status
pub fn run(Machine, @core.Nat) -> Status
pub(all) enum Status { Done(Reduction); Paused(Machine); Fault(Machine) }
pub fn check(input, transform, reduced) -> Reduction?
pub fn check_with_gram(input, transform, reduced, GramSchmidt) -> Reduction?
```

三つの行列の型は `@matrix.Matrix[@exact.Integer]`。
opaqueな `Reduction` から `original/transform/basis/gram` で検査済み結果を取り出せる。
kernelはBinary/Integer/Rational/Chainと再帰だけを使い、浮動小数・近似・配列・可変状態を使わない。

## 条件とtie規約

Gram–Schmidtを `b_i*=b_i−Σ_(j<i) μ_ij b_j*`、
`μ_ij=<b_i,b_j*>/||b_j*||²` と定義し、すべて厳密Rationalで計算する。
簡約結果は次の二条件を満たす。

- 全j<iで `|μ_ij|<=1/2`。
- k>=1で `||b_k*||² >= (3/4−μ_(k,k−1)²)*||b_(k−1)*||²`。

これは [Lenstra–Lenstra–Lovász (1982), §1](https://ir.cwi.nl/pub/9304) の
δ=3/4の基底簡約条件に対応する。
生成器は後ろの係数からsize reductionを行い、Lovasz条件が破れたら隣接行を交換する。
丸めはnearest integerで、ちょうど中間なら0から遠ざかる整数を選ぶ。
例として3/2は2、−3/2は−2。係数がちょうど±1/2ならsize条件を満たすため操作しない。
tie規約は実行の決定性のためであり、checkerは上記の数学的条件を直接検査する。

## latticeとGram–Schmidtの独立checker

生成中の行操作を整数の変換行列Uへ同時適用し、checkerは `B'=U*B` を別の行列積で確認する。
Uの行列式は既存の有理Gaussian消去で再計算し、厳密に±1を要求する。
これにより生成する整数格子が同じであることを確認する。

rawな `GramSchmidt` は直交vector列、三角形のμ列、norm列を持つ。
checkerはこの値を信用せず、次を直接確認する。

- すべての寸法、μの行iの長さがiであること。
- 直交vectorの相互内積が0であること。
- normが実際の二乗内積に等しく、正であること。
- 各元の行が `b_i*+Σ μ_ij b_j*` に正確に再構成されること。

この再構成は生成側の射影の減算とは分け、加算で検査する。
したがって生成器のGram–Schmidt計算や簡約traceをそのまま正しいと仮定していない。
`check` はevidenceを再計算して上記checkerへ渡し、`check_with_gram` は外部のraw witnessを検査する。
最後に全size/Lovasz条件を確認してからopaqueな結果を返す。

燃料1はsize候補1個、phase移行、Lovaszの判定/交換、または最終checkerの1回。
各遷移のGram–Schmidt再計算や多倍長演算のコストを燃料1に固定しない。
燃料0と `Paused` への追加燃料は完全に同じ途中状態を保存する。
`Fault` は不変条件に反する防御的停止で、簡約成功とは区別する。

## 検証

2×2の全成分−2〜2の625入力を調べ、依存行を拒否し、full rankの結果について
独立した整数式 `2*|<u,v>|<=||u||²`、`4*||v||²>=3*||u||²` を確認する。
後者は2次元のLovasz条件から射影項が相殺した形であり、生成器のRational条件を使わない。
Uの整数行列式とU*Bも整数oracleで再計算する。
半整数の正負tie、Lovaszの等号境界、空/矩形、燃料分割、途中の格子等価性も検査する。
サイズ条件だけ、Lovaszだけ、unimodularityだけを破った候補と、
norm・直交性・再構成を偽ったGram–Schmidt witnessも拒否する。

28例の独立SymPy fixtureには、δ=QQ(3,4)のLLL結果と変換U、別途求めた正確な
直交vector/μ/normを含める。SymPy側でもU*B、detU=±1、全簡約条件を検査して生成する。
MoonBitのcheckerがこれを受理し、Gram–Schmidt計算も一致することを調べる。
LLLの結果は一意とは限らないため、MoonBitとSymPyの基底の文字列一致は要求しない。
APIの根拠は [SymPy DomainMatrix.lll_transformの公式資料](https://docs.sympy.org/latest/modules/polys/domainmatrix.html#sympy.polys.matrices.domainmatrix.DomainMatrix.lll_transform)。

```sh
python3 tools/generate_lll.py
tools/moon fmt src/lll
tools/moon test src/lll --target native
tools/moon test src/lll --target wasm-gc
tools/moon test src/lll --target js
python3 tools/audit_purity.py
```

通常テストはコミット済みfixtureを使い、PythonやSymPyを実行しない。
再生成環境はSymPy 1.14.0で、fixtureの値と条件の検査は整数/QQで行う。

## 計測と限界

2026-11-15、Intel Core Ultra 7 255H、x86_64、moonc v0.10.20、
`tools/moon bench src/lll --target native --release`。
入力と燃料の構築を除外し、生成側は初期rank検査・全変形・最終独立checkerを含む。
共有ホストの同時負荷やCPU周波数は固定していない。

| 処理 | 平均±標準偏差 |
| --- | --- |
| 固定3×3の簡約とchecker | 353.92 µs ± 20.09 µs |
| 同じ3×3の既存証拠のchecker | 25.88 µs ± 847.94 ns |
| 固定3×4の簡約とchecker | 368.00 µs ± 3.58 µs |

生成と検査の費用の記録で、別実装に対する性能優位の比較ではない。
Gram–Schmidtを各遷移で再計算するため、小次元の成立確認を優先した実装である。
大次元の係数増大対策、実メモリ量、最短vectorの最適性証明は含めない。
全入力の終了時間やMoonBit実装の多項式bit計算量を形式証明していない。

```text
reduce/check 3x3: 353.92 µs ± 20.09 µs; 329.40 µs … 391.73 µs; 10 × 280 runs
check 3x3: 25.88 µs ± 847.94 ns; 24.88 µs … 27.15 µs; 10 × 3702 runs
reduce/check 3x4: 368.00 µs ± 3.58 µs; 363.40 µs … 373.47 µs; 10 × 252 runs
```

## Smithから依存した生成集合を整備する

`start` のfull-row-rank境界を維持したまま、別入口 `from_smith(form)` で
任意の整数生成行列を整備できる。検査済み `U*B*V=D` からU*Bを再計算し、
rank以降の行が厳密に零であることを確認してから、その零行だけを落とす。
残った先頭rank行はGram–Schmidtでも独立性を再検査する。
Uが整数unimodularなので、元と同じ**整数**row latticeを張る。
単に有理数で独立な元の行を選ぶ処理ではない。
例えば(2,0)と(3,0)を並べた入力では、(1,0)を張る基底を得る必要がある。

```moonbit
pub fn from_smith(@smith.Decomposition) -> IndependentBasis?
pub fn independent_basis(IndependentBasis) -> @matrix.Matrix[@exact.Integer]
pub fn combine(IndependentBasis, Reduction) -> LatticeReduction?
pub fn check_lattice(input, square_transform, reduced) -> LatticeReduction?
```

呼出側はSmithのfuel付き実行、`from_smith`、得られた基底へのLLLのfuel付き実行を順に行う。
`combine` はその基底に対するLLL証拠だけを受け取り、rank×rankのLLL変換Wを
`diag(W,I)` へ拡大してSmithのUへ合成する。
最終の正方整数変換Cは `C*B=(reduced_basis; zero_rows)` を満たす。

`check_lattice` はSmith証明を受け取らず、この等式、det(C)=±1、末尾の全零行、
先頭の基底のGram–Schmidtと全LLL条件を直接検査する。
これにより依存入力にも同じ整数格子を保証し、行を落として部分格子に変える候補を拒否する。
受理したopaque結果には `lattice_original/lattice_transform/lattice_basis/lattice_gram` でアクセスする。
全零、0行/0列、矩形と全小2×2依存入力について、内容gcdも整数oracleで照合する。

同じnative release環境で、固定した依存3×4入力のSmith生成・証明検査・
基底整備・LLL・最終の格子checkerまでを計測すると325.94 µs ± 19.66 µs。
入力の構築だけを除外した構成例のコストであり、full-rank例と直接の優位比較はしない。

```text
Smith plus LLL 3x4: 325.94 µs ± 19.66 µs; 306.94 µs … 359.87 µs; 10 × 289 runs
```
