# 条件付き真偽判定の Boolean 部分と Lean の対応

[形式検証](README.md) / [モデル](PrefixLogic.lean)

`prefixlogic` は、残りの変数に依存する係数が親セル全体で消滅するとき、
原子式の真偽を確定する。確定できない原子式は `Undetermined` に保つ。
この記録は、それらの原子式を結ぶ Boolean 再帰の条件付き健全性を対象とする。
係数分解から CAD 全体までを形式証明したとは主張しない。

## 今回の主張と正本

正本は `src/prefixlogic/evaluate.mbt::evaluate_conditional` の実装と、
「`Known(b)` を返すなら、親セルに属するすべての接尾変数割当てで値が `b`」
という枝刈りの契約である。
任意の原子式についてこの契約が成り立つ、という明示的な仮定の下で、
任意の深さの有限式にも同じ契約が成り立つことを Lean 4.19.0 で証明する。

領域の型 `Domain` と、その有効点を表す `admissible : Domain → Prop` は任意である。
実数や有限集合に固定しておらず、空領域も許す。
空領域で一様性が自明になることは意味上の挙動であり、
CAD に必要な領域被覆や非空性をこのモデルから導いてはいない。

## 人手で確認した対応

| MoonBit | Lean | 対応と境界 |
| --- | --- | --- |
| `Known(Bool)` / `Undetermined` | `Truth.known Bool` / `Truth.undetermined` | 値の対応 |
| `Constant(value)` | `Formula.constant value` | 常に同じ Boolean 値 |
| `Atom(constant, future, relation)` | `Formula.atom atom` と `observe atom` | 原子式全体を抽象化。係数の消滅、符号参照、六関係の算術は仮定 `atomSound` の外部の根拠 |
| `Not(body)` | `Formula.negation` と `negate` | 既知値だけを反転し、不明は不明のまま |
| `And(left, right)` | `Formula.conjunction` と `conjoin` | どちらかが既知の偽なら偽、両方が既知の真なら真、それ以外は不明 |
| `Or(left, right)` | `Formula.disjunction` と `disjoin` | どちらかが既知の真なら真、両方が既知の偽なら偽、それ以外は不明 |
| 同じ `signs` を渡す二つの再帰呼出し | 同じ `observe` を渡す再帰 | 観測を再帰中に変更しない |

Lean の `Atom` 型は、MoonBit の原子ノードの内容に対応する任意の型である。
式の同じ原子に対して同じ `observe` を使い、具体的な全割当ての評価には
`assignment point atom` を使う。`Formula` の構造は Boolean 部分の射影であり、
MoonBit の全 ADT や polynomial の翻訳ではない。
実装担当がこの対応を確認したもので、独立した翻訳検証を実施したとは主張しない。

## 定理と機械検査

- `partialEvaluate_sound`：任意の有限式に対する構造帰納法。
  原子観測が各有効点の真偽と整合するなら、式全体の部分評価も整合する。
- `known_is_uniform`：部分評価が `Known(b)` の場合、すべての有効点で具体評価が `b`。
  原子に関する前提は定理の引数であり、追加した正しさ公理ではない。
- `negate_sound`、`conjoin_sound`、`disjoin_sound`：帰納法に使う局所補題。
  Boolean の有限場合分けはこの局所演算だけに使い、式の深さや領域を有限化していない。

`#print axioms` による二つの主要定理の依存は標準の `[propext]` のみ。
`sorryAx`、`Classical.choice`、独自の正しさ公理を含まない。
定数による左右両方向の短絡と、不明が残る場合の sanity examples も検査する。

実行コマンドは次のとおり。共通の計測 lock を通して実行した。

```bash
tools/measure --cpu 6 .tools/lean/bin/lean \
  -DwarningAsError=true formal/PrefixLogic.lean
python3 tools/check_model_drift.py
python3 tools/test_model_drift.py
```

正しいモデルのコピーで `conjoin(Known(false), _)` の結果を `Known(true)` へ変えた対照と、
`disjoin(Known(true), _)` を `Known(false)` へ変えた対照を個別に作成し、
いずれも Lean が健全性補題と sanity examples を拒否した。
失敗するモデルは production の formal ディレクトリへ置いていない。
実行ログは作業時の `.tools/prefixlogic-formal/` に保存した。

## ロックの意味と未証明部分

既存の source/model レコードを保ち、`evaluate_conditional` 一関数と
`formal/PrefixLogic.lean` の fingerprint を source-map へ追加した。
関数全体をロックするため、抽象化した Atom 分岐の変更も再レビューを要求する。
ただし、fingerprint は翻訳証明や Atom 算術の証明にはならない。

次の事項はこの定理の結論に含まれない。

- 多項式を接尾単項式ごとの係数へ分解する実装の正しさ。
- 係数と射影族の完全一致、観測 index、定数符号の正しさ。
- 観測した符号が一点だけでなく親セル全体で成り立つこと。
- 射影の健全性、根の分離、CAD の被覆、短縮証拠木の元の式への束縛。
- `prepare`、`check_plan`、観測長検査、リソース上限、コンパイラの正しさ。

算術の対応は別の実行証拠として、全六関係・81 個の二次式族について
7,290 点の独立整数式評価と厳密有理数評価を照合し、
162 件の一様性確定、3 変数の係数合成、非整数の消滅点 `2/3`、
不足した係数の保守的な不明判定、改変した Plan の拒否を三バックエンドで検査した。
これらは有界の回帰検査であり、上の未証明事項の一般証明として扱わない。

## 座標等式からの大域的な矛盾（2026-11-20）

以下は採用ソース`6861797`時点の記録。現在の一般化は次節に記す。

`linear_conflict`は、ANDだけをたどって必須の`EqualZero`原子を集める。
その中の非零な座標等式`a*x_i+b=0`を除数とし、他の必須等式pを既存の多項式除算で簡約する。
余りが非零定数cなら、返された商q_iから`p = Σ q_i d_i + c`を厳密に再構築し、元のpとの一致を検査する。
全てのd_iとpが零である点ではcも零になるはずなので、非零定数との矛盾から元の式全体が偽となる。
この場合だけ各stageを`Constant(false)`とし、CAD checkerも元の式から同じ判定と恒等式を再計算する。
`Known(true)`は導出しない。OR・否定・他の関係の内側から等式を仮定しない。

除数を座標等式に限るのは計算量の条件である。一般の連立一次式からの代入は単項式を多数へ展開し得るため、今回の経路では使わない。
対象のpは線形にも非線形にもなり得る。非零定数を得られない場合、完全性やSATを主張せず既存の係数判定とCADへ戻る。
Groebner基底を準備する新しいsolverや、公開の証拠型・API・importは追加していない。

Leanの`requiredAtoms_sound`は、任意の有限式と任意の原子selectorについて、元の式が真なら
ANDのみから取り出した全原子が真であることを構造帰納法で証明する。
`conjunct_conflict_sound`は、その必須原子が同時に真になれないという前提の下で、元の式が偽になることを示す。
二つの定理の公理依存は標準の`[propext, Quot.sound]`で、`sorryAx`や独自公理はない。既存の二定理は変更していない。
ORと否定の内側の原子も集める二つの誤ったモデルは、それぞれLeanの定理とsanity exampleに拒否された。

算術的な矛盾の前提は、MoonBitの除算結果・係数条件・再構築した恒等式が担う。
これらの多項式演算、QQから実数への評価、再構築とモデルの翻訳は、このLeanモデルでは形式証明していない。
誤った係数・次数・arityを許してよいという意味ではなく、既存の検査と独立した有限回帰で補う範囲である。

| 変更判定 | 記録 |
| --- | --- |
| claim_id | CAD-CONJUNCT-CONFLICT-001 |
| source_of_truth | 厳密な判定・元の式への証拠の束縛を保ち、不要なCAD展開を省くという契約 |
| spec_delta / code_delta | 検査した座標等式の恒等式から全域の偽を導出する。一般CAD・元の原子・射影と証拠検査は維持 |
| model_delta / drift_class | 新しい必須原子の抽出を追加。主分類はcoverage-gap。Boolean条件を補い、算術の一般証明は未達と明記 |
| check_command | `.tools/lean/bin/lean -DwarningAsError=true formal/PrefixLogic.lean`、`tools/check_formal`、`tools/check_model_drift.py` |
| previous_machine_result | 既存のBoolean一様性定理は成功。新しい抽出についての定理は未存在 |
| current_machine_result | 新定理が成功し、OR/NOTを仮定へ取り込む二変異を拒否（machine-confirmed）。数値回帰と統合範囲は検証記録に保存 |
| domain_wording / domain_question | 条件付きの等式から無条件の矛盾を作らない。既存契約と実装の許可で判断でき、追加の業務判断は不要 |
| lock_update | `linear_conflict`全体と`prepare`の接続をsource-mapへ追加し、モデルを再検査してhashを更新。翻訳証明ではない |

## 二項等式と六関係への一般化（2026-11-21）

既存のprivate規則を`conjunct_conflict`へ改名し、ANDから必須の全関係原子を収集する。
仮定にするのは引き続き`EqualZero`のみ。座標等式による既存判定を先に行い、
それで決まらなければ非零の一項・二項多項式を除数へ加える。
二項では、lex先頭項の総次数が残項以上という条件を加えた。
一回の書き換えで一単項式は高々一単項式となり、総次数も増えない。
係数のbit長・除算回数・全体の時間を一定とする保証ではない。

各元等式を、それ自身と完全一致する式を除いた元等式群で一度ずつ簡約する。
新しい二項以下の余り、または矛盾する定数だけを重複なく追加する。
元の除数がm本なら追加は高々m本で、追加済みの結果を再帰的に閉包しない。
`p = Σ q_i*d_i + r`を厳密に再構築した変更だけを採用し、変更がなければ恒等式`p=p`を使う。
各追加余りは元の必須等式が成り立つ点で零である。その帰結を再度除数にしても同じ条件を保つ。

必須原子の簡約結果が定数なら、既存の`relation_holds`で元の関係を評価する。
非零定数と等号の矛盾に加え、零と厳密不等号・非等号の矛盾も扱える。
`xy=0`から`x=0`や`y=0`を勝手に選ばず、`x²=y²`から`x=y`を導かない。
ORと否定の内側は収集しない。`Known(true)`、完全性、一般のGroebner基底は導出しない。
恒等式が確認できない場合は既存の係数判定と完全CADへ戻る。

Leanモデルの変更はない。`requiredAtoms_sound`の任意selectorを全原子に適用し、
`conjunct_conflict_sound`の条件付き論理伝播を再利用する。
恒等式、余りの帰結、次数制限の算術的健全性とMoonBitへの翻訳は形式証明していない。
実行時の恒等式検査、有理数の具体的証人、全六関係の独立整数評価、完全CAD参照、
既存の独立Z3 corpusと三backendの回帰検査がこの範囲を補う。
以前保存したOR/NOT変異の拒否は同一Leanソースの証拠であり、今回新規の証明とは数えない。

| 変更判定 | 記録 |
| --- | --- |
| claim_id | CAD-CONJUNCT-CONFLICT-002 |
| source_of_truth | 厳密な元の判定、証拠のsourceへの束縛、既存公開APIを保つ |
| spec_delta / code_delta | 座標限定から次数を増やさない二項等式へ広げ、六関係の定数矛盾を共有処理する |
| model_delta / drift_class | Leanはbyte一致。code-driftとしてselectorと算術前提の対応を再確認 |
| check_command | `tools/check_formal`、`tools/check_model_drift.py`、三backendの影響範囲検査 |
| lock_update | 旧private関数の領域を`conflict.mbt::conjunct_conflict`へ移し、`prepare`接続も更新。翻訳証明ではない |
| remaining_obligation | 多項式除算、QQ評価、恒等式からの帰結、実装の形式的な翻訳は未証明 |
