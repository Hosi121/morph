# Integer/Rationalの同条件最適化

ユーザーの2026-11-15の優先指示に従い、上位算法の追加を止めて基礎算術を計測する。
基点はnumber-theory-nextの `ed68ad4`。src/exactはその時点のmainと同一で、
既存の交差約分とRationalの0/±1恒等則を維持する。
値・精度・公開API・純ADT制約を変えない。

## 変更前の位置特定

native perfは導入されていないため、Node v24.13.0のCPU samplingを使って
LLLの4つの固定benchmarkから呼ばれる算術を調べた。採用する速度比較は別途nativeで行う。
4221 samples、sampled時間5.206267秒。再帰した同名functionのinclusive集計は
1sampleにつき1回として数え、互いに重なるinclusive値を加算しない。

| function | self | inclusive |
| --- | --- | --- |
| binary.divide_bits | 1.373151 s | 2.249850 s |
| binary.compare_bits | 0.404345 s | 0.404345 s |
| binary.subtract_bits | 0.392519 s | 0.409893 s |
| binary.multiply_bits | 0.344716 s | 0.454299 s |
| GC | 0.318514 s | 0.318514 s |
| exact.rational_add | 0.175419 s | 2.333349 s |
| exact.common_factor | 0.093970 s | 1.439904 s |
| binary.gcd | 0.005747 s | 1.343709 s |
| exact.exact_quotient | 0.001168 s | 0.917750 s |

このprofileはJS backendと指定benchmarkの内訳であり、nativeの割合や一般の利用頻度とは同一視しない。
profileからは、交差約分後もGCDとexact quotientが多くの長除算を呼ぶことが分かる。
コードを確認すると、normalizeはGCD=1の後も長除算を2回行い、halfも既約性を使わず再GCDする。
Rational比較は符号が違う場合や共通denomでも交差積を作る。

再現用buildとprofileの入口は次の通り。生成driverのfilter引数は `--build-only` の出力を使う。

```sh
tools/moon bench src/lll --target js --release --build-only
node --cpu-prof --cpu-prof-dir=/tmp/morph-exact-profile-before \
  --cpu-prof-name=lll-before.cpuprofile \
  _build/js/release/bench/lll/lll.whitebox_test.js \
  '{"package":"Hosi121/morph/lll","file_and_index":[["bench_wbtest.mbt",[{"start":0,"end":4}]]]}'
```

## nativeの予備baseline（affinity未固定）

2026-11-15、Intel Core Ultra 7 255H、x86_64、moonc v0.10.20。
入力の構築を除外し、同じ固定fixtureとrelease設定を変更後にも使う。
共有ホストの同時負荷・CPU周波数は固定していない。

| microbenchmark | 変更前の平均±標準偏差 |
| --- | --- |
| coprime 128bit normalize | 36.04 µs ± 1.11 µs |
| shared 127bit factor normalize | 133.00 µs ± 6.11 µs |
| even numerator half | 62.82 µs ± 3.59 µs |
| odd numerator half | 77.51 µs ± 3.33 µs |
| shared denominator add | 68.99 µs ± 3.71 µs |
| coprime denominator add control | 260.66 µs ± 39.22 µs |
| opposite sign compare | 14.95 µs ± 2.35 µs |
| common denominator compare | 27.26 µs ± 2.96 µs |
| reciprocal cross-cancel product | 186.35 µs ± 15.09 µs |
| signed 0/unit corpus | 21.49 µs ± 1.49 µs |

| 上位の同入力baseline | 変更前の平均±標準偏差 |
| --- | --- |
| LLL 3x3生成/検査 | 350.53 µs ± 11.39 µs |
| LLL 3x3 checker | 27.33 µs ± 820.21 ns |
| LLL 3x4生成/検査 | 405.65 µs ± 7.74 µs |
| Smith+LLL依存3x4 | 308.80 µs ± 13.24 µs |

専用の `src/exactbench` はbenchmarkだけを持ち、共有する上位算法を変更しない。
Smith/simplexの固定ケースもここから同じ形で計測する。

## 採用比較用CPU8 baseline

rootのbinary計測をCPU4へ分離する指示に合わせ、exact核を変更する前に
全比較対象を `taskset -c 8` で取り直した。変更後も同じCPU8を使い、
この表を採用比較のbeforeとする。binaryの変更とは分離して測る。
affinityは固定したが、周波数・共有キャッシュ・他CPUの同時負荷は固定していない。

```sh
taskset -c 8 tools/moon bench src/exact --target native --release
taskset -c 8 tools/moon bench src/lll --target native --release
taskset -c 8 tools/moon bench src/exactbench --target native --release
```

| CPU8の固定microbenchmark | before平均±標準偏差 |
| --- | --- |
| coprime normalize | 40.96 µs ± 5.21 µs |
| shared factor normalize | 151.92 µs ± 5.00 µs |
| even half | 75.38 µs ± 11.40 µs |
| odd half | 90.50 µs ± 2.86 µs |
| common denominator add | 72.77 µs ± 3.11 µs |
| coprime add control | 255.42 µs ± 4.08 µs |
| opposite sign compare | 8.03 µs ± 282.14 ns |
| common denominator compare | 11.23 µs ± 815.85 ns |
| reciprocal product | 123.60 µs ± 6.57 µs |
| signed corpus | 21.06 µs ± 2.10 µs |

| CPU8の上位同入力 | before平均±標準偏差 |
| --- | --- |
| LLL 3x3 | 367.58 µs ± 15.31 µs |
| LLL checker | 29.14 µs ± 2.38 µs |
| LLL 3x4 | 451.30 µs ± 30.22 µs |
| Smith+LLL依存3x4 | 322.86 µs ± 12.04 µs |
| Smith 3x3 | 41.25 µs ± 1.37 µs |
| Smith checker | 17.49 µs ± 585.55 ns |
| simplex | 44.89 µs ± 3.32 µs |
