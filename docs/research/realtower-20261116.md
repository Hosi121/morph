# 多段実代数塔（2026-11-16）

## API 契約の初期公開

`src/realtower/pkg.generated.mbti` はコンパイラで生成した契約である。
この初期コミットは API の接続先を固定する段階であり、fallible な演算は
`PendingImplementation` を返す。証明書 checker はまだ証明を受理しない。
これを数学的実装の完成や実験結果として数えない。

- `rational_field`, `rational`, `scalar_field`, `same_field`, `embed`
- `scalar_add/subtract/multiply/inverse/divide/sign/equal/compare`
- `polynomial(field, ascending_coefficients)`, `coefficients`, 四則演算、微分、評価
- `system`, `count_between`, `root_in_interval`, `isolate/start/advance`, `refine`
- `adjoin(root)` は新しい `Extension { field, generator }` を返す。
- scalar、source system、根、全根被覆には公開 payload 証明書と checker を持つ。

Field は親の塔・monic squarefree な raw 定義多項式・有理選択区間を保持し、
構築は一根性の検査を通す。Scalar は Field と raw な分子分母の組を保持する。
raw 係数には親の Field を重複保存しない。Field の同一性は構文的な context の
同一性であり、値の等価性は選択実埋込みでの意味論的な零判定による。

分母は選択根で非零であればよい。商環全体で可逆であることや、定義多項式の
既約性・最小性は要求しない。次数は真の体拡大次数と主張しない。

端点は既存 `orderedsturm` と同じ `(lower, upper]`。符号付き PRS の端点零は
最初の非零導関数による右側 Taylor 符号で扱う。checker の最初の実装は、
source/context/payload を束縛して厳密な決定計算を再実行する方式であり、
探索を再実行しない証明検証器とは主張しない。

初期検査：`tools/measure --cpu 6 tools/moon check --target js src/realtower` 成功。
`moon info` のログは `.tools/realtower-20261116/api-info.log`（未追跡）。

## 最初の実装済み到達点

初期 scaffold の全演算・checker は実装に置き換わった。
`PendingImplementation` は初期契約との互換性のための enum 名として残るだけで、
現在の実装から返す経路はない。Field / Scalar / Polynomial の derived `Eq` は
raw 表現の比較であり、数学的等価性には `scalar_equal` / `polynomial_equal` を使う。

順序判定は分子分母の Sturm–Tarski query を親の係数体へ帰着する。
係数の逆元も一段低い塔を再帰的に扱うため、任意の有限深さに対応する。
深さ2/3を実測したが、深さによる性能上限や実用性能の一般的主張はしない。
全根分離は strict Cauchy bound の倍増探索と有理二分を fuel で中断・再開できる。
証明書 checker は厳密な決定計算を再実行し、context、原入力、結果の個々の
payload を比較する。根の探索全体を verifier から再実行する必要はないが、
PRS と符号決定は再計算する。

6テストが native / wasm-gc / JS の各 backend で成功。
[測定条件と検査範囲](../measurements/realtower-20261116.md)に記録した。
次段階は独立な Fraction/SymPy による平坦な数体 oracle と相対根分離の照合。
