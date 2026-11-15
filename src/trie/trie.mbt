///|
/// Persistent binary-word map. Empty word and every leading/trailing zero matter.
/// Opaque constructors maintain pruning: empty branches collapse to Empty.
#derive(Eq, Debug)
pub enum Trie[A] {
  Empty
  Branch(A?, Trie[A], Trie[A])
}

///|
pub extend Trie with Eq::{equal, not_equal}

///|
pub extend Trie with Debug::{to_repr}

///|
pub fn[A] empty() -> Trie[A] {
  Empty
}

///|
fn[A] branch(value : A?, left : Trie[A], right : Trie[A]) -> Trie[A] {
  match (value, left, right) {
    (None, Empty, Empty) => Empty
    _ => Branch(value, left, right)
  }
}

///|
fn[A] parts(trie : Trie[A]) -> (A?, Trie[A], Trie[A]) {
  match trie {
    Empty => (None, Empty, Empty)
    Branch(value, left, right) => (value, left, right)
  }
}

///|
pub fn[A] lookup(trie : Trie[A], key : @core.Chain[Bool]) -> A? {
  match (trie, key) {
    (Empty, _) => None
    (Branch(value, _, _), Nil) => value
    (Branch(_, left, _), Cons(false, rest)) => lookup(left, rest)
    (Branch(_, _, right), Cons(true, rest)) => lookup(right, rest)
  }
}

///|
/// Copies only the key path; the other subtrees are shared.
pub fn[A] put(trie : Trie[A], key : @core.Chain[Bool], value : A) -> Trie[A] {
  let (old, left, right) = parts(trie)
  match key {
    Nil => Branch(Some(value), left, right)
    Cons(false, rest) => Branch(old, put(left, rest, value), right)
    Cons(true, rest) => Branch(old, left, put(right, rest, value))
  }
}

///|
pub fn[A] remove(trie : Trie[A], key : @core.Chain[Bool]) -> Trie[A] {
  match trie {
    Empty => Empty
    Branch(old, left, right) =>
      match key {
        Nil => branch(None, left, right)
        Cons(false, rest) => branch(old, remove(left, rest), right)
        Cons(true, rest) => branch(old, left, remove(right, rest))
      }
  }
}

///|
/// Return the trie below a prefix. Keys in that trie are relative to the prefix.
pub fn[A] below(trie : Trie[A], prefix : @core.Chain[Bool]) -> Trie[A] {
  match (trie, prefix) {
    (_, Nil) => trie
    (Empty, _) => Empty
    (Branch(_, left, _), Cons(false, rest)) => below(left, rest)
    (Branch(_, _, right), Cons(true, rest)) => below(right, rest)
  }
}

///|
/// Longest stored prefix: number of consumed key bits and the associated value.
pub fn[A] longest_prefix(
  trie : Trie[A],
  key : @core.Chain[Bool],
) -> (@core.Nat, A)? {
  fn walk(
    trie : Trie[A],
    key : @core.Chain[Bool],
    consumed : @core.Nat,
    best : (@core.Nat, A)?,
  ) -> (@core.Nat, A)? {
    match trie {
      Empty => best
      Branch(value, left, right) => {
        let best = match value {
          None => best
          Some(value) => Some((consumed, value))
        }
        match key {
          Nil => best
          Cons(false, rest) => walk(left, rest, Succ(consumed), best)
          Cons(true, rest) => walk(right, rest, Succ(consumed), best)
        }
      }
    }
  }
  walk(trie, key, Zero, None)
}

///|
/// Binary lexicographic word order: a prefix precedes its extensions, false < true.
/// This is word order, not numeric order for variable-width little-endian numbers.
pub fn[A] entries(trie : Trie[A]) -> @core.Chain[(@core.Chain[Bool], A)] {
  fn walk(
    trie : Trie[A],
    prefix : @core.Chain[Bool],
    tail : @core.Chain[(@core.Chain[Bool], A)],
  ) -> @core.Chain[(@core.Chain[Bool], A)] {
    match trie {
      Empty => tail
      Branch(value, left, right) => {
        let after_right = walk(right, Cons(true, prefix), tail)
        let after_left = walk(left, Cons(false, prefix), after_right)
        match value {
          None => after_left
          Some(value) => Cons((@core.reverse(prefix), value), after_left)
        }
      }
    }
  }
  walk(trie, Nil, Nil)
}

///|
/// Pointwise union, sharing untouched subtrees and combining collisions.
pub fn[A] union(a : Trie[A], b : Trie[A], combine : (A, A) -> A) -> Trie[A] {
  match (a, b) {
    (Empty, _) => b
    (_, Empty) => a
    (Branch(av, al, ar), Branch(bv, bl, br)) => {
      let value = match (av, bv) {
        (None, _) => bv
        (_, None) => av
        (Some(x), Some(y)) => Some(combine(x, y))
      }
      Branch(value, union(al, bl, combine), union(ar, br, combine))
    }
  }
}

///|
pub fn[A, B] map(trie : Trie[A], f : (A) -> B) -> Trie[B] {
  match trie {
    Empty => Empty
    Branch(value, left, right) =>
      Branch(
        match value {
          None => None
          Some(value) => Some(f(value))
        },
        map(left, f),
        map(right, f),
      )
  }
}

///|
pub fn[A] size(trie : Trie[A]) -> @core.Nat {
  fn count(trie : Trie[A], acc : @core.Nat) -> @core.Nat {
    match trie {
      Empty => acc
      Branch(value, left, right) => {
        let acc = match value {
          None => acc
          Some(_) => Succ(acc)
        }
        count(right, count(left, acc))
      }
    }
  }
  count(trie, Zero)
}
