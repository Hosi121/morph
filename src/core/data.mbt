///|
/// An immutable list whose spine is the only indexing mechanism.
#derive(Eq, Debug)
pub(all) enum Chain[A] {
  Nil
  Cons(A, Chain[A])
}

///|
/// Unary naturals: no machine integer is stored in this type.
#derive(Eq, Debug)
pub(all) enum Nat {
  Zero
  Succ(Nat)
}

///|
#derive(Eq, Debug)
pub(all) enum Ordering {
  Less
  Equal
  Greater
}

///|
pub extend Chain with Eq::{equal, not_equal}

///|
pub extend Chain with Debug::{to_repr}

///|
pub extend Nat with Eq::{equal, not_equal}

///|
pub extend Nat with Debug::{to_repr}

///|
pub extend Ordering with Eq::{equal, not_equal}

///|
pub extend Ordering with Debug::{to_repr}

///|
pub fn[A] append(xs : Chain[A], ys : Chain[A]) -> Chain[A] {
  match xs {
    Nil => ys
    Cons(x, rest) => Cons(x, append(rest, ys))
  }
}

///|
pub fn[A] reverse_onto(xs : Chain[A], tail : Chain[A]) -> Chain[A] {
  match xs {
    Nil => tail
    Cons(x, rest) => reverse_onto(rest, Cons(x, tail))
  }
}

///|
pub fn[A] reverse(xs : Chain[A]) -> Chain[A] {
  reverse_onto(xs, Nil)
}

///|
pub fn[A, B] map(xs : Chain[A], f : (A) -> B) -> Chain[B] {
  match xs {
    Nil => Nil
    Cons(x, rest) => Cons(f(x), map(rest, f))
  }
}

///|
pub fn[A, B] fold_left(xs : Chain[A], init : B, f : (B, A) -> B) -> B {
  match xs {
    Nil => init
    Cons(x, rest) => fold_left(rest, f(init, x), f)
  }
}

///|
pub fn[A] length(xs : Chain[A]) -> Nat {
  fold_left(xs, Zero, fn(n, _) { Succ(n) })
}

///|
pub fn[A] replicate(n : Nat, value : A) -> Chain[A] {
  match n {
    Zero => Nil
    Succ(rest) => Cons(value, replicate(rest, value))
  }
}

///|
pub fn[A] take(n : Nat, xs : Chain[A]) -> Chain[A] {
  match (n, xs) {
    (Zero, _) | (_, Nil) => Nil
    (Succ(rest), Cons(x, tail)) => Cons(x, take(rest, tail))
  }
}

///|
pub fn[A] drop(n : Nat, xs : Chain[A]) -> Chain[A] {
  match (n, xs) {
    (Zero, _) | (_, Nil) => xs
    (Succ(rest), Cons(_, tail)) => drop(rest, tail)
  }
}

///|
pub fn[A] nth(xs : Chain[A], n : Nat) -> A? {
  match (xs, n) {
    (Nil, _) => None
    (Cons(x, _), Zero) => Some(x)
    (Cons(_, rest), Succ(k)) => nth(rest, k)
  }
}

///|
pub fn[A] last(xs : Chain[A]) -> A? {
  match xs {
    Nil => None
    Cons(x, Nil) => Some(x)
    Cons(_, rest) => last(rest)
  }
}

///|
/// Consume exactly n constructors in one pass; retain the untouched suffix.
pub fn[A] split_exact(n : Nat, xs : Chain[A]) -> (Chain[A], Chain[A])? {
  match (n, xs) {
    (Zero, _) => Some((Nil, xs))
    (Succ(_), Nil) => None
    (Succ(rest), Cons(x, xt)) =>
      match split_exact(rest, xt) {
        None => None
        Some((prefix, suffix)) => Some((Cons(x, prefix), suffix))
      }
  }
}

///|
/// The naturals from zero up to (but excluding) n, constructed structurally.
pub fn indices(n : Nat) -> Chain[Nat] {
  fn go(todo : Nat, next : Nat) -> Chain[Nat] {
    match todo {
      Zero => Nil
      Succ(rest) => Cons(next, go(rest, Succ(next)))
    }
  }
  go(n, Zero)
}

///|
pub fn[A] filter(xs : Chain[A], keep : (A) -> Bool) -> Chain[A] {
  match xs {
    Nil => Nil
    Cons(x, rest) =>
      match keep(x) {
        true => Cons(x, filter(rest, keep))
        false => filter(rest, keep)
      }
  }
}

///|
pub fn[A] any(xs : Chain[A], predicate : (A) -> Bool) -> Bool {
  match xs {
    Nil => false
    Cons(x, rest) =>
      match predicate(x) {
        true => true
        false => any(rest, predicate)
      }
  }
}

///|
pub fn[A] all(xs : Chain[A], predicate : (A) -> Bool) -> Bool {
  match xs {
    Nil => true
    Cons(x, rest) =>
      match predicate(x) {
        false => false
        true => all(rest, predicate)
      }
  }
}

///|
pub fn[A, B] zip(xs : Chain[A], ys : Chain[B]) -> Chain[(A, B)]? {
  match (xs, ys) {
    (Nil, Nil) => Some(Nil)
    (Cons(x, xt), Cons(y, yt)) =>
      match zip(xt, yt) {
        None => None
        Some(rest) => Some(Cons((x, y), rest))
      }
    _ => None
  }
}

///|
pub fn[A] interleave(xs : Chain[A], ys : Chain[A]) -> Chain[A] {
  match xs {
    Nil => ys
    Cons(x, rest) => Cons(x, interleave(ys, rest))
  }
}

///|
pub fn[A] alternating(xs : Chain[A]) -> (Chain[A], Chain[A]) {
  match xs {
    Nil => (Nil, Nil)
    Cons(x, rest) => {
      let (odds, evens) = alternating(rest)
      (Cons(x, evens), odds)
    }
  }
}

///|
pub fn add(a : Nat, b : Nat) -> Nat {
  match a {
    Zero => b
    Succ(rest) => add(rest, Succ(b))
  }
}

///|
pub fn multiply(a : Nat, b : Nat) -> Nat {
  match a {
    Zero => Zero
    Succ(rest) => add(b, multiply(rest, b))
  }
}

///|
/// Saturating subtraction.
pub fn subtract(a : Nat, b : Nat) -> Nat {
  match (a, b) {
    (_, Zero) | (Zero, _) => a
    (Succ(x), Succ(y)) => subtract(x, y)
  }
}

///|
pub fn compare(a : Nat, b : Nat) -> Ordering {
  match (a, b) {
    (Zero, Zero) => Equal
    (Zero, Succ(_)) => Less
    (Succ(_), Zero) => Greater
    (Succ(x), Succ(y)) => compare(x, y)
  }
}

///|
pub fn minimum(a : Nat, b : Nat) -> Nat {
  match compare(a, b) {
    Greater => b
    _ => a
  }
}

///|
pub fn is_zero(a : Nat) -> Bool {
  match a {
    Zero => true
    Succ(_) => false
  }
}

///|
/// Quotient and remainder; division by zero is explicit.
pub fn divmod(a : Nat, b : Nat) -> (Nat, Nat)? {
  match b {
    Zero => None
    Succ(_) => Some(divmod_nonzero(a, b))
  }
}

///|
fn divmod_nonzero(a : Nat, b : Nat) -> (Nat, Nat) {
  match compare(a, b) {
    Less => (Zero, a)
    _ => {
      let (q, r) = divmod_nonzero(subtract(a, b), b)
      (Succ(q), r)
    }
  }
}

///|
/// Euclid's algorithm on unary naturals.
pub fn gcd(a : Nat, b : Nat) -> Nat {
  match b {
    Zero => a
    Succ(_) => {
      let (_, r) = divmod_nonzero(a, b)
      gcd(b, r)
    }
  }
}
