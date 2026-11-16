# 証明を受け取る素数判定

[ドキュメント](../README.md) / [探索・改善記録](README.md)

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

## 初版の同条件の検査コスト

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

## 重複する素因数の合同検査を共有する

初版の65537の結果から、`p−1=2^16` に対して同じ合同累乗を16回検査することが
支配的なコストになると考えた。checker内で、そのノードですでに合同条件を確認した
素数値を不変リストに記録し、同じ値の合同式だけ再利用する。
子の証明の再帰検査と、重複込みの完全分解の確認は毎回行う。
同じ素数値を名乗る不正な重複子を後ろに置いた場合も拒否する。
公開APIと証明の受理条件は変更しない。

変更直前の `4d90966` と変更後を、同じnative releaseベンチ・fixtureで比較した。
測定対象は証明検査のみ。16回・23回含まれていた素因数2の合同累乗が各1回となる。
共有ホスト上の実時間測定であり、同時負荷やCPUの周波数は固定していない。

| 候補 | 変更直前 | 重複合同式の共有後 | 同時に再測定した試し割り |
| --- | --- | --- | --- |
| 65537 | 1.13 ms ± 27.88 µs | 160.79 µs ± 8.15 µs | 737.72 µs ± 28.66 µs |
| 998244353 | 15.74 ms ± 630.47 µs | 2.47 ms ± 103.22 µs | 239.30 ms ± 5.55 ms |

```text
before Lucas 65537: 1.13 ms ± 27.88 µs; 1.10 ms … 1.20 ms; 10 × 91 runs
before trial 65537: 644.15 µs ± 10.81 µs; 629.56 µs … 660.20 µs; 10 × 155 runs
before Lucas 998244353: 15.74 ms ± 630.47 µs; 14.96 ms … 16.69 ms; 10 × 7 runs
before trial 998244353: 246.73 ms ± 10.01 ms; 233.33 ms … 264.72 ms; 10 × 1 runs
after Lucas 65537: 160.79 µs ± 8.15 µs; 145.82 µs … 169.53 µs; 10 × 670 runs
after trial 65537: 737.72 µs ± 28.66 µs; 701.91 µs … 773.53 µs; 10 × 127 runs
after Lucas 998244353: 2.47 ms ± 103.22 µs; 2.37 ms … 2.68 ms; 10 × 41 runs
after trial 998244353: 239.30 ms ± 5.55 ms; 232.66 ms … 250.73 ms; 10 × 1 runs
```

## 完全素因数分解の証拠境界

`@factor.check_factorization(n,certificates)` は素数証明の列を検査し、
その重複込みの積がちょうど `n` である場合だけ `Factorization` を返す。
`factorization_value` で元の値、`prime_factors` で検査済み `Prime` の列を得る。
並び替えは行わず、渡した順序と重複を保つ。
1の空分解は受理し、0には完全素因数分解を与えない。

```moonbit
pub fn check_factorization(
  @binary.Binary,
  @core.Chain[@primality.Certificate],
) -> Factorization?
pub fn factorization_value(Factorization) -> @binary.Binary
pub fn prime_factors(Factorization) -> @core.Chain[@primality.Prime]
```

ここにも探索は含まない。各certificateをLucas/Prattで検査し、残りの商を
その素数で割り切れることを確認し、最後が1かを確認する。
`Split` や強いMiller–Rabinの全通過だけでは、この型は構築できない。
因子不足、余分な因子、割り切れない因子、積だけは合う合成数の偽証明を拒否する。

小さな重複・順序を含む積、0と1、不正証拠を検査するほか、rhoが得た大きい三つの
分割にも各leafの再帰素数証明を付け、完全分解として検査する。
これにより281479271350267についても、単なる二数への分割から
65537と4294967291の**確定した素数**への分解へ進める。
通常テストはコミット済みfixtureを使い、その再生成も同じPythonツールで行う。

## 有限の計画で再帰分割するdriver

`factor_search(n,bank,seeds)` は、証明の候補列と有限の `(seed,c)` 列を受け取る。
未処理の因子に合う素数証明がbankにあれば検査して確定し、なければrhoで分割する。
rhoの失敗では、その因子について次の明示seedへ移る。
全seedが失敗、または未証明の因子にseedを与えていない場合は `Exhausted` で止まる。
次の因子には同じ有限seed列を最初から使う。

```moonbit
pub fn factor_search(
  @binary.Binary,
  @core.Chain[@primality.Certificate],
  @core.Chain[(@binary.Binary, @binary.Binary)],
) -> Search?
pub fn search_step(Search) -> SearchStatus
pub fn search_run(Search, @core.Nat) -> SearchStatus
pub(all) enum SearchStatus {
  Complete(Factorization)
  Searching(Search)
  Exhausted(Search)
}
```

`Searching` は燃料切れの継続状態であり、同じ `search_run` でそのまま再開する。
`Exhausted` は計画が尽きた状態なので、燃料だけ足しても進まない。
`retry_search(search,additional_certificates,seeds)` で証拠を追加し、seed列を明示的に
置き換える。完了した素数leafは保ち、動いていた軌道があればその対象だけ再初期化する。
`unresolved` と `proven_certificates` から途中の未処理因子と検査済み証明を取り出せる。
途中では「検査済みleafの積 × 未処理因子の積 = 元のn」を保つ。

燃料1はschedulerの1処理（leaf選択・証明bankの照合・rho初期化・rho1反復・完了確認）。
bankに含まれるcertificateを検査する内部コストは、燃料1で固定されるわけではない。
`Complete` の直前には独立の `check_factorization` で全証明と積を再検査する。
bankの誤証明、未証明の素数、Miller–Rabinを通過しただけの値は確定leafにしない。
このdriver自身は新しい素数証明を発見しないため、任意入力の完全分解を保証しない。

小さな分解では、複数seedへの移行、燃料の分割と一括実行の同一性、
すべての途中境界での積の不変条件、枯渇状態の安定性、証拠とseedを追加した再開を検査する。
例えば22を2×11へ分割しても、11の証明がなければ2の証明だけを保持して止まる。
正しい11の証明を追加すると、先の進捗を保って完全分解へ進む。
大きい三つのsemiprimeも、生成済みbankと `(2,1)` の計画・燃料512で再帰分割から
両leafの素数証明まで到達することを検査する。

## 部分分解を使うPocklingtonの入口

`@primality.check_pocklington(n,a,children)` は既存のcertificate型を変更せず、
`n−1` の一部の素因数だけを受け取って `Prime?` を返す。
奇数 `n>2` を要求し、すべての子を既存Lucas checkerで再帰検査する。
子の値の重複込みの積 `F` が `n−1` を割り、保守的な閾値 `F²>n` を満たすことを確認する。
合同条件は `a^(n−1)≡1` と、各異なる素因数 `q` に対する
`gcd(a^((n−1)/q)−1,n)=1`。ここではLucasの単なる不等式では足りない。

根拠は [HAC Fact 4.40](https://cacr.uwaterloo.ca/hac/about/chap4.pdf)。
この条件により、`n` の各素因数 `r` について `F` が `r−1` を割るので `r>F`。
`F²>n` なら合成数の最小素因数が平方根以下にあることと矛盾し、`n` は素数となる。
HACの閾値より強い条件を使い、境界の取り違えを避ける。

65537には2の子9個（`F=512`）で足り、998244353には15個（`F=32768`）で足りる。
同じ部分木を完全Lucasに渡すと、欠けた分解なので拒否される。
不足するF、過剰/非約数の因子、不正な子、誤witnessはPocklingtonでも拒否する。
小さい候補とすべての因子prefix・witnessを整数の独立条件と照合し、受理された候補は
独立した試し割りでも必ず素数となることを確認する。

必要なGCD条件の回帰例は561、witness 5、`F=2^4*5=80`。
この合成数はFの大きさとFermat条件を満たし、q=2、5での累乗も両方1ではないが、
それぞれ差のGCDは33、51となるため、Pocklingtonでは拒否される。
これは部分分解に完全Lucasの不等式を流用すると誤受理し得る具体例である。

同じnative release計測で998244353を比較すると、完全Lucas検査は
2.59 ms ± 152.62 µs、部分Pocklingtonは1.33 ms ± 48.44 µs。
入力/証明木の構築は除外し、既知の異なる証拠を使って同じ素数を厳密に確定する比較である。
証明の探索コストや任意入力での改善を示さない。

```text
Lucas 998244353: 2.59 ms ± 152.62 µs; 2.41 ms … 2.85 ms; 10 × 41 runs
Pocklington 998244353: 1.33 ms ± 48.44 µs; 1.26 ms … 1.39 ms; 10 × 69 runs
```
