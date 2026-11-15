///|
fn clues(grid : Array[Array[Int32]]) -> @core.Chain[Cell] {
  let result = []
  for row, values in grid {
    for column, value in values {
      if value != 0 {
        result.push(Cell::{
          row: @oracle.nat(row),
          column: @oracle.nat(column),
          value: @oracle.nat(value - 1),
        })
      }
    }
  }
  @oracle.chain(result)
}

///|
fn check_grid(
  side : Int32,
  cells : @core.Chain[Cell],
) -> Array[Array[Int32]] raise {
  let n = side * side
  let grid = Array::make(n, 0).map(fn(_) { Array::make(n, 0) })
  for cell in @oracle.array(cells) {
    let r = @oracle.int_of_nat(cell.row)
    let c = @oracle.int_of_nat(cell.column)
    assert_eq(grid[r][c], 0)
    grid[r][c] = @oracle.int_of_nat(cell.value) + 1
  }
  let expected = [ for i in 1..<=n => i ]
  for i in 0..<n {
    let row = grid[i].copy()
    row.sort()
    assert_eq(row, expected)
    let column = [ for j in 0..<n => grid[j][i] ]
    column.sort()
    assert_eq(column, expected)
    let box = [
      for j in 0..<n => {
        grid[i / side * side + j / side][i % side * side + j % side]
      }
    ]
    box.sort()
    assert_eq(box, expected)
  }
  grid
}

///|
test "four by four Sudoku and a classic nine by nine grid via the same exact cover solver" {
  let small = clues([[1, 0, 0, 4], [0, 4, 1, 0], [2, 0, 4, 0], [0, 3, 0, 1]])
  match sudoku(@oracle.nat(2), small) {
    None => fail("solvable four by four rejected")
    Some(solution) => {
      assert_true(check_sudoku(@oracle.nat(2), small, solution))
      ignore(check_grid(2, solution))
    }
  }
  let given = clues([
    [5, 3, 0, 0, 7, 0, 0, 0, 0],
    [6, 0, 0, 1, 9, 5, 0, 0, 0],
    [0, 9, 8, 0, 0, 0, 0, 6, 0],
    [8, 0, 0, 0, 6, 0, 0, 0, 3],
    [4, 0, 0, 8, 0, 3, 0, 0, 1],
    [7, 0, 0, 0, 2, 0, 0, 0, 6],
    [0, 6, 0, 0, 0, 0, 2, 8, 0],
    [0, 0, 0, 4, 1, 9, 0, 0, 5],
    [0, 0, 0, 0, 8, 0, 0, 7, 9],
  ])
  let expected = [
    [5, 3, 4, 6, 7, 8, 9, 1, 2],
    [6, 7, 2, 1, 9, 5, 3, 4, 8],
    [1, 9, 8, 3, 4, 2, 5, 6, 7],
    [8, 5, 9, 7, 6, 1, 4, 2, 3],
    [4, 2, 6, 8, 5, 3, 7, 9, 1],
    [7, 1, 3, 9, 2, 4, 8, 5, 6],
    [9, 6, 1, 5, 3, 7, 2, 8, 4],
    [2, 8, 7, 4, 1, 9, 6, 3, 5],
    [3, 4, 5, 2, 8, 6, 1, 7, 9],
  ]
  match sudoku(@oracle.nat(3), given) {
    None => fail("solvable nine by nine rejected")
    Some(solution) => {
      assert_eq(check_grid(3, solution), expected)
      assert_true(check_sudoku(@oracle.nat(3), given, solution))
    }
  }
  match sudoku(@oracle.nat(2), Nil) {
    Some(solution) => ignore(check_grid(2, solution))
    None => fail("empty four by four rejected")
  }
}

///|
test "Sudoku rejects conflicting, repeated and out-of-bounds clues" {
  assert_eq(sudoku(@oracle.nat(2), clues([[1, 1, 0, 0]])), None)
  let clue : Cell = {
    row: @oracle.nat(0),
    column: @oracle.nat(0),
    value: @oracle.nat(0),
  }
  assert_eq(sudoku(@oracle.nat(2), @oracle.chain([clue, clue])), None)
  assert_eq(sudoku(@oracle.nat(0), Nil), None)
  assert_eq(
    sudoku(
      @oracle.nat(2),
      @oracle.chain([
        Cell::{
          row: @oracle.nat(4),
          column: @oracle.nat(0),
          value: @oracle.nat(0),
        },
      ]),
    ),
    None,
  )
  assert_eq(sudoku(@oracle.nat(1), Nil), Some(@oracle.chain([clue])))
}
