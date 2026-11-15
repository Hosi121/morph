///|
#derive(Eq, Debug)
pub(all) struct Row {
  label : @core.Nat
  columns : @core.Chain[@core.Nat]
}

///|
pub extend Row with Eq::{equal, not_equal}

///|
pub extend Row with Debug::{to_repr}

///|
/// Primary columns must be covered exactly once; secondary columns at most once.
#derive(Eq, Debug)
pub struct Problem {
  primary : @core.Chain[@core.Nat]
  secondary : @core.Chain[@core.Nat]
  rows : @core.Chain[Row]
}

///|
pub extend Problem with Eq::{equal, not_equal}

///|
pub extend Problem with Debug::{to_repr}

///|
fn contains(xs : @core.Chain[@core.Nat], value : @core.Nat) -> Bool {
  @core.any(xs, fn(other) {
    match @core.compare(value, other) {
      Equal => true
      _ => false
    }
  })
}

///|
fn unique(xs : @core.Chain[@core.Nat]) -> Bool {
  match xs {
    Nil => true
    Cons(x, rest) =>
      match contains(rest, x) {
        true => false
        false => unique(rest)
      }
  }
}

///|
pub fn problem(
  primary : @core.Chain[@core.Nat],
  secondary : @core.Chain[@core.Nat],
  rows : @core.Chain[Row],
) -> Problem? {
  let columns = @core.append(primary, secondary)
  let valid_rows = @core.all(rows, fn(row) {
    match unique(row.columns) {
      false => false
      true => @core.all(row.columns, fn(column) { contains(columns, column) })
    }
  })
  match
    (
      unique(columns),
      unique(@core.map(rows, fn(row) { row.label })),
      valid_rows,
    ) {
    (true, true, true) => Some({ primary, secondary, rows, })
    _ => None
  }
}

///|
fn occurrences(column : @core.Nat, rows : @core.Chain[Row]) -> @core.Nat {
  @core.fold_left(rows, @core.Zero, fn(count, row) {
    match contains(row.columns, column) {
      true => Succ(count)
      false => count
    }
  })
}

///|
/// Algorithm X with the smallest-column heuristic, implemented by immutable
/// filtering rather than mutable dancing links. Returns one solution.
pub fn solve(problem : Problem) -> @core.Chain[@core.Nat]? {
  fn search(
    primary : @core.Chain[@core.Nat],
    rows : @core.Chain[Row],
  ) -> @core.Chain[@core.Nat]? {
    match primary {
      Nil => Some(Nil)
      Cons(first, rest) => {
        let initial = (first, occurrences(first, rows))
        let (column, count) = @core.fold_left(rest, initial, fn(best, column) {
          let (_, smallest) = best
          let count = occurrences(column, rows)
          match @core.compare(count, smallest) {
            Less => (column, count)
            _ => best
          }
        })
        fn choose(candidates : @core.Chain[Row]) -> @core.Chain[@core.Nat]? {
          match candidates {
            Nil => None
            Cons(row, rest) => {
              let remaining_columns = @core.filter(primary, fn(column) {
                match contains(row.columns, column) {
                  true => false
                  false => true
                }
              })
              let remaining_rows = @core.filter(rows, fn(other) {
                match
                  @core.any(other.columns, fn(column) {
                    contains(row.columns, column)
                  }) {
                  true => false
                  false => true
                }
              })
              match search(remaining_columns, remaining_rows) {
                Some(solution) => Some(Cons(row.label, solution))
                None => choose(rest)
              }
            }
          }
        }
        match count {
          Zero => None
          Succ(_) =>
            choose(
              @core.filter(rows, fn(row) { contains(row.columns, column) }),
            )
        }
      }
    }
  }
  search(problem.primary, problem.rows)
}

///|
/// Verify a proposed set of row labels without running the search.
pub fn check(problem : Problem, solution : @core.Chain[@core.Nat]) -> Bool {
  let known = @core.map(problem.rows, fn(row) { row.label })
  let selected = @core.filter(problem.rows, fn(row) {
    contains(solution, row.label)
  })
  match
    (
      unique(solution),
      @core.all(solution, fn(label) { contains(known, label) }),
    ) {
    (true, true) => {
      let primary = @core.all(problem.primary, fn(column) {
        match occurrences(column, selected) {
          Succ(Zero) => true
          _ => false
        }
      })
      let secondary = @core.all(problem.secondary, fn(column) {
        match occurrences(column, selected) {
          Zero | Succ(Zero) => true
          _ => false
        }
      })
      match (primary, secondary) {
        (true, true) => true
        _ => false
      }
    }
    _ => false
  }
}
