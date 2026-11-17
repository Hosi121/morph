///|
fn remove_axes(
  dimensions : @core.Chain[@core.Nat],
  a : @core.Nat,
  b : @core.Nat,
  axis : @core.Nat,
) -> @core.Chain[@core.Nat] {
  match dimensions {
    Nil => Nil
    Cons(size, rest) => {
      let tail = remove_axes(rest, a, b, @core.Nat::Succ(axis))
      if axis.equal(a) || axis.equal(b) {
        tail
      } else {
        Cons(size, tail)
      }
    }
  }
}

///|
/// Sum over the diagonal of two distinct equal-sized axes. Remaining axes keep
/// their order. Contracting zero-sized axes produces additive zero per output.
pub fn[A] contract(
  arithmetic : @algebra.Semiring[A],
  value : Tensor[A],
  a : @core.Nat,
  b : @core.Nat,
) -> Result[Tensor[A], TensorError] {
  let n = rank(value)
  if !(@core.compare(a, n) is Less) || !(@core.compare(b, n) is Less) {
    return Err(AxisOutOfBounds)
  }
  if a.equal(b) {
    return Err(RepeatedAxis)
  }
  match (@core.nth(value.dimensions, a), @core.nth(value.dimensions, b)) {
    (Some(size_a), Some(size_b)) => {
      if !size_a.equal(size_b) {
        return Err(AxisSizeMismatch)
      }
      let dimensions = remove_axes(value.dimensions, a, b, @core.Nat::Zero)
      contract_cursor(value, a, b, size_a, dimensions, arithmetic)
    }
    _ => Err(InternalShape)
  }
}

///|
fn[A] replace(
  values : @core.Chain[A],
  axis : @core.Nat,
  value : A,
) -> @core.Chain[A]? {
  match (values, axis) {
    (Cons(_, tail), Zero) => Some(Cons(value, tail))
    (Cons(head, tail), Succ(index)) =>
      match replace(tail, index, value) {
        None => None
        Some(rest) => Some(Cons(head, rest))
      }
    _ => None
  }
}

///|
/// Apply linear_map[out,in] along one axis, requiring its width to match that
/// axis. The new axis size is the map height; zero input/output sizes are valid.
pub fn[A] mode_product(
  value : Tensor[A],
  axis : @core.Nat,
  linear_map : @matrix.Matrix[A],
  arithmetic : @algebra.Semiring[A],
) -> Result[Tensor[A], TensorError] {
  if !(@core.compare(axis, rank(value)) is Less) {
    return Err(AxisOutOfBounds)
  }
  match @core.nth(value.dimensions, axis) {
    None => Err(InternalShape)
    Some(size) => {
      if !@matrix.width(linear_map).equal(size) {
        return Err(ModeWidthMismatch)
      }
      match replace(value.dimensions, axis, @matrix.height(linear_map)) {
        None => Err(InternalShape)
        Some(dimensions) =>
          mode_cursor(value, axis, size, linear_map, dimensions, arithmetic)
      }
    }
  }
}
