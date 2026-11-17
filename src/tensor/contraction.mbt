///|
fn[A] sum_terms(
  indices : @core.Chain[@core.Nat],
  accumulated : A,
  add : (A, A) -> A,
  term : (@core.Nat) -> Result[A, TensorError],
) -> Result[A, TensorError] {
  match indices {
    Nil => Ok(accumulated)
    Cons(head, tail) =>
      match term(head) {
        Err(error) => Err(error)
        Ok(value) => sum_terms(tail, add(accumulated, value), add, term)
      }
  }
}

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
fn diagonal_coordinates(
  dimensions : @core.Chain[@core.Nat],
  output : @core.Chain[@core.Nat],
  a : @core.Nat,
  b : @core.Nat,
  diagonal : @core.Nat,
  axis : @core.Nat,
) -> Result[@core.Chain[@core.Nat], TensorError] {
  match dimensions {
    Nil =>
      match output {
        Nil => Ok(Nil)
        _ => Err(InternalShape)
      }
    Cons(_, rest) => {
      let selected = axis.equal(a) || axis.equal(b)
      let next = @core.Nat::Succ(axis)
      let pair = if selected {
        Some((diagonal, output))
      } else {
        match output {
          Nil => None
          Cons(head, tail) => Some((head, tail))
        }
      }
      match pair {
        None => Err(InternalShape)
        Some((head, tail)) =>
          match diagonal_coordinates(rest, tail, a, b, diagonal, next) {
            Err(error) => Err(error)
            Ok(indices) => Ok(Cons(head, indices))
          }
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
      tabulate_result(dimensions, fn(output) {
        sum_terms(@core.indices(size_a), arithmetic.zero, arithmetic.plus, fn(
          diagonal,
        ) {
          match
            diagonal_coordinates(
              value.dimensions,
              output,
              a,
              b,
              diagonal,
              @core.Nat::Zero,
            ) {
            Err(error) => Err(error)
            Ok(indices) => at(value, indices)
          }
        })
      })
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
          tabulate_result(dimensions, fn(output) {
            match @core.nth(output, axis) {
              None => Err(InternalShape)
              Some(row_index) =>
                match @core.nth(@matrix.rows(linear_map), row_index) {
                  None => Err(InternalShape)
                  Some(row) =>
                    sum_terms(
                      @core.indices(size),
                      arithmetic.zero,
                      arithmetic.plus,
                      fn(index) {
                        match
                          (@core.nth(row, index), replace(output, axis, index)) {
                          (Some(coefficient), Some(indices)) =>
                            match at(value, indices) {
                              Err(error) => Err(error)
                              Ok(entry) =>
                                Ok((arithmetic.times)(coefficient, entry))
                            }
                          _ => Err(InternalShape)
                        }
                      },
                    )
                }
            }
          })
      }
    }
  }
}
