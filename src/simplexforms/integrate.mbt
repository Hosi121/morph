///|
fn factorial(value : @core.Nat) -> @binary.Binary {
  fn walk(
    remaining : @core.Nat,
    factor : @binary.Binary,
    result : @binary.Binary,
  ) -> @binary.Binary {
    match remaining {
      Zero => result
      Succ(rest) =>
        walk(rest, @binary.successor(factor), @binary.multiply(result, factor))
    }
  }
  walk(value, @binary.one(), @binary.one())
}

///|
fn moment(
  dimension : @core.Nat,
  exponents : @core.Chain[@core.Nat],
) -> @exact.Rational? {
  let numerator = @core.fold_left(exponents, @binary.one(), fn(
    product,
    exponent,
  ) {
    @binary.multiply(product, factorial(exponent))
  })
  let total = @core.fold_left(exponents, dimension, @core.add)
  @exact.ratio(@exact.positive(numerator), factorial(total))
}

///|
fn integrate_polynomial(
  dimension : @core.Nat,
  input : @core.Chain[@poly.Term],
) -> @exact.Rational? {
  match input {
    Nil => Some(@exact.rational_zero())
    Cons(term, rest) =>
      match
        (
          moment(dimension, term.exponents),
          integrate_polynomial(dimension, rest),
        ) {
        (Some(weight), Some(previous)) =>
          Some(
            @exact.rational_add(
              @exact.rational_multiply(term.coefficient, weight),
              previous,
            ),
          )
        _ => None
      }
  }
}

///|
pub fn integrate(
  value : Simplex,
  integrand : @forms.Form,
) -> Result[@exact.Rational, IntegrationError] {
  if !@forms.variables(integrand).equal(value.ambient) {
    Err(DimensionMismatch)
  } else if !@forms.degree(integrand).equal(value.dimension) {
    Err(DegreeMismatch)
  } else {
    match parameterization(value) {
      Err(error) => Err(error)
      Ok(mapping) =>
        match @forms.pullback(mapping, integrand) {
          Err(error) => Err(FormFailure(error))
          Ok(pulled) => {
            fn walk(terms : @core.Chain[@forms.Term]) -> @exact.Rational? {
              match terms {
                Nil => Some(@exact.rational_zero())
                Cons(term, rest) =>
                  if !term.indices.equal(@core.indices(value.dimension)) {
                    None
                  } else {
                    match
                      (
                        integrate_polynomial(
                          value.dimension,
                          @poly.terms(term.coefficient),
                        ),
                        walk(rest),
                      ) {
                      (Some(current), Some(previous)) =>
                        Some(@exact.rational_add(current, previous))
                      _ => None
                    }
                  }
              }
            }
            match walk(@forms.terms(pulled)) {
              None => Err(InternalInvariant)
              Some(result) => Ok(result)
            }
          }
        }
    }
  }
}

///|
/// Separate recurrence for the checker's standard-simplex moment. It starts at
/// mass 1/k! and applies M(alpha+e_i)=(alpha_i+1)M(alpha)/(k+|alpha|+1).
/// It neither calls factorial nor constructs the producer's factorial quotient.
fn recurrent_moment(
  dimension : @core.Nat,
  exponents : @core.Chain[@core.Nat],
) -> @exact.Rational? {
  fn base(
    remaining : @core.Nat,
    denominator : @binary.Binary,
    result : @exact.Rational,
  ) -> (@exact.Rational, @binary.Binary)? {
    match remaining {
      Zero => Some((result, denominator))
      Succ(rest) =>
        match @exact.ratio(@exact.positive(@binary.one()), denominator) {
          None => None
          Some(scale) =>
            base(
              rest,
              @binary.successor(denominator),
              @exact.rational_multiply(result, scale),
            )
        }
    }
  }
  fn increment(
    remaining : @core.Nat,
    numerator : @binary.Binary,
    denominator : @binary.Binary,
    result : @exact.Rational,
  ) -> (@exact.Rational, @binary.Binary)? {
    match remaining {
      Zero => Some((result, denominator))
      Succ(rest) =>
        match @exact.ratio(@exact.positive(numerator), denominator) {
          None => None
          Some(scale) =>
            increment(
              rest,
              @binary.successor(numerator),
              @binary.successor(denominator),
              @exact.rational_multiply(result, scale),
            )
        }
    }
  }
  fn walk(
    input : @core.Chain[@core.Nat],
    denominator : @binary.Binary,
    result : @exact.Rational,
  ) -> @exact.Rational? {
    match input {
      Nil => Some(result)
      Cons(exponent, rest) =>
        match increment(exponent, @binary.one(), denominator, result) {
          None => None
          Some((updated, next)) => walk(rest, next, updated)
        }
    }
  }
  match base(dimension, @binary.one(), @exact.rational_one()) {
    None => None
    Some((weight, denominator)) => walk(exponents, denominator, weight)
  }
}

///|
/// Definition-based check with recurrent rather than factorial moments. Affine
/// parameterization, polynomial pullback and exact arithmetic remain shared.
pub fn check_integral(
  value : Simplex,
  integrand : @forms.Form,
  actual : @exact.Rational,
) -> Bool {
  if !@forms.variables(integrand).equal(value.ambient) ||
    !@forms.degree(integrand).equal(value.dimension) {
    return false
  }
  fn polynomial(input : @core.Chain[@poly.Term]) -> @exact.Rational? {
    match input {
      Nil => Some(@exact.rational_zero())
      Cons(term, rest) =>
        match
          (recurrent_moment(value.dimension, term.exponents), polynomial(rest)) {
          (Some(weight), Some(previous)) =>
            Some(
              @exact.rational_add(
                @exact.rational_multiply(term.coefficient, weight),
                previous,
              ),
            )
          _ => None
        }
    }
  }
  fn terms(input : @core.Chain[@forms.Term]) -> @exact.Rational? {
    match input {
      Nil => Some(@exact.rational_zero())
      Cons(term, rest) =>
        if !term.indices.equal(@core.indices(value.dimension)) {
          None
        } else {
          match (polynomial(@poly.terms(term.coefficient)), terms(rest)) {
            (Some(current), Some(previous)) =>
              Some(@exact.rational_add(current, previous))
            _ => None
          }
        }
    }
  }
  match parameterization(value) {
    Err(_) => false
    Ok(mapping) =>
      match @forms.pullback(mapping, integrand) {
        Err(_) => false
        Ok(pulled) =>
          match terms(@forms.terms(pulled)) {
            None => false
            Some(expected) => expected.equal(actual)
          }
      }
  }
}
