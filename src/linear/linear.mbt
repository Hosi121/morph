///|
/// Reduced row echelon form and its pivot columns. The factor is the signed
/// product of original pivots; for full-rank square matrices it is the determinant.
#derive(Eq, Debug)
pub(all) struct Reduction {
  matrix : @matrix.Matrix[@exact.Rational]
  pivots : @core.Chain[@core.Nat]
  factor : @exact.Rational
}

///|
pub extend Reduction with Eq::{equal, not_equal}

///|
pub extend Reduction with Debug::{to_repr}

///|
/// First nonzero pivot, remaining rows, and parity of the row permutation.
fn pivot(
  rows : @core.Chain[@core.Chain[@exact.Rational]],
  column : @core.Nat,
) -> (
  @exact.Nonzero,
  @core.Chain[@exact.Rational],
  @core.Chain[@core.Chain[@exact.Rational]],
  Bool,
)? {
  match rows {
    Nil => None
    Cons(row, rest) => {
      let value = match @core.nth(row, column) {
        None => None
        Some(value) => @exact.nonzero(value)
      }
      match value {
        Some(nonzero) => Some((nonzero, row, rest, false))
        None =>
          match pivot(rest, column) {
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
fn eliminate(
  row : @core.Chain[@exact.Rational],
  basis : @core.Chain[@exact.Rational],
  column : @core.Nat,
) -> @core.Chain[@exact.Rational] {
  match (@core.nth(row, column), @core.zip(row, basis)) {
    (Some(factor), Some(cells)) =>
      @core.map(cells, fn(cell) {
        let (old, pivot) = cell
        @exact.rational_subtract(old, @exact.rational_multiply(factor, pivot))
      })
    _ => row
  }
}

///|
/// Gauss-Jordan elimination with exact rational arithmetic and row pivoting.
/// None is an internal shape guard; every checked Matrix should return Some.
pub fn rref(input : @matrix.Matrix[@exact.Rational]) -> Reduction? {
  fn reduce(
    rows : @core.Chain[@core.Chain[@exact.Rational]],
    todo : @core.Nat,
    column : @core.Nat,
  ) -> (
    @core.Chain[@core.Chain[@exact.Rational]],
    @core.Chain[@core.Nat],
    @exact.Rational,
  ) {
    match todo {
      Zero => (rows, Nil, @exact.rational_one())
      Succ(rest) =>
        match pivot(rows, column) {
          None => reduce(rows, rest, Succ(column))
          Some((value, chosen, others, parity)) => {
            let inverse = @exact.reciprocal(value)
            let normalized = @core.map(chosen, fn(x) {
              @exact.rational_multiply(x, inverse)
            })
            let below = @core.map(others, fn(row) {
              eliminate(row, normalized, column)
            })
            let (lower_rows, lower_pivots, lower_factor) = reduce(
              below,
              rest,
              Succ(column),
            )
            fn clear_above(
              row : @core.Chain[@exact.Rational],
              bases : @core.Chain[@core.Chain[@exact.Rational]],
              pivots : @core.Chain[@core.Nat],
            ) -> @core.Chain[@exact.Rational] {
              match (bases, pivots) {
                (Cons(basis, bt), Cons(pivot, pt)) =>
                  clear_above(eliminate(row, basis, pivot), bt, pt)
                _ => row
              }
            }
            let factor = @exact.rational_multiply(
              @exact.nonzero_value(value),
              lower_factor,
            )
            let signed = match parity {
              true => @exact.rational_negate(factor)
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

///|
pub fn determinant(input : @matrix.Matrix[@exact.Rational]) -> @exact.Rational? {
  match @core.compare(@matrix.height(input), @matrix.width(input)) {
    Equal =>
      match rref(input) {
        None => None
        Some(reduced) =>
          match
            @core.compare(@core.length(reduced.pivots), @matrix.width(input)) {
            Equal => Some(reduced.factor)
            _ => Some(@exact.rational_zero())
          }
      }
    _ => None
  }
}

///|
#derive(Eq, Debug)
pub(all) enum Solution {
  Unique(@core.Chain[@exact.Rational])
  Affine(
    @core.Chain[@exact.Rational],
    @core.Chain[@core.Chain[@exact.Rational]]
  )
  Inconsistent
}

///|
pub extend Solution with Eq::{equal, not_equal}

///|
pub extend Solution with Debug::{to_repr}

///|
/// Return a particular solution and a nullspace basis for underdetermined systems.
pub fn solve(
  a : @matrix.Matrix[@exact.Rational],
  b : @core.Chain[@exact.Rational],
) -> Solution? {
  let n = @matrix.width(a)
  match @core.zip(@matrix.rows(a), b) {
    None => None
    Some(pairs) => {
      let augmented = @core.map(pairs, fn(pair) {
        let (row, rhs) = pair
        @core.append(row, Cons(rhs, Nil))
      })
      match @matrix.matrix(Succ(n), augmented) {
        None => None
        Some(matrix) =>
          match rref(matrix) {
            None => None
            Some(reduced) => {
              let zero = @exact.rational_zero()
              let contradictory = @core.any(@matrix.rows(reduced.matrix), fn(
                row,
              ) {
                let left_zero = @core.all(@core.take(n, row), fn(x) {
                  match @exact.nonzero(x) {
                    None => true
                    Some(_) => false
                  }
                })
                match (@core.nth(row, n), left_zero) {
                  (Some(rhs), true) =>
                    match @exact.nonzero(rhs) {
                      Some(_) => true
                      None => false
                    }
                  _ => false
                }
              })
              match contradictory {
                true => Some(Inconsistent)
                false => {
                  let pivot_rows = @core.take(
                    @core.length(reduced.pivots),
                    @matrix.rows(reduced.matrix),
                  )
                  match @core.zip(reduced.pivots, pivot_rows) {
                    None => None
                    Some(pivot_pairs) => {
                      fn row_for(
                        variable : @core.Nat,
                      ) -> @core.Chain[@exact.Rational]? {
                        fn find(
                          pairs : @core.Chain[
                            (@core.Nat, @core.Chain[@exact.Rational]),
                          ],
                        ) -> @core.Chain[@exact.Rational]? {
                          match pairs {
                            Nil => None
                            Cons((column, row), rest) =>
                              match @core.compare(column, variable) {
                                Equal => Some(row)
                                _ => find(rest)
                              }
                          }
                        }
                        find(pivot_pairs)
                      }
                      let columns = @core.indices(n)
                      let free = @core.filter(columns, fn(column) {
                        match row_for(column) {
                          None => true
                          Some(_) => false
                        }
                      })
                      let particular = @core.map(columns, fn(column) {
                        match row_for(column) {
                          None => zero
                          Some(row) =>
                            match @core.nth(row, n) {
                              Some(value) => value
                              None => zero
                            }
                        }
                      })
                      let basis = @core.map(free, fn(free_column) {
                        @core.map(columns, fn(column) {
                          match @core.compare(column, free_column) {
                            Equal => @exact.rational_one()
                            _ =>
                              match row_for(column) {
                                None => zero
                                Some(row) =>
                                  match @core.nth(row, free_column) {
                                    Some(value) => @exact.rational_negate(value)
                                    None => zero
                                  }
                              }
                          }
                        })
                      })
                      match free {
                        Nil => Some(Unique(particular))
                        _ => Some(Affine(particular, basis))
                      }
                    }
                  }
                }
              }
            }
          }
      }
    }
  }
}

///|
/// One Gauss-Jordan reduction of (A | I), rejecting singular or nonsquare A.
pub fn inverse(
  input : @matrix.Matrix[@exact.Rational],
) -> @matrix.Matrix[@exact.Rational]? {
  let n = @matrix.width(input)
  match @core.compare(@matrix.height(input), n) {
    Equal => {
      let columns = @core.indices(n)
      let identities = @core.map(columns, fn(i) {
        @core.map(columns, fn(j) {
          match @core.compare(i, j) {
            Equal => @exact.rational_one()
            _ => @exact.rational_zero()
          }
        })
      })
      match @core.zip(@matrix.rows(input), identities) {
        None => None
        Some(pairs) =>
          match
            @matrix.matrix(
              @core.add(n, n),
              @core.map(pairs, fn(pair) {
                let (row, identity) = pair
                @core.append(row, identity)
              }),
            ) {
            None => None
            Some(augmented) =>
              match rref(augmented) {
                None => None
                Some(reduced) =>
                  match @core.zip(reduced.pivots, columns) {
                    None => None
                    Some(pivots) =>
                      match
                        @core.all(pivots, fn(pair) {
                          let (actual, expected) = pair
                          match @core.compare(actual, expected) {
                            Equal => true
                            _ => false
                          }
                        }) {
                        false => None
                        true =>
                          @matrix.matrix(
                            n,
                            @core.map(@matrix.rows(reduced.matrix), fn(row) {
                              @core.drop(n, row)
                            }),
                          )
                      }
                  }
              }
          }
      }
    }
    _ => None
  }
}
