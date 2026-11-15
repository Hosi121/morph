# 上限を明示する離散対数探索

`src/discretelog` は、検査済み素数体の乗法群で `g^x=h` を満たす
`0<=x<B` の最小の指数を探す。`g,h` は非零の正規剰余に直して受け取り、
0の剰余は `problem` が拒否する。GF(2)も含む。

```moonbit
pub fn problem(@primefield.Field, @binary.Binary, @binary.Binary, @binary.Binary) -> Problem?
pub fn baby_step_giant_step(Problem) -> Logarithm?
pub fn naive(Problem) -> Logarithm?
pub fn check(Problem, @binary.Binary) -> Logarithm?
pub fn exponent(Logarithm) -> @binary.Binary
pub fn instance(Logarithm) -> Problem
```

非零元の位数は `p−1` を割るが、`g` が全乗法群の生成元とは仮定しない。
`B` は呼出側が指定した排他的上限であり、群の位数と同一視しない。
`B=0` の探索範囲は空。`None` は指定範囲内での未発見であり、
探索範囲を越えた解や別の底に対する解の不存在を示す証明ではない。
例えばGF(17)の `g=3,h=13` ではB=4で未発見、B=5でx=4となる。
GF(7)の `g=2` は位数3の部分群しか生成しないので、h=3はB=6でも見つからない。

## 純記号のbaby-step giant-step

幅 `m=ceil(sqrt(B))` を既存の厳密二進平方根から作り、`g^j`、`0<=j<m` を
不変Bool trieに保存する。keyは正規剰余の二進リスト、値は最小のbaby指数j。
同じ群要素が繰り返し出ても小さいjを保持し、底の位数がm未満の場合にも対応する。
次に `h*(g^(−m))^i` を、`i*m<B` の範囲で順に調べる。
一致したjから `x=i*m+j` を作り、元の上限と新しい剰余累乗で検査する。

分解 `x=i*m+j` と照合式は [HAC §3.6.2, Algorithm 3.56](https://cacr.uwaterloo.ca/hac/about/chap3.pdf)
に基づく。この実装は既知の群位数の代わりに明示した有限指数範囲を被覆する。
小さいiの区間から調べ、同じbaby値には最小jを置くため、見つかる最初の指数が最小になる。
`check` は探索せず、範囲と `g^x=h` を独立に再累乗して検査する。
`check` だけでは最小性を証明しない。例えばg=1,h=1では範囲内のx=5も検査を通るが、
探索算法はx=0を返す。

剰余乗算は概ね `m+ceil(B/m)` 回、さらに逆元・候補の検査などを行う。
格納するbabyは最大m個で、trieのkey長は法のビット長に依存する。
これは群演算と構造上の回数の説明であり、二進リスト演算を定数時間とみなさない。
実装は既存の純Chain/Binary/Bool trieと再帰だけを使い、配列や機械整数を核に持ち込まない。
大きなBではメモリや時間を消費する。中断用の燃料や再開機械はこのmilestoneには含めない。
実用暗号の安全性、定数時間性、一般の離散対数の高速な解法は主張しない。

## 検証と再生成

GF(2)、3、5、7、11、13、17、19について、すべての非零g/hと
B=0〜p+2を、独立した整数逐次乗算の全探索および純記号naiveと比較する。
排他的な上限、平方根の切り上げ、部分群、繰り返すbaby、指数0、正規化、
ゼロ入力の拒否を含む。受理した候補は `check` で再検査する。

通常テストではコミット済みfixtureを使う。Pythonの `pow` と有限全探索で生成し、
65537、998244353、2305843009213693951上の例と、上限直前/直後を含める。
大きい法の素数性も、外部の判定名ではなくLucas証明をMoonBitで検査してから利用する。

```sh
python3 tools/generate_discretelog.py
tools/moon fmt src/discretelog
tools/moon test src/discretelog --target wasm-gc
tools/moon test src/discretelog --target js
tools/moon test src/discretelog --target native
python3 tools/audit_purity.py
```

再生成ツールは既存 `generate_primality.py` の整数certificate builderだけを再利用する。
通常のMoonBitテストはPythonを実行しない。

## 同じ問題でのnaive比較

2026-11-15、Intel Core Ultra 7 255H、x86_64、moonc v0.10.20、
`tools/moon bench src/discretelog --target native --release`。
体の証明検査、Problem構築、目標値の生成を除外する。
BSGSはbaby tableの構築・逆元・探索・独立再累乗を含み、naiveも独立再累乗を含む。
両方が同じ最小指数を返すことを計測前に検査している。
共有ホストの同時負荷や周波数は固定していない。

| 法・底・指数上限 | 同じ目標の最小解 | BSGS（平均±標準偏差） | naive（平均±標準偏差） |
| --- | --- | --- | --- |
| p=65537、g=3、B=16384 | 10000 | 1.14 ms ± 13.18 µs | 24.51 ms ± 658.56 µs |
| p=998244353、g=3、B=65536 | 50000 | 7.39 ms ± 266.45 µs | 318.49 ms ± 8.77 ms |

この有限範囲の二例では計算時間が小さくなるが、trieの領域を追加で使う。
領域のbyte量は計測しておらず、任意入力や機械整数実装との優劣は示さない。

```text
BSGS 65537: 1.14 ms ± 13.18 µs; 1.12 ms … 1.16 ms; 10 × 84 runs
naive 65537: 24.51 ms ± 658.56 µs; 23.64 ms … 25.55 ms; 10 × 5 runs
BSGS 998244353: 7.39 ms ± 266.45 µs; 7.08 ms … 7.88 ms; 10 × 14 runs
naive 998244353: 318.49 ms ± 8.77 ms; 307.37 ms … 332.99 ms; 10 × 1 runs
```

## 最小位数の証拠と部分群全体の境界

`exact_order(field,g,factors)` は候補dの完全な検査済み素因数分解を受け取り、
`d | p−1`、`g^d=1`、すべての素因数qに対する `g^(d/q) != 1` を再累乗で確認する。
位数がdの真の約数なら、いずれかのqについて最後の条件が破れるので、
受理したopaque `Order` は最小の正の位数を表す。
根拠は [HAC §4.6, Algorithm 4.79/4.80](https://cacr.uwaterloo.ca/hac/about/chap4.pdf)
と同じ素因数ごとの位数条件である。ここでも因数や証明の探索は行わない。

```moonbit
pub fn exact_order(@primefield.Field, @binary.Binary, @factor.Factorization) -> Order?
pub fn order_value(Order) -> @binary.Binary
pub fn order_base(Order) -> @binary.Binary
pub fn order_field(Order) -> @primefield.Field
pub fn order_factorization(Order) -> @factor.Factorization
pub fn subgroup_problem(Order, @binary.Binary) -> Problem?
```

`subgroup_problem` はB=dを使うため、探索区間はgが生成する部分群を一周分覆う。
このProblemの完全な探索で未発見なら、目標はその生成部分群に属さない。
それでもgが全乗法群の生成元だとは限らない。GF(7)のg=2は検査済み位数3で、
h=4は指数2を持つ一方、h=3は同じ体の非零元であってもその部分群には属さない。

小素数のすべての底と候補位数を整数の最小反復回数と照合する。
真の位数の倍数、根拠のない候補位数、零元を拒否し、
GF(2)の位数1と65537上の底3の位数65536も検査する。
