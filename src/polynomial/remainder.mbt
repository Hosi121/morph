///|
/// Lex remainder with the same leading-term and first-divisor choices as
/// divide, without constructing its discarded quotient polynomials or indices.
fn remainder_only(
  dividend : Polynomial,
  divisors : @core.Chain[Polynomial],
) -> Result[Polynomial, PolyError] {
  fn find(
    divisors : @core.Chain[Polynomial],
    term : Term,
  ) -> (Polynomial, Term)? {
    match divisors {
      Nil => None
      Cons(divisor, rest) =>
        match divisor.terms {
          Nil => find(rest, term)
          Cons(leading, _) =>
            match
              (
                monomial_quotient(term.exponents, leading.exponents),
                @exact.nonzero(leading.coefficient),
              ) {
              (Some(exponents), Some(coefficient)) =>
                Some(
                  (
                    divisor,
                    {
                      coefficient: @exact.rational_multiply(
                        term.coefficient,
                        @exact.reciprocal(coefficient),
                      ),
                      exponents,
                    },
                  ),
                )
              _ => find(rest, term)
            }
        }
    }
  }
  fn reduce(
    todo : @core.Chain[Term],
    reversed : @core.Chain[Term],
  ) -> Polynomial {
    match todo {
      Nil => { variables: dividend.variables, terms: @core.reverse(reversed), }
      Cons(term, rest) =>
        match find(divisors, term) {
          None => reduce(rest, Cons(term, reversed))
          Some((divisor, multiplier)) => {
            let negative = @core.map(term_times(multiplier, divisor.terms), fn(
              term,
            ) {
              {
                coefficient: @exact.rational_negate(term.coefficient),
                exponents: term.exponents,
              }
            })
            reduce(merge_terms(todo, negative), reversed)
          }
        }
    }
  }
  let same_dimension = @core.all(divisors, fn(p) {
    match @core.compare(p.variables, dividend.variables) {
      Equal => true
      _ => false
    }
  })
  // Dimension errors precede zero divisors, including zero dividends.
  match (same_dimension, @core.any(divisors, is_zero)) {
    (false, _) => Err(DimensionMismatch)
    (_, true) => Err(ZeroDivisor)
    (true, false) => Ok(reduce(dividend.terms, Nil))
  }
}
