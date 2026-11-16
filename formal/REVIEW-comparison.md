# Binary比較のtail化とモデルの対応

公開APIと厳密な比較の意味を維持して、長い列を戻りがけに処理する再帰を除く。
実装担当がsource/modelの対応を確認し、Leanと三backendの実行を検査した記録である。
実装担当とは別の独立レビューや翻訳/refinement証明を実施したとは主張しない。

| source | Comparison.lean | 対応 |
| --- | --- | --- |
| 固定旧compare_bits / WB reference | reference | Nil同士はEqual、長さ差を優先し、同幅は高位の結果を先に返す |
| 一node試作loop | loop | 高いbitの相違が過去orderingを上書きする |
| compare_bits_grouped内の四node分岐 | groupFourOrder / loop4 | 各groupの高いbitから相違を探し、両cursorを四つ進める |
| groupedのbase/余り分岐 | loop4 | 両Nilは過去ordering、異幅は長さ優先、一nodeずつの余りを処理 |
| compare_bits_grouped | groupedTail | 初期orderingがEqual |
| compare_bits_tail内stage_7〜stage_0 | peelを八回重ねたprotectedCompare | 各段は旧式の一段。最後だけgrouped helperへ委譲 |
| 通常compare_bits入口 | protectedCompare | 統合担当がhelperへのwrapperに置換して再lockする |

LeanのChainとMoonBitのcore.Chain、Ordering.lt/eq/gtとLess/Equal/Greaterの同一視は人手の対応である。
既存Binaryモデルのvalueとcanonicalを再利用し、変更していない。

`loop_eq_reference`は任意の有限列と任意のpreviousについて、
loopの結果は「旧referenceがEqualならprevious、それ以外なら旧reference」と示す。
`tail_eq_reference`は初期Equalの系。両定理は追加公理なし。
`loop4_eq_loop`は全有限列を量化する帰納法で、四node分岐の8 Bool条件だけを局所的にcasesする。
Boolの局所条件は固定長だが、suffixは任意であり、任意長の等価性を有限テストへ置換していない。

`peel_eq_reference`で、正しいsuffix比較の前へ旧式を一段置いても同じ結果であることを示す。
これを八回適用した`protectedCompare_eq_reference`が採用helperの等価性を示す。
canonicalな非空列の値は正であり、帰納法による`reference_sound`と最終`protectedCompare_sound`で
数値のLess/Equal/Greaterを示す。これらは標準propext/Quot.soundのみを使い、Classical.choiceは追加していない。
`peel_eq_reference`は標準propextのみ。出力は[comparison-lean.txt](../docs/measurements/comparison-lean.txt)。

非canonical列について数値順序の定理は主張しない。例えば長い全0列は、短い正値列より大きいと返す。
この既存のlength-first挙動も全有限列の等価定理とraw列の実行検査で維持する。

Source lockは既存19領域を維持し、compare_bits入口・grouped helper・tail helperを追加して22領域とした。
helper境界を保つ`#inline(never)`もfunction fingerprintへ含める。
属性の値変更を検出し、コメント/空白は除外するunit testを追加した。
compiler hintはモデルの値の定理には影響せず、実際の速度は同一artifactの比較で検査する。

不正な異幅ordering、逆向きのsuffix、inline属性変更はsource gateが拒否した。
モデルのgroup内の高位orderingを反転すると、全有限列の等価証明が失敗した。
すべて一時コピーだけで行い、正常source/modelの復元後にgateを再通過した。

ComparisonはBinaryモデルをimportするため、checkerはCore→Binaryの順にfresh oleanを生成する。
他のモデルも従来どおりwarningをerrorとして検査し、ドリフトゲートを省略していない。
MoonBitへの翻訳、globalなresource上限、参照カウントの物理的な挙動、コンパイラの正しさは証明していない。
20000bitのstack問題と有限oracleは別の実行証拠である。
