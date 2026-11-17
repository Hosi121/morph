///|
fn integers() -> @algebra.Semiring[@exact.Integer] {
  {
    zero: @exact.positive(@binary.zero()),
    one: @exact.positive(@binary.one()),
    plus: @exact.add,
    times: @exact.multiply,
  }
}

///|
fn inverse_pair(
  a : @matrix.Matrix[@exact.Integer],
  b : @matrix.Matrix[@exact.Integer],
) -> Bool {
  let identity = @matrix.identity(@matrix.width(a), integers())
  @matrix.height(a).equal(@matrix.width(a)) &&
  @matrix.multiply(a, b, integers()).equal(Some(identity)) &&
  @matrix.multiply(b, a, integers()).equal(Some(identity))
}

///|
fn integer_inverse(
  input : @matrix.Matrix[@exact.Integer],
) -> @matrix.Matrix[@exact.Integer]? {
  fn integral_row(
    row : @core.Chain[@exact.Rational],
  ) -> @core.Chain[@exact.Integer]? {
    match row {
      Nil => Some(Nil)
      Cons(value, rest) =>
        match
          (
            @binary.compare(@exact.denominator(value), @binary.one()),
            integral_row(rest),
          ) {
          (Equal, Some(rest)) => Some(Cons(@exact.numerator(value), rest))
          _ => None
        }
    }
  }
  fn integral_rows(
    rows : @core.Chain[@core.Chain[@exact.Rational]],
  ) -> @core.Chain[@core.Chain[@exact.Integer]]? {
    match rows {
      Nil => Some(Nil)
      Cons(row, rest) =>
        match (integral_row(row), integral_rows(rest)) {
          (Some(row), Some(rest)) => Some(Cons(row, rest))
          _ => None
        }
    }
  }
  let rational = @matrix.matrix(
    @matrix.width(input),
    @core.map(@matrix.rows(input), fn(row) { @core.map(row, @exact.whole) }),
  )
  match rational {
    None => None
    Some(rational) =>
      match @linear.inverse(rational) {
        None => None
        Some(inverse) =>
          match integral_rows(@matrix.rows(inverse)) {
            None => None
            Some(rows) =>
              match @matrix.matrix(@matrix.width(inverse), rows) {
                Some(candidate) =>
                  match inverse_pair(input, candidate) {
                    true => Some(candidate)
                    false => None
                  }
                None => None
              }
          }
      }
  }
}

///|
fn apply_matrix(
  matrix : @matrix.Matrix[@exact.Integer],
  vector : @core.Chain[@exact.Integer],
) -> @core.Chain[@exact.Integer]? {
  match @matrix.matrix(Succ(Zero), @core.map(vector, fn(x) { Cons(x, Nil) })) {
    None => None
    Some(column) =>
      match @matrix.multiply(matrix, column, integers()) {
        None => None
        Some(product) => @matrix.column(product, Zero)
      }
  }
}

///|
fn bottom(
  matrix : @matrix.Matrix[@exact.Integer],
  rank : @core.Nat,
) -> @matrix.Matrix[@exact.Integer]? {
  @matrix.matrix(@matrix.width(matrix), @core.drop(rank, @matrix.rows(matrix)))
}

///|
fn leading_zero(
  matrix : @matrix.Matrix[@exact.Integer],
  rank : @core.Nat,
) -> Bool {
  @core.all(@core.take(rank, @matrix.rows(matrix)), fn(row) {
    @core.all(row, fn(x) { @binary.is_zero(@exact.magnitude(x)) })
  })
}
