///|
#derive(Eq, Debug)
pub struct Decomposition {
  input : @matrix.Matrix[@exact.Integer]
  left : @matrix.Matrix[@exact.Integer]
  diagonal : @matrix.Matrix[@exact.Integer]
  right : @matrix.Matrix[@exact.Integer]
}

///|
pub extend Decomposition with Eq::{equal, not_equal}

///|
pub extend Decomposition with Debug::{to_repr}

///|
pub fn original(form : Decomposition) -> @matrix.Matrix[@exact.Integer] {
  form.input
}

///|
pub fn left(form : Decomposition) -> @matrix.Matrix[@exact.Integer] {
  form.left
}

///|
pub fn diagonal(form : Decomposition) -> @matrix.Matrix[@exact.Integer] {
  form.diagonal
}

///|
pub fn right(form : Decomposition) -> @matrix.Matrix[@exact.Integer] {
  form.right
}

///|
pub fn invariant_factors(form : Decomposition) -> @core.Chain[@binary.Binary] {
  fn walk(
    rows : @core.Chain[@core.Chain[@exact.Integer]],
    index : @core.Nat,
  ) -> @core.Chain[@binary.Binary] {
    match rows {
      Nil => Nil
      Cons(row, rest) =>
        match @core.nth(row, index) {
          Some(value) => Cons(@exact.magnitude(value), walk(rest, Succ(index)))
          None => Nil
        }
    }
  }
  walk(@matrix.rows(form.diagonal), Zero)
}

///|
pub fn rank(form : Decomposition) -> @core.Nat {
  @core.fold_left(invariant_factors(form), Zero, fn(rank, value) {
    match @binary.is_zero(value) {
      true => rank
      false => Succ(rank)
    }
  })
}

///|
fn unimodular(input : @matrix.Matrix[@exact.Integer]) -> Bool {
  let rows = @core.map(@matrix.rows(input), fn(row) {
    @core.map(row, @exact.whole)
  })
  match @matrix.matrix(@matrix.width(input), rows) {
    None => false
    Some(rationals) =>
      match @linear.determinant(rationals) {
        Some(determinant) =>
          @binary.compare(@exact.denominator(determinant), @binary.one())
          is Equal &&
          @binary.compare(
            @exact.magnitude(@exact.numerator(determinant)),
            @binary.one(),
          )
          is Equal
        None => false
      }
  }
}

///|
fn valid_diagonal(input : @matrix.Matrix[@exact.Integer]) -> Bool {
  fn row_ok(
    row : @core.Chain[@exact.Integer],
    i : @core.Nat,
    j : @core.Nat,
  ) -> Bool {
    match row {
      Nil => true
      Cons(value, rest) => {
        let valid = match @core.compare(i, j) {
          Equal => !@exact.negative(value)
          _ => zero(value)
        }
        valid && row_ok(rest, i, Succ(j))
      }
    }
  }
  fn walk(
    rows : @core.Chain[@core.Chain[@exact.Integer]],
    index : @core.Nat,
    previous : @binary.Binary?,
  ) -> Bool {
    match rows {
      Nil => true
      Cons(row, rest) => {
        let value = @core.nth(row, index)
        let chain = match (previous, value) {
          (Some(before), Some(value)) =>
            divides(before, @exact.magnitude(value))
          _ => true
        }
        row_ok(row, index, Zero) &&
        chain &&
        walk(
          rest,
          Succ(index),
          match value {
            Some(value) => Some(@exact.magnitude(value))
            None => previous
          },
        )
      }
    }
  }
  walk(@matrix.rows(input), Zero, None)
}

///|
/// Independent search-free checker: dimensions, U*A*V=D, determinant U/V in
/// {one, negative one}, and the nonnegative diagonal divisibility chain.
pub fn check(
  input : @matrix.Matrix[@exact.Integer],
  u : @matrix.Matrix[@exact.Integer],
  d : @matrix.Matrix[@exact.Integer],
  v : @matrix.Matrix[@exact.Integer],
) -> Decomposition? {
  let m = @matrix.height(input)
  let n = @matrix.width(input)
  let dimensions = @core.compare(@matrix.height(u), m) is Equal &&
    @core.compare(@matrix.width(u), m) is Equal &&
    @core.compare(@matrix.height(v), n) is Equal &&
    @core.compare(@matrix.width(v), n) is Equal &&
    @core.compare(@matrix.height(d), m) is Equal &&
    @core.compare(@matrix.width(d), n) is Equal
  match dimensions && valid_diagonal(d) && unimodular(u) && unimodular(v) {
    false => None
    true =>
      match @matrix.multiply(u, input, integers()) {
        None => None
        Some(product) =>
          match @matrix.multiply(product, v, integers()) {
            Some(product) =>
              match product.equal(d) {
                true => Some({ input, left: u, diagonal: d, right: v, })
                false => None
              }
            None => None
          }
      }
  }
}
