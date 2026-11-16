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

morph は、代数的データ型（ADT）と再帰で計算する MoonBit のアルゴリズム集です。
自然数は `Zero` と `Succ`、二進数は Bool の不変リストで表し、
値の構造をパターンマッチで分解して演算や探索を組み立てます。

## 試す

MoonBit、Python 3、Bash を使用します。Mooncakes の追加依存はありません。
初回は `tools/bootstrap` で公式配布のツールチェーンを `.tools` に配置します。

```sh
tools/bootstrap
tools/moon run src/cmd/main
```

| 実行する内容 | コマンド | 出力例 |
| --- | --- | --- |
| Fibonacci(100)、SHA-256、Gröbner基底、単体法、8クイーン | `tools/moon run src/cmd/main` | [基本ツアー](docs/TOUR.txt) |
| 代数的数、数体、F4/FGLM、実解列挙、μ-calculus | `tools/moon run src/cmd/advanced` | [厳密代数とモデル検査](docs/ADVANCED_TOUR.txt) |
| 実閉体の量化消去、球の射影、三段平方根、非線形SMT | `tools/moon run src/cmd/realclosed` | [実閉体と非線形SMT](docs/REALCLOSED_TOUR.txt) |
| 複素数の厳密演算、全根、複素数体と一生成元への変換 | `tools/moon run src/cmd/complex` | [複素代数](docs/COMPLEX_TOUR.txt) |
| 明示した分解体の自己同型、部分群と固定体 | `tools/moon run src/cmd/galois` | [対称性と中間体](docs/GALOIS_TOUR.txt) |

準備・テストのコマンドと検証済みのツールチェーンは[開発・検証環境](docs/ENVIRONMENT.md)にあります。
表示と入力変換の例は [cmd/main](src/cmd/main/showcase.mbt) を参照してください。

## アルゴリズム

| カテゴリ | 主な実装 |
| --- | --- |
| [基礎算術・データ構造](docs/ALGORITHMS.md#foundations) | Peano自然数、二進算術、ペア、有理数、ソート、永続木 |
| [数論・有限体](docs/ALGORITHMS.md#number-theory) | CRT、素数証明、因数分解、拡大体、離散対数、楕円曲線 |
| [変換・記号計算](docs/ALGORITHMS.md#symbolic-computation) | FFT・NTT、円分体、Gröbner基底、実根隔離、自動微分、厳密幾何 |
| [線形代数・最適化](docs/ALGORITHMS.md#linear-optimization) | Gauss–Jordan、Smith標準形、LLL、単体法、0/1分枝限定法 |
| [グラフ](docs/ALGORITHMS.md#graphs) | 最短路、SCC、最小全域森、最大流、一般マッチング |
| [論理・制約解決](docs/ALGORITHMS.md#logic-constraints) | SAT・非線形実数SMT、BDD、回路、実閉体の量化消去、パリティゲーム |
| [言語・列アルゴリズム](docs/ALGORITHMS.md#languages-sequences) | 単一化、型推論、CEK、正規表現、CYK、文字列検索、動的計画法 |
| [符号・圧縮・暗号](docs/ALGORITHMS.md#coding-cryptography) | 自己区切り符号、Huffman、LZ78、SHA-256、AES、Reed–Solomon |

各カテゴリから、個別のアルゴリズムとソースへ進めます。

## 実装方針と検証

手書きの計算核は Bool・Unit・独自の不変リスト・代数的データ型で構成します。
組み込み数値型・数値リテラル・数値演算・配列・可変状態・FFI は使いません。
この制約は計算核に適用し、入力変換・表示・テスト、MoonBit のランタイムや暗黙の prelude は対象に含めません。

`tools/check` で実装制約、整形、型、WasmGC・JSのテスト、公開APIの差分を検査します。

```sh
tools/check
tools/moon test --target native  # nativeの全テスト
```

正しさは、有限の総当たり、独立した実装との照合、問題ごとの証拠検査で確かめます。
一部の基礎演算は Lean モデルでも証明しています。各検査の対象と限界は[検証ガイド](docs/VALIDATION.md)にまとめています。

## 詳しく読む

| 資料 | 内容 |
| --- | --- |
| [ハンドブック](HANDBOOK.md) | アルゴリズムの設計、表現コスト、考察、限界 |
| [到達点と次の候補](docs/ROADMAP.md) | 実装済みの実数制約ソルバと、残る課題 |
| [パッケージ一覧](docs/INVENTORY.md) | ソースから生成した依存関係・テスト宣言数 |
| [基礎部品の最適化](docs/KERNELS.md)・[呼び出し経路](docs/CALL_PATHS.md) | 改善の採否と、通常経路への統合状況 |
| [計測記録](docs/MEASUREMENTS.md) | 性能比較の条件・生ログと、初期計測のアーカイブ |
| [探索・改善記録](docs/bootstrap/README.md)・[時系列](docs/bootstrap/TRACE.md) | 基礎部品の採用理由、SATによる検証・合成の経緯 |
| [研究・探索記録](docs/research/README.md) | 厳密代数・実数制約などの実装と独立レビュー、未採用の試作 |
