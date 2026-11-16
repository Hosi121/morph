///|
#derive(Eq, Debug)
pub(all) struct ProjectedPointCertificate {
  separation : SeparationCertificate
  parameter : @real.RootCertificate
}

///|
pub extend ProjectedPointCertificate with Eq::{equal, not_equal}

///|
pub extend ProjectedPointCertificate with Debug::{to_repr}

///|
pub fn check_projected_point(
  source : Problem,
  proof : ProjectedPointCertificate,
) -> Bool {
  check_separation(source, proof.separation) &&
  check_point({
    shape: proof.separation.solutions.shape,
    parameter: proof.parameter,
  })
}

///|
#derive(Debug)
pub struct ProjectedPoint {
  separation : SeparationCertificate
  full : Point
}

///|
pub extend ProjectedPoint with Debug::{to_repr}

///|
pub fn projected_points(
  value : SeparatedSet,
) -> Result[@core.Chain[ProjectedPoint], VarietyError] {
  let separation = separation_certificate(value)
  match points(value.full) {
    Ok(points) => Ok(@core.map(points, fn(full) { { separation, full, } }))
    Err(error) => Err(error)
  }
}

///|
pub fn projected_parameter(value : ProjectedPoint) -> @real.Number {
  parameter(value.full)
}

///|
pub fn projected_dimension(value : ProjectedPoint) -> @core.Nat {
  value.separation.projection
}

///|
/// Only the original coordinates are returned; the final auxiliary t is omitted.
pub fn projected_coordinate_expressions(
  value : ProjectedPoint,
) -> @core.Chain[@poly.Polynomial] {
  @core.take(value.separation.projection, coordinate_expressions(value.full))
}

///|
pub fn projected_point_certificate(
  value : ProjectedPoint,
) -> ProjectedPointCertificate {
  {
    separation: value.separation,
    parameter: @real.root_certificate(parameter(value.full)),
  }
}

///|
pub fn check_projected_point_result(
  source : Problem,
  value : ProjectedPoint,
  proof : ProjectedPointCertificate,
) -> Bool {
  projected_point_certificate(value).equal(proof) &&
  check_projected_point(source, proof)
}

///|
pub fn evaluate_projected_coordinate(
  value : ProjectedPoint,
  index : @core.Nat,
  fuel : @core.Nat,
) -> Result[CoordinateProgress, VarietyError] {
  if !@core.compare(index, value.separation.projection).equal(Less) {
    Err(InvalidCoordinate)
  } else {
    evaluate_coordinate(value.full, index, fuel)
  }
}

///|
/// Bind source Problem, projected point, coordinate index and Number payload.
pub fn check_projected_coordinate_result(
  source : Problem,
  point : ProjectedPoint,
  value : @real.Number,
  proof : CoordinateCertificate,
) -> Bool {
  @core.compare(proof.index, point.separation.projection).equal(Less) &&
  proof.point.equal(point_certificate(point.full)) &&
  check_projected_point_result(
    source,
    point,
    projected_point_certificate(point),
  ) &&
  check_coordinate_result(value, proof)
}
