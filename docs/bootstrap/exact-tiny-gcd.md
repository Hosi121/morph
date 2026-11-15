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
この段階ではまだ本番common_factorへ接続せず、上位算法の効果も主張しない。
[各batch統計、ELF SHA256、wall/CPU秒](../measurements/exact-tiny-gcd-comparison.json)を残す。
全256対はnativeで一致した。generatorは `python3 src/exact/generate_tiny_gcd.py --check` で照合できる。
保存したnative exeへのfilterは `tiny_gcd_bench_wbtest.mbt:1-6`。逆順はfile:start-endを`/`で連結する。
