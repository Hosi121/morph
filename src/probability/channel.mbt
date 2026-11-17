///|
/// A finite stochastic map. Rows are input outcomes, columns output outcomes.
/// Input/output sample spaces are nonempty and may have different sizes.
#derive(Eq, Debug)
pub struct Channel {
  rows : @core.Chain[Distribution]
  output_size : @core.Nat
}

///|
pub extend Channel with Eq::{equal, not_equal}

///|
pub extend Channel with Debug::{to_repr}

///|
pub fn channel(rows : @core.Chain[Distribution]) -> Channel? {
  match rows {
    Nil => None
    Cons(first, _) => {
      let output_size = size(first)
      match @core.all(rows, fn(row) { size(row).equal(output_size) }) {
        false => None
        true => Some({ rows, output_size, })
      }
    }
  }
}

///|
pub fn channel_rows(channel : Channel) -> @core.Chain[Distribution] {
  channel.rows
}

///|
pub fn input_size(channel : Channel) -> @core.Nat {
  @core.length(channel.rows)
}

///|
pub fn output_size(channel : Channel) -> @core.Nat {
  channel.output_size
}

///|
fn weighted_add(
  weight : @exact.Rational,
  row : @core.Chain[@exact.Rational],
  values : @core.Chain[@exact.Rational],
) -> @core.Chain[@exact.Rational] {
  match (row, values) {
    (Cons(a, row), Cons(b, values)) =>
      Cons(
        @exact.rational_add(@exact.rational_multiply(weight, a), b),
        weighted_add(weight, row, values),
      )
    _ => Nil
  }
}

///|
pub fn apply(channel : Channel, input : Distribution) -> Distribution? {
  match @core.zip(input.masses, channel.rows) {
    None => None
    Some(pairs) =>
      Some({
        masses: @core.fold_left(
          pairs,
          @core.replicate(channel.output_size, @exact.rational_zero()),
          fn(sum, pair) {
            let (weight, row) = pair
            weighted_add(weight, row.masses, sum)
          },
        ),
      })
  }
}

///|
fn apply_rows(
  channel : Channel,
  rows : @core.Chain[Distribution],
) -> @core.Chain[Distribution]? {
  match rows {
    Nil => Some(Nil)
    Cons(row, rest) =>
      match (apply(channel, row), apply_rows(channel, rest)) {
        (Some(row), Some(rest)) => Some(Cons(row, rest))
        _ => None
      }
  }
}

///|
/// Apply first, then second. The intermediate sample-space sizes must agree.
pub fn compose_channels(first : Channel, second : Channel) -> Channel? {
  match apply_rows(second, first.rows) {
    None => None
    Some(rows) => channel(rows)
  }
}

///|
/// Posterior over input outcomes after observing one output outcome.
pub fn posterior(
  channel : Channel,
  prior : Distribution,
  output : @core.Nat,
) -> Distribution? {
  fn column(rows : @core.Chain[Distribution]) -> @core.Chain[@exact.Rational]? {
    match rows {
      Nil => Some(Nil)
      Cons(row, rest) =>
        match (mass(row, output), column(rest)) {
          (Some(value), Some(rest)) => Some(Cons(value, rest))
          _ => None
        }
    }
  }
  match column(channel.rows) {
    None => None
    Some(likelihoods) => bayes(prior, likelihoods)
  }
}

///|
/// Reverse channel for a fixed prior. All output events must have positive mass.
/// A zero-mass output has no unique Bayesian posterior and is rejected.
pub fn bayesian_inverse(source : Channel, prior : Distribution) -> Channel? {
  fn rows(indices : @core.Chain[@core.Nat]) -> @core.Chain[Distribution]? {
    match indices {
      Nil => Some(Nil)
      Cons(index, rest) =>
        match (posterior(source, prior, index), rows(rest)) {
          (Some(row), Some(rest)) => Some(Cons(row, rest))
          _ => None
        }
    }
  }
  match rows(@core.indices(source.output_size)) {
    None => None
    Some(rows) => channel(rows)
  }
}
