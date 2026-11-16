# 全加算器の有限候補探索：12案を棄却

[ドキュメント](../README.md) / [探索・改善記録](README.md)

プリミティブをさらに高速化するため、三入力full adderのjoint cofactorを列挙した。
最初に読む変数が3通り、false/trueそれぞれで次に読む変数が2通りずつあり、計12通り。
二変数を読めばsum/carryの残りは最後の変数・否定・定数で表せる。
これは二段read-once decision treeという限定した候補群で、あらゆる実装の超最適解ではない。

`tools/generate_adder_candidates.py`は同じ木からMoonBitとLeanを生成する。
全12案を全8Bool入力・128 word入力で検査し、Leanでも従来の全真理値matchとの同値を証明した。
12の証明は追加公理なし。実装候補は`*_wbtest.mbt`だけに置き、productionは変えない。

各候補を専用のword加算へ直接組み込み、callback呼び出しを比較コストへ加えないようにした。
native release・CPU4固定・入力構築除外・同じprocess・各10標本：

| 幅 | 従来の真理値match | 12候補の平均の範囲 |
| --- | ---: | ---: |
| 256bit | 2.91 µs | 3.61〜4.02 µs |
| 2048bit | 25.60 µs | 29.47〜37.09 µs |

この入力では全て遅く、採用候補はなかった。
論理式の短さや分岐の見た目からbackendの時間を予測できないことを再確認した。
従来のcarry-mux案の棄却と合わせ、次は式の変形ではなくword処理・表現・不要走査を調べる。

生ログ：[native](../measurements/adder-candidates-native.txt)、[Lean](../measurements/adder-candidates-lean.txt)。

```sh
python3 tools/generate_adder_candidates.py
tools/moon test src/binary/adder_candidates_wbtest.mbt --target native
taskset -c 4 tools/moon bench src/binary/adder_candidates_wbtest.mbt --target native --release
tools/check_formal
```
