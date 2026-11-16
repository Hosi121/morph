# 節IDヒント付きRUP証拠

[ドキュメント](../README.md) / [探索・改善記録](README.md)

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

## 外部text adapterと独立checker

`tools/generate_ruplog.py` はopt-inのnumeric/JSONテストadapterを実行し、**実際にkernelが
生成・検査した**certificateをDIMACS CNF、ASCII LRAT、hintを消したDRUPへ書き出す。
Python側で証拠を作り直してはいない。Nat変数ラベル0をDIMACSの1へずらす。
原節の重複literalだけは除き、tautologyと全原節の位置・IDは保つ。raw CNFも別ファイルに保存する。

固定した外部実装:

- [LRAT-TRIM](https://github.com/arminbiere/lrat-trim) 0.2.0、commit
  `b30f400f4ee5c32b77ee566a7c006081b521534f`。`--forward --no-trim` で全追加を検査する。
- [DRAT-trim](https://github.com/marijnheule/drat-trim)、commit
  `2e3b2dc0ecf938addbd779d42877b6ed69d9a985`。eraseした節列の内容を別方式で検査する。

両builderのunits、unit chain、duplicate/tautology、原空節、branching cube、pigeonhole、
8bit/64bit miter、合計16証拠が**両方の外部checkerで受理**された。
偽のSAT→空節、hint順序の破壊、必須hint除去、self参照、削除した原節の参照、最終空節の
切り詰め、計7つのnegative controlsが受理されないことも確認した。
DRAT検査はhintそのものを検査しないため、LRAT検査とは役割を区別する。

64bitの両builderでは、duplicate除去は0個で、同じCNF・同じerase節列を検査した。

```text
CNF SHA256   81791c0eaf39a0faa927490662747272f98213455eb61fa011dd30ef303184b8
DRUP SHA256  17d3c80302c403309b2a5a6159d3ea7ebc443fccbc3df24219474f06ff88f7ec
```

出力の `manifest.json` に各証拠のhash、ID/節/hint数、checkerの固定revisionと実行binary hash、
negative controlsの結果を残す。これらの外部実装も、本実装の形式的soundness証明ではない。

### 外部checkerのnegative controlで判明した制約

同じDRAT-trim repoの古い `lrat-check.c` は、SATな入力 `p cnf 1 1` / `1 0` に対する偽の
`2 0 0` を `c VERIFIED`・exit 0で受理した。この最小例を実際に再現し、
[既報のregression #42](https://github.com/marijnheule/drat-trim/issues/42) と一致したため、
このbinaryはadapterの検査器に使わない。LRAT-TRIMとDRAT-trimは同じnegative controlを拒否した。
また、固定版DRAT-trimは原CNFが空節を含むtrivial UNSAT時にVERIFIEDでもexit 1を返す。
adapterは入力に実際の空節がある場合だけ、この終了値を認める。

```sh
# 通常はローカルへexportするだけ。--check時に固定sourceを取得・buildする。
python3 tools/generate_ruplog.py --check --miter64 --cpu 10
```

成果物は既定で `.tools/ruplog-export/`、外部checkerのcacheは `.tools/ruplog-checkers/` に置く。
環境変数 `MORPH_RUPLOG_EXPORT` はテストadapterだけが読み、通常のテストではexportしない。

## 節ID再検索を除く単独候補を一度白箱へ隔離

`1017d72` と同じ共有Core/Binary基盤で、occurrence indexとwork queueに節IDの代わりに
不変の `Entry` 参照を保持する候補を比較した。各queue訪問でclause-ID trieを引く処理を除く。
節もIDも順序も同じであり、候補が生成するcertificateはhint列を含めて元のbuilderと一致した。
この段階では候補を `references_wbtest.mbt` に残し、productionは節ID再検索のままとした。
次節では別の改善と合成し、同じ全query比較を再実施している。

同じnative release ELF、CPU 10、共通mutex、各10サンプルのABBA比較：

| 準備済み64bit proofのbuilder | 平均 ± 標準偏差 |
| --- | ---: |
| 節ID、最初のcontrol | 75.19 ms ± 6.78 ms |
| 節参照 | 62.32 ms ± 3.86 ms |
| 節参照、繰り返しcontrol | 61.76 ms ± 2.92 ms |
| 節ID、繰り返しcontrol | 75.39 ms ± 3.57 ms |
| 未変更の準備済みhint checker | 15.95 ms ± 332.29 µs |

builder単体では改善した。しかし毎回startup・探索・入力準備・builder・独立checkerを含む
全queryを20対、順序を交互に変えて実行すると、節IDが314.89 ms ± 10.09 ms、
節参照が316.04 ms ± 27.56 msだった。節参照は13/20対で速く、対差は平均−1.15 ms、
標準偏差32.59 ms、比の中央値1.0394、範囲0.8074–1.1178。実行順グループ間でも方向が
揃わず、全queryの改善を確定できないため単独の既定採用は見送った。
このcontrolは15.20 ms ± 614.97 µs。固定1,000個六変数cohortの全queryも
45.25 ms ± 2.63 ms対44.18 ms ± 950.26 µsで区間が重なる。うちUNSATは219個。

別のstage測定では全学習節の正規化が2.96 ms ± 84.79 µs、節参照builder全体が
58.78 ms ± 1.89 msだった。この条件では正規化sortの変更より伝播側を優先する。
各stageは独立したclosureであり、単純に差し引いた値を厳密なprofileとは扱わない。

三変数の全二節CNF×candidate lemma、合計19,683列（受理・拒否の両方）、原空節、重複、
tautology、65535ラベル、64bit miter、上記cohortでcertificateの完全一致を確認した。
候補を一時的にproductionへ選択した状態では13 RUPLOG testsがnative/JS/Wasm GCで通過し、
deny-warn、purity、外部16 positive/7 negativeも通過した。外部CNF/DRUP hashは不変。
白箱へ隔離し直した後のnative回帰とdeny-warnも通過した。

最初の比較ELF SHA256は
`9c9bc6d5fe11d66030d3497eb57d722dea4f00f9f8ba4f9934297e66960edac3`。
ELFとraw logsは `.tools/cdcl-profile/references-*` に保存した。

```sh
/home/hosi/morph/tools/measure --cpu 10 tools/moon bench src/ruplog/references_wbtest.mbt --target native --release -i 1
/home/hosi/morph/tools/measure --cpu 10 tools/moon bench src/ruplog/references_wbtest.mbt --target native --release -i 2
/home/hosi/morph/tools/measure --cpu 10 tools/moon bench src/ruplog/references_wbtest.mbt --target native --release -i 3
```

## 非unitの早期確定と節参照共有を合成して採用

builderはunitまたはconflictだけに反応する。節中に二つの未割当literalが見つかれば、
残りを検査せず非unitとして終了できる。最初の未割当literalを引数で保持し、偽literalを
tail recursionで飛ばす。`Open` と `Satisfied` はともに「何も伝播しない」の内部状態であり、
早期終了した `Open` には既に満たされた節も含み得る。checkerの完全な節評価は変更しない。
この早期終了と、前節の不変節への直接参照を一緒に既定へ採用した。
節・unit・queueの順序、生成する全hint、追加ID、eraseしたRUPは変わらない。

同一native release ELF、CPU 10、共通mutex、各10サンプルのstage比較：

| 準備済み64bit builder | 平均 ± 標準偏差 |
| --- | ---: |
| 完全評価＋節ID、最初のcontrol | 81.13 ms ± 4.19 ms |
| 早期終了＋節ID | 63.73 ms ± 2.37 ms |
| 早期終了＋節参照 | 52.23 ms ± 1.13 ms |
| 早期終了＋節ID、繰り返しcontrol | 64.47 ms ± 2.77 ms |
| 完全評価＋節ID、繰り返しcontrol | 75.10 ms ± 2.91 ms |
| 未変更の準備済みhint checker | 16.49 ms ± 954.52 µs |

20対の交互全query比較では、早期終了だけの変更は324.30 ms ± 28.83 ms対
319.08 ms ± 69.78 ms、16/20勝だった。612.37 msのサンプルもあり、これだけでは
全体改善を確定しない。合成候補を別の20対で比較した結果は次の通り。

| 64bit全query | 完全評価＋節ID | 早期終了＋節参照 |
| --- | ---: | ---: |
| 同一ELF内、最初の20対 | 314.14 ms ± 7.41 ms | 284.44 ms ± 7.58 ms |
| productionへ選択後の別ELF内、20対 | 325.55 ms ± 44.58 ms | 312.95 ms ± 53.29 ms |

最初は20/20対で合成候補が速く、対差は29.70 ms ± 10.62 ms、比中央値1.0906、
両実行順群とも10/10勝。平均全queryは約9.45%短縮した。未変更checkerは
15.33 ms ± 553.09 µsだった。後の確認は17/20勝、対差12.60 ms ± 38.95 ms、
比中央値1.0822、両実行順群の平均方向も同じだった。ただし両側に大きいサンプルがあり、
後の平均短縮は約3.87%に留まる。どちらのログも残し、固定の9%改善とは主張しない。
後のcheckerは15.88 ms ± 531.58 µs。異なるELF同士の生時間を採否の比較には使わない。

選択後の同一ELFでpigeonhole 6 into 5の全queryは16.81 ms ± 459.62 µsから
13.94 ms ± 385.28 µsへ短縮した。固定1,000個六変数cohortは43.21 ms ± 946.20 µs対
43.27 ms ± 1.21 msで重なり、改善を主張しない。

旧完全評価、早期終了＋節ID、早期終了＋節参照を白箱で再現できるようにした。
三変数の全27節×27部分割当729組でunit/conflict actionを比較し、全19,683候補証拠列、
64bit miter、固定cohortではhint列を含むcertificateの完全一致を要求する。
採用後の15 RUPLOG testsがnative/JS/Wasm GC、deny-warn、purityを通過した。
外部16 positive/7 negativeも再検査し、CNF/DRUP hashは前と同一だった。

最初の全query比較ELFは `afcd046128ba5bd7abe39fc293aa7629a30f4067ca27948157da27b983e01e83`、
選択後ELFは `23179bdf6852f817828b002695c63fa30e2d609f998f2f1005f216a9f04a438e`。
ELFとraw logsを `.tools/cdcl-profile/early-open-*` に保存する。

```sh
/home/hosi/morph/tools/measure --cpu 10 tools/moon bench src/ruplog/early_open_wbtest.mbt --target native --release -i 1
/home/hosi/morph/tools/measure --cpu 10 tools/moon bench src/ruplog/early_open_wbtest.mbt --target native --release -i 2
/home/hosi/morph/tools/measure --cpu 10 tools/moon bench src/ruplog/early_open_wbtest.mbt --target native --release -i 3
/home/hosi/morph/tools/measure --cpu 10 tools/moon bench src/ruplog/early_open_wbtest.mbt --target native --release -i 5
```
