///|
#derive(Eq, Debug)
pub(all) enum GeometryError {
  MissingDerivative
  Metric(@riemann.JetError)
  Tensor(@tensor.TensorError)
}

///|
pub extend GeometryError with Eq::{equal, not_equal}

///|
pub extend GeometryError with Debug::{to_repr}

///|
/// A probability three-jet supplies all derivatives of its Fisher metric.
/// Redundant parameterizations are rejected by the nondegeneracy check here.
pub fn fisher_jet(
  point : @infogeom.ModelPoint,
) -> Result[@riemann.MetricJet, GeometryError] {
  let model = @infogeom.local_model(point)
  match (@infogeom.metric_first(model), @infogeom.metric_second(point)) {
    (Some(first), Some(second)) =>
      match @riemann.metric_jet(@infogeom.fisher(model), first, second) {
        Ok(jet) => Ok(jet)
        Err(error) => Err(Metric(error))
      }
    _ => Err(MissingDerivative)
  }
}

///|
pub fn curvature(
  point : @infogeom.ModelPoint,
) -> Result[@riemann.Curvature, GeometryError] {
  match fisher_jet(point) {
    Err(error) => Err(error)
    Ok(jet) => Ok(@riemann.curvature(@riemann.connection(jet)))
  }
}
