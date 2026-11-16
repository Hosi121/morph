# Binary の共有定数

[ドキュメント](../README.md) / [探索・改善記録](README.md)

`zero()` と `one()` の返す値は不変であり、共有しても値と API は変わらない。
`constants.mbt` に package-private な `canonical_zero()` / `canonical_one()` を分離した。
共有ファイル担当が公開 factory の body をこの helper に向け、main `66f48ae` で採用した。

Native release の生成 C を調べると、旧 `zero()` は Binary wrapper を一つ、
旧 `one()` は Bool Chain の Cons と Binary wrapper を一つずつ毎回割り当てる。
この版の compiler は、これらの関数を自動で global へ移していなかった。
共有版では三つの割当が initializer の一回だけになり、benchmark callback は
二つの global pointer を参照する。GC/RC による共有後の扱いまで省略したという意味ではない。

CPU 8 に固定した同一 ELF、各十標本の初回結果は、factory 二つの組が
22.04 ± 2.02 ns から 12.37 ± 2.85 ns。
現行 adaptive division を含めた 128 組の add/subtract/multiply/divmod/gcd 混合 cohort は
142.88 ± 5.18 µs と 142.83 ± 7.89 µs で、差は確認できなかった。
factory の局所差を全体の高速化として扱わない。

二つの factory 以外は同じ kernel を複製した WB 対照を
`tools/generate_binary_factory_control.py` で再生成できる。
65,536 組の八 bit 入力について共有版の add/multiply/divmod を数値 oracle と比較し、
gcd を production と比較した。Native release の対象試験は通過した。
手書き kernel の purity gate も通過した。

生ログは `docs/measurements/binary-constants-initial.txt`。
上位 exact/LLL の実利用経路については、同一 source snapshot の fresh/cached ELF を
保存して ABBA 順で再生し、`tools/compare_binary_factories.py` で記録する。


## 実利用経路と backend の確認

Core/Binary/exact/modular を main `c8edec0` と同一にした基盤で fresh ELF を保存し、
factory の body 二行だけを切り替えた cached ELF を保存した。Native release、CPU 8、
入力構築除外、共通 flock の下で before/after/after/before を二巡した。
下表は四実行それぞれの平均値の範囲であり、一実行の分散を合算した値ではない。
各実行は十 batch の統計を含む。

| 固定 fixture | fresh の実行平均範囲 µs | cached の実行平均範囲 µs |
| --- | ---: | ---: |
| LLL 3x3 | 149.29–161.50 | 138.12–140.57 |
| LLL checker | 9.86–10.86 | 8.71–9.53 |
| LLL 3x4 | 159.75–176.60 | 152.55–159.47 |
| Smith+LLL 依存 3x4 | 162.92–191.83 | 152.56–184.01 |
| Smith 3x3 | 23.14–27.14 | 22.06–23.54 |
| Smith checker | 9.20–10.14 | 8.56–9.17 |
| simplex | 13.52–14.14 | 12.39–12.95 |

LLL 3x3/checker/3x4 と simplex、Smith checker で短縮を観測した。
Smith生成と依存LLLは範囲が重なるため改善を主張しない。
同じ ELF 内でも host 周波数や外部負荷による変動があり、他の入力への倍率には使わない。
生の batch 統計・ELF SHA256・wall/child CPU 秒は
`docs/measurements/binary-constants-{lll,upper}.json` に保存した。

Native の実割当確認は、生成 C の `moonbit_malloc_inlined` 呼出しと二つの
benchmark callback の境界だけを計測用に instrument した。
同一 ELF の小入力混合 cohort 一回あたり fresh は 11,360、cached は 11,014 回で、
346 回（約 3%）減った。compiler の RC/reuse 分岐を通過した後の実行回数であり、
source 上の constructor 個数ではない。runtime 内の別の allocator 呼出しは数えない。
計測 counter の費用が入るため、この instrument 版の実行時間は採否に使わない。

JS の factory 二つは fresh 24.24 ± 3.07 ns、cached 15.36 ± 4.87 ns、
Wasm GC は fresh 18.94 ± 7.13 ns、cached 11.57 ± 0.87 ns だった。
この値にも import/startup の初期化は含まない。
Native/JS/Wasm GC で共有版の八 bit 全 65,536 対の oracle 試験を通過した。
追加生ログは `docs/measurements/binary-constants-backends.txt`。

必要な ELF・生成 C・allocation probe・初期候補 diff は削除対象の worktree の外へ
`.tools/binary-constant-artifacts/` として保存した。`manifest.json` に hash と基盤を記録している。
