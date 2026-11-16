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
/// Column j is the residue of value*t^j in the power basis.
pub fn multiplication_matrix(
  value : Element,
) -> Result[@matrix.Matrix[@exact.Rational], FieldError] {
  let d = degree(value.field)
  fn columns(
    todo : @core.Chain[@core.Nat],
  ) -> @core.Chain[@core.Chain[@exact.Rational]]? {
    match todo {
      Nil => Some(Nil)
      Cons(j, rest) =>
        match (power_monomial(j), columns(rest)) {
          (Some(monomial), Some(tail)) =>
            match @poly.multiply(value.residue, monomial) {
              Err(_) => None
              Ok(product) =>
                match element(value.field, product) {
                  Err(_) => None
                  Ok(reduced) =>
                    Some(
                      Cons(
                        @core.map(@core.indices(d), fn(i) {
                          coefficient(reduced.residue, i)
                        }),
                        tail,
                      ),
                    )
                }
            }
          _ => None
        }
    }
  }
  match columns(@core.indices(d)) {
    Some(rows) =>
      match @matrix.matrix(d, rows) {
        Some(matrix) => Ok(@matrix.transpose(matrix))
        None => Err(InternalInvariant)
      }
    None => Err(InternalInvariant)
  }
}

///|
pub fn trace(value : Element) -> Result[@exact.Rational, FieldError] {
  match multiplication_matrix(value) {
    Err(error) => Err(error)
    Ok(matrix) => {
      fn diagonal(
        rows : @core.Chain[@core.Chain[@exact.Rational]],
        index : @core.Nat,
      ) -> @exact.Rational? {
        match rows {
          Nil => Some(@exact.rational_zero())
          Cons(row, rest) =>
            match (@core.nth(row, index), diagonal(rest, Succ(index))) {
              (Some(a), Some(b)) => Some(@exact.rational_add(a, b))
              _ => None
            }
        }
      }
      match diagonal(@matrix.rows(matrix), Zero) {
        Some(result) => Ok(result)
        None => Err(InternalInvariant)
      }
    }
  }
}

///|
pub fn norm(value : Element) -> Result[@exact.Rational, FieldError] {
  match multiplication_matrix(value) {
    Err(error) => Err(error)
    Ok(matrix) =>
      match @linear.determinant(matrix) {
        Some(result) => Ok(result)
        None => Err(InternalInvariant)
      }
  }
}
