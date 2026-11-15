///|
/// Laws are a caller obligation: associative plus/times, distributivity,
/// additive zero, multiplicative one, and an absorbing zero for times.
pub(all) struct Semiring[A] {
  zero : A
  one : A
  plus : (A, A) -> A
  times : (A, A) -> A
}

///|
pub fn booleans() -> Semiring[Bool] {
  {
    zero: false,
    one: true,
    plus: fn(a, b) {
      match a {
        true => true
        false => b
      }
    },
    times: fn(a, b) {
      match a {
        true => b
        false => false
      }
    },
  }
}

///|
pub fn naturals() -> Semiring[@binary.Binary] {
  {
    zero: @binary.zero(),
    one: @binary.one(),
    plus: @binary.add,
    times: @binary.multiply,
  }
}

///|
pub fn rationals() -> Semiring[@exact.Rational] {
  {
    zero: @exact.rational_zero(),
    one: @exact.rational_one(),
    plus: @exact.rational_add,
    times: @exact.rational_multiply,
  }
}

///|
#derive(Eq, Debug)
pub(all) enum Distance {
  Infinity
  Finite(@binary.Binary)
}

///|
pub extend Distance with Eq::{equal, not_equal}

///|
pub extend Distance with Debug::{to_repr}

///|
/// The min-plus semiring over nonnegative binary distances.
pub fn tropical() -> Semiring[Distance] {
  {
    zero: Infinity,
    one: Finite(@binary.zero()),
    plus: fn(a, b) {
      match (a, b) {
        (Infinity, _) => b
        (_, Infinity) => a
        (Finite(x), Finite(y)) =>
          match @binary.compare(x, y) {
            Greater => b
            _ => a
          }
      }
    },
    times: fn(a, b) {
      match (a, b) {
        (Finite(x), Finite(y)) => Finite(@binary.add(x, y))
        _ => Infinity
      }
    },
  }
}
