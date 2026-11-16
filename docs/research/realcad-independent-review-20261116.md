# realcad 独立レビュー（2026-11-16）

[ドキュメント](../README.md) / [研究・探索記録](README.md)

[研究記録](README.md) / [凍結した本体](../../src/realcad/machine.mbt)

対象は commit `64f703d` の `src/realcad`。今回の有限な検証範囲で、誤った分解・符号・真理値・完了判定を返す反例は見つからなかった。本体は変更していない。既存944件の SymPy 例を増やすだけでなく、**SymPy、Sturm 列、production 実行を使わない別の期待値経路**と、半開端点・gap refinement・全 fuel 境界の試験を追加した。

## 静的な所見

非零 atom の monic 積の squarefree 部分を共通根多項式とするため、その一根区間 `(a,b]` では各 atom の相異なる根数は零か一になる。一なら共通根そのものが atom の根。零なら区間内部の符号は一定であり、内部の有理中点がその符号を与える。下端 a に別の atom の根があっても、区間には含まれず、中点は内部なのでこの議論を壊さない。偶数重根でも相異なる根数を使う零判定は保持され、元の atom を評価するため monic 化による符号反転は失われない。

隣接根区間の上端と次の下端が接している場合、次の区間だけを細分する。そこに属する根は旧下端より厳密に大きいので、正確な二分を続ければ下端が動き、開セルを置く厳密な隙間ができる。これは停止までの一様な計算量上限を意味しない。

この所見はコードと数学上の前提の照合であり、Sturm・有理数・多項式演算を含む checker 全体の形式証明ではない。`check` と生成器は Sturm 計数・符号 helper を共有している。

## 別経路の Fraction / 二次体オラクル

[generator](../../tools/generate_realcad_review.py) は Python 標準ライブラリの `Fraction` だけを使う。多項式を、既知の有理一次因子、`(x−h)²−d`（d=2,3,5）、実根を持たない正の因子 `x²+1` と `x⁴+x²+1` から構成する。根は因子から既知であり、CAS の根探索や Euclid/Sturm は呼ばない。

全ての根を有理数または `a+b√d` として保持する。同じ二次体での加減乗算を Fraction で行い、`a` と `b√d` が異符号の場合は `a²` と `d*b²` の大小で符号を決める。これで根順序、各 atom の根上・開区間上の全符号、複雑な Boolean 式の真理値を厳密に計算する。

[32件の生成試験](../../src/realcad/independent_review_fixtures_wbtest.mbt) は全360セル、1,800個の atom 符号を比較する。次数・係数の範囲は以下。

- 最大 atom 次数10、非零 atom 積次数19。積の次数は squarefree 化前。
- 負の有理 scale、異なる分母、分母257の近接根、`3/7+1/127` 近傍の根。
- `±√2`、`±√3`、`±√5` と有理平行移動、これらに近い有理根。
- 偶数・奇数の重根、atom 間の共有根、実根を持たない正の因子、零・負の定数、重複 atom。
- 否定・論理積・論理和を入れ子にし、恒真式・矛盾式も同じ根集合上で比較。

[試験 helper](../../src/realcad/independent_review_wbtest.mbt) は返された各隔離区間に、期待された二次体の根が厳密に一つ含まれることも確認する。この判定は exact 有理数の平方比較だけを使い、Sturm 根数を参照しない。開セルの有理 sample が期待根間の正しい連結成分にあることも確認する。戻された真理値だけが偶然合う場合を避け、全 atom 符号列まで比較している。

## 半開端点・隙間・fuel・改竄

[境界レビュー試験](../../src/realcad/boundary_review_wbtest.mbt) は `x≥0 ∧ 257x−1≤0`、すなわち `[0,1/257]` を主に使う。

1. `(0,1/257]` と `(0,1]` は右根だけを表し、atom 符号は `[+,0]`。`(-1,0]` は左根を表して `[0,−]`。根なし・二根・逆向き・幅零の algebraic sample は拒否される。
2. 接した cover `(-1,0]`, `(0,1]` から Separation phase を開始する。最初の8細分では右下端は零のまま。9細分目に右区間が `(1/512,1/256]` となり、厳密な gap が生じる。sampling / completion を含む16ステップで正しい五セルへ到達する。
3. 通常の start からの完了ステップ数を独立に step で記録し、その前の**全 fuel 値**が Paused、ちょうどの fuel とそれ以上が同じ Complete になることを確認する。全ての途中 phase からの fuel零と再開も比較する。
4. 根の欠落・重複・逆順・重なり・二根区間・接した未分離 cover、セルの不足・重複、各 atom 符号を別の全符号へ置換、真理値反転、sample の移動、別 formula への証明書転用を拒否する。
5. 零係数の異なる表現、負の有理定数、canonical 化後の atom 重複が正しい一セルにまとまることを確認する。

接した cover 自体は Sturm の半開区間による隔離として有効でも、realcad の開セル生成には厳密な gap が必要であり、`check` は未分離の証明書を拒否する。この仕様と generator の追加 refinement は整合していた。

## 実行記録

最終結果は `.tools/realcad-review-20261116/validation.json` と `validation-*.log` に、UTC・コマンド・終了コード・非零試験数・経過時間を記録した。新規レビュー37件と既存5件の package 全体を native / JS / WasmGC で実行する。個々の既存 SymPy fixture は一つの test 内に944例を持つため、test 件数と例数は区別する。

| backend | test 件数 | 結果 | 実行時間 |
| --- | --- | --- | --- |
| native | 42 | 42 passed / 0 failed | 35.151秒 |
| JS | 42 | 42 passed / 0 failed | 24.196秒 |
| WasmGC | 42 | 42 passed / 0 failed | 22.507秒 |

全実行を `tools/measure --cpu 10` の共有 lock 内で行った。時間はコンパイルを含む package test の一回分であり、アルゴリズム単体の比較性能とは扱わない。

オラクルの係数・根・全符号・真理値は `.tools/realcad-review-20261116/fraction-oracle.json`。元の `src/realcad` の全 tracked file が凍結 snapshot と byte 一致することを検査し、SHA256 を `frozen-source.json` に保存した。fixture 再生成照合、formatter check、警告なし check、purity gate も実行する。

```sh
tools/measure --cpu 10 python3 tools/generate_realcad_review.py --check
tools/measure --cpu 10 tools/moon fmt --check src/realcad
tools/measure --cpu 10 tools/moon check src/realcad --deny-warn
tools/measure --cpu 10 tools/moon test src/realcad --target native
tools/measure --cpu 10 tools/moon test src/realcad --target js
tools/measure --cpu 10 tools/moon test src/realcad --target wasm-gc
```

## 残る範囲と引継ぎ

根の独立な期待値を持つ範囲は、有理一次因子と一つの二次体に分解できる上記の有限32例である。高次数ではあっても、一般の高次数既約多項式の代数根を網羅した検証ではない。有理演算は MoonBit helper と本体で共有され、独立な Python Fraction の期待値が追加の照合を与える。checker 全体の正しさや一般入力の停止・性能の証明は主張しない。

`AlgebraicPoint(interval)` は所有する Problem の根として解釈され、interval 自体が独立した実数表現ではない。別 Problem へ同じ interval を持ち込むと別の根を意味し得るため、Problem と sample の対を保つ必要がある。これは本体の既存の明示的な契約であり、今回の反例とは扱わない。

`prepare` と一つの fuel step の内部には入力依存の有理・多項式演算がある。fuel は壁時計やメモリの予算ではない。生成レビュー例は一例16,384ステップ、専用境界例は明示した256または16ステップを上限にし、未完了を成功とみなさない。

変更は新しい review test、専用 generator、この記録だけ。レビュー用 branch は `research/realcad-review-20261116`、元の BCH/GS branch `research/bch-20261116` と `.tools/bch-20261116` / `.tools/listdecode-20261116` は保存した。push / merge / deploy はしていない。統合担当による artifact 保存確認まで worktree とログを維持する。
