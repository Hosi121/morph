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
fn zero(value : @exact.Integer) -> Bool {
  @binary.is_zero(@exact.magnitude(value))
}

///|
fn divides(divisor : @binary.Binary, value : @binary.Binary) -> Bool {
  match @binary.divmod(value, divisor) {
    Some((_, remainder)) => @binary.is_zero(remainder)
    None => @binary.is_zero(value)
  }
}

///|
fn quotient(a : @exact.Integer, b : @exact.Integer) -> @exact.Integer? {
  match @binary.divmod(@exact.magnitude(a), @exact.magnitude(b)) {
    None => None
    Some((q, _)) => {
      let positive = @exact.positive(q)
      Some(
        match (@exact.negative(a), @exact.negative(b)) {
          (true, false) | (false, true) => @exact.negate(positive)
          _ => positive
        },
      )
    }
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
fn cell(
  input : @matrix.Matrix[@exact.Integer],
  row : @core.Nat,
  col : @core.Nat,
) -> @exact.Integer? {
  match @core.nth(@matrix.rows(input), row) {
    Some(row) => @core.nth(row, col)
    None => None
  }
}

///|
fn row_swap(
  input : @matrix.Matrix[@exact.Integer],
  a : @core.Nat,
  b : @core.Nat,
) -> @matrix.Matrix[@exact.Integer]? {
  let rows = @matrix.rows(input)
  match (@core.nth(rows, a), @core.nth(rows, b)) {
    (Some(x), Some(y)) =>
      match replace(rows, a, y) {
        Some(rows) =>
          match replace(rows, b, x) {
            Some(rows) => @matrix.matrix(@matrix.width(input), rows)
            None => None
          }
        None => None
      }
    _ => None
  }
}

///|
fn row_add(
  input : @matrix.Matrix[@exact.Integer],
  target : @core.Nat,
  source : @core.Nat,
  factor : @exact.Integer,
) -> @matrix.Matrix[@exact.Integer]? {
  let rows = @matrix.rows(input)
  match (@core.nth(rows, target), @core.nth(rows, source)) {
    (Some(x), Some(y)) =>
      match @core.zip(x, y) {
        Some(pairs) => {
          let row = @core.map(pairs, fn(pair) {
            let (x, y) = pair
            @exact.add(x, @exact.multiply(factor, y))
          })
          match replace(rows, target, row) {
            Some(rows) => @matrix.matrix(@matrix.width(input), rows)
            None => None
          }
        }
        None => None
      }
    _ => None
  }
}

///|
fn row_negate(
  input : @matrix.Matrix[@exact.Integer],
  target : @core.Nat,
) -> @matrix.Matrix[@exact.Integer]? {
  let rows = @matrix.rows(input)
  match @core.nth(rows, target) {
    Some(row) =>
      match replace(rows, target, @core.map(row, @exact.negate)) {
        Some(rows) => @matrix.matrix(@matrix.width(input), rows)
        None => None
      }
    None => None
  }
}

///|
fn column_swap(
  input : @matrix.Matrix[@exact.Integer],
  a : @core.Nat,
  b : @core.Nat,
) -> @matrix.Matrix[@exact.Integer]? {
  match row_swap(@matrix.transpose(input), a, b) {
    Some(transposed) => Some(@matrix.transpose(transposed))
    None => None
  }
}

///|
fn column_add(
  input : @matrix.Matrix[@exact.Integer],
  target : @core.Nat,
  source : @core.Nat,
  factor : @exact.Integer,
) -> @matrix.Matrix[@exact.Integer]? {
  match row_add(@matrix.transpose(input), target, source, factor) {
    Some(transposed) => Some(@matrix.transpose(transposed))
    None => None
  }
}
