# 8進単位のNat変換とLeanの対応

値を変えず、入力のNatを再構築せずに三bitずつ出力する変更を対象とする。
実装担当が関数の分岐対応を確認し、Lean 4.19.0と三backendの有限oracleを検査した。
この記録は実装担当自身の対応確認であり、独立した翻訳/refinement証明ではない。

| MoonBit | Lean | 対応 |
| --- | --- | --- |
| split_nat_grouped内walk | splitGroupedLoop | fast=0〜7の八分岐、slowの同じ個数のSucc除去、三Boolのlittle-endian順序が一致 |
| walkの再帰 | splitGroupedLoopのfast+8/slow+7 | fastを八つ、slowを七つ進め、既存tailへ再帰する |
| walkのfallback | splitGroupedLoopの最終分岐 | fast≤slowから到達不能。値の定理はその前提を明示する |
| split_nat_groupedのwalk(n,n) | splitGrouped | 同じ入力を両cursorの初期値にする |
| low_bit | lowBit | false/Nilだけを省き、他はConsを作る |
| from_nat_grouped内convert | fromNatGroupedBits | ZeroはNil、正なら商へ再帰し、上位から三回low_bitを重ねる |
| public from_natの保護wrapper | fromNat | Zeroはzero、Succ(Zero)はone、それ以外はgrouped helperへ委譲する |

商の不変式は`8*q+remainder=8*slow−7*fast`。余りは
`bit0+2*bit1+4*bit2`である。初期状態から`8*q+remainder=n`を導き、
正の入力では`q<n`を示して、変換のwell-founded recursionを検査する。
既存のCoreの半分化、split、旧converterの値の定理は残し、
旧converterだけを`fromNatByHalves`へ改名した。主張を有限例へ切り詰めていない。

`lowBit_sound`は値を保存する。別の`lowBit_canonical`は正規なtailから
正規な列を作ることを示し、`fromNat_canonical`が全自然数への正規性を示す。
ここで正規性は「Nil、または最高位bitがtrueの有限Chain」というモデル内の性質である。
値の保存だけでは高位0の追加を検出できないため、両方を別々に検査する。

`zero_sound`/`one_sound`/`lowBit_sound`は公理なし、`lowBit_canonical`は標準propextのみ。
商・停止性・変換値・変換の正規性の定理は標準propext/Quot.soundのみを使う。
独自の正しさ公理、sorry、unsafe、partialは導入しない。
全モデルのaxiom出力は[nat-radix-lean.txt](../docs/measurements/nat-radix-lean.txt)。

Source lockにはsplit_nat_grouped/from_nat_grouped/low_bitに加え、zero/one、
canonical_zero/canonical_one、canonical_zero_value/canonical_one_valueを追加し、計19領域とした。
二つのglobalは関数とは別に型付きBinary recordのinitializer全体をlockする。
コメントと空白は除外するが、true/falseの変更は検出する。aliasへ変える場合も明示的な再レビューが必要となる。
公開wrapperは統合担当が適用した後に再レビュー・再記録する。
rootは八つのbase分岐の余りbit順、八つ/七つ進む再帰、low_bitとfactoryのaliasを
モデルと照合し、公開wrapperの0/1/それ以外の分岐を適用した。
同じ値と正規性の主張を維持したまま19領域lockを再記録し、全Leanモデルを再検査した。
値1の余りを0へ変える変更と低bitを捨てる変更はsource drift gateが拒否し、
Leanの不正余りは商の不変式を証明できない。高位0を残す変更は正規性の証明を壊す。
negative controlは一時コピーだけで行い、正常source/modelは復元した。

MoonBitのNatとLean Nat、Chain型、Binary recordの同一視は引き続き人手の対応である。
zero/one factoryの共有そのものは別担当の実装である。今回の対応確認では
不変global→private helper→public factoryのaliasをLeanでも写し、
zero_sound/one_soundを公理なしで検査した。値が0/1という前提だけを未lockの依存に残さない。
実行時のglobal初期化と物理的な共有は三backendの有限oracle/計測の境界に残る。
Leanは物理的なtail共有、実際の割当数、全入力のstack/heap上限、コンパイラの正しさを証明しない。
0〜4096の商・三bit余り、0〜1024と8進境界・Nat200001の厳密なBinary比較は別の実行証拠である。
