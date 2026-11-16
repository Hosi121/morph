# 検査済み実最小多項式による有理数体の剰余演算

`src/numberfield/` は、`realminimal` の完全因数分解・既約性証拠が
`Proven` と検査できた最小多項式 `m` に対して `Q[t]/(m)` を構成する。
通常の加減乗除では剰余多項式だけを使い、resultant や共役選択を再実行しない。
性能改善の実測を主張する成果ではない。

## 公開入口と型の境界

- `field(proof, verification_fuel)` は `realminimal.check=Proven` が必要。
  `Refuted` は `InvalidCertificate`、`Undecided` は `VerificationBudget`。
  既約性を仮定する unchecked な公開 constructor はない。
- `field_result(number, proof, fuel)` は別渡し Number の root certificate も厳密に束縛する。
- `Field` と `Element` は外部から構築できない opaque 型。
  `element(field, p)` が一変数を確認して `p mod m` に正規化する。
- `same_field` は monic な最小多項式と選択根の半開区間の厳密一致。
  異なる証拠から同じ context を検査して構築した Field は互換だが、
  同じ多項式の別共役、別の最小多項式、同じ根を囲む別区間は互換でない。
  これは抽象数体の同型判定を行わず、選んだ実埋込みの取り違えを防ぐ契約である。
- `rational/zero/one/generator`, `add/subtract/negate/multiply`, `equal/is_zero`、
  `representative/parent/modulus/degree/embedding/certificate` を公開する。
- 二項演算は両方の context を照合し、不一致なら `DifferentField`。
  別 Field に多項式を明示的に読み込む操作は新しい解釈であり、暗黙の coercion はない。

## 逆元の証拠

`inverse_with_certificate(a)` は一変数多項式の extended Euclid を行う。
`inverse(a)` はその値だけを返し、零の逆元は `Ok(None)`。
`divide` も零除算は `Ok(None)` とし、異なる Field の零との除算はまず context mismatch を返す。

証拠は context、入力剰余 `a`、逆元剰余 `b`、補助多項式 `c` を持つ。
独立の `check_inverse_result(a,b,proof)` は両方の opaque Element と証拠を束縛し、
`a*b + m*c = 1` を **Q[t] の等式として**確認する。
checker は Euclid を再実行しない。逆元 producer の一時的 gcd が定数にならない場合は
内部不変条件の失敗として扱い、既約性を推測で補わない。

## trace と norm

基底 `1,t,...,t^(d-1)` 上の線形写像「a を掛ける」の列を `a*t^j mod m` から作り、
`multiplication_matrix` を返す。`trace` は対角和、`norm` は既存 `linear.determinant`。
この意味は SageMath の[数体要素の公式文書](https://doc.sagemath.org/html/en/reference/number_fields/sage/rings/number_field/number_field_element.html)
にある power-basis multiplication matrix と absolute trace/norm の定義に合わせた。
数体要素を有理係数多項式で表すことは [SymPy number fields の公式文書](https://docs.sympy.org/latest/modules/polys/numberfields.html)
とも対応する。Sage/SymPy の計算を production kernel から呼び出すことはない。

## 有限の独立検証

native / JS / Wasm GC 各 **70/70** test が `--deny-warn` で成功。
うち独立 oracle fixture は8法（次数1〜4）の64例。
残り6 test で零逆元、有理数・零の次数1、別 Field/共役/interval、
公開証拠の定義・payload 改変、Bezout 改変、積一致だけの reducible 偽装を検査した。
全64例で環・体の法則、trace の加法性、norm の乗法性も検査する。
入力は小さい有理係数だが期待される逆元係数等には32bitを超えるものがあり、
fixture adapter は Int64 から独自 Binary を作る（production に machine 整数はない）。

純粋性 gate は **146 kernel files** を通過。生成 `.mbti`、format check、
fixture の再生成 byte 一致も成功。ログは
`.tools/numberfield-20261116/verification-milestone1.json`、
oracle の全データは同ディレクトリ `fraction-fixtures.json`。
`tools/generate_numberfield_fixtures.py` は Python 標準 `Fraction` による長除算、
乗法行列の Gaussian elimination による逆元、全順列 Leibniz determinant を使用する。
逆元 oracle は production の extended Euclid と別経路である。
SymPy は各法の既約性、剰余積、逆元、resultant による norm を追加照合する。

## 制約

対象は選択された実根を持つ有理数体。複素埋込み、抽象数体同型、最大整環、整数基底は扱わない。
最小多項式の検査 fuel は既約性証明の有限 subset 検査 budget であり、
剰余演算・Euclid・行列式の arithmetic work や stack depth の上限ではない。
係数と次数が大きい入力の実行時間・メモリ制限は別途必要。
既存 realalgebraic/Zassenhaus/realminimal/F4/FGLM source は変更していない。
