# 計測記録

## 2026-11-15：Warshall の一列抽出

比較条件：同じローカル環境、moon 0.1.20261104 / moonc v0.10.20、native release。
入力は24頂点、対角true、それ以外は `(i*17+j*7)%11<2` のBool隣接行列。
入力構築と型の検査は計測範囲外。各10サンプル、ベンチランナーがbatch数を調整。

| 実装 | 平均 | 標準偏差 | 範囲 |
| --- | ---: | ---: | ---: |
| 各pivotで全行列を転置 | 665.55 µs | 19.98 µs | 645.09–704.07 µs |
| 必要な一列だけ抽出 | 361.14 µs | 10.78 µs | 348.26–378.28 µs |

この入力では約45.7%短縮、約1.84倍。正確さ、入力、半環、表現、backendを維持した比較。
全用途・他backend・大規模グラフで同じ比率になるという主張ではない。
一列を得るために作る中間リストの要素数を、pivot全体で O(n³) から O(n²) に減らした。
行列更新自体の O(n³) は変わらない。

生ログ：[変更前](measurements/warshall-before.txt)、[変更後](measurements/warshall-after.txt)。
変更前の核は `6ca4675`。再現コマンド：

```sh
tools/moon bench src/benchmarks --target native --release
```

## 2026-11-15：冪等置換の値域を共有する

同じ native release 環境。深さ6の共有された二分項（木として展開すると127ノード）へ
一変数を束縛した置換を、事前に作成しておく。その変数への apply だけを計測した。
置換作成・値域の正規化は計測範囲外。各10サンプル。

| 実装 | 平均 | 標準偏差 |
| --- | ---: | ---: |
| 束縛値を再帰走査して再構築 | 2.69 µs | 41.22 ns |
| 正規化済みの束縛値を共有 | 9.08 ns | 1.11 ns |

この参照操作だけでは約300倍。型推論全体や単一化全体の速度比ではない。
前提は、置換のどの値域にも置換の定義域の変数が残っていないこと。
bind が新しい束縛を全既存値域へ合成するため、値域の再走査を省ける。
この不変条件を、単一化が成功する全有限項ペアのテストで明示的に確認した。

生ログ：[変更前](measurements/unify-before.txt)、[変更後](measurements/unify-after.txt)。
変更前の核は `d96d4f9`。再現：

```sh
tools/moon bench src/benchmarks/unify_test.mbt --target native --release
```

## 2026-11-15：Buchberger の積判定

同じ native release、各10サンプル。入力構築は範囲外で、基底計算全体を測定。
比較前の核は `79c4fb1`。

| 三変数の入力系 | 全Sペアを除算 | 先頭単項式が互いに素なら省略 |
| --- | ---: | ---: |
| x²−1, y²−1, z²−1 | 18.51 µs ± 0.41 µs | 4.48 µs ± 0.14 µs |
| xy−z, yz−x, zx−y | 184.06 µs ± 4.62 µs | 111.19 µs ± 1.69 µs |

この二系では約75.8% / 39.6%短縮。Buchberger の product criterion により、
先頭単項式の支持が交わらないペアのS多項式は生成・除算せずに処理済みにできる。
全45系の SymPy fixture とS多項式検証を維持した。一般の系での速度比ではない。
燃料は省略したペアも一回と数え、予算の意味を維持する。

生ログ：[変更前](measurements/groebner-before.txt)、[変更後](measurements/groebner-after.txt)。

```sh
tools/moon bench src/benchmarks/groebner_test.mbt --target native --release
```

## 2026-11-15：学校式と Karatsuba の二進乗算

同じ canonical Bool リスト、native release、各10サンプル。
入力構築を除外し、生成された積を保持する。Karatsuba は64ビット以下の片方の入力が
あれば学校式へ切り替える。入力のビットパターンは benchmark ソースに固定。

| 桁数 | 学校式 | Karatsuba |
| --- | ---: | ---: |
| 128 | 155.45 ± 4.67 µs | 151.66 ± 2.58 µs |
| 512 | 2.63 ± 0.03 ms | 1.48 ± 0.04 ms |
| 2048 | 41.57 ± 0.71 ms | 13.45 ± 0.24 ms |

128桁では差が小さく、明確な優位とは判定しない。この入力では512桁で約1.78倍、
2048桁で約3.09倍。短い整数の標準 API はそのままにし、大きい値には `karatsuba` を明示して選べる。
他backendや疎なビット列で同じ比率になるという主張ではない。

生ログ：[比較](measurements/karatsuba.txt)。

```sh
tools/moon bench src/benchmarks/multiply_test.mbt --target native --release
```
