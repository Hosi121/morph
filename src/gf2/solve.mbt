///|
fn row_for(
  pairs : @core.Chain[(@core.Nat, @core.Chain[Bool])],
  variable : @core.Nat,
) -> @core.Chain[Bool]? {
  match pairs {
    Nil => None
    Cons((column, row), rest) =>
      match @core.compare(column, variable) {
        Equal => Some(row)
        _ => row_for(rest, variable)
      }
  }
}

///|
/// Both internal callers supply increasing canonical RREF pivots.
/// Both cursors increase: a pivot passed once never needs another scan.
fn free_columns(
  columns : @core.Chain[@core.Nat],
  pairs : @core.Chain[(@core.Nat, @core.Chain[Bool])],
) -> @core.Chain[@core.Nat] {
  match (columns, pairs) {
    (Nil, _) => Nil
    (_, Nil) => columns
    (Cons(column, rest), Cons((pivot, _), tail)) =>
      match @core.compare(column, pivot) {
        Less => Cons(column, free_columns(rest, pairs))
        Equal => free_columns(rest, tail)
        Greater => free_columns(columns, tail)
      }
  }
}

///|
fn nullspace_vector(
  columns : @core.Chain[@core.Nat],
  pairs : @core.Chain[(@core.Nat, @core.Chain[Bool])],
  free_column : @core.Nat,
) -> @core.Chain[Bool] {
  match (columns, pairs) {
    (Nil, _) => Nil
    (Cons(column, rest), Nil) =>
      Cons(column.equal(free_column), nullspace_vector(rest, Nil, free_column))
    (Cons(column, rest), Cons((pivot, row), tail)) =>
      match @core.compare(column, pivot) {
        Less =>
          Cons(
            column.equal(free_column),
            nullspace_vector(rest, pairs, free_column),
          )
        Equal =>
          Cons(
            @core.nth(row, free_column).equal(Some(true)),
            nullspace_vector(rest, tail, free_column),
          )
        Greater => nullspace_vector(columns, tail, free_column)
      }
  }
}

///|
fn nullspace(
  width : @core.Nat,
  pairs : @core.Chain[(@core.Nat, @core.Chain[Bool])],
) -> @core.Chain[@core.Chain[Bool]] {
  let columns = @core.indices(width)
  @core.map(free_columns(columns, pairs), fn(free_column) {
    nullspace_vector(columns, pairs, free_column)
  })
}

///|
/// Free variables are enumerated in ascending column order, as in rowreduce.solve.
pub fn nullspace_factor(
  value : Factorization,
) -> @core.Chain[@core.Chain[Bool]] {
  let reduced = value.reduction
  let rows = @core.take(
    @core.length(reduced.pivots),
    @matrix.rows(reduced.matrix),
  )
  match @core.zip(reduced.pivots, rows) {
    None => Nil
    Some(pairs) => nullspace(@matrix.width(value.source), pairs)
  }
}

///|
fn apply_rhs(
  rhs : @core.Chain[Bool],
  operation : Operation,
) -> @core.Chain[Bool] {
  match operation {
    Swap(a, b) =>
      match (@core.nth(rhs, a), @core.nth(rhs, b)) {
        (Some(x), Some(y)) => replace(replace(rhs, a, y), b, x)
        _ => rhs
      }
    Add(target, source) =>
      match (@core.nth(rhs, target), @core.nth(rhs, source)) {
        (Some(x), Some(y)) => replace(rhs, target, xor(x, y))
        _ => rhs
      }
  }
}

///|
/// Reuse the existing decomposition: only apply its row operations to the RHS.
pub fn solve_factor(
  value : Factorization,
  rhs : @core.Chain[Bool],
) -> @rowreduce.Solution[Bool]? {
  match @core.compare(@core.length(rhs), @matrix.height(value.source)) {
    Equal => {
      let transformed = @core.fold_left(
        @core.reverse(value.reverse_operations),
        rhs,
        apply_rhs,
      )
      let reduced = value.reduction
      let rank = @core.length(reduced.pivots)
      if @core.any(@core.drop(rank, transformed), fn(x) { x }) {
        Some(Inconsistent)
      } else {
        match @core.zip(reduced.pivots, @core.take(rank, transformed)) {
          None => None
          Some(pairs) => {
            fn lookup(
              variable : @core.Nat,
              pairs : @core.Chain[(@core.Nat, Bool)],
            ) -> Bool {
              match pairs {
                Nil => false
                Cons((column, value), rest) =>
                  if column.equal(variable) {
                    value
                  } else {
                    lookup(variable, rest)
                  }
              }
            }
            let particular = @core.map(
              @core.indices(@matrix.width(value.source)),
              fn(column) { lookup(column, pairs) },
            )
            let basis = nullspace_factor(value)
            match basis {
              Nil => Some(Unique(particular))
              _ => Some(Affine(particular, basis))
            }
          }
        }
      }
    }
    _ => None
  }
}

///|
pub fn solve(
  input : @matrix.Matrix[Bool],
  rhs : @core.Chain[Bool],
) -> @rowreduce.Solution[Bool]? {
  let width = @matrix.width(input)
  match @core.zip(@matrix.rows(input), rhs) {
    None => None
    Some(pairs) => {
      let augmented = @core.map(pairs, fn(pair) {
        let (row, value) = pair
        @core.append(row, Cons(value, Nil))
      })
      match @matrix.matrix(Succ(width), augmented) {
        None => None
        Some(matrix) =>
          match rref(matrix) {
            None => None
            Some(reduced) => {
              let rows = @matrix.rows(reduced.matrix)
              let inconsistent = @core.any(rows, fn(row) {
                @core.all(@core.take(width, row), fn(value) { !value }) &&
                @core.nth(row, width).equal(Some(true))
              })
              if inconsistent {
                Some(Inconsistent)
              } else {
                match
                  @core.zip(
                    reduced.pivots,
                    @core.take(@core.length(reduced.pivots), rows),
                  ) {
                  None => None
                  Some(pairs) => {
                    let particular = @core.map(@core.indices(width), fn(
                      column,
                    ) {
                      match row_for(pairs, column) {
                        None => false
                        Some(row) => @core.nth(row, width).equal(Some(true))
                      }
                    })
                    let basis = nullspace(width, pairs)
                    match basis {
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

///|
pub fn inverse(input : @matrix.Matrix[Bool]) -> @matrix.Matrix[Bool]? {
  let width = @matrix.width(input)
  match @core.compare(@matrix.height(input), width) {
    Equal =>
      match factor(input) {
        None => None
        Some(value) =>
          match @core.compare(@core.length(value.reduction.pivots), width) {
            Equal => Some(value.transform)
            _ => None
          }
      }
    _ => None
  }
}

///|
pub fn determinant(input : @matrix.Matrix[Bool]) -> Bool? {
  let width = @matrix.width(input)
  match @core.compare(@matrix.height(input), width) {
    Equal =>
      match rref(input) {
        None => None
        Some(result) => Some(@core.length(result.pivots).equal(width))
      }
    _ => None
  }
}
