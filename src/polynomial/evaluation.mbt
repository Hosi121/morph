///|
fn univariate_power(
  base : @exact.Rational,
  exponent : @core.Nat,
) -> @exact.Rational {
  fn power(bits : @core.Chain[Bool]) -> @exact.Rational {
    match bits {
      Nil => @exact.rational_one()
      Cons(bit, rest) => {
        let half = power(rest)
        let square = @exact.rational_multiply(half, half)
        if bit {
          @exact.rational_multiply(base, square)
        } else {
          square
        }
      }
    }
  }
  match exponent {
    Zero => @exact.rational_one()
    Succ(Zero) => base
    _ => power(@binary.bits(@binary.from_nat(exponent)))
  }
}

///|
fn univariate_horner(
  terms : @core.Chain[Term],
  value : @exact.Rational,
) -> @exact.Rational? {
  fn scan(
    rest : @core.Chain[Term],
    degree : @core.Nat,
    accumulated : @exact.Rational,
  ) -> @exact.Rational? {
    match rest {
      Nil =>
        match degree {
          Zero => Some(accumulated)
          _ =>
            Some(
              @exact.rational_multiply(
                accumulated,
                univariate_power(value, degree),
              ),
            )
        }
      Cons(term, tail) =>
        match term.exponents {
          Cons(next, Nil) =>
            scan(
              tail,
              next,
              @exact.rational_add(
                @exact.rational_multiply(
                  accumulated,
                  univariate_power(value, @core.subtract(degree, next)),
                ),
                term.coefficient,
              ),
            )
          _ => None
        }
    }
  }
  match terms {
    Nil => Some(@exact.rational_zero())
    Cons(term, rest) =>
      match term.exponents {
        Cons(degree, Nil) => scan(rest, degree, term.coefficient)
        _ => None
      }
  }
}

///|
/// Sparse Horner evaluation reuses degree gaps in a canonical univariate
/// polynomial. Other dimensions retain the generic term-by-term evaluator.
pub fn evaluate(
  p : Polynomial,
  values : @core.Chain[@exact.Rational],
) -> @exact.Rational? {
  match (p.variables, values) {
    (Succ(Zero), Cons(value, Nil)) =>
      match univariate_horner(p.terms, value) {
        Some(result) => Some(result)
        None => evaluate_generic(p, values)
      }
    _ => evaluate_generic(p, values)
  }
}
