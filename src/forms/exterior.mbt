///|
// Both bases come from checked Forms and are strictly increasing. Moving a
// right index ahead of the remaining left basis contributes its length parity.
// A repeated index kills the product before coefficient multiplication.
fn merge_exterior_basis(
  left : @core.Chain[@core.Nat],
  right : @core.Chain[@core.Nat],
  left_odd : Bool,
) -> (@core.Chain[@core.Nat], Bool)? {
  match (left, right) {
    (Nil, _) => Some((right, false))
    (_, Nil) => Some((left, false))
    (Cons(a, rest_a), Cons(b, rest_b)) =>
      match @core.compare(a, b) {
        Equal => None
        Less =>
          match merge_exterior_basis(rest_a, right, !left_odd) {
            None => None
            Some((tail, negative)) => Some((Cons(a, tail), negative))
          }
        Greater =>
          match merge_exterior_basis(left, rest_b, left_odd) {
            None => None
            Some((tail, negative)) =>
              Some((Cons(b, tail), if left_odd { !negative } else { negative }))
          }
      }
  }
}

///|
pub fn wedge(a : Form, b : Form) -> Result[Form, FormError] {
  if !a.variables.equal(b.variables) {
    return Err(DimensionMismatch)
  }
  let degree = @core.add(a.degree, b.degree)
  if is_zero(a) || is_zero(b) || @core.compare(degree, a.variables) is Greater {
    return Ok(zero(a.variables, degree))
  }
  let (_, left_odd) = @core.halve_nat(a.degree)
  fn product_row(
    term : Term,
    other : @core.Chain[Term],
    accumulator : @core.Chain[Term],
  ) -> Result[@core.Chain[Term], FormError] {
    match other {
      Nil => Ok(accumulator)
      Cons(head, rest) =>
        match merge_exterior_basis(term.indices, head.indices, left_odd) {
          None => product_row(term, rest, accumulator)
          Some((indices, negative)) =>
            match @poly.multiply(term.coefficient, head.coefficient) {
              Err(_) => Err(InternalInvariant)
              Ok(product) => {
                let coefficient = if negative {
                  @poly.negate(product)
                } else {
                  product
                }
                match insert_term({ coefficient, indices, }, accumulator) {
                  Err(error) => Err(error)
                  Ok(updated) => product_row(term, rest, updated)
                }
              }
            }
        }
    }
  }
  fn product(
    left : @core.Chain[Term],
    accumulator : @core.Chain[Term],
  ) -> Result[@core.Chain[Term], FormError] {
    match left {
      Nil => Ok(accumulator)
      Cons(head, rest) =>
        match product_row(head, b.terms, accumulator) {
          Err(error) => Err(error)
          Ok(updated) => product(rest, updated)
        }
    }
  }
  match product(a.terms, Nil) {
    Err(error) => Err(error)
    Ok(terms) => Ok({ variables: a.variables, degree, terms, })
  }
}

///|
pub fn exterior_derivative(value : Form) -> Result[Form, FormError] {
  fn differentiate(
    term : Term,
    indices : @core.Chain[@core.Nat],
  ) -> @core.Chain[Term]? {
    match indices {
      Nil => Some(Nil)
      Cons(index, rest) =>
        match
          (@poly.derivative(term.coefficient, index), differentiate(term, rest)) {
          (Some(coefficient), Some(tail)) =>
            Some(
              Cons({ coefficient, indices: Cons(index, term.indices), }, tail),
            )
          _ => None
        }
    }
  }
  fn walk(terms : @core.Chain[Term]) -> @core.Chain[Term]? {
    match terms {
      Nil => Some(Nil)
      Cons(term, rest) =>
        match
          (differentiate(term, @core.indices(value.variables)), walk(rest)) {
          (Some(row), Some(tail)) => Some(@core.append(row, tail))
          _ => None
        }
    }
  }
  match walk(value.terms) {
    None => Err(InternalInvariant)
    Some(terms) => form(value.variables, Succ(value.degree), terms)
  }
}
