<p align="center">
  <img src="assets/brand/morph-logo.png" alt="morph" width="280">
</p>

<p align="center">
  <strong>データ型と再帰で計算する、MoonBitのアルゴリズム集。</strong>
</p>

<p align="center">
  <a href="docs/ALGORITHMS.md">アルゴリズム一覧</a> ·
  <a href="docs/README.md">ドキュメント</a> ·
  <a href="docs/TOUR.txt">実行例</a>
</p>

自然数は `Zero` と `Succ`、二進数は Bool の不変リストで表現します。
値の構造をパターンマッチで分解し、再帰によって演算や探索を組み立てます。

## 試す

MoonBit と Python 3 を使用します。Mooncakes の追加依存はありません。
初回は `tools/bootstrap` で公式の最新ツールチェーンを `.tools` に配置します。

```sh
tools/bootstrap
tools/moon run src/cmd/main
```

Fibonacci(100)、SHA-256、Gröbner基底、単体法、8クイーンなどをまとめて試せます。
表示と入力変換の実装は [cmd/main](src/cmd/main/showcase.mbt) にあります。
確認済みのコンパイラは moonc v0.10.20 です。再現条件は[検証環境](docs/ENVIRONMENT.md)を参照してください。

## アルゴリズム

| カテゴリ | 主な実装 |
| --- | --- |
| [基礎算術・データ構造](docs/ALGORITHMS.md#foundations) | Peano自然数、二進算術、ペア、有理数、ソート、永続木 |
| [数論・有限体](docs/ALGORITHMS.md#number-theory) | CRT、素数証明、因数分解、拡大体、離散対数、楕円曲線 |
| [変換・記号計算](docs/ALGORITHMS.md#symbolic-computation) | FFT・NTT、円分体、Gröbner基底、実根隔離、自動微分、厳密幾何 |
| [線形代数・最適化](docs/ALGORITHMS.md#linear-optimization) | Gauss–Jordan、Smith標準形、LLL、単体法、0/1分枝限定法 |
| [グラフ](docs/ALGORITHMS.md#graphs) | 最短路、SCC、最小全域森、最大流、一般マッチング |
| [論理・制約解決](docs/ALGORITHMS.md#logic-constraints) | SAT・SMT、BDD、回路、実数制約、パリティゲーム |
| [言語・列アルゴリズム](docs/ALGORITHMS.md#languages-sequences) | 単一化、型推論、CEK、正規表現、CYK、文字列検索、動的計画法 |
| [符号・圧縮・暗号](docs/ALGORITHMS.md#coding-cryptography) | 自己区切り符号、Huffman、LZ78、SHA-256、AES、Reed–Solomon |

各カテゴリから、個別のアルゴリズムとソースへ進めます。

## 実装方針と検証

手書きの計算核は Bool・Unit・独自の不変リスト・代数的データ型で構成します。
組み込み数値型・数値リテラル・数値演算・配列・可変状態・FFI は使いません。
この制約は計算核に適用し、入力変換・表示・テスト、MoonBit のランタイムや暗黙の prelude は対象に含めません。

`tools/check` で実装制約、整形、型、Wasm GC・JSのテスト、公開APIの差分を検査します。

```sh
tools/check
tools/moon test --target native                          # nativeの全テスト
tools/moon test src/fft                                   # パッケージを指定
tools/moon bench src/benchmarks --target native --release  # ベンチマーク
```

正しさは、有限の総当たり、独立した実装との照合、問題ごとの証拠検査で確かめます。
一部の基礎演算は Lean モデルでも証明しています。各検査の対象と限界は[検証ガイド](docs/VALIDATION.md)にまとめています。

## 詳しく読む

| 資料 | 内容 |
| --- | --- |
| [ハンドブック](HANDBOOK.md) | アルゴリズムの設計、表現コスト、考察、限界 |
| [パッケージ一覧](docs/INVENTORY.md) | ソースから生成した依存関係・テスト宣言数 |
| [基礎部品の最適化](docs/KERNELS.md)・[呼び出し経路](docs/CALL_PATHS.md) | 改善の採否と、通常経路への統合状況 |
| [計測記録](docs/MEASUREMENTS.md) | 性能比較の条件と生ログ |
| [bootstrapの記録](docs/bootstrap/TRACE.md) | SATによる検証・合成を使った、基礎部品と上位アルゴリズムの改善 |
