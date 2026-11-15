///|
/// Contiguous halves, found with slow/fast list cursors.
pub fn[A] split(xs : @core.Chain[A]) -> (@core.Chain[A], @core.Chain[A]) {
  fn walk(
    slow : @core.Chain[A],
    fast : @core.Chain[A],
  ) -> (@core.Chain[A], @core.Chain[A]) {
    match (slow, fast) {
      (Cons(x, st), Cons(_, Cons(_, ft))) => {
        let (prefix, suffix) = walk(st, ft)
        (Cons(x, prefix), suffix)
      }
      _ => (Nil, slow)
    }
  }
  walk(xs, xs)
}

///|
/// Equal keys are taken from the left run, preserving stability.
pub fn[A] merge(
  xs : @core.Chain[A],
  ys : @core.Chain[A],
  compare : (A, A) -> @core.Ordering,
) -> @core.Chain[A] {
  match (xs, ys) {
    (Nil, _) => ys
    (_, Nil) => xs
    (Cons(x, xt), Cons(y, yt)) =>
      match compare(x, y) {
        Greater => Cons(y, merge(xs, yt, compare))
        _ => Cons(x, merge(xt, ys, compare))
      }
  }
}

///|
/// Stable merge sort. Alternating halves would break stability on equal keys.
pub fn[A] merge_sort(
  xs : @core.Chain[A],
  compare : (A, A) -> @core.Ordering,
) -> @core.Chain[A] {
  match xs {
    Nil | Cons(_, Nil) => xs
    _ => {
      let (left, right) = split(xs)
      merge(merge_sort(left, compare), merge_sort(right, compare), compare)
    }
  }
}

///|
fn[A] insert(
  x : A,
  xs : @core.Chain[A],
  compare : (A, A) -> @core.Ordering,
) -> @core.Chain[A] {
  match xs {
    Nil => Cons(x, Nil)
    Cons(y, rest) =>
      match compare(x, y) {
        Greater => Cons(y, insert(x, rest, compare))
        _ => Cons(x, xs)
      }
  }
}

///|
pub fn[A] insertion_sort(
  xs : @core.Chain[A],
  compare : (A, A) -> @core.Ordering,
) -> @core.Chain[A] {
  match xs {
    Nil => Nil
    Cons(x, rest) => insert(x, insertion_sort(rest, compare), compare)
  }
}

///|
fn[A] partition(
  pivot : A,
  xs : @core.Chain[A],
  compare : (A, A) -> @core.Ordering,
) -> (@core.Chain[A], @core.Chain[A], @core.Chain[A]) {
  match xs {
    Nil => (Nil, Nil, Nil)
    Cons(x, rest) => {
      let (less, equal, greater) = partition(pivot, rest, compare)
      match compare(x, pivot) {
        Less => (Cons(x, less), equal, greater)
        Equal => (less, Cons(x, equal), greater)
        Greater => (less, equal, Cons(x, greater))
      }
    }
  }
}

///|
/// Stable three-way quicksort; first pivot means quadratic worst-case behavior.
pub fn[A] quick_sort(
  xs : @core.Chain[A],
  compare : (A, A) -> @core.Ordering,
) -> @core.Chain[A] {
  match xs {
    Nil => Nil
    Cons(pivot, rest) => {
      let (less, equal, greater) = partition(pivot, rest, compare)
      @core.append(
        quick_sort(less, compare),
        Cons(pivot, @core.append(equal, quick_sort(greater, compare))),
      )
    }
  }
}
