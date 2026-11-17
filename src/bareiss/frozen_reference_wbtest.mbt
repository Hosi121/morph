///|
// Frozen from a8e7207 src/linear::arithmetic and src/rowreduce::determinant.
// Keep this path independent of future @linear.determinant dispatch changes.
fn bareiss_reference_arithmetic() -> @rowreduce.Field[@exact.Rational] {
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
fn bareiss_reference_field_determinant(
  field : @rowreduce.Field[@exact.Rational],
  input : @matrix.Matrix[@exact.Rational],
) -> @exact.Rational? {
  match @core.compare(@matrix.height(input), @matrix.width(input)) {
    Equal =>
      match bareiss_reference_rref(field, input) {
        None => None
        Some(reduced) =>
          match
            @core.compare(@core.length(reduced.pivots), @matrix.width(input)) {
            Equal => Some(reduced.factor)
            _ => Some(field.zero)
          }
      }
    _ => None
  }
}

///|
fn bareiss_frozen_reference(
  input : @matrix.Matrix[@exact.Rational],
) -> @exact.Rational? {
  bareiss_reference_field_determinant(bareiss_reference_arithmetic(), input)
}
