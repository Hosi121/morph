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
