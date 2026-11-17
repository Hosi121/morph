# 数値系の余分な変換・再構築の読み取り監査

固定ソース: `09f615b8374817d04817eb5b45e776dbee2bfa8a`。`git show <commit>:<path>` と固定コミットの検索で確認した。実装変更・試験・ビルド・計測・コミットは行っていない。

強い重複候補は N01–N06。N07–N12 は追加の不変条件や準備コストも含め次の検証で判定する候補。N13–N17 は必須・既修正・共有済み・テスト専用として除外する。実使用とは静的に非テスト呼出元がある意味で、実行頻度や支配コストを観測した意味ではない。

優先候補は根数だけの Nat/Binary/Integer 往復、塔の再帰定数構築、既約剰余の再 reduce、検証後/同一 start 内の monic 再計算。負差エラー、公開証明の独立検証、context と選択根区間の束縛は保持が必要。

全件未測定。raw_rational の source 呼出木、生成コードの CSE、構造 Eq コスト、実速度は分けて扱う。静的複雑度でも単項 Nat の走査と二進算術を区別する。

| ID | 分類 | 優先 | 内容 |
|---|---|---|---|
| N01 | avoidable_production | high | orderedsturm の根数で Nat→Binary→Integer→Nat |
| N02 | avoidable_production | high | realtower の根数にも Nat→Binary→Integer→Nat |
| N03 | avoidable_production | high | realtower が有理数埋込みと単位元判定で再帰的な 1 を重複構築 |
| N04 | avoidable_production | high | modular.signed_reduce が既約剰余を subtract 経由で再 reduce |
| N05 | avoidable_production | high | numberfield.field が検証済み monic を再 monic 化 |
| N06 | avoidable_production | high | resultant_start が両入力をそれぞれ二度 monic 化 |
| N07 | loop_conversion_candidate | medium | resultant 補間点を Nat から毎回作り直す |
| N08 | representation_candidate | medium | realalgebraic sparse→dense が各単項式を零埋めして加算 |
| N09 | representation_candidate | medium | realminimal dense 係数抽出が次数ごとに sparse terms を再走査 |
| N10 | representation_candidate | medium | NF/CF Horner 評価に legacy な係数全走査が残る |
| N11 | conditional_reduction_candidate | low | modular.power が未正規化 base を立ちビットごとに再使用 |
| N12 | avoidable_production | low | complexalgebraic rational fast path が保証済み linear=1 で除算 |
| N13 | semantically_required | exclude | Nat→Binary→Integer→Rational の一方向埋込みは必要 |
| N14 | semantically_required | exclude | 証明→checked Number/System の再構築は検証境界として必要 |
| N15 | already_fixed | exclude | 昔の Nat→Binary→half→Nat と NF/CF 座標再走査は既修正 |
| N16 | already_cached | exclude | exact.rational_zero/one は既に共有定数 |
| N17 | test_only | exclude | テスト・比較 bench の Nat/Binary 往復は意図的 |

## N01 orderedsturm の根数で Nat→Binary→Integer→Nat

分類 `avoidable_production` / 優先 `high` / 確度 `high` / source `09f615b8374817d04817eb5b45e776dbee2bfa8a`。未計測。

**主箇所**

`src/orderedsturm/count.mbt:109–112`

```moonbit
  @exact.subtract(
    @exact.positive(@binary.from_nat(variations(lower))),
    @exact.positive(@binary.from_nat(variations(upper))),
  )
```

**関連根拠**

`src/orderedsturm/count.mbt:83–89`

```moonbit
///|
fn variations(values : @core.Chain[EndpointJet]) -> @core.Nat {
  fn scan(
    values : @core.Chain[EndpointJet],
    previous : @core.Ordering,
    count : @core.Nat,
  ) -> @core.Nat {
```

`src/orderedsturm/count.mbt:176–185`

```moonbit
        let value = difference(lower, upper)
        if @exact.negative(value) {
          Err(InternalInvariant)
        } else {
          Ok({
            system: system.certificate,
            interval,
            lower,
            upper,
            count: @binary.to_nat(@exact.magnitude(value)),
```

`src/orderedsturm/count.mbt:208–210`

```moonbit
  difference(proof.lower, proof.upper).equal(
    @exact.positive(@binary.from_nat(count)),
  )
```

**呼出元**

`src/orderedsturm/isolation.mbt:346–348`

```moonbit
      count_between(system, { lower: interval.lower, upper: middle, }),
      count_between(system, { lower: middle, upper: interval.upper, }),
    ) {
```

`src/relativecad/signs.mbt:30–36`

```moonbit
        RationalPoint(value) => scalar_at(atom.polynomial, value)
        AlgebraicPoint(interval) =>
          match @ordered.count_between(system, interval) {
            Err(error) => Err(OrderedFailure(error))
            Ok(proof) =>
              match proof.count {
                Zero => scalar_at(atom.polynomial, midpoint(interval))
```

**実使用の根拠**: 区間二分の根分離と relativecad の原子符号判定から呼ばれる非テスト経路。実行頻度は未計測。

**意味論・余分か否か**: variations は既に Nat。差を符号付き Integer にして負値を拒否し、直後に Nat に戻す。根数だけの経路でこの往復は必須でない。ただし負差の InternalInvariant は意味上必要。

**推奨する次の確認**: Nat を compare し、lower>=upper の場合だけ core.subtract する専用根数関数を検討。core.subtract 単独は負差を clamp して検査を失うので不可。check_count の system/interval/endpoints 検証と差の検査も保持。

**静的複雑度・限界**: a,b は単項 Nat。現状は from_nat(a),from_nat(b) の単項走査と最終差の単項再構築を追加する。Nat compare/subtract も O(a+b) のため漸近改善とは断言せず、Binary/Integer 中間値と追加走査を省く候補。


## N02 realtower の根数にも Nat→Binary→Integer→Nat

分類 `avoidable_production` / 優先 `high` / 確度 `high` / source `09f615b8374817d04817eb5b45e776dbee2bfa8a`。未計測。

**主箇所**

`src/realtower/raw.mbt:585–594`

```moonbit
  both(
    rp_variations(field, sequence, interval.lower),
    rp_variations(field, sequence, interval.upper),
    fn(a, b) {
      Ok(
        @exact.subtract(
          @exact.positive(@binary.from_nat(a)),
          @exact.positive(@binary.from_nat(b)),
        ),
      )
```

**関連根拠**

`src/realtower/system.mbt:72–82`

```moonbit
    next(rp_difference(value.polynomial.field, value.sequence, interval), fn(
      n,
    ) {
      if @exact.negative(n) {
        Err(InternalInvariant)
      } else {
        Ok({
          system: value.certificate,
          interval,
          count: @binary.to_nat(@exact.magnitude(n)),
        })
```

`src/realtower/raw.mbt:600–613`

```moonbit
/// Sturm-Tarski: sum sign(query(r)) over distinct roots in (lower, upper].
fn rp_query(
  field : Field,
  polynomial : @core.Chain[Representation],
  query : @core.Chain[Representation],
  interval : @sturm.Interval,
) -> Result[@exact.Integer, TowerError] {
  next(rp_monic(field, polynomial), fn(monic) {
    next(rp_derivative(field, monic), fn(d) {
      next(rp_multiply(field, d, query), fn(product) {
        next(rp_remainder(field, product, monic), fn(seed) {
          next(rp_sequence(field, monic, seed), fn(sequence) {
            rp_difference(field, sequence, interval)
          })
```

**呼出元**

`src/realtower/isolation.mbt:134–142`

```moonbit
fn split(
  value : System,
  interval : @sturm.Interval,
) -> Result[(CountCertificate, CountCertificate), TowerError] {
  let middle = midpoint(interval)
  both(
    count_between(value, { lower: interval.lower, upper: middle, }),
    count_between(value, { lower: middle, upper: interval.upper, }),
    fn(a, b) { Ok((a, b)) },
```

`src/realtower/system.mbt:106–113`

```moonbit
pub fn root_in_interval(
  value : System,
  interval : @sturm.Interval,
) -> Result[Root, TowerError] {
  next(count_between(value, interval), fn(count) {
    if count.count.equal(Succ(Zero)) {
      Ok({ system: value, certificate: { system: value.certificate, count, }, })
    } else {
```

**実使用の根拠**: realtower の根分離・区間内一根判定が count_between を使う。rp_difference は signed Sturm–Tarski query にも共有される。

**意味論・余分か否か**: count_between は負差を拒否して Nat に戻す。一方 rp_query の結果は負もあり得る符号付き和なので、共有 rp_difference 全体の Nat 化は誤り。

**推奨する次の確認**: 根数用の Nat compare/subtract を分離する案。負差・endpoint 評価エラー・区間条件を保持。rp_query の Integer 経路は残す。

**静的複雑度・限界**: 変動数の二進変換と Nat 差の再構築を省ける候補。変動数算出・符号判定は依然必要。速度・頻度は未測定。


## N03 realtower が有理数埋込みと単位元判定で再帰的な 1 を重複構築

分類 `avoidable_production` / 優先 `high` / 確度 `high` / source `09f615b8374817d04817eb5b45e776dbee2bfa8a`。未計測。

**主箇所**

`src/realtower/api.mbt:12–21`

```moonbit
fn raw_rational(field : Field, q : @exact.Rational) -> Representation {
  match field.context {
    Rationals => Base(q)
    Extension(parent, _, _) =>
      Fraction(
        Cons(raw_rational(parent, q), Nil),
        Cons(raw_rational(parent, @exact.rational_one()), Nil),
      )
  }
}
```

**関連根拠**

`src/realtower/raw.mbt:25–31`

```moonbit
fn raw_one(field : Field) -> Representation {
  raw_rational(field, @exact.rational_one())
}

///|
fn raw_zero(field : Field) -> Representation {
  raw_rational(field, @exact.rational_zero())
```

`src/realtower/raw.mbt:411–423`

```moonbit
fn raw_multiply(
  field : Field,
  a : Representation,
  b : Representation,
) -> Result[Representation, TowerError] {
  if a.equal(raw_one(field)) {
    Ok(b)
  } else if b.equal(raw_one(field)) {
    Ok(a)
  } else {
    match (field.context, a, b) {
      (Rationals, Base(a), Base(b)) => Ok(Base(@exact.rational_multiply(a, b)))
      (Extension(parent, _, _), Fraction(an, ad), Fraction(bn, bd)) =>
```

`src/realtower/raw.mbt:436–442`

```moonbit
fn raw_inverse(
  field : Field,
  value : Representation,
) -> Result[Representation, TowerError] {
  if value.equal(raw_one(field)) {
    Ok(value)
  } else {
```

`src/realtower/data.mbt:22–25`

```moonbit
pub enum Representation {
  Base(@exact.Rational)
  Fraction(@core.Chain[Representation], @core.Chain[Representation])
}
```

`src/realtower/data.mbt:34–44`

```moonbit
#derive(Eq, Debug)
enum Context {
  Rationals
  Extension(Field, @core.Chain[Representation], @sturm.Interval)
}

///|
#derive(Eq, Debug)
pub struct Field {
  context : Context
}
```

**呼出元**

`src/realtower/scalar.mbt:43–52`

```moonbit
pub fn scalar_multiply(
  left : Scalar,
  right : Scalar,
) -> Result[Scalar, TowerError] {
  if !same_field(left.field, right.field) {
    Err(DifferentField)
  } else {
    next(raw_multiply(left.field, left.value, right.value), fn(value) {
      Ok({ field: left.field, value, })
    })
```

`src/realtower/raw.mbt:125–130`

```moonbit
    match values {
      Nil => Ok(Nil)
      Cons(c, cs) =>
        both(raw_multiply(field, c, scalar), walk(cs), fn(v, vs) {
          Ok(Cons(v, vs))
        })
```

`src/realtower/polynomial.mbt:114–119`

```moonbit
pub fn evaluate_rational(
  value : Polynomial,
  point : @exact.Rational,
) -> Result[Scalar, TowerError] {
  evaluate(value, rational(value.field, point))
}
```

**実使用の根拠**: 公開 scalar_multiply、多項式スカラー倍、有理点評価から到達する。raw_one は raw_rational(field,1) を毎回呼ぶ。

**意味論・余分か否か**: Extension ごとに q と 1 を親へそれぞれ再帰埋込みする。q=1 では同一部分木を左右別々に構築し、一般 q も各段で 1 の木を再構築する。a が1でない raw_multiply は raw_one(field) を二度呼ぶ。塔表現への埋込みは必要だが同じ immutable な 1 の再構築は不要。

**推奨する次の確認**: 将来候補は raw_rational_pair により (q_rep,one_rep) を各段一回作り共有、または文脈に束縛した定数の保持。まず raw_multiply 内で同一 one を共有する等を独立比較する。Fraction の深さ・field/context/選択根を保ち Base に短絡しない。今回は実装しない。

**静的複雑度・限界**: 塔高さ h に対する source 呼出数は T(h)=2T(h-1)+O(1)。source 呼出木の評価であり、生成コードの CSE・割当て・速度は未確認。構築を共有しても Representation.equal が両枝を再帰走査するコストは残り得る。全体の O(h) 化や実測高速化とは主張しない。


## N04 modular.signed_reduce が既約剰余を subtract 経由で再 reduce

分類 `avoidable_production` / 優先 `high` / 確度 `high` / source `09f615b8374817d04817eb5b45e776dbee2bfa8a`。未計測。

**主箇所**

`src/modular/modular.mbt:120–126`

```moonbit
pub fn signed_reduce(m : Modulus, a : @exact.Integer) -> @binary.Binary {
  let remainder = reduce(m, @exact.magnitude(a))
  match @exact.negative(a) {
    false => remainder
    true => subtract(m, @binary.zero(), remainder)
  }
}
```

**関連根拠**

`src/modular/modular.mbt:45–59`

```moonbit
pub fn subtract(
  m : Modulus,
  a : @binary.Binary,
  b : @binary.Binary,
) -> @binary.Binary {
  let x = reduce(m, a)
  let y = reduce(m, b)
  match @binary.subtract(x, y) {
    Some(difference) => difference
    None =>
      match @binary.subtract(@binary.add(x, m.value), y) {
        Some(difference) => difference
        None => @binary.zero()
      }
  }
```

`src/modular/modular.mbt:28–33`

```moonbit
pub fn reduce(m : Modulus, a : @binary.Binary) -> @binary.Binary {
  match @binary.remainder(a, m.value) {
    Some(remainder) => remainder
    None => @binary.zero()
  }
}
```

`src/binary/division.mbt:118–136`

```moonbit
pub fn remainder(a : Binary, b : Binary) -> Binary? {
  match (a.bits, b.bits) {
    (_, Nil) => None
    (Nil, _) | (_, Cons(true, Nil)) => Some(zero())
    (_, Cons(false, Cons(true, Nil))) =>
      Some(
        match odd(a) {
          true => one()
          false => zero()
        },
      )
    _ =>
      match equal_prefix(a.bits, b.bits) {
        false => Some(remainder_adaptively(a, b))
        true =>
          match compare(a, b) {
            Less => Some(a)
            Equal => Some(zero())
            Greater => Some(remainder_adaptively(a, b))
```

**呼出元**

`src/modular/modular.mbt:111–117`

```moonbit
pub fn inverse(m : Modulus, a : @binary.Binary) -> @binary.Binary? {
  let (g, x, _) = extended_gcd(a, m.value)
  match @binary.compare(g, @binary.one()) {
    Equal => Some(signed_reduce(m, x))
    _ => None
  }
}
```

`src/modular/crt.mbt:50–56`

```moonbit
            false => magnitude
          }
          let coefficient = @exact.multiply(delta, x)
          let k = match modulus(reduced_period) {
            Some(modulus) => signed_reduce(modulus, coefficient)
            None => @binary.zero()
          }
```

`src/zassenhaus/polynomial.mbt:377–382`

```moonbit
  let modulus = @primefield.modulus(field)
  @fppoly.polynomial(
    field,
    @core.map(value.coefficients, fn(c) { @modular.signed_reduce(modulus, c) }),
  )
}
```

**実使用の根拠**: 逆元・CRT・Zassenhaus の整数係数から有限体への変換に使われる。負の係数で該当経路へ入る。

**意味論・余分か否か**: remainder は既に 0<=r<m。負号処理の subtract(m,0,r) の内部で 0 と r を再 reduce する。負の剰余を正規代表へ移す処理は必要だが、剰余をもう一度求める必要はない。

**推奨する次の確認**: r==0 なら0、それ以外は modulus-r を返す private な正規剰余専用処理を検討。法>1、負の零、r==0 を保つ。公開 subtract の任意入力正規化は削らない。

**静的複雑度・限界**: 余分な remainder 呼出し二回を減らす候補。ただし Binary.remainder は零/単位元/大小比較で早期終了するため、毎回長除算二回分の節約という説明は不正確。未測定。


## N05 numberfield.field が検証済み monic を再 monic 化

分類 `avoidable_production` / 優先 `high` / 確度 `high` / source `09f615b8374817d04817eb5b45e776dbee2bfa8a`。未計測。

**主箇所**

`src/numberfield/field.mbt:72–84`

```moonbit
  match @minimal.check(proof, verification_fuel) {
    @zass.Refuted => Err(InvalidCertificate)
    @zass.Undecided => Err(VerificationBudget)
    @zass.Proven =>
      match @poly.terms(proof.result.polynomial) {
        Cons({ exponents: Cons(d, Nil), .. }, _) =>
          match d {
            Zero => Err(InvalidCertificate)
            Succ(_) =>
              Ok({
                proof,
                degree: d,
                reduction: @poly.negate(@poly.monic(proof.result.polynomial)),
```

**関連根拠**

`src/realminimal/certificate.mbt:90–97`

```moonbit
        ) {
        @zass.Proven =>
          if selection_valid(proof) {
            @zass.Proven
          } else {
            @zass.Refuted
          }
        other => other
```

`src/realminimal/certificate.mbt:57–66`

```moonbit
  match @core.nth(proof.factorization.factors, proof.selected) {
    None => false
    Some(factor) =>
      match integer_polynomial(factor.polynomial) {
        None => false
        Some(polynomial) =>
          proof.result.polynomial.equal(polynomial) &&
          proof.result.interval.equal(proof.input.interval) &&
          @real.check_root(proof.result) &&
          check_factors(proof.factorization.factors, Zero)
```

`src/realminimal/polynomial.mbt:55–57`

```moonbit
  match @poly.polynomial(Succ(Zero), terms(@zass.coefficients(value), Zero)) {
    Ok(p) => Some(@poly.monic(p))
    Err(_) => None
```

`src/polynomial/polynomial.mbt:467–483`

```moonbit
pub fn monic(p : Polynomial) -> Polynomial {
  match p.terms {
    Nil => p
    Cons(leading, _) =>
      match @exact.nonzero(leading.coefficient) {
        None => p
        Some(coefficient) => {
          let factor = @exact.reciprocal(coefficient)
          {
            variables: p.variables,
            terms: @core.map(p.terms, fn(term) {
              {
                coefficient: @exact.rational_multiply(factor, term.coefficient),
                exponents: term.exponents,
              }
            }),
          }
```

**呼出元**

`src/compositum/producer.mbt:129–134`

```moonbit
  let field = match @nf.field_result(parameter, minimal, budget.verification) {
    Ok(field) => field
    Err(@nf.VerificationBudget) =>
      return Ok(Unresolved(MinimalBudget(@minimal.VerificationBudget)))
    Err(error) => return Err(FieldFailure(error))
  }
```

`src/cad2/lift.mbt:196–200`

```moonbit
        Ok(Unresolved(reason)) => Ok(Insufficient(reason))
        Ok(Normalized(value, proof)) =>
          match @nf.field_result(value, proof, budget.verification) {
            Ok(field) => Ok(Ready(field, proof))
            Err(error) => Err(FieldFailure(error))
```

`src/complexcompositum/producer.mbt:47–52`

```moonbit
        Ok(@minimal.Normalized(_, proof)) => proof
      }
      let field = match @nf.field(proof, budget.verification) {
        Ok(field) => field
        Err(@nf.VerificationBudget) =>
          return Ok(Paused(build, VerificationBudget))
```

**実使用の根拠**: 数体構築は合成体生成と CAD 持上げから使用される。公開 field(proof,fuel) も checker を通す。

**意味論・余分か否か**: minimal.check が Proven の場合、integer_polynomial が作った monic 多項式と proof.result.polynomial の完全一致を確認済み。その後の poly.monic は同じ値の再正規化。poly.monic は係数1でも terms を map する。

**推奨する次の確認**: Proven 分岐で proof.result.polynomial をそのまま negate へ渡す案を検証。checker、Refuted/Undecided と fuel、正次数、embedding/root interval の束縛は保持する。

**静的複雑度・限界**: t 項に対する monic の map と係数処理一巡を Field setup から省く候補。反復 multiply ごとのコストではない。setup/one-shot を含め測る必要がある。


## N06 resultant_start が両入力をそれぞれ二度 monic 化

分類 `avoidable_production` / 優先 `high` / 確度 `high` / source `09f615b8374817d04817eb5b45e776dbee2bfa8a`。未計測。

**主箇所**

`src/realalgebraic/resultant.mbt:211–217`

```moonbit
  match (positive_dense(left), positive_dense(right)) {
    (Some((m, left_dense)), Some((n, right_dense))) =>
      Ok({
        left: @poly.monic(left),
        right: @poly.monic(right),
        left_dense,
        right_dense,
```

**関連根拠**

`src/realalgebraic/polynomial.mbt:142–151`

```moonbit
fn positive_dense(
  value : @poly.Polynomial,
) -> (@core.Nat, @core.Chain[@exact.Rational])? {
  match dense(@poly.monic(value)) {
    Some(values) =>
      match dense_degree(values) {
        Some(Succ(_) as n) => Some((n, values))
        _ => None
      }
    None => None
```

`src/polynomial/polynomial.mbt:467–483`

```moonbit
pub fn monic(p : Polynomial) -> Polynomial {
  match p.terms {
    Nil => p
    Cons(leading, _) =>
      match @exact.nonzero(leading.coefficient) {
        None => p
        Some(coefficient) => {
          let factor = @exact.reciprocal(coefficient)
          {
            variables: p.variables,
            terms: @core.map(p.terms, fn(term) {
              {
                coefficient: @exact.rational_multiply(factor, term.coefficient),
                exponents: term.exponents,
              }
            }),
          }
```

**呼出元**

`src/realalgebraic/arithmetic.mbt:142–149`

```moonbit
  left : Number,
  right : Number,
  operation : BinaryOperation,
) -> Result[Arithmetic, AlgebraError] {
  match resultant_start(definition(left), definition(right), operation) {
    Err(error) => Err(error)
    Ok(state) =>
      Ok({
```

**実使用の根拠**: 実代数的数 arithmetic_start が定義多項式を resultant_start に渡す。resultant_start 自体も公開 API。

**意味論・余分か否か**: positive_dense 内部で dense(poly.monic(value)) を計算し、その直後に Resultant.left/right 用に同じ入力の poly.monic を再計算する。公開任意入力の正規化は一度必要だが二重計算は不要。

**推奨する次の確認**: 各入力を一度 monic 化し、その同一値から dense と状態を作る案。零/定数/次元の失敗条件を保持。公開 check_resultant の未信頼入力の再計算は独立に保つ。

**静的複雑度・限界**: 入力 t_l+t_r 項に対する重複正規化を各一巡削る候補。dense 化、Sylvester 行列、行列式コストは残る。未測定。


## N07 resultant 補間点を Nat から毎回作り直す

分類 `loop_conversion_candidate` / 優先 `medium` / 確度 `medium` / source `09f615b8374817d04817eb5b45e776dbee2bfa8a`。未計測。

**主箇所**

`src/realalgebraic/resultant.mbt:252–256`

```moonbit
    Succ(remaining) =>
      match fuel {
        Zero => Ok(ResultantPaused(state))
        Succ(rest) => {
          let point = rnat(state.point)
```

**関連根拠**

`src/realalgebraic/polynomial.mbt:156–158`

```moonbit
fn rnat(value : @core.Nat) -> @exact.Rational {
  @exact.whole(@exact.positive(@binary.from_nat(value)))
}
```

`src/realalgebraic/resultant.mbt:287–295`

```moonbit
                    ),
                  )
                  resultant_advance(
                    {
                      ..state,
                      remaining,
                      point: Succ(state.point),
                      coefficients,
                      basis,
```

`src/realalgebraic/resultant.mbt:138–151`

```moonbit
      fn samples(
        values : @core.Chain[@exact.Rational],
        remaining : @core.Nat,
        point : @core.Nat,
      ) -> Bool {
        match (values, remaining) {
          (Nil, Zero) => true
          (Cons(head, tail), Succ(rest)) => {
            let x = rnat(point)
            match sylvester(left, right, m, n, x, proof.operation) {
              Some(expected) =>
                expected.equal(head) &&
                dense_evaluate(claimed, x).equal(head) &&
                samples(tail, rest, Succ(point))
```

**呼出元**

`src/realalgebraic/arithmetic.mbt:165–171`

```moonbit
  fuel : @core.Nat,
) -> Result[ArithmeticProgress, AlgebraError] {
  match state.phase {
    Computing(job) =>
      match resultant_advance(job, Zero) {
        Err(error) => Err(error)
        Ok(ResultantReady(proof)) =>
```

**実使用の根拠**: resultant の各サンプルと公開 check_resultant の点列再計算で rnat(point) が呼ばれる。

**意味論・余分か否か**: Nat point は回数管理、Rational point は行列評価に必要。一回の型変換は意味があるが、0,1,... の各値を毎回 unary 先頭から二進変換する必要性は別。単純な恒等往復ではない。

**推奨する次の確認**: producer 状態に Rational point を carry して increment する案を追加状態コスト込みで比較する候補。checker の独立な点列生成を維持し、証明内の点を無検証で信じない。

**静的複雑度・限界**: N=m*n+1 点で from_nat の単項走査は合計 0+1+...+(N-1)=Theta(N^2)。逐次 Rational 加算にも二進算術/割当てがあり必ず勝つとは限らない。行列式の支配コスト・実頻度は未測定。


## N08 realalgebraic sparse→dense が各単項式を零埋めして加算

分類 `representation_candidate` / 優先 `medium` / 確度 `high` / source `09f615b8374817d04817eb5b45e776dbee2bfa8a`。未計測。

**主箇所**

`src/realalgebraic/polynomial.mbt:91–102`

```moonbit
      Cons(term, rest) =>
        match (term.exponents, walk(rest)) {
          (Cons(n, Nil), Some(tail)) =>
            Some(
              dense_add(
                @core.replicate_onto(
                  n,
                  @exact.rational_zero(),
                  Cons(term.coefficient, Nil),
                ),
                tail,
              ),
```

**関連根拠**

`src/realalgebraic/polynomial.mbt:22–33`

```moonbit
fn trim(values : @core.Chain[@exact.Rational]) -> @core.Chain[@exact.Rational] {
  match values {
    Nil => Nil
    Cons(head, rest) => {
      let tail = trim(rest)
      match tail {
        Nil => if qzero(head) { Nil } else { Cons(head, Nil) }
        _ => Cons(head, tail)
      }
    }
  }
}
```

`src/realalgebraic/polynomial.mbt:36–44`

```moonbit
fn dense_add(
  a : @core.Chain[@exact.Rational],
  b : @core.Chain[@exact.Rational],
) -> @core.Chain[@exact.Rational] {
  match (a, b) {
    (Nil, _) => b
    (_, Nil) => a
    (Cons(x, xs), Cons(y, ys)) =>
      trim(Cons(@exact.rational_add(x, y), dense_add(xs, ys)))
```

`src/realalgebraic/polynomial.mbt:142–149`

```moonbit
fn positive_dense(
  value : @poly.Polynomial,
) -> (@core.Nat, @core.Chain[@exact.Rational])? {
  match dense(@poly.monic(value)) {
    Some(values) =>
      match dense_degree(values) {
        Some(Succ(_) as n) => Some((n, values))
        _ => None
```

**呼出元**

`src/realalgebraic/resultant.mbt:211–217`

```moonbit
  match (positive_dense(left), positive_dense(right)) {
    (Some((m, left_dense)), Some((n, right_dense))) =>
      Ok({
        left: @poly.monic(left),
        right: @poly.monic(right),
        left_dense,
        right_dense,
```

`src/realalgebraic/resultant.mbt:130–135`

```moonbit
  match
    (
      positive_dense(proof.left),
      positive_dense(proof.right),
      dense(proof.polynomial),
    ) {
```

**実使用の根拠**: resultant の実行と検証が dense 係数列を使用。

**意味論・余分か否か**: dense 境界自体は必要。現状は指数 n ごとに n 個の零を置いた一時列を作って dense_add し、再帰の各段で trim する。sorted unique terms を使えば一度の走査で dense 列を組める可能性がある。

**推奨する次の確認**: 単変数・次数・零・順序を保った一巡 dense view を検討。変数数検査、末尾零除去と係数一致を保持。checker も共有依存を使うため独立 Fraction oracle が必要。

**静的複雑度・限界**: 出力 D+1 要素は必要。一時零埋めは sum(e_i+1) セル。dense_add は再帰の各段で trim が残列を走査し、最悪 O(t*D^2) の列走査があり得る（算術・単項比較別）。時間・割当て・ピーク RAM は未測定。


## N09 realminimal dense 係数抽出が次数ごとに sparse terms を再走査

分類 `representation_candidate` / 優先 `medium` / 確度 `high` / source `09f615b8374817d04817eb5b45e776dbee2bfa8a`。未計測。

**主箇所**

`src/realminimal/polynomial.mbt:29–33`

```moonbit
        Cons(degree, Nil) =>
          Some(
            @core.map(@core.indices(Succ(degree)), fn(index) {
              coefficient(@poly.terms(value), index)
            }),
```

**関連根拠**

`src/realminimal/polynomial.mbt:7–23`

```moonbit
  fn coefficient(
    terms : @core.Chain[@poly.Term],
    index : @core.Nat,
  ) -> @exact.Rational {
    match terms {
      Nil => @exact.rational_zero()
      Cons(term, rest) =>
        match term.exponents {
          Cons(exponent, Nil) =>
            if @core.compare(exponent, index).equal(Equal) {
              term.coefficient
            } else {
              coefficient(rest, index)
            }
          _ => @exact.rational_zero()
        }
    }
```

**呼出元**

`src/realminimal/realminimal.mbt:95–102`

```moonbit
  if !@real.check_root(input) {
    return Err(InvalidInput)
  }
  match coefficients(input.polynomial) {
    None => Err(InvalidInput)
    Some(values) =>
      match @zass.factor_rational(values, primes, lift_fuel, subset_fuel) {
        Err(error) => Err(FactorizationFailure(error))
```

`src/realminimal/certificate.mbt:80–86`

```moonbit
    return @zass.Refuted
  }
  match coefficients(proof.input.polynomial) {
    None => @zass.Refuted
    Some(values) =>
      match
        @zass.check_rational_factorization(
```

**実使用の根拠**: normalize_root の有理因数分解入力と、公開 minimal 証明 checker の入力再構築から使用。

**意味論・余分か否か**: 因数分解 API の dense 列は必要だが各 index で terms の先頭から探すことは不要。指数を primitive Int に落とす必要もない。

**推奨する次の確認**: sorted unique univariate terms を一度進める cursor と零埋めを検討。非単変数 None、零、欠けた次数、public polynomial constructor の正規化を確認する。

**静的複雑度・限界**: D+1 係数に最大 t 項を調べ O((D+1)*t) 項訪問。Nat 比較にも指数長のコストがある。新案の O(D+t) は項/出力訪問の目標で、Nat 比較まで定数時間とはしない。


## N10 NF/CF Horner 評価に legacy な係数全走査が残る

分類 `representation_candidate` / 優先 `medium` / 確度 `high` / source `09f615b8374817d04817eb5b45e776dbee2bfa8a`。未計測。

**主箇所**

`src/numberfield/minimal.mbt:33–48`

```moonbit
  fn go(todo : @core.Chain[@core.Nat], accumulated : Element) -> Element? {
    match todo {
      Nil => Some(accumulated)
      Cons(i, rest) =>
        match multiply(accumulated, value) {
          Err(_) => None
          Ok(product) =>
            match
              add(product, rational(value.field, coefficient(polynomial, i))) {
              Ok(next) => go(rest, next)
              Err(_) => None
            }
        }
    }
  }
  go(@core.reverse(@core.indices(count)), zero(value.field))
```

**関連根拠**

`src/numberfield/linear.mbt:2–16`

```moonbit
fn coefficient(
  polynomial : @poly.Polynomial,
  exponent : @core.Nat,
) -> @exact.Rational {
  @core.fold_left(@poly.terms(polynomial), @exact.rational_zero(), fn(
    sum,
    term,
  ) {
    if term.exponents.equal(Cons(exponent, Nil)) {
      @exact.rational_add(sum, term.coefficient)
    } else {
      sum
    }
  })
}
```

`src/complexfield/coordinates.mbt:2–16`

```moonbit
fn coefficient(
  polynomial : @poly.Polynomial,
  exponent : @core.Nat,
) -> @exact.Rational {
  @core.fold_left(@poly.terms(polynomial), @exact.rational_zero(), fn(
    sum,
    term,
  ) {
    if term.exponents.equal(Cons(exponent, Nil)) {
      @exact.rational_add(sum, term.coefficient)
    } else {
      sum
    }
  })
}
```

`src/complexfield/coordinates.mbt:86–101`

```moonbit
  fn go(todo : @core.Chain[@core.Nat], accumulated : Element) -> Element? {
    match todo {
      Nil => Some(accumulated)
      Cons(i, rest) =>
        match multiply(accumulated, value) {
          Err(_) => None
          Ok(product) =>
            match
              add(product, rational(value.field, coefficient(polynomial, i))) {
              Ok(next) => go(rest, next)
              Err(_) => None
            }
        }
    }
  }
  go(@core.reverse(@core.indices(count)), zero(value.field))
```

`src/complexfield/coordinates.mbt:19–21`

```moonbit
/// Exact QQ coordinates in [1,alpha,...,i,i*alpha,...].
pub fn coordinates(value : Element) -> @core.Chain[@exact.Rational] {
  @core.append(@nf.coordinates(value.real), @nf.coordinates(value.imaginary))
```

**呼出元**

`src/numberfield/minimal.mbt:62–70`

```moonbit
  let k = match polynomial_degree(polynomial) {
    Some(Succ(_) as d) => d
    _ => return false
  }
  if @core.compare(k, degree(value.field)).equal(Greater) {
    return false
  }
  match evaluate_polynomial(value, polynomial) {
    Some(result) => if !is_zero(result) { return false }
```

`src/complexfield/minimal.mbt:28–34`

```moonbit
  if @core.compare(k, degree(value.field)).equal(Greater) {
    return false
  }
  match evaluate_polynomial(value, polynomial) {
    Some(result) => if !is_zero(result) { return false }
    None => return false
  }
```

**実使用の根拠**: 公開 evaluate_polynomial と minimal-polynomial checker の実使用。NF multiplication_matrix と CF coordinates は既に一巡抽出を使うので未修正と扱わない。

**意味論・余分か否か**: Horner の各次数 i に対して coefficient(polynomial,i) が全 terms を fold する。入力 polynomial は field degree 未満とは限らず、nf.coordinates(Element) の無条件流用は不可。有理係数の field 埋込み自体は必要。

**推奨する次の確認**: 任意単変数 polynomial 用の一巡係数 cursor/view を検討。field/context と次元検査・エラーを保持。checker と producer の共有依存を独立係数 oracle で検査する必要がある。

**静的複雑度・限界**: 現在は D+1 回の t 項 fold と exponent-vector equality（Nat 比較コスト別）。Horner の数体乗算は必要なままで係数抽出のみ軽減候補。未測定。


## N11 modular.power が未正規化 base を立ちビットごとに再使用

分類 `conditional_reduction_candidate` / 優先 `low` / 確度 `medium` / source `09f615b8374817d04817eb5b45e776dbee2bfa8a`。未計測。

**主箇所**

`src/modular/modular.mbt:78–91`

```moonbit
  fn go(bits : @core.Chain[Bool]) -> @binary.Binary {
    match bits {
      Nil => @binary.one()
      Cons(bit, rest) => {
        let half = go(rest)
        let square = multiply(m, half, half)
        match bit {
          false => square
          true => multiply(m, base, square)
        }
      }
    }
  }
  go(@binary.bits(exponent))
```

**関連根拠**

`src/modular/modular.mbt:63–69`

```moonbit
pub fn multiply(
  m : Modulus,
  a : @binary.Binary,
  b : @binary.Binary,
) -> @binary.Binary {
  reduce(m, @binary.multiply(a, b))
}
```

`src/ntt/ntt.mbt:30–35`

```moonbit
    ) {
    (true, true) => {
      let n = @binary.from_nat(size)
      let root = @modular.reduce(modulus, root)
      let complete = @modular.power(modulus, root, n)
      let primitive = match @binary.compare(n, @binary.one()) {
```

**呼出元**

`src/finitefield/sqrt.mbt:42–48`

```moonbit
            match @binary.compare(candidate, p) {
              Less =>
                match
                  @binary.compare(
                    @modular.power(modulus, candidate, exponent),
                    previous,
                  ) {
```

`src/finitefield/sqrt.mbt:167–174`

```moonbit
      let c = @modular.power(modulus, field.nonresidue, field.odd_part)
      let t = @modular.power(modulus, value, field.odd_part)
      let x = @modular.power(
        modulus,
        value,
        @binary.half(@binary.successor(field.odd_part)),
      )
      match correct(c, x, t, field.two_power) {
```

**実使用の根拠**: NTT plan と有限体平方根などが公開 power を使用。呼出元の base<m 保証割合は未計測。

**意味論・余分か否か**: true bit ごとに raw base と square を乗算して reduce。巨大な base なら同じ巨大整数を繰り返し乗算する。これは同一 remainder の直接再実行ではなく、正規 base 再利用候補。

**推奨する次の確認**: 非零指数で base を一度 reduce する案を、指数0/1・tiny・既約 base の回帰を含め比較。積ごとの reduce は削らない。既約 base が主なら準備コストで不採用もあり得る。

**静的複雑度・限界**: popcount 回の乗算で raw base bit 長が効く。事前剰余一回の追加で operand を法程度へ制限できる可能性。e=0/1 や既約 base では不利になり得る。未測定。


## N12 complexalgebraic rational fast path が保証済み linear=1 で除算

分類 `avoidable_production` / 優先 `low` / 確度 `high` / source `09f615b8374817d04817eb5b45e776dbee2bfa8a`。未計測。

**主箇所**

`src/complexalgebraic/step.mbt:57–65`

```moonbit
  match
    coefficients(
      @poly.terms(@realalgebraic.definition(value)),
      @exact.rational_zero(),
      @exact.rational_zero(),
    ) {
    Some((constant, linear)) =>
      @exact.rational_divide(@exact.rational_negate(constant), linear)
    None => None
```

**関連根拠**

`src/realalgebraic/number.mbt:27–34`

```moonbit
pub fn number(data : RootCertificate) -> Result[Number, AlgebraError] {
  match @sturm.system(data.polynomial) {
    Err(_) => Err(InvalidDefinition)
    Ok(system) =>
      match
        @sturm.count_between(system, data.interval.lower, data.interval.upper) {
        Some(Succ(Zero)) => Ok({ system, interval: data.interval, })
        _ => Err(InvalidInterval)
```

`src/realalgebraic/number.mbt:55–57`

```moonbit
pub fn definition(value : Number) -> @poly.Polynomial {
  @sturm.squarefree(value.system)
}
```

`src/sturm/sturm.mbt:63–68`

```moonbit
                  match @polynomial.is_zero(remainder) {
                    false => Err(PolynomialFailure)
                    true => {
                      let squarefree = @polynomial.monic(quotient)
                      match @polynomial.derivative(squarefree, Zero) {
                        None => Err(PolynomialFailure)
```

`src/exact/exact.mbt:462–466`

```moonbit
pub fn rational_divide(a : Rational, b : Rational) -> Rational? {
  match nonzero(b) {
    None => None
    Some(value) => Some(rational_multiply(a, reciprocal(value)))
  }
```

`src/exact/exact.mbt:510–519`

```moonbit
pub fn reciprocal(nonzero : Nonzero) -> Rational {
  let r = nonzero.value
  let n = positive(r.denominator)
  {
    numerator: match r.numerator.negative {
      true => negate(n)
      false => n
    },
    denominator: r.numerator.magnitude,
  }
```

**呼出元**

`src/complexalgebraic/step.mbt:70–81`

```moonbit
fn rational_evaluate(
  instruction : Instruction,
  a : @realalgebraic.Number,
  b : @realalgebraic.Number,
) -> Result[@exact.Rational?, @realalgebraic.AlgebraError] {
  match (as_rational(a), as_rational(b)) {
    (Some(a), Some(b)) =>
      match instruction {
        Sum(_, _) => Ok(Some(@exact.rational_add(a, b)))
        Product(_, _) => Ok(Some(@exact.rational_multiply(a, b)))
        Negative(_) => Ok(Some(@exact.rational_negate(a)))
        Quotient(_, _) =>
```

`src/complexalgebraic/arithmetic.mbt:193–202`

```moonbit
              match
                instruction_inputs(
                  instruction,
                  state.left,
                  state.right,
                  state.values,
                ) {
                Some((a, b)) =>
                  match start_step(instruction, a, b) {
                    Ok(job) =>
```

**実使用の根拠**: complexalgebraic arithmetic 各 step の有理数判定で使用し、RationalStep checker も再抽出する。

**意味論・余分か否か**: as_rational が読むのは任意外部 polynomial でなく checked Number.definition。System.squarefree は monic なので次数1なら linear=1。rational_divide(-constant,linear) の nonzero/reciprocal 経由はこの不変条件の下で不要。高次は None、有効 Number は定数定義にならない。

**推奨する次の確認**: private helper の次数1抽出で -constant を直接返す案。monic を保証する Number/System constructor と opaque 境界を確認し、一般 public rational_divide は変更しない。

**静的複雑度・限界**: 単位元除算の wrapper/reciprocal 構築という小さな定数因子候補。rational_multiply に unit fast path があるため大きな算術節約とは言えない。未測定。


## N13 Nat→Binary→Integer→Rational の一方向埋込みは必要

分類 `semantically_required` / 優先 `exclude` / 確度 `high` / source `09f615b8374817d04817eb5b45e776dbee2bfa8a`。未計測。

**主箇所**

`src/realalgebraic/polynomial.mbt:156–158`

```moonbit
fn rnat(value : @core.Nat) -> @exact.Rational {
  @exact.whole(@exact.positive(@binary.from_nat(value)))
}
```

**関連根拠**

`src/realtower/data.mbt:22–25`

```moonbit
pub enum Representation {
  Base(@exact.Rational)
  Fraction(@core.Chain[Representation], @core.Chain[Representation])
}
```

`src/realtower/api.mbt:12–21`

```moonbit
fn raw_rational(field : Field, q : @exact.Rational) -> Representation {
  match field.context {
    Rationals => Base(q)
    Extension(parent, _, _) =>
      Fraction(
        Cons(raw_rational(parent, q), Nil),
        Cons(raw_rational(parent, @exact.rational_one()), Nil),
      )
  }
}
```

**呼出元**

`src/realalgebraic/resultant.mbt:252–256`

```moonbit
    Succ(remaining) =>
      match fuel {
        Zero => Ok(ResultantPaused(state))
        Succ(rest) => {
          let point = rnat(state.point)
```

`src/realtower/polynomial.mbt:114–119`

```moonbit
pub fn evaluate_rational(
  value : Polynomial,
  point : @exact.Rational,
) -> Result[Scalar, TowerError] {
  evaluate(value, rational(value.field, point))
}
```

**実使用の根拠**: Rational 点を受け取る補間と、塔の Scalar を受け取る多項式評価で使用。

**意味論・余分か否か**: Nat は単項の指数/回数、Binary は Integer magnitude、Integer は Rational numerator。元の Nat に戻していない。Extension は係数体に対応する Fraction 深さが必要。形が連なるだけの変換を恒等往復と分類しない。N03/N07 の重複計算とは別。

**推奨する次の確認**: 必要な型埋込みや正規化を一括除去せず、個別の重複計算を対象にする。

**静的複雑度・限界**: 出力型が異なり表現構築が必要。ループでの再利用可能性は N07 に分離。速度測定なし。


## N14 証明→checked Number/System の再構築は検証境界として必要

分類 `semantically_required` / 優先 `exclude` / 確度 `high` / source `09f615b8374817d04817eb5b45e776dbee2bfa8a`。未計測。

**主箇所**

`src/realalgebraic/arithmetic.mbt:71–82`

```moonbit
pub fn check_arithmetic(proof : ArithmeticCertificate) -> Bool {
  if !check_resultant(proof.resultant) {
    false
  } else {
    match
      (
        number(proof.left),
        number(proof.right),
        @sturm.system(proof.resultant.polynomial),
      ) {
      (Ok(a), Ok(b), Ok(system)) =>
        match
```

**関連根拠**

`src/complexalgebraic/number.mbt:53–68`

```moonbit
fn read_certificate(
  proof : NumberCertificate,
) -> Result[Number, @realalgebraic.AlgebraError] {
  match
    (@realalgebraic.number(proof.real), @realalgebraic.number(proof.imaginary)) {
    (Ok(real), Ok(imaginary)) => {
      let value = number(real, imaginary)
      if certificate(value).equal(proof) {
        Ok(value)
      } else {
        Err(@realalgebraic.InvalidDefinition)
      }
    }
    (Err(error), _) | (_, Err(error)) => Err(error)
  }
}
```

`src/numberfield/realization.mbt:110–120`

```moonbit
pub fn realize_start(value : Element) -> Result[Realization, FieldError] {
  let polynomial = match minimal_polynomial(value) {
    Ok(polynomial) => polynomial
    Err(error) => return Err(error)
  }
  match @real.number(embedding(value.field)) {
    Err(_) => Err(InternalInvariant)
    Ok(root) =>
      Ok({ input: value, polynomial, root, padding: @exact.rational_one(), })
  }
}
```

`src/realalgebraic/number.mbt:27–35`

```moonbit
pub fn number(data : RootCertificate) -> Result[Number, AlgebraError] {
  match @sturm.system(data.polynomial) {
    Err(_) => Err(InvalidDefinition)
    Ok(system) =>
      match
        @sturm.count_between(system, data.interval.lower, data.interval.upper) {
        Some(Succ(Zero)) => Ok({ system, interval: data.interval, })
        _ => Err(InvalidInterval)
      }
```

**呼出元**

`src/complexalgebraic/number.mbt:71–73`

```moonbit
pub fn check_number(proof : NumberCertificate) -> Bool {
  read_certificate(proof) is Ok(_)
}
```

`src/compositum/producer.mbt:141–150`

```moonbit
    _ => return Err(InternalInvariant)
  }
  let (xvalue, xembedding) = match @nf.realize(x, budget.realization) {
    Err(error) => return Err(FieldFailure(error))
    Ok(@nf.RealPaused(_)) => return Ok(Unresolved(RealizationBudget))
    Ok(@nf.RealReady(value, proof)) => (value, proof)
  }
  let (yvalue, yembedding) = match @nf.realize(y, budget.realization) {
    Err(error) => return Err(FieldFailure(error))
    Ok(@nf.RealPaused(_)) => return Ok(Unresolved(RealizationBudget))
```

**実使用の根拠**: 公開 root/arithmetic/complex 証明の検証と NF の実埋込み realization から到達。

**意味論・余分か否か**: 外部 RootCertificate は未検証。number が squarefree/Sturm 情報と区間一根性を作り検証する。Field は root certificate を持つが checked Number の Sturm.System を持たず、realize_start は現行型で必要な派生情報を供給する。

**推奨する次の確認**: checker の再構築を同じ payload だからと削らない。producer-only checked 値再利用は別設計。field(proof) と field_result(Number,proof) の両経路、context/根区間同一性を分けて検証する必要がある。

**静的複雑度・限界**: Sturm/根数検証を伴い単なる wrapper ではない。現行検証要件の一部で余分変換から除外。


## N15 昔の Nat→Binary→half→Nat と NF/CF 座標再走査は既修正

分類 `already_fixed` / 優先 `exclude` / 確度 `high` / source `09f615b8374817d04817eb5b45e776dbee2bfa8a`。未計測。

**主箇所**

`src/core/natural.mbt:3–20`

```moonbit
pub fn halve_nat(n : Nat) -> (Nat, Bool) {
  fn walk(fast : Nat, slow : Nat) -> (Nat, Bool) {
    match (fast, slow) {
      (Zero, _) => (slow, false)
      (Succ(Zero), Succ(tail)) => (tail, true)
      (Succ(Succ(rest)), Succ(tail)) => walk(rest, tail)
      // Initially fast=slow, and consuming two/one preserves fast <= slow.
      // Thus a positive fast with zero slow is unreachable.
      _ => (Zero, false)
    }
  }
  walk(n, n)
}

///|
pub fn half_nat(n : Nat) -> Nat {
  let (quotient, _) = halve_nat(n)
  quotient
```

**関連根拠**

`src/fppoly/irreducibility.mbt:94–98`

```moonbit
                        false => Ok(None)
                        true => {
                          let half = @core.half_nat(n)
                          match
                            coprime_witnesses(
```

`src/fppoly/irreducibility.mbt:163–167`

```moonbit
            Err(_) => false
            Ok({ remainder: x, .. }) => {
              let half = @core.half_nat(n)
              check_powers(x, certificate.frobenius, n, x) &&
              check_witnesses(
```

`src/cyclotomic/cyclotomic.mbt:56–60`

```moonbit
        Succ(Zero) =>
          (Succ(Zero), @exact.rational_negate(@exact.rational_one()))
        _ => (@core.half_nat(order), @exact.rational_one())
      }
      match
```

`src/complexfield/coordinates.mbt:19–21`

```moonbit
/// Exact QQ coordinates in [1,alpha,...,i,i*alpha,...].
pub fn coordinates(value : Element) -> @core.Chain[@exact.Rational] {
  @core.append(@nf.coordinates(value.real), @nf.coordinates(value.imaginary))
```

`src/numberfield/linear.mbt:37–39`

```moonbit
                  Ok(reduced) => Some(Cons(coordinates(reduced), tail))
                }
            }
```

`docs/bootstrap/nat-conversions.md:1–15`

```moonbit
# Natを直接処理する共有基礎

[ドキュメント](../README.md) / [探索・改善記録](README.md)

ユーザー監査の`fppoly/irreducibility.mbt`二箇所と`cyclotomic/cyclotomic.mbt`では、
floor(n/2)のためにNat→Binary→Natを作っていた。
この経路を`core.half_nat`へ置き換えた。

最初は`halve_nat(n)`でSuccを二つずつ消費して商へ一つずつ積む方式を共有化した。
その後、[末尾共有](nat-tail-sharing.md)へ進め、商のSuccの新規構築も省いた。
同じNat上をfastは二つずつ、slowは一つずつ進み、slowの既存tailを返す。
Binary.from_natはこの二進分割を経て、現在は[8進単位の末尾共有](nat-radix-grouping.md)で
一度に三bitを作る。半分化だけが必要な経路は引き続きCore helperを使う。
いずれもBigIntも組み込み整数も必要ない。
商の値だけなら`half_nat`を呼び、Boolが必要なら`halve_nat`を呼ぶ。
```

**呼出元**

`src/fppoly/irreducibility.mbt:75–81`

```moonbit
/// Return a certificate precisely for monic irreducible positive-degree inputs.
/// The half-degree test uses every i, avoiding any factorization oracle for n.
pub fn irreducibility(
  value : Polynomial,
) -> Result[IrreducibilityCertificate?, PolyError] {
  match (degree(value), leading(value)) {
    (Some(Succ(_) as n), Some(coefficient)) =>
```

`src/cyclotomic/cyclotomic.mbt:51–53`

```moonbit
pub fn field(order : @core.Nat) -> Field? {
  match @core.is_power_of_two_nat(order) {
    false => None
```

**実使用の根拠**: 有限体既約性と円分多項式は Nat 専用 half_nat へ移行済み。

**意味論・余分か否か**: half_nat は fast/slow pointer で既存 unary tail を返す。文書の3箇所を今の未修正往復として再提案しない。NF multiplication_matrix/CF coordinates も一巡抽出へ変更済み。N10 の Horner は別経路。

**推奨する次の確認**: 既修正として保持。lexical gate の外にある N01/N02 等へ集中する。

**静的複雑度・限界**: half_nat は O(n) の単項走査だが Nat 出力の新規再構築や二進中間表現を省く既存変更。今回の性能成果ではない。


## N16 exact.rational_zero/one は既に共有定数

分類 `already_cached` / 優先 `exclude` / 確度 `high` / source `09f615b8374817d04817eb5b45e776dbee2bfa8a`。未計測。

**主箇所**

`src/exact/exact.mbt:192–205`

```moonbit
let canonical_rational_zero : Rational = whole(positive(@binary.zero()))

///|
let canonical_rational_one : Rational = whole(positive(@binary.one()))

///|
pub fn rational_zero() -> Rational {
  canonical_rational_zero
}

///|
pub fn rational_one() -> Rational {
  canonical_rational_one
}
```

**呼出元**

`src/realtower/api.mbt:15–19`

```moonbit
    Extension(parent, _, _) =>
      Fraction(
        Cons(raw_rational(parent, q), Nil),
        Cons(raw_rational(parent, @exact.rational_one()), Nil),
      )
```

`src/realalgebraic/polynomial.mbt:95–100`

```moonbit
              dense_add(
                @core.replicate_onto(
                  n,
                  @exact.rational_zero(),
                  Cons(term.coefficient, Nil),
                ),
```

**実使用の根拠**: production 算術・零埋め・塔埋込みなど多数から使用。

**意味論・余分か否か**: factory 風の名前だが module-level immutable 値を返し、呼出しごとに gcd/正規化しない。realtower.raw_one の再帰構築とは違う。

**推奨する次の確認**: exact factory 一律の cache 追加は不要。Tower Representation の構築を N03 として分ける。

**静的複雑度・限界**: source 上は Rational を毎回構築/正規化しない。inlining/RC コストは未測定。


## N17 テスト・比較 bench の Nat/Binary 往復は意図的

分類 `test_only` / 優先 `exclude` / 確度 `high` / source `09f615b8374817d04817eb5b45e776dbee2bfa8a`。未計測。

**主箇所**

`src/binary/prefix_bench_wbtest.mbt:75–83`

```moonbit
test "direct Nat half versus a Binary roundtrip" (b : @bench.T) {
  for value in [64, 4096] {
    let n = @oracle.nat(value)
    b.bench(name="Binary roundtrip half \{value}", fn() {
      b.keep(to_nat(half(from_nat(n))))
    })
    b.bench(name="structural Nat half \{value}", fn() {
      b.keep(@core.half_nat(n))
    })
```

**関連根拠**

`src/binary/natural_conversion_wbtest.mbt:7–13`

```moonbit
    unary = @core.Succ(unary)
  }
  for value in [8191, 8192, 20000, 65535, 100000] {
    assert_eq(from_nat(@oracle.nat(value)), @oracle.binary(value))
    assert_eq(@oracle.int_of_nat(to_nat(from_nat(@oracle.nat(value)))), value)
  }
}
```

`src/binary/binary_wbtest.mbt:43–49`

```moonbit
    @oracle.int_of_binary(gcd(@oracle.binary(1071), @oracle.binary(462))),
    21,
  )
  for n in 0..<128 {
    assert_eq(from_nat(to_nat(@oracle.binary(n))), @oracle.binary(n))
    assert_eq(@oracle.int_of_binary(double(@oracle.binary(n))), n * 2)
    assert_eq(@oracle.int_of_binary(half(@oracle.binary(n))), n / 2)
```

**実使用の根拠**: 全て *_wbtest.mbt。旧 roundtrip と Nat-native の比較、または変換の往復 law。production caller はない。

**意味論・余分か否か**: 変換互換性や改善の比較対象を検査している。往復が存在するだけで production の無駄にはならない。

**推奨する次の確認**: test oracle/比較 bench として保持。production 変換件数に混入させない。

**静的複雑度・限界**: 意図的なテストの往復で、配布ライブラリの production 性能指摘から除外。

## 到達点と制約

17 件を分類した。全参照を固定コミットから抽出し、JSON に参照した各ソースファイルの SHA-256 を収録。JSON とこの Markdown 以外は変更していない。採用判断、生成 C/RC/CSE、実行頻度、時間・割当て量・ピーク RAM の測定は読み取り監査の範囲外。ソース上の重複を性能成果として扱わない。
