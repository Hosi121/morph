# Core追加分の独立レビュー

[ドキュメント](../docs/README.md) / [形式検証](README.md)

担当：rootとは別のcyclotomic agent。対象sourceは17c206d、利用経路の説明は3cda1ca。
source・Lean・文書・既存の実行ログを読むレビューで、checkerの独立再実行ではない。

- `halve_nat`のwalkとLeanのhalveLoopは、0/1/二つ消費して商を一つ増やす構造が一致する。
  不変式`2*商+Boolの余り=残り+2*accumulator`と余りの範囲からfloorの値が出る。
- `replicate_onto`とreplicateOntoは同じtail accumulatorで、元の構造的replicateに
  appendするモデルとのgenericな等式とNilの系がwrapper変更を橋渡しする。
- `is_power_of_two_nat`は0拒否・1受理・奇数拒否・偶数半分化の構造を確認した。
  この関数は今回のLean定理の対象外で、有限oracleの検査範囲である。
- MoonBitへの翻訳、コンパイラ、実行資源、全kernelの正しさをモデル定理から主張していない。

モデルの値の対応に修正を要する所見はなかった。
文書で古いBinary専用ログを現在の全モデルのログと混同しないよう、
新しいnat-path-validationへのリンクを追加した。
prefixテストの一部は新wrapperとの比較で独立oracleではない。
長さ・tailの検査と旧構造を持つLeanモデルを併用するが、これらの証拠は同一視しない。
