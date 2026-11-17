///|
/// A probability vector on a nonempty, ordered finite sample space.
/// Zero masses are permitted. Construction checks nonnegativity and total one.
#derive(Eq, Debug)
pub struct Distribution {
  masses : @core.Chain[@exact.Rational]
}

///|
pub extend Distribution with Eq::{equal, not_equal}

///|
pub extend Distribution with Debug::{to_repr}

///|
fn nonnegative(value : @exact.Rational) -> Bool {
  !@exact.negative(@exact.numerator(value))
}

///|
fn total(values : @core.Chain[@exact.Rational]) -> @exact.Rational {
  @core.fold_left(values, @exact.rational_zero(), @exact.rational_add)
}

///|
pub fn distribution(masses : @core.Chain[@exact.Rational]) -> Distribution? {
  match masses {
    Nil => None
    Cons(_, _) =>
      match
        @core.all(masses, nonnegative) &&
        total(masses).equal(@exact.rational_one()) {
        true => Some({ masses, })
        false => None
      }
  }
}

///|
/// Normalize nonnegative weights. The all-zero measure has no distribution.
pub fn normalize(weights : @core.Chain[@exact.Rational]) -> Distribution? {
  match @core.all(weights, nonnegative) {
    false => None
    true =>
      match @exact.nonzero(total(weights)) {
        None => None
        Some(mass) => {
          let inverse = @exact.reciprocal(mass)
          Some({
            masses: @core.map(weights, fn(value) {
              @exact.rational_multiply(value, inverse)
            }),
          })
        }
      }
  }
}

///|
pub fn masses(distribution : Distribution) -> @core.Chain[@exact.Rational] {
  distribution.masses
}

///|
pub fn size(distribution : Distribution) -> @core.Nat {
  @core.length(distribution.masses)
}

///|
pub fn mass(distribution : Distribution, index : @core.Nat) -> @exact.Rational? {
  @core.nth(distribution.masses, index)
}

///|
/// Strict positivity is checked separately from the closed-simplex invariant.
pub fn is_interior(distribution : Distribution) -> Bool {
  @core.all(distribution.masses, fn(value) { @exact.nonzero(value) is Some(_) })
}

///|
pub fn uniform(size : @core.Nat) -> Distribution? {
  match size {
    Zero => None
    Succ(_) => {
      let count = @exact.whole(@exact.positive(@binary.from_nat(size)))
      match @exact.nonzero(count) {
        None => None
        Some(nonzero) =>
          Some({ masses: @core.replicate(size, @exact.reciprocal(nonzero)), })
      }
    }
  }
}

///|
/// The outcome order is failure, success.
pub fn bernoulli(success : @exact.Rational) -> Distribution? {
  distribution(
    Cons(
      @exact.rational_subtract(@exact.rational_one(), success),
      Cons(success, Nil),
    ),
  )
}

///|
pub fn expectation(
  distribution : Distribution,
  values : @core.Chain[@exact.Rational],
) -> @exact.Rational? {
  match @core.zip(distribution.masses, values) {
    None => None
    Some(pairs) =>
      Some(
        @core.fold_left(pairs, @exact.rational_zero(), fn(sum, pair) {
          let (left, right) = pair
          @exact.rational_add(sum, @exact.rational_multiply(left, right))
        }),
      )
  }
}

///|
pub fn covariance(
  distribution : Distribution,
  left : @core.Chain[@exact.Rational],
  right : @core.Chain[@exact.Rational],
) -> @exact.Rational? {
  match
    (
      expectation(distribution, left),
      expectation(distribution, right),
      @core.zip(left, right),
    ) {
    (Some(l), Some(r), Some(pairs)) =>
      expectation(
        distribution,
        @core.map(pairs, fn(pair) {
          let (left, right) = pair
          @exact.rational_multiply(
            @exact.rational_subtract(left, l),
            @exact.rational_subtract(right, r),
          )
        }),
      )
    _ => None
  }
}

///|
pub fn variance(
  distribution : Distribution,
  values : @core.Chain[@exact.Rational],
) -> @exact.Rational? {
  covariance(distribution, values, values)
}

///|
pub fn event_probability(
  distribution : Distribution,
  event : @core.Chain[Bool],
) -> @exact.Rational? {
  match @core.zip(distribution.masses, event) {
    None => None
    Some(pairs) =>
      Some(
        @core.fold_left(pairs, @exact.rational_zero(), fn(sum, pair) {
          let (left, right) = pair
          match right {
            false => sum
            true => @exact.rational_add(sum, left)
          }
        }),
      )
  }
}

///|
/// Keep the original outcome order, including zeros outside the event.
pub fn condition(
  distribution : Distribution,
  event : @core.Chain[Bool],
) -> Distribution? {
  match @core.zip(distribution.masses, event) {
    None => None
    Some(pairs) =>
      normalize(
        @core.map(pairs, fn(pair) {
          let (left, right) = pair
          match right {
            true => left
            false => @exact.rational_zero()
          }
        }),
      )
  }
}

///|
/// Likelihoods may be any nonnegative weights; impossible evidence is rejected.
pub fn bayes(
  prior : Distribution,
  likelihoods : @core.Chain[@exact.Rational],
) -> Distribution? {
  match @core.zip(prior.masses, likelihoods) {
    None => None
    Some(pairs) =>
      match @core.all(likelihoods, nonnegative) {
        false => None
        true =>
          normalize(
            @core.map(pairs, fn(pair) {
              let (left, right) = pair
              @exact.rational_multiply(left, right)
            }),
          )
      }
  }
}

///|
/// Weight is the proportion of the right distribution.
pub fn mixture(
  left : Distribution,
  right : Distribution,
  weight : @exact.Rational,
) -> Distribution? {
  match
    nonnegative(weight) &&
    nonnegative(@exact.rational_subtract(@exact.rational_one(), weight)) {
    false => None
    true =>
      match @core.zip(left.masses, right.masses) {
        None => None
        Some(pairs) => {
          let complement = @exact.rational_subtract(
            @exact.rational_one(),
            weight,
          )
          Some({
            masses: @core.map(pairs, fn(pair) {
              let (left, right) = pair
              @exact.rational_add(
                @exact.rational_multiply(complement, left),
                @exact.rational_multiply(weight, right),
              )
            }),
          })
        }
      }
  }
}

///|
/// Independent product, with the right index varying fastest.
pub fn product(left : Distribution, right : Distribution) -> Distribution {
  {
    masses: @core.fold_left(left.masses, Nil, fn(reversed, l) {
      @core.fold_left(right.masses, reversed, fn(reversed, r) {
        Cons(@exact.rational_multiply(l, r), reversed)
      })
    })
    |> @core.reverse,
  }
}

///|
fn add_at(
  values : @core.Chain[@exact.Rational],
  index : @core.Nat,
  mass : @exact.Rational,
) -> @core.Chain[@exact.Rational]? {
  match (values, index) {
    (Nil, _) => None
    (Cons(value, rest), Zero) =>
      Some(Cons(@exact.rational_add(value, mass), rest))
    (Cons(value, rest), Succ(index)) =>
      match add_at(rest, index, mass) {
        None => None
        Some(rest) => Some(Cons(value, rest))
      }
  }
}

///|
fn push_masses(
  masses : @core.Chain[@exact.Rational],
  mapping : @core.Chain[@core.Nat],
  accumulated : @core.Chain[@exact.Rational],
) -> @core.Chain[@exact.Rational]? {
  match (masses, mapping) {
    (Nil, Nil) => Some(accumulated)
    (Cons(mass, masses), Cons(index, mapping)) =>
      match add_at(accumulated, index, mass) {
        None => None
        Some(accumulated) => push_masses(masses, mapping, accumulated)
      }
    _ => None
  }
}

///|
/// Deterministic pushforward, including marginalization/coarse graining.
/// Every source outcome needs a valid destination, even when its mass is zero.
pub fn pushforward(
  distribution : Distribution,
  output_size : @core.Nat,
  mapping : @core.Chain[@core.Nat],
) -> Distribution? {
  match output_size {
    Zero => None
    Succ(_) =>
      match
        push_masses(
          distribution.masses,
          mapping,
          @core.replicate(output_size, @exact.rational_zero()),
        ) {
        None => None
        Some(masses) => Some({ masses, })
      }
  }
}

///|
fn absolute(value : @exact.Rational) -> @exact.Rational {
  match nonnegative(value) {
    true => value
    false => @exact.rational_negate(value)
  }
}

///|
pub fn total_variation(
  left : Distribution,
  right : Distribution,
) -> @exact.Rational? {
  match @core.zip(left.masses, right.masses) {
    None => None
    Some(pairs) =>
      Some(
        @exact.rational_half(
          @core.fold_left(pairs, @exact.rational_zero(), fn(sum, pair) {
            let (left, right) = pair
            @exact.rational_add(
              sum,
              absolute(@exact.rational_subtract(left, right)),
            )
          }),
        ),
      )
  }
}
