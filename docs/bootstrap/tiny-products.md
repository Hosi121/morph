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
共有 binary.mbt の変更は root 担当が行う。

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
