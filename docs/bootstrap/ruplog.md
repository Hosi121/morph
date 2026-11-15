# 節IDヒント付きRUP証拠

`ruplog` は既存の `@cdcl.Proof = Rup(Chain[Clause])` を受け取り、各追加節にunit
propagationの参照ID列を付ける。SAT APIと既存Proof型は変更しない。
核は純ADT、Chain、Nat、Binary、不変Bool trieであり、組み込み数値・配列・可変状態・FFIを使わない。

形式の根拠は [Cruz-FilipeらのLRAT論文 §3・Fig.1/3](https://arxiv.org/pdf/1612.02353) と、
[著者のlrat-check.c](https://github.com/marijnheule/drat-trim/blob/master/lrat-check.c)。
本実装は正のRUP参照だけを扱う、削除・RATのない部分系である。形式検証済みLRAT checkerを
移植したものではない。現在の成果はADT表現で、text adapterは後続単位とする。

## IDと受理条件

原CNFの節occurrenceへ順に1〜mのIDを与える。重複節・重複literal・tautologyがあっても
原節の位置とIDは変えない。追加IDはm+1から連番。IDは正のBinaryで、RAT用の負IDと
削除操作はデータ型に含めない。

```text
Step { id: Binary, clause: @sat.Clause, hints: Chain[Binary] }
Certificate { steps: Chain[Step] }
prepare(Cnf) -> Input
first_derived_id(Input) -> Binary
build(Cnf, @cdcl.Proof) -> Certificate?
build_prepared(Input, @cdcl.Proof) -> Certificate?
build_scanning(Cnf, @cdcl.Proof) -> Certificate?
build_scanning_prepared(Input, @cdcl.Proof) -> Certificate?
check(Cnf, Certificate) -> Bool
check_prepared(Input, Certificate) -> Bool
erase(Certificate) -> @cdcl.Proof
hint_count(Certificate) -> Nat
```

checkerは追加節のliteralを全て否定して仮定し、指定IDの節だけを読む。
途中の各参照節が厳密にunitであることを確認して割り当て、最後の参照節が全literal偽に
なることを要求する。全hintを使い切り、全追加を順に検査し、末尾の追加は空節でなければならない。
全DB走査、SAT探索、builderのunit探索コードは呼ばない。

追加節は変数ラベルが狭義昇順で、同じ変数の重複・相補literalを含まない形式に限定する。
Satisfiedな節や余分なhint、途中の空節も受理しない。これは完全なLRAT parserの契約ではない。
builderは元RUP列のliteralをsort/deduplicateし、tautological lemmaは不要なので省略する。
元RUP列の空節も末尾一回の形を要求する。証拠内に同じ有効lemmaを繰り返すことは許す。

入力の重複literalは準備段階で正規化し、tautologicalな原節は使用しないままIDを保持する。
checkerとbuilderはこの入力表現とgeneric trieを共有するが、unit節判定と伝播の実装は分ける。
builderは信用する必要がなく、生成後のcertificateを別checkerが受理することが条件になる。

## 有限検証

最初の単位には9テストを置く。

- 三変数三節の全19,683 CNFを真理値表・CDCL outcomeと照合し、生成したcertificateと
  eraseした既存RUPを両checkerに通す。
- 二節CNFの全729通りと、非空candidate lemmaの全26通り、合計18,954列を既存RUP checkerと
  照合する。この比較は途中に空節を含めない受理形の範囲で行う。
- IDゼロ・未知ID・再使用・self/forward参照・連番違反、hintの並べ替え・必要hintの削除・
  必要lemmaの削除、unitでないhint、既にSatisfiedなhint、衝突後の余分なhintを拒否する。
- 空証拠、空節なし、途中の空節、非canonicalな追加節、tautologyを偽装した追加を拒否する。
  原CNFのtautology・literal重複はIDを保持し、source lemmaの重複は正規化後も意味を保つ。
- pigeonholeの2〜6 pigeons、および8bit加算器miterの学習を含む証拠を検査する。

有限照合であり、任意CNFに対するchecker soundnessの形式証明ではない。

## 同一証拠のnative計測

各行は同じprebuilt CNF、同じCDCL RUP列、同じ生成certificateを使う。
MoonBit v0.10.20、native release、Intel Core Ultra 7 255H/WSL2、各10サンプル。
CNF生成とSAT探索はこの表の計測外である。

| 処理 | 16bit miter | 64bit miter |
| --- | ---: | ---: |
| 原CNF節 / 追加 / hints | 502 / 118 / 3,280 | 2,038 / 478 / 31,960 |
| 既存のunhinted RUP checker | 77.87 ms ± 5.71 ms | 4.43 s ± 81.76 ms |
| scan hint builder、入力準備込み | 87.41 ms ± 7.57 ms | 5.56 s ± 180.40 ms |
| hint checker、入力準備込み | 3.24 ms ± 269.51 µs | 39.44 ms ± 2.26 ms |
| hint checker、準備済み入力 | 1.98 ms ± 99.94 µs | 25.26 ms ± 1.87 ms |
| 入力準備だけ | 1.23 ms ± 37.50 µs | 16.21 ms ± 727.76 µs |

64bitのcheckerは同条件で約112倍軽くなった。一方、scan builder込みで一度だけ検査する
総時間は増える。builderがunitを探すため全DBを何度も走査するためであり、この段階で
query全体の高速化は主張しない。ヒント付き証拠を保存して別checkerで再検査する処理を
分離できたことが最初の到達点である。

```sh
tools/moon test src/ruplog --target native
tools/moon test src/ruplog --target js
tools/moon test src/ruplog --target wasm-gc
tools/moon bench src/ruplog/bench_wbtest.mbt --target native --release
```

## Occurrence indexによるbuilder改善

現行の `build` / `build_prepared` は、signed literalからそれを含む節ID列への不変indexを
一度構築する。仮定またはunit伝播でliteralが偽になると、そのliteralを含む節だけをqueueへ
積む。ID列はchunkとして共有し、毎回コピーしない。初期unit節と空節は別に保持する。
追加lemmaはindexとunit一覧へ追記する。旧scan builderは `build_scanning` 系に残す。
checkerは変更していない。

伝播順が変わるため、生成hintsの列も変わる。元のRUP追加節・追加ID・canonicalなerase結果は
同じである。既存の有限照合を両builderへ通し、追加の1,000個の6変数3SATを真理値全探索・
両builder・独立checkerで照合した。ラベル65535とclause IDの分離も確認する。
全11テストがnative、JavaScript、Wasm GCで通過する。

以下は全て `taskset -c 10` で同一process、同じprebuilt CNFと元RUP列を比較した。
共有Binaryの基盤は `e717649` に固定し、builder変更と混ぜていない。

| 処理 | 16bit | 64bit |
| --- | ---: | ---: |
| scan hints / occurrence hints | 3,280 / 2,940 | 31,960 / 21,132 |
| scan builder、準備込み | 98.16 ms ± 5.08 ms | 5.87 s ± 267.11 ms |
| occurrence builder、準備込み | 7.46 ms ± 361.22 µs | 110.65 ms ± 10.77 ms |
| checker、scan hints | 3.15 ms ± 89.87 µs | 41.51 ms ± 3.86 ms |
| checker、occurrence hints | 2.97 ms ± 296.23 µs | 38.60 ms ± 2.78 ms |

64bitのbuilderはこの条件で約53倍軽くなった。hint列が短くなる効果も含むため、同一伝播列の
データ構造だけの速度差とは呼ばない。

同じCPU10固定で、prebuilt 64bit CNFから毎回新しくSAT探索・証拠生成・検査まで行った比較：

| 一回の全処理 | 平均 ± 標準偏差 | min〜max |
| --- | ---: | ---: |
| solve + 既存RUP検査 | 7.32 s ± 1.40 s | 6.08〜9.69 s |
| solve + occurrence builder + hint検査 | 1.82 s ± 41.09 ms | 1.76〜1.90 s |

各10回。CNF構築と200,000遷移のfuel構築は両者とも計測外、solverのstart・RUP生成・builder・
checkerの入力準備は計測内である。baselineの分散は大きいが範囲は分離し、単発の全処理でも
改善を確認できた。この入力では平均約4倍であり、全CNFについての一般的な速度保証ではない。

```sh
taskset -c 10 tools/moon bench src/ruplog/bench_wbtest.mbt --target native --release -i 3
taskset -c 10 tools/moon bench src/ruplog/bench_wbtest.mbt --target native --release -i 4
taskset -c 10 tools/moon bench src/ruplog/bench_wbtest.mbt --target native --release -i 5
```
