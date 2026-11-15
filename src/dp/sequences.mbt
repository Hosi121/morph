///|
/// Generic row-by-row dynamic programming, using no numeric column indices.
fn[A, B, C] grid(
  xs : @core.Chain[A],
  ys : @core.Chain[B],
  origin : C,
  row_border : (A, C) -> C,
  column_border : (B, C) -> C,
  cell : (A, B, C, C, C) -> C,
) -> @core.Chain[C] {
  fn initial(ys : @core.Chain[B], start : C) -> @core.Chain[C] {
    match ys {
      Nil => Cons(start, Nil)
      Cons(y, rest) => Cons(start, initial(rest, column_border(y, start)))
    }
  }
  fn next_row(x : A, previous : @core.Chain[C]) -> @core.Chain[C] {
    fn walk(
      ys : @core.Chain[B],
      above : @core.Chain[C],
      diagonal : C,
      left : C,
    ) -> @core.Chain[C] {
      match (ys, above) {
        (Cons(y, yt), Cons(up, ut)) => {
          let value = cell(x, y, diagonal, up, left)
          Cons(value, walk(yt, ut, up, value))
        }
        _ => Nil
      }
    }
    match previous {
      Nil => Nil
      Cons(first, rest) => {
        let start = row_border(x, first)
        Cons(start, walk(ys, rest, first, start))
      }
    }
  }
  @core.fold_left(xs, initial(ys, origin), fn(previous, x) {
    next_row(x, previous)
  })
}

///|
pub fn[A] levenshtein(
  xs : @core.Chain[A],
  ys : @core.Chain[A],
  equal : (A, A) -> Bool,
) -> @core.Nat {
  let row = grid(
    xs,
    ys,
    @core.Zero,
    fn(_, cost) { @core.Succ(cost) },
    fn(_, cost) { @core.Succ(cost) },
    fn(x, y, diagonal, up, left) {
      match equal(x, y) {
        true => diagonal
        false => @core.Succ(@core.minimum(diagonal, @core.minimum(up, left)))
      }
    },
  )
  match @core.last(row) {
    Some(cost) => cost
    None => Zero
  }
}

///|
priv struct Subsequence[A] {
  size : @core.Nat
  reversed : @core.Chain[A]
}

///|
/// A longest common subsequence, with deterministic preference for the upper cell.
pub fn[A] lcs(
  xs : @core.Chain[A],
  ys : @core.Chain[A],
  equal : (A, A) -> Bool,
) -> @core.Chain[A] {
  let empty : Subsequence[A] = { size: Zero, reversed: Nil, }
  let row = grid(
    xs,
    ys,
    empty,
    fn(_, value) { value },
    fn(_, value) { value },
    fn(x, y, diagonal, up, left) {
      match equal(x, y) {
        true =>
          { size: Succ(diagonal.size), reversed: Cons(x, diagonal.reversed), }
        false =>
          match @core.compare(up.size, left.size) {
            Less => left
            _ => up
          }
      }
    },
  )
  match @core.last(row) {
    Some(result) => @core.reverse(result.reversed)
    None => Nil
  }
}

///|
#derive(Eq, Debug)
pub(all) enum Edit[A] {
  Keep(A)
  Insert(A)
  Delete(A)
  Replace(A, A)
}

///|
pub extend Edit with Eq::{equal, not_equal}

///|
pub extend Edit with Debug::{to_repr}

///|
priv struct Script[A] {
  cost : @core.Nat
  reversed : @core.Chain[Edit[A]]
}

///|
/// Optimal unit-cost edit script. Ties prefer replacement, then deletion.
pub fn[A] edit_script(
  xs : @core.Chain[A],
  ys : @core.Chain[A],
  equal : (A, A) -> Bool,
) -> @core.Chain[Edit[A]] {
  let empty : Script[A] = { cost: Zero, reversed: Nil, }
  let row = grid(
    xs,
    ys,
    empty,
    fn(x, prev) {
      { cost: Succ(prev.cost), reversed: Cons(Delete(x), prev.reversed), }
    },
    fn(y, prev) {
      { cost: Succ(prev.cost), reversed: Cons(Insert(y), prev.reversed), }
    },
    fn(x, y, diagonal, up, left) {
      match equal(x, y) {
        true =>
          { cost: diagonal.cost, reversed: Cons(Keep(x), diagonal.reversed), }
        false => {
          let replacement : Script[A] = {
            cost: Succ(diagonal.cost),
            reversed: Cons(Replace(x, y), diagonal.reversed),
          }
          let deletion : Script[A] = {
            cost: Succ(up.cost),
            reversed: Cons(Delete(x), up.reversed),
          }
          let insertion : Script[A] = {
            cost: Succ(left.cost),
            reversed: Cons(Insert(y), left.reversed),
          }
          let best = match @core.compare(replacement.cost, deletion.cost) {
            Greater => deletion
            _ => replacement
          }
          match @core.compare(best.cost, insertion.cost) {
            Greater => insertion
            _ => best
          }
        }
      }
    },
  )
  match @core.last(row) {
    Some(result) => @core.reverse(result.reversed)
    None => Nil
  }
}

///|
/// Apply a script only if its old symbols match the consumed source exactly.
pub fn[A] apply_script(
  xs : @core.Chain[A],
  edits : @core.Chain[Edit[A]],
  equal : (A, A) -> Bool,
) -> @core.Chain[A]? {
  fn prepend(value : A, tail : @core.Chain[A]?) -> @core.Chain[A]? {
    match tail {
      None => None
      Some(rest) => Some(Cons(value, rest))
    }
  }
  match (xs, edits) {
    (Nil, Nil) => Some(Nil)
    (_, Cons(Insert(y), rest)) => prepend(y, apply_script(xs, rest, equal))
    (Cons(x, xt), Cons(Keep(old), rest)) =>
      match equal(x, old) {
        true => prepend(x, apply_script(xt, rest, equal))
        false => None
      }
    (Cons(x, xt), Cons(Delete(old), rest)) =>
      match equal(x, old) {
        true => apply_script(xt, rest, equal)
        false => None
      }
    (Cons(x, xt), Cons(Replace(old, y), rest)) =>
      match equal(x, old) {
        true => prepend(y, apply_script(xt, rest, equal))
        false => None
      }
    _ => None
  }
}
