///|
fn xor(
  a : @core.Chain[@core.Nat],
  b : @core.Chain[@core.Nat],
) -> @core.Chain[@core.Nat] {
  match (a, b) {
    (Nil, _) => b
    (_, Nil) => a
    (Cons(x, xs), Cons(y, ys)) =>
      match @core.compare(x, y) {
        Less => Cons(x, xor(xs, b))
        Equal => xor(xs, ys)
        Greater => Cons(y, xor(a, ys))
      }
  }
}

///|
fn sparse_canonical(xs : @core.Chain[@core.Nat], bound : @core.Nat) -> Bool {
  fn walk(rest : @core.Chain[@core.Nat], previous : @core.Nat) -> Bool {
    match rest {
      Nil => true
      Cons(x, tail) =>
        @core.compare(previous, x) is Less &&
        @core.compare(x, bound) is Less &&
        walk(tail, x)
    }
  }
  match xs {
    Nil => true
    Cons(x, rest) => @core.compare(x, bound) is Less && walk(rest, x)
  }
}

///|
fn linear_combination(
  columns : @core.Chain[@core.Chain[@core.Nat]],
  indices : @core.Chain[@core.Nat],
) -> @core.Chain[@core.Nat]? {
  match indices {
    Nil => Some(Nil)
    Cons(index, rest) =>
      match (@core.nth(columns, index), linear_combination(columns, rest)) {
        (Some(column), Some(tail)) => Some(xor(column, tail))
        _ => None
      }
  }
}

///|
fn unique_pivots(columns : @core.Chain[@core.Chain[@core.Nat]]) -> Bool {
  match columns {
    Nil => true
    Cons(column, rest) => {
      let pivot = @core.last(column)
      match pivot {
        None => unique_pivots(rest)
        Some(_) =>
          !@core.any(rest, fn(other) { @core.last(other).equal(pivot) }) &&
          unique_pivots(rest)
      }
    }
  }
}
