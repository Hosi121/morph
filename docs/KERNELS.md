# 共有kernelの採用状況

実装の存在、通常経路での利用、正しさの検査、速度の採否を分ける。
内部の字句参照は[CALL_PATHS](CALL_PATHS.md)、全packageは[INVENTORY](INVENTORY.md)。
以下の時間は各行にリンクした同条件比較であり、異なる行の絶対時間は比較しない。

| 基礎部品 | 通常経路の利用 | 採用と検証・計測の範囲 |
| --- | --- | --- |
| Natの半分化 | Fp既約性、円分体の次数、2冪判定 | [共有化](bootstrap/nat-conversions.md)。4096単体でBinary往復67.70→22.72 µs。Leanのfloorモデルと三backendの有限oracle |
| NatからBinaryへの変換 | 公開binary.from_natとその利用先 | [8進単位の共有](bootstrap/nat-radix-grouping.md)。三bitずつ出力し、商は元のNatの末尾を共有。0/1の小値と三backendの独立oracle・Leanの値/停止性を検査 |
| 定数prefix | core.replicate、binary.pair | [末尾共有](bootstrap/constant-prefix.md)。8192要素192.60→84.33 µs。任意型のLean等式。Karatsubaへの融合は差が不明瞭なので未採用 |
| Binaryの恒等元 | multiply/divmod/gcdを使う全package | [恒等元経路](bootstrap/primitive-identities.md)。2048bitの同値GCD6.34 ms→5.29 µs。全体の一般入力にこの比は適用しない。短い除算groupには回帰あり |
| full adder | 二進加減乗算・run算術 | [12候補探索](bootstrap/adder-search.md)。全8条件の等価性をLeanでも確認したが、実測で遅いためproduction式は変更していない |
| exactの小商・約分・符号 | Rational、行列、Smith、LLL、単体法など | [段階最適化](bootstrap/exact-optimization.md)。小さい既知の正確な商、Steinへの限定dispatch、零・±1の共有を採用。さらに[4bit有限表](bootstrap/exact-tiny-gcd.md)を実際の約分へ接続し、156対で旧selector約55→6 µs、二つの固定LLL入力も短縮 |
| Fp多項式の係数と除算 | Galois、巡回RS、AESの表生成 | [Fp(2)と除算](bootstrap/gf2-performance/README.md)。同じ検査済みfieldの係数、幅、scale/shiftを再利用。CPU時間とwall時間を別に記録 |
| GF(2^m)の積 | Galois.multiply→RSの符号化/復号、AESの有限体演算 | [可変長Bool列](bootstrap/gf2-performance/README.md)。同一CPU timer系列でGF256積5.225→0.942 µs、RS255は7.510→5.000 ms。固定幅案はRSを悪化させたため棄却 |
| CDCLのdecision/conflict | watched solver→NAND合成・SMT・RUP生成 | [SAT kernel](bootstrap/sat-engine.md)。first-openとassignment trieを採用。同一ELFのcomplete-query4.39 s→0.826 s、生成CNFと燃料構築を除きbuilder/checkerを含む。探索traceと証拠の一致も検査 |
| RUPの索引とhint生成 | 生成proof→独立checker | [RUP](bootstrap/ruplog.md)。検索時間とbuild/check全体を区別し、LRAT-TRIM/DRAT-trimへ16証拠と7偽造例を出力して追試 |

`core.gcd`と`core.interleave`は内部利用のない公開APIである。
`runbinary`は圧縮に特化した独立実装で、通常Binary全体のbackendにはしていない。
局所的な速さだけで、別表現への変換costを無視して強制的に接続することはしない。

実験の記録と採用したsourceは分ける。特に小差・未変更対照の揺れが大きい結果は、
上位の成功例だけを拾って採用理由にしない。
重いbuild/test/計測は`tools/measure --cpu N ...`で全worktree共通のmutexを通す。
これにより担当間の競合を避けるが、外部loadや周波数の変動までは除去しない。
