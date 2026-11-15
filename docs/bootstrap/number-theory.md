# 証明を受け取る素数判定

`src/primality` は、素数を探索する処理と、渡された証明を検査する処理を分ける。
外部の探索で作ったLucas/Pratt型の木を、純記号の二進算術と剰余累乗だけで検査する。
`check` が返す `Prime` はフィールドを外部から構築できない型であり、
確定した素数を要求する別パッケージの入口に渡せる。

```moonbit
pub(all) enum Certificate {
  Two
  Lucas(@binary.Binary, @binary.Binary, @core.Chain[Certificate])
}
pub fn check(Certificate) -> Prime?
pub fn value(Prime) -> @binary.Binary
pub fn candidate(Certificate) -> @binary.Binary
```

`Lucas(n, a, children)` の子は `n−1` の素因数を**重複込み**で並べる。
順序は任意。例えば7には2と3の証明、5には2の証明を二つ渡す。
子の証明をすべて再帰検査し、`n−1` を各素因数で割っていき、余りがすべて0で
最後の商が1になることを確認する。これにより欠けた因子、余分な因子、
素数でない子を受け付けない。2は `Two` が基底となる。

検査する合同式は `a^(n−1) ≡ 1 (mod n)` と、各素因数 `q` について
`a^((n−1)/q) ≢ 1 (mod n)`。
前者から `a` は乗法群の元で、その位数は `n−1` を割る。
後者がすべての素因数に成立すると、その位数は `n−1` そのものになる。
したがって `φ(n) ≥ n−1` となり、`n>1` は素数である。
これは [Handbook of Applied Cryptography, Fact 4.38, §4.3.2](https://cacr.uwaterloo.ca/hac/about/chap4.pdf)
の条件に対応する。部分分解を使うPocklingtonの条件とは混同しない。
`None` はその証明が不正だったことだけを意味し、合成数の証明にはならない。

## fixtureと検証

通常のテストはコミット済み `vectors_wbtest.mbt` だけを使う。
再生成は次のとおり。Python整数の試し割りで `n−1` を完全分解し、
Pythonの `pow` で最小のwitnessを探索する。MoonBitのcheckerはこの探索を呼ばない。

```sh
python3 tools/generate_primality.py
tools/moon fmt src/primality
tools/moon test src/primality --target wasm-gc
tools/moon test src/primality --target js
tools/moon test src/primality --target native
python3 tools/audit_purity.py
```

独立した整数試し割りと旧 `@modular.is_prime` に対し0〜127を照合する。
同範囲のすべての合成数は、`n−1` の正しい完全分解を渡しても
0〜`n−1` のすべてのwitnessで拒否される。
因子の欠落・追加・非約数・不正な子証明・誤witnessも拒否する。
大きいfixtureは257、65537、998244353、2147483647、2305843009213693951。
受理の根拠は外部での「素数らしい」という判定ではなく、MoonBitでの証明検査である。

この境界はMoonBit型システムと既存の二進・剰余算術の正しさに依存する。
任意入力の終了時間やスタック量は保証しない。証明木は非循環の通常値として受け取る。
実用暗号の安全性、定数時間性、機械整数ライブラリに対する性能優位は主張しない。

## 同条件の検査コスト

2026-11-15、Intel Core Ultra 7 255H、x86_64環境、moonc v0.10.20、
`tools/moon bench src/primality --target native --release`。
証明木と二進入力の構築を計測外に置き、同じ数を既存の完全試し割りと比較した。
証明を発見するコストは含まない。

| 候補 | Lucas証明検査（平均±標準偏差） | 既存試し割り（平均±標準偏差） |
| --- | --- | --- |
| 65537 | 1.27 ms ± 36.95 µs | 692.30 µs ± 20.47 µs |
| 998244353 | 17.28 ms ± 751.96 µs | 250.94 ms ± 9.55 ms |

65537では子の重複検査と合同累乗のコストで証明検査の方が遅い。
998244353では同じ厳密な素数受理に対する検査時間が小さくなる。
この二つの数での結果であり、一般の素数探索や機械整数実装との優劣を示さない。

```text
Lucas 65537:    1.27 ms ± 36.95 µs; 1.23 ms … 1.34 ms; 10 × 83 runs
trial 65537: 692.30 µs ± 20.47 µs; 665.63 µs … 723.14 µs; 10 × 149 runs
Lucas 998244353: 17.28 ms ± 751.96 µs; 16.23 ms … 18.27 ms; 10 × 6 runs
trial 998244353: 250.94 ms ± 9.55 ms; 236.47 ms … 268.24 ms; 10 × 1 runs
```

## 燃料付きPollard rhoと因子の検査

`src/factor` は非自明因子を探す処理と、その積を確認する境界を持つ。
`check_factor(n,d)` は `1<d<n` と割り切れることを検査し、
外から構築できない `Split` を返す。`number`、`divisor`、`cofactor` で値を取り出せる。
どちらの因子も素数とは限らず、`Split` を `Prime` の代用にはできない。

```moonbit
pub fn check_factor(@binary.Binary, @binary.Binary) -> Split?
pub fn start(@binary.Binary, @binary.Binary, @binary.Binary) -> Machine?
pub fn step(Machine) -> Status
pub fn run(Machine, @core.Nat) -> Status
pub(all) enum Status {
  Found(Split)
  Suspended(Machine)
  Failed(Machine)
}
```

`start(n,seed,c)` は `n>1` を要求する。二つの点を `seed mod n` から始め、
`f(x)=x²+c mod n` に対してFloydの遅い点を1回、速い点を2回進め、
差と `n` のGCDを調べる。`1<gcd<n` のとき `check_factor` を通して返す。
GCDが `n` なら `Failed`、1なら次の不変状態を返す。偶数 `n>2` は2で分割する。
これは [HAC Algorithm 3.9 と Note 3.12](https://cacr.uwaterloo.ca/hac/about/chap3.pdf)
の探索を、seedと定数を明示する形で表す。

燃料1は `step` 1回であり、最大Floyd1反復（剰余多項式評価3回とGCD）を行う。
偶数の直接分割も1ステップとして扱う。燃料0では一切進めず、同じ機械を返す。
燃料はビット演算数・メモリ・実時間の上限ではない。
`iterations` は実際に行ったFloyd反復数で、偶数の直接分割は含まない。
分割が見つかる前の状態を `run` に再投入すると、分割実行と一括実行は同じ結果になる。

`Failed` はその軌道が衝突したことだけを示す。素数の確定や因数の不存在は意味しない。
呼出側が同じ `n` と別の `seed,c` で `start` し直す。
固定seedで全合成数の分割を保証せず、暗黙の乱数や無制限の再試行はない。
例えば `n=21, seed=2, c=1` は失敗するが、`c=2` なら因子3を得る。
退化する `c=0` 等も入力として許し、失敗の再現と検査に使う。
完全な素因数分解を得る再帰driverは、このmilestoneでは含めない。

検証は0〜127の候補と0〜131の因子主張の全組合せ、
2〜63の候補・seed 0〜3・定数0〜3のFloyd状態を整数モデルと照合する。
燃料0、分割再開、一括実行との同一性、退化seed、素数での非受理を調べる。
通常テストにはPython `math.gcd` で独立生成した大きな軌道のfixtureも置く。
100160063を40反復で10007×10009、281479271350267を172反復で
65537×4294967291、1000036000099を478反復で1000033×1000003へ分割し、
直前の燃料では未完了、次の1ステップで該当因子を返すことを照合する。
再生成は同じ `tools/generate_primality.py`、その後 `tools/moon fmt src/primality src/factor`。

同じ環境で `tools/moon bench src/factor --target native --release` を実行した。
入力・機械・燃料の構築を計測外に置き、両方式とも非自明因子の検査まで含む。
比較する試し割りはテスト内の同じ二進算術による素朴な探索。
rhoは固定 `seed=2,c=1`、燃料256であり、この二つで成功した条件の比較である。

| 候補 | rho（平均±標準偏差） | 試し割り（平均±標準偏差） |
| --- | --- | --- |
| 1022117 | 920.43 µs ± 33.30 µs | 4.67 ms ± 264.61 µs |
| 100160063 | 4.15 ms ± 209.46 µs | 68.93 ms ± 6.45 ms |

```text
rho 1022117: 920.43 µs ± 33.30 µs; 862.92 µs … 961.48 µs; 10 × 117 runs
trial 1022117: 4.67 ms ± 264.61 µs; 4.30 ms … 5.16 ms; 10 × 24 runs
rho 100160063: 4.15 ms ± 209.46 µs; 3.92 ms … 4.50 ms; 10 × 28 runs
trial 100160063: 68.93 ms ± 6.45 ms; 62.30 ms … 78.59 ms; 10 × 2 runs
```

## 合成数witnessとしてのMiller–Rabin

`@primality.check_composite(n,witness)` は、非自明因子 `Divisor(d)` または
強いMiller–Rabinの失敗を示す `Strong(base)` を受け取る。
受理した `CompositeProof` の値と証拠は `composite_value`、`composite_witness` で取り出す。
`Strong` は奇数 `n>2` と `1<=base<n` に限る。範囲外のbaseは受理しない。

```moonbit
pub(all) enum CompositeWitness { Divisor(@binary.Binary); Strong(@binary.Binary) }
pub fn check_composite(@binary.Binary, CompositeWitness) -> CompositeProof?
pub(all) enum Screening { Composite(CompositeProof); Inconclusive }
pub fn screen(@binary.Binary, @core.Chain[@binary.Binary]) -> Screening
```

`n−1=2^s*d`（dは奇数）とし、`base^d` が1でもなく、
`base^(2^j*d)` が `0<=j<s` のどこでも−1にならないことを検査する。
奇素数ではこの失敗は起きないので、受理は合成数の証拠になる。
根拠は [HAC Fact 4.20、Definition 4.21、Algorithm 4.24](https://cacr.uwaterloo.ca/hac/about/chap4.pdf)。
この実装は固定baseで確率や誤判定率を主張せず、失敗の片方向だけを使う。

`screen` はまず偶数の非自明因子2を調べ、次に指定baseを順に検査する。
すべて通過、空のbase列、0や1、素数候補は `Inconclusive` を返す。
`Inconclusive` は素数の確定ではなく、`Prime` を構築できない。
例えば2047はbase2、1373653はbase2と3を通過するが、
それぞれbase3、base5を加えると合成数witnessが得られる。

0〜127とbase 0〜`n+1` の全組合せを、独立した整数の直接累乗で照合する。
受理されたものはすべて整数試し割りで合成数となる。
真の素数、範囲外base、空base、Carmichael数561、上記の強い擬素数も検査する。
素数の確定に使う入口は引き続きLucas/Prattの完全なcertificate検査だけである。

同じnative release環境で合成数の確定を比較した（入力/base列の構築を除外）。
比較対象は既存 `@modular.is_prime` の `false`、screen側は根拠付き `Composite`。
1373653=829×1657にはbase2、3を通過させてからbase5で失敗を示し、
100160063=10007×10009にはbase2で失敗を示す。
両方で非自明因子の証拠も独立に受理されることを通常テストで確認する。
この選んだ合成数・baseでの比較であり、任意候補に対する素数判定の性能比較ではない。

| 候補とbase | screen（平均±標準偏差） | 既存試し割り（平均±標準偏差） |
| --- | --- | --- |
| 1373653、2/3/5 | 661.22 µs ± 38.90 µs | 3.28 ms ± 144.56 µs |
| 100160063、2 | 501.36 µs ± 29.69 µs | 61.24 ms ± 2.72 ms |

```text
screen 1373653: 661.22 µs ± 38.90 µs; 607.01 µs … 714.72 µs; 10 × 165 runs
trial 1373653: 3.28 ms ± 144.56 µs; 3.04 ms … 3.49 ms; 10 × 29 runs
screen 100160063: 501.36 µs ± 29.69 µs; 474.68 µs … 562.99 µs; 10 × 201 runs
trial 100160063: 61.24 ms ± 2.72 ms; 58.25 ms … 65.91 ms; 10 × 2 runs
```
