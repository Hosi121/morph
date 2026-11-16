# morph

MoonBit の代数的データ型・パターンマッチ・再帰でアルゴリズムを組み立てる実験。

計算の核は Bool・Unit・不変リストなどで構成し、組み込み数値型・数値リテラル・数値演算・配列・可変状態・FFI を使わない。
入力変換・表示・テストと、MoonBit のランタイム・暗黙の prelude はこの制約の対象外。

## 動かす

```sh
tools/bootstrap              # 初回：公式の最新ツールチェーンを .tools へ配置
tools/moon run src/cmd/main   # 各算法を実行するツアー
tools/check                  # 制約・整形・型・Wasm GC/JS テスト・公開API差分
```

Python 3 と MoonBit を使用する。Mooncakes の追加依存はない。
確認済みのコンパイラは moonc v0.10.20。ツールチェーンの再現条件は[検証環境](docs/ENVIRONMENT.md)を参照。
ツアーでは Fibonacci(100)、SHA-256、Gröbner基底、単体法、8クイーンなどを実行する（[実装](src/cmd/main/showcase.mbt)・[出力例](docs/TOUR.txt)）。

## 実装カテゴリ

| カテゴリ | 主な実装 |
| --- | --- |
| [基礎算術・データ構造](docs/ALGORITHMS.md#foundations) | Peano自然数、二進算術、ペア、有理数、ソート、永続木 |
| [数論・有限体](docs/ALGORITHMS.md#number-theory) | CRT、素数証明、因数分解、拡大体、離散対数、楕円曲線 |
| [変換・記号計算](docs/ALGORITHMS.md#symbolic-computation) | FFT・NTT、円分体、Gröbner基底、実根隔離、自動微分、厳密幾何 |
| [線形代数・最適化](docs/ALGORITHMS.md#linear-optimization) | Gauss–Jordan、Smith標準形、LLL、単体法、0/1分枝限定法 |
| [グラフ](docs/ALGORITHMS.md#graphs) | 最短路、SCC、最小全域森、最大流、二部マッチング |
| [論理・制約解決](docs/ALGORITHMS.md#logic-constraints) | SAT・CDCL・SMT、BDD、回路検証・合成、exact cover、数独 |
| [言語・列アルゴリズム](docs/ALGORITHMS.md#languages-sequences) | 単一化、型推論、CEK、正規表現、CYK、文字列検索、動的計画法 |
| [符号・圧縮・暗号](docs/ALGORITHMS.md#coding-cryptography) | 自己区切り符号、Huffman、LZ78、SHA-256、AES、Reed–Solomon |

各カテゴリのリンク先に、個別の算法とソースへの入口をまとめている。

## 開発・検証

```sh
tools/moon test src/fft                                  # パッケージを指定
tools/moon test --target native                          # nativeの全テスト
tools/moon bench src/benchmarks --target native --release # ベンチマーク
```

テストは有限の総当たり・独立オラクル・問題ごとの証拠検査を組み合わせる。
基礎ADTには別途[Leanモデルの証明](formal/README.md)があり、対象・実行手順・実装との対応範囲を記録している。

## 設計と記録

| 資料 | 内容 |
| --- | --- |
| [ハンドブック](HANDBOOK.md) | 算法の設計、表現コスト、考察、限界 |
| [パッケージ一覧](docs/INVENTORY.md) | ソースから生成した依存関係・テスト宣言数 |
| [共有kernel](docs/KERNELS.md)・[呼び出し経路](docs/CALL_PATHS.md) | 基礎部品の採否、通常経路への統合状況 |
| [計測記録](docs/MEASUREMENTS.md) | 性能比較の条件と生ログ |
| [bootstrapの記録](docs/bootstrap/TRACE.md) | SATを検証・合成に使い、基礎と上位算法を改善する反復 |
