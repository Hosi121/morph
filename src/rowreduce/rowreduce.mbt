///|
/// Laws are assumed: a commutative field, canonical zero, inverse None iff zero.
/// The record is an operation dictionary, not a formal proof of the field laws.
pub(all) struct Field[A] {
  zero : A
  one : A
  add : (A, A) -> A
  subtract : (A, A) -> A
  negate : (A) -> A
  multiply : (A, A) -> A
  inverse : (A) -> A?
}

///|
priv struct Nonzero[A] {
  value : A
  inverse : A
}

///|
fn[A] nonzero(field : Field[A], value : A) -> Nonzero[A]? {
  match (field.inverse)(value) {
    None => None
    Some(inverse) => Some({ value, inverse, })
  }
}

///|
/// Reduced row echelon form and its pivot columns. The factor is the signed
/// product of original pivots; for full-rank square matrices it is the determinant.
#derive(Eq, Debug)
pub(all) struct Reduction[A] {
  matrix : @matrix.Matrix[A]
  pivots : @core.Chain[@core.Nat]
  factor : A
}

///|
pub extend Reduction with Eq::{equal, not_equal}

///|
pub extend Reduction with Debug::{to_repr}

///|
/// First nonzero pivot, remaining rows, and parity of the row permutation.
fn[A] pivot(
  field : Field[A],
  rows : @core.Chain[@core.Chain[A]],
  column : @core.Nat,
) -> (Nonzero[A], @core.Chain[A], @core.Chain[@core.Chain[A]], Bool)? {
  match rows {
    Nil => None
    Cons(row, rest) => {
      let value = match @core.nth(row, column) {
        None => None
        Some(value) => nonzero(field, value)
      }
      match value {
        Some(nonzero) => Some((nonzero, row, rest, false))
        None =>
          match pivot(field, rest, column) {
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
fn[A] eliminate(
  field : Field[A],
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
/// Gauss-Jordan elimination with a supplied exact field dictionary and row pivoting.
/// None is an internal shape guard; every checked Matrix should return Some.
pub fn[A] rref(field : Field[A], input : @matrix.Matrix[A]) -> Reduction[A]? {
  fn reduce(
    rows : @core.Chain[@core.Chain[A]],
    todo : @core.Nat,
    column : @core.Nat,
  ) -> (@core.Chain[@core.Chain[A]], @core.Chain[@core.Nat], A) {
    match todo {
      Zero => (rows, Nil, field.one)
      Succ(rest) =>
        match pivot(field, rows, column) {
          None => reduce(rows, rest, Succ(column))
          Some((value, chosen, others, parity)) => {
            let inverse = value.inverse
            let normalized = @core.map(chosen, fn(x) {
              (field.multiply)(x, inverse)
            })
            let below = @core.map(others, fn(row) {
              eliminate(field, row, normalized, column)
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
                  clear_above(eliminate(field, row, basis, pivot), bt, pt)
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

///|
pub fn[A] determinant(field : Field[A], input : @matrix.Matrix[A]) -> A? {
  match @core.compare(@matrix.height(input), @matrix.width(input)) {
    Equal =>
      match rref(field, input) {
        None => None
        Some(reduced) =>
          match
            @core.compare(@core.length(reduced.pivots), @matrix.width(input)) {
            Equal => Some(reduced.factor)
            _ => Some(field.zero)
          }
      }
    _ => None
  }
}

///|
#derive(Eq, Debug)
pub(all) enum Solution[A] {
  Unique(@core.Chain[A])
  Affine(@core.Chain[A], @core.Chain[@core.Chain[A]])
  Inconsistent
}

///|
pub extend Solution with Eq::{equal, not_equal}

///|
pub extend Solution with Debug::{to_repr}

///|
/// Return a particular solution and a nullspace basis for underdetermined systems.
pub fn[A] solve(
  field : Field[A],
  a : @matrix.Matrix[A],
  b : @core.Chain[A],
) -> Solution[A]? {
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
          match rref(field, matrix) {
            None => None
            Some(reduced) => {
              let zero = field.zero
              let contradictory = @core.any(@matrix.rows(reduced.matrix), fn(
                row,
              ) {
                let left_zero = @core.all(@core.take(n, row), fn(x) {
                  match nonzero(field, x) {
                    None => true
                    Some(_) => false
                  }
                })
                match (@core.nth(row, n), left_zero) {
                  (Some(rhs), true) =>
                    match nonzero(field, rhs) {
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
                      fn row_for(variable : @core.Nat) -> @core.Chain[A]? {
                        fn find(
                          pairs : @core.Chain[(@core.Nat, @core.Chain[A])],
                        ) -> @core.Chain[A]? {
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
                            Equal => field.one
                            _ =>
                              match row_for(column) {
                                None => zero
                                Some(row) =>
                                  match @core.nth(row, free_column) {
                                    Some(value) => (field.negate)(value)
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
pub fn[A] inverse(
  field : Field[A],
  input : @matrix.Matrix[A],
) -> @matrix.Matrix[A]? {
  let n = @matrix.width(input)
  match @core.compare(@matrix.height(input), n) {
    Equal => {
      let columns = @core.indices(n)
      let identities = @core.map(columns, fn(i) {
        @core.map(columns, fn(j) {
          match @core.compare(i, j) {
            Equal => field.one
            _ => field.zero
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
              match rref(field, augmented) {
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
