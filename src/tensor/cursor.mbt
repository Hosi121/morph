///|
/// Split consecutive immutable rows without recomputing flat coordinate offsets.
fn[A] cursor_rows(
  count : @core.Nat,
  width : @core.Nat,
  values : @core.Chain[A],
) -> Result[(@core.Chain[@core.Chain[A]], @core.Chain[A]), TensorError] {
  match count {
    Zero => Ok((Nil, values))
    Succ(remaining) =>
      match @core.split_exact(width, values) {
        None => Err(InternalShape)
        Some((row, tail)) =>
          match cursor_rows(remaining, width, tail) {
            Err(error) => Err(error)
            Ok((rows, rest)) => Ok((Cons(row, rows), rest))
          }
      }
  }
}

///|
fn[A] cursor_heads(
  rows : @core.Chain[@core.Chain[A]],
) -> Result[(@core.Chain[A], @core.Chain[@core.Chain[A]]), TensorError] {
  match rows {
    Nil => Ok((Nil, Nil))
    Cons(row, rest) =>
      match row {
        Nil => Err(InternalShape)
        Cons(head, tail) =>
          match cursor_heads(rest) {
            Err(error) => Err(error)
            Ok((heads, tails)) => Ok((Cons(head, heads), Cons(tail, tails)))
          }
      }
  }
}

///|
/// The callback still visits one complete output cell before the next cell.
fn[A] cursor_columns(
  count : @core.Nat,
  rows : @core.Chain[@core.Chain[A]],
  reduce : (@core.Chain[A]) -> Result[A, TensorError],
) -> Result[@core.Chain[A], TensorError] {
  match count {
    Zero => Ok(Nil)
    Succ(remaining) =>
      match cursor_heads(rows) {
        Err(error) => Err(error)
        Ok((heads, tails)) =>
          match reduce(heads) {
            Err(error) => Err(error)
            Ok(value) =>
              match cursor_columns(remaining, tails, reduce) {
                Err(error) => Err(error)
                Ok(rest) => Ok(Cons(value, rest))
              }
          }
      }
  }
}

///|
fn[A] cursor_dot(
  arithmetic : @algebra.Semiring[A],
  coefficients : @core.Chain[A],
  values : @core.Chain[A],
) -> Result[A, TensorError] {
  match @core.zip(coefficients, values) {
    None => Err(InternalShape)
    Some(pairs) =>
      Ok(
        @core.fold_left(pairs, arithmetic.zero, fn(total, pair) {
          let (coefficient, value) = pair
          let term = (arithmetic.times)(coefficient, value)
          (arithmetic.plus)(total, term)
        }),
      )
  }
}

///|
fn[A] cursor_mapped_block(
  arithmetic : @algebra.Semiring[A],
  rows : @core.Chain[@core.Chain[A]],
  coefficients : @core.Chain[@core.Chain[A]],
  inner : @core.Nat,
) -> Result[@core.Chain[A], TensorError] {
  match coefficients {
    Nil => Ok(Nil)
    Cons(row, rest) =>
      match
        cursor_columns(inner, rows, fn(values) {
          cursor_dot(arithmetic, row, values)
        }) {
        Err(error) => Err(error)
        Ok(values) =>
          match cursor_mapped_block(arithmetic, rows, rest, inner) {
            Err(error) => Err(error)
            Ok(tail) => Ok(@core.append(values, tail))
          }
      }
  }
}

///|
fn[A] cursor_mode_prefix(
  arithmetic : @algebra.Semiring[A],
  outer : @core.Nat,
  axis_size : @core.Nat,
  inner : @core.Nat,
  values : @core.Chain[A],
  coefficients : @core.Chain[@core.Chain[A]],
) -> Result[@core.Chain[A], TensorError] {
  match outer {
    Zero => Ok(Nil)
    Succ(remaining) =>
      match cursor_rows(axis_size, inner, values) {
        Err(error) => Err(error)
        Ok((rows, rest)) =>
          match cursor_mapped_block(arithmetic, rows, coefficients, inner) {
            Err(error) => Err(error)
            Ok(block) =>
              match
                cursor_mode_prefix(
                  arithmetic, remaining, axis_size, inner, rest, coefficients,
                ) {
                Err(error) => Err(error)
                Ok(tail) => Ok(@core.append(block, tail))
              }
          }
      }
  }
}

///|
fn[A] mode_cursor(
  value : Tensor[A],
  axis : @core.Nat,
  axis_size : @core.Nat,
  linear_map : @matrix.Matrix[A],
  dimensions : @core.Chain[@core.Nat],
  arithmetic : @algebra.Semiring[A],
) -> Result[Tensor[A], TensorError] {
  let count = cardinality(dimensions)
  match (count, axis_size) {
    (Zero, _) => Ok({ dimensions, values: Nil, })
    (_, Zero) =>
      Ok({ dimensions, values: @core.replicate(count, arithmetic.zero), })
    _ => {
      let outer = cardinality(@core.take(axis, value.dimensions))
      let inner = cardinality(
        @core.drop(@core.Nat::Succ(axis), value.dimensions),
      )
      match
        cursor_mode_prefix(
          arithmetic,
          outer,
          axis_size,
          inner,
          value.values,
          @matrix.rows(linear_map),
        ) {
        Err(error) => Err(error)
        Ok(values) => Ok({ dimensions, values, })
      }
    }
  }
}

///|
/// In each middle block, keep the selected second-axis row and advance once.
fn[A] cursor_middle(
  middle : @core.Nat,
  block_size : @core.Nat,
  skip : @core.Nat,
  inner : @core.Nat,
  values : @core.Chain[A],
) -> Result[(@core.Chain[A], @core.Chain[A]), TensorError] {
  match middle {
    Zero => Ok((Nil, values))
    Succ(remaining) =>
      match @core.split_exact(block_size, values) {
        None => Err(InternalShape)
        Some((block, rest)) =>
          match @core.split_exact(inner, @core.drop(skip, block)) {
            None => Err(InternalShape)
            Some((selected, _)) =>
              match cursor_middle(remaining, block_size, skip, inner, rest) {
                Err(error) => Err(error)
                Ok((tail, unconsumed)) =>
                  Ok((@core.append(selected, tail), unconsumed))
              }
          }
      }
  }
}

///|
fn[A] cursor_diagonal_rows(
  remaining : @core.Nat,
  diagonal : @core.Nat,
  middle : @core.Nat,
  block_size : @core.Nat,
  inner : @core.Nat,
  values : @core.Chain[A],
) -> Result[(@core.Chain[@core.Chain[A]], @core.Chain[A]), TensorError] {
  match remaining {
    Zero => Ok((Nil, values))
    Succ(rest_count) =>
      match
        cursor_middle(
          middle,
          block_size,
          @core.multiply(diagonal, inner),
          inner,
          values,
        ) {
        Err(error) => Err(error)
        Ok((row, rest)) =>
          match
            cursor_diagonal_rows(
              rest_count,
              @core.Nat::Succ(diagonal),
              middle,
              block_size,
              inner,
              rest,
            ) {
            Err(error) => Err(error)
            Ok((rows, tail)) => Ok((Cons(row, rows), tail))
          }
      }
  }
}

///|
fn[A] cursor_contract_prefix(
  arithmetic : @algebra.Semiring[A],
  outer : @core.Nat,
  axis_size : @core.Nat,
  middle : @core.Nat,
  inner : @core.Nat,
  values : @core.Chain[A],
) -> Result[@core.Chain[A], TensorError] {
  match outer {
    Zero => Ok(Nil)
    Succ(remaining) =>
      match
        cursor_diagonal_rows(
          axis_size,
          @core.Nat::Zero,
          middle,
          @core.multiply(axis_size, inner),
          inner,
          values,
        ) {
        Err(error) => Err(error)
        Ok((rows, rest)) =>
          match
            cursor_columns(@core.multiply(middle, inner), rows, fn(heads) {
              Ok(@core.fold_left(heads, arithmetic.zero, arithmetic.plus))
            }) {
            Err(error) => Err(error)
            Ok(block) =>
              match
                cursor_contract_prefix(
                  arithmetic, remaining, axis_size, middle, inner, rest,
                ) {
                Err(error) => Err(error)
                Ok(tail) => Ok(@core.append(block, tail))
              }
          }
      }
  }
}

///|
fn[A] contract_cursor(
  value : Tensor[A],
  a : @core.Nat,
  b : @core.Nat,
  axis_size : @core.Nat,
  dimensions : @core.Chain[@core.Nat],
  arithmetic : @algebra.Semiring[A],
) -> Result[Tensor[A], TensorError] {
  let count = cardinality(dimensions)
  match (count, axis_size) {
    (Zero, _) => Ok({ dimensions, values: Nil, })
    (_, Zero) =>
      Ok({ dimensions, values: @core.replicate(count, arithmetic.zero), })
    _ => {
      let (first, last) = match @core.compare(a, b) {
        Less => (a, b)
        _ => (b, a)
      }
      let after_first = @core.drop(@core.Nat::Succ(first), value.dimensions)
      let middle_rank = @core.subtract(last, @core.Nat::Succ(first))
      let outer = cardinality(@core.take(first, value.dimensions))
      let middle = cardinality(@core.take(middle_rank, after_first))
      let inner = cardinality(
        @core.drop(@core.Nat::Succ(last), value.dimensions),
      )
      match
        cursor_contract_prefix(
          arithmetic,
          outer,
          axis_size,
          middle,
          inner,
          value.values,
        ) {
        Err(error) => Err(error)
        Ok(values) => Ok({ dimensions, values, })
      }
    }
  }
}
