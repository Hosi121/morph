///|
/// Chomsky normal form: A -> token, A -> B C. Only the start may produce epsilon.
#derive(Eq, Debug)
pub(all) enum Rule[A] {
  Terminal(@core.Nat, A)
  Binary(@core.Nat, @core.Nat, @core.Nat)
}

///|
pub extend Rule with Eq::{equal, not_equal}

///|
pub extend Rule with Debug::{to_repr}

///|
#derive(Eq, Debug)
pub struct Grammar[A] {
  symbols : @core.Chain[@core.Nat]
  start : @core.Nat
  rules : @core.Chain[Rule[A]]
  epsilon : Bool
}

///|
pub extend Grammar with Eq::{equal, not_equal}

///|
pub extend Grammar with Debug::{to_repr}

///|
#derive(Eq, Debug)
pub(all) enum Tree[A] {
  Empty(@core.Nat)
  Leaf(@core.Nat, A)
  Branch(@core.Nat, Tree[A], Tree[A])
}

///|
pub extend Tree with Eq::{equal, not_equal}

///|
pub extend Tree with Debug::{to_repr}

///|
fn same(a : @core.Nat, b : @core.Nat) -> Bool {
  match @core.compare(a, b) {
    Equal => true
    _ => false
  }
}

///|
fn has_symbol(symbols : @core.Chain[@core.Nat], symbol : @core.Nat) -> Bool {
  @core.any(symbols, fn(other) { same(symbol, other) })
}

///|
pub fn[A] grammar(
  symbols : @core.Chain[@core.Nat],
  start : @core.Nat,
  rules : @core.Chain[Rule[A]],
  epsilon : Bool,
) -> Grammar[A]? {
  fn unique(symbols : @core.Chain[@core.Nat]) -> Bool {
    match symbols {
      Nil => true
      Cons(symbol, rest) => !has_symbol(rest, symbol) && unique(rest)
    }
  }
  let valid = @core.all(rules, fn(rule) {
    match rule {
      Terminal(lhs, _) => has_symbol(symbols, lhs)
      Binary(lhs, left, right) =>
        has_symbol(symbols, lhs) &&
        has_symbol(symbols, left) &&
        has_symbol(symbols, right) &&
        (!epsilon || (!same(left, start) && !same(right, start)))
    }
  })
  match unique(symbols) && has_symbol(symbols, start) && valid {
    true => Some({ symbols, start, rules, epsilon, })
    false => None
  }
}

///|
pub fn[A] root(tree : Tree[A]) -> @core.Nat {
  match tree {
    Empty(symbol) | Leaf(symbol, _) | Branch(symbol, _, _) => symbol
  }
}

///|
/// Accumulator traversal avoids repeatedly concatenating subtree yields.
pub fn[A] yield_word(tree : Tree[A]) -> @core.Chain[A] {
  fn walk(tree : Tree[A], tail : @core.Chain[A]) -> @core.Chain[A] {
    match tree {
      Empty(_) => tail
      Leaf(_, token) => Cons(token, tail)
      Branch(_, left, right) => walk(left, walk(right, tail))
    }
  }
  walk(tree, Nil)
}

///|
fn[A] lookup(
  entries : @core.Chain[(@core.Nat, Tree[A])],
  symbol : @core.Nat,
) -> Tree[A]? {
  match entries {
    Nil => None
    Cons((other, tree), rest) =>
      match same(other, symbol) {
        true => Some(tree)
        false => lookup(rest, symbol)
      }
  }
}

///|
priv struct Cell[A] {
  start : @core.Nat
  width : @core.Nat
  entries : @core.Chain[(@core.Nat, Tree[A])]
}

///|
fn[A] cell(
  chart : @core.Chain[Cell[A]],
  start : @core.Nat,
  width : @core.Nat,
) -> @core.Chain[(@core.Nat, Tree[A])] {
  match chart {
    Nil => Nil
    Cons(found, rest) =>
      match same(found.start, start) && same(found.width, width) {
        true => found.entries
        false => cell(rest, start, width)
      }
  }
}

///|
/// CYK chart, retaining one parse witness per nonterminal and interval.
/// Token equality is supplied explicitly; no terminal comparison is built in.
pub fn[A] parse(
  g : Grammar[A],
  word : @core.Chain[A],
  equal : (A, A) -> Bool,
) -> Tree[A]? {
  fn terminals(
    word : @core.Chain[A],
    start : @core.Nat,
    chart : @core.Chain[Cell[A]],
  ) -> @core.Chain[Cell[A]] {
    match word {
      Nil => chart
      Cons(token, rest) => {
        let entries : @core.Chain[(@core.Nat, Tree[A])] = @core.fold_left(
          g.rules,
          Nil,
          fn(entries, rule) {
            match rule {
              Terminal(lhs, expected) =>
                match (equal(token, expected), lookup(entries, lhs)) {
                  (true, None) => Cons((lhs, Leaf(lhs, token)), entries)
                  _ => entries
                }
              Binary(_, _, _) => entries
            }
          },
        )
        terminals(
          rest,
          Succ(start),
          Cons({ start, width: Succ(Zero), entries, }, chart),
        )
      }
    }
  }
  fn splits(
    chart : @core.Chain[Cell[A]],
    start : @core.Nat,
    width : @core.Nat,
    left_width : @core.Nat,
    right_width : @core.Nat,
    entries : @core.Chain[(@core.Nat, Tree[A])],
  ) -> @core.Chain[(@core.Nat, Tree[A])] {
    match right_width {
      Zero => entries
      Succ(previous) => {
        let left = cell(chart, start, left_width)
        let right = cell(chart, @core.add(start, left_width), right_width)
        let entries = @core.fold_left(g.rules, entries, fn(entries, rule) {
          match rule {
            Terminal(_, _) => entries
            Binary(lhs, a, b) =>
              match (lookup(entries, lhs), lookup(left, a), lookup(right, b)) {
                (None, Some(l), Some(r)) =>
                  Cons((lhs, Branch(lhs, l, r)), entries)
                _ => entries
              }
          }
        })
        splits(chart, start, width, Succ(left_width), previous, entries)
      }
    }
  }
  fn widths(
    width : @core.Nat,
    remaining : @core.Nat,
    chart : @core.Chain[Cell[A]],
  ) -> @core.Chain[Cell[A]] {
    match remaining {
      Zero => chart
      Succ(previous) => {
        let chart = @core.fold_left(@core.indices(remaining), chart, fn(
          chart,
          start,
        ) {
          let right = @core.subtract(width, Succ(Zero))
          let entries = splits(chart, start, width, Succ(Zero), right, Nil)
          Cons({ start, width, entries, }, chart)
        })
        widths(Succ(width), previous, chart)
      }
    }
  }
  match word {
    Nil =>
      match g.epsilon {
        true => Some(Empty(g.start))
        false => None
      }
    Cons(_, tail) => {
      let chart = widths(
        Succ(Succ(Zero)),
        @core.length(tail),
        terminals(word, Zero, Nil),
      )
      lookup(cell(chart, Zero, @core.length(word)), g.start)
    }
  }
}

///|
/// Check a witness from grammar rules and its yield without constructing a chart.
pub fn[A] check(
  g : Grammar[A],
  word : @core.Chain[A],
  tree : Tree[A],
  equal : (A, A) -> Bool,
) -> Bool {
  fn nonempty(tree : Tree[A]) -> Bool {
    match tree {
      Empty(_) => false
      Leaf(lhs, token) =>
        @core.any(g.rules, fn(rule) {
          match rule {
            Terminal(other, expected) =>
              same(lhs, other) && equal(token, expected)
            _ => false
          }
        })
      Branch(lhs, left, right) =>
        nonempty(left) &&
        nonempty(right) &&
        @core.any(g.rules, fn(rule) {
          match rule {
            Binary(other, a, b) =>
              same(lhs, other) && same(root(left), a) && same(root(right), b)
            _ => false
          }
        })
    }
  }
  let valid = match tree {
    Empty(symbol) => g.epsilon && same(symbol, g.start)
    _ => same(root(tree), g.start) && nonempty(tree)
  }
  match @core.zip(word, yield_word(tree)) {
    None => false
    Some(pairs) =>
      valid &&
      @core.all(pairs, fn(pair) {
        let (a, b) = pair
        equal(a, b)
      })
  }
}
