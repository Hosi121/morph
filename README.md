# morph

MoonBit の代数的データ型・パターンマッチ・再帰でアルゴリズムを組み立てる実験。
12本の等式による記号FFTを出発点に、二進算術、型推論、計算代数、証拠付き最適化、誤り訂正へ進める。

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
python3 tools/bootstrap_lean.py       # 任意：検証用Leanをローカルへ隔離
tools/check_formal                    # 任意長の加算/Nat変換のLeanモデル
```

検証環境：moonc v0.10.20。グローバルの古い環境は変更しない。
bootstrap を省略した場合、`tools/moon` は PATH 上の moon を使う。
Mooncakes の追加依存はない。公開リポジトリは[Hosi121/morph](https://github.com/Hosi121/morph)。

算法の核・依存・テスト宣言数は、ソースから生成する[一覧](docs/INVENTORY.md)にある。
公開APIの実装と内部への統合は、[呼び出し経路の一覧](docs/CALL_PATHS.md)で区別する。
`tools/check`で制約・整形・警告禁止・Wasm GC/JavaScriptのテスト・公開APIの生成差分を検査する。
nativeは`tools/moon test --target native`で確認する。有限の総当たり、外部オラクル、個別問題の証拠検査であり、
すべての入力に対する形式証明ではない。

| 分野 | 実装と入口 |
| --- | --- |
| 基礎 | [不変リスト・Peano算術・Euclid](src/core/data.mbt) |
| 二進表現 | [算術・連結・pair/unpair](src/binary/binary.mbt)・[Karatsuba](src/binary/karatsuba.mbt)・[Stein GCD・整数平方根・Fibonacci](src/binary/number_theory.mbt) |
| 圧縮二進算術 | [runを展開しない加減乗算・shift・pair](src/runbinary/runbinary.mbt)・[燃料付き除算](src/runbinary/division.mbt) |
| ビット符号 | [Elias gamma・任意精度ペアの自己区切り符号](src/bitcodec/bitcodec.mbt) |
| 厳密数 | [符号付き整数・有理数・非ゼロの証拠](src/exact/exact.mbt) |
| FFT | [画像の12等式に対応するFFTと直接DFT](src/fft/fft.mbt) |
| 円分体・厳密FFT | [円分多項式の正規形・逆元](src/cyclotomic/cyclotomic.mbt)・[正規化されたFFT/逆FFT](src/exactfft/exactfft.mbt) |
| 剰余算術 | [平方反復・拡張Euclid・逆元・素数判定](src/modular/modular.mbt)・[一般化CRT](src/modular/crt.mbt)・[小さなRSA](src/modular/rsa.mbt) |
| 有限体 | [Euler判定・Tonelli–Shanksの剰余平方根](src/finitefield/sqrt.mbt) |
| 素数・因数分解 | [Lucas/Pratt・部分Pocklington証明と合成数証拠](src/primality/primality.mbt)・[燃料付きPollard rho・完全分解検査](src/factor/factor.mbt) |
| 素数証明の生成 | [手書きbankなしの分解・再帰証明・Lucas witness探索](src/primeprove/primeprove.mbt) |
| 有限拡大体 | [検査済み素数からGF(p)](src/primefield/primefield.mbt)・[Berlekamp多項式分解・既約性証拠](src/fppoly/factorization.mbt)・[GF(p^m)・trace/norm](src/galois/galois.mbt) |
| 離散対数 | [baby-step giant-step・最小位数と部分群境界](src/discretelog/discretelog.mbt) |
| 楕円曲線 | [群演算・二進スカラー倍・点の圧縮と復元](src/elliptic/elliptic.mbt) |
| NTT | [有限体変換・逆変換・線形畳み込み](src/ntt/ntt.mbt) |
| 行列 | [半環](src/algebra/algebra.mbt)・[行列積・累乗・Warshall](src/matrix/matrix.mbt) |
| 線形代数 | [有理数の行列式・逆行列・解空間](src/linear/linear.mbt)・[体で共通化したGauss–Jordan](src/rowreduce/rowreduce.mbt) |
| 整数線形代数 | [証拠付きSmith標準形](src/smith/smith.mbt)・[整数解/不可能証拠](src/smith/equations.mbt)・[有限生成アーベル群](src/smith/cokernel.mbt) |
| 格子 | [厳密有理数のLLL・依存基底の前処理・unimodular証拠](src/lll/lll.mbt) |
| 線形最適化 | [二段階単体法・Bland規則・双対解/非有界/Farkas証拠](src/simplex/simplex.mbt) |
| 整数最適化 | [0/1分枝限定法・再開可能なLP緩和・最適性の証拠木](src/zeroone/zeroone.mbt) |
| ソート | [安定merge/insertion/quick sort](src/sorting/sorting.mbt) |
| 優先度キュー | [永続leftist heap・heap sort](src/heap/heap.mbt) |
| 辞書 | [Boolワードの永続trie・最長prefix・union](src/trie/trie.mbt)・[永続AVL・削除・順位と選択](src/avl/avl.mbt) |
| グラフ | [BFS・Dijkstra・経路](src/graph/graph.mbt)・[topological・SCC](src/graph/structure.mbt) |
| 全域森 | [Kruskal・Prim・最小性の証拠検査](src/spanning/spanning.mbt) |
| ネットワーク | [Edmonds–Karp最大流・最小カット・証拠検査](src/maxflow/maxflow.mbt) |
| マッチング | [Hopcroft–Karp・最小頂点被覆・最適性検査](src/bipartite/bipartite.mbt) |
| 動的計画法 | [編集距離・編集手順・LCS](src/dp/sequences.mbt)・[0/1 knapsack](src/dp/knapsack.mbt) |
| 論理 | [DPLL SAT・モデルと反証の検査](src/sat/sat.mbt) |
| 証拠付きSAT | [first-UIP・watch・非時系列backjump・独立RUP検査](src/cdcl/cdcl.mbt) |
| 回路の検証・合成 | [Bool式→CNF・等価性miter](src/circuit/circuit.mbt)・[上限付きNAND合成](src/synthesis/encoding.mbt) |
| BDD | [永続ROBDD・異manager間の演算](src/bdd/apply.mbt)・[厳密モデル数・存在/全称量化](src/bdd/count.mbt) |
| SMT | [差分制約・負閉路の証拠](src/difference/difference.mbt)・[CDCLと整数差分理論の接続](src/smt/smt.mbt) |
| 組合せ探索 | [Algorithm X・primary/secondary列のexact cover](src/exactcover/exactcover.mbt)・[再開可能な全解列挙](src/exactcover/enumerate.mbt) |
| 制約のモデル化 | [Nクイーン](src/puzzles/queens.mbt)・[4×4/9×9数独](src/puzzles/sudoku.mbt) |
| 単一化 | [occurs check・冪等置換](src/unify/unify.mbt) |
| 型推論 | [Hindley–Milner・let多相](src/infer/infer.mbt) |
| 評価機械 | [燃料付き・再開可能なCEK](src/cek/cek.mbt) |
| 正規表現 | [Brzozowski微分](src/regex/derivative.mbt)・[Thompson NFA](src/regex/thompson.mbt) |
| 構文解析 | [CNF文法のCYK・構文木と導出検査](src/cyk/cyk.mbt) |
| 複数語検索 | [Aho–Corasick・failure遷移・チャンクをまたぐ検索](src/aho/aho.mbt) |
| 圧縮 | [Huffman符号・復号](src/huffman/huffman.mbt)・[LZ78・辞書番号とliteralのビット符号](src/lz78/lz78.mbt) |
| ハッシュ | [BoolリストだけのSHA-256](src/sha256/sha256.mbt)・[固定幅ビット演算](src/sha256/word.mbt) |
| AES | [GF(256)からのSbox生成](src/aes/sbox.mbt)・[128/192/256bit鍵のblock暗号・復号](src/aes/cipher.mbt) |
| 誤り訂正 | [Reed–Solomon評価符号・Berlekamp–Welch・消失訂正](src/reedsolomon/reedsolomon.mbt) |
| 漸化式と巡回符号 | [Berlekamp–Massey](src/recurrence/recurrence.mbt)・[Chien/ForneyによるGF(p^m)のRS訂正](src/cyclicrs/cyclicrs.mbt) |
| 多項式 | [有理係数の疎多項式・除算・GCD・偏微分](src/polynomial/polynomial.mbt) |
| 計算代数 | [再開可能なBuchberger・既約Gröbner基底](src/groebner/groebner.mbt) |
| 実代数 | [Sturm列・実根数・有理区間による隔離と精密化](src/sturm/sturm.mbt) |
| 微分 | [式ADTの記号微分・半環解釈](src/autodiff/expression.mbt)・[前向き/逆向き自動微分](src/autodiff/autodiff.mbt) |
| 厳密幾何 | [凸包・線分交差・面積・Bézier評価](src/geometry/geometry.mbt) |

設計、検証範囲、表現コスト、採用理由、限界は [ハンドブック](HANDBOOK.md) に記録する。
性能比較の条件と生ログは [計測記録](docs/MEASUREMENTS.md) にある。
SATから基礎へ戻す反復、独立レビューと棄却案は[bootstrapの記録](docs/bootstrap/TRACE.md)にある。
ツールチェーンとfixture再生成の条件は [検証環境](docs/ENVIRONMENT.md) にある。
Leanモデルの全称定理、実装との対応と限界は[形式検証](formal/README.md)と[独立レビュー](formal/REVIEW.md)にある。
これは数値計算ライブラリの高速化を目的とするものではない。

ツアーは期待値を表示するだけでなく、各アルゴリズムを呼んで結果を表示する。
[実行出力](docs/TOUR.txt)では、Fibonacci(100)、SHA-256、Gröbner基底、
二段階単体法の8/3、Sturmの根隔離、8クイーン92解、逆向きADなどを確認できる。
表示と入力変換は [cmd/main](src/cmd/main/showcase.mbt) にあり、記号計算の核とは別である。
