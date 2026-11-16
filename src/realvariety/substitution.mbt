///|
#derive(Eq, Debug)
pub(all) enum VarietyError {
  DimensionMismatch
  InvalidBasis
  InvalidCoordinate
  InvalidCertificate
  F4Failure(@f4.F4Error)
  InternalInvariant
}

///|
pub extend VarietyError with Eq::{equal, not_equal}

///|
pub extend VarietyError with Debug::{to_repr}

///|
fn univariate_one() -> @poly.Polynomial {
  @poly.constant(Succ(Zero), @exact.rational_one())
}

///|
fn univariate_zero() -> @poly.Polynomial {
  @poly.zero(Succ(Zero))
}

///|
fn parameter_polynomial() -> @poly.Polynomial? {
  match
    @poly.polynomial(
      Succ(Zero),
      Cons(
        {
          coefficient: @exact.rational_one(),
          exponents: Cons(Succ(Zero), Nil),
        },
        Nil,
      ),
    ) {
    Ok(p) => Some(p)
    Err(_) => None
  }
}

///|
fn positive_degree(value : @poly.Polynomial) -> Bool {
  match @poly.terms(value) {
    Cons({ exponents: Cons(Succ(_), Nil), .. }, _) =>
      @poly.variables(value).equal(Succ(Zero))
    _ => false
  }
}

///|
fn parameter_exponent(
  exponents : @core.Chain[@core.Nat],
  variables : @core.Nat,
) -> @core.Nat? {
  match (variables, exponents) {
    (Succ(Zero), Cons(last, Nil)) => Some(last)
    (Succ(Succ(rest)), Cons(Zero, tail)) => parameter_exponent(tail, Succ(rest))
    _ => None
  }
}

///|
fn as_parameter(
  value : @poly.Polynomial,
  variables : @core.Nat,
) -> @poly.Polynomial? {
  fn walk(terms : @core.Chain[@poly.Term]) -> @core.Chain[@poly.Term]? {
    match terms {
      Nil => Some(Nil)
      Cons(term, rest) =>
        match (parameter_exponent(term.exponents, variables), walk(rest)) {
          (Some(exponent), Some(tail)) =>
            Some(
              Cons(
                {
                  coefficient: term.coefficient,
                  exponents: Cons(exponent, Nil),
                },
                tail,
              ),
            )
          _ => None
        }
    }
  }
  if !@poly.variables(value).equal(variables) {
    None
  } else {
    match walk(@poly.terms(value)) {
      Some(terms) =>
        match @poly.polynomial(Succ(Zero), terms) {
          Ok(p) => Some(p)
          Err(_) => None
        }
      None => None
    }
  }
}

///|
/// Read a*x_i+q(t) with constant a!=0 and return h_i(t)=-q(t)/a.
fn coordinate_expression(
  value : @poly.Polynomial,
  variables : @core.Nat,
  index : @core.Nat,
) -> @poly.Polynomial? {
  let variable_exponents : @core.Chain[@core.Nat] = @core.map(
    @core.indices(variables),
    fn(j) { if j.equal(index) { Succ(Zero) } else { Zero } },
  )
  fn walk(
    terms : @core.Chain[@poly.Term],
  ) -> (@exact.Rational, @core.Chain[@poly.Term])? {
    match terms {
      Nil => Some((@exact.rational_zero(), Nil))
      Cons(term, rest) =>
        match walk(rest) {
          None => None
          Some((scalar, tail)) =>
            if term.exponents.equal(variable_exponents) {
              Some((@exact.rational_add(scalar, term.coefficient), tail))
            } else {
              match parameter_exponent(term.exponents, variables) {
                Some(exponent) =>
                  Some(
                    (
                      scalar,
                      Cons(
                        {
                          coefficient: term.coefficient,
                          exponents: Cons(exponent, Nil),
                        },
                        tail,
                      ),
                    ),
                  )
                None => None
              }
            }
        }
    }
  }
  if !@poly.variables(value).equal(variables) {
    None
  } else {
    match walk(@poly.terms(value)) {
      Some((scalar, terms)) =>
        match (@exact.nonzero(scalar), @poly.polynomial(Succ(Zero), terms)) {
          (Some(proof), Ok(q)) =>
            match
              @poly.scale(q, {
                coefficient: @exact.rational_negate(@exact.reciprocal(proof)),
                exponents: Cons(Zero, Nil),
              }) {
              Ok(h) => Some(h)
              Err(_) => None
            }
          _ => None
        }
      None => None
    }
  }
}

///|
fn product_mod(
  left : @poly.Polynomial,
  right : @poly.Polynomial,
  modulus : @poly.Polynomial,
) -> @poly.Polynomial? {
  match @poly.multiply(left, right) {
    Err(_) => None
    Ok(product) =>
      match @poly.normal_form(product, Cons(modulus, Nil)) {
        Ok(p) => Some(p)
        Err(_) => None
      }
  }
}

///|
fn power_mod(
  value : @poly.Polynomial,
  exponent : @core.Nat,
  modulus : @poly.Polynomial,
) -> @poly.Polynomial? {
  match exponent {
    Zero => Some(univariate_one())
    Succ(rest) =>
      match power_mod(value, rest, modulus) {
        Some(p) => product_mod(value, p, modulus)
        None => None
      }
  }
}

///|
/// Exact substitution x_i=h_i(t), followed by remainder modulo g(t).
pub fn substitute_mod(
  value : @poly.Polynomial,
  coordinates : @core.Chain[@poly.Polynomial],
  eliminant : @poly.Polynomial,
) -> Result[@poly.Polynomial, VarietyError] {
  fn monomial(
    exponents : @core.Chain[@core.Nat],
    coordinates : @core.Chain[@poly.Polynomial],
  ) -> @poly.Polynomial? {
    match (exponents, coordinates) {
      (Nil, Nil) => Some(univariate_one())
      (Cons(exponent, rest), Cons(coordinate, tail)) =>
        match
          (power_mod(coordinate, exponent, eliminant), monomial(rest, tail)) {
          (Some(a), Some(b)) => product_mod(a, b, eliminant)
          _ => None
        }
      _ => None
    }
  }
  fn terms(values : @core.Chain[@poly.Term]) -> @poly.Polynomial? {
    match values {
      Nil => Some(univariate_zero())
      Cons(term, rest) =>
        match (monomial(term.exponents, coordinates), terms(rest)) {
          (Some(m), Some(tail)) =>
            match
              @poly.scale(m, {
                coefficient: term.coefficient,
                exponents: Cons(Zero, Nil),
              }) {
              Err(_) => None
              Ok(scaled) =>
                match @poly.add(scaled, tail) {
                  Ok(sum) =>
                    match @poly.normal_form(sum, Cons(eliminant, Nil)) {
                      Ok(p) => Some(p)
                      Err(_) => None
                    }
                  Err(_) => None
                }
            }
          _ => None
        }
    }
  }
  if !@poly.variables(value).equal(@core.length(coordinates)) ||
    !positive_degree(eliminant) ||
    !@core.all(coordinates, fn(p) { @poly.variables(p).equal(Succ(Zero)) }) {
    Err(DimensionMismatch)
  } else {
    match terms(@poly.terms(value)) {
      Some(p) => Ok(p)
      None => Err(InternalInvariant)
    }
  }
}

///|
fn nonzero_constant(value : @poly.Polynomial) -> Bool {
  match @poly.terms(value) {
    Cons(term, Nil) =>
      @core.all(term.exponents, fn(e) { e.equal(Zero) }) &&
      !@exact.rational_compare(term.coefficient, @exact.rational_zero()).equal(
        Equal,
      )
    _ => false
  }
}
