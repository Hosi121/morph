///|
/// Zero-based row, column and symbol. Absence is represented by no clue,
/// so symbol zero is an ordinary value rather than an empty-cell sentinel.
#derive(Eq, Debug)
pub(all) struct Cell {
  row : @core.Nat
  column : @core.Nat
  value : @core.Nat
}

///|
pub extend Cell with Eq::{equal, not_equal}

///|
pub extend Cell with Debug::{to_repr}

///|
fn same_cell(a : Cell, b : Cell) -> Bool {
  match (@core.compare(a.row, b.row), @core.compare(a.column, b.column)) {
    (Equal, Equal) => true
    _ => false
  }
}

///|
/// side is nonzero at every caller.
fn box_index(
  side : @core.Nat,
  row : @core.Nat,
  column : @core.Nat,
) -> @core.Nat {
  match (@core.divmod(row, side), @core.divmod(column, side)) {
    (Some((r, _)), Some((c, _))) => @core.add(@core.multiply(r, side), c)
    _ => Zero
  }
}

///|
fn compatible(side : @core.Nat, a : Cell, b : Cell) -> Bool {
  match same_cell(a, b) {
    true =>
      match @core.compare(a.value, b.value) {
        Equal => true
        _ => false
      }
    false =>
      match @core.compare(a.value, b.value) {
        Equal =>
          match
            (
              @core.compare(a.row, b.row),
              @core.compare(a.column, b.column),
              @core.compare(
                box_index(side, a.row, a.column),
                box_index(side, b.row, b.column),
              ),
            ) {
            (Equal, _, _) | (_, Equal, _) | (_, _, Equal) => false
            _ => true
          }
        _ => true
      }
  }
}

///|
fn valid_cells(
  side : @core.Nat,
  n : @core.Nat,
  cells : @core.Chain[Cell],
) -> Bool {
  match cells {
    Nil => true
    Cons(cell, rest) => {
      let bounded = match
        (
          @core.compare(cell.row, n),
          @core.compare(cell.column, n),
          @core.compare(cell.value, n),
        ) {
        (Less, Less, Less) => true
        _ => false
      }
      let consistent = @core.all(rest, fn(other) {
        match same_cell(cell, other) {
          true => false
          false => compatible(side, cell, other)
        }
      })
      match (bounded, consistent) {
        (true, true) => valid_cells(side, n, rest)
        _ => false
      }
    }
  }
}

///|
/// General Sudoku with side-by-side boxes and dimension n=side*side.
/// Four exact constraints: cell, row/symbol, column/symbol, box/symbol.
pub fn sudoku(
  side : @core.Nat,
  clues : @core.Chain[Cell],
) -> @core.Chain[Cell]? {
  match side {
    Zero => None
    Succ(_) => {
      let n = @core.multiply(side, side)
      match valid_cells(side, n, clues) {
        false => None
        true => {
          let cells = @core.multiply(n, n)
          let twice = @core.add(cells, cells)
          let thrice = @core.add(twice, cells)
          let primary = @core.indices(@core.add(twice, twice))
          let coordinates = @core.indices(n)
          let choices : @core.Chain[@exactcover.Row] = @core.fold_left(
            coordinates,
            @core.Nil,
            fn(found, row) {
              @core.fold_left(coordinates, found, fn(found, column) {
                @core.fold_left(coordinates, found, fn(found, value) {
                  let candidate : Cell = { row, column, value, }
                  match
                    @core.all(clues, fn(clue) {
                      compatible(side, candidate, clue)
                    }) {
                    false => found
                    true => {
                      let position = @core.add(@core.multiply(row, n), column)
                      let label = @core.add(@core.multiply(position, n), value)
                      let row_symbol = @core.add(
                        cells,
                        @core.add(@core.multiply(row, n), value),
                      )
                      let column_symbol = @core.add(
                        twice,
                        @core.add(@core.multiply(column, n), value),
                      )
                      let box_symbol = @core.add(
                        thrice,
                        @core.add(
                          @core.multiply(box_index(side, row, column), n),
                          value,
                        ),
                      )
                      @core.Cons(
                        @exactcover.Row::{
                          label,
                          columns: Cons(
                            position,
                            Cons(
                              row_symbol,
                              Cons(column_symbol, Cons(box_symbol, Nil)),
                            ),
                          ),
                        },
                        found,
                      )
                    }
                  }
                })
              })
            },
          )
          match @exactcover.problem(primary, Nil, choices) {
            None => None
            Some(problem) =>
              match @exactcover.solve(problem) {
                None => None
                Some(labels) => {
                  fn decode(
                    labels : @core.Chain[@core.Nat],
                  ) -> @core.Chain[Cell]? {
                    match labels {
                      Nil => Some(Nil)
                      Cons(label, rest) =>
                        match @core.divmod(label, n) {
                          None => None
                          Some((position, value)) =>
                            match (@core.divmod(position, n), decode(rest)) {
                              (Some((row, column)), Some(rest)) =>
                                Some(Cons({ row, column, value, }, rest))
                              _ => None
                            }
                        }
                    }
                  }
                  match decode(labels) {
                    None => None
                    Some(cells) =>
                      Some(
                        @sorting.merge_sort(cells, fn(a, b) {
                          match @core.compare(a.row, b.row) {
                            Equal => @core.compare(a.column, b.column)
                            order => order
                          }
                        }),
                      )
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
/// Check all complete-board constraints and every clue without solving again.
pub fn check_sudoku(
  side : @core.Nat,
  clues : @core.Chain[Cell],
  solution : @core.Chain[Cell],
) -> Bool {
  match side {
    Zero => false
    Succ(_) => {
      let n = @core.multiply(side, side)
      match
        (
          @core.compare(@core.length(solution), @core.multiply(n, n)),
          valid_cells(side, n, clues),
          valid_cells(side, n, solution),
        ) {
        (Equal, true, true) =>
          @core.all(clues, fn(clue) {
            @core.any(solution, fn(cell) {
              match
                (same_cell(clue, cell), @core.compare(clue.value, cell.value)) {
                (true, Equal) => true
                _ => false
              }
            })
          })
        _ => false
      }
    }
  }
}
