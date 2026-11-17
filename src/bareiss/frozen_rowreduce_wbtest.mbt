// Frozen, test-only Gauss-Jordan implementation from 4d9e6c4 rowreduce.mbt.
// Its original bytes and normalized copied regions are checked by
// tools/benchmark_bareiss.py --check-reference-only. Production rowreduce changes
// must not change the determinant benchmark's historical reference arithmetic.

///|
priv struct BareissReferenceNonzero[A] {
  value : A
  inverse : A
}

///|
fn[A] bareiss_reference_nonzero(
  field : @rowreduce.Field[A],
  value : A,
) -> BareissReferenceNonzero[A]? {
  match (field.inverse)(value) {
    None => None
    Some(inverse) => Some({ value, inverse, })
  }
}

///|
fn[A] bareiss_reference_pivot(
  field : @rowreduce.Field[A],
  rows : @core.Chain[@core.Chain[A]],
  column : @core.Nat,
) -> (
  BareissReferenceNonzero[A],
  @core.Chain[A],
  @core.Chain[@core.Chain[A]],
  Bool,
)? {
  match rows {
    Nil => None
    Cons(row, rest) => {
      let value = match @core.nth(row, column) {
        None => None
        Some(value) => bareiss_reference_nonzero(field, value)
      }
      match value {
        Some(nonzero) => Some((nonzero, row, rest, false))
        None =>
          match bareiss_reference_pivot(field, rest, column) {
            None => None
            Some((p, chosen, others, parity)) =>
              Some(
                (
                  p,
                  chosen,
                  Cons(row, others),
                  match parity {
                    true => false
                    false => true
                  },
                ),
              )
          }
      }
    }
  }
}

///|
fn[A] bareiss_reference_eliminate(
  field : @rowreduce.Field[A],
  row : @core.Chain[A],
  basis : @core.Chain[A],
  column : @core.Nat,
) -> @core.Chain[A] {
  match (@core.nth(row, column), @core.zip(row, basis)) {
    (Some(factor), Some(cells)) =>
      @core.map(cells, fn(cell) {
        let (old, pivot) = cell
        (field.subtract)(old, (field.multiply)(factor, pivot))
      })
    _ => row
  }
}

///|
fn[A] bareiss_reference_rref(
  field : @rowreduce.Field[A],
  input : @matrix.Matrix[A],
) -> @rowreduce.Reduction[A]? {
  fn reduce(
    rows : @core.Chain[@core.Chain[A]],
    todo : @core.Nat,
    column : @core.Nat,
  ) -> (@core.Chain[@core.Chain[A]], @core.Chain[@core.Nat], A) {
    match todo {
      Zero => (rows, Nil, field.one)
      Succ(rest) =>
        match bareiss_reference_pivot(field, rows, column) {
          None => reduce(rows, rest, Succ(column))
          Some((value, chosen, others, parity)) => {
            let inverse = value.inverse
            let normalized = @core.map(chosen, fn(x) {
              (field.multiply)(x, inverse)
            })
            let below = @core.map(others, fn(row) {
              bareiss_reference_eliminate(field, row, normalized, column)
            })
            let (lower_rows, lower_pivots, lower_factor) = reduce(
              below,
              rest,
              Succ(column),
            )
            fn clear_above(
              row : @core.Chain[A],
              bases : @core.Chain[@core.Chain[A]],
              pivots : @core.Chain[@core.Nat],
            ) -> @core.Chain[A] {
              match (bases, pivots) {
                (Cons(basis, bt), Cons(pivot, pt)) =>
                  clear_above(
                    bareiss_reference_eliminate(field, row, basis, pivot),
                    bt,
                    pt,
                  )
                _ => row
              }
            }
            let factor = (field.multiply)(value.value, lower_factor)
            let signed = match parity {
              true => (field.negate)(factor)
              false => factor
            }
            (
              Cons(
                clear_above(normalized, lower_rows, lower_pivots),
                lower_rows,
              ),
              Cons(column, lower_pivots),
              signed,
            )
          }
        }
    }
  }
  let (rows, pivots, factor) = reduce(
    @matrix.rows(input),
    @matrix.width(input),
    Zero,
  )
  match @matrix.matrix(@matrix.width(input), rows) {
    None => None
    Some(matrix) => Some({ matrix, pivots, factor, })
  }
}
