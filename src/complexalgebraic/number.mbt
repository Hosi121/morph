///|
/// An exact complex algebraic number, represented by its real coordinates.
#derive(Debug)
pub struct Number {
  priv real : @realalgebraic.Number
  priv imaginary : @realalgebraic.Number
}

///|
pub extend Number with Debug::{to_repr}

///|
pub fn number(
  real : @realalgebraic.Number,
  imaginary : @realalgebraic.Number,
) -> Number {
  { real, imaginary, }
}

///|
pub fn real_part(value : Number) -> @realalgebraic.Number {
  value.real
}

///|
pub fn imaginary_part(value : Number) -> @realalgebraic.Number {
  value.imaginary
}

///|
/// Representation binding is deliberately stronger than numeric equality.
#derive(Eq, Debug)
pub(all) struct NumberCertificate {
  real : @realalgebraic.RootCertificate
  imaginary : @realalgebraic.RootCertificate
}

///|
pub extend NumberCertificate with Eq::{equal, not_equal}

///|
pub extend NumberCertificate with Debug::{to_repr}

///|
pub fn certificate(value : Number) -> NumberCertificate {
  {
    real: @realalgebraic.root_certificate(value.real),
    imaginary: @realalgebraic.root_certificate(value.imaginary),
  }
}

///|
fn read_certificate(
  proof : NumberCertificate,
) -> Result[Number, @realalgebraic.AlgebraError] {
  match
    (@realalgebraic.number(proof.real), @realalgebraic.number(proof.imaginary)) {
    (Ok(real), Ok(imaginary)) => {
      let value = number(real, imaginary)
      if certificate(value).equal(proof) {
        Ok(value)
      } else {
        Err(@realalgebraic.InvalidDefinition)
      }
    }
    (Err(error), _) | (_, Err(error)) => Err(error)
  }
}

///|
pub fn check_number(proof : NumberCertificate) -> Bool {
  read_certificate(proof) is Ok(_)
}

///|
/// Construct a Gaussian rational without approximation.
pub fn rational(
  real : @exact.Rational,
  imaginary : @exact.Rational,
) -> Result[Number, @realalgebraic.AlgebraError] {
  match (@realalgebraic.rational(real), @realalgebraic.rational(imaginary)) {
    (Ok(real), Ok(imaginary)) => Ok(number(real, imaginary))
    (Err(error), _) | (_, Err(error)) => Err(error)
  }
}

///|
fn real_zero(value : @realalgebraic.Number) -> Bool {
  let zero = @exact.rational_zero()
  let interval = @realalgebraic.interval(value)
  // Every valid real algebraic definition is univariate. Evaluation at zero is
  // its constant coefficient, so no partial evaluator or failure is involved.
  let constant = @core.fold_left(
    @poly.terms(@realalgebraic.definition(value)),
    zero,
    fn(sum, term) {
      match term.exponents {
        Cons(Zero, Nil) => @exact.rational_add(sum, term.coefficient)
        _ => sum
      }
    },
  )
  let vanishes = @exact.rational_compare(constant, zero).equal(Equal)
  @exact.rational_compare(interval.lower, zero).equal(Less) &&
  !@exact.rational_compare(interval.upper, zero).equal(Less) &&
  vanishes
}

///|
/// Exact zero test: each valid coordinate isolates one root, so containing zero
/// and vanishing there is necessary and sufficient. No refinement is needed.
pub fn is_zero(value : Number) -> Bool {
  real_zero(value.real) && real_zero(value.imaginary)
}
