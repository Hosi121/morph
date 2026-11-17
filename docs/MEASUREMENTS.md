# 計測記録

[ドキュメント](README.md) / [基礎部品の最適化](KERNELS.md)

比較条件と生データを探すための入口です。
通常経路への採否は[KERNELS](KERNELS.md)、値の正しさと検査範囲は[検証ガイド](VALIDATION.md)にまとめています。

## 計測値を読むとき

- ソース、入力、バックエンド、CPU、測定範囲を揃えた系列の中で比較します。
- 入力構築や証拠検査を含むかは、各記録の条件を確認します。
- 異なる系列の絶対時間や倍率を足し合わせたり掛け合わせたりしません。
- 同じ値を返すことと、その環境で速いことは別に検査します。

中央値・平均・標準偏差、タイムアウトの打切り値も区別します。
個別入力での改善を、全入力の速度保証へ一般化しません。

## 実数制約・SMTの比較

| 比較 | 条件・採否 | 生データ |
| --- | --- | --- |
| 全割当ての理論節 → 既存被覆からの原子削減 | [小さな理論衝突節](research/theory-core-20261117.md) | [native](measurements/theory-core-native-20261117.json)・[JS](measurements/theory-core-js-20261117.json)・[WasmGC](measurements/theory-core-wasm-gc-20261117.json) |
| 理論衝突後のCDCL再始動 → 状態保持 | [CDCL状態保持](research/retained-cdcl-20261117.md) | [native](measurements/retained-cdcl-native-20261117.json)・[JS](measurements/retained-cdcl-js-20261117.json)・[WasmGC](measurements/retained-cdcl-wasm-gc-20261117.json) |
| 完全CAD → 早期SAT終了・円柱の枝刈り | [必要なセルからの探索](research/incremental-cad-20261117.md) | [native](measurements/incremental-cad-native-20261117.json)・[JS](measurements/incremental-cad-js-20261117.json)・[WasmGC](measurements/incremental-cad-wasm-gc-20261117.json) |

各系列は同じartifact内の二方式を比較し、準備・探索・最終検査の内訳を記録しています。
新しい系列でも共通checkerが変わる場合があるため、過去のGit版との直接の速度比とは区別します。
未完了のstress例や改善の見えない対照も、各設計記録へ残しています。

## 複素根の列挙

[因数分解を先行する経路と直接列挙](research/complex-algebra-20261117.md#同じartifactでの費用比較)を、
同じnative release artifactで比較しました。
混合因子の一入力について、先行する経路は6回完了、直接列挙は6回とも5秒で打ち切りました。
未完了の時間を平均や速度倍率へ置き換えません。
[試行順序・hash・生データ](measurements/complex-roots-native-20261117.json)を保存しています。

## 複素数体での反復演算

[二座標演算と K(i) の固定基底](research/complex-fields-20261117.md#同じ入力最終検査での比較)を、
各入力の同じ native release artifact、CPU固定、入力準備と最終検査を含めて比較しました。
平方では両方が6回完了し、中央値は1.752msと1.109ms。
八乗では固定基底が6回完了して中央値1.168ms、一般演算は6回とも5秒で打ち切りました。
短時間例の起動費用・揺れと、八乗の打切りを保った記録であり、一般的な倍率を示しません。
[平方](measurements/complex-field-square-native-20261117.json)・[八乗](measurements/complex-field-native-20261117.json)に全試行があります。

## 最小分解体の構成

QQ三次式から最小分解体までの[一般経路と専用経路の比較](research/complex-splitting-20261117.md#同じartifactでの三次式の比較)も記録しています。
同じnative release artifact・CPU固定・最終checker込みで、専用経路は `t³−2` が中央値2.375秒、
`t³−1` が1.168秒で各6回完了。一般経路は両入力とも6回を各5秒で打ち切りました。
未完了の倍率は計算せず、[三乗根2](measurements/splitting-cubic-native-20261117.json)と
[1の三乗根](measurements/splitting-unity-native-20261117.json)に全試行を残しています。

## 群・不等式・位相をつなぐ実行例

コード `d1e738c` の同じnative release artifactで、五つの異なる処理を各3回測りました。
Core Ultra 7 255H、WSL2、CPU 4固定。プロセス起動、例の構築、準備、計算、
各例の結果検査を含み、コンパイルを除きます。全15試行が掲載出力と一致しました。
異なる入力・処理の時間なので、行同士から算法の速度比は計算しません。

| 実行例に含まれる処理 | 中央値 |
| --- | ---: |
| S4・A5・S5の全群生成、導来列と再計算検査 | 87.461 ms |
| 二次式のBernstein包囲・細分証明・CADの別経路・端点の反例 | 1.073 ms |
| 円・円板・球面・射影平面のH0/H1/H2と整数証拠検査 | 7.365 ms |
| 五つの群表示の可換化と、射影平面・トーラスの単体H1との比較 | 9.392 ms |
| `z³−2` の分解体・全Galois作用・導来列・入力と結果に束縛した検査 | 14.752秒 |

最後の行は、以前の「分解体まで」の2.375秒より広い処理を含むため、直接の比較には使いません。
短い処理には起動費用と揺れも含み、三試行から一般の実用規模を保証しません。
入力と検査内容は[掲載出力](CONNECTIONS_TOUR.txt)、
全生値・source manifest・artifact hashは[計測データ](measurements/connections-native-20261117.json)にあります。

```sh
tools/measure --cpu 4 tools/moon build src/cmd/connections --target native --release -j 1
tools/measure --cpu 4 python3 tools/measure_connections.py \
  --artifact _build/native/release/build/cmd/connections/connections.exe \
  --repetitions 3 --timeout-seconds 30 --output .tools/connections.json
```

## 再現する

Linuxで、既存被覆による理論節削減を一つの入力について比較する例です。
CPU番号は環境に合わせて選びます。その他のバックエンド・入力・方式は
[比較器](../tools/compare_incremental_cad.py)の `--help` と各記録を参照してください。

```sh
tools/measure --cpu 4 tools/moon build src/cmd/incrementalbench --target native --release
tools/measure --cpu 4 python3 tools/compare_incremental_cad.py \
  --artifact _build/native/release/build/cmd/incrementalbench/incrementalbench.exe \
  --layer smt --modes retained core --abba-repetitions 3 \
  --case squares-unsat4 --output .tools/theory-core-comparison.json
```

基礎算術・有限体・SAT核などの比較は、[最適化の採用一覧](KERNELS.md)と
[分野別の探索記録](bootstrap/README.md)から辿れます。

## 初回探索の記録

<details>
<summary>2026-11-15の比較条件・結果・再現コマンド</summary>

以下は初回探索時の記録です。当時の入力、コード、環境に対する値を保存しています。

## 初回探索終了時の連続実行

初回探索の共有算術と行基本変形を含む版で、native releaseの全13ベンチグループを通した。
同じ機械・入力・10サンプルという条件で、主な平均は次の通り。

| 例 | 平均 ± 標準偏差 |
| --- | ---: |
| 24頂点Warshall | 357.43 ±6.23 µs |
| 9×9数独の構築・検査・探索・復元 | 128.86 ±4.40 ms |
| 三変数coupled Gröbner系 | 56.05 ±0.79 µs |
| 二段階単体法の例 | 39.47 ±0.64 µs |
| Sturm五次式の全実根隔離 | 88.28 ±1.29 µs |
| 2048bit Karatsuba | 14.09 ±0.55 ms |

個別の変更前後を比較した表とは別の連続実行である。
例えば数独は個別計測の121.81msと、この実行の128.86msで値が変わる。
過去の比較倍率が最終版の全実行で保たれるとは扱わず、条件と生ログを併記する。
有理数の整理が他の計算へ波及する一方、実行環境の変動や処理の内訳も残る。

[全結果の生ログ](measurements/final-native-benchmarks.txt)。
正しさのnative検証は[166テストのログ](measurements/native-validation.txt)にある。

```sh
tools/moon bench src/benchmarks --target native --release
tools/moon test --target native
```

## 2026-11-15：有理数と有限体の行基本変形の共有

比較前の核は `d80424d`。同じnative release環境、各10サンプル、
行列 `[[3,1,0,2],[1,4,1,0],[0,1,5,1],[2,0,1,6]]` の厳密逆行列全体を測る。
行列の入力構築は除外。有理数専用版119.50±2.13µs、Field辞書を渡す共有版118.47±2.27µs。
範囲が重なっており、速度差を成果として主張しない。
共通化の目的は、同じpivot・行消去を有限体にも使い、実装の分岐を避けること。

生ログ：[前](measurements/field-linear-before.txt)、[後](measurements/field-linear-after.txt)。再現：

```sh
tools/moon bench src/benchmarks/linear_test.mbt --target native --release
```

## 2026-11-15：連想リストと永続AVLの同じ検索

native release、各10サンプル。キー0..1023をBinaryへ変換し、値はその平方。
構築は計測範囲外で、同じ順序の検索 `[0,127,511,1023,1024]` を毎回行う。
最後は存在しないキー。両者とも比較は同じbinary.compareを使う。

| 辞書 | 5検索の平均 | 標準偏差 |
| --- | ---: | ---: |
| 昇順の連想リスト | 36.84 µs | 1.03 µs |
| 昇順挿入した永続AVL | 411.00 ns | 10.73 ns |

この検索集合では約89.6倍。更新・構築・メモリ量を含む優劣や、全検索分布での倍率ではない。
核はどちらも不変リスト/木とBool二進数のみで、配列やネイティブMapは使わない。
生ログ：[avl.txt](measurements/avl.txt)。再現：

```sh
tools/moon bench src/benchmarks/avl_test.mbt --target native --release
```

## 2026-11-15：有理数の交差約分を共通核へ戻す

比較前の核は `39528d8`。同じnative release環境、各10サンプル。
入力構築は除外し、単体法は台帳初期化から解まで、Sturmはsquarefree化・列構築・隔離まで含む。
ベンチの入力と出力仕様、正確な有理数表現を維持した。

| 入力 | 積を作ってから正規化 | 交差約分と恒等則 | 比率 |
| --- | ---: | ---: | ---: |
| 128桁の二進因子を持つ有理数と逆数の積 | 467.14 ±13.38 µs | 111.73 ±3.27 µs | 約4.18倍 |
| 共通127bit分母の和 | 905.53 ±9.28 µs | 61.23 ±0.84 µs | 約14.79倍 |
| 負の右辺を含む二段階単体法、最適値8/3 | 131.72 ±3.01 µs | 40.81 ±1.49 µs | 約3.23倍 |
| x⁵−x−1のSturm列と全実根隔離 | 220.82 ±5.20 µs | 92.28 ±4.21 µs | 約2.39倍 |

和は分母のgcdからLCMを作り、追加の約分はそのgcdの因子だけで行う。
積は互いの分子・分母を先に約分する。巨大な中間積と、その後の大きなgcdを避ける。
入力が既約である不変条件が必要で、APIからは非既約のRationalを作れない。
全23409組の小さい分数で整数分子・分母のオラクルと一致し、256bitの打ち消しも検査した。

途中の交差約分だけの案では、単体法が203.59 µsに悪化した。
そこで0、±1、除数1の恒等則を共有し、小さな整数係数が多い用途でgcdや除算を省いた。
マイクロベンチだけの改善で採用せず、上位のアルゴリズムも測る必要があった。
他の係数分布・大きさ・backendで同じ比率になる保証はない。

生ログ：[前](measurements/rational-before.txt)、[交差約分だけ](measurements/rational-cancel.txt)、
[採用版](measurements/rational-after.txt)。再現：

```sh
tools/moon bench src/benchmarks/rational_test.mbt --target native --release
```

## 2026-11-15：Warshall の一列抽出

比較条件：同じローカル環境、moon 0.1.20261104 / moonc v0.10.20、native release。
入力は24頂点、対角true、それ以外は `(i*17+j*7)%11<2` のBool隣接行列。
入力構築と型の検査は計測範囲外。各10サンプル、ベンチランナーがbatch数を調整。

| 実装 | 平均 | 標準偏差 | 範囲 |
| --- | ---: | ---: | ---: |
| 各pivotで全行列を転置 | 665.55 µs | 19.98 µs | 645.09–704.07 µs |
| 必要な一列だけ抽出 | 361.14 µs | 10.78 µs | 348.26–378.28 µs |

この入力では約45.7%短縮、約1.84倍。正確さ、入力、半環、表現、backendを維持した比較。
全用途・他backend・大規模グラフで同じ比率になるという主張ではない。
一列を得るために作る中間リストの要素数を、pivot全体で O(n³) から O(n²) に減らした。
行列更新自体の O(n³) は変わらない。

生ログ：[変更前](measurements/warshall-before.txt)、[変更後](measurements/warshall-after.txt)。
変更前の核は `6ca4675`。再現コマンド：

```sh
tools/moon bench src/benchmarks --target native --release
```

## 2026-11-15：冪等置換の値域を共有する

同じ native release 環境。深さ6の共有された二分項（木として展開すると127ノード）へ
一変数を束縛した置換を、事前に作成しておく。その変数への apply だけを計測した。
置換作成・値域の正規化は計測範囲外。各10サンプル。

| 実装 | 平均 | 標準偏差 |
| --- | ---: | ---: |
| 束縛値を再帰走査して再構築 | 2.69 µs | 41.22 ns |
| 正規化済みの束縛値を共有 | 9.08 ns | 1.11 ns |

この参照操作だけでは約300倍。型推論全体や単一化全体の速度比ではない。
前提は、置換のどの値域にも置換の定義域の変数が残っていないこと。
bind が新しい束縛を全既存値域へ合成するため、値域の再走査を省ける。
この不変条件を、単一化が成功する全有限項ペアのテストで明示的に確認した。

生ログ：[変更前](measurements/unify-before.txt)、[変更後](measurements/unify-after.txt)。
変更前の核は `d96d4f9`。再現：

```sh
tools/moon bench src/benchmarks/unify_test.mbt --target native --release
```

## 2026-11-15：Buchberger の積判定

同じ native release、各10サンプル。入力構築は範囲外で、基底計算全体を測定。
比較前の核は `79c4fb1`。

| 三変数の入力系 | 全Sペアを除算 | 先頭単項式が互いに素なら省略 |
| --- | ---: | ---: |
| x²−1, y²−1, z²−1 | 18.51 µs ± 0.41 µs | 4.48 µs ± 0.14 µs |
| xy−z, yz−x, zx−y | 184.06 µs ± 4.62 µs | 111.19 µs ± 1.69 µs |

この二系では約75.8% / 39.6%短縮。Buchberger の product criterion により、
先頭単項式の支持が交わらないペアのS多項式は生成・除算せずに処理済みにできる。
全45系の SymPy fixture とS多項式検証を維持した。一般の系での速度比ではない。
燃料は省略したペアも一回と数え、予算の意味を維持する。

生ログ：[変更前](measurements/groebner-before.txt)、[変更後](measurements/groebner-after.txt)。

```sh
tools/moon bench src/benchmarks/groebner_test.mbt --target native --release
```

## 2026-11-15：学校式と Karatsuba の二進乗算

同じ canonical Bool リスト、native release、各10サンプル。
入力構築を除外し、生成された積を保持する。Karatsuba は64ビット以下の片方の入力が
あれば学校式へ切り替える。入力のビットパターンは benchmark ソースに固定。

| 桁数 | 学校式 | Karatsuba |
| --- | ---: | ---: |
| 128 | 155.45 ± 4.67 µs | 151.66 ± 2.58 µs |
| 512 | 2.63 ± 0.03 ms | 1.48 ± 0.04 ms |
| 2048 | 41.57 ± 0.71 ms | 13.45 ± 0.24 ms |

128桁では差が小さく、明確な優位とは判定しない。この入力では512桁で約1.78倍、
2048桁で約3.09倍。短い整数の標準 API はそのままにし、大きい値には `karatsuba` を明示して選べる。
他backendや疎なビット列で同じ比率になるという主張ではない。

生ログ：[比較](measurements/karatsuba.txt)。

```sh
tools/moon bench src/benchmarks/multiply_test.mbt --target native --release
```

## 2026-11-15：exact cover の制約IDを二進表現へキャッシュ

同じ9×9数独、native release、各10サンプル。
手掛かりの表示アダプターからNatへの変換は範囲外。
候補の生成・入力検査・ID変換・探索・座標復元・整列まで、`puzzles.sudoku` 全体を測る。
前の核は `5705ce7`。

| 内部の制約ID | 平均 | 標準偏差 |
| --- | ---: | ---: |
| 比較のたびにPeanoの値を走査 | 1.07 s | 9.65 ms |
| 探索用に二進IDをキャッシュ | 139.55 ms | 1.86 ms |
| 入力検査もキャッシュされたIDで共通化 | 121.81 ms | 2.90 ms |

最終版はこの問題で約8.8倍、約88.6%短縮。公開のNat型・問題・返る解は同じで、
整数型や配列への置換はない。二進IDの生成コストも測定に含む。
検査器は元のNat制約で被覆回数を調べ、キャッシュ表現に依存させていない。
キャッシュ分のメモリは追加している。一般のパズルの速度比ではない。

生ログ：[前](measurements/sudoku-before.txt)、[探索だけ変更](measurements/sudoku-search-cache.txt)、[最終](measurements/sudoku-after.txt)。

```sh
tools/moon bench src/benchmarks/sudoku_test.mbt --target native --release
```

</details>
