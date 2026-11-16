///|
fn distinct(values : @core.Chain[@binary.Binary]) -> Bool {
  match values {
    Nil => true
    Cons(head, rest) =>
      !@core.any(rest, fn(value) { value.equal(head) }) && distinct(rest)
  }
}

///|
fn canonical(field : @primefield.Field, value : @binary.Binary) -> Bool {
  @binary.compare(value, @modular.value(@primefield.modulus(field))) is Less
}

///|
fn weighted_monomials(
  weight : @core.Nat,
  bound : @core.Nat,
) -> @core.Chain[Monomial] {
  fn rows(y : @core.Nat, remaining : @core.Nat) -> @core.Chain[Monomial] {
    let row = @core.map(@core.indices(Succ(remaining)), fn(x) { { x, y, } })
    if @core.compare(remaining, weight) is Less {
      row
    } else {
      @core.append(row, rows(Succ(y), @core.subtract(remaining, weight)))
    }
  }
  rows(Zero, bound)
}

///|
fn derivative_indices(multiplicity : @core.Nat) -> @core.Chain[Monomial] {
  match multiplicity {
    Zero => Nil
    Succ(bound) => weighted_monomials(Succ(Zero), bound)
  }
}

///|
/// k≥2; distinct canonical support; explicit complete canonical prime alphabet.
/// Require #monomials > n*s*(s+1)/2 and D<s*A. These sufficient conditions
/// ensure a nonzero interpolation and inclusion of every degree<k polynomial
/// agreeing in at least A positions. They need not be necessary for one word.
pub fn plan(
  field : @primefield.Field,
  alphabet : @core.Chain[@binary.Binary],
  points : @core.Chain[@binary.Binary],
  dimension : @core.Nat,
  agreements : @core.Nat,
  multiplicity : @core.Nat,
  degree_bound : @core.Nat,
) -> Result[Plan, DecodeError] {
  if !@binary.from_nat(@core.length(alphabet)).equal(
      @modular.value(@primefield.modulus(field)),
    ) ||
    !@core.all(alphabet, fn(value) { canonical(field, value) }) ||
    !distinct(alphabet) {
    return Err(InvalidAlphabet)
  }
  if !@core.all(points, fn(value) { canonical(field, value) }) {
    return Err(NoncanonicalSymbol)
  }
  if !distinct(points) {
    return Err(DuplicatePoint)
  }
  let n = @core.length(points)
  let weight = match dimension {
    Zero | Succ(Zero) => return Err(InvalidPlan)
    Succ(weight) => weight
  }
  if @core.compare(dimension, n) is Greater ||
    @core.is_zero(agreements) ||
    @core.compare(agreements, n) is Greater ||
    @core.is_zero(multiplicity) ||
    !(@core.compare(degree_bound, @core.multiply(multiplicity, agreements))
    is Less) {
    return Err(InvalidPlan)
  }
  let monomials = weighted_monomials(weight, degree_bound)
  let derivatives = derivative_indices(multiplicity)
  if !(@core.compare(
      @core.length(monomials),
      @core.multiply(n, @core.length(derivatives)),
    )
    is Greater) {
    return Err(InvalidPlan)
  }
  Ok({
    field,
    alphabet,
    points,
    dimension,
    agreements,
    multiplicity,
    degree_bound,
    monomials,
    derivatives,
  })
}

///|
pub fn field_of(plan : Plan) -> @primefield.Field {
  plan.field
}

///|
pub fn alphabet(plan : Plan) -> @core.Chain[@binary.Binary] {
  plan.alphabet
}

///|
pub fn points(plan : Plan) -> @core.Chain[@binary.Binary] {
  plan.points
}

///|
pub fn message_size(plan : Plan) -> @core.Nat {
  plan.dimension
}

///|
pub fn minimum_agreements(plan : Plan) -> @core.Nat {
  plan.agreements
}

///|
pub fn multiplicity(plan : Plan) -> @core.Nat {
  plan.multiplicity
}

///|
pub fn degree_bound(plan : Plan) -> @core.Nat {
  plan.degree_bound
}

///|
pub fn monomials(plan : Plan) -> @core.Chain[Monomial] {
  plan.monomials
}

///|
pub fn constraint_count(plan : Plan) -> @core.Nat {
  @core.multiply(@core.length(plan.points), @core.length(plan.derivatives))
}

///|
pub fn terms(interpolation : Interpolation) -> @core.Chain[Term] {
  interpolation.terms
}

///|
fn check_word(
  plan : Plan,
  word : @core.Chain[@binary.Binary],
  length : @core.Nat,
) -> DecodeError? {
  if !@core.length(word).equal(length) {
    return Some(LengthMismatch)
  }
  if !@core.all(word, fn(value) { canonical(plan.field, value) }) {
    return Some(NoncanonicalSymbol)
  }
  None
}

///|
pub fn encode(
  plan : Plan,
  message : @core.Chain[@binary.Binary],
) -> Result[@core.Chain[@binary.Binary], DecodeError] {
  match check_word(plan, message, plan.dimension) {
    Some(error) => Err(error)
    None => {
      let polynomial = @fppoly.polynomial(plan.field, message)
      Ok(
        @core.map(plan.points, fn(point) { @fppoly.evaluate(polynomial, point) }),
      )
    }
  }
}
