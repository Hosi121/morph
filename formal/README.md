# 基礎ADTのLeanモデル

[ドキュメント](../docs/README.md)

有限テストとは別に、Core・Binary・Comparison・Fold等のモデルの全称命題をLean 4.19.0で検査する。
Mathlibや追加Leanライブラリは使わず、公式配布のStdだけを利用する。
Leanは検証用で、MoonBitの計算核の依存ではない。

```sh
python3 tools/bootstrap_lean.py   # Linux x86_64、.tools内へ隔離
tools/check_formal
```

| 主張 | Leanの定理 | 対応するMoonBitの関数 |
| --- | --- | --- |
| 原子観測の一様性を任意深さのBoolean式へ伝える | partialEvaluate_sound / known_is_uniform | prefixlogic.evaluate_conditional のBoolean部分（[対応と仮定](REVIEW-prefixlogic.md)） |
| 全8条件のfull adderが桁の和を保存 | fullAdder_sound | binary.full_adder |
| 任意の有限bit列のincrementが値を1増やす | increment_sound | binary.increment_bits |
| 任意の二つの有限bit列とcarryの加算が値を保存 | addition_sound | binary.add_bits / add |
| Succ二個ずつの分割が商と余りを保存 | split_sound / halveNat_sound | core.halve_nat（旧Binary経路も保存） |
| 任意の自然数の半分化がfloor(n/2)を返す | halfNat_floor | core.half_nat |
| 共有したzero/one factoryの値が0/1 | zero_sound / one_sound | binary.zero / one / canonical helpers / immutable globals |
| 8進単位の分割が商と三bit余りを保存 | splitGrouped_sound | binary.split_nat_grouped |
| 省略可能な高位0の除去が値を保存 | lowBit_sound | binary.low_bit |
| 任意の自然数からbit列への変換が正規性を保存 | fromNat_canonical | binary.from_nat / from_nat_grouped |
| 任意の自然数からbit列への変換が値を保存 | fromNat_sound | binary.from_nat / from_nat_grouped |
| 旧二進分割による変換が値を保存 | fromNatByHalves_sound | 比較用の旧converter |
| 非canonicalを含む全有限列で新旧比較が等しい | protectedCompare_eq_reference | binary.compare_bits / compare_bits_tail / compare_bits_grouped |
| canonicalな列の比較が数値順序を表す | protectedCompare_sound | binary.compare |
| reverse-left foldと従来right foldが一致 | foldLeft_reverse / boundedRightFour_eq_foldRight | core.reverse / reverse_onto、未採用のwide試作の参照法則 |
| 均質blockのcarry/borrowが一桁後に安定 | carry_stabilizes / borrow_stabilizes | full_adder / runbinary.digit |
| 降順指数で疎Hornerが項別評価と一致 | scan_invariant / horner_eq_genericSum | polynomial.univariate_horner / evaluate |

値の意味は`value(Nil)=0`、`value(Cons(b,rest))=bitValue(b)+2*value(rest)`。
加算の定理は最上位の0を含む非正規形の列にも成立する。
証明は帰納法と算術を使い、特定の桁数の総当たりへ切り詰めていない。
`#print axioms`で、Bool全条件の三定理は追加公理なし、
Binary.leanの帰納・算術の定理はLean標準の`propext`/`Quot.sound`のみと確認した。
`sorry`や独自の正しさ公理を導入していない。
実行ログ：[formal-lean.txt](../docs/measurements/formal-lean.txt)。
Core追加後の10領域と各モデル定理は[nat-path-validation.txt](../docs/measurements/nat-path-validation.txt)に記録する。

## 信頼する境界と変更検出

MoonBitからLeanへの変換器やコンパイラを形式検証したものではない。
両方のADTと関数の構造の対応は人手のレビューで、実行テストも別途必要になる。
Leanモデルの値の定理から、MoonBitの資源上限、最上位bitの正規性、
全run演算、全SAT、コンパイラの正しさは結論しない。

`tools/check_model_drift.py`が、対応を確認した32領域のコメント/空白を除くtoken列と
Binary定数recordのinitializerと全Leanモデルファイルのhashを`source-map.json`に照合する。
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

`core.halve_nat`はfastで二つずつ、slowで一つずつSuccを消費し、既存tailを返す。
`fast≤slow`の不変条件でfallbackを除外し、初期状態fast=slow=nから商を得る。
`halveNat_sound`は、任意のnに対する`2*商+Boolの余り=n`を示し、
`halfNat_floor`は商が`n/2`と等しいことを示す。
MoonBit側では0〜4096の商・余りと、200001の大きなNatを別に検査する。
円分体とFp多項式の半分化はBinary往復を作らない。
旧Binary converterのモデル`fromNatByHalves`もCoreをimportして同じhelperを使う。
現在のconverterは次節の8進分割を使う。
`tools/check_formal`はCoreをローカルの`.tools/formal/Core.olean`へ先に再生成し、
そのディレクトリをLEAN_PATHの先頭に置く。別の古いCore artifactを前提にしない。
末尾共有への変更の[独立レビューと実測](../docs/bootstrap/nat-tail-sharing.md)も残す。

公式配布：[Lean v4.19.0](https://github.com/leanprover/lean4/releases/tag/v4.19.0)。
zipのSHA256：`4e09ca16ff782f51f58b409e7bf983591a3fa17b85aa18d56feddca4398b7f29`。
checker/olean/共有ライブラリだけを抽出し、グローバルなelanやPATHは変更しない。

## Natから三bitずつ作る変換

`binary.from_nat`のprivate helperはfastを八つ、slowを七つずつ進める。
`splitGroupedLoop_sound`は`fast≤slow`の下で`8*商+三bit余り=8*slow−7*fast`を示し、
初期状態fast=slow=nから`splitGrouped_sound`を導く。正の入力では商が小さいため
`fromNatGroupedBits`の再帰は停止する。高位の余分な0を省く`low_bit`の意味は`lowBit_sound`で保つ。
旧二進分割・変換の定理も削除せず、`fromNatByHalves_sound`として維持した。

新しいモデル定理のうち`lowBit_sound`は公理なし、商・停止性・値の定理は標準の
`propext`/`Quot.sound`のみを使う。正規なtailへの`lowBit_canonical`と
全自然数への`fromNat_canonical`も別に示す。MoonBitの末尾共有、tupleの三bit順序、fallback、
三つのlow_bit呼び出しとの対応は[レビュー記録](REVIEW-nat-grouped.md)に分けた。
不正な余り・低bitの破棄・高位0の残留をnegative controlで検査する。
値の定理は元の主張を維持し、全入力の物理的なstack/heap上限やコンパイラの正しさは含めない。
採否と三backendの有限実行証拠は[8進変換の記録](../docs/bootstrap/nat-radix-grouping.md)を参照する。

共有zero/oneについてはpublic factory、private helper、不変globalのinitializerもlockする。
Leanでは同じalias関係を定義し、zero_sound/one_soundを公理なしで示す。
ソースlockは値の翻訳証明ではなく、初期化の実行時挙動は三backendの有限oracleで別に検査する。

## 比較の有限prefixとtail loop

`Comparison.lean`は既存Binaryのvalue/canonicalをimportし、新旧比較の全有限列での等価性と、
canonicalな場合の数値順序を検査する。sourceの先頭八段と四node groupの対応は
[比較のレビュー](REVIEW-comparison.md)、採否とstack/速度の有限実行証拠は
[比較kernelの記録](../docs/bootstrap/binary-comparison.md)へ分けた。
`tools/check_formal`はCoreに続けてBinary.oleanも再生成し、Comparisonが古いartifactをimportしない。
function fingerprintは直前のcode-generation属性も含め、値を変えないinline方針の変更も検出する。

## 対応レビューと変更記録

| 資料 | 対象 |
| --- | --- |
| [Binaryの独立レビュー](REVIEW.md) | 初期の加算・変換モデルとMoonBitの構造対応 |
| [Coreのレビュー](REVIEW-core.md) | prefix共有の追加分 |
| [Nat変換のレビュー](REVIEW-nat-grouped.md) | 8進単位の変換、値・停止性・正規性 |
| [比較のレビュー](REVIEW-comparison.md) | raw列の旧比較との一致、canonical値の順序 |
| [疎Hornerの独立レビュー](../docs/research/sparse-horner-independent-review-20261116.md) | 抽象代数のscan不変条件、降順前提、公開dispatchと独立QQ oracle |
| [対応の変更記録](drift-ledger.md) | 仕様・ソース・モデルを揃えた変更の経緯 |

各レビューの領域数や実行結果はレビュー時点の記録です。
横断検証の固定スナップショットは[検証ガイド](../docs/VALIDATION.md)から参照できます。

## 疎Hornerの抽象代数モデル

[SparseHorner.lean](reviews/SparseHorner.lean)は、明示した結合則・単位則・右分配則と
指数の降順を前提に、gapを使うscanの不変条件と項別評価との一致を示す。
可換性は不要だが、実際の有理数実装が各法則を満たすことはこのモデル内では証明していない。
二進累乗と0/1の省略も示し、Nat→bit列の値の保存は明示的な仮定にしている。
既存のBinaryモデルとの構造対応と、MoonBitでの独立QQ評価は別途確認する。
降順を外すと結果が変わる具体的な反例も、Leanと実sourceのコピーで検査する。

`tools/check_formal`はこのモデルも毎回検査する。通常の差分ゲートは
評価器とsmart constructorの7領域、およびモデルを既存のlockへ追加して監視する。
正しさの前提を消したまま実装やモデルを更新しないための仕組みであり、翻訳証明ではない。
