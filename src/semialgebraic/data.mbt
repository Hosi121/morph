///|
#derive(Eq, Debug)
pub(all) enum Bound {
  NegativeInfinity
  Finite(@real.RootCertificate)
  PositiveInfinity
}

///|
pub extend Bound with Eq::{equal, not_equal}

///|
pub extend Bound with Debug::{to_repr}

///|
/// Finite endpoints are exact real algebraic roots. Infinite endpoints are open.
#derive(Eq, Debug)
pub(all) struct Interval {
  lower : Bound
  upper : Bound
  lower_closed : Bool
  upper_closed : Bool
}

///|
pub extend Interval with Eq::{equal, not_equal}

///|
pub extend Interval with Debug::{to_repr}

///|
#derive(Eq, Debug)
pub(all) enum SetError {
  MalformedCells
  InvalidEndpoint
  AlgebraFailure(@real.AlgebraError)
}

///|
pub extend SetError with Eq::{equal, not_equal}

///|
pub extend SetError with Debug::{to_repr}

///|
#derive(Eq, Debug)
pub(all) struct Certificate {
  formula : @base.Formula
  quantifier : @cad2.Quantifier
  cad : @cad2.Certificate
  truth : @core.Chain[Bool]
  intervals : @core.Chain[Interval]
}

///|
pub extend Certificate with Eq::{equal, not_equal}

///|
pub extend Certificate with Debug::{to_repr}

///|
/// Maximal connected interval/point components, in order. This is an exact
/// interval-set QE result, not a QQ-polynomial Formula or a minimal-polynomial
/// canonicalization of algebraic endpoint representations.
#derive(Debug)
pub struct RealSet {
  certificate : Certificate
}

///|
pub extend RealSet with Debug::{to_repr}

///|
pub fn certificate(value : RealSet) -> Certificate {
  value.certificate
}

///|
pub fn intervals(value : RealSet) -> @core.Chain[Interval] {
  value.certificate.intervals
}
