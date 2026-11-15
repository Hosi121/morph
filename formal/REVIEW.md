# Binary Leanモデルの独立レビュー

レビュー対象はmainの `6ff31423dad6497471b5e4fec22617efa6fa22cd`。
2026-11-15、実装担当とは別のagentがformal-methods-drift-guardの手順で、
Leanモデル・MoonBit関数・source-map・実行harnessを確認した。
実装、定理、lockは変更していない。

結論：現在記載されている限定範囲の主張は支持できる。
Lean内の値の定理は検査を通り、対応するMoonBit関数の構造にも明らかな不一致は見つからない。
MoonBitからLeanへの翻訳・実装refinementの形式証明は引き続き未実施である。
hash gateはレビュー済み領域の変更検出として動作し、この未証明部分を自動で埋めない。

## 機械で追試した結果

新しい独立worktreeで、rootに隔離されたLeanを利用した。

```sh
/home/hosi/morph/.tools/lean/bin/lean --version
python3 tools/check_model_drift.py
tools/check_formal
```

Leanは4.19.0、commit `6caaee842e94`。6つのsource領域とモデルhashはlockに一致した。
報告対象の7定理はすべて通過した。ほかに停止性の補助定理 `split_lt` があり、
`fromNat` の停止性と最終定理から利用される。

| 定理 | `#print axioms` の結果 |
| --- | --- |
| fullAdder_sound | 追加公理なし |
| carry_stabilizes | 追加公理なし |
| borrow_stabilizes | 追加公理なし |
| increment_sound | propext, Quot.sound |
| addition_sound | propext, Quot.sound |
| split_sound | propext, Quot.sound |
| fromNat_sound | propext, Quot.sound |

モデル内に `sorry`、独自の `axiom`、`unsafe`、`partial` は見つからない。
標準のpropext/Quot.soundを含むLean kernelと配布物は信頼境界に残る。

## 手で確認した関数対応

| MoonBit領域 | Lean側 | 対応の判断 |
| --- | --- | --- |
| binary.full_adder | fullAdder | 全Bool分岐と返すsum/carryが一致 |
| binary.increment_bits | increment | Nil、false先頭、trueのcarry再帰が一致 |
| binary.add_bits / add | add | 両列非空のfull adder再帰、片列終了時のsuffix共有/incrementとcarry=falseのwrapperが一致 |
| binary.from_nat内split | split | Zero、Succ(Zero)、Succ(Succ(rest))の三分岐とhalfのSuccが対応 |
| binary.from_nat内convert | fromNat | 入力が正のとき同じ入力をsplitし、lowをconsしてhalfへ再帰する構造が対応 |
| runbinary.digit | fullAdder / borrowStep | AdditionとDifferenceの反転・carry/borrow変換が一致 |

MoonBitの `@core.Nat` とLean Nat、`@core.Chain[Bool]` とLean Chainの同一視は人手の対応である。
`split_sound` はaccumulatorを含めて `2*half_result+bit=n+2*half_input` を示す。
`split_lt` により正の入力から得るhalfが小さいことを示し、`fromNat_sound` は
そのhalfへの帰納仮定と商余りの等式を使って値の保存を証明している。

加算定理は任意の有限bit列と両carryを量化しており、上位0を含む非正規形も対象にする。
Binary recordの正規性や最高位bit、MoonBitのstack/heap上限、コンパイラ、全run算術は
この定理の結論に含まれていない。carry/borrowの安定性も均質な一桁の局所命題である。

## hash gateの守備範囲とnegative sanity

`function_tokens` はコメントと空白を除去した関数領域をfingerprint化し、
モデルはファイル全体のhashを記録する。compiler ASTや依存グラフの意味比較ではない。
`from_nat` の外側の関数領域にはローカルsplit/convertも含まれる。

追試は一時directoryのコピーだけで行い、すべて削除した。

| 一時的な変更 | 追試結果 |
| --- | --- |
| MoonBitの0+0+0のsumをtrueに変更 | full_adderのfingerprintだけがlockと異なる |
| MoonBitのローカルsplitでhalfのSuccを削除 | from_natのfingerprintがlockと異なる |
| Leanの0+0+0のsumをtrueに変更 | Lean exit 1、定理の証明を拒否 |
| Leanのsplitでhalf+1をhalfに変更 | Lean exit 1、定理の証明を拒否 |
| 未登録のsuccessor wrapperを恒等関数へ変更 | このgateのsnapshotは変わらない |

最後の例は対象範囲の確認である。successor wrapperやcoreのADT定義、imports、
未登録helperの変更はこの6領域のlockだけでは検出しない。
通常のMoonBitテストとpurity/typeチェックは別の検査であり、今回はこの一時変更に対して
その全suiteを実行したとは主張しない。

`tools/check` が実行するのは安価なdrift検査で、Lean本体の検査は `tools/check_formal` で別に行う。
`--record` は翻訳や定理を検査せずlockを更新できるため、READMEにある
対応レビュー・Lean/MoonBit検査後の更新という運用条件が必要となる。
今回の正常状態はnegative追試後もdrift検査とLeanの両方を再通過した。

## 境界の記録

```yaml
claim_id: REVIEW-BIN-REFINEMENT
source_of_truth: formal/README.md / formal/drift-ledger.md
spec_delta: なし。限定した値の契約を維持
code_delta: このレビューでは変更なし
model_delta: このレビューでは変更なし
check_command: tools/check_formal
previous_machine_result: 7定理通過という担当者の記録
current_machine_result: machine-confirmed; 同じ7定理とaxiom出力を独立追試
drift_class: coverage-gap (既知の翻訳境界)
witness: ADTと関数の対応は手で確認し、翻訳器やrefinement theoremは存在しない
domain_wording: Lean内の全称値定理とMoonBitの全入力の実装正しさを分ける
domain_question: なし。現行の限定契約に明記されている
recommended_fix_target: 将来実装定理を主張するときは抽出/翻訳対応の証明を追加
lock_update: 不要。source-mapとモデルは変更していない
epistemic_status: Lean結果はmachine-confirmed、MoonBit対応はreviewed、翻訳は未証明
```

```yaml
claim_id: REVIEW-BIN-MAP-SCOPE
source_of_truth: tools/check_model_drift.py / formal/source-map.json
spec_delta: なし。6領域の変更検出という範囲を確認
code_delta: 一時コピーのみでnegative sanityを実施
model_delta: 一時コピーのみで不正真理値/不正splitを検査
check_command: snapshot比較 / 一時Leanファイルのchecker実行
previous_machine_result: full adderのnegative sanity記録
current_machine_result: machine-confirmed; nested splitの検出と未登録wrapperの非検出も確認
drift_class: coverage-gap (意図された領域lockの外側)
witness: ローカルsplit変更は親from_nat hashに入り、未登録successor変更は入らない
domain_wording: hash一致は登録された断片の不変を示し、実装全体の意味同値を示さない
domain_question: なし。公開API全体を形式保証する範囲拡大は今回の依頼外
recommended_fix_target: 対象主張を広げる際にwrapper/ADT/helperと依存を追加レビュー
lock_update: 不要。--recordは実行していない
epistemic_status: gateの機械結果と守備範囲を確認。現在の限定説明に矛盾なし
```
