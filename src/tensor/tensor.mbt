///|
#derive(Eq, Debug)
pub(all) enum TensorError {
  EntryCountMismatch
  CoordinateRankMismatch
  CoordinateOutOfBounds
  ShapeMismatch
  AxisOutOfBounds
  RepeatedAxis
  AxisSizeMismatch
  PermutationRankMismatch
  PermutationOutOfBounds
  PermutationNotBijective
  ModeWidthMismatch
  InternalShape
}

///|
pub extend TensorError with Eq::{equal, not_equal}

///|
pub extend TensorError with Debug::{to_repr}

///|
/// Checked dense row-major tensor. The last axis varies fastest.
/// Empty shape is a scalar with one entry; any zero-sized axis gives no entries.
#derive(Eq, Debug)
pub struct Tensor[A] {
  dimensions : @core.Chain[@core.Nat]
  values : @core.Chain[A]
}

///|
pub extend Tensor with Eq::{equal, not_equal}

///|
pub extend Tensor with Debug::{to_repr}

///|
fn cardinality(dimensions : @core.Chain[@core.Nat]) -> @core.Nat {
  match dimensions {
    Nil => Succ(Zero)
    Cons(Zero, _) => Zero
    Cons(size, rest) =>
      match cardinality(rest) {
        Zero => Zero
        other => @core.multiply(size, other)
      }
  }
}

///|
pub fn[A] from_flat(
  dimensions : @core.Chain[@core.Nat],
  values : @core.Chain[A],
) -> Result[Tensor[A], TensorError] {
  if !@core.length(values).equal(cardinality(dimensions)) {
    return Err(EntryCountMismatch)
  }
  Ok({ dimensions, values, })
}

///|
pub fn[A] shape(value : Tensor[A]) -> @core.Chain[@core.Nat] {
  value.dimensions
}

///|
pub fn[A] rank(value : Tensor[A]) -> @core.Nat {
  @core.length(value.dimensions)
}

///|
pub fn[A] entries(value : Tensor[A]) -> @core.Chain[A] {
  value.values
}

///|
fn[A, B] concatenate_map(
  values : @core.Chain[A],
  transform : (A) -> @core.Chain[B],
) -> @core.Chain[B] {
  match values {
    Nil => Nil
    Cons(head, tail) =>
      @core.append(transform(head), concatenate_map(tail, transform))
  }
}

///|
fn coordinates(
  dimensions : @core.Chain[@core.Nat],
) -> @core.Chain[@core.Chain[@core.Nat]] {
  match dimensions {
    Nil => Cons(Nil, Nil)
    Cons(Zero, _) => Nil
    Cons(size, rest) =>
      match coordinates(rest) {
        Nil => Nil
        tails =>
          concatenate_map(@core.indices(size), fn(head) {
            @core.map(tails, fn(tail) { @core.Chain::Cons(head, tail) })
          })
      }
  }
}

///|
/// Calls the callback once per entry in row-major order, never for a zero-sized
/// tensor, and once with empty coordinates for a rank-zero scalar.
pub fn[A] tabulate(
  dimensions : @core.Chain[@core.Nat],
  entry : (@core.Chain[@core.Nat]) -> A,
) -> Tensor[A] {
  { dimensions, values: @core.map(coordinates(dimensions), entry), }
}

///|
fn offset(
  dimensions : @core.Chain[@core.Nat],
  indices : @core.Chain[@core.Nat],
  accumulated : @core.Nat,
) -> Result[@core.Nat, TensorError] {
  match (dimensions, indices) {
    (Nil, Nil) => Ok(accumulated)
    (Cons(size, rest), Cons(index, tail)) =>
      match @core.compare(index, size) {
        Less =>
          offset(
            rest,
            tail,
            @core.add(@core.multiply(accumulated, size), index),
          )
        _ => Err(CoordinateOutOfBounds)
      }
    _ => Err(CoordinateRankMismatch)
  }
}

///|
/// Rank mismatch is checked before coordinate bounds. No value is fabricated.
pub fn[A] at(
  value : Tensor[A],
  indices : @core.Chain[@core.Nat],
) -> Result[A, TensorError] {
  if !@core.length(indices).equal(rank(value)) {
    return Err(CoordinateRankMismatch)
  }
  match offset(value.dimensions, indices, @core.Nat::Zero) {
    Err(error) => Err(error)
    Ok(index) =>
      match @core.nth(value.values, index) {
        None => Err(InternalShape)
        Some(entry) => Ok(entry)
      }
  }
}

///|
pub fn[A, B] map(value : Tensor[A], transform : (A) -> B) -> Tensor[B] {
  { dimensions: value.dimensions, values: @core.map(value.values, transform), }
}

///|
pub fn[A, B, C] zip(
  left : Tensor[A],
  right : Tensor[B],
  combine : (A, B) -> C,
) -> Result[Tensor[C], TensorError] {
  if !left.dimensions.equal(right.dimensions) {
    return Err(ShapeMismatch)
  }
  match @core.zip(left.values, right.values) {
    None => Err(InternalShape)
    Some(pairs) =>
      Ok({
        dimensions: left.dimensions,
        values: @core.map(pairs, fn(pair) {
          let (a, b) = pair
          combine(a, b)
        }),
      })
  }
}

///|
fn[A, B] traverse(
  values : @core.Chain[A],
  transform : (A) -> Result[B, TensorError],
) -> Result[@core.Chain[B], TensorError] {
  match values {
    Nil => Ok(Nil)
    Cons(head, tail) =>
      match transform(head) {
        Err(error) => Err(error)
        Ok(value) =>
          match traverse(tail, transform) {
            Err(error) => Err(error)
            Ok(rest) => Ok(Cons(value, rest))
          }
      }
  }
}

///|
fn[A] tabulate_result(
  dimensions : @core.Chain[@core.Nat],
  entry : (@core.Chain[@core.Nat]) -> Result[A, TensorError],
) -> Result[Tensor[A], TensorError] {
  match traverse(coordinates(dimensions), entry) {
    Err(error) => Err(error)
    Ok(values) => Ok({ dimensions, values, })
  }
}

///|
fn distinct(values : @core.Chain[@core.Nat]) -> Bool {
  match values {
    Nil => true
    Cons(head, tail) =>
      !@core.any(tail, fn(other) { head.equal(other) }) && distinct(tail)
  }
}

///|
fn position(
  values : @core.Chain[@core.Nat],
  wanted : @core.Nat,
  index : @core.Nat,
) -> @core.Nat? {
  match values {
    Nil => None
    Cons(head, tail) =>
      match head.equal(wanted) {
        true => Some(index)
        false => position(tail, wanted, @core.Nat::Succ(index))
      }
  }
}

///|
/// Output axis j corresponds to input axis order[j]. Order must be a bijection.
/// An empty order is valid exactly for a scalar. Zero axes are still permuted.
pub fn[A] permute(
  value : Tensor[A],
  order : @core.Chain[@core.Nat],
) -> Result[Tensor[A], TensorError] {
  let n = rank(value)
  if !@core.length(order).equal(n) {
    return Err(PermutationRankMismatch)
  }
  if !@core.all(order, fn(axis) { @core.compare(axis, n) is Less }) {
    return Err(PermutationOutOfBounds)
  }
  if !distinct(order) {
    return Err(PermutationNotBijective)
  }
  match
    traverse(order, fn(axis) {
      match @core.nth(value.dimensions, axis) {
        None => Err(InternalShape)
        Some(size) => Ok(size)
      }
    }) {
    Err(error) => Err(error)
    Ok(dimensions) =>
      match
        traverse(@core.indices(n), fn(axis) {
          match position(order, axis, @core.Nat::Zero) {
            None => Err(InternalShape)
            Some(index) => Ok(index)
          }
        }) {
        Err(error) => Err(error)
        Ok(inverse_order) =>
          if @core.any(dimensions, fn(size) { size is Zero }) {
            Ok({ dimensions, values: Nil, })
          } else {
            match permutation_index(value.dimensions, value.values) {
              Err(error) => Err(error)
              Ok((indexed, _)) =>
                tabulate_result(dimensions, fn(indices) {
                  match
                    traverse(inverse_order, fn(axis) {
                      match @core.nth(indices, axis) {
                        None => Err(InternalShape)
                        Some(index) => Ok(index)
                      }
                    }) {
                    Err(error) => Err(error)
                    Ok(original) => permutation_lookup(indexed, original)
                  }
                })
            }
          }
      }
  }
}

///|
/// Tensor product: left axes precede right axes; entries multiply left to right.
/// The supplied dictionary is assumed to obey its semiring laws.
pub fn[A] product(
  arithmetic : @algebra.Semiring[A],
  left : Tensor[A],
  right : Tensor[A],
) -> Tensor[A] {
  let values = concatenate_map(left.values, fn(a) {
    @core.map(right.values, fn(b) { (arithmetic.times)(a, b) })
  })
  { dimensions: @core.append(left.dimensions, right.dimensions), values, }
}
