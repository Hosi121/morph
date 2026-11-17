// Frozen pre-cursor contraction helpers from 974f0a6, for behavior/order comparison.

///|
fn[A] lookup_legacy_sum_terms(
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
        Ok(value) =>
          lookup_legacy_sum_terms(tail, add(accumulated, value), add, term)
      }
  }
}

///|
fn lookup_legacy_remove_axes(
  dimensions : @core.Chain[@core.Nat],
  a : @core.Nat,
  b : @core.Nat,
  axis : @core.Nat,
) -> @core.Chain[@core.Nat] {
  match dimensions {
    Nil => Nil
    Cons(size, rest) => {
      let tail = lookup_legacy_remove_axes(rest, a, b, @core.Nat::Succ(axis))
      if axis.equal(a) || axis.equal(b) {
        tail
      } else {
        Cons(size, tail)
      }
    }
  }
}

///|
fn lookup_legacy_diagonal_coordinates(
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
          match
            lookup_legacy_diagonal_coordinates(rest, tail, a, b, diagonal, next) {
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
fn[A] lookup_legacy_contract(
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
      let dimensions = lookup_legacy_remove_axes(
        value.dimensions,
        a,
        b,
        @core.Nat::Zero,
      )
      tabulate_result(dimensions, fn(output) {
        lookup_legacy_sum_terms(
          @core.indices(size_a),
          arithmetic.zero,
          arithmetic.plus,
          fn(diagonal) {
            match
              lookup_legacy_diagonal_coordinates(
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
          },
        )
      })
    }
    _ => Err(InternalShape)
  }
}

///|
fn[A] lookup_legacy_replace(
  values : @core.Chain[A],
  axis : @core.Nat,
  value : A,
) -> @core.Chain[A]? {
  match (values, axis) {
    (Cons(_, tail), Zero) => Some(Cons(value, tail))
    (Cons(head, tail), Succ(index)) =>
      match lookup_legacy_replace(tail, index, value) {
        None => None
        Some(rest) => Some(Cons(head, rest))
      }
    _ => None
  }
}

///|
/// Apply linear_map[out,in] along one axis, requiring its width to match that
/// axis. The new axis size is the map height; zero input/output sizes are valid.
fn[A] lookup_legacy_mode_product(
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
      match
        lookup_legacy_replace(
          value.dimensions,
          axis,
          @matrix.height(linear_map),
        ) {
        None => Err(InternalShape)
        Some(dimensions) =>
          tabulate_result(dimensions, fn(output) {
            match @core.nth(output, axis) {
              None => Err(InternalShape)
              Some(row_index) =>
                match @core.nth(@matrix.rows(linear_map), row_index) {
                  None => Err(InternalShape)
                  Some(row) =>
                    lookup_legacy_sum_terms(
                      @core.indices(size),
                      arithmetic.zero,
                      arithmetic.plus,
                      fn(index) {
                        match
                          (
                            @core.nth(row, index),
                            lookup_legacy_replace(output, axis, index),
                          ) {
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

///|
fn recorded(
  events : Array[(Bool, @exact.Rational, @exact.Rational)],
) -> @algebra.Semiring[@exact.Rational] {
  {
    zero: @exact.rational_zero(),
    one: @exact.rational_one(),
    plus: fn(a, b) {
      events.push((false, a, b))
      @exact.rational_add(a, b)
    },
    times: fn(a, b) {
      events.push((true, a, b))
      @exact.rational_multiply(a, b)
    },
  }
}

///|
test "contraction and mode product retain exact legacy callback sequence" {
  for dimensions in small_shapes(3) {
    let value = numbered(dimensions)
    for a in 0..<dimensions.length() {
      for b in 0..<dimensions.length() {
        let before = []
        let after = []
        assert_eq(
          contract(recorded(after), value, @oracle.nat(a), @oracle.nat(b)),
          lookup_legacy_contract(
            recorded(before),
            value,
            @oracle.nat(a),
            @oracle.nat(b),
          ),
        )
        assert_eq(after, before)
      }
      for height in 0..<3 {
        let rows = Array::makei(height, fn(i) {
          Array::makei(dimensions[a], fn(j) { i - j })
        })
        let linear = rational_matrix(rows, dimensions[a])
        let before = []
        let after = []
        assert_eq(
          mode_product(value, @oracle.nat(a), linear, recorded(after)),
          lookup_legacy_mode_product(
            value,
            @oracle.nat(a),
            linear,
            recorded(before),
          ),
        )
        assert_eq(after, before)
      }
    }
  }
}
