# Binary の共有定数

`zero()` と `one()` の返す値は不変であり、共有しても値と API は変わらない。
`constants.mbt` に package-private な `canonical_zero()` / `canonical_one()` を分離した。
公開 factory の body をこの helper に向ける二行の変更は、共有ファイル担当が適用する。

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
