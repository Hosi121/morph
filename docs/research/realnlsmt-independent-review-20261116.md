# 非線形 SMT の独立レビュー（2026-11-16）

## 対象と結論

正本 `ffa053e` と opaque Problem の source/CNF 束縛修正 `612a159` を対象に、
production を変更せず、異なる exact reference solver による有限レビューを行った。
38件の新しい2〜4変数 QQ 入力と4件の adversarial test が、native / wasm-gc / JS の
各 backend で42/42成功した。追加の意味論的反例は見つからなかった。
この有限コーパスを一般の入力に対する形式証明や性能保証とは扱わない。

対象ブランチは `research/realnlsmt-review-20261116`。既存の tower 作業ブランチは保持した。
`612a159` は作業木では前提として `f597dc5` に cherry-pick しただけで、
レビューから production の修正は追加していない。

## 参照 solver と独立性

[Z3 の公式 qfnra-nlsat 説明](https://microsoft.github.io/z3guide/docs/strategies/summary/#tactic-qfnra-nlsat)
に従い、`Tactic("qfnra-nlsat").solver()` を用いた。
参照版は `z3-solver==5.4.1.0`、C API の full version も `5.4.1.0`。
専用 `.tools/realnlsmt-review-20261116/venv` にのみ導入した。
システム Python に ensurepip がなかったため、venv の Python に対して uv で
wheel を導入した。MoonBit kernel から Z3 やその他の外部 solver は呼ばない。

入力係数は Python `Fraction`、Z3 の exact rational AST、MoonBit の Rational の間で
変換する。Float、近似根、evalf、decimal model の比較は使用しない。
SMT-LIB の多項式も整数・有理式と積に展開して保存し、別途 parse して同じ判定になる
ことを確認する。SAT/UNSAT 以外の参照応答は生成エラーとし、unknown を期待値へ変換しない。
SAT では Z3 model 上で元の Boolean 式の評価が true となることも確認する。

[全41候補の SMT-LIB・厳密判定・手計算の理由・参照ライブラリ SHA256](../measurements/realnlsmt-review-oracle-20261116.json)
を保存した。Z3 の判定は20 SAT / 21 UNSAT。通常コーパスは19 SAT / 19 UNSAT。
既存114件の一変数 Fraction sign-cell oracle とは参照実装・変数数・入力族が異なる。

## 検査した入力族と checker

- 2変数の積、ゼロ因子となる prefix、正負の積、無理数の従属座標、共役の選択肢。
- 親変数が負の場合の相対平方根、重複した零の section、正の入れ子第四根。
- 円上の有理端点、開区間の annulus、矛盾する同心領域。
- 同じ非線形項を共有する CNF/disjunction/negation と、複数の theory conflict。
- 3変数の nullification、積の graph、平方和、球面と平面の交差。
- 4変数の二つの差の積、nullified coefficients、無理数の diagonal、正の重み付き平方和。

各 SAT は public `check_model`、元式の `@cad.evaluate_formula`、座標数を検査した。
各 UNSAT は public `check_refutation` と全 theory lemma の `lemma_clause` を検査した。
探索の fuel 上限や OS timing 上限は検証の失敗/未完了として扱い、UNSAT と読み替えない。

追加4件の改竄検査では以下を確認した。

- `x=y=sqrt(2)` と `x=y=sqrt(3)` の正しいモデル間で、外側 context を整合的に貼り替えても
  元の QQ 式に反する点は拒否される。
- 常に不可能な二つの平方条件の OR に対する反証を、SAT となる OR に貼り替える。
  lemma context・signed source・projection metadata まで整合させても、偽の CAD tree は拒否される。
  正しい形を保って leaf の真偽だけを変えた場合も拒否される。
- 複数 theory lemma に依存する反証から lemma を落とす、最後の empty RUP step を落とす、
  context の arity を変える操作はいずれも拒否される。Boolean CNF 単独には反証を流用できない。
- 同じ算術 atom ID を持つ SAT な OR に、UNSAT な AND の強い CNF encoding を入れ、
  lemma と最終反証の context を一貫して変えても、opaque Problem の不整合として拒否される。

## 有限の実行範囲と残る計算時間

開始時に3件の probe（2変数の無理数 diagonal、3変数 nullified fibre、4変数の共有積の矛盾）を
native で実行し、3/3成功、コンパイル込み2.17秒を確認してから候補を増やした。
41候補の一括実行は122.10秒で区切ったため、その一括実行を成功とは数えない。
その後、同じ有限41入力をそれぞれ12秒の計測枠で実行し、38件が成功、3件が未完了となった。

3件は通常コーパスから分け、generator の `--stress` で再生成できるように残した。
いずれも Z3 の判定と手計算の根拠は保存している。

| stress 入力（すべて実数、QQ係数） | Z3 | MoonBit の12秒枠 |
| --- | --- | --- |
| x²=2 ∧ y=x ∧ z=y ∧ z²=2 | SAT | 未完了 |
| x²=2 ∧ y=x ∧ z=y ∧ z²≠2 | UNSAT | 未完了 |
| x=y ∧ y=z ∧ z=w ∧ x²=2 ∧ w²≠2 | UNSAT | 未完了 |

別の4秒の粗い phase probe では、3件とも `@cad.prepare` を終え、lifting 中に計測枠を使い切った。
witness と final result checker の開始 marker には達していない。lifting 内部の個別処理までは
この計測で特定していない。production の最適化や、未完了入力の新しい真偽判定は行っていない。
[各候補の計測・phase marker・確定した42件の3backend結果](../measurements/realnlsmt-review-20261116.json)
に記録した。

| target | tests | wall seconds | user seconds | sys seconds |
| --- | ---: | ---: | ---: | ---: |
| native | 42/42 | 12.22 | 11.01 | 0.74 |
| wasm-gc | 42/42 | 6.92 | 6.10 | 0.96 |
| js | 42/42 | 11.62 | 9.86 | 1.07 |

すべて共通 `tools/measure` ロック・CPU 6 の下で行い、上表には必要なコンパイルを含む。
backend 間の性能比較には使わない。実行時に `--deny-warn` を適用した。
一度だけ広い `independent*` filter が既存114件も拾い、156/156を実行したが、
最終の受入条件・上表には新しい42件のみの固有 filter を使った。

## 再生成

```sh
.tools/realnlsmt-review-20261116/venv/bin/python tools/generate_realnlsmt_review.py
tools/measure --cpu 6 tools/moon fmt src/realnlsmt/independent_review_z3_wbtest.mbt
.tools/realnlsmt-review-20261116/venv/bin/python tools/generate_realnlsmt_review.py --check
tools/measure --cpu 6 tools/moon test --deny-warn --target native src/realnlsmt -f 'independent Z3 review*'
```

参照環境を作り直す場合は専用 venv に `z3-solver==5.4.1.0` を導入する。
`--check` は生成 syntax と provenance を検査し、moon fmt による空白と末尾 comma のみを許容する。
`--probe` は先頭3件、`--stress` は未完了だった3候補も出力する。
通常の全体テストに stress 入力を暗黙に混ぜない。

成果はテスト・generator・研究記録・計測 JSON に限定する。生ログは専用 `.tools` に保持し、
main への統合・公開同期と worktree の最終片付けは root が担当する。
