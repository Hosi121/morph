# 有限4bit GCDの表と分岐グラフ

対象は非負整数0〜15の全256入力対。公開APIは変えず、exactの私的なGCD候補を作る。
Pythonは構築時だけmath.gcdを使い、生成されたMoonBitはBool tuple、ADT match、
既存Binaryのcanonicalな不変定数だけで返す。近似・machine整数演算・配列・可変状態は核へ入れない。

`src/exact/generate_tiny_gcd.py` は全256対の表とmulti-terminal decision DAGを生成する。
各分岐でlow/high cofactorを取り、同じ子への分岐を除き、同一nodeを共有する。
固定seedから選んだ512順序と4標準順序の516候補を比較し、node数の上位3候補を残した。
いずれも106 nodesであり、8!順序全体に対する最適性は主張しない。
変数0〜3はaの低位からの4bit、4〜7はbの4bitである。

- 第一候補: 0,2,1,4,3,6,7,5
- 第二候補: 2,3,0,1,4,6,5,7
- 第三候補: 4,0,5,7,6,2,1,3

16個の出力は `binary.from_bits` で一度だけ構築するcanonicalな不変値を共有する。
このため速度差には定数共有によるallocation削減も含む。初期化と入力構築はbenchmarkに含まない。
rootによるBinaryの0/1共有やGCD2 shortcutと重なる効果を、全libraryの倍率にはしない。

全256対を、別に書いたInt32 Euclid oracleと比較する。表と3 DAGの全てを確認する。
prototypeのdecodeは4bitだけを読むため、本番への導入では幅のガードを必須とする。
既存common_factorの0〜256全対と大きい近接奇数/共有因子/2冪の検査でfallbackも確認する。
これは有限領域の全探索検査であり、Leanによる翻訳・コンパイラの証明とは呼ばない。

同じnative release ELFに5方式を入れ、3〜15の異なる全156対で比較する。
0/1/同値とoperand=2を除いて、既存の恒等則やrootのGCD2 shortcutと区別する。
実行順はtable→3DAG→Stein、逆順、順方向とし、同一ELFの反復も記録する。

## native同一ELFの比較

2026-11-15、CPU8、moonc v0.10.20、native release、共通mutexで順/逆/順を実行した。
各欄は156対の1巡についての平均µs。各実行内10batch。

| 方式 | 順方向 | 逆方向 | 再び順方向 |
| --- | --- | --- | --- |
| plain full table | 19.60 | 18.77 | 20.57 |
| DAG第一候補 | 20.25 | 20.89 | 20.55 |
| DAG第二候補 | 20.51 | 22.87 | 21.87 |
| DAG第三候補 | 20.41 | 22.11 | 18.94 |
| 既存Stein | 51.88 | 51.97 | 49.99 |

表と各DAGの小さな差は確定的な順位と扱わず、より単純なplain表を本番候補に選ぶ。
この比較には本番common_factorの幅guard等を含めない。上位算法の比較は次節で分ける。
[各batch統計、ELF SHA256、wall/CPU秒](../measurements/exact-tiny-gcd-comparison.json)を残す。
全256対はnativeで一致した。generatorは `python3 src/exact/generate_tiny_gcd.py --check` で照合できる。
保存したnative exeへのfilterは `tiny_gcd_bench_wbtest.mbt:1-6`。逆順はfile:start-endを`/`で連結する。

## canonical Chainを直接matchする最終経路

生成Cを調べると、decodeの各popは動的な(Bool,Chain) tupleをmalloc/freeし、
さらに4Bool tupleを返していた。各operandで4回のpopと1回のdecode tupleがある。
Bool×Boolだけを返すfull_adderはclosed constant tupleへhoistされており、同じ問題とは扱わない。

そこで、256対のcanonical Chain patternを直接matchして16個の不変値へ返す表を生成する。
この経路にはdecodeを置かない。4bitを超える入力にはdefensiveな既存GCD fallbackもある。
本番common_factorは既存0/1/同値の後、両入力が4bit以下の場合だけこの表を呼ぶ。
16〜255は既存Stein、他は既存Euclidを保つ。公開APIは変えない。

最終の同一ELF比較、同じ156対、CPU8/native release/共通mutex：

| 方式 | 順方向 | 逆方向 | 再び順方向（平均µs） |
| --- | --- | --- | --- |
| decodeあり表 | 23.45 | 24.04 | 23.53 |
| DAG第一候補 | 18.12 | 20.85 | 18.82 |
| DAG第二候補 | 20.23 | 20.95 | 19.61 |
| DAG第三候補 | 20.15 | 18.97 | 19.47 |
| Stein | 51.02 | 53.23 | 53.16 |
| **direct Chain表** | **3.48** | **3.39** | **3.65** |

同一ELFのchecked common_factorを通しても、新表5.56/5.86/6.00 µsに対し、
旧0/1/同値/幅guard付きStein selectorは57.24/55.24/56.29 µsだった。
これは4bitの非自明156対についての値であり、任意幅や全libraryの倍率ではない。
初期化と入力構築を含めず、不変定数の共有の効果も含む。

## 上位とfallbackの同入力比較

beforeはexact `058e201` とBinary `b21222b` の固定基盤。afterは同基盤への表/幅guard追加だけ。
保存ELFをABBA順に実行した。各欄は2実行の平均µsで、各実行内10batch。

| 固定fixture | before | after |
| --- | --- | --- |
| LLL 3x3生成/検査 | 359.89 / 383.34 | 317.85 / 303.69 |
| LLL checker | 26.25 / 24.57 | 22.02 / 23.86 |
| LLL 3x4生成/検査 | 427.59 / 407.15 | 349.58 / 338.65 |
| Smith+LLL依存3x4 | 401.70 / 334.08 | 376.41 / 368.88 |
| Smith 3x3 | 50.93 / 50.58 | 50.72 / 51.11 |
| Smith checker | 20.13 / 20.88 | 20.53 / 20.17 |
| simplex | 36.13 / 35.92 | 35.20 / 35.06 |
| 小GCD128対control | 181.75 / 203.27 | 178.77 / 178.58 |
| 大幅GCD12対control | 565.09 / 586.91 | 590.21 / 594.72 |

LLL 3x3/3x4では短縮を観測する。他の上位では値が重なるか差が小さく、改善を主張しない。
幅guardは一般経路へ追加の一定費用を持ち、大幅controlはafterが少し遅かった。
同一beforeの依存LLLにも402→334 µsの変動があり、host外部負荷と周波数は固定できていない。
小さい差の採否や他入力への倍率推定には使わない。

[生の統計・ELF SHA256・wall/CPU秒](../measurements/exact-tiny-gcd-direct.json)を保存する。
生成は `python3 src/exact/generate_tiny_gcd.py --winner direct`、照合は同じ引数に`--check`を加える。
pure gate94 kernel files、--deny-warn、exact/LLL/Smith/simplex計32testsが
native/js/wasm-gcの全てで通過した。0〜256の全GCD対で幅境界とfallbackを検査し、
16/32/64/128bitの既知GCDと上位の独立証拠checkerも維持する。
