# morph

MoonBit の代数的データ型・パターンマッチ・再帰でアルゴリズムを組み立てる実験。
12本の等式による記号FFTを出発点に、二進算術から型推論まで進める。

手書きの核では、組み込み数値型・数値リテラル・数値演算・配列・可変状態・FFI を使わない。
Bool、Unit、独自の不変リスト、直和型・直積型から構成する。
テストと表示アダプターは独立した数値オラクルとして Int や配列を使う。
MoonBit のランタイムや暗黙の prelude まで排除する主張ではない。

```sh
tools/bootstrap                      # 初回：公式配布を .tools へ隔離
tools/moon run src/cmd/main           # 実際の結果を表示するツアー
tools/check                          # 制約・整形・型・Wasm GC/JS テスト
tools/moon test src/fft               # 特定パッケージだけ試す
tools/moon bench src/benchmarks --target native --release
```

検証環境：moonc v0.10.20。グローバルの古い環境は変更しない。
bootstrap を省略した場合、`tools/moon` は PATH 上の moon を使う。
Mooncakes の追加依存はない。外部公開はしていない。

| 分野 | 実装と入口 |
| --- | --- |
| 基礎 | [不変リスト・Peano算術・Euclid](src/core/data.mbt) |
| 二進表現 | [算術・連結・pair/unpair](src/binary/binary.mbt)・[Karatsuba](src/binary/karatsuba.mbt)・[Stein GCD・整数平方根・Fibonacci](src/binary/number_theory.mbt) |
| ビット符号 | [Elias gamma・任意精度ペアの自己区切り符号](src/bitcodec/bitcodec.mbt) |
| 厳密数 | [符号付き整数・有理数・非ゼロの証拠](src/exact/exact.mbt) |
| FFT | [画像の12等式に対応するFFTと直接DFT](src/fft/fft.mbt) |
| 剰余算術 | [平方反復・拡張Euclid・逆元・素数判定](src/modular/modular.mbt)・[一般化CRT](src/modular/crt.mbt)・[小さなRSA](src/modular/rsa.mbt) |
| NTT | [有限体変換・逆変換・線形畳み込み](src/ntt/ntt.mbt) |
| 行列 | [半環](src/algebra/algebra.mbt)・[行列積・累乗・Warshall](src/matrix/matrix.mbt) |
| 線形代数 | [Gauss–Jordan・行列式・逆行列・解空間](src/linear/linear.mbt) |
| 線形最適化 | [二段階単体法・Bland規則・双対解/非有界/Farkas証拠](src/simplex/simplex.mbt) |
| ソート | [安定merge/insertion/quick sort](src/sorting/sorting.mbt) |
| 優先度キュー | [永続leftist heap・heap sort](src/heap/heap.mbt) |
| 辞書 | [Boolワードの永続trie・最長prefix・union](src/trie/trie.mbt) |
| グラフ | [BFS・Dijkstra・経路](src/graph/graph.mbt)・[topological・SCC](src/graph/structure.mbt) |
| 全域森 | [Kruskal・Prim・最小性の証拠検査](src/spanning/spanning.mbt) |
| ネットワーク | [Edmonds–Karp最大流・最小カット・証拠検査](src/maxflow/maxflow.mbt) |
| 動的計画法 | [編集距離・編集手順・LCS](src/dp/sequences.mbt)・[0/1 knapsack](src/dp/knapsack.mbt) |
| 論理 | [DPLL SAT・モデルと反証の検査](src/sat/sat.mbt) |
| 組合せ探索 | [Algorithm X・primary/secondary列のexact cover](src/exactcover/exactcover.mbt)・[再開可能な全解列挙](src/exactcover/enumerate.mbt) |
| 制約のモデル化 | [Nクイーン](src/puzzles/queens.mbt)・[4×4/9×9数独](src/puzzles/sudoku.mbt) |
| 単一化 | [occurs check・冪等置換](src/unify/unify.mbt) |
| 型推論 | [Hindley–Milner・let多相](src/infer/infer.mbt) |
| 評価機械 | [燃料付き・再開可能なCEK](src/cek/cek.mbt) |
| 正規表現 | [Brzozowski微分](src/regex/derivative.mbt)・[Thompson NFA](src/regex/thompson.mbt) |
| 構文解析 | [CNF文法のCYK・構文木と導出検査](src/cyk/cyk.mbt) |
| 圧縮 | [Huffman符号・復号](src/huffman/huffman.mbt) |
| ハッシュ | [BoolリストだけのSHA-256](src/sha256/sha256.mbt)・[固定幅ビット演算](src/sha256/word.mbt) |
| 多項式 | [有理係数の疎多項式・除算・GCD・偏微分](src/polynomial/polynomial.mbt) |
| 計算代数 | [再開可能なBuchberger・既約Gröbner基底](src/groebner/groebner.mbt) |
| 実代数 | [Sturm列・実根数・有理区間による隔離と精密化](src/sturm/sturm.mbt) |
| 微分 | [式ADTの記号微分・半環解釈](src/autodiff/expression.mbt)・[前向き/逆向き自動微分](src/autodiff/autodiff.mbt) |
| 厳密幾何 | [凸包・線分交差・面積・Bézier評価](src/geometry/geometry.mbt) |

設計、検証範囲、表現コスト、採用理由、限界は [ハンドブック](HANDBOOK.md) に記録する。
性能比較の条件と生ログは [計測記録](docs/MEASUREMENTS.md) にある。
これは数値計算ライブラリの高速化を目的とするものではない。

ツアーは期待値を表示するだけでなく、各アルゴリズムを呼んで結果を表示する。
[実行出力](docs/TOUR.txt)では、Fibonacci(100)、SHA-256、Gröbner基底、
二段階単体法の8/3、Sturmの根隔離、8クイーン92解、逆向きADなどを確認できる。
表示と入力変換は [cmd/main](src/cmd/main/showcase.mbt) にあり、記号計算の核とは別である。
