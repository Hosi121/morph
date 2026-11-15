///|
test "all queens placements through eight match independent column backtracking" {
  fn expected(n : Int32) -> Int32 {
    fn search(columns : Array[Int32]) -> Int32 {
      let row = columns.length()
      if row == n {
        return 1
      }
      let mut count = 0
      for col in 0..<n {
        if [
            for r in 0..<row => r
          ].all(fn(r) {
            columns[r] != col && (columns[r] - col).abs() != row - r
          }) {
          count += search(columns + [col])
        }
      }
      count
    }
    search([])
  }
  let known = [1, 1, 0, 0, 2, 10, 4, 40, 92]
  for n in 0..<=8 {
    let p = queens_problem(@oracle.nat(n)).unwrap()
    let mut state = @exactcover.enumerate(p)
    let mut count = 0
    let mut done = false
    while !done {
      match @exactcover.advance(state, @oracle.nat(7)) {
        Exhausted => done = true
        Pending(rest) => state = rest
        Found(labels, rest) => {
          assert_true(@exactcover.check(p, labels))
          let queens = @oracle.chain(
            @oracle.array(labels).map(fn(label) {
              let value = @oracle.int_of_nat(label)
              Queen::{
                row: @oracle.nat(value / n),
                column: @oracle.nat(value % n),
              }
            }),
          )
          assert_true(check_queens(@oracle.nat(n), queens))
          count += 1
          state = rest
        }
      }
    }
    assert_eq(count, known[n])
    assert_eq(count, expected(n))
  }
}
