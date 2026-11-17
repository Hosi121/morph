///|
/// Checked curve, order conditions, field cardinality and final-exponent data.
#derive(Eq, Debug)
pub struct Parameters {
  curve : @ec.Curve
  order : @binary.Binary
  size : @binary.Binary
  exponent : @binary.Binary
}

///|
pub extend Parameters with Eq::{equal, not_equal}

///|
pub extend Parameters with Debug::{to_repr}

///|
/// A nonzero partial Miller evaluation and its exact scalar multiple.
#derive(Debug)
pub struct MillerValue {
  multiple : @ec.Point
  value : @gf.Element
}

///|
pub extend MillerValue with Debug::{to_repr}

///|
#derive(Eq, Debug)
pub(all) enum PairingError {
  InvalidOrder
  CharacteristicDivisor
  OrderNotDivisor
  DifferentCurve
  NotTorsion
  EvaluationAtInfinity
  ZeroEvaluation
  PoleEvaluation
  IndeterminateEvaluation
  CurveFailure(@ec.CurveError)
  FieldFailure(@gf.FieldError)
  InternalInvariant
}

///|
pub extend PairingError with Eq::{equal, not_equal}

///|
pub extend PairingError with Debug::{to_repr}

///|
pub fn parent(parameters : Parameters) -> @ec.Curve {
  parameters.curve
}

///|
pub fn order(parameters : Parameters) -> @binary.Binary {
  parameters.order
}

///|
/// Cardinality of the actual galois.Field, not merely its characteristic.
pub fn field_size(parameters : Parameters) -> @binary.Binary {
  parameters.size
}

///|
pub fn final_exponent(parameters : Parameters) -> @binary.Binary {
  parameters.exponent
}

///|
pub fn multiple(result : MillerValue) -> @ec.Point {
  result.multiple
}

///|
pub fn value(result : MillerValue) -> @gf.Element {
  result.value
}
