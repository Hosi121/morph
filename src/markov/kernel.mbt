///|
/// Exact finite-state, time-homogeneous transition kernel. State indices are
/// 0..states-1. Rows are outgoing probabilities; row distributions evolve as mu P.
/// The constructor guarantees a nonempty square matrix, nonnegative entries and
/// exact row sums of one. No numerical tolerance or implicit normalization is used.
#derive(Eq, Debug)
pub struct Kernel {
  transition : @matrix.Matrix[@exact.Rational]
}

///|
pub extend Kernel with Eq::{equal, not_equal}

///|
pub extend Kernel with Debug::{to_repr}

///|
#derive(Eq, Debug)
pub(all) enum MarkovError {
  EmptyStateSpace
  NonSquare
  NegativeProbability
  NotNormalized
  DimensionMismatch
  InvalidState
  NonUniqueStationary
  InternalInvariant
}

///|
pub extend MarkovError with Eq::{equal, not_equal}

///|
pub extend MarkovError with Debug::{to_repr}

///|
fn nonnegative(value : @exact.Rational) -> Bool {
  !(@exact.rational_compare(value, @exact.rational_zero()) is Less)
}

///|
fn sum(values : @core.Chain[@exact.Rational]) -> @exact.Rational {
  @core.fold_left(values, @exact.rational_zero(), @exact.rational_add)
}

///|
fn probability(
  count : @core.Nat,
  values : @core.Chain[@exact.Rational],
) -> Result[Unit, MarkovError] {
  if !@core.length(values).equal(count) {
    Err(DimensionMismatch)
  } else if !@core.all(values, nonnegative) {
    Err(NegativeProbability)
  } else if !sum(values).equal(@exact.rational_one()) {
    Err(NotNormalized)
  } else {
    Ok(())
  }
}

///|
pub fn kernel(
  rows : @core.Chain[@core.Chain[@exact.Rational]],
) -> Result[Kernel, MarkovError] {
  let count = @core.length(rows)
  match count {
    Zero => Err(EmptyStateSpace)
    Succ(_) =>
      match @matrix.matrix(count, rows) {
        None => Err(NonSquare)
        Some(transition) =>
          if !@core.all(rows, fn(row) { @core.all(row, nonnegative) }) {
            Err(NegativeProbability)
          } else if !@core.all(rows, fn(row) {
              sum(row).equal(@exact.rational_one())
            }) {
            Err(NotNormalized)
          } else {
            Ok({ transition, })
          }
      }
  }
}

///|
pub fn states(value : Kernel) -> @core.Nat {
  @matrix.width(value.transition)
}

///|
/// Immutable matrix view; this does not permit constructing an unchecked Kernel.
pub fn transitions(value : Kernel) -> @matrix.Matrix[@exact.Rational] {
  value.transition
}

///|
fn adopt(
  value : @matrix.Matrix[@exact.Rational],
) -> Result[Kernel, MarkovError] {
  match kernel(@matrix.rows(value)) {
    Ok(value) => Ok(value)
    Err(_) => Err(InternalInvariant)
  }
}

///|
pub fn identity(count : @core.Nat) -> Result[Kernel, MarkovError] {
  match count {
    Zero => Err(EmptyStateSpace)
    Succ(_) => adopt(@matrix.identity(count, @algebra.rationals()))
  }
}

///|
fn scaled_add(
  scalar : @exact.Rational,
  row : @core.Chain[@exact.Rational],
  accumulator : @core.Chain[@exact.Rational],
) -> @core.Chain[@exact.Rational]? {
  match (row, accumulator) {
    (Nil, Nil) => Some(Nil)
    (Cons(value, rest), Cons(previous, tail)) =>
      match scaled_add(scalar, rest, tail) {
        None => None
        Some(values) =>
          Some(
            Cons(
              @exact.rational_add(
                @exact.rational_multiply(scalar, value),
                previous,
              ),
              values,
            ),
          )
      }
    _ => None
  }
}

///|
/// Linear action, also used with signed stationary directions internally.
fn row_action(
  value : Kernel,
  coefficients : @core.Chain[@exact.Rational],
) -> @core.Chain[@exact.Rational]? {
  fn walk(
    rows : @core.Chain[@core.Chain[@exact.Rational]],
    weights : @core.Chain[@exact.Rational],
  ) -> @core.Chain[@exact.Rational]? {
    match (rows, weights) {
      (Nil, Nil) => Some(@core.replicate(states(value), @exact.rational_zero()))
      (Cons(row, rest), Cons(weight, tail)) =>
        match walk(rest, tail) {
          None => None
          Some(accumulator) => scaled_add(weight, row, accumulator)
        }
      _ => None
    }
  }
  walk(@matrix.rows(value.transition), coefficients)
}

///|
pub fn evolve(
  value : Kernel,
  distribution : @core.Chain[@exact.Rational],
) -> Result[@core.Chain[@exact.Rational], MarkovError] {
  match probability(states(value), distribution) {
    Err(error) => Err(error)
    Ok(_) =>
      match row_action(value, distribution) {
        None => Err(InternalInvariant)
        Some(result) =>
          match probability(states(value), result) {
            Err(_) => Err(InternalInvariant)
            Ok(_) => Ok(result)
          }
      }
  }
}

///|
/// Apply first, then second: mu -> (mu first) second.
pub fn compose(first : Kernel, second : Kernel) -> Result[Kernel, MarkovError] {
  if !states(first).equal(states(second)) {
    Err(DimensionMismatch)
  } else {
    match
      @matrix.multiply(
        first.transition,
        second.transition,
        @algebra.rationals(),
      ) {
      None => Err(InternalInvariant)
      Some(result) => adopt(result)
    }
  }
}

///|
/// Exact exponentiation; exponent zero is the identity, including periodic chains.
pub fn power(
  value : Kernel,
  exponent : @binary.Binary,
) -> Result[Kernel, MarkovError] {
  match @matrix.power(value.transition, exponent, @algebra.rationals()) {
    None => Err(InternalInvariant)
    Some(result) => adopt(result)
  }
}

///|
pub fn evolve_steps(
  value : Kernel,
  distribution : @core.Chain[@exact.Rational],
  exponent : @binary.Binary,
) -> Result[@core.Chain[@exact.Rational], MarkovError] {
  match probability(states(value), distribution) {
    Err(error) => Err(error)
    Ok(_) =>
      match power(value, exponent) {
        Err(error) => Err(error)
        Ok(iterated) => evolve(iterated, distribution)
      }
  }
}
