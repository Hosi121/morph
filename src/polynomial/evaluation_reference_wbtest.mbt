///|
/// Frozen term-by-term evaluator from the pre-Horner public implementation.
fn evaluation_reference(
  p : Polynomial,
  values : @core.Chain[@exact.Rational],
) -> @exact.Rational? {
  fn power(
    base : @exact.Rational,
    exponent : @core.Chain[Bool],
  ) -> @exact.Rational {
    match exponent {
      Nil => @exact.rational_one()
      Cons(bit, rest) => {
        let half = power(base, rest)
        let square = @exact.rational_multiply(half, half)
        if bit {
          @exact.rational_multiply(base, square)
        } else {
          square
        }
      }
    }
  }
  fn term_value(term : Term) -> @exact.Rational {
    match @core.zip(term.exponents, values) {
      None => @exact.rational_zero()
      Some(pairs) =>
        @core.fold_left(pairs, term.coefficient, fn(product, pair) {
          let (exponent, value) = pair
          @exact.rational_multiply(
            product,
            power(value, @binary.bits(@binary.from_nat(exponent))),
          )
        })
    }
  }
  match @core.compare(p.variables, @core.length(values)) {
    Equal =>
      Some(
        @core.fold_left(p.terms, @exact.rational_zero(), fn(sum, term) {
          @exact.rational_add(sum, term_value(term))
        }),
      )
    _ => None
  }
}
