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

## Opaque 結果 payload の検査強化

独立 review と自己点検により、外部から構築できない `System` の内部 sequence を
white-box で別の多項式の sequence に差し替えた場合、初版 `check_count` が
source 証明書だけを再計算して受理する例を確認した。例えば `x²-2` の source に
`x²+1` の sequence を入れ、`(-2,2]` の根数0を与える例である。

`system_payload` で source から正規の System 全体を再構築して照合するようにし、
count、bound、Root、SolutionSet 内の squarefree/sequence を含む payload を束縛した。
同じ差し替えを Root/SolutionSet に行う white-box 受入検査が native で成功した。
外部クライアントに opaque 型の偽造を許す API はないが、checker の検査対象を
公開証明書だけでなく返却結果全体にも揃えるための修正である。

## 独立な平坦数体 oracle と二次符号判定

`tools/generate_realtower_fixtures.py` は塔を使わず、一つの既約式
`X^(2^depth)-2`（Eisenstein、depth0では有理数）上の Fraction 係数ベクトルで
算術する。逆元は SymPy の QQ 多項式逆元を積が1となることでも検査し、
符号は有理区間演算・厳密二分で確定する。Float / evalf は使わない。
その独立な数体で相対多項式の signed Sturm sequence を作り、根数と全根数も照合した。
44 quotient・96区間根数・16全根被覆を含む27テストが3backendで成功した。

相対二次拡大では次の厳密短縮経路を使う。monic squarefree な
`f=x²+b*x+c` と選択根 beta に対し、`z=2*beta+b` とすると
`z²=Delta=b²-4*c`。選択区間の上端 u において `2*u+b<=0` なら左の根、
それ以外では `f(u)>=0` なら右の根、`f(u)<0` なら左の根である。
区間がちょうど一根を含む検査を済ませていることを前提に、この分岐は上端が根や
頂点である場合も `(lower,upper]` 規約と一致する。

線形式 `q=a*x+d` では `2*q(beta)=a*z+w`, `w=2*d-a*b`。
両項の符号が同じならその符号、逆なら `w²` と `a²*Delta` の大小で決める。
親の体の算術と符号にのみ帰着し、可約性や親からの独立性を要求しない。
一般次数の定義・query は元の Sturm–Tarski に戻る。Field context は変更しない。
凍結した同一入力での ABBA 計測と残る高次数ケースの制約は
[測定記録](../measurements/realtower-20261116.md)に分けて記した。

Sturm–Tarski の基礎は一次資料
[Deciding Univariate Polynomial Problems Using Untrusted Certificates in Isabelle/HOL](https://wenda302.github.io/assets/pdf/rcf_jar.pdf)
および [Archive of Formal Proofs: The Sturm–Tarski Theorem](https://isa-afp.org/entries/Sturm_Tarski.html)
で確認した。通常の非根端点の式から `(a,b]` への拡張は本実装側の整理である。
有限個の関連多項式の根を越えない正の微小量を取り両端を右に移すと、
a の根は除外され b の根は包含される。その右側の符号を最初の非零導関数で
決めるため、数値的な epsilon や端点摂動を実装する必要はない。
