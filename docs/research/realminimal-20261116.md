# 実代数的数の最小多項式正規化、2026-11-16

[ドキュメント](../README.md) / [研究・探索記録](README.md)

[研究・探索記録](README.md) / [実代数的数](realalgebraic-20261116.md) / [Zassenhaus](zassenhaus-20261116.md)

`realalgebraic.Number` の定義多項式を明示的に因数分解し、同じ選択根を表す monic・Q 上既約な最小多項式へ置き換える。既存の arithmetic は変更しない。手書き計算核は不変 ADT・Bool・Nat・Chain・クロージャのみで、機械数値・配列・可変状態・FFI を使わない。

[公開 API](../../src/realminimal/pkg.generated.mbti)、[正規化](../../src/realminimal/realminimal.mbt)、[証拠検査](../../src/realminimal/certificate.mbt)、[多項式表現の橋渡し](../../src/realminimal/polynomial.mbt)。

## 入口と未完了の扱い

`normalize(number, primes, lift_fuel, subset_fuel, verification_fuel)` は `Normalized(Number, Certificate)` または `Unresolved(reason)` を返す。`normalize_root` は元の raw `RootCertificate` を受け取り、非 monic・有理係数・繰返し因子を含む定義も直接扱う。

`Number` 自体は構築時に monic square-free 定義へ正規化されている。従って `normalize(Number)` はその現在の定義を分解し、raw 定義の重複度まで証拠に残したい場合は `normalize_root` を使う。

素数候補は有限の明示リスト。Zassenhaus の `factor_rational` が完全分解を返した後、`check_rational_factorization` が **Proven** となることを必須条件とする。係数の積一致だけを minimality とみなす経路はない。零・有理数・既に minimal な定義でも、この証明条件を省略しない。

| 戻り値 | 意味 |
| --- | --- |
| `Normalized(value, proof)` | 完全分解・既約性・選択根を検査済み |
| `Unresolved(NoGoodPrime)` | 指定リストに良い素数がなかった |
| `Unresolved(LiftBudget)` | 必要な prime-power precision に未到達 |
| `Unresolved(SubsetBudget)` | recombination の full subset exhaustion が未完了 |
| `Unresolved(VerificationBudget)` | 分解は完了したが verifier が Undecided |
| `Err(InvalidInput)` | 無効な定義・零/複数根 interval など |

lift / subset fuel は Zassenhaus と同じく square-free component ごと、verification fuel は既約性を主張する因子ごとに適用する。算術演算数・ビット演算数・時間・メモリの総予算ではない。Unresolved は中断状態を保持しないため、予算を増やす retry は factorization からやり直す。

## 最小多項式と共役の選択

完全分解を検証した後、元の半開一根区間 `(lower,upper]` に根を持つ唯一の因子を選ぶ。producer は候補を集めて一つであることを確認し、checker は selected index と全因子の Sturm root count を別に検査する。選択因子は区間内の root count が一、その他はゼロでなければならない。

選んだ primitive 整数因子を有理係数の monic 多項式へ直す。例えば `3x−2` は `x−2/3` になる。結果の interval は元と同一なので、元の一根と別の共役に切り替わらない。

既約な monic 因子 `g` が選択根 α を持てば、それが Q 上の最小多項式である。より低次数の非零 annihilator `h` があれば、既約性から `gcd(g,h)=1`。Bézout 恒等式を α へ代入すると一がゼロとなり矛盾する。完全分解の一致と一根区間が `g(α)=0` を、Zassenhaus checker の Proven が既約性を担う。

この処理が落とすのは選択根を含まない**余分な既約因子**。最小因子そのものの別共役は、有理係数のまま取り除けない。実測した固定例では `sqrt(2)^2` の既存定義 `x²−4` を `x−2` へ、余分な実・複素因子を持つ degree 五の sqrt(2) 定義を degree 二へ下げた。一方 `sqrt(2)+sqrt(3)` の `x⁴−10x²+1` は既約なので degree 四のまま保持し、その既約性を証明する。

## 証拠と値付き checker

公開 `Certificate` は元 `RootCertificate`、完全な `RationalFactorization`、選択因子の Nat index、結果の `RootCertificate` を持つ。

- `check(proof, verification_fuel)` は自己記述的な証拠を再検査し、Zassenhaus と同じ `Proven / Refuted / Undecided` を返す。
- `check_result(value, proof, fuel)` は返却 Number の canonical root certificate が proof.result と完全一致することも要求する。
- `check_normalization(original, value, proof, fuel)` は、caller の元 Number も proof.input から構築した Number と同じ canonical 定義・同じ interval であることを要求する。raw 入力の scalar と重複は Number と同じ規則で正規化して比較する。

値付き検査は表現の束縛であり、任意の interval で表した等値な Number 全てを受理するものではない。自己記述的な proof 全体を別の共役へ整合的に組み替えると、その別入力に対する proof としては正しい場合があるが、元 Number を指定した `check_normalization` は拒否する。この context 束縛も試験した。

係数積が正しくても可約な全定義を一つの「既約因子」にした偽証拠、別の因子・別共役・無関係な Number、範囲外の selected index を拒否する。下端に別因子の root がちょうどある場合は正しく除外し、上端にある選択根は含める。

## 独立照合

[generator](../../tools/generate_realminimal_fixtures.py) は SymPy 1.14.0 の [minimal_polynomial](https://docs.sympy.org/latest/modules/polys/numberfields.html#sympy.polys.numberfields.minpoly.minimal_polynomial)、exact root isolation、代数式の sign 判定を使う。production の Zassenhaus / Sturm とは別に期待する monic minimal polynomial と選択 interval を生成する。

零、有理数、正負の平方根・立方根、逆平方根、平行移動した根、黄金比、二平方根の和と差など十八式を、それぞれ余分な実/複素因子付き、繰返し因子付きの二定義へ変換した計三十六 fixture。全ての raw 定義は非 minimal で、返却定義が期待値に一致し、元 Number と同値で、次数が実際に下がることを検査する。

追加試験は既存演算 `sqrt(2)^2` と `sqrt(2)+sqrt(3)` の明示正規化、prime / lift / subset / verification 各不足の Unresolved、product-only forgery、別因子・共役・payload・input context 差替え、下端 root 除外、公開 API の black-box 呼び出しを含む。suite は四十三テスト。

| 検査 | 結果 |
| --- | --- |
| native / JS / Wasm GC、`--deny-warn` | それぞれ 43 passed / 0 failed |
| purity gate | 143 kernel files passed、この worktree の先行成果を含む |
| SymPy fixture 再生成 | formatter を含めた byte 一致 |
| `moon info src/realminimal` | compiler-generated API を生成 |
| package fmt check | 成功 |

生ログ・command・独立 fixture data は `.tools/realminimal-20261116/` に保存する。

```sh
tools/measure --cpu 6 python3 tools/generate_realminimal_fixtures.py
tools/measure --cpu 6 tools/moon test src/realminimal --target native --deny-warn
tools/measure --cpu 6 tools/moon test src/realminimal --target js --deny-warn
tools/measure --cpu 6 tools/moon test src/realminimal --target wasm-gc --deny-warn
python3 tools/audit_purity.py
tools/measure --cpu 6 tools/moon info src/realminimal
```

## 残る制約

この worktree では Zassenhaus の最初の verified API と realalgebraic の値付き checker fix を使用し、既存本体を変更していない。Zassenhaus の追加境界 commit は API 変更がないため、この新 package の依存に追加していない。

選択根の正確な表現・Sturm root count・Zassenhaus の十分な precision / full exhaustion / 既約性検査は実装依存として残る。既存 checker を接続する証拠であり、この MoonBit 実装全体を形式的に証明したという主張ではない。factorization の指数的 subset 探索や係数成長を軽くする変更、最良の素数選択、性能比較、大規模な資源上限、演算ごとの自動正規化は対象外。次数の低下は固定例で確認した成果であり、全演算で次数が下がるという保証はない。
