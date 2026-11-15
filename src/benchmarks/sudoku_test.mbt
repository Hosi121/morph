///|
test "Sudoku nine by nine symbolic encoding and search" (b : @bench.T) {
  let grid = [
    [5, 3, 0, 0, 7, 0, 0, 0, 0],
    [6, 0, 0, 1, 9, 5, 0, 0, 0],
    [0, 9, 8, 0, 0, 0, 0, 6, 0],
    [8, 0, 0, 0, 6, 0, 0, 0, 3],
    [4, 0, 0, 8, 0, 3, 0, 0, 1],
    [7, 0, 0, 0, 2, 0, 0, 0, 6],
    [0, 6, 0, 0, 0, 0, 2, 8, 0],
    [0, 0, 0, 4, 1, 9, 0, 0, 5],
    [0, 0, 0, 0, 8, 0, 0, 7, 9],
  ]
  let cells = []
  for row, values in grid {
    for column, value in values {
      if value != 0 {
        cells.push(@puzzles.Cell::{
          row: @oracle.nat(row),
          column: @oracle.nat(column),
          value: @oracle.nat(value - 1),
        })
      }
    }
  }
  let clues = @oracle.chain(cells)
  let side = @oracle.nat(3)
  b.bench(fn() { b.keep(@puzzles.sudoku(side, clues)) })
}
