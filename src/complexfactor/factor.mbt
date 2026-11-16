///|
#derive(Eq, Debug)
pub(all) enum RootError {
  NotUnivariate
  ZeroPolynomial
  InvalidFactorization
  PolynomialFailure
  FactorizationFailure(@zassenhaus.AlgebraError)
  RootFailure(@complexroots.RootError)
  InternalInvariant
}

///|
pub extend RootError with Eq::{equal, not_equal}

///|
pub extend RootError with Debug::{to_repr}

///|
fn degree(source : @poly.Polynomial) -> @core.Nat {
  match @poly.terms(source) {
    Cons({ exponents: Cons(exponent, Nil), .. }, _) => exponent
    _ => Zero
  }
}

///|
fn coefficient(
  terms : @core.Chain[@poly.Term],
  exponent : @core.Nat,
) -> @exact.Rational {
  match terms {
    Nil => @exact.rational_zero()
    Cons({ coefficient: value, exponents: Cons(power, Nil), }, rest) =>
      if power.equal(exponent) {
        value
      } else {
        coefficient(rest, exponent)
      }
    Cons(_, rest) => coefficient(rest, exponent)
  }
}

///|
/// Ascending dense QQ coefficients, including all missing powers.
fn coefficients(source : @poly.Polynomial) -> @core.Chain[@exact.Rational] {
  fn walk(exponent : @core.Nat) -> @core.Chain[@exact.Rational] {
    if @core.compare(exponent, degree(source)).equal(Greater) {
      Nil
    } else {
      Cons(coefficient(@poly.terms(source), exponent), walk(Succ(exponent)))
    }
  }
  walk(Zero)
}

///|
fn factor_polynomial(factor : @zassenhaus.Factor) -> @poly.Polynomial {
  fn terms(
    values : @core.Chain[@exact.Integer],
    exponent : @core.Nat,
  ) -> @core.Chain[@poly.Term] {
    match values {
      Nil => Nil
      Cons(value, rest) =>
        Cons(
          { coefficient: @exact.whole(value), exponents: Cons(exponent, Nil), },
          terms(rest, Succ(exponent)),
        )
    }
  }
  // All dimensions are generated here, so construction cannot fail. The zero
  // fallback is rejected by every factor checker before a Problem is produced.
  match
    @poly.polynomial(
      Succ(Zero),
      terms(@zassenhaus.coefficients(factor.polynomial), Zero),
    ) {
    Ok(value) => value
    Err(_) => @poly.zero(Succ(Zero))
  }
}

///|
fn coprime_factors(factors : @core.Chain[@zassenhaus.Factor]) -> Bool {
  match factors {
    Nil => true
    Cons(head, tail) => {
      let source = factor_polynomial(head)
      head.multiplicity is Succ(_) &&
      degree(source) is Succ(_) &&
      @core.all(tail, fn(other) {
        match @poly.univariate_gcd(source, factor_polynomial(other)) {
          Ok(gcd) => !@poly.is_zero(gcd) && degree(gcd).equal(Zero)
          Err(_) => false
        }
      }) &&
      coprime_factors(tail)
    }
  }
}

///|
#derive(Eq, Debug)
pub struct Problem {
  source : @poly.Polynomial
  factorization : @zassenhaus.RationalFactorization
}

///|
pub extend Problem with Eq::{equal, not_equal}

///|
pub extend Problem with Debug::{to_repr}

///|
#derive(Eq, Debug)
pub(all) enum Preparation {
  Prepared(Problem)
  FactorizationIncomplete(@zassenhaus.StopReason)
  VerificationUndecided(@zassenhaus.RationalFactorization)
}

///|
pub extend Preparation with Eq::{equal, not_equal}

///|
pub extend Preparation with Debug::{to_repr}

///|
/// Import/retry a factorization without treating verification exhaustion as
/// validity. Verification fuel is a subset budget per claimed factor.
pub fn prepare_with_factorization(
  source : @poly.Polynomial,
  factorization : @zassenhaus.RationalFactorization,
  verification_fuel : @core.Nat,
) -> Result[Preparation, RootError] {
  if !@poly.variables(source).equal(Succ(Zero)) {
    Err(NotUnivariate)
  } else if @poly.is_zero(source) {
    Err(ZeroPolynomial)
  } else if !coprime_factors(factorization.factors) {
    Err(InvalidFactorization)
  } else {
    match
      @zassenhaus.check_rational_factorization(
        coefficients(source),
        factorization,
        verification_fuel,
      ) {
      Proven => Ok(Prepared({ source, factorization, }))
      Refuted => Err(InvalidFactorization)
      Undecided => Ok(VerificationUndecided(factorization))
    }
  }
}

///|
/// Zassenhaus budgets apply separately to each square-free component;
/// verification fuel applies separately to each irreducibility claim.
/// Incomplete factorization is an explicit outcome, never an empty root set.
pub fn prepare(
  source : @poly.Polynomial,
  primes : @core.Chain[@binary.Binary],
  lift_fuel : @core.Nat,
  subset_fuel : @core.Nat,
  verification_fuel : @core.Nat,
) -> Result[Preparation, RootError] {
  if !@poly.variables(source).equal(Succ(Zero)) {
    Err(NotUnivariate)
  } else if @poly.is_zero(source) {
    Err(ZeroPolynomial)
  } else {
    match
      @zassenhaus.factor_rational(
        coefficients(source),
        primes,
        lift_fuel,
        subset_fuel,
      ) {
      Err(error) => Err(FactorizationFailure(error))
      Ok(RationalIncomplete(reason)) => Ok(FactorizationIncomplete(reason))
      Ok(RationalComplete(factorization)) =>
        prepare_with_factorization(source, factorization, verification_fuel)
    }
  }
}
