# 本体からの静的参照と変換経路

`python3 tools/audit_paths.py --write`で生成する。
本体は通常の.mbt、test/demoは別集計。コメント・文字列・自己再帰は参照に数えない。
関数引数としての参照も含む。静的な字句参照であり、実行頻度や到達可能性の証明ではない。
内部参照がなくても、public APIは通常のライブラリ本体に含まれる。「テスト専用」とは区別する。

| symbol | 本体の参照 | test/demo参照 | 現在の分類 |
| --- | ---: | ---: | --- |
| `core.gcd` | 0 | 1 | 公開API・内部の呼出しなし |
| `core.interleave` | 0 | 1 | 公開API・内部の呼出しなし |
| `binary.stein_gcd` | 1 | 5 | 本体から参照あり |
| `binary.karatsuba` | 4 | 10 | 本体から参照あり |
| `core.half_nat` | 3 | 2 | 本体から参照あり |
| `core.halve_nat` | 3 | 2 | 本体から参照あり |
| `core.replicate_onto` | 2 | 5 | 本体から参照あり |

`runbinary`の他package本体からの参照：0ファイル。
現時点では独立した公開実装で、通常Binaryの代替backendとして全体へ組み込んだとは扱わない。

## 本体の参照位置

- `binary.stein_gcd`: [src/exact/exact.mbt:409](../src/exact/exact.mbt#L409)
- `binary.karatsuba`: [src/binary/number_theory.mbt:40](../src/binary/number_theory.mbt#L40), [src/binary/number_theory.mbt:48](../src/binary/number_theory.mbt#L48), [src/binary/number_theory.mbt:63](../src/binary/number_theory.mbt#L63), [src/binary/number_theory.mbt:64](../src/binary/number_theory.mbt#L64)
- `core.half_nat`: [src/cyclotomic/cyclotomic.mbt:58](../src/cyclotomic/cyclotomic.mbt#L58), [src/fppoly/irreducibility.mbt:96](../src/fppoly/irreducibility.mbt#L96), [src/fppoly/irreducibility.mbt:165](../src/fppoly/irreducibility.mbt#L165)
- `core.halve_nat`: [src/binary/binary.mbt:340](../src/binary/binary.mbt#L340), [src/core/natural.mbt:16](../src/core/natural.mbt#L16), [src/core/natural.mbt:26](../src/core/natural.mbt#L26)
- `core.replicate_onto`: [src/binary/binary.mbt:377](../src/binary/binary.mbt#L377), [src/core/data.mbt:87](../src/core/data.mbt#L87)

## 変換ゲートの範囲

直接のto_nat(from_nat(...))、逆方向の恒等変換、to_nat(half(from_nat(...)))を拒否する。
変数を介する経路や一般の意味の同値性はこの字句ゲートだけでは証明しない。
既約性検査の二箇所と円分体の半分化をcore.half_natへ変更し、Binaryのconverter自身もcore.halve_natを共有する。
IDの二進cache、係数/指数への入力変換、明示的な展開境界は別の意味を持つので一括置換しない。
残るto_natは、Fpのp乗根のstride、展開上限を検査するrunbinary.expand、SHAの有限padding長などの境界にある。
