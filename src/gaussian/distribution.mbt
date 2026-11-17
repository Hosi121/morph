///|
#derive(Eq, Debug)
pub(all) enum GaussianError {
  DimensionMismatch
  NotSymmetric
  NotPositiveDefinite
  InternalShape
}

///|
pub extend GaussianError with Eq::{equal, not_equal}

///|
pub extend GaussianError with Debug::{to_repr}

///|
/// Exact parameters of a nondegenerate Gaussian measure; no density evaluation.
/// Positive definiteness is checked over QQ, using leading principal minors.
#derive(Eq, Debug)
pub struct Gaussian {
  mean : @core.Chain[@exact.Rational]
  covariance : @matrix.Matrix[@exact.Rational]
  precision : @matrix.Matrix[@exact.Rational]
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
  match covariance.equal(@matrix.transpose(covariance)) {
    false => return Err(NotSymmetric)
    true => ()
  }
  match
    @core.all(@core.indices(n), fn(index) {
      let size = @core.Nat::Succ(index)
      let rows = @core.map(@core.take(size, @matrix.rows(covariance)), fn(row) {
        @core.take(size, row)
      })
      match @matrix.matrix(size, rows) {
        None => false
        Some(minor) =>
          match @linear.determinant(minor) {
            None => false
            Some(value) =>
              @exact.rational_compare(value, @exact.rational_zero()) is Greater
          }
      }
    }) {
    false => return Err(NotPositiveDefinite)
    true => ()
  }
  match @linear.inverse(covariance) {
    None => Err(NotPositiveDefinite)
    Some(precision) => Ok({ mean, covariance, precision, })
  }
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
