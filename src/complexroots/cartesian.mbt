///|
#derive(Eq, Debug)
pub(all) enum RootError {
  NotUnivariate
  ZeroPolynomial
  InvalidCertificate
  PolynomialFailure
  VarietyFailure(@variety.VarietyError)
  InternalInvariant
}

///|
pub extend RootError with Eq::{equal, not_equal}

///|
pub extend RootError with Debug::{to_repr}

///|
/// Exact identity p(x+i*y) = real(x,y) + i*imaginary(x,y).
#derive(Eq, Debug)
pub(all) struct Cartesian {
  real : @poly.Polynomial
  imaginary : @poly.Polynomial
}

///|
pub extend Cartesian with Eq::{equal, not_equal}

///|
pub extend Cartesian with Debug::{to_repr}

///|
fn two() -> @core.Nat {
  Succ(Succ(Zero))
}

///|
fn cartesian_product(a : Cartesian, b : Cartesian) -> Cartesian? {
  match
    (
      @poly.multiply(a.real, b.real),
      @poly.multiply(a.imaginary, b.imaginary),
      @poly.multiply(a.real, b.imaginary),
      @poly.multiply(a.imaginary, b.real),
    ) {
    (Ok(ac), Ok(bd), Ok(ad), Ok(bc)) =>
      match (@poly.subtract(ac, bd), @poly.add(ad, bc)) {
        (Ok(real), Ok(imaginary)) => Some({ real, imaginary, })
        _ => None
      }
    _ => None
  }
}

///|
fn cartesian_power(base : Cartesian, exponent : @core.Nat) -> Cartesian? {
  match exponent {
    Zero =>
      Some({
        real: @poly.constant(two(), @exact.rational_one()),
        imaginary: @poly.zero(two()),
      })
    Succ(rest) =>
      match cartesian_power(base, rest) {
        Some(previous) => cartesian_product(base, previous)
        None => None
      }
  }
}

///|
pub fn cartesian(source : @poly.Polynomial) -> Result[Cartesian, RootError] {
  if !@poly.variables(source).equal(Succ(Zero)) {
    Err(NotUnivariate)
  } else {
    match
      (
        @poly.polynomial(
          two(),
          Cons(
            {
              coefficient: @exact.rational_one(),
              exponents: Cons(Succ(Zero), Cons(Zero, Nil)),
            },
            Nil,
          ),
        ),
        @poly.polynomial(
          two(),
          Cons(
            {
              coefficient: @exact.rational_one(),
              exponents: Cons(Zero, Cons(Succ(Zero), Nil)),
            },
            Nil,
          ),
        ),
      ) {
      (Ok(x), Ok(y)) => {
        let base : Cartesian = { real: x, imaginary: y, }
        fn terms(values : @core.Chain[@poly.Term]) -> Cartesian? {
          match values {
            Nil =>
              Some({ real: @poly.zero(two()), imaginary: @poly.zero(two()), })
            Cons({ coefficient, exponents: Cons(exponent, Nil), }, rest) =>
              match (cartesian_power(base, exponent), terms(rest)) {
                (Some(power), Some(tail)) => {
                  let scale : @poly.Term = {
                    coefficient,
                    exponents: Cons(Zero, Cons(Zero, Nil)),
                  }
                  match
                    (
                      @poly.scale(power.real, scale),
                      @poly.scale(power.imaginary, scale),
                    ) {
                    (Ok(real), Ok(imaginary)) =>
                      match
                        (
                          @poly.add(real, tail.real),
                          @poly.add(imaginary, tail.imaginary),
                        ) {
                        (Ok(real), Ok(imaginary)) => Some({ real, imaginary, })
                        _ => None
                      }
                    _ => None
                  }
                }
                _ => None
              }
            _ => None
          }
        }
        match terms(@poly.terms(source)) {
          Some(result) => Ok(result)
          None => Err(PolynomialFailure)
        }
      }
      _ => Err(PolynomialFailure)
    }
  }
}

///|
fn degree(source : @poly.Polynomial) -> @core.Nat {
  match @poly.terms(source) {
    Cons({ exponents: Cons(exponent, Nil), .. }, _) => exponent
    _ => Zero
  }
}

///|
#derive(Eq, Debug)
pub struct Problem {
  source : @poly.Polynomial
  squarefree : @poly.Polynomial
  cartesian : Cartesian
  variety : @variety.Problem
}

///|
pub extend Problem with Eq::{equal, not_equal}

///|
pub extend Problem with Debug::{to_repr}

///|
pub fn prepare(source : @poly.Polynomial) -> Result[Problem, RootError] {
  if !@poly.variables(source).equal(Succ(Zero)) {
    Err(NotUnivariate)
  } else if @poly.is_zero(source) {
    Err(ZeroPolynomial)
  } else {
    match @sturm.system(source) {
      Err(_) => Err(PolynomialFailure)
      Ok(system) => {
        let squarefree = @sturm.squarefree(system)
        match cartesian(squarefree) {
          Err(error) => Err(error)
          Ok(expansion) =>
            match
              @variety.problem(
                two(),
                Cons(expansion.real, Cons(expansion.imaginary, Nil)),
              ) {
              Err(error) => Err(VarietyFailure(error))
              Ok(variety) =>
                Ok({ source, squarefree, cartesian: expansion, variety, })
            }
        }
      }
    }
  }
}

///|
pub fn source(problem : Problem) -> @poly.Polynomial {
  problem.source
}

///|
pub fn squarefree(problem : Problem) -> @poly.Polynomial {
  problem.squarefree
}
