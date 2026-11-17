///|
/// Checks one output coordinate by its original scalar equation. This does not
/// call evolve, row_action, matrix.multiply or the producer's row accumulator.
fn coordinate(
  rows : @core.Chain[@core.Chain[@exact.Rational]],
  weights : @core.Chain[@exact.Rational],
  index : @core.Nat,
) -> @exact.Rational? {
  match (rows, weights) {
    (Nil, Nil) => Some(@exact.rational_zero())
    (Cons(row, rest), Cons(weight, tail)) =>
      match (@core.nth(row, index), coordinate(rest, tail, index)) {
        (Some(entry), Some(previous)) =>
          Some(
            @exact.rational_add(
              @exact.rational_multiply(weight, entry),
              previous,
            ),
          )
        _ => None
      }
    _ => None
  }
}

///|
pub fn check_evolution(
  value : Kernel,
  distribution : @core.Chain[@exact.Rational],
  actual : @core.Chain[@exact.Rational],
) -> Bool {
  match
    (
      probability(states(value), distribution),
      probability(states(value), actual),
    ) {
    (Ok(_), Ok(_)) =>
      @core.all(@core.indices(states(value)), fn(index) {
        coordinate_equal(value, distribution, actual, index)
      })
    _ => false
  }
}

///|
pub fn check_composition(
  first : Kernel,
  second : Kernel,
  actual : Kernel,
) -> Bool {
  if !states(first).equal(states(second)) ||
    !states(first).equal(states(actual)) {
    false
  } else {
    match
      @core.zip(@matrix.rows(first.transition), @matrix.rows(actual.transition)) {
      None => false
      Some(pairs) =>
        @core.all(pairs, fn(pair) {
          let (distribution, result) = pair
          check_evolution(second, distribution, result)
        })
    }
  }
}

///|
fn coordinate_equal(
  value : Kernel,
  weights : @core.Chain[@exact.Rational],
  expected : @core.Chain[@exact.Rational],
  index : @core.Nat,
) -> Bool {
  match
    (
      coordinate(@matrix.rows(value.transition), weights, index),
      @core.nth(expected, index),
    ) {
    (Some(actual), Some(expected)) => actual.equal(expected)
    _ => false
  }
}
