# 基礎部品の最適化

[ドキュメント](README.md) / [探索・改善記録](bootstrap/README.md)

通常経路に採用した改善と、その利用先・検証・比較条件をまとめます。
実装の存在だけでは、上位アルゴリズムへの統合や速度改善を意味しません。
本体からの静的参照は[呼び出し経路](CALL_PATHS.md)、全パッケージは[一覧](INVENTORY.md)を参照してください。

各数値はリンク先の同条件比較です。異なる行・測定系列の絶対時間や倍率は合成しません。

## リストと自然数

| 基礎部品 | 通常経路の利用 | 採用と検証・計測の範囲 |
| --- | --- | --- |
| Natの半分化 | Fp既約性、円分体の次数、2冪判定 | [共有化](bootstrap/nat-conversions.md)から[末尾共有](bootstrap/nat-tail-sharing.md)へ進めた。4096の後段比較は21.70→9.87 µs。Leanのfloorモデルと三backendの有限oracle |
| NatからBinaryへの変換 | 公開binary.from_natとその利用先 | [8進単位の共有](bootstrap/nat-radix-grouping.md)。4096はnative9.60→6.23 µs、JS9.39→5.90、Wasm8.11→5.07。0/1保護、値・停止性・canonical性のLeanモデル |
| 定数prefix | core.replicate、binary.pair | [末尾共有](bootstrap/constant-prefix.md)。8192要素192.60→84.33 µs。任意型のLean等式。Karatsubaへの融合は差が不明瞭なので未採用 |

## 二進算術

| 基礎部品 | 通常経路の利用 | 採用と検証・計測の範囲 |
| --- | --- | --- |
| Binaryの恒等元 | multiply/divmod/gcdを使う全package | [恒等元経路](bootstrap/primitive-identities.md)。2048bitの同値GCD6.34 ms→5.29 µs。全体の一般入力にこの比は適用しない。短い除算groupには回帰あり |
| 0/1の共有 | 公開zero/one factoryを使う全kernel | [不変leaf](bootstrap/binary-constants.md)。同ELFのfactory22.04→12.37 ns、LLL3x3の別比較149〜162→138〜141 µs。差が重なる上位には改善を主張しない |
| 桁幅を使う除算・剰余・GCD | divmod、GCD、modular.reduce | [適応kernel](bootstrap/adaptive-division.md)。近い幅32対の除算1.48→0.262 ms、GCD26.82→9.95 ms。広い差の除算は同程度。8bit全対とPython2048bit fixture |
| 有界積と小さい差 | 公開multiply/subtract→exact・LLL・Smith等 | [4bit積](bootstrap/tiny-products.md)は169積26.58→2.18 µs、[差](bootstrap/tiny-differences.md)は225差9.23→2.70 µs。外域は従来算法へ戻す。積はsuffix DAGで追加Cons544→100、差のWasm byte外域には小回帰の可能性 |
| Binary比較 | binary.compareと除算/GCD等の内部比較 | [有限prefixとtail loop](bootstrap/binary-comparison.md)。全有限raw列のLean等価性、canonical値の順序、三backendの20k bitを検査。native短語2.53→2.28 µs、2048bit等値6.47→3.59 µs。64bitの全caseでの改善は主張しない |

## 整数と有理数

| 基礎部品 | 通常経路の利用 | 採用と検証・計測の範囲 |
| --- | --- | --- |
| exactの小商・約分・符号 | Rational、行列、Smith、LLL、単体法など | [段階最適化](bootstrap/exact-optimization.md)。小さい既知の正確な商、Steinへの限定dispatch、零・±1の共有を採用。さらに[4bit有限表](bootstrap/exact-tiny-gcd.md)を実際の約分へ接続し、156対で旧selector約55→6 µs、二つの固定LLL入力も短縮 |
| 有理数の直接減算 | 公開rational_subtract→行列・LLL・単体法など | [中間の否定を省く](bootstrap/rational-subtraction.md)。同ELFの784演算96.25→79.64 µs。23,409対とPython Fraction fixture、上位への波及は別計測 |

## 有限体と多項式

| 基礎部品 | 通常経路の利用 | 採用と検証・計測の範囲 |
| --- | --- | --- |
| Fp多項式の係数と除算 | Galois、巡回RS、AESの表生成 | [Fp(2)と除算](bootstrap/gf2-performance/README.md)。同じ検査済みfieldの係数、幅、scale/shiftを再利用。CPU時間とwall時間を別に記録 |
| GF(2^m)の積 | Galois.multiply→RSの符号化/復号、AESの有限体演算 | [可変長Bool列](bootstrap/gf2-performance/README.md)。同一CPU timer系列でGF256積5.225→0.942 µs、RS255は7.510→5.000 ms。固定幅案はRSを悪化させたため棄却 |
| 一変数多項式の評価 | 公開polynomial.evaluate→Sturm・実数制約・実代数計算 | [疎Horner](research/sparse-horner-20261116.md)。同じnative ELFの密な6評価2.51→0.336 ms、実数制約の次数8例1.59→0.490 s。√2の小例は横ばい。JSにも局所改善、WasmGCの短い対照は揺れが大きい。独立QQと降順を前提にしたLeanモデル |

## SATと反証

| 基礎部品 | 通常経路の利用 | 採用と検証・計測の範囲 |
| --- | --- | --- |
| CDCLのdecision/conflict | watched solver→NAND合成・SMT・RUP生成 | [SAT kernel](bootstrap/sat-engine.md)。first-openとassignment trieを採用。同一ELFのcomplete-query4.39 s→0.826 s、生成CNFと燃料構築を除きbuilder/checkerを含む。探索traceと証拠の一致も検査 |
| RUPの索引とhint生成 | 生成proof→独立checker | [RUP](bootstrap/ruplog.md)。非unitの早期終了と節参照の共有を合成し、20対全query314.14→284.44 ms。単独案は差が不明確で保留した。LRAT/DRATへ16証拠と7偽造例を出力して追試 |

## 採用しなかった候補と独立実装

- [全加算器の12候補](bootstrap/adder-search.md)は、全8条件の等価性をLeanでも確認しましたが、実測で遅いため通常の式を変更していません。
- [長語除算の追加実験](research/wide-kernels/README.md)は、JSのスタック制約を避けてもnative剰余が悪化するため未採用です。
- `runbinary`は圧縮に特化した独立実装で、通常のBinary全体のバックエンドにはしていません。
- `core.gcd`と`core.interleave`は内部利用のない公開APIです。局所的な速さだけで、変換費用を無視して接続することはしません。

小差や未変更対照の揺れが大きい結果では、上位の成功例だけを採用理由にしません。

## 計測の共通条件

重いbuild・test・計測は`tools/measure --cpu N COMMAND...`で、全worktree共通のロックを通します。
担当間の競合は避けられますが、外部負荷や周波数の変動までは除去できません。
詳細な条件と生ログは[計測記録](MEASUREMENTS.md)と各行の探索記録にあります。
