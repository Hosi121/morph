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
fn coordinates(value : Element) -> @core.Chain[@exact.Rational] {
  fn part(value : @nf.Element) -> @core.Chain[@exact.Rational] {
    @core.map(@core.indices(@nf.degree(@nf.parent(value))), fn(i) {
      coefficient(@nf.representative(value), i)
    })
  }
  @core.append(part(value.real), part(value.imaginary))
}

///|
fn vector_matrix(
  d : @core.Nat,
  columns : @core.Chain[@core.Chain[@exact.Rational]],
) -> @matrix.Matrix[@exact.Rational]? {
  match @matrix.matrix(d, columns) {
    Some(matrix) => Some(@matrix.transpose(matrix))
    None => None
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
fn evaluate_polynomial(
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

///|
/// Check monicity, annihilation, and independence of all preceding powers.
/// Rank k of [1,a,...,a^(k-1)] rules out every lower-degree annihilator.
pub fn check_minimal_polynomial(
  value : Element,
  polynomial : @poly.Polynomial,
) -> Bool {
  if !valid(value) ||
    !@poly.variables(polynomial).equal(Succ(Zero)) ||
    !@poly.monic(polynomial).equal(polynomial) {
    return false
  }
  let k = match polynomial_degree(polynomial) {
    Some(Succ(_) as d) => d
    _ => return false
  }
  if @core.compare(k, degree(value.field)).equal(Greater) {
    return false
  }
  match evaluate_polynomial(value, polynomial) {
    Some(result) => if !is_zero(result) { return false }
    None => return false
  }
  fn powers(
    n : @core.Nat,
    power : Element,
  ) -> @core.Chain[@core.Chain[@exact.Rational]]? {
    match n {
      Zero => Some(Nil)
      Succ(rest) =>
        match multiply(power, value) {
          Err(_) => None
          Ok(next) =>
            match powers(rest, next) {
              Some(tail) => Some(Cons(coordinates(power), tail))
              None => None
            }
        }
    }
  }
  match powers(k, one(value.field)) {
    Some(columns) =>
      match vector_matrix(degree(value.field), columns) {
        Some(matrix) =>
          match @linear.rref(matrix) {
            Some(reduction) => @core.length(reduction.pivots).equal(k)
            None => false
          }
        None => false
      }
    None => false
  }
}

///|
/// Find the first dependence among powers in the finite Q-vector space.
/// A separate rank/annihilation checker certifies minimality before returning.
pub fn minimal_polynomial(
  value : Element,
) -> Result[@poly.Polynomial, FieldError] {
  if !valid(value) {
    return Err(DifferentField)
  }
  let d = degree(value.field)
  fn dependence(
    remaining : @core.Nat,
    k : @core.Nat,
    columns : @core.Chain[@core.Chain[@exact.Rational]],
    power : Element,
  ) -> @poly.Polynomial? {
    match remaining {
      Zero => None
      Succ(rest) =>
        match vector_matrix(d, columns) {
          None => None
          Some(matrix) =>
            match @linear.solve(matrix, coordinates(power)) {
              Some(@linear.Unique(coefficients)) =>
                match @core.zip(@core.indices(k), coefficients) {
                  None => None
                  Some(entries) =>
                    match
                      @poly.polynomial(
                        Succ(Zero),
                        Cons(
                          {
                            coefficient: @exact.rational_one(),
                            exponents: Cons(k, Nil),
                          },
                          @core.map(entries, fn(entry) {
                            let (i, c) = entry
                            @poly.Term::{
                              coefficient: @exact.rational_negate(c),
                              exponents: Cons(i, Nil),
                            }
                          }),
                        ),
                      ) {
                      Ok(polynomial) => Some(polynomial)
                      Err(_) => None
                    }
                }
              Some(@linear.Inconsistent) =>
                match multiply(power, value) {
                  Ok(next) =>
                    dependence(
                      rest,
                      Succ(k),
                      @core.append(columns, Cons(coordinates(power), Nil)),
                      next,
                    )
                  Err(_) => None
                }
              _ => None
            }
        }
    }
  }
  match
    dependence(d, Succ(Zero), Cons(coordinates(one(value.field)), Nil), value) {
    Some(polynomial) =>
      if check_minimal_polynomial(value, polynomial) {
        Ok(polynomial)
      } else {
        Err(InternalInvariant)
      }
    None => Err(InternalInvariant)
  }
}
