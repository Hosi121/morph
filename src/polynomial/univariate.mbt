///|
/// Coefficient of X^exponent; terms with other exponent shapes contribute zero.
pub fn univariate_coefficient(
  polynomial : Polynomial,
  exponent : @core.Nat,
) -> @exact.Rational {
  @core.fold_left(terms(polynomial), @exact.rational_zero(), fn(sum, term) {
    if term.exponents.equal(Cons(exponent, Nil)) {
      @exact.rational_add(sum, term.coefficient)
    } else {
      sum
    }
  })
}

///|
/// Leading univariate degree, or None for zero or a non-univariate term shape.
pub fn univariate_degree(polynomial : Polynomial) -> @core.Nat? {
  match terms(polynomial) {
    Cons({ exponents: Cons(d, Nil), .. }, _) => Some(d)
    _ => None
  }
}

///|
/// Univariate Horner evaluation in a caller-supplied algebra. The embedding
/// and operations must use one fixed context and the rational coefficient map.
pub fn[A, E] evaluate_in(
  value : A,
  polynomial : Polynomial,
  zero : A,
  rational : (@exact.Rational) -> A,
  add_element : (A, A) -> Result[A, E],
  multiply_element : (A, A) -> Result[A, E],
) -> A? {
  if !variables(polynomial).equal(Succ(Zero)) {
    return None
  }
  let count : @core.Nat = match univariate_degree(polynomial) {
    Some(d) => Succ(d)
    None => Zero
  }
  fn go(todo : @core.Chain[@core.Nat], accumulated : A) -> A? {
    match todo {
      Nil => Some(accumulated)
      Cons(i, rest) =>
        match multiply_element(accumulated, value) {
          Err(_) => None
          Ok(product) =>
            match
              add_element(
                product,
                rational(univariate_coefficient(polynomial, i)),
              ) {
              Ok(next) => go(rest, next)
              Err(_) => None
            }
        }
    }
  }
  go(@core.reverse(@core.indices(count)), zero)
}
