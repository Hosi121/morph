# 小さな差を既存の不変値から返す

LLL3x3 の現行生成 C で、非同値の四 bit Binary.subtract が 1,397,110 回、
その生成 C malloc が 7,318,707 回だった。同値は 204,193 回 / 601,832 malloc、
より大きい入力は 720,049 回 / 7,125,261 malloc。計数版の時間は採否に使わない。

compare 先行と lookup 先行を同じ ELF で比較した。前者は Less を None、Equal を
既存 cached Some(zero)、Greater だけを正の差表へ送る。後者は四 bit 全域を
不変 global の二重 Option とし、None=外域、Some(None)=既知 underflow、
Some(Some(value))=既知の差、と区別する。結果の Binary/内側 Some は既存
`tiny_product_value_0..15` を再利用し、追加は外側の不変 outcome 十七個だけである。

両案は零の単位則と同値 zero shortcut を持ち、外域は既存 compare/subtract_bits/from_bits へ戻す。
幅 guard を大きい表本体から分離し、外域で大きな lookup 関数を呼ばない構成へ改めた。

| 同一 ELF の非零 small225、十 batch、CPU8 | 旧式 | compare 先行 | lookup 先行 |
| --- | ---: | ---: | ---: |
| Native | 9.78 ± 0.57 µs | 2.95 ± 0.09 µs | 2.70 ± 0.13 µs |
| JS | 7.64 ± 0.37 µs | 3.55 ± 0.17 µs | 2.69 ± 0.12 µs |
| Wasm GC | 5.71 ± 0.23 µs | 3.03 ± 0.07 µs | 2.99 ± 0.06 µs |

Native/JS の結果から lookup 先行を候補に選んだ。Wasm GC の両案の差は小さい。
byte128 外域 control は Native 11.30→11.43 µs、JS 6.86→6.97 µs で範囲が重なる。
Wasm GC は 4.76→5.13 µs で小さい悪化の可能性があり、全入力での改善を主張しない。
wide7 は Native 9.96→5.98、JS 6.17→4.19、Wasm GC 4.13→2.69 µs だが、
この短縮には共通の零/同値 shortcut が含まれ、差表だけの効果とは呼ばない。

両候補の全 65,536 byte 対を独立整数 oracle と比較した。
選定した `subtract_adaptively` も全 byte 対と 64/127/512/2048 bit の零・同値・underflow を
Native/JS/Wasm GC で検査した。外域/underflow の二重 Option の区別も検査した。
生成物 --check と purity gate は通過した。核へ machine 数値、配列、可変、FFI は追加しない。

公開 `subtract` の wrapper は共有ファイル担当が `subtract_adaptively(a,b)` へ向ける。
`python3 tools/generate_binary_tiny_differences.py --check --winner lookup` で生成物を照合できる。
通常試験は Python を実行しない。比較と試験ログは `docs/measurements/tiny-differences-initial.txt`。
上位の採否は wrapper 適用後の保存 ELF 比較で確認する。
