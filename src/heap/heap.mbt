///|
/// Persistent leftist heap. Constructors are private to protect rank invariants.
#derive(Eq, Debug)
pub enum Heap[A] {
  Empty
  Node(@core.Nat, A, Heap[A], Heap[A])
}

///|
pub extend Heap with Eq::{equal, not_equal}

///|
pub extend Heap with Debug::{to_repr}

///|
pub fn[A] empty() -> Heap[A] {
  Empty
}

///|
pub fn[A] singleton(x : A) -> Heap[A] {
  Node(Succ(Zero), x, Empty, Empty)
}

///|
fn[A] rank(h : Heap[A]) -> @core.Nat {
  match h {
    Empty => Zero
    Node(rank, _, _, _) => rank
  }
}

///|
fn[A] node(x : A, a : Heap[A], b : Heap[A]) -> Heap[A] {
  match @core.compare(rank(a), rank(b)) {
    Less => Node(Succ(rank(a)), x, b, a)
    _ => Node(Succ(rank(b)), x, a, b)
  }
}

///|
/// Always use the same ordering for all operations on a heap.
pub fn[A] merge(
  a : Heap[A],
  b : Heap[A],
  compare : (A, A) -> @core.Ordering,
) -> Heap[A] {
  match (a, b) {
    (Empty, _) => b
    (_, Empty) => a
    (Node(_, x, al, ar), Node(_, y, bl, br)) =>
      match compare(x, y) {
        Greater => node(y, bl, merge(a, br, compare))
        _ => node(x, al, merge(ar, b, compare))
      }
  }
}

///|
pub fn[A] insert(
  h : Heap[A],
  x : A,
  compare : (A, A) -> @core.Ordering,
) -> Heap[A] {
  merge(singleton(x), h, compare)
}

///|
pub fn[A] pop(h : Heap[A], compare : (A, A) -> @core.Ordering) -> (A, Heap[A])? {
  match h {
    Empty => None
    Node(_, x, left, right) => Some((x, merge(left, right, compare)))
  }
}

///|
fn[A] merge_pairs(
  heaps : @core.Chain[Heap[A]],
  compare : (A, A) -> @core.Ordering,
) -> @core.Chain[Heap[A]] {
  match heaps {
    Cons(a, Cons(b, rest)) =>
      Cons(merge(a, b, compare), merge_pairs(rest, compare))
    _ => heaps
  }
}

///|
/// Bottom-up construction by pairwise merging singleton heaps.
pub fn[A] from_chain(
  xs : @core.Chain[A],
  compare : (A, A) -> @core.Ordering,
) -> Heap[A] {
  fn combine(heaps : @core.Chain[Heap[A]]) -> Heap[A] {
    match heaps {
      Nil => Empty
      Cons(h, Nil) => h
      _ => combine(merge_pairs(heaps, compare))
    }
  }
  combine(@core.map(xs, singleton))
}

///|
pub fn[A] drain(
  h : Heap[A],
  compare : (A, A) -> @core.Ordering,
) -> @core.Chain[A] {
  match pop(h, compare) {
    None => Nil
    Some((x, rest)) => Cons(x, drain(rest, compare))
  }
}

///|
/// Heap sort is not stable.
pub fn[A] sort(
  xs : @core.Chain[A],
  compare : (A, A) -> @core.Ordering,
) -> @core.Chain[A] {
  drain(from_chain(xs, compare), compare)
}
