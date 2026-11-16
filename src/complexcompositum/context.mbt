///|
#derive(Debug)
pub(all) enum StepCertificate {
  Rational(@exact.Rational)
  Reuse(@core.Nat)
  Normalize(@minimal.Certificate)
  Merge(@comp.Common, @comp.Certificate)
}

///|
pub extend StepCertificate with Debug::{to_repr}

///|
/// A replayable real-coordinate construction. Coordinates are in flattened
/// input order: real(z0), imaginary(z0), real(z1), imaginary(z1), ... .
/// Every merge transports the previous residues through its checked left map.
#derive(Debug)
pub(all) struct Certificate {
  sources : @core.Chain[@cx.NumberCertificate]
  initial : @minimal.Certificate
  steps : @core.Chain[StepCertificate]
  field : @nf.Field
  coordinates : @core.Chain[@poly.Polynomial]
}

///|
pub extend Certificate with Debug::{to_repr}

///|
#derive(Debug)
pub struct Common {
  field : @cf.Field
  values : @core.Chain[@cf.Element]
  proof : Certificate
}

///|
pub extend Common with Debug::{to_repr}

///|
#derive(Debug)
struct State {
  field : @nf.Field
  coordinates : @core.Chain[@nf.Element]
  seen : @core.Chain[@real.RootCertificate]
}

///|
pub extend State with Debug::{to_repr}

///|
#derive(Debug)
pub struct Build {
  inputs : @core.Chain[@cx.Number]
  remaining : @core.Chain[@real.Number]
  initial : @minimal.Certificate?
  state : State?
  steps_rev : @core.Chain[StepCertificate]
}

///|
pub extend Build with Debug::{to_repr}

///|
#derive(Eq, Debug)
pub(all) enum StopReason {
  InitializationBudget(@minimal.StopReason)
  NormalizationBudget(@minimal.StopReason)
  MergeBudget(@comp.StopReason)
  VerificationBudget
}

///|
pub extend StopReason with Eq::{equal, not_equal}

///|
pub extend StopReason with Debug::{to_repr}

///|
#derive(Eq, Debug)
pub(all) enum CompositumError {
  AlgebraFailure(@real.AlgebraError)
  MinimalFailure(@minimal.MinimalError)
  FieldFailure(@nf.FieldError)
  ComplexFieldFailure(@cf.FieldError)
  MergeFailure(@comp.CompositumError)
  InternalInvariant
}

///|
pub extend CompositumError with Eq::{equal, not_equal}

///|
pub extend CompositumError with Debug::{to_repr}

///|
#derive(Debug)
pub(all) enum Progress {
  Ready(Common, Certificate)
  Paused(Build, StopReason)
}

///|
pub extend Progress with Debug::{to_repr}

///|
pub fn common_field(value : Common) -> @cf.Field {
  value.field
}

///|
pub fn elements(value : Common) -> @core.Chain[@cf.Element] {
  value.values
}

///|
pub fn certificate(value : Common) -> Certificate {
  value.proof
}

///|
/// Completed real coordinates survive every pause, including an unfinished
/// compositum attempt. The unfinished individual merge is retried on advance.
pub fn completed_coordinates(build : Build) -> @core.Nat {
  match build.state {
    None => Zero
    Some(state) => @core.length(state.coordinates)
  }
}

///|
fn flatten(inputs : @core.Chain[@cx.Number]) -> @core.Chain[@real.Number] {
  match inputs {
    Nil => Nil
    Cons(value, rest) =>
      Cons(@cx.real_part(value), Cons(@cx.imaginary_part(value), flatten(rest)))
  }
}

///|
fn rational_coordinate(value : @real.Number) -> @exact.Rational? {
  match @poly.terms(@real.definition(value)) {
    Cons({ coefficient: leading, exponents: Cons(Succ(Zero), Nil), }, rest) => {
      let constant = match rest {
        Nil => @exact.rational_zero()
        Cons({ coefficient, exponents: Cons(Zero, Nil), }, Nil) => coefficient
        _ => return None
      }
      @exact.rational_divide(@exact.rational_negate(constant), leading)
    }
    _ => None
  }
}

///|
fn duplicate(
  input : @real.RootCertificate,
  seen : @core.Chain[@real.RootCertificate],
  index : @core.Nat,
) -> @core.Nat? {
  match seen {
    Nil => None
    Cons(value, rest) =>
      if value.equal(input) {
        Some(index)
      } else {
        duplicate(input, rest, Succ(index))
      }
  }
}

///|
fn transport(
  previous : @core.Chain[@nf.Element],
  image : @nf.Element,
) -> @core.Chain[@nf.Element]? {
  match previous {
    Nil => Some(Nil)
    Cons(value, rest) =>
      match
        (
          @nf.evaluate_polynomial(image, @nf.representative(value)),
          transport(rest, image),
        ) {
        (Some(value), Some(tail)) => Some(Cons(value, tail))
        _ => None
      }
  }
}

///|
fn with_coordinate(
  state : State,
  input : @real.Number,
  value : @nf.Element,
) -> State {
  {
    ..state,
    coordinates: @core.append(state.coordinates, Cons(value, Nil)),
    seen: @core.append(state.seen, Cons(@real.root_certificate(input), Nil)),
  }
}

///|
fn complex_elements(
  field : @cf.Field,
  coordinates : @core.Chain[@nf.Element],
) -> Result[@core.Chain[@cf.Element], CompositumError] {
  match coordinates {
    Nil => Ok(Nil)
    Cons(real, Cons(imaginary, rest)) => {
      let value = match @cf.element(field, real, imaginary) {
        Ok(value) => value
        Err(error) => return Err(ComplexFieldFailure(error))
      }
      match complex_elements(field, rest) {
        Ok(tail) => Ok(Cons(value, tail))
        Err(error) => Err(error)
      }
    }
    _ => Err(InternalInvariant)
  }
}
