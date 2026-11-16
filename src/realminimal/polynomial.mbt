///|
/// A dense ascending rational view, reconstructed through symbolic Nat indices.
fn coefficients(value : @poly.Polynomial) -> @core.Chain[@exact.Rational]? {
  if !@core.compare(@poly.variables(value), Succ(Zero)).equal(Equal) {
    return None
  }
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
  }
  match @poly.terms(value) {
    Nil => Some(Nil)
    Cons(head, _) =>
      match head.exponents {
        Cons(degree, Nil) =>
          Some(
            @core.map(@core.indices(Succ(degree)), fn(index) {
              coefficient(@poly.terms(value), index)
            }),
          )
        _ => None
      }
  }
}

///|
fn integer_polynomial(value : @zass.Polynomial) -> @poly.Polynomial? {
  fn terms(
    values : @core.Chain[@exact.Integer],
    index : @core.Nat,
  ) -> @core.Chain[@poly.Term] {
    match values {
      Nil => Nil
      Cons(c, rest) =>
        Cons(
          { coefficient: @exact.whole(c), exponents: Cons(index, Nil), },
          terms(rest, Succ(index)),
        )
    }
  }
  match @poly.polynomial(Succ(Zero), terms(@zass.coefficients(value), Zero)) {
    Ok(p) => Some(@poly.monic(p))
    Err(_) => None
  }
}
