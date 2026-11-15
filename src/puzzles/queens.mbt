///|
#derive(Eq, Debug)
pub(all) struct Queen {
  row : @core.Nat
  column : @core.Nat
}

///|
pub extend Queen with Eq::{equal, not_equal}

///|
pub extend Queen with Debug::{to_repr}

///|
/// Rows/columns are primary constraints, both diagonal families secondary.
pub fn queens_problem(n : @core.Nat) -> @exactcover.Problem? {
  match n {
    Zero => @exactcover.problem(Nil, Nil, Nil)
    Succ(previous) => {
      let twice = @core.add(n, n)
      let diagonal_count = @core.add(n, previous)
      let second_diagonal = @core.add(twice, diagonal_count)
      let primary = @core.indices(twice)
      let secondary = @core.map(
        @core.indices(@core.add(diagonal_count, diagonal_count)),
        fn(index) { @core.add(twice, index) },
      )
      let coordinates = @core.indices(n)
      let choices : @core.Chain[@exactcover.Row] = @core.fold_left(
        coordinates,
        @core.Nil,
        fn(found, row) {
          @core.fold_left(coordinates, found, fn(found, column) {
            let label = @core.add(@core.multiply(row, n), column)
            let ascending = @core.add(twice, @core.add(row, column))
            let descending = @core.add(
              second_diagonal,
              @core.subtract(@core.add(previous, row), column),
            )
            @core.Cons(
              @exactcover.Row::{
                label,
                columns: Cons(
                  row,
                  Cons(
                    @core.add(n, column),
                    Cons(ascending, Cons(descending, Nil)),
                  ),
                ),
              },
              found,
            )
          })
        },
      )
      @exactcover.problem(primary, secondary, choices)
    }
  }
}

///|
/// Decode row labels r*n+c from queens_problem and return one placement.
pub fn n_queens(n : @core.Nat) -> @core.Chain[Queen]? {
  fn decode(labels : @core.Chain[@core.Nat]) -> @core.Chain[Queen]? {
    match labels {
      Nil => Some(Nil)
      Cons(label, rest) =>
        match (@core.divmod(label, n), decode(rest)) {
          (Some((row, column)), Some(rest)) =>
            Some(Cons({ row, column, }, rest))
          _ => None
        }
    }
  }
  match queens_problem(n) {
    None => None
    Some(problem) =>
      match @exactcover.solve(problem) {
        None => None
        Some(labels) =>
          match decode(labels) {
            None => None
            Some(queens) =>
              Some(
                @sorting.merge_sort(queens, fn(a, b) {
                  @core.compare(a.row, b.row)
                }),
              )
          }
      }
  }
}

///|
/// Check row, column and both diagonal constraints without invoking Algorithm X.
pub fn check_queens(n : @core.Nat, queens : @core.Chain[Queen]) -> Bool {
  fn safe(queens : @core.Chain[Queen]) -> Bool {
    match queens {
      Nil => true
      Cons(q, rest) => {
        let bounded = match
          (@core.compare(q.row, n), @core.compare(q.column, n)) {
          (Less, Less) => true
          _ => false
        }
        let disjoint = @core.all(rest, fn(other) {
          match
            (
              @core.compare(q.row, other.row),
              @core.compare(q.column, other.column),
              @core.compare(
                @core.add(q.row, q.column),
                @core.add(other.row, other.column),
              ),
              @core.compare(
                @core.add(q.row, other.column),
                @core.add(other.row, q.column),
              ),
            ) {
            (Equal, _, _, _)
            | (_, Equal, _, _)
            | (_, _, Equal, _)
            | (_, _, _, Equal) => false
            _ => true
          }
        })
        match (bounded, disjoint) {
          (true, true) => safe(rest)
          _ => false
        }
      }
    }
  }
  match @core.compare(@core.length(queens), n) {
    Equal => safe(queens)
    _ => false
  }
}
