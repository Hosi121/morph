///|
pub fn wedge(a : Form, b : Form) -> Result[Form, FormError] {
  fn product_row(
    term : Term,
    other : @core.Chain[Term],
  ) -> Result[@core.Chain[Term], FormError] {
    match other {
      Nil => Ok(Nil)
      Cons(head, rest) =>
        match
          (
            @poly.multiply(term.coefficient, head.coefficient),
            product_row(term, rest),
          ) {
          (Ok(coefficient), Ok(tail)) =>
            Ok(
              Cons(
                {
                  coefficient,
                  indices: @core.append(term.indices, head.indices),
                },
                tail,
              ),
            )
          _ => Err(InternalInvariant)
        }
    }
  }
  fn product(left : @core.Chain[Term]) -> Result[@core.Chain[Term], FormError] {
    match left {
      Nil => Ok(Nil)
      Cons(head, rest) =>
        match (product_row(head, b.terms), product(rest)) {
          (Ok(row), Ok(tail)) => Ok(@core.append(row, tail))
          _ => Err(InternalInvariant)
        }
    }
  }
  if !a.variables.equal(b.variables) {
    Err(DimensionMismatch)
  } else {
    match product(a.terms) {
      Err(error) => Err(error)
      Ok(terms) => form(a.variables, @core.add(a.degree, b.degree), terms)
    }
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
