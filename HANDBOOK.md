# morph ハンドブック

データ型で値を表し、パターンマッチと再帰で計算するための設計ガイドです。
実装を読み、表現を変えたときに意味とコストがどう変わるかを追えるように、分野ごとに章をまとめています。

[ドキュメント案内](docs/README.md) · [アルゴリズム一覧](docs/ALGORITHMS.md) · [実行例](docs/TOUR.txt)

## 読み始める順序

| 関心 | 読む順序 |
| --- | --- |
| 数をデータ構造から作る | [リスト・自然数](docs/handbook/foundations.md#list-nat) → [二進算術](docs/handbook/foundations.md#binary) → [整数・有理数](docs/handbook/foundations.md#exact) |
| 記号計算の仕組みを読む | [矢印FFT](docs/handbook/symbolic-computation.md#fft) → [多項式](docs/handbook/symbolic-computation.md#polynomials) → [円分体・厳密FFT](docs/handbook/symbolic-computation.md#exact-fft) |
| 構文木を扱う | [単一化](docs/handbook/languages-sequences.md#unification) → [型推論](docs/handbook/languages-sequences.md#inference) → [CEK評価機械](docs/handbook/languages-sequences.md#cek) |
| 解と根拠を組み立てる | [SAT反証](docs/handbook/logic-constraints.md#sat) → [最大流・カット](docs/handbook/graphs.md#flow) → [LPの証拠](docs/handbook/linear-optimization.md#simplex) |
| 厳密代数をつないで使う | [多項式](docs/handbook/symbolic-computation.md#polynomials) → [基底・実解・数体・実閉体・SMT](docs/handbook/algebraic-solving.md) |

動作から確かめる場合は、リポジトリのルートで `tools/moon run src/cmd/main` を実行してください。
環境の準備とコマンドは[開発・検証環境](docs/ENVIRONMENT.md)にあります。

## 共通する考え方

### 値の構造が計算の手順になる

自然数は `Zero | Succ(Nat)`、不変リストは `Nil | Cons(A, Chain[A])` で表します。
加算は構造をたどって組み直す操作になり、二進数ではBool列と桁上がりの状態へ置き換わります。
同じリストや木から、数式、構文木、制約、探索の続きを表せます。

手書きの計算核には、組み込み数値型・数値リテラル・数値演算・配列・可変状態・FFIを使いません。
入力変換・表示・テストでは通常の数値型も利用します。
制約の適用範囲と機械的な検査は[検証ガイド](docs/VALIDATION.md)を参照してください。

### 表現を変えると費用も変わる

| 表現 | 大きさを決めるもの | 読むときの注意 |
| --- | --- | --- |
| Peano自然数 | 値そのもの | 長さや位置には素直だが、大きな数の展開は重い |
| Bool二進数 | 桁数 | 数の正規化と、ワードとしての桁幅の保存を区別する |
| 同一ビットのrun | run数 | 長い連続には向くが、交互ビットでは利点が小さい |
| 矢印の形式和 | 矢印と位相の展開量 | FFTの分割構造だけでは実時間を評価できない |

不変リストの連結は左側を作り直し、右側を共有できます。
正規形や既存の末尾を保つことで、中間データの構築を減らせます。
採用した最適化と比較条件は[基礎部品の最適化](docs/KERNELS.md)にまとめています。

### 演算の意味を辞書で渡す

半環の辞書を渡すと、同じ行列積をBool、二進自然数、有理数などで解釈できます。
体の辞書は、有理数の消去法と有限体の復号計算で行基本変形を共有するために使います。
型が操作の形を揃え、法則の成立は検査と利用側の条件で支えます。

### 探索と検査を分ける

SATの反証、流れのカット、マッチングの頂点被覆、LPの双対解は、見つける処理とは別に検査できます。
探索途中の状態もADTで保持すれば、燃料を追加して再開できます。
証拠検査・有限テスト・Leanモデルがそれぞれ示す範囲は[検証ガイド](docs/VALIDATION.md)で区別しています。

## 分野別の章

| 章 | 主な内容 |
| --- | --- |
| [基礎算術とデータ構造](docs/handbook/foundations.md) | 自然数、二進数、ペア、整数・有理数、ソート、永続木 |
| [数論と有限体](docs/handbook/number-theory.md) | 剰余算術、CRT、素数証明、因数分解、拡大体、楕円曲線 |
| [変換と記号計算](docs/handbook/symbolic-computation.md) | FFT・NTT、多項式、Gröbner基底、実根隔離、微分、幾何 |
| [厳密代数の計算経路](docs/handbook/algebraic-solving.md) | F4、FGLM、実解、数体、多段拡大、CAD・量化消去をつなぐ |
| [線形代数と最適化](docs/handbook/linear-optimization.md) | 半環、Gauss–Jordan、Smith標準形、LLL、単体法、0/1最適化 |
| [グラフ](docs/handbook/graphs.md) | BFS、Dijkstra、SCC、全域森、最大流、二部マッチング |
| [論理と制約解決](docs/handbook/logic-constraints.md) | SAT・CDCL、回路、BDD、SMT、exact cover、数独 |
| [言語と列アルゴリズム](docs/handbook/languages-sequences.md) | 単一化、型推論、CEK、正規表現、CYK、検索、動的計画法 |
| [符号・圧縮・暗号](docs/handbook/coding-cryptography.md) | 自己区切り符号、Huffman、LZ78、SHA-256、AES、誤り訂正 |

各章は、表現と不変条件、算法、検証例、限界を説明します。
正確な依存と公開APIは、各パッケージの `moon.pkg` と `pkg.generated.mbti` が正本です。

## 手を動かす

[小さな実験](docs/handbook/exercises.md)では、二進ワードの連結、FFTの位相、
0/1探索の証拠木、誤り訂正の半径、実根隔離の再開を試せます。
変更したパッケージのテストから始め、共有部品を変えたら横断検証へ進んでください。

## 設計の経緯を調べる

現在の設計を読むには各章を、採用理由を調べるには[探索・改善記録](docs/bootstrap/README.md)を使います。
初期の動機、作業期限、過去の検証数、リファクタリングの経緯は[履歴](docs/research/HISTORY.md)へ移しました。
計測値と未採用の試作も保存し、現行の説明と当時の記録を区別しています。
