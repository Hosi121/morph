# 二進数とbit wordの16進表示を分ける

[研究索引](README.md) / [検証ガイド](../VALIDATION.md)

情報幾何の比較CLIに、既存の `conversionmodularbench` の表示helperを流用した際、
独立Python検査が空の分母を拒否した。
`testsupport.hex_bits` はbig-endianかつ4bit単位のword列を表示するhelperであり、
little-endian・可変bit長の `binary.bits` をそのまま渡すと、向きが逆になり、端数のbitも落ちる。
数の0と1の表示が共に空になる場合もあった。

両CLIの数値表示を修正した。big-endianへ反転し、上位を4bit境界まで0で埋め、数の0は `"0"` とする。
0〜1024と4bit境界・任意長の例について、数から文字列へ表示して再読込した値が等しいことを検査する。
`audit_paths` も、import aliasを照合して `hex_bits(binary.bits(...))` の直接経路を拒否する。
word自体の表示は許す。変数を介する誤用や、全ての形式の意味を解析するlintではない。

過去の[modular比較](modular-signed-reduction-20261117.md)の生stdoutは当時のまま保存する。
当時のCLIは文字列化する前に全てのBinary結果を期待値と比較していたため、
その実行内の数値照合は残る。一方、保存stdoutの16進文字列から元の全数値を復元できるとは扱わない。
棄却した算術の試作を、この表示修正によって採用へ変更するものではない。
旧性能値は旧表示を含む固定harnessでの結果であり、新表示の性能値へ読み替えない。

新しい情報幾何比較では、数値JSONの分子・分母を任意長の正しい16進数で出力し、
Python側で非空・canonical表示・正規な分数・全期待値の一致を検査してからtimingを採用する。
最初の二回のcalibration失敗は検査結果が成立する前に停止しており、性能比較の試行には数えない。
