///|
/// Regular expressions over an arbitrary alphabet; these match whole words.
#derive(Eq, Debug)
pub(all) enum Regex[A] {
  Empty
  Epsilon
  Atom(A)
  Choice(Regex[A], Regex[A])
  Sequence(Regex[A], Regex[A])
  Repeat(Regex[A])
}

///|
pub extend Regex with Eq::{equal, not_equal}

///|
pub extend Regex with Debug::{to_repr}

///|
pub fn[A] choice(a : Regex[A], b : Regex[A]) -> Regex[A] {
  match (a, b) {
    (Empty, _) => b
    (_, Empty) => a
    (Epsilon, Epsilon) => Epsilon
    _ => Choice(a, b)
  }
}

///|
pub fn[A] sequence(a : Regex[A], b : Regex[A]) -> Regex[A] {
  match (a, b) {
    (Empty, _) | (_, Empty) => Empty
    (Epsilon, _) => b
    (_, Epsilon) => a
    _ => Sequence(a, b)
  }
}

///|
pub fn[A] repeat(expression : Regex[A]) -> Regex[A] {
  match expression {
    Empty | Epsilon => Epsilon
    Repeat(_) => expression
    _ => Repeat(expression)
  }
}

///|
pub fn[A] nullable(expression : Regex[A]) -> Bool {
  match expression {
    Empty | Atom(_) => false
    Epsilon | Repeat(_) => true
    Choice(a, b) =>
      match nullable(a) {
        true => true
        false => nullable(b)
      }
    Sequence(a, b) =>
      match nullable(a) {
        false => false
        true => nullable(b)
      }
  }
}

///|
/// Brzozowski derivative: language(D_a r) = {w | a::w is in language(r)}.
pub fn[A] derivative(
  expression : Regex[A],
  symbol : A,
  equal : (A, A) -> Bool,
) -> Regex[A] {
  match expression {
    Empty | Epsilon => Empty
    Atom(value) =>
      match equal(value, symbol) {
        true => Epsilon
        false => Empty
      }
    Choice(a, b) =>
      choice(derivative(a, symbol, equal), derivative(b, symbol, equal))
    Sequence(a, b) => {
      let left = sequence(derivative(a, symbol, equal), b)
      match nullable(a) {
        false => left
        true => choice(left, derivative(b, symbol, equal))
      }
    }
    Repeat(body) => sequence(derivative(body, symbol, equal), repeat(body))
  }
}

///|
pub fn[A] matches(
  expression : Regex[A],
  word : @core.Chain[A],
  equal : (A, A) -> Bool,
) -> Bool {
  nullable(
    @core.fold_left(word, expression, fn(current, symbol) {
      derivative(current, symbol, equal)
    }),
  )
}
