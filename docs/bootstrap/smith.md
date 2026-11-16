# 整数行列の証拠付きSmith標準形

[ドキュメント](../README.md) / [探索・改善記録](README.md)

`src/smith` は整数行列Aから `U*A*V=D` を構築し、整数の行・列変形の証拠とともに返す。
UとVはそれぞれ正方のunimodular行列、Dは元と同じ矩形で、対角は非負、
非零の対角値は次の値を割り切り、零は末尾に並ぶ。

```moonbit
pub fn start(@matrix.Matrix[@exact.Integer]) -> Machine
pub fn step(Machine) -> Status
pub fn run(Machine, @core.Nat) -> Status
pub(all) enum Status { Done(Decomposition); Paused(Machine); Fault(Machine) }
pub fn check(A, U, D, V) -> Decomposition?
```

型A/U/D/Vはすべて `@matrix.Matrix[@exact.Integer]`。
受理後のopaqueな `Decomposition` には `original/left/diagonal/right` でアクセスする。
`invariant_factors` はmin(行数,列数)個の対角値を零込みで返し、`rank` は非零の個数を返す。
0行、0列、正方・矩形、ランク欠損も同じ型で扱う。

## 生成と独立checker

生成は古典的なEuclid型の行・列基本変形で行う。
残余blockから非零pivotを移し、pivot列・行のほかの値を整数の商で減らす。
余りが非零ならその小さい絶対値をpivotへ移す。
行と列が零になってもpivotが残余block全体を割らない場合は、該当行をpivot行へ加え、
再びEuclidでpivotを小さくする。全体を割るまで固定せず、最後に符号を正にして次へ進む。
各行操作をU、列操作をVにも同時適用する。
整除された残余blockへの整数基本変形は先のpivotの整除性を保存する。

この古典的な基本変形の枠組みと、Smith形の条件は
[FLINTのSmith normal form公式資料](https://flintlib.org/doc/fmpz_mat/snf.html) を参照した。
この実装を係数増大を制御するKannan–Bachemの実装や、多項式時間の実装とは呼ばない。
中間の整数値は大きくなり得る。

checkerは生成器を実行しない。まず寸法と対角条件を調べ、
U/Vを有理行列へ埋め込んで既存 `linear.determinant` のGaussian消去により
det(U),det(V)が厳密に±1かを検査する。これは整数行列のunimodularityを保証する。
さらに別の行列積で `U*A*V=D` を再計算する。
等式だけ合う非unimodular変形、負の対角、整除しない対角、零の順序、非対角成分も拒否する。

燃料1はEuclidによる一つの行/列縮約（必要なら交換を伴う）、pivotの移動/確定、
または完了checkerの一回。行列の走査や整数演算、最終行列式の計算時間を固定しない。
燃料0と `Paused` の再投入は正確に同じ途中状態を引き継ぐ。
`Fault` は生成器の不変条件に反する防御的な停止で、正常な完了とは区別する。

## 検証とfixture

2×2の全成分−2〜2の625行列を、整数のgcdと行列式から得る独立の
determinantal divisorと照合する。3×3、長方形、符号、rank欠損、0行/0列も含む。
燃料を分割しても一括実行と一致し、途中のすべての検査境界でもUAVの等式と
U/Vのunimodularityを保つことを調べる。

再現可能な固定seedで作った47例の独立SymPy対角fixtureもコミットする。
SymPyからは対角Dだけを取り、U/Vの変換はMoonBit自身が生成して独立checkerへ渡す。
通常テストはPythonを呼ばない。

```sh
python3 tools/generate_smith.py
tools/moon fmt src/smith
tools/moon test src/smith --target native
tools/moon test src/smith --target wasm-gc
tools/moon test src/smith --target js
python3 tools/audit_purity.py
```

再生成に使った独立oracleはSymPy 1.14.0の
[`smith_normal_form(...,domain=ZZ)`](https://docs.sympy.org/latest/modules/matrices/normalforms.html)。
核の整数は独自Binaryに基づき、配列・機械整数・可変状態・FFIを使わない。
有限の検査であり、すべての整数行列の終了・実時間・係数サイズの形式証明ではない。

## 整数方程式と独立した不可能証拠

`solve(form,b)` は整数の `A*x=b` を扱う。検査済み `UAV=D` から
`D*z=U*b`、`x=V*z` と変換し、非零対角の位置は割り切れることを要求し、
零行の位置は右辺も零であることを要求する。

```moonbit
pub fn solve(Decomposition, @core.Chain[@exact.Integer]) -> SolveResult?
pub(all) enum SolveResult { Solved(IntegralSolution); Impossible(Obstruction) }
pub fn particular(IntegralSolution) -> @core.Chain[@exact.Integer]
pub fn kernel_basis(IntegralSolution) -> @core.Chain[@core.Chain[@exact.Integer]]
```

解は特解と、Vのrank以降の列を基底とする完全な整数kernelを持つ。
すべての解は `particular + Σ t_j*basis_j`（t_jは任意の整数）。
`check_solution` はA*x=bと各kernel vectorの零像を直接確認し、
基底が検査済みVの自由列そのものであることも確認する。
単にkernelに入るだけの真の部分格子を、完全な整数解族とは認めない。

不可能性は二種類のrawな `Obstruction` で表す。
`Congruence(y,d)` はd>1、y*Aの全係数がdの倍数、y*bがdの倍数でないことを示す。
`Annihilator(y)` はy*A=0なのにy*bが非零であることを示す。
`check_obstruction(A,b,witness)` はSmith生成器やDecompositionを受け取らず、
元の整数の内積と割り切れだけで検査するため、独立して不可能性を確認できる。
有理数なら解ける `2*x=1` も、整数では最初の証拠で拒否する。

全scalar係数/右辺−4〜4、2×2係数−1〜1と右辺−2〜2の2025組を調べる。
返された解は整数式で直接検査し、不可能証拠を再検査する。
不可能の例ではさらに−4〜4の全候補解にも反例がないことを確認する。
この有限の候補探索だけを一般の不可能証明の代用にはしていない。
長方形、空の制約、変数0個、整合しない右辺長、偽の基底・不可能証拠も検査する。

## 有限生成アーベル群の入口

整数m×n行列Aを関係写像 `Z^n -> Z^m` とし、`cokernel(form)` は
`Z^m/image(A)` の自由rankと、1より大きいtorsion invariant factorsを返す。
これは [William Stein, §2.1, Theorem 2.1.2とProposition 2.1.6](https://wstein.org/books/ant/ant/Ch2.html)
に述べられるSmith形による分類に対応する。

```moonbit
pub fn cokernel(Decomposition) -> Cokernel
pub fn free_rank(Cokernel) -> @core.Nat
pub fn torsion_factors(Cokernel) -> @core.Chain[@binary.Binary]
pub fn finite_order(Cokernel) -> @binary.Binary?
pub fn class_coordinates(Cokernel, @core.Chain[@exact.Integer]) -> @core.Chain[@exact.Integer]?
pub fn equivalent(Cokernel, @core.Chain[@exact.Integer], @core.Chain[@exact.Integer]) -> Bool
```

自由rankはm−rank(A)。自由部分がなければ `finite_order` はtorsion factorsの積、
自由部分があれば `None` を返す。空のtorsion積は1。
`class_coordinates` はUを適用した後、非零対角では正の剰余へ、自由位置では
符号付き整数のままにする。元の座標系のvectorそのものではなくSmith座標である。
`equivalent` は二つのvectorが同じ剰余類かをこの正規座標で判定する。
例えばdiag(4,6)のcokernelは `Z/2 ⊕ Z/12`、要素数24となる。
零行を一つ加えたdiag(2,6)なら自由rank1とtorsion 2/6を持ち、無限群となる。

## 生成と検査の計測

2026-11-15、Intel Core Ultra 7 255H、x86_64、moonc v0.10.20、
`tools/moon bench src/smith --target native --release`。
入力・初期identity・燃料の構築を除外する。生成側は全変形と最終独立checkerを含む。
共有ホストの同時負荷や周波数は固定していない。

| 処理 | 平均±標準偏差 |
| --- | --- |
| 固定3×3の生成とchecker | 41.21 µs ± 2.04 µs |
| 同じ3×3の既存証拠をcheckerで再検査 | 18.97 µs ± 706.37 ns |
| 固定4×4の生成とchecker | 247.73 µs ± 5.80 µs |

生成と再検査のコストの記録であり、異なる結果を返す処理の性能優位を示す比較ではない。
他の整数行列ライブラリとの比較や、中間整数の最大bit量・メモリ量の測定は行っていない。

```text
generate/check 3x3: 41.21 µs ± 2.04 µs; 38.63 µs … 44.06 µs; 10 × 2391 runs
check 3x3: 18.97 µs ± 706.37 ns; 17.81 µs … 19.80 µs; 10 × 5564 runs
generate/check 4x4: 247.73 µs ± 5.80 µs; 242.82 µs … 261.82 µs; 10 × 402 runs
```
