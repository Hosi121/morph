# 整数行列の証拠付きSmith標準形

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
