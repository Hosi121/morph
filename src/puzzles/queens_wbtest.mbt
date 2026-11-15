///|
test "N queens is an exact-cover encoding with independently valid placements" {
  for n in 0..<=10 {
    match n_queens(@oracle.nat(n)) {
      None => assert_true(n == 2 || n == 3)
      Some(queens) => {
        assert_true(n != 2 && n != 3)
        assert_true(check_queens(@oracle.nat(n), queens))
        let coordinates = @oracle.array(queens).map(fn(q) {
          (@oracle.int_of_nat(q.row), @oracle.int_of_nat(q.column))
        })
        assert_eq(coordinates.length(), n)
        for i in 0..<n {
          for j in (i + 1)..<n {
            assert_true(coordinates[i].0 != coordinates[j].0)
            assert_true(coordinates[i].1 != coordinates[j].1)
            assert_true(
              (coordinates[i].0 - coordinates[j].0).abs() !=
              (coordinates[i].1 - coordinates[j].1).abs(),
            )
          }
        }
      }
    }
  }
  let bad = @oracle.chain([
    Queen::{ row: @oracle.nat(0), column: @oracle.nat(0), },
    Queen::{ row: @oracle.nat(1), column: @oracle.nat(1), },
  ])
  assert_false(check_queens(@oracle.nat(2), bad))
}
