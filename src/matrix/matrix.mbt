///|
/// Width is retained even when there are no rows (so zero dimensions work).
#derive(Eq, Debug)
pub struct Matrix[A] {
  width : @core.Nat
  rows : @core.Chain[@core.Chain[A]]
}

///|
pub extend Matrix with Eq::{equal, not_equal}

///|
pub extend Matrix with Debug::{to_repr}

///|
pub fn[A] matrix(
  width : @core.Nat,
  rows : @core.Chain[@core.Chain[A]],
) -> Matrix[A]? {
  fn valid(rows : @core.Chain[@core.Chain[A]]) -> Bool {
    match rows {
      Nil => true
      Cons(row, tail) =>
        match @core.compare(@core.length(row), width) {
          Equal => valid(tail)
          _ => false
        }
    }
  }
  match valid(rows) {
    true => Some({ width, rows, })
    false => None
  }
}

///|
pub fn[A] rows(m : Matrix[A]) -> @core.Chain[@core.Chain[A]] {
  m.rows
}

///|
pub fn[A] width(m : Matrix[A]) -> @core.Nat {
  m.width
}

///|
pub fn[A] height(m : Matrix[A]) -> @core.Nat {
  @core.length(m.rows)
}

///|
/// Only called with nonempty rows, guaranteed by the stored width.
fn[A] peel(
  rows : @core.Chain[@core.Chain[A]],
) -> (@core.Chain[A], @core.Chain[@core.Chain[A]]) {
  match rows {
    Nil => (Nil, Nil)
    Cons(Cons(x, rest), tail) => {
      let (heads, tails) = peel(tail)
      (Cons(x, heads), Cons(rest, tails))
    }
    Cons(Nil, tail) => peel(tail)
  }
}

///|
fn[A] columns(
  n : @core.Nat,
  rows : @core.Chain[@core.Chain[A]],
) -> @core.Chain[@core.Chain[A]] {
  match n {
    Zero => Nil
    Succ(rest) => {
      let (heads, tails) = peel(rows)
      Cons(heads, columns(rest, tails))
    }
  }
}

///|
pub fn[A] transpose(m : Matrix[A]) -> Matrix[A] {
  { width: @core.length(m.rows), rows: columns(m.width, m.rows), }
}

///|
/// Extract just one column, instead of allocating a complete transpose.
pub fn[A] column(m : Matrix[A], index : @core.Nat) -> @core.Chain[A]? {
  fn collect(rows : @core.Chain[@core.Chain[A]]) -> @core.Chain[A]? {
    match rows {
      Nil => Some(Nil)
      Cons(row, rest) =>
        match (@core.nth(row, index), collect(rest)) {
          (Some(value), Some(tail)) => Some(Cons(value, tail))
          _ => None
        }
    }
  }
  match @core.compare(index, m.width) {
    Less => collect(m.rows)
    _ => None
  }
}

///|
fn[A] dot(
  xs : @core.Chain[A],
  ys : @core.Chain[A],
  ops : @algebra.Semiring[A],
) -> A {
  match (xs, ys) {
    (Cons(x, xt), Cons(y, yt)) =>
      (ops.plus)((ops.times)(x, y), dot(xt, yt, ops))
    _ => ops.zero
  }
}

///|
fn[A] multiply_known(
  a : Matrix[A],
  b : Matrix[A],
  ops : @algebra.Semiring[A],
) -> Matrix[A] {
  let cols = columns(b.width, b.rows)
  {
    width: b.width,
    rows: @core.map(a.rows, fn(row) {
      @core.map(cols, fn(col) { dot(row, col, ops) })
    }),
  }
}

///|
pub fn[A] multiply(
  a : Matrix[A],
  b : Matrix[A],
  ops : @algebra.Semiring[A],
) -> Matrix[A]? {
  match @core.compare(a.width, @core.length(b.rows)) {
    Equal => Some(multiply_known(a, b, ops))
    _ => None
  }
}

///|
pub fn[A] identity(n : @core.Nat, ops : @algebra.Semiring[A]) -> Matrix[A] {
  fn build(
    todo : @core.Nat,
    prefix : @core.Chain[A],
  ) -> @core.Chain[@core.Chain[A]] {
    match todo {
      Zero => Nil
      Succ(rest) => {
        let row = @core.reverse_onto(
          prefix,
          Cons(ops.one, @core.replicate(rest, ops.zero)),
        )
        Cons(row, build(rest, Cons(ops.zero, prefix)))
      }
    }
  }
  { width: n, rows: build(n, Nil), }
}

///|
pub fn[A] power(
  m : Matrix[A],
  exponent : @binary.Binary,
  ops : @algebra.Semiring[A],
) -> Matrix[A]? {
  fn go(bits : @core.Chain[Bool]) -> Matrix[A] {
    match bits {
      Nil => identity(m.width, ops)
      Cons(bit, rest) => {
        let half = go(rest)
        let square = multiply_known(half, half, ops)
        match bit {
          false => square
          true => multiply_known(m, square, ops)
        }
      }
    }
  }
  match @core.compare(m.width, @core.length(m.rows)) {
    Equal => Some(go(@binary.bits(exponent)))
    _ => None
  }
}

///|
/// Floyd-Warshall recurrence. Valid for Bool reachability and nonnegative
/// min-plus distances; arbitrary semirings do NOT necessarily define a closure.
/// The caller supplies diagonal identities when reflexive closure is desired.
pub fn[A] warshall(m : Matrix[A], ops : @algebra.Semiring[A]) -> Matrix[A]? {
  // All rows have the stored width: the constructor validates this invariant,
  // and every stage preserves it. Fuse zip/map without a pair Chain per cell.
  fn update_row(
    row : @core.Chain[A],
    pivot : @core.Chain[A],
    aik : A,
  ) -> @core.Chain[A] {
    match (row, pivot) {
      (Cons(aij, rest), Cons(akj, pivot_rest)) =>
        Cons(
          (ops.plus)(aij, (ops.times)(aik, akj)),
          update_row(rest, pivot_rest, aik),
        )
      _ => Nil
    }
  }
  fn update_rows(
    rows : @core.Chain[@core.Chain[A]],
    col : @core.Chain[A],
    pivot : @core.Chain[A],
  ) -> @core.Chain[@core.Chain[A]]? {
    match (rows, col) {
      (Nil, Nil) => Some(Nil)
      (Cons(row, rest), Cons(aik, col_rest)) => {
        let updated = update_row(row, pivot, aik)
        match update_rows(rest, col_rest, pivot) {
          Some(tail) => Some(Cons(updated, tail))
          None => None
        }
      }
      _ => None
    }
  }
  fn advance(
    todo : @core.Nat,
    k : @core.Nat,
    current : Matrix[A],
  ) -> Matrix[A]? {
    match todo {
      Zero => Some(current)
      Succ(rest) =>
        match (@core.nth(current.rows, k), column(current, k)) {
          (Some(pivot), Some(col)) =>
            match update_rows(current.rows, col, pivot) {
              Some(updated) =>
                advance(rest, Succ(k), { width: current.width, rows: updated, })
              None => None
            }
          _ => None
        }
    }
  }
  match @core.compare(m.width, @core.length(m.rows)) {
    Equal => advance(m.width, Zero, m)
    _ => None
  }
}
