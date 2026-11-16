# 四 bit の積を不変の Bool Chain として共有する

LLL 3x3 の既存生成 C を計測用に instrument すると、非恒等の Binary.multiply のうち
3〜15 同士が 1,641,822 回、より大きな一般積が 44,135 回だった。
前者が非恒等積の 97.4% を占め、割当は 19,993,155 対 873,873 回で 95.8% を占めた。
零/一/二の恒等経路を含めた全 Binary.multiply の割当では前者は 91.2% となる。
この入力分布は固定 fixture のものであり、任意の行列についての主張ではない。
Integer quotient wrapper の削減はこの割当群に比べて小さいと分かったため、
次の一問を小さい積そのものの共有へ絞った。

`tiny_products.mbt` は canonical な零〜十五の Bool Chain 二つを完全に pattern match する。
全 256 組は 90 種類の `Some(Binary)` 結果を不変 global として共有し、それ以外は `None` を返す。
Some wrapper も共有するので lookup ごとの Option 構築を避ける。
算術と数値 literal は生成用 Python と試験 oracle にだけ置き、kernel は Bool/Chain/Option/Binary だけを使う。
生成値は既に canonical なので、initialization 時の trim も要らない。

既存 multiply の零/一/二の経路を先に残し、一般経路だけで lookup を試す候補を WB で測った。
表から外れた入力には従来の `multiply_bits` をそのまま呼ぶ。
共有 binary.mbt の最後の一般経路へ root 担当が接続し、main `7bfe78c` へ採用した。

| 同一 ELF、十 batch、CPU8 | 従来の再帰積 | 表を使う候補 |
| --- | ---: | ---: |
| Native の 3〜15 積 169 組 | 26.58 ± 0.70 µs | 2.18 ± 0.05 µs |
| Native の byte 混合 128 組 | 64.37 ± 1.09 µs | 62.40 ± 0.81 µs |
| Native の wide control 三組 | 128.62 ± 3.75 µs | 129.06 ± 3.47 µs |
| JS の 3〜15 積 169 組 | 13.29 ± 1.15 µs | 2.39 ± 0.09 µs |
| Wasm GC の 3〜15 積 169 組 | 8.75 ± 0.77 µs | 2.45 ± 0.09 µs |

Native の生成 C に allocator counter を置いた場合、同じ 169 組の callback は
2,634→169 割当だった。残った 169 回は各 `bench.keep` の共通 Ref wrapper であり、
表 lookup/積自体には割当が残らないことを C の本体でも確認した。
この counter 版の時間は採否に使わない。表の import/startup initialization は測定から除外している。
従来より多い 90 個の結果とその Chain を起動時に保持する費用がある。

0〜255 の全 65,536 対で候補を独立 Int32 積と比較し、private lookup は両方が
十六未満のときだけ Some を返すことも検査した。Native/JS/Wasm GC のすべてで通過した。
これには十五/十六の境界、片側だけ表に収まる場合、零/一/二の API 挙動を含む。
手書き kernel の purity gate は machine 数値・配列・可変・FFI を検出しなかった。

`python3 tools/generate_binary_tiny_products.py --check` で整形済み生成物を再照合できる。
通常の MoonBit 試験は Python を実行せず、commit 済みデータを使う。
生ログは `docs/measurements/tiny-products-initial.txt`。
実利用経路の効果は、公開 multiply に適用した保存 ELF と旧 ELF の ABBA 比較で別途確認する。


## 公開経路の上位比較と実割当

公開 multiply の dispatch hunk だけを direct-subtraction 基盤へ適用し、後続の
Nat converter / comparator 変更は混ぜずに保存 ELF を作った。
CPU8、共通 flock、Native release、ABBA 二巡。表は四実行それぞれの平均値の範囲で、
各実行は十 batch を含む。

| 固定 fixture | 再帰積の実行平均 µs | 小積表ありの実行平均 µs |
| --- | ---: | ---: |
| LLL 3x3 | 135.00–143.83 | 115.47–124.11 |
| LLL checker | 8.91–9.15 | 8.59–8.90 |
| LLL 3x4 | 151.93–161.02 | 136.60–142.36 |
| Smith+LLL 依存 3x4 | 158.64–168.05 | 146.23–152.97 |
| Smith 3x3 | 23.32–24.41 | 21.76–22.28 |
| Smith checker | 8.80–9.00 | 7.82–8.03 |
| simplex | 11.93–12.38 | 11.68–12.13 |

LLL の三生成群と Smith の生成/checker で短縮を観測した。
LLL checker は小差、simplex は範囲が重なるため、この二群の改善は主張しない。
生 batch 統計・ELF hash・wall/CPU 秒は `tiny-products-{lll,upper}.json` に保存した。

LLL3x3 callback 全体の生成 C allocator 実行数は、一回あたり 12,367→10,102。
共通の `bench.keep` 一回も含むが、差の 2,265 は実利用経路内の削減である。
計測 counter は通常 latency の比較には入れていない。
逆に、試験を一つも実行しない process の起動時生成 C allocator は 148→780。
追加 632 回は 544 Cons と 88 Binary wrapper に一致する。零/一は既存 alias を使い、
Native の Some はこの型では pointer 表現へ elide されていた。
この段階では runtime の積を安くする代わりに固定の startup/pinned-data 費用を増やしている。

起動と callback の counter 生ログは `docs/measurements/tiny-products-allocations.txt`。
必要 ELF/C/probe は worktree 外 `.tools/tiny-product-artifacts/` に hash 付き manifest とともに保存した。


## 不変 suffix DAG で startup の重複を除く

積表の九十結果は内容の等しい末尾を繰り返していた。
生成器で末尾の closure を求め、各非空 suffix を一度だけ Cons する不変 global に変えた。
零/一の既存 alias と各 Some global、公開 wrapper、lookup の pattern は維持した。
上位の wrapper 変更や machine 数値型を追加していない。

| 数えている対象 | flat literal | suffix DAG |
| --- | ---: | ---: |
| 論理的に異なる非空 suffix | 101 | 101 |
| Nil を含む論理 suffix | 102 | 102 |
| 表が追加する source Cons constructor | 544 | 100 |
| 表が追加する Native runtime Cons | 544 | 100 |
| 共通初期化を含む Native startup Bool Cons | 643 | 199 |
| 共通初期化を含む Native startup 全生成 C malloc | 780 | 336 |

DAG の百一 suffix のうち一は既存 canonical one の cell を使うため、追加 Cons は百となる。
八十八個の新 Binary wrapper は同じままで、追加 startup malloc は 632→188 に減った。
表の runtime Cons は、表なし共通初期化の九十九 Cons を差し引いた実行 counter から確認した。
論理的な distinct 値の数を、そのまま compiler の実割当と呼んでいない。
Native の生成 C に型別 Cons counter と allocator counter を置き、試験を一つも実行しない
`bench_wbtest.mbt:0-0` の process を比較した。他 backend の実 heap 数への外挿はしない。

Native 同一 ELF の lookup 169 組は flat 1.77 ± 0.06 µs、DAG 1.78 ± 0.11 µs で同等だった。
これは Option を返す lookup 本体であり、前の表の公開 multiply guards 込みの microbenchmark と直接比べない。
別の保存 ELF を CPU8 で ABBA 二巡、各欄二百 process 起動すると、whole process の平均範囲は
flat 496–592 µs、DAG 500–527 µs だった。範囲が重なるため process 起動時間の短縮は主張しない。
この時間には OS の process 起動、全 module の初期化、native driver の引数解析が含まれる。

変更後も byte の全 65,536 積を独立整数 oracle と比較し、flat/DAG の表は
境界を含む 289 組で同値かつ最高 bit が true の canonical 形であることを確認した。
この二群は Native / JS / Wasm GC のすべてで通過した。
生成物 --check と purity gate も通過した。

`python3 tools/generate_binary_tiny_products.py --flat-control` は比較用の一時 WB source を作る。
それを `tiny_products_flat_control_wbtest.mbt` として bench/test した後、通常 source から削除した。
再生成した対照・ELF・生成 C は `.tools/tiny-product-artifacts/` に保全している。
source の数は `tiny-products-dag-source-counts.json`、startup の各 batch は
`tiny-products-dag-startup-wall.json`、試験と counter のログは `tiny-products-suffix-dag.txt`。
