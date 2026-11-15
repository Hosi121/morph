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
  indexed_primary : @core.Chain[@binary.Binary]
  indexed_rows : @core.Chain[(@core.Nat, @core.Chain[@binary.Binary])]
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
/// IDs are encoded once at the checked boundary; searches use their bit width.
fn key_member(keys : @core.Chain[@binary.Binary], key : @binary.Binary) -> Bool {
  @core.any(keys, fn(other) {
    match @binary.compare(key, other) {
      Equal => true
      _ => false
    }
  })
}

///|
fn keys_unique(keys : @core.Chain[@binary.Binary]) -> Bool {
  match keys {
    Nil => true
    Cons(key, rest) =>
      match key_member(rest, key) {
        true => false
        false => keys_unique(rest)
      }
  }
}

///|
pub fn problem(
  primary : @core.Chain[@core.Nat],
  secondary : @core.Chain[@core.Nat],
  rows : @core.Chain[Row],
) -> Problem? {
  let indexed_primary = @core.map(primary, @binary.from_nat)
  let indexed_rows = @core.map(rows, fn(row) {
    (row.label, @core.map(row.columns, @binary.from_nat))
  })
  let columns = @core.append(
    indexed_primary,
    @core.map(secondary, @binary.from_nat),
  )
  let labels = @core.map(rows, fn(row) { @binary.from_nat(row.label) })
  let valid_rows = @core.all(indexed_rows, fn(row) {
    let (_, covered) = row
    match keys_unique(covered) {
      false => false
      true => @core.all(covered, fn(column) { key_member(columns, column) })
    }
  })
  match (keys_unique(columns), keys_unique(labels), valid_rows) {
    (true, true, true) =>
      Some({ primary, secondary, rows, indexed_primary, indexed_rows, })
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
  fn count(
    column : @binary.Binary,
    rows : @core.Chain[(@core.Nat, @core.Chain[@binary.Binary])],
  ) -> @core.Nat {
    @core.fold_left(rows, @core.Zero, fn(count, row) {
      let (_, columns) = row
      match key_member(columns, column) {
        true => Succ(count)
        false => count
      }
    })
  }
  fn search(
    primary : @core.Chain[@binary.Binary],
    rows : @core.Chain[(@core.Nat, @core.Chain[@binary.Binary])],
  ) -> @core.Chain[@core.Nat]? {
    match primary {
      Nil => Some(Nil)
      Cons(first, rest) => {
        let initial = (first, count(first, rows))
        let (column, number) = @core.fold_left(rest, initial, fn(best, column) {
          let (_, smallest) = best
          let number = count(column, rows)
          match @core.compare(number, smallest) {
            Less => (column, number)
            _ => best
          }
        })
        fn choose(
          candidates : @core.Chain[(@core.Nat, @core.Chain[@binary.Binary])],
        ) -> @core.Chain[@core.Nat]? {
          match candidates {
            Nil => None
            Cons((label, covered), rest) => {
              let remaining_columns = @core.filter(primary, fn(column) {
                match key_member(covered, column) {
                  true => false
                  false => true
                }
              })
              let remaining_rows = @core.filter(rows, fn(other) {
                let (_, columns) = other
                match
                  @core.any(columns, fn(column) { key_member(covered, column) }) {
                  true => false
                  false => true
                }
              })
              match search(remaining_columns, remaining_rows) {
                Some(solution) => Some(Cons(label, solution))
                None => choose(rest)
              }
            }
          }
        }
        match number {
          Zero => None
          Succ(_) =>
            choose(
              @core.filter(rows, fn(row) {
                let (_, columns) = row
                key_member(columns, column)
              }),
            )
        }
      }
    }
  }
  search(problem.indexed_primary, problem.indexed_rows)
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
