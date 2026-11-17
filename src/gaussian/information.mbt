///|
/// Fisher metric and Amari-Chentsov tensor in linear/quadratic natural coordinates.
/// Retains the Gaussian parameters that fixed the expectations and statistic order.
#derive(Eq, Debug)
pub struct Information {
  source : Gaussian
  metric : @matrix.Matrix[@exact.Rational]
  cubic : @tensor.Tensor[@exact.Rational]
}

///|
pub extend Information with Eq::{equal, not_equal}

///|
pub extend Information with Debug::{to_repr}

///|
/// Computes second/third cumulants, without metric second derivatives or a
/// fourth-cumulant tensor. Quadratic statistics still use raw moments up to six.
pub fn information(source : Gaussian) -> Result[Information, GaussianError] {
  let (metric, cubic, state) = match prepare_information(source) {
    Ok(value) => value
    Err(error) => return Err(error)
  }
  let d = @core.length(state.centered)
  let indices = @core.indices(d)
  let rows = @core.map(indices, fn(i) {
    @core.map(indices, fn(j) { tensor_value(metric, Cons(i, Cons(j, Nil))) })
  })
  match @matrix.matrix(d, rows) {
    None => Err(InternalShape)
    Some(metric) => Ok({ source, metric, cubic, })
  }
}

///|
pub fn Information::parent(self : Information) -> Gaussian {
  self.source
}

///|
pub fn Information::fisher(
  self : Information,
) -> @matrix.Matrix[@exact.Rational] {
  self.metric
}

///|
/// T[i,j,k] = third joint cumulant of sufficient statistics.
pub fn Information::amari_chentsov(
  self : Information,
) -> @tensor.Tensor[@exact.Rational] {
  self.cubic
}
