///|
/// Rational specialization of the shared exact field row-reduction kernel.
fn arithmetic() -> @rowreduce.Field[@exact.Rational] {
  {
    zero: @exact.rational_zero(),
    one: @exact.rational_one(),
    add: @exact.rational_add,
    subtract: @exact.rational_subtract,
    negate: @exact.rational_negate,
    multiply: @exact.rational_multiply,
    inverse: fn(value) {
      match @exact.nonzero(value) {
        None => None
        Some(proof) => Some(@exact.reciprocal(proof))
      }
    },
  }
}

///|
#derive(Eq, Debug)
pub(all) struct Reduction {
  matrix : @matrix.Matrix[@exact.Rational]
  pivots : @core.Chain[@core.Nat]
  factor : @exact.Rational
}

///|
pub extend Reduction with Eq::{equal, not_equal}

///|
pub extend Reduction with Debug::{to_repr}

///|
pub fn rref(input : @matrix.Matrix[@exact.Rational]) -> Reduction? {
  match @rowreduce.rref(arithmetic(), input) {
    None => None
    Some(reduction) =>
      Some({
        matrix: reduction.matrix,
        pivots: reduction.pivots,
        factor: reduction.factor,
      })
  }
}

///|
pub fn determinant(input : @matrix.Matrix[@exact.Rational]) -> @exact.Rational? {
  @rowreduce.determinant(arithmetic(), input)
}

///|
#derive(Eq, Debug)
pub(all) enum Solution {
  Unique(@core.Chain[@exact.Rational])
  Affine(
    @core.Chain[@exact.Rational],
    @core.Chain[@core.Chain[@exact.Rational]]
  )
  Inconsistent
}

///|
pub extend Solution with Eq::{equal, not_equal}

///|
pub extend Solution with Debug::{to_repr}

///|
pub fn solve(
  a : @matrix.Matrix[@exact.Rational],
  b : @core.Chain[@exact.Rational],
) -> Solution? {
  match @rowreduce.solve(arithmetic(), a, b) {
    None => None
    Some(Unique(solution)) => Some(Unique(solution))
    Some(Affine(particular, basis)) => Some(Affine(particular, basis))
    Some(Inconsistent) => Some(Inconsistent)
  }
}

///|
pub fn inverse(
  input : @matrix.Matrix[@exact.Rational],
) -> @matrix.Matrix[@exact.Rational]? {
  @rowreduce.inverse(arithmetic(), input)
}
