# runを展開せずに計算する二進数

[ドキュメント](../README.md) / [探索・改善記録](README.md)

`runbinary.Number`は、下位から順に`Run{bit,length:Binary}`を並べた正規形を持つ。
長さ0を除去し、隣り合う同じbitを併合し、最上位の0を除く。
たとえば56は0が3個・1が3個の二本で、0は空列になる。
通常の`Binary`は一桁ずつの表現として引き続き使う。

背景となる発想は[Tarauの再帰的run-length算術](https://publications.info.uaic.ro/files/sacs/XXIV2/XXIV2_4.pdf)。
今回の実装は長さを既存Binaryで持つ一段の圧縮であり、論文の再帰的な数体系の移植ではない。
同じbitのblockをまとめて処理する算術を、既存full_adderから独立に組み立てた。

## 加減乗算とペア

同じa,bが続くblockでは、carry/borrowの状態は最初の一桁の後に安定する。
最初の一桁と残りのblockを一度に出力し、短い方のrunの長さだけ両入力を進める。
この局所性はadd/subtractの全Bool条件を列挙して検査する。
比較は総bit幅を先に調べ、同じ幅なら上位から異なるblockを探す。

乗算では、bの各1-run（offset=o、長さ=l）の寄与を
`a * (2^l−1) * 2^o = (a << (o+l)) − (a << o)`
で作る。1bitごとの部分積は生成しない。
一般のrun数や中間結果のrun数が小さい保証はない。

`pair(a,b)=2^a*(2*b+1)`は、指数aもBinaryで受け取り、低位の0をrun一本で保持する。
`unpair`は0-runの長さと低位1の除去から逆算する。
従来のNat指数のpairと同じ自然数を表すが、0列を値の数だけ展開しない。

## 展開できない値の計算

E=2^1000、A=2^E−1を一本のrunとして構築できる。
実際に加算A+1、減算2^E−1、2^Eの二乗、pair/unpairを計算した。
A²の結果は下位から1が1個・0がE個・1がE−1個の三本で、
`1 + 2^(E+1)*(2^(E−1)−1)`と一致する。
`expand(value, maximum_bits)`は幅を先に検査し、上限を越えれば展開せずNoneを返す。
この例に4096bitの上限を与える回帰も置く。

native release、入力と圧縮構築を除外し、意味が同じ演算の結果を保持する10標本比較：

| 入力/処理 | 一桁ずつのBinary | runbinary |
| --- | ---: | ---: |
| 2048bit全1 + 1 | 20.10 µs | 1.18 µs |
| 2048bit全1の二乗 | 学校式64.88 ms / Karatsuba17.32 ms | 2.90 µs |
| 交互bitを含む256bit加算 | 3.01 µs | 39.11 µs |
| 同じ256bitの乗算 | 384.50 µs | 4.65 ms |
| A=2^(2^1000)−1の二乗 | 展開して比較しない | 206.13 µs |

長い同一blockでは大きく改善し、交互bitの多い入力では大幅に悪化した。
この結果から既存Binaryの全面置換は行わず、規則的な値を扱う別の表現として公開する。
CPU固定なし、他agentが動作する環境。一般の数や全backendでの性能を保証しない。
生ログ：[runbinary-native.txt](../measurements/runbinary-native.txt)。

0〜127の全16,384対をnative整数算術と比較し、shift/pair/underflow/正規化/展開上限も検査した。
Pythonの任意精度整数から生成した18組の32〜512bit fixtureは、加減乗除算とshiftを別途照合する。
基本6＋除算3通常テストがWasm GC/JS/nativeで通過。巨大な例は圧縮された式の等式検査であり、
展開した全bitを第三者の整数ライブラリと比べたものではない。

```sh
tools/moon test src/runbinary --target native
tools/moon bench src/runbinary --target native --release
python3 tools/generate_runbinary.py
```

## 展開しないsplit、燃料付き除算

`split_at(value,k)`は下位k bitと残りをrunの境界で分け、
`value=low+(high<<k)`を満たす。kもBinaryなので、幅をNatへ展開する必要がない。
2の冪による除算はこのsplitで一遷移で終わる。
たとえば`2^(2^1000) / 2^(2^999)`を実際に計算し、商が`2^(2^999)`、余り0と照合した。

一般の除算はbit幅から除数を上位へ合わせ、引ける最大の二進位置を商へ足す。
`start_division`/`step_division`/`run_division`は途中状態と燃料を明示し、
`Divided`を返す前に探索と異なる`q*b+r=a`および`0<=r<b`のcheckerを通す。
0除算はconstructorで拒否する。燃料は遷移数で、時間やBool操作数ではない。

圧縮入力から短い出力が得られるとは限らない。
`(2^E−1)/3`の商は長い交互bit列になり得るため、圧縮サイズに対する高速性は主張しない。
E=2^1000の例は3遷移で停止させ、商・残りが元の式を保っていることだけを検査する。
0〜127×除数1〜63の8,064問題、Pythonの18fixture、fuel分割を別に照合した。

専用の`mersenne_gcd`は、非零の全1-run二数について
`gcd(2^a−1,2^b−1)=2^gcd(a,b)−1`を使う。
指数にEuclidを適用して一runの結果を作り、巨大なbit列を生成しない。
根拠は`2^b≡1 mod(2^b−1)`による指数の剰余への縮小である。
一般の入力のGCDをこの関数で代用することはなく、適用できなければNoneを返す。
