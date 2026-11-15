///|
test "Algorithm X exhausts all four-row three-column incidence matrices" {
  let columns = @oracle.chain([0, 1, 2].map(@oracle.nat))
  for matrix in 0..<4096 {
    let rows = [
      for row in 0..<4 => {
        Row::{
          label: @oracle.nat(row),
          columns: @oracle.chain(
            [
              for column in 0..<3 if (matrix & (1 << (row * 3 + column))) != 0 => {
                @oracle.nat(column)
              }
            ],
          ),
        }
      }
    ]
    let mut expected = false
    for subset in 0..<16 {
      let mut valid = true
      for column in 0..<3 {
        let mut count = 0
        for row in 0..<4 {
          if (subset & (1 << row)) != 0 &&
            (matrix & (1 << (row * 3 + column))) != 0 {
            count += 1
          }
        }
        if count != 1 {
          valid = false
        }
      }
      if valid {
        expected = true
      }
    }
    match problem(columns, Nil, @oracle.chain(rows)) {
      None => fail("valid incidence matrix rejected")
      Some(problem) =>
        match solve(problem) {
          None => assert_false(expected)
          Some(solution) => {
            assert_true(expected)
            assert_true(check(problem, solution))
          }
        }
    }
  }
}

///|
test "secondary columns constrain at most once and malformed inputs are rejected" {
  let p = @oracle.chain([0, 1].map(@oracle.nat))
  let s = @oracle.chain([@oracle.nat(2)])
  let rows = @oracle.chain([
    Row::{
      label: @oracle.nat(0),
      columns: @oracle.chain([0, 2].map(@oracle.nat)),
    },
    Row::{
      label: @oracle.nat(1),
      columns: @oracle.chain([1, 2].map(@oracle.nat)),
    },
  ])
  match problem(p, s, rows) {
    Some(problem) => assert_eq(solve(problem), None)
    None => fail("valid problem")
  }
  let more = @core.Cons(
    Row::{ label: @oracle.nat(2), columns: @oracle.chain([@oracle.nat(1)]), },
    rows,
  )
  match problem(p, s, more) {
    None => fail("valid problem")
    Some(problem) => {
      assert_true(check(problem, solve(problem).unwrap()))
      assert_false(
        check(problem, @oracle.chain([@oracle.nat(0), @oracle.nat(1)])),
      )
      assert_false(
        check(problem, @oracle.chain([@oracle.nat(0), @oracle.nat(0)])),
      )
    }
  }
  assert_eq(problem(p, p, rows), None)
  assert_eq(
    problem(@oracle.chain([@oracle.nat(0), @oracle.nat(0)]), Nil, Nil),
    None,
  )
}
