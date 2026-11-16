# Spec / code / modelの対応記録

[ドキュメント](../docs/README.md) / [形式検証](README.md)

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

```yaml
claim_id: CORE-HALF-1 / CORE-PREFIX-1
source_of_truth: 純記号の制約と厳密な値を保ち、共有基礎を高速化するユーザー指示
spec_delta: floor(n/2)とreplicate-prefixの値を維持
code_delta: core.halve_nat/half_nat/replicate_ontoを共有し、三箇所のBinary往復を除去
model_delta: 商余り・floor・任意型のprefix融合の全称定理
check_command: tools/check_formal
previous_machine_result: 元の関数の有限検査のみ
current_machine_result: halveNat_sound/halfNat_floor/replicateOnto_eq_append/replicateOnto_nil成立
drift_class: coverage-gap (共有化の対応モデルを追加)
witness: 0〜4096、Nat200001、prefix100000、三backendの実行検査はモデルとは別
domain_wording: 同じ値を、別表現への変換や二重prefix走査なしで構築する
domain_question: なし。Karatsubaへのprefix融合は速度差が曖昧なので採用保留
recommended_fix_target: 構造と停止条件を維持し、MoonBit/Leanの両方を検査
lock_update: source-map.jsonの10領域と全Leanファイル
epistemic_status: モデル定理はmachine-confirmed、MoonBitへの翻訳の形式証明なし
```

```yaml
claim_id: NAT-3
source_of_truth: docs/bootstrap/nat-radix-grouping.md / strict canonical Binary API
spec_delta: 値とcanonicalなbit列を維持
code_delta: 八つ/七つの二cursor走査で既存Nat tailを商にし、三bitずつ出力。公開wrapperは0/1を保護
model_delta: 8q+r=8slow−7fast、q<n、lowBitの値/正規性、全自然数の値/正規性を追加。旧二進モデルも保存
check_command: tools/check_formal / moon test --target native,js,wasm-gc -p Hosi121/morph/binary
previous_machine_result: 旧二進共有の全称値定理と有限oracle
current_machine_result: machine-confirmed; 新旧の値定理、新しい停止性/正規性、三backend各25 tests通過
drift_class: model-drift (実装の三bit分割にモデルを追従し、元の値契約も維持)
witness: 不正な余りは値の不変式を壊し、高位0の残留は値が同じでも正規性を壊す
domain_wording: どの自然数でも同じ値のcanonicalな有限bit列になるモデル
domain_question: なし。実装の全入力の資源上限や翻訳証明は主張しない
recommended_fix_target: 公開wrapper統合後にsource lockを再記録し、共通factoryと合わせた比較を維持
lock_update: split_nat_grouped/from_nat_grouped/low_bitと関連factory依存、全モデルhash
epistemic_status: モデル定理はmachine-confirmed、MoonBit対応はreviewed、翻訳/refinementは未証明
```

```yaml
claim_id: BIN-FACTORY-1
source_of_truth: docs/bootstrap/binary-constants.md / zero()=0, one()=1
spec_delta: なし。不変のcanonical葉を共有
code_delta: public zero/one→private canonical helpers→二つの不変global
model_delta: 同じalias関係とzero_sound/one_soundを追加
check_command: tools/check_formal / tools/test_model_drift.py / 三backendのBinary oracle
previous_machine_result: factoryの有限oracleと共有候補の別担当による検査
current_machine_result: machine-confirmed; 両値の定理は公理なし、initializerの変更検出も検査
drift_class: coverage-gap (新wrapperのfactory依存をlockへ追加して解消)
witness: canonical_one_valueのtrueをfalseへ変えるとsource gateがそのinitializerを拒否
domain_wording: 定数を共有してもzeroは0、oneは1のcanonicalな葉である
domain_question: なし。実際の初期化/割当はモデルの外に残す
recommended_fix_target: factory/helper/globalのいずれを変えても構造対応と有限oracleを確認
lock_update: 合計19領域。global initializerは型付きBinary recordとして明示的に登録
epistemic_status: aliasのモデル値はmachine-confirmed、実行時の初期化は有限oracle、翻訳証明なし
```

```yaml
claim_id: BIN-COMPARE-1
source_of_truth: canonical Binaryの数値比較と既存raw列のlength-first挙動を保つユーザー指示
spec_delta: 値・API・非canonical列の振る舞いを維持
code_delta: 八段の有限prefixと四node tail loop、helper境界をinline neverで保持
model_delta: 任意previousのloop不変式、全有限列の新旧等価、canonical値のOrdering soundを追加
check_command: tools/check_formal / comparison対象の三backend tests / 同artifact benchmarks
previous_machine_result: 比較の有限テストのみ。旧20k bit JS比較はRangeErrorを実確認
current_machine_result: machine-confirmed; 全称モデルと三backend各5 testsが通過
drift_class: coverage-gap (比較の全称対応を追加して解消)
witness: 高位ordering反転は等価証明を壊し、異幅/逆suffix/inline属性変更はsource gateが拒否
domain_wording: 任意長の有限列で従来どおりに比較し、canonicalなら値の大小を表すモデル
domain_question: なし。上位全体の速度比と全入力の実行資源上限は未主張
recommended_fix_target: 通常入口をhelperへ接続しsource lockを再記録、上位の速度評価は別に実施
lock_update: 既存19領域を維持し、入口と二helperを足した22領域。codegen属性もlock
epistemic_status: モデルと有限実行はmachine-confirmed、source対応はreviewed、翻訳/refinementは未証明
```

## 2026-11-16: 疎Hornerの採用

- 採用ソース `00b220e`、独立レビュー `a558a29`。降順指数でのscan不変条件、項別評価との一致、二進累乗と0/1省略をStdのみのLeanモデルで検査した。
- smart constructorと評価器の7領域を対応lockへ追加し、合計31領域にした。既存24領域の意味とモデルは変えていない。
- `tools/check_formal`の対象を`formal/reviews/*.lean`へ広げた。Leanが全12定理を受理し、`sorryAx`がなく、既存の全モデルと6つのdrift保守テストも成功してからlockを記録・再検査した。
- 降順、演算辞書の法則、converterの値の保存は明示的な前提。有理数実装・compiler全体の証明を追加したという主張ではない。
