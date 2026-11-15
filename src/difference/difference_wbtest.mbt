///|
fn constraint(left : Int32, right : Int32, bound : Int32) -> Constraint {
  {
    left: @oracle.nat(left),
    right: @oracle.nat(right),
    bound: @oracle.integer(bound),
  }
}

///|
// Independent all-pairs dynamic program, with ordinary signed integers.
fn native_feasible(items : Array[Constraint], vertices : Int32) -> Bool {
  let matrix = Array::makei(vertices, fn(i) {
    Array::makei(vertices, fn(j) { if i == j { 0 } else { 1000000 } })
  })
  for item in items {
    let from = @oracle.int_of_nat(item.right)
    let to = @oracle.int_of_nat(item.left)
    let weight = @oracle.int_of_integer(item.bound)
    if weight < matrix[from][to] {
      matrix[from][to] = weight
    }
  }
  for pivot in 0..<vertices {
    for from in 0..<vertices {
      for to in 0..<vertices {
        if matrix[from][pivot] < 1000000 && matrix[pivot][to] < 1000000 {
          let candidate = matrix[from][pivot] + matrix[pivot][to]
          if candidate < matrix[from][to] {
            matrix[from][to] = candidate
          }
        }
      }
    }
  }
  [ for i in 0..<vertices => matrix[i][i] >= 0 ].all(fn(x) { x })
}

///|
fn compare_native(items : Array[Constraint], vertices : Int32) -> Unit raise {
  let problem = problem(@oracle.chain(items))
  let expected = native_feasible(items, vertices)
  match solve(problem) {
    Feasible(solution) => {
      assert_true(expected)
      assert_true(check_solution(problem, solution))
      assert_eq(value(solution, @core.Zero), Some(@oracle.integer(0)))
      for item in items {
        let left = @oracle.int_of_integer(value(solution, item.left).unwrap())
        let right = @oracle.int_of_integer(value(solution, item.right).unwrap())
        assert_true(left - right <= @oracle.int_of_integer(item.bound))
      }
    }
    Infeasible(cycle) => {
      assert_false(expected)
      assert_true(check_cycle(problem, cycle))
      let indices = @oracle.array(cycle.indices)
      assert_true(indices.length() > 0)
      let mut weight = 0
      for i in 0..<indices.length() {
        let current = items[@oracle.int_of_nat(indices[i])]
        let next = items[@oracle.int_of_nat(indices[(i + 1) % indices.length()])]
        assert_eq(
          @oracle.int_of_nat(current.left),
          @oracle.int_of_nat(next.right),
        )
        weight += @oracle.int_of_integer(current.bound)
      }
      assert_true(weight < 0)
    }
    InvariantViolation => fail("Bellman-Ford certificate extraction failed")
  }
}

///|
test "all triples of small difference constraints match independent Floyd-Warshall" {
  let pool = Array::makei(27, fn(i) { constraint(i / 9, i / 3 % 3, i % 3 - 1) })
  compare_native([], 3)
  for a in pool {
    compare_native([a], 3)
    for b in pool {
      compare_native([a, b], 3)
      for c in pool {
        compare_native([a, b, c], 3)
      }
    }
  }
}

///|
test "generated larger graphs have checked potentials or closed negative walks" {
  for seed in 0..<600 {
    let vertices = 2 + seed % 5
    let items = Array::makei(seed % 13, fn(i) {
      constraint(
        (seed * 17 + i * 7) % vertices,
        (seed * 3 + i * 11 + 1) % vertices,
        (seed * 13 + i * 5) % 9 - 4,
      )
    })
    compare_native(items, vertices)
  }
}

///|
test "negative-cycle and assignment checkers reject forged certificates" {
  let bad = problem(@oracle.chain([constraint(1, 0, -1), constraint(0, 1, 0)]))
  assert_true(
    check_cycle(bad, {
      indices: @oracle.chain([@oracle.nat(0), @oracle.nat(1)]),
    }),
  )
  assert_false(check_cycle(bad, { indices: @core.Nil, }))
  assert_false(check_cycle(bad, { indices: @core.Cons(@oracle.nat(0), Nil), }))
  assert_false(check_cycle(bad, { indices: @core.Cons(@oracle.nat(99), Nil), }))
  let good = problem(@oracle.chain([constraint(1, 0, 1), constraint(0, 1, 1)]))
  assert_false(
    check_cycle(good, {
      indices: @oracle.chain([@oracle.nat(0), @oracle.nat(1)]),
    }),
  )
  let raw = @oracle.chain([
    (@oracle.nat(0), @oracle.integer(0)),
    (@oracle.nat(1), @oracle.integer(1)),
  ])
  assert_true(check_values(good, raw) is Some(_))
  assert_eq(check_values(good, @core.Nil), None)
  assert_eq(
    check_values(good, @core.Cons((@oracle.nat(1), @oracle.integer(1)), raw)),
    None,
  )
  assert_eq(
    check_values(good, @core.Cons((@oracle.nat(9), @oracle.integer(1)), raw)),
    None,
  )
  assert_eq(
    check_values(
      good,
      @oracle.chain([
        (@oracle.nat(0), @oracle.integer(1)),
        (@oracle.nat(1), @oracle.integer(1)),
      ]),
    ),
    None,
  )
  assert_eq(check_values(bad, raw), None)
}

///|
test "integer negation is the exact complement and sparse IDs stay sparse internally" {
  for left in -3..<=3 {
    for right in -3..<=3 {
      let raw = @oracle.chain([
        (@oracle.nat(0), @oracle.integer(0)),
        (@oracle.nat(1), @oracle.integer(left)),
        (@oracle.nat(2), @oracle.integer(right)),
      ])
      for bound in -3..<=3 {
        let c = constraint(1, 2, bound)
        assert_true(holds(c, raw) != holds(negate(c), raw))
        assert_eq(negate(negate(c)), c)
      }
    }
  }
  let p = problem(
    @oracle.chain([constraint(65535, 8191, -4), constraint(8191, 65535, 3)]),
  )
  match solve(p) {
    Infeasible(cycle) => assert_true(check_cycle(p, cycle))
    _ => fail("sparse two-edge cycle must be negative")
  }
  let huge = @exact.positive(
    @oracle.binary_from_hex(
      "10000000000000000000000000000000000000000000000000000000000000000",
    ),
  )
  let p = problem(
    @oracle.chain([
      Constraint::{
        left: @core.Succ(Zero),
        right: Zero,
        bound: @exact.negate(huge),
      },
      { left: Zero, right: @core.Succ(Zero), bound: huge, },
    ]),
  )
  match solve(p) {
    Feasible(solution) =>
      assert_eq(value(solution, @core.Succ(Zero)), Some(@exact.negate(huge)))
    _ => fail("huge exact integer equality must be feasible")
  }
}
