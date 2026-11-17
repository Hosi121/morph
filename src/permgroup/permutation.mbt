///|
/// A checked bijection of the points below degree. Constructors are private.
#derive(Eq, Debug)
pub struct Permutation {
  priv degree : @core.Nat
  priv images : @core.Chain[@core.Nat]
}

///|
pub extend Permutation with Eq::{equal, not_equal}

///|
pub extend Permutation with Debug::{to_repr}

///|
pub fn degree(value : Permutation) -> @core.Nat {
  value.degree
}

///|
pub fn images(value : Permutation) -> @core.Chain[@core.Nat] {
  value.images
}

///|
fn valid_permutation(value : Permutation) -> Bool {
  fn distinct(todo : @core.Chain[@core.Nat]) -> Bool {
    match todo {
      Nil => true
      Cons(head, rest) =>
        @core.compare(head, value.degree).equal(Less) &&
        !@core.any(rest, fn(other) { head.equal(other) }) &&
        distinct(rest)
    }
  }
  @core.length(value.images).equal(value.degree) && distinct(value.images)
}

///|
/// Rejects wrong lengths, repeated images and images outside the point set.
/// Degree zero has one permutation, represented by the empty image chain.
pub fn checked_permutation(
  degree : @core.Nat,
  images : @core.Chain[@core.Nat],
) -> Permutation? {
  let result : Permutation = { degree, images, }
  if valid_permutation(result) {
    Some(result)
  } else {
    None
  }
}

///|
pub fn identity(degree : @core.Nat) -> Permutation {
  { degree, images: @core.indices(degree), }
}

///|
pub fn apply(value : Permutation, point : @core.Nat) -> @core.Nat? {
  @core.nth(value.images, point)
}

///|
// Only used with an in-range image of a privately constructed permutation.
fn image_at(value : Permutation, point : @core.Nat) -> @core.Nat {
  match apply(value, point) {
    Some(image) => image
    None => Zero
  }
}

///|
fn compose_same(left : Permutation, right : Permutation) -> Permutation {
  {
    degree: left.degree,
    images: @core.map(right.images, fn(point) { image_at(left, point) }),
  }
}

///|
/// Composition is left after right, as ordinary function composition.
pub fn compose(left : Permutation, right : Permutation) -> Permutation? {
  if left.degree.equal(right.degree) {
    Some(compose_same(left, right))
  } else {
    None
  }
}

///|
pub fn inverse(value : Permutation) -> Permutation {
  fn preimage(
    todo : @core.Chain[@core.Nat],
    target : @core.Nat,
    index : @core.Nat,
  ) -> @core.Nat {
    match todo {
      Nil => Zero
      Cons(head, rest) =>
        if head.equal(target) {
          index
        } else {
          preimage(rest, target, Succ(index))
        }
    }
  }
  {
    degree: value.degree,
    images: @core.map(@core.indices(value.degree), fn(point) {
      preimage(value.images, point, Zero)
    }),
  }
}

///|
fn compare_images(
  left : @core.Chain[@core.Nat],
  right : @core.Chain[@core.Nat],
) -> @core.Ordering {
  match (left, right) {
    (Nil, Nil) => Equal
    (Nil, _) => Less
    (_, Nil) => Greater
    (Cons(x, xs), Cons(y, ys)) =>
      match @core.compare(x, y) {
        Equal => compare_images(xs, ys)
        other => other
      }
  }
}

///|
pub fn compare(left : Permutation, right : Permutation) -> @core.Ordering {
  match @core.compare(left.degree, right.degree) {
    Equal => compare_images(left.images, right.images)
    other => other
  }
}

///|
/// The convention is x inverse, y inverse, x, y (all composed left after right).
pub fn commutator(left : Permutation, right : Permutation) -> Permutation? {
  if left.degree.equal(right.degree) {
    Some(commutator_same(left, right))
  } else {
    None
  }
}

///|
fn commutator_same(left : Permutation, right : Permutation) -> Permutation {
  compose_same(
    compose_same(inverse(left), inverse(right)),
    compose_same(left, right),
  )
}
