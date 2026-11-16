# Zassenhaus 独立レビュー、2026-11-16

[研究・探索記録](README.md) / [実装記録](zassenhaus-20261116.md)

実装者とは別のエージェントが、`df66e93` の Zassenhaus 実装を独立に検査した。この専有 worktree では依存コミットを `d42a183` として取り込んだ。レビューで追加したものは [テスト](../../src/zassenhaus/independent_review_wbtest.mbt)、[標準ライブラリだけの数値 witness 検査](../../tools/zassenhaus_independent_review.py)、本記録のみ。本体・既存テスト・既存 generator は変更していない。

検査した範囲では、`Complete` / `Proven` の誤受理、非モニック復元の誤り、Hensel 不変条件の破れは見つからなかった。これは実装の完全な正当性証明ではなく、以下の有限検査とソース上の推論による結果である。

## 係数界と非モニック復元

非零の整数多項式 `F` と整数除数 `g` について、Mahler measure の乗法性と整数の補因子の measure が一以上であることから、`g` の各係数は `2^degree(F) * ||F||₂` 以下、従って実装の `B = 2^degree(F) * ||F||₁` 以下となる。`F = 0` では任意の多項式が除数なので、この結論は適用できない。公開 `coefficient_bound(0)` の戻り値ゼロはゼロ多項式の除数界として使用してはならず、因数分解 API 自体はゼロを拒否する。

primitive・最高次係数正の除数 `g` の最高次係数を `b`、根 `F` の最高次係数を `a` とすると、`b` は `a` を割り、対応する monic lift の subset 積に `a` を掛けたものは `(a/b)g` と合同になる。各係数の絶対値は `aB` 以下なので、`m > 2aB` を満たせば対称剰余の復元は一意となり、primitive part から `g` を復元できる。最高次係数を常に一とみなす実装にはなっておらず、検査器も根から界を再計算する。係数界・lifting uniqueness の前提は [Divasón et al., Sections 7–9](https://link.springer.com/content/pdf/10.1007/s10817-019-09526-y.pdf) と照合した。

数値検査は実装の polynomial 演算を使わず、機械整数の畳み込み・gcd・法逆元で行った。

- primitive 一次因子二つの全 529 積で、`B` の算術式、`2aB`、真の因子係数が界内にあることを照合。
- 二つまたは三つの既知の非モニック一次因子から作る 48 ケースで、各 `q_i` の monic lift が直接計算した `q_i / lc(q_i) mod p^k` と一致することを検査。正負の content と `p = 3,5,7` を含む。
- 各ケースの指数一〜五、計 240 段で monicity、係数範囲、次数、元の因子との合同性、非モニック product invariant を独立に照合。
- 十分な精度へ進めたあと、全 proper subset の計 192 復元を、既知の整数因子積および独立した対称剰余・primitive 化と照合。
- 可約だが pairwise coprime な二次 modular seed も正しく lift できることを検査。同じ lift に空の有限体既約証拠を付けても整数既約性は受理されない。

## Complete と既約性の独立 oracle

有理根定理は次数二・三で可約性の完全な判定となる。この条件を使い、次の全 primitive・最高次係数正の入力を検査した。

| 次数 | 係数範囲 | 件数 |
| --- | --- | --- |
| 二 | 最高次 `1..3`、その他 `−3..3` | 129 |
| 三 | 最高次 `1..3`、その他 `−2..2` | 347 |
| 合計 | 既約 309 件、可約 167 件 | 476 |

全入力で `Complete`、全出力で `check_factorization = Proven` を得た。各出力について、独立した数値畳み込みによる入力の復元、primitive 正規化、正の重複度、各二次・三次因子の有理根が存在しないことを確認した。可約な入力全体を「単一の既約因子」として返す偽造 factorization は、product 検査には通るが、全件で irreducibility 検査に拒否された。

四次 `x^4+x+2` の既約性も CAS に頼らず確認した。有理根はなく、monic 二次因子二つが存在するなら、その定数項 `b,d` は `bd=2`、一次項は互いに反対で、`a²=b+d` を満たす。可能な `b,d` 四組の和は三または負三なので不可能。この witness は [Python 検査](../../tools/zassenhaus_independent_review.py) に保持した。

## 全 subset exhaustion と厳密境界

`x^4+x+2` は `p=2` で三つの互いに素な modular 因子を持ち、計算された閾値は 128。

- `m=128` ちょうどでは lift 自体は有効だが、irreducibility は `Refuted`。`lift_above` もこの精度では `Suspended`。
- `m=256` で fuel `0..7` は全て `Undecided`、fuel 8 で `Proven`。
- producer も subset fuel `0..7` は全て `Incomplete(RecombinationBudget)`、8 で `Complete`。
- lifting fuel は六段で `Incomplete(LiftBudget)`、七段で必要精度に到達する。

別の攻撃例は `x^4+4 = (x²−2x+2)(x²+2x+2)`。`p=5` では四つの一次 modular 因子に分かれ、個々の singleton は整数除数にはならない。独立した数値 subset 探索と整数長除法で最初の真の因子が現れる leaf の位置を求め、checker がその直前まで `Undecided`、その leaf を検査できた時点から `Refuted` となることを、fuel `0..16` の全境界で確認した。producer は途中で因子を発見しても full exhaustion 未了なら全て `Incomplete` を返し、16 leaf 完了時にだけ `Complete` を返す。

従って、今回のケースでは singleton 検査への短縮、empty/full subset の未計上、fuel が足りない状態からの早過ぎる `Proven` / `Complete` は起きていない。

## 偽造証拠

`x^4+x+2` と `x^4+x−130302` は modulo 256 で同一。後者は整数根 `−19` を持つ可約多項式である。元の十分な lift に対して target だけを後者へ入れ替える攻撃を行った。

- `check_lift` は受理する。これは正しい合同式であり、lift 検査だけでは整数既約性を主張しない設計どおり。
- 新しい target の閾値は 4,169,728。検査器はこの界を再計算するので、modulus 256 の証拠では `check_irreducible = Refuted`。

さらに、lift 係数への一加算、modulus の加算、負の係数、非 monic 化、lift だけの交換・欠落、ゼロ指数、非素数や異なる素数、定数 seed、異なる field、重複 seed、target の変更、最高次係数の退化、空の有限体既約証拠を拒否することを検査した。primitive でない target への scale は合同式を保っても既約性証拠として拒否された。

## 再現と残る制約

追加レビューは 8 テスト。既存 36 テストと合わせた package suite は 44 テスト。

| 検査 | 結果 |
| --- | --- |
| レビュー専用 native、`--deny-warn` | 8 passed / 0 failed |
| package native、`--deny-warn` | 44 passed / 0 failed |
| package JS、`--deny-warn` | 44 passed / 0 failed |
| package Wasm GC、`--deny-warn` | 44 passed / 0 failed |
| 独立 Python witness | 全 assertion 成功 |
| purity gate | 127 kernel files passed、この worktree の既存 Blossom を含む |
| package fmt check | 成功 |

各 backend の結果とコマンドは `.tools/zassenhaus-independent-review-20261116/verification.json`、標準出力は同ディレクトリの `*.log` に保存する。独立数値 witness の JSON も同ディレクトリに保持する。

```sh
tools/measure --cpu 6 python3 tools/zassenhaus_independent_review.py
tools/measure --cpu 6 tools/moon test src/zassenhaus/independent_review_wbtest.mbt --target native --deny-warn
tools/measure --cpu 6 tools/moon test src/zassenhaus --target native --deny-warn
tools/measure --cpu 6 tools/moon test src/zassenhaus --target js --deny-warn
tools/measure --cpu 6 tools/moon test src/zassenhaus --target wasm-gc --deny-warn
```

レビューは特定の有限範囲であり、任意次数・任意係数について機械化した証明を追加したわけではない。公開検査器が依存する symbolic 整数・有限体演算そのものを、このレビューだけで再検証したとは主張しない。性能比較や大規模入力の資源上限は対象外。検査器の前提を満たさない非 canonical な private ADT をテスト内部から作る攻撃は、公開 API の入力範囲と分けて扱い、今回の誤受理判定には使っていない。
