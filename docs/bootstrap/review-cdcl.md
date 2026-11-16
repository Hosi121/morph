# CDCL / RUP の独立レビュー

[ドキュメント](../README.md) / [探索・改善記録](README.md)

レビュー対象：`31f80d68cc88cedb4bbf1b6dd58068f1c0a4b628`
（scan版CDCL、2026-11-15、MoonBit v0.10.20）。
`src/cdcl/cdcl.mbt` は変更せず、追加テストを `src/cdcl/review_wbtest.mbt` に置いた。
後続のwatch版と基礎算術の修正は、この記録時点では対象外。

## 所見：大きな疎IDで探索開始時にスタックが尽きる

最小の再現入力は、変数ラベル `65535` の正のunit節ひとつ。
論理的には明らかにSATだが、JS / Wasm GCでは `start` の内部で失敗する。

```sh
tools/moon test src/cdcl/review_wbtest.mbt --index 6 --target js
tools/moon test src/cdcl/review_wbtest.mbt --index 6 --target wasm-gc
```

JSは `RangeError: Maximum call stack size exceeded`、終了コード2。
Wasm GCは同じエラーで実行不能、終了コード255。
スタックは `src/binary/binary.mbt:267` の `from_nat` 再帰を繰り返す。
CDCLの `atom` が変数ラベルを `Nat` から `Binary` に変換する際の、非末尾再帰が原因。
テストの `Nat` 構築・表示用の変換は明示的な反復で行い、テストアダプター自身の再帰を原因に混ぜていない。

同じ最小テストはnativeで成功した。
疎ID `[0,1024,4096,8191]` のSAT・UNSAT・証拠検査は3バックエンドで成功した。
この所見は**実行上の制限**であり、誤ったSAT/UNSAT結果や不正なRUP証拠の受理を示すものではない。
任意長のPeano表現が、実際のバックエンドで無制限の呼び出しスタックを持つことは意味しない。
rootへ最小再現テストを先に渡し、基礎算術側の修正と再検証を依頼した。

## 独立オラクルと攻撃的ケース

追加テストは、入力を符号付き機械整数の配列として別途保持する。
真理値判定では小さい変数集合の全割当てを列挙し、変数ラベルをビット位置と混同しない。
返されたmodelも、SATパッケージの検査器を使わずこの配列に対して検査する。

RUPオラクルは機械整数の割当て配列で候補節を否定し、重複literalを除いた未充足literal集合から
unitを反復して固定点に達する。CDCLの `normalize`・`inspect_database`・`unit_conflict`・
`analyze`・SATパッケージのソルバーや証拠検査器を呼ばない。
CNF自身の真理値判定も併用し、オラクルが受理した反証がSAT入力に付かないことを確認する。

追加した6個の基本テストは次を含む。

- 重複・順序違い・tautology・unit・空節を含む21種類の2変数節から、全9,261三つ組を真理値と照合。
- 重複literal・重複節を意図的に含めた5変数600式を真理値と照合。
- fresh変数、tautology、重複literal、途中の空節を含む2,662組の短いRUP列で独立オラクルと受理結果を比較。
- 4変数の全cubeを反証した学習証拠から、学習節の削除・交換・literal順反転・符号反転・
  literal重複・終端空節の削除・非空の末尾追加・空節の繰り返しを作り、RUP規則との一致を確認。
- 空CNF・root矛盾・SAT・学習UNSAT・非時系列backjumpを含む7式で、すべての燃料分割境界を検査。
  結果だけでなく累積統計、ゼロ燃料、同じsnapshotからの再実行も比較。
- ラベル8191までの疎なIDに対して、SAT/UNSAT・model・RUPを検査。

学習節の削除や並べ替えは、冗長な推論を消しただけなら有効なRUP列のままの場合がある。
そのため「変異した証拠はすべて拒否」という誤った要件は置かず、独立したRUP規則の判定に一致することを要求した。
最終節が非空の列は、途中に空節があっても拒否される。

## 実行結果と限界

```sh
tools/moon fmt --check src/cdcl
tools/moon check --deny-warn src/cdcl
tools/moon test src/cdcl/review_wbtest.mbt --index 0-6 --target wasm-gc
tools/moon test src/cdcl/review_wbtest.mbt --index 0-6 --target js
tools/moon test src/cdcl/review_wbtest.mbt --index 0-6 --target native
tools/moon test src/cdcl/review_wbtest.mbt --index 6 --target native
```

6個の基本テストはWasm GC・JS・nativeすべて成功。
7個目の最小再現はnative成功、旧ソースのWasm GC・JSで上記の失敗を再現する。
整形・警告禁止の型検査も成功。

確認した有限例では、誤ったSAT/UNSAT、RUPの不正受理、再開の不一致、
`InvariantViolation` は見つからなかった。すべての入力に対する形式証明ではない。
共有実装を避けたオラクルも、機械整数の小さい変数集合・固定fixture・有限の探索予算に限られる。
巨大な式、さらに大きなID、watch版、後続の実装変更への保証はこの結果から推論しない。
