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
