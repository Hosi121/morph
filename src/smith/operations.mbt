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
/// Traverse the stored rows directly. Validate the retained width even when
/// there are no rows, so zero-by-n matrices retain column-index semantics.
fn update_columns(
  input : @matrix.Matrix[@exact.Integer],
  a : @core.Nat,
  b : @core.Nat,
  update : (@core.Chain[@exact.Integer]) -> @core.Chain[@exact.Integer]?,
) -> @matrix.Matrix[@exact.Integer]? {
  fn walk(
    rows : @core.Chain[@core.Chain[@exact.Integer]],
  ) -> @core.Chain[@core.Chain[@exact.Integer]]? {
    match rows {
      Nil => Some(Nil)
      Cons(row, rest) =>
        match (update(row), walk(rest)) {
          (Some(row), Some(rest)) => Some(Cons(row, rest))
          _ => None
        }
    }
  }
  match
    (
      @core.compare(a, @matrix.width(input)),
      @core.compare(b, @matrix.width(input)),
    ) {
    (Less, Less) =>
      match walk(@matrix.rows(input)) {
        Some(rows) => @matrix.matrix(@matrix.width(input), rows)
        None => None
      }
    _ => None
  }
}

///|
fn column_swap(
  input : @matrix.Matrix[@exact.Integer],
  a : @core.Nat,
  b : @core.Nat,
) -> @matrix.Matrix[@exact.Integer]? {
  update_columns(input, a, b, fn(row) {
    match (@core.nth(row, a), @core.nth(row, b)) {
      (Some(x), Some(y)) =>
        match replace(row, a, y) {
          Some(row) => replace(row, b, x)
          None => None
        }
      _ => None
    }
  })
}

///|
fn column_add(
  input : @matrix.Matrix[@exact.Integer],
  target : @core.Nat,
  source : @core.Nat,
  factor : @exact.Integer,
) -> @matrix.Matrix[@exact.Integer]? {
  update_columns(input, target, source, fn(row) {
    match (@core.nth(row, target), @core.nth(row, source)) {
      (Some(x), Some(y)) =>
        replace(row, target, @exact.add(x, @exact.multiply(factor, y)))
      _ => None
    }
  })
}
