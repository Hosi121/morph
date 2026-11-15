# 基礎ADTのLeanモデル

有限テストとは別に、`Binary.lean`・`Core.lean`の全称命題をLean 4.19.0で検査する。
Mathlibや追加Leanライブラリは使わず、公式配布のStdだけを利用する。
Leanは検証用で、MoonBitの計算核の依存ではない。

```sh
python3 tools/bootstrap_lean.py   # Linux x86_64、.tools内へ隔離
tools/check_formal
```

| 主張 | Leanの定理 | 対応するMoonBitの関数 |
| --- | --- | --- |
| 全8条件のfull adderが桁の和を保存 | fullAdder_sound | binary.full_adder |
| 任意の有限bit列のincrementが値を1増やす | increment_sound | binary.increment_bits |
| 任意の二つの有限bit列とcarryの加算が値を保存 | addition_sound | binary.add_bits / add |
| Succ二個ずつの分割が商と余りを保存 | split_sound / halveNat_sound | core.halve_nat / binary.from_nat |
| 任意の自然数の半分化がfloor(n/2)を返す | halfNat_floor | core.half_nat |
| 任意の自然数からbit列への変換が値を保存 | fromNat_sound | binary.from_nat |
| 均質blockのcarry/borrowが一桁後に安定 | carry_stabilizes / borrow_stabilizes | full_adder / runbinary.digit |

値の意味は`value(Nil)=0`、`value(Cons(b,rest))=bitValue(b)+2*value(rest)`。
加算の定理は最上位の0を含む非正規形の列にも成立する。
証明は帰納法と算術を使い、特定の桁数の総当たりへ切り詰めていない。
`#print axioms`で、Bool全条件の三定理は追加公理なし、
Binary.leanの帰納・算術の四定理はLean標準の`propext`/`Quot.sound`のみと確認した。
`sorry`や独自の正しさ公理を導入していない。
実行ログ：[formal-lean.txt](../docs/measurements/formal-lean.txt)。
Core追加後の10領域と各モデル定理は[nat-path-validation.txt](../docs/measurements/nat-path-validation.txt)に記録する。

## 信頼する境界と変更検出

MoonBitからLeanへの変換器やコンパイラを形式検証したものではない。
両方のADTと関数の構造の対応は人手のレビューで、実行テストも別途必要になる。
Leanモデルの値の定理から、MoonBitの資源上限、最上位bitの正規性、
全run演算、全SAT、コンパイラの正しさは結論しない。

`tools/check_model_drift.py`が、対応を確認した10領域のコメント/空白を除くtoken列と
全Leanモデルファイルのhashを`source-map.json`に照合する。
通常の`tools/check`はこの安価な差分検査を実行する。
これは意味の同値性を自動で証明する機構ではなく、対応を未確認のまま変えないためのlockである。
変更したら元の主張を維持してモデル・実装のどちらが変わるべきか判断し、
LeanとMoonBitの検査、対応レビューの後に限って`--record`する。
詳細は[drift台帳](drift-ledger.md)。

壊したfull adder（0+0+0が1を返す）をMoonBit側へ一時適用すると差分ゲートが拒否し、
Lean側のモデルに適用すると定理の検査が失敗した。両方を復元し、正常な状態で再確認した。
Leanはwarningをerrorとして実行し、`sorry`のnegative controlも拒否した。

## 一回で作る定数prefix

`Core.lean`は任意の型α・自然数n・末尾tailについて、
`replicateOnto(n,x,tail)=append(replicate(n,x),tail)`を示す。
末尾Nilの系もあり、coreのreplicate wrapperも同じ列を作る。
これはBoolの有限全条件を越えたgenericな構造の定理で、標準`propext`だけを使う。
対応領域にcore.replicate/replicate_ontoを追加した。
最初の[独立レビュー](REVIEW.md)は追加前の6領域を対象とした記録である。
Coreの追加分は[別のレビュー](REVIEW-core.md)に範囲と限界を残した。

## Natを別表現へ変換しない半分化

`core.halve_nat`は二つずつSuccを消費し、商へ一つずつSuccを積む末尾再帰である。
`halveNat_sound`は、任意のnに対する`2*商+Boolの余り=n`を示し、
`halfNat_floor`は商が`n/2`と等しいことを示す。
MoonBit側では0〜4096の商・余りと、200001の大きなNatを別に検査する。
Binary converter自身もこの関数を呼び、円分体とFp多項式の半分化はBinary往復を作らない。

公式配布：[Lean v4.19.0](https://github.com/leanprover/lean4/releases/tag/v4.19.0)。
zipのSHA256：`4e09ca16ff782f51f58b409e7bf983591a3fa17b85aa18d56feddca4398b7f29`。
checker/olean/共有ライブラリだけを抽出し、グローバルなelanやPATHは変更しない。
