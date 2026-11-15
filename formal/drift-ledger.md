# Spec / code / modelの対応記録

formal-methods-drift-guardの出力形式。現在の正本は厳密な自然数算術を保つというユーザー指示。
機械で確認したモデル定理と、人手で対応を読んだ実装を分ける。

```yaml
claim_id: BIN-ADD-1
source_of_truth: HANDBOOK.md / docs/bootstrap/addition.md
spec_delta: 加算の意味は変更なし
code_delta: suffix共有とincrementの共通化、6領域の変更検出lock
model_delta: 任意の有限ChainとBool carryに対する値の定理を新設
check_command: tools/check_formal
previous_machine_result: not-run (Leanモデルなし)
current_machine_result: machine-confirmed; fullAdder_sound/increment_sound/addition_sound成立
drift_class: coverage-gap (モデルを追加して解消)
witness: 壊れた0+0+0の真理値はLeanでもsource差分でも拒否
domain_wording: どの長さのbit列でも値の和とcarryを保存するモデル
domain_question: なし。計算値を維持する既存契約を継続
recommended_fix_target: 変更時はコードとモデルの構造対応を再レビュー
lock_update: source-map.json。主張を弱めてgreenにしない
epistemic_status: モデル定理はmachine-confirmed、MoonBit対応はreviewed、翻訳の形式証明なし
```

```yaml
claim_id: NAT-2
source_of_truth: docs/bootstrap/naturals.md
spec_delta: Natから二進数への値を維持
code_delta: 同じ構造的半分化をsource lockへ追加
model_delta: splitの商余り等式、商の減少、fromNatの値の保存を新設
check_command: tools/check_formal
previous_machine_result: 有限例のテストのみ
current_machine_result: machine-confirmed; split_sound/fromNat_sound成立
drift_class: coverage-gap (モデルを追加して解消)
witness: 全称定理。JS/Wasmの65535回帰は別の実行証拠
domain_wording: どの自然数でも同じ値の有限bit列になるモデル
domain_question: なし。stack/資源制約を値の定理と同一視しない
recommended_fix_target: 変換アルゴリズム変更時にsplitと停止性も再確認
lock_update: binary.from_natとLeanファイルのhash
epistemic_status: モデル定理はmachine-confirmed、実装の全入力の資源保証なし
```

```yaml
claim_id: RUN-1
source_of_truth: docs/bootstrap/runbinary.md
spec_delta: 均質blockを一度に処理する根拠を明示
code_delta: runbinary.digitを対応領域へ登録
model_delta: carry/borrowの局所固定点定理を追加
check_command: tools/check_formal
previous_machine_result: 全Bool条件のMoonBit実行検査
current_machine_result: machine-confirmed; carry_stabilizes/borrow_stabilizes成立
drift_class: coverage-gap (局所命題について解消)
witness: 全Bool入力のdecideによる証明
domain_wording: 同じ二bitが続く間は一桁後のcarry/borrowが再び変わらない
domain_question: なし。runbinary全体の正しさの証明は未実施
recommended_fix_target: full_adderやdigitの意味を変えたら局所定理を再確認
lock_update: source-map.jsonとverification-ledger.md
epistemic_status: 局所モデルはmachine-confirmed、run算術全体は有限oracle検査
```
