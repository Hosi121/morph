///|
/// Fixed Boolean arithmetic removes scalar callback dispatch from each term.
fn product_dot(left : @core.Chain[Bool], right : @core.Chain[Bool]) -> Bool {
  match (left, right) {
    (Cons(x, xs), Cons(y, ys)) => xor(x && y, product_dot(xs, ys))
    _ => false
  }
}

///|
fn product_peel(
  rows : @core.Chain[@core.Chain[Bool]],
) -> (@core.Chain[Bool], @core.Chain[@core.Chain[Bool]]) {
  match rows {
    Nil => (Nil, Nil)
    Cons(Cons(x, xs), rest) => {
      let (heads, tails) = product_peel(rest)
      (Cons(x, heads), Cons(xs, tails))
    }
    Cons(Nil, rest) => product_peel(rest)
  }
}

///|
fn product_columns(
  width : @core.Nat,
  rows : @core.Chain[@core.Chain[Bool]],
) -> @core.Chain[@core.Chain[Bool]] {
  match width {
    Zero => Nil
    Succ(rest) => {
      let (heads, tails) = product_peel(rows)
      Cons(heads, product_columns(rest, tails))
    }
  }
}

///|
fn product_row(
  row : @core.Chain[Bool],
  columns : @core.Chain[@core.Chain[Bool]],
) -> @core.Chain[Bool] {
  match columns {
    Nil => Nil
    Cons(column, rest) => Cons(product_dot(row, column), product_row(row, rest))
  }
}

///|
fn product_rows(
  rows : @core.Chain[@core.Chain[Bool]],
  columns : @core.Chain[@core.Chain[Bool]],
) -> @core.Chain[@core.Chain[Bool]] {
  match rows {
    Nil => Nil
    Cons(row, rest) =>
      Cons(product_row(row, columns), product_rows(rest, columns))
  }
}

///|
fn boolean_product(
  a : @matrix.Matrix[Bool],
  b : @matrix.Matrix[Bool],
) -> @matrix.Matrix[Bool]? {
  match @core.compare(@matrix.width(a), @matrix.height(b)) {
    Equal =>
      @matrix.matrix(
        @matrix.width(b),
        product_rows(
          @matrix.rows(a),
          product_columns(@matrix.width(b), @matrix.rows(b)),
        ),
      )
    _ => None
  }
}
