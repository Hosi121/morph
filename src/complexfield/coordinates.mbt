///|
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

///|
/// Exact QQ coordinates in [1,alpha,...,i,i*alpha,...].
pub fn coordinates(value : Element) -> @core.Chain[@exact.Rational] {
  @core.append(@nf.coordinates(value.real), @nf.coordinates(value.imaginary))
}

///|
/// Reconstruct in the same fixed basis; dimensions are checked before splitting.
pub fn from_coordinates(
  field : Field,
  values : @core.Chain[@exact.Rational],
) -> Result[Element, FieldError] {
  if !@core.length(values).equal(degree(field)) {
    return Err(DimensionMismatch)
  }
  fn polynomial(values : @core.Chain[@exact.Rational]) -> @poly.Polynomial? {
    match @core.zip(@core.indices(@core.length(values)), values) {
      Some(entries) =>
        match
          @poly.polynomial(
            Succ(Zero),
            @core.map(entries, fn(entry) {
              let (index, coefficient) = entry
              @poly.Term::{ coefficient, exponents: Cons(index, Nil), }
            }),
          ) {
          Ok(result) => Some(result)
          Err(_) => None
        }
      None => None
    }
  }
  let n = @nf.degree(real_field(field))
  match (polynomial(@core.take(n, values)), polynomial(@core.drop(n, values))) {
    (Some(real), Some(imaginary)) =>
      match
        (
          @nf.element(real_field(field), real),
          @nf.element(real_field(field), imaginary),
        ) {
        (Ok(a), Ok(b)) => element(field, a, b)
        _ => Err(InternalInvariant)
      }
    _ => Err(InternalInvariant)
  }
}

///|
fn polynomial_degree(polynomial : @poly.Polynomial) -> @core.Nat? {
  match @poly.terms(polynomial) {
    Cons({ exponents: Cons(d, Nil), .. }, _) => Some(d)
    _ => None
  }
}

///|
/// Horner evaluation inside this checked quotient field.
pub fn evaluate_polynomial(
  value : Element,
  polynomial : @poly.Polynomial,
) -> Element? {
  if !@poly.variables(polynomial).equal(Succ(Zero)) {
    return None
  }
  let count : @core.Nat = match polynomial_degree(polynomial) {
    Some(d) => Succ(d)
    None => Zero
  }
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
}
