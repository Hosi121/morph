# 共有kernelの採用状況

実装の存在、通常経路での利用、正しさの検査、速度の採否を分ける。
内部の字句参照は[CALL_PATHS](CALL_PATHS.md)、全packageは[INVENTORY](INVENTORY.md)。
以下の時間は各行にリンクした同条件比較であり、異なる行の絶対時間は比較しない。

| 基礎部品 | 通常経路の利用 | 採用と検証・計測の範囲 |
| --- | --- | --- |
| Natの半分化 | Fp既約性、円分体の次数、2冪判定 | [共有化](bootstrap/nat-conversions.md)から[末尾共有](bootstrap/nat-tail-sharing.md)へ進めた。4096の後段比較は21.70→9.87 µs。Leanのfloorモデルと三backendの有限oracle |
| NatからBinaryへの変換 | 公開binary.from_natとその利用先 | [8進単位の共有](bootstrap/nat-radix-grouping.md)。4096はnative9.60→6.23 µs、JS9.39→5.90、Wasm8.11→5.07。0/1保護、値・停止性・canonical性のLeanモデル |
| 定数prefix | core.replicate、binary.pair | [末尾共有](bootstrap/constant-prefix.md)。8192要素192.60→84.33 µs。任意型のLean等式。Karatsubaへの融合は差が不明瞭なので未採用 |
| Binaryの恒等元 | multiply/divmod/gcdを使う全package | [恒等元経路](bootstrap/primitive-identities.md)。2048bitの同値GCD6.34 ms→5.29 µs。全体の一般入力にこの比は適用しない。短い除算groupには回帰あり |
| 0/1の共有 | 公開zero/one factoryを使う全kernel | [不変leaf](bootstrap/binary-constants.md)。同ELFのfactory22.04→12.37 ns、LLL3x3の別比較149〜162→138〜141 µs。差が重なる上位には改善を主張しない |
| 桁幅を使う除算・剰余・GCD | divmod、GCD、modular.reduce | [適応kernel](bootstrap/adaptive-division.md)。近い幅32対の除算1.48→0.262 ms、GCD26.82→9.95 ms。広い差の除算は同程度。8bit全対とPython2048bit fixture |
| 有界積と小さい差 | 公開multiply/subtract→exact・LLL・Smith等 | [4bit積](bootstrap/tiny-products.md)は169積26.58→2.18 µs、[差](bootstrap/tiny-differences.md)は225差9.23→2.70 µs。外域は従来算法へ戻す。積はsuffix DAGで追加Cons544→100、差のWasm byte外域には小回帰の可能性 |
| Binary比較 | binary.compareと除算/GCD等の内部比較 | [有限prefixとtail loop](bootstrap/binary-comparison.md)。全有限raw列のLean等価性、canonical値の順序、三backendの20k bitを検査。native短語2.53→2.28 µs、2048bit等値6.47→3.59 µs。64bitの全caseでの改善は主張しない |
| full adder | 二進加減乗算・run算術 | [12候補探索](bootstrap/adder-search.md)。全8条件の等価性をLeanでも確認したが、実測で遅いためproduction式は変更していない |
| exactの小商・約分・符号 | Rational、行列、Smith、LLL、単体法など | [段階最適化](bootstrap/exact-optimization.md)。小さい既知の正確な商、Steinへの限定dispatch、零・±1の共有を採用。さらに[4bit有限表](bootstrap/exact-tiny-gcd.md)を実際の約分へ接続し、156対で旧selector約55→6 µs、二つの固定LLL入力も短縮 |
| 有理数の直接減算 | 公開rational_subtract→行列・LLL・単体法など | [中間の否定を省く](bootstrap/rational-subtraction.md)。同ELFの784演算96.25→79.64 µs。23,409対とPython Fraction fixture、上位への波及は別計測 |
| Fp多項式の係数と除算 | Galois、巡回RS、AESの表生成 | [Fp(2)と除算](bootstrap/gf2-performance/README.md)。同じ検査済みfieldの係数、幅、scale/shiftを再利用。CPU時間とwall時間を別に記録 |
| GF(2^m)の積 | Galois.multiply→RSの符号化/復号、AESの有限体演算 | [可変長Bool列](bootstrap/gf2-performance/README.md)。同一CPU timer系列でGF256積5.225→0.942 µs、RS255は7.510→5.000 ms。固定幅案はRSを悪化させたため棄却 |
| CDCLのdecision/conflict | watched solver→NAND合成・SMT・RUP生成 | [SAT kernel](bootstrap/sat-engine.md)。first-openとassignment trieを採用。同一ELFのcomplete-query4.39 s→0.826 s、生成CNFと燃料構築を除きbuilder/checkerを含む。探索traceと証拠の一致も検査 |
| RUPの索引とhint生成 | 生成proof→独立checker | [RUP](bootstrap/ruplog.md)。非unitの早期終了と節参照の共有を合成し、20対全query314.14→284.44 ms。単独案は差が不明確で保留した。LRAT/DRATへ16証拠と7偽造例を出力して追試 |

`core.gcd`と`core.interleave`は内部利用のない公開APIである。
`runbinary`は圧縮に特化した独立実装で、通常Binary全体のbackendにはしていない。
局所的な速さだけで、別表現への変換costを無視して強制的に接続することはしない。

実験の記録と採用したsourceは分ける。特に小差・未変更対照の揺れが大きい結果は、
上位の成功例だけを拾って採用理由にしない。
重いbuild/test/計測は`tools/measure --cpu N ...`で全worktree共通のmutexを通す。
これにより担当間の競合を避けるが、外部loadや周波数の変動までは除去しない。
