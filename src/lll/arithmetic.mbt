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
fn half() -> @exact.Rational {
  @exact.rational_half(@exact.rational_one())
}

///|
fn delta() -> @exact.Rational {
  @exact.rational_add(half(), @exact.rational_half(half()))
}

///|
/// Nearest integer, with ties away from zero. No floating representation.
fn nearest(value : @exact.Rational) -> @exact.Integer {
  let numerator = @exact.numerator(value)
  let denominator = @exact.denominator(value)
  match @binary.divmod(@exact.magnitude(numerator), denominator) {
    None => @exact.positive(@binary.zero())
    Some((q, remainder)) => {
      let magnitude = match
        @binary.compare(@binary.double(remainder), denominator) {
        Less => q
        _ => @binary.successor(q)
      }
      let positive = @exact.positive(magnitude)
      match @exact.negative(numerator) {
        false => positive
        true => @exact.negate(positive)
      }
    }
  }
}

///|
fn size_bounded(value : @exact.Rational) -> Bool {
  match
    @binary.compare(
      @binary.double(@exact.magnitude(@exact.numerator(value))),
      @exact.denominator(value),
    ) {
    Greater => false
    _ => true
  }
}

///|
fn dot(
  xs : @core.Chain[@exact.Rational],
  ys : @core.Chain[@exact.Rational],
) -> @exact.Rational? {
  match @core.zip(xs, ys) {
    None => None
    Some(pairs) =>
      Some(
        @core.fold_left(pairs, @exact.rational_zero(), fn(sum, pair) {
          let (x, y) = pair
          @exact.rational_add(sum, @exact.rational_multiply(x, y))
        }),
      )
  }
}

///|
fn subtract_projection(
  current : @core.Chain[@exact.Rational],
  star : @core.Chain[@exact.Rational],
  coefficient : @exact.Rational,
) -> @core.Chain[@exact.Rational]? {
  match @core.zip(current, star) {
    None => None
    Some(pairs) =>
      Some(
        @core.map(pairs, fn(pair) {
          let (x, y) = pair
          @exact.rational_subtract(x, @exact.rational_multiply(coefficient, y))
        }),
      )
  }
}

///|
fn add_projection(
  current : @core.Chain[@exact.Rational],
  star : @core.Chain[@exact.Rational],
  coefficient : @exact.Rational,
) -> @core.Chain[@exact.Rational]? {
  match @core.zip(current, star) {
    None => None
    Some(pairs) =>
      Some(
        @core.map(pairs, fn(pair) {
          let (x, y) = pair
          @exact.rational_add(x, @exact.rational_multiply(coefficient, y))
        }),
      )
  }
}

///|
fn[A] replace(
  items : @core.Chain[A],
  index : @core.Nat,
  value : A,
) -> @core.Chain[A]? {
  match (items, index) {
    (Cons(_, rest), Zero) => Some(Cons(value, rest))
    (Cons(item, rest), Succ(index)) =>
      match replace(rest, index, value) {
        Some(rest) => Some(Cons(item, rest))
        None => None
      }
    _ => None
  }
}

///|
fn row_swap(
  input : @matrix.Matrix[@exact.Integer],
  i : @core.Nat,
  j : @core.Nat,
) -> @matrix.Matrix[@exact.Integer]? {
  let rows = @matrix.rows(input)
  match (@core.nth(rows, i), @core.nth(rows, j)) {
    (Some(x), Some(y)) =>
      match replace(rows, i, y) {
        Some(rows) =>
          match replace(rows, j, x) {
            Some(rows) => @matrix.matrix(@matrix.width(input), rows)
            None => None
          }
        None => None
      }
    _ => None
  }
}

///|
fn row_reduce(
  input : @matrix.Matrix[@exact.Integer],
  target : @core.Nat,
  source : @core.Nat,
  q : @exact.Integer,
) -> @matrix.Matrix[@exact.Integer]? {
  let rows = @matrix.rows(input)
  match (@core.nth(rows, target), @core.nth(rows, source)) {
    (Some(x), Some(y)) =>
      match @core.zip(x, y) {
        None => None
        Some(pairs) => {
          let row = @core.map(pairs, fn(pair) {
            let (x, y) = pair
            @exact.subtract(x, @exact.multiply(q, y))
          })
          match replace(rows, target, row) {
            Some(rows) => @matrix.matrix(@matrix.width(input), rows)
            None => None
          }
        }
      }
    _ => None
  }
}
