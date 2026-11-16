# NAND synthesis independent review

[ドキュメント](../README.md) / [探索・改善記録](README.md)

対象は root の `6f3f0cc`。実装は変更せず、独立した
`src/synthesis/review_wbtest.mbt` を追加した。追加7テストを native、JavaScript、
Wasm GC で実行し、すべて通過した。この範囲で最小反例は見つからなかった。

## 符号化と復号の照合

SAT探索を使わず、次の306個の問題について、CNFの全Boolean割当てを直接列挙した。
最大のCNFは11変数である。

| 入力数 | 真理値表 | gate上限 |
| --- | --- | --- |
| 0 | 全2個 | 0、1、2 |
| 1 | 全4個 | 0、1、2 |
| 2 | 全16個 | 0、1 |
| 3 | 全256個 | 0 |

期待する存在判定は、整数ビット列を真理値表とするnative NANDプログラム列挙から得た。
encoderの三角形の選択肢列挙を再利用せず、NAND入力の左右両方の順序を列挙した。
各CNFの充足割当ては全て `decode` へ渡し、別の配列ベースのNAND実行器で全入力行の
結果を照合した。CNF充足可能性とプログラムの存在が一致し、充足modelの復号失敗や、
仕様と異なる復号回路はなかった。

加えて、one-hotのサイズ0〜6について全127割当てを調べ、選択数がちょうど一つの
場合だけCNFが成立することを確認した。空の選択肢は不可能となる。
guarded NAND節は、固定入力2本と既存gate値2本から選ぶ左右16通り、固定入力4通り、
既存値・selector・出力の16割当て、合計1,024条件を直接検査した。
節の意味は全て `selector ⇒ y = NAND(a,b)` と一致した。これはencoderが生成する
到達可能な値だけでなく、既存gate値の任意の組合せも含む。

## 境界と証拠

- 入力0〜5本の行列挙を、整数の辞書順ビット抽出と照合した。先頭入力が最もゆっくり変わる。
  真理値表の行数が一つ足りない・多い場合、0入力で空の場合もconstructorが拒否する。
- 2段のnetworkについて、左右それぞれの入力範囲外、自己参照、前方参照、不正な出力wire、
  0入力のwire、評価時の入力長不一致を検査した。
- 1入力の全4真理値表とgate上限0〜5の24問題で、nativeプログラムの存在判定と一致した。
  燃料0は常にpauseし、燃料1ずつの再開、まとめた実行、同じ初期状態からの再実行が
  同じnetworkまたは証拠を返した。
- `decode` は空model、矛盾するmodel、複数のtopology selectorを立てたmodelを拒否した。
  SATなNAND問題に対する空RUP・未正当化の空節を拒否した。
  0入力・0gateのCNFには実際に空節があるため、空節1個のRUP証拠を受理することも確認した。

## 読み取れた契約と残る範囲

`Found` のnetworkには指定上限と同じ個数のslotが入る。入力が一つ以上あれば不要なslotを
既存入力からのNANDで埋められ、出力はそれ以前のwireも選べるため、存在判定は「高々上限」
として成立する。定数は無料ではなく、0入力では出発wireがない。この点はdocsの説明と一致する。

燃料が数えるのはCDCL探索の遷移である。`problem` の構築、成功後の全行network評価、
`Impossible` のRUP検査はこの燃料に含まれない。現在の実装を誤りとは判定しないが、
外側APIに時間上限を期待させる場合は、この契約を明示するのがよい。

全3入力関数の正のgate上限や、大きな上限での全CNF割当ては列挙していない。
このレビューは有限照合と局所節の真理値検査であり、任意サイズの符号化の形式証明ではない。
RUP checkerと問題からCNFへの符号化は引き続き別の信頼境界である。

再現:

```sh
tools/moon test src/synthesis/review_wbtest.mbt --target native
tools/moon test src/synthesis/review_wbtest.mbt --target js
tools/moon test src/synthesis/review_wbtest.mbt --target wasm-gc
```
