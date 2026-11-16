///|
/// Complete real-root coverage for a checked shape presentation. Intervals
/// denote distinct parameter roots in order; algebraic multiplicities are not
/// encoded, even when the eliminant is non-square-free.
#derive(Eq, Debug)
pub(all) struct SolutionCertificate {
  shape : ShapeCertificate
  intervals : @core.Chain[@sturm.Interval]
}

///|
pub extend SolutionCertificate with Eq::{equal, not_equal}

///|
pub extend SolutionCertificate with Debug::{to_repr}

///|
pub fn check_solutions(proof : SolutionCertificate) -> Bool {
  match shape_from_certificate(proof.shape) {
    Ok(shape) => @sturm.check_isolation(shape.system, proof.intervals)
    Err(_) => false
  }
}

///|
pub fn check_basis_solutions(
  basis : @f4.Basis,
  proof : SolutionCertificate,
) -> Bool {
  check_basis_shape(basis, proof.shape) && check_solutions(proof)
}

///|
#derive(Eq, Debug)
pub struct SolutionSet {
  shape : Shape
  intervals : @core.Chain[@sturm.Interval]
}

///|
pub extend SolutionSet with Eq::{equal, not_equal}

///|
pub extend SolutionSet with Debug::{to_repr}

///|
pub fn solution_certificate(value : SolutionSet) -> SolutionCertificate {
  { shape: value.shape.certificate, intervals: value.intervals, }
}

///|
pub fn solutions_from_certificate(
  proof : SolutionCertificate,
) -> Result[SolutionSet, VarietyError] {
  match shape_from_certificate(proof.shape) {
    Err(error) => Err(error)
    Ok(shape) =>
      if @sturm.check_isolation(shape.system, proof.intervals) {
        Ok({ shape, intervals: proof.intervals, })
      } else {
        Err(InvalidCertificate)
      }
  }
}

///|
#derive(Eq, Debug)
pub struct Isolation {
  shape : Shape
  isolation : @sturm.Isolation
}

///|
pub extend Isolation with Eq::{equal, not_equal}

///|
pub extend Isolation with Debug::{to_repr}

///|
#derive(Eq, Debug)
pub(all) enum Start {
  Isolating(Isolation)
  NoSolutions(UnitCertificate)
  UnsupportedSystem(UnsupportedReason)
}

///|
pub extend Start with Eq::{equal, not_equal}

///|
pub extend Start with Debug::{to_repr}

///|
#derive(Eq, Debug)
pub(all) enum Progress {
  Complete(SolutionSet)
  Paused(Isolation)
}

///|
pub extend Progress with Eq::{equal, not_equal}

///|
pub extend Progress with Debug::{to_repr}

///|
pub fn isolate(shape : Shape) -> Isolation {
  { shape, isolation: @sturm.isolate(shape.system), }
}

///|
pub fn start(
  variables : @core.Nat,
  basis : @core.Chain[@poly.Polynomial],
) -> Result[Start, VarietyError] {
  match extract(variables, basis) {
    Err(error) => Err(error)
    Ok(UnitIdeal(proof)) => Ok(NoSolutions(proof))
    Ok(Unsupported(reason)) => Ok(UnsupportedSystem(reason))
    Ok(ShapeReady(shape)) => Ok(Isolating(isolate(shape)))
  }
}

///|
pub fn start_basis(basis : @f4.Basis) -> Result[Start, VarietyError] {
  match from_basis(basis) {
    Err(error) => Err(error)
    Ok(UnitIdeal(proof)) => Ok(NoSolutions(proof))
    Ok(Unsupported(reason)) => Ok(UnsupportedSystem(reason))
    Ok(ShapeReady(shape)) => Ok(Isolating(isolate(shape)))
  }
}

///|
/// Fuel counts Sturm interval nodes. Paused states retain the complete pending
/// isolation problem; no partial set is represented as a complete solution set.
pub fn advance(state : Isolation, fuel : @core.Nat) -> Progress {
  match @sturm.advance(state.isolation, fuel) {
    Paused(next) => Paused({ ..state, isolation: next, })
    Isolated(intervals) => Complete({ shape: state.shape, intervals, })
  }
}

///|
#derive(Eq, Debug)
pub(all) struct PointCertificate {
  shape : ShapeCertificate
  parameter : @real.RootCertificate
}

///|
pub extend PointCertificate with Eq::{equal, not_equal}

///|
pub extend PointCertificate with Debug::{to_repr}

///|
pub fn check_point(proof : PointCertificate) -> Bool {
  match shape_from_certificate(proof.shape) {
    Err(_) => false
    Ok(shape) =>
      proof.parameter.polynomial.equal(@sturm.squarefree(shape.system)) &&
      @real.check_root(proof.parameter)
  }
}

///|
/// Coordinates are h_i(alpha) for one shared algebraic parameter alpha. Keeping
/// this dependency avoids the degree growth of independently materializing
/// each coordinate through repeated algebraic arithmetic.
#derive(Debug)
pub struct Point {
  shape : Shape
  parameter : @real.Number
}

///|
pub extend Point with Debug::{to_repr}

///|
pub fn parameter(value : Point) -> @real.Number {
  value.parameter
}

///|
pub fn coordinate_expressions(value : Point) -> @core.Chain[@poly.Polynomial] {
  value.shape.certificate.coordinates
}

///|
pub fn coordinate_expression_at(
  value : Point,
  index : @core.Nat,
) -> @poly.Polynomial? {
  @core.nth(coordinate_expressions(value), index)
}

///|
pub fn point_certificate(value : Point) -> PointCertificate {
  {
    shape: value.shape.certificate,
    parameter: @real.root_certificate(value.parameter),
  }
}

///|
pub fn point_from_certificate(
  proof : PointCertificate,
) -> Result[Point, VarietyError] {
  if !check_point(proof) {
    Err(InvalidCertificate)
  } else {
    match (shape_from_certificate(proof.shape), @real.number(proof.parameter)) {
      (Ok(shape), Ok(parameter)) => Ok({ shape, parameter, })
      _ => Err(InternalInvariant)
    }
  }
}

///|
pub fn points(value : SolutionSet) -> Result[@core.Chain[Point], VarietyError] {
  fn walk(intervals : @core.Chain[@sturm.Interval]) -> @core.Chain[Point]? {
    match intervals {
      Nil => Some(Nil)
      Cons(interval, rest) =>
        match
          (
            @real.number({
              polynomial: @sturm.squarefree(value.shape.system),
              interval,
            }),
            walk(rest),
          ) {
          (Ok(parameter), Some(tail)) =>
            Some(Cons({ shape: value.shape, parameter, }, tail))
          _ => None
        }
    }
  }
  match walk(value.intervals) {
    Some(points) => Ok(points)
    None => Err(InternalInvariant)
  }
}
