///|
test "resumable enumeration matches every valid subset including empty rows" {
  let columns = @oracle.chain([0, 1, 2].map(@oracle.nat))
  for matrix in 0..<4096 {
    let rows = @oracle.chain(
      [
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
      ],
    )
    let p = problem(columns, Nil, rows).unwrap()
    let expected = Array::make(16, false)
    for subset in 0..<16 {
      expected[subset] = [0, 1, 2].all(fn(column) {
        let mut count = 0
        for row in 0..<4 {
          if (subset & (1 << row)) != 0 &&
            (matrix & (1 << (row * 3 + column))) != 0 {
            count += 1
          }
        }
        count == 1
      })
    }
    let seen = Array::make(16, false)
    let mut state = enumerate(p)
    let mut done = false
    while !done {
      match advance(state, @oracle.nat(2)) {
        Exhausted => done = true
        Pending(next) => state = next
        Found(solution, next) => {
          assert_true(check(p, solution))
          let mut mask = 0
          for label in @oracle.array(solution) {
            mask = mask | (1 << @oracle.int_of_nat(label))
          }
          assert_false(seen[mask])
          seen[mask] = true
          state = next
        }
      }
    }
    assert_eq(seen, expected)
  }
}

///|
test "optional secondary rows, persistent replay, zero fuel and empty problem" {
  let p = problem(
    Nil,
    @oracle.chain([@oracle.nat(0)]),
    @oracle.chain([
      Row::{ label: @oracle.nat(0), columns: @oracle.chain([@oracle.nat(0)]), },
      Row::{ label: @oracle.nat(1), columns: @oracle.chain([@oracle.nat(0)]), },
      Row::{ label: @oracle.nat(2), columns: Nil, },
    ]),
  ).unwrap()
  let initial = enumerate(p)
  assert_eq(advance(initial, Zero), Pending(initial))
  assert_eq(
    advance(initial, @oracle.nat(100)),
    advance(initial, @oracle.nat(100)),
  )
  let mut state = initial
  let mut count = 0
  let mut done = false
  while !done {
    match advance(state, @oracle.nat(1)) {
      Found(solution, rest) => {
        assert_true(check(p, solution))
        count += 1
        state = rest
      }
      Pending(rest) => state = rest
      Exhausted => done = true
    }
  }
  assert_eq(count, 6)
  let empty = enumerate(problem(Nil, Nil, Nil).unwrap())
  match advance(empty, @oracle.nat(1)) {
    Found(Nil, rest) => assert_eq(advance(rest, Zero), Exhausted)
    _ => fail("one empty solution expected")
  }
}
