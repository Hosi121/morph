# realalgebraic 独立レビュー、2026-11-16

[研究・探索記録](README.md) / [実装記録](realalgebraic-20261116.md)

実装者とは別のエージェントが `7a33d59` と `c500327` を検査した。専有 worktree での依存取り込みはそれぞれ `e56b671` と `fe8fc67`。本体・F4・既存テスト・既存 generator は変更していない。追加は [レビュー専用テスト](../../src/realalgebraic/independent_review_wbtest.mbt)、[独立 resultant fixture](../../src/realalgebraic/independent_review_fixtures_wbtest.mbt)、[標準ライブラリだけの oracle](../../tools/generate_realalgebraic_review.py)、本記録である。

証拠内の別共役・無関係な結果の差替え、同一補間点を通る高次多項式、誤った区間 padding の誤受理は、今回の検査範囲では見つからなかった。一方、公開 `Progress` の payload と proof-only checker の間には、下記の明示すべき境界がある。これは producer が誤った数を返したという報告ではない。

## 独立 resultant oracle

既存の SymPy fixture を増やす方式ではなく、Python の `fractions.Fraction` だけで次の二つを別々に計算した。

1. 既知の有理根の全組について和・積を取り、その根を持つ monic 多項式を直接積で作る。二次 `x²−a, x²−b` については独立した閉形式 `x⁴−2(a+b)x²+(a−b)²` と `(x²−ab)²` も使う。
2. 固定 nominal degree の Sylvester 行列を構成し、全置換の符号付き積という Leibniz 公式で determinant を求める。補間・Gaussian elimination・SymPy・MoonBit の多項式演算は使用しない。

両 oracle が全点で一致することを Python 側で確認してから、入力・多項式全係数・全 determinant sample を [80 fixture](../../src/realalgebraic/independent_review_fixtures_wbtest.mbt) として固定した。degree bound は `1,2,3,4,6,9`。非モニック有理入力、重根、零根、複素根を持つ二次入力を含む。22 ケースは積変換の次数が nominal degree より常に低く、各ケースの `x=0` specialization は零多項式になる。それでも nominal size の determinant と期待する次数 `mn` の resultant が一致した。

各 fixture で `mn` sample の時点では `Paused`、もう一点で完成することを検査する。異なる多項式を全 sample に一致させるため `∏(x−i), i=0..mn` を加える攻撃も全 80 件で行い、sample 一致自体を確認したうえで degree bound により拒否されることを確認した。sample の欠落・余分な一点・一値だけの改ざんも拒否された。

数学的境界も確認した。monic な第一入力の根を `α_i` とすると、和は `∏Q(x−α_i)`、積は `∏(α_i^n Q(x/α_i))` に対応し、どちらも `x` に関して monic・次数 `mn`。`α_i=0` の積変換も固定次数の式として評価すると `x^n` になる。次数が高々 `mn` という条件と、異なる `mn+1` 点の完全一致を合わせて使うことが重要である。有限点一致だけを証拠として受理していない。

## 閉区間・半開区間と padding

半整数 endpoint 集合 `−2,−1,−1/2,0,1/2,1,2` の全 21 有効区間を組み合わせ、計 882 回の和・積 enclosure を、独立した機械整数の共通分母計算と照合した。積では符号にかかわらず四隅の全最小・最大を取り、二つの入力幅の和を両側に加える。和も独立式と一致した。

含まれる上端と内部中点の全組について、実際の値が padded range の**厳密な内部**に入ることを数値式で確認した。負の上端同士の積など、積の最小値が元の含まれる endpoint で達成される場合も対象に含める。従って `(lower,upper]` への変換で真の結果が新しい excluded lower endpoint に落ちる問題は起きていない。

同じ全 21 区間で negation と reciprocal を照合した。reciprocal は閉区間がゼロを避ける場合だけ計算し、padding が元区間の幅ではなく reciprocal range 自身の幅であることを独立式で確認した。下端ゼロを半開区間から除外していても、閉 relaxation がゼロに接すれば refine が必要という境界も確認した。

## 非 minimal 定義と共役選択

`x²−1` の二つの根と `x(x−2)` の二つの根を、上端 root を含む区間で全組選択し、和・積を既知の整数結果と比較した。resultant が同じ整数根を重複して持つ場合、零の積、定義に零根があるが選択した根は非零の場合も含む。

各演算証拠について、resultant の別の共役を示す**個別には有効な** `RootCertificate`、無関係な有効な `Number` の証拠、同じ値を示す別 interval、別共役の input refinement、異なる演算種への差替えを行った。証拠内の差替えは全て拒否された。同じ値の別 interval も拒否するのは、現在の証拠形式が再計算した enclosure の完全一致を要求するためであり、全ての正しい同値表現を受理する契約ではない。

無理数については `d=2,3` の `x(x²−d)` の正根と `x²−d` の負根を使い、和ゼロ・積 `−d`・逆数・負号・繰返し因子を持つ定義との等値を独立した恒等式で確認した。逆数で別の零根を除去して次数が下がる場合、選択根が零なら拒否される場合、零が元の excluded lower endpoint にある場合を検査した。

## 見つかった API 境界

既存の `check_arithmetic` / `check_unary` / `check_quotient` / `check_comparison` は、引数である**証拠そのもの**の中の結果と入力の関係を検査する。返却 wrapper の別フィールドは引数に含まれない。

公開 enum には、例えば外部から次の再構成が可能である。

```text
ArithmeticReady(unrelated_but_valid_Number, correct_certificate)
Compared(wrong_Ordering, correct_comparison_certificate)
```

このとき `check_arithmetic(correct_certificate)` や `check_comparison(correct_comparison_certificate)` は true のままであり、wrapper の payload を認証したことにはならない。同じ境界は unary / quotient にもある。レビューで、正しい producer の返した `Number` は証拠内 `result` と一致することを確認し、別の有効な Number に組み替えた場合との差を機械検査した。

これは証拠内 result の共役差替えが通るという問題ではない。producer が作った組を含めて外部で再検証する用途には、`root_certificate(value) == proof.result`（quotient は `proof.product.result`）、comparison は返却 Ordering と `proof.order` の一致も必要になる。root と実装者へ報告し、既存 proof-only API の役割を保ったまま値付き `check_*_result` を追加する別 fix の対象となった。本レビュー commit は本体を変更せず、新 API の追試は別記録・別 commit とする。

## 再現範囲と制約

追加レビューは resultant 80 テストと、区間・共役・API 境界の 4 テスト、計 84 テスト。既存 69 テストを含めると package は 153 テスト。

| 検査 | 結果 |
| --- | --- |
| review native / JS / Wasm GC、`--deny-warn` | それぞれ 84 passed / 0 failed |
| package native、`--deny-warn` | 153 passed / 0 failed |
| purity gate | 136 kernel files passed、この worktree の先行成果を含む |
| fixture 再生成 | byte 一致 |
| package fmt check | 成功 |

生成データ・specialization 次数・生ログ・コマンドは `.tools/realalgebraic-independent-review-20261116/` に保存する。

```sh
tools/measure --cpu 6 python3 tools/generate_realalgebraic_review.py
tools/measure --cpu 6 tools/moon test src/realalgebraic/independent_review_wbtest.mbt src/realalgebraic/independent_review_fixtures_wbtest.mbt --target native --deny-warn
tools/measure --cpu 6 tools/moon test src/realalgebraic --target native --deny-warn
```

検証は有限の次数・係数・区間に対するもの。任意次数の resultant、Sturm、exact rational 全体について機械化した証明を追加したわけではない。元の realalgebraic API は自己記述的な証拠を検査するため、外部の期待する入力とも別途対応を取る必要がある。実行時間・メモリ上限・最小多項式への最適化は対象外であり、今回の経過時間は性能 benchmark ではない。
