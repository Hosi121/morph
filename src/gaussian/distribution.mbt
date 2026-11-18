///|
#derive(Eq, Debug)
pub(all) enum GaussianError {
  DimensionMismatch
  NotSymmetric
  NotPositiveDefinite
  InternalShape
  Geometry(@riemann.JetError)
}

///|
pub extend GaussianError with Eq::{equal, not_equal}

///|
pub extend GaussianError with Debug::{to_repr}

///|
/// Exact parameters of a nondegenerate Gaussian measure; no density evaluation.
/// Positive definiteness is retained as a structured exact LDL form.
#derive(Debug)
pub struct Gaussian {
  mean : @core.Chain[@exact.Rational]
  covariance : @matrix.Matrix[@exact.Rational]
  precision : @matrix.Matrix[@exact.Rational]
  form : @positiveform.PositiveDefinite
}

///|
// A prepared representation is a cache, not part of the probability measure.
pub impl Eq for Gaussian with fn equal(self, other) {
  self.mean.equal(other.mean) &&
  self.covariance.equal(other.covariance) &&
  self.precision.equal(other.precision)
}

///|
pub extend Gaussian with Eq::{equal, not_equal}

///|
pub extend Gaussian with Debug::{to_repr}

///|
pub fn gaussian(
  mean : @core.Chain[@exact.Rational],
  covariance : @matrix.Matrix[@exact.Rational],
) -> Result[Gaussian, GaussianError] {
  let n = @core.length(mean)
  match
    @matrix.height(covariance).equal(n) && @matrix.width(covariance).equal(n) {
    false => return Err(DimensionMismatch)
    true => ()
  }
  match @positiveform.positive_definite(covariance) {
    Err(NotSymmetric) => Err(NotSymmetric)
    Err(NotPositiveDefinite) => Err(NotPositiveDefinite)
    Err(NotSquare) => Err(DimensionMismatch)
    Err(InternalShape) => Err(InternalShape)
    Ok(form) => gaussian_from_form(mean, form)
  }
}

///|
/// Retains an existing SPD construction, including scales and independent blocks.
/// Matrix caches are materialized once for the existing moment API.
pub fn gaussian_from_form(
  mean : @core.Chain[@exact.Rational],
  form : @positiveform.PositiveDefinite,
) -> Result[Gaussian, GaussianError] {
  if !@core.length(mean).equal(form.dimension()) {
    return Err(DimensionMismatch)
  }
  match (form.matrix(), form.inverse().matrix()) {
    (Ok(covariance), Ok(precision)) =>
      Ok({ mean, covariance, precision, form, })
    _ => Err(InternalShape)
  }
}

///|
pub fn covariance_form(value : Gaussian) -> @positiveform.PositiveDefinite {
  value.form
}

///|
pub fn precision_form(value : Gaussian) -> @positiveform.PositiveDefinite {
  value.form.inverse()
}

///|
pub fn dimension(value : Gaussian) -> @core.Nat {
  @core.length(value.mean)
}

///|
pub fn mean(value : Gaussian) -> @core.Chain[@exact.Rational] {
  value.mean
}

///|
pub fn covariance(value : Gaussian) -> @matrix.Matrix[@exact.Rational] {
  value.covariance
}

///|
pub fn precision(value : Gaussian) -> @matrix.Matrix[@exact.Rational] {
  value.precision
}

///|
fn component(
  values : @core.Chain[@exact.Rational],
  i : @core.Nat,
) -> @exact.Rational {
  match @core.nth(values, i) {
    Some(value) => value
    None => @exact.rational_zero()
  }
}

///|
fn entry(
  matrix : @matrix.Matrix[@exact.Rational],
  i : @core.Nat,
  j : @core.Nat,
) -> @exact.Rational {
  match @core.nth(@matrix.rows(matrix), i) {
    Some(row) => component(row, j)
    None => @exact.rational_zero()
  }
}
