# アルゴリズム一覧

[ドキュメント](README.md) / [ハンドブック](../HANDBOOK.md)

[README](../README.md)のカテゴリごとに、実装の入口をまとめる。
設計・表現コスト・検証範囲は[ハンドブック](../HANDBOOK.md)、
パッケージ単位の依存関係は[生成一覧](INVENTORY.md)を参照。
公開APIが他の算法から使われているかは[呼び出し経路](CALL_PATHS.md)で確認できる。

<a id="foundations"></a>

## 基礎算術・データ構造

| 分野 | 実装と入口 |
| --- | --- |
| リスト・自然数 | [不変リスト・Peano算術・Euclid](../src/core/data.mbt) |
| Bool代数 | [演算辞書・full adderの構成](../src/boolean/boolean.mbt) |
| 二進算術 | [算術・連結・pair/unpair](../src/binary/binary.mbt)・[Karatsuba](../src/binary/karatsuba.mbt)・[Stein GCD・整数平方根・Fibonacci](../src/binary/number_theory.mbt) |
| 圧縮二進算術 | [runを展開しない加減乗算・shift・pair](../src/runbinary/runbinary.mbt)・[燃料付き除算](../src/runbinary/division.mbt) |
| 厳密数 | [符号付き整数・有理数・非ゼロの証拠](../src/exact/exact.mbt) |
| 実代数的数 | [検査済み一根区間・比較・resultant・厳密な四則演算](../src/realalgebraic/number.mbt) |
| 複素代数的数 | [実代数的座標・四則演算・共役・等号・証拠](../src/complexalgebraic) |
| 複素数体 | [K(i) の基底・逆元・trace/norm・最小多項式](../src/complexfield)・[α+i と絶対一生成元への双方向変換](../src/complexprimitive) |
| 共通体と生成部分体 | [複素代数的数の選択座標を共通K(i)へ移す](../src/complexcompositum)・[単項式基底による最小生成体と剰余表示](../src/complexsubfield) |
| 分解体とGalois群 | [全根から最小分解体を構成](../src/complexsplitting)・[二項三次式の厳密根構成](../src/cubicradical)・[遅延置換探索と完全な体作用](../src/splittinggalois) |
| 自己同型と固定体 | [明示分解した体の全自己同型と合成表](../src/complexautomorphism)・[部分群の不変部分空間・完全基底・座標変換](../src/fixedfield) |
| 最小多項式・数体 | [既約因子と選択根による正規化](../src/realminimal/realminimal.mbt)・[Q(α)の剰余演算・Bézout逆元・trace/norm](../src/numberfield/field.mbt) |
| 多段の実代数拡大 | [選択根を順に加える四則演算・順序・相対実根](../src/realtower/api.mbt)・[二次式の厳密な符号判定](../src/realtower/quadratic.mbt) |
| 共通数体 | [実代数的数のprimitive-element合成と両生成元の埋込み](../src/compositum/producer.mbt) |
| ソート | [安定merge/insertion/quick sort](../src/sorting/sorting.mbt) |
| 優先度キュー | [永続leftist heap・heap sort](../src/heap/heap.mbt) |
| 辞書 | [Boolワードの永続trie・最長prefix・union](../src/trie/trie.mbt)・[永続AVL・削除・順位と選択](../src/avl/avl.mbt) |

<a id="number-theory"></a>

## 数論・有限体

| 分野 | 実装と入口 |
| --- | --- |
| 剰余算術 | [平方反復・拡張Euclid・逆元・素数判定](../src/modular/modular.mbt)・[一般化CRT](../src/modular/crt.mbt)・[小さなRSA](../src/modular/rsa.mbt) |
| 素数・因数分解 | [Lucas/Pratt・部分Pocklington証明と合成数証拠](../src/primality/primality.mbt)・[燃料付きPollard rho・完全分解検査](../src/factor/factor.mbt) |
| 素数証明の生成 | [分解・再帰証明・Lucas witness探索](../src/primeprove/primeprove.mbt) |
| 有限体・平方根 | [Euler判定・Tonelli–Shanks](../src/finitefield/sqrt.mbt) |
| 有限拡大体 | [検査済み素数からGF(p)](../src/primefield/primefield.mbt)・[Berlekamp多項式分解・既約性証拠](../src/fppoly/factorization.mbt)・[GF(p^m)・trace/norm](../src/galois/galois.mbt) |
| 離散対数 | [baby-step giant-step・最小位数と部分群境界](../src/discretelog/discretelog.mbt) |
| 楕円曲線 | [群演算・二進スカラー倍・点の圧縮と復元](../src/elliptic/elliptic.mbt) |

<a id="symbolic-computation"></a>

## 変換・記号計算

| 分野 | 実装と入口 |
| --- | --- |
| FFT | [12等式に対応する記号FFTと直接DFT](../src/fft/fft.mbt) |
| 円分体・厳密FFT | [円分多項式の正規形・逆元](../src/cyclotomic/cyclotomic.mbt)・[正規化されたFFT/逆FFT](../src/exactfft/exactfft.mbt) |
| NTT | [有限体変換・逆変換・線形畳み込み](../src/ntt/ntt.mbt) |
| 多項式 | [有理係数の疎多項式・除算・GCD・偏微分](../src/polynomial/polynomial.mbt) |
| 整数・有理係数の因数分解 | [Berlekamp–Zassenhaus・Hensel持ち上げ・既約性の検査](../src/zassenhaus/factorization.mbt) |
| Gröbner基底 | [再開可能なBuchberger・既約基底](../src/groebner/groebner.mbt) |
| F4 | [Macaulay行列のbatch簡約・入力idealへのwitness](../src/f4/f4.mbt) |
| FGLM | [零次元商空間の線形従属・Lex/GradedLex/GrevLexへの基底変換](../src/fglm/fglm.mbt) |
| 零次元系の実解 | [shapeと全実根の共有パラメータ表現](../src/realvariety/shape.mbt)・[分離線形形式の探索と元座標への射影](../src/realvariety/separation.mbt) |
| 全複素根 | [QQ因数分解を先行する列挙](../src/complexfactor/search.mbt)・[実部・虚部の方程式と全根の被覆](../src/complexroots/search.mbt)・[微分とSturm–Tarskiによる重複度](../src/complexroots/multiplicity.mbt) |
| 実代数 | [Sturm列・実根数・有理区間による隔離と精密化](../src/sturm/sturm.mbt)・[Sturm–Tarski query・代数的な根での厳密な符号](../src/tarski/root_sign.mbt) |
| 消去 | [環上の固定次数resultant・discriminant・Bézout証拠](../src/elimination/fixed.mbt)・[QQ多変数式の指定変数を消去](../src/elimination/projection.mbt) |
| 代数係数の根 | [Q(α)上の相対Sturm・全実根の隔離・tower root](../src/orderedsturm/isolation.mbt) |
| 射影 | [principal subresultants](../src/elimination/principal.mbt)・[full Collinsの係数・全reducta・全対PSC](../src/projection/collins.mbt) |
| 任意変数の射影 | [導関数で閉じた全Collins階層・入力束縛](../src/cadprojection/hierarchy.mbt) |
| 微分 | [式ADTの記号微分・半環解釈](../src/autodiff/expression.mbt)・[前向き/逆向き自動微分](../src/autodiff/autodiff.mbt) |
| 厳密幾何 | [凸包・線分交差・面積・Bézier評価](../src/geometry/geometry.mbt) |

<a id="linear-optimization"></a>

## 線形代数・最適化

| 分野 | 実装と入口 |
| --- | --- |
| 半環・行列 | [半環の演算辞書](../src/algebra/algebra.mbt)・[行列積・累乗・Warshall](../src/matrix/matrix.mbt) |
| 線形代数 | [有理数の行列式・逆行列・解空間](../src/linear/linear.mbt)・[体で共通化したGauss–Jordan](../src/rowreduce/rowreduce.mbt) |
| 環上の行列 | [除算不要のBerkowitz特性多項式・行列式](../src/berkowitz/berkowitz.mbt)・[随伴行列・行列への多項式代入](../src/berkowitz/matrix_polynomial.mbt) |
| 整数線形代数 | [証拠付きSmith標準形](../src/smith/smith.mbt)・[整数解/不可能証拠](../src/smith/equations.mbt)・[有限生成アーベル群](../src/smith/cokernel.mbt) |
| 分数なしの行列式 | [Bareiss・厳密除算・行ごとの分母払い](../src/bareiss/bareiss.mbt)・[通常の有理数行列式](../src/linear/linear.mbt) |
| 格子 | [厳密有理数のLLL・依存基底の前処理・unimodular証拠](../src/lll/lll.mbt) |
| 線形最適化 | [二段階単体法・Bland規則・双対解/非有界/Farkas証拠](../src/simplex/simplex.mbt) |
| 整数最適化 | [0/1分枝限定法・再開可能なLP緩和・最適性の証拠木](../src/zeroone/zeroone.mbt) |

<a id="graphs"></a>

## グラフ

| 分野 | 実装と入口 |
| --- | --- |
| 経路・構造 | [BFS・Dijkstra・経路](../src/graph/graph.mbt)・[topological・SCC](../src/graph/structure.mbt) |
| 全域森 | [Kruskal・Prim・最小性の証拠検査](../src/spanning/spanning.mbt) |
| ネットワーク | [Edmonds–Karp最大流・最小カット・証拠検査](../src/maxflow/maxflow.mbt) |
| マッチング | [Hopcroft–Karp・最小頂点被覆・最適性検査](../src/bipartite/bipartite.mbt) |
| 一般マッチング | [Blossom縮約・展開・最大対応とTutte–Berge証拠](../src/blossom/blossom.mbt) |

<a id="logic-constraints"></a>

## 論理・制約解決

| 分野 | 実装と入口 |
| --- | --- |
| SAT | [DPLL・モデルと反証の検査](../src/sat/sat.mbt) |
| CDCL | [first-UIP・watch・非時系列backjump・独立RUP検査](../src/cdcl/cdcl.mbt) |
| SAT反証ログ | [RUP証拠の構築](../src/ruplog/build.mbt)・[ヒント付き証拠の検査](../src/ruplog/check.mbt) |
| 回路の検証・合成 | [Bool式→CNF・等価性miter](../src/circuit/circuit.mbt)・[上限付きNAND合成](../src/synthesis/encoding.mbt) |
| BDD | [永続ROBDD・異manager間の演算](../src/bdd/apply.mbt)・[厳密モデル数・存在/全称量化](../src/bdd/count.mbt) |
| SMT | [差分制約・負閉路の証拠](../src/difference/difference.mbt)・[CDCLと整数差分理論の接続](../src/smt/smt.mbt) |
| 実数多項式制約 | [一変数CAD・厳密な符号分割・存在/全称の決定と証拠検査](../src/realcad/prepare.mbt) |
| 非線形実数SMT | [Tseitin・CDCL状態保持・早期SAT・理論節の削減](../src/realnlsmt/search.mbt)・[モデル・理論補題・最終RUPの検査](../src/realnlsmt/check.mbt) |
| 実閉体・量化消去 | [一階実数式から量化なしのQQ式へ](../src/realclosed/realclosed.mbt)・[任意変数CADと円柱省略の検査](../src/cad/check.mbt)・[符号木の量化fold](../src/signcad/encode.mbt) |
| 二変数の実数制約 | [full Collins→数体上のlifting→量化文の判定](../src/cad2/machine.mbt)・[量化結果の区間集合と厳密membership](../src/semialgebraic/assemble.mbt) |
| パリティゲーム | [再開可能なZielonka法・位置戦略・独立した閉路検査](../src/parity/solve.mbt) |
| モデル検査 | [μ-calculusの再帰的な様相論理式→パリティゲーム](../src/mucalc/compiler.mbt) |
| 組合せ探索 | [Algorithm X・primary/secondary列のexact cover](../src/exactcover/exactcover.mbt)・[再開可能な全解列挙](../src/exactcover/enumerate.mbt) |
| 制約のモデル化 | [Nクイーン](../src/puzzles/queens.mbt)・[4×4/9×9数独](../src/puzzles/sudoku.mbt) |

<a id="languages-sequences"></a>

## 言語・列アルゴリズム

| 分野 | 実装と入口 |
| --- | --- |
| 単一化 | [occurs check・冪等置換](../src/unify/unify.mbt) |
| 型推論 | [Hindley–Milner・let多相](../src/infer/infer.mbt) |
| 評価機械 | [燃料付き・再開可能なCEK](../src/cek/cek.mbt) |
| 正規表現 | [Brzozowski微分](../src/regex/derivative.mbt)・[Thompson NFA](../src/regex/thompson.mbt) |
| 構文解析 | [CNF文法のCYK・構文木と導出検査](../src/cyk/cyk.mbt) |
| 複数語検索 | [Aho–Corasick・failure遷移・チャンクをまたぐ検索](../src/aho/aho.mbt) |
| 動的計画法 | [編集距離・編集手順・LCS](../src/dp/sequences.mbt)・[0/1 knapsack](../src/dp/knapsack.mbt) |

<a id="coding-cryptography"></a>

## 符号・圧縮・暗号

| 分野 | 実装と入口 |
| --- | --- |
| ビット符号 | [Elias gamma・任意精度ペアの自己区切り符号](../src/bitcodec/bitcodec.mbt) |
| 圧縮 | [Huffman符号・復号](../src/huffman/huffman.mbt)・[LZ78・辞書番号とliteralのビット符号](../src/lz78/lz78.mbt) |
| ハッシュ | [BoolリストだけのSHA-256](../src/sha256/sha256.mbt)・[固定幅ビット演算](../src/sha256/word.mbt) |
| AES | [GF(256)からのSbox生成](../src/aes/sbox.mbt)・[128/192/256bit鍵のblock暗号・復号](../src/aes/cipher.mbt) |
| 誤り訂正 | [Reed–Solomon評価符号・Berlekamp–Welch・消失訂正](../src/reedsolomon/reedsolomon.mbt) |
| 二進BCH | [共役根からの生成多項式・系統符号化・BM/Chien訂正](../src/bch/bch.mbt) |
| リスト復号 | [Guruswami–Sudan多重度補間・Roth–Ruckenstein探索](../src/listdecode/interpolate.mbt) |
| 漸化式と巡回符号 | [Berlekamp–Massey](../src/recurrence/recurrence.mbt)・[Chien/ForneyによるGF(p^m)のRS訂正](../src/cyclicrs/cyclicrs.mbt) |
