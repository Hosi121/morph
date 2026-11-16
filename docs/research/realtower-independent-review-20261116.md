# 多段実代数塔の独立検査（2026-11-16）

対象は `163430f` の `src/realtower`。実装者とは別の担当が、計算核を変更せずに
独立な期待値と証明全体の差し替えを用いて検査した。
この検査の目的は、選択実埋込みと可約定義・意味論的な零・相対根数・証明の入力束縛の境界を確認すること。
終了条件は、以下の有限の検査族を3 backendで実行し、見つかった反例と修正後の結果を記録すること。

## 独立な期待値

[生成器](../../tools/generate_realtower_review.py) はMoonBit実装を呼ばない。
Fractionの有理数演算と `a+b*sqrt(2)` の係数対演算を独立に持ち、
後者の積・逆元は `sqrt(2)^2=2` とnorm、符号は有理数の平方比較で求める。
正負両方の実埋込みについて符号と値を検査し、SymPyの厳密な代数式とも照合する。

- 8件：可約4次定義の有理選択根 `-2,0,1,3/2` における有理関数。
  分母は未選択成分で零となる因子を含むが、選択成分では非零である。
- 16件：正負の `sqrt(2)` の選択埋込みにおける4次までの有理式。
  零・符号・比較・逆元・分母を掛け戻す恒等式を検査する。
- 20件：既知の有理根と多重度から生成したSturm–Tarski query。
  期待値は `(lower,upper]` に属する相異なる根でのquery符号の和をFractionで計算する。
  queryとの共通根、重根、両端での零、右Taylor jetを含む。
- 8件・各5区間：`Q(sqrt(2))` と `Q(2^(1/4))` 上の3/4次相対多項式。
  SymPy `Poly.count_roots` の厳密な閉区間根数から左端の根を除いて `(lower,upper]` に変換する。
  係数・根数の計算にはFloat、近似根、数値サンプリングを使わない。
  実根だけの積に加え、選択埋込みで実根数が変わる二次因子とさらに深い実根も含む。

## 従属拡大と入力束縛

`alpha=±sqrt(2)` の上で `beta^2-2` の同じ符号の根を選ぶと `beta=alpha`。
この依存関係は定義多項式の剰余環では恒等式にならないが、選択実埋込みでは成立する。
`beta-alpha` が非零のraw剰余でも符号零・逆元拒否となること、
その係数を末尾に持つ相対多項式の次数が落ちることを確認する。
`beta+alpha` は未選択成分で零となるが、選択根ではその逆元が存在し `alpha/4` と一致する。

証明差し替えは一つのbit反転だけに限定しない。
同じ符号の異なる有効なcontext、同じsquarefree根集合を持つ異なる元の重複因子付きsource、
異なるsourceの全system/count/root/boundデータ、根順序と根の重複を含めて検査する。
各再計算主張を新しいsourceに束縛し直し、その根数も正しい場合の受理を正の対照とする。
単に別の証明から来たという理由だけで、数学的に正しい主張を拒否する検査にはしない。

## 見つかった反例

旧 `163430f` では、opaqueなSystem内部のsequenceとsquarefreeの整合性がcheckerに束縛されていなかった。
公開クライアントからこれらの構造体を直接作ることはできないが、white-boxで次の反例を再現した。

```text
P = x^2 - 2, Q = x^2 + 1
s = system(P), t = system(Q)
forged = { ..s, sequence: t.sequence }
c = count_between(forged, (-2,2])       // 0
check_count(forged, (-2,2], 0, c)       // true (旧実装)
```

実際のPの相異なる実根数は2である。
この最小例を実装担当と統合担当に報告した。同じ検査にはRootの内部squarefree/sequenceと、
SolutionSetの内部Systemの一貫した差し替えの拒否も含めた。
修正は元の実装担当が行い、独立検査担当はproductionファイルを変更しない。

## 到達点と制約

元の実装担当による修正 `da46274` を取り込んだ後、独立57件は native / wasm-gc / JS で各57/57成功した。
修正前の同じcorpusではopaque改竄1件が失敗し、修正後はそのSystem・Root・SolutionSetの差し替えも全て拒否した。
警告禁止check、生成fixtureの再生成整合性、format check、purity gateも成功した。

検査ログと修正前後の対象commit、3 backendの結果は
[測定・検査記録](../measurements/realtower-review-20261116.json)に保存する。
この検査は有限の厳密例によるadversarial reviewであり、任意深さ・任意次数の形式的な正当性証明ではない。
性能改善の比較実験でもない。元実装担当のflat数体fixtureとは別の期待値生成器と例を使用した。

## 追加：shifted quadraticの符号判定に向けた厳密corpus

二次定義の符号判定を親の体の四則・比較へ帰着する候補に向け、13 context・123 linear queryを追加した。
これにより独立検査は全70件となり、現行の汎用PRS実装 `da46274` で native / wasm-gc / JS 各70/70成功した。

一次係数が非零の `beta=h±k*sqrt(2)`、頂点が区間端点にある場合、
もう一方の根が除外される左端点で選択根が含まれる右端点にある可約二次定義を含む。
重根を持つ二次入力のsquarefree定義が一次になる場合も検査する。
queryには零・定数・正負の傾き・非自明な `a*beta+d=0`、
`239/169, 577/408, 1393/985, 19601/13860` による `sqrt(2)` の両側からの近接相殺を使う。

さらに親を `alpha=sqrt(2)` とする `beta^2-2*alpha*beta+1` から `beta=alpha±1` を選び、
一次係数自体が有理数でない二つのcontextを追加した。
queryの係数も `Q(sqrt(2))` とし、例えば `alpha*beta-2∓alpha=0` を係数対のFraction oracleで確認する。
この追加は最適化を採用したという記録ではなく、同じ期待値で候補実装を検査するためのもの。
[追加corpusのbaseline検査記録](../measurements/realtower-review-quadratic-20261116.json)に全期待値を残した。

## 最適化後の独立再検査

二次符号判定の最適化 `aedec4f` を取り込み、同一の独立70件を native / wasm-gc / JS で再実行し、各70/70成功した。
shifted quadraticの13 context・123 query、irrationalな一次係数、従属拡大、零の判定、
proof/context差し替えの全検査を含む。追加の反例は見つからなかった。
警告禁止checkも成功した。gcd正規化はこの対象commitに含まれない。
[最適化後の独立検査記録](../measurements/realtower-review-optimized-20261116.json)に対象commitとログを残した。
これらのpackage test時間はcompile/harnessを含むため、速度改善の比較として使わない。
