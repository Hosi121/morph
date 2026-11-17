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
fn nullspace(
  width : @core.Nat,
  pairs : @core.Chain[(@core.Nat, @core.Chain[Bool])],
) -> @core.Chain[@core.Chain[Bool]] {
  let columns = @core.indices(width)
  let free = @core.filter(columns, fn(column) { row_for(pairs, column) is None })
  @core.map(free, fn(free_column) {
    @core.map(columns, fn(column) {
      match @core.compare(column, free_column) {
        Equal => true
        _ =>
          match row_for(pairs, column) {
            None => false
            Some(row) => @core.nth(row, free_column).equal(Some(true))
          }
      }
    })
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
  match factor(input) {
    None => None
    Some(value) => solve_factor(value, rhs)
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
