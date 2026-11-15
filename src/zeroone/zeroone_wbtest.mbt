///|
fn make_problem(
  rows : Array[Array[Int32]],
  bounds : Array[Int32],
  costs : Array[Int32],
) -> Problem {
  let a = @matrix.matrix(
    @oracle.nat(costs.length()),
    @oracle.chain(
      rows.map(fn(row) {
        @oracle.chain(row.map(fn(x) { @oracle.rational(x, 1) }))
      }),
    ),
  ).unwrap()
  problem(
    a,
    @oracle.chain(bounds.map(fn(x) { @oracle.rational(x, 1) })),
    @oracle.chain(costs.map(fn(x) { @oracle.rational(x, 1) })),
  ).unwrap()
}

///|
fn finish(p : Problem) -> Progress {
  let mut state = start(p)
  for _ in 0..<16384 {
    match run(state, @oracle.nat(3)) {
      Paused(rest) => state = rest
      result => return result
    }
  }
  abort("small binary LP exceeded test work bound")
}

///|
fn depth(proof : Proof, fixed : Int32) -> Int32 raise {
  match proof {
    Excluded(_) | Bounded(_) => 0
    Split(variable, left, right) => {
      let bit = 1 << @oracle.int_of_nat(variable)
      assert_eq(fixed & bit, 0)
      let left = depth(left, fixed | bit)
      let right = depth(right, fixed | bit)
      1 + (if left > right { left } else { right })
    }
  }
}

///|
test "192 signed six-variable problems versus all 64 Boolean assignments" {
  for sample in 0..<192 {
    let rows = [
      for r in 0..<(1 + sample % 4) => {
        [
          for c in 0..<6 => {
            (sample * 13 + r * 17 + c * c * 5 + r * c * 3) % 7 - 3
          }
        ]
      }
    ]
    let bounds = [ for r in 0..<rows.length() => (sample * 5 + r * 7) % 10 - 4 ]
    let costs = [ for c in 0..<6 => (sample * 7 + c * 11) % 13 - 5 ]
    let mut best : Int32? = None
    for mask in 0..<64 {
      let valid = [
        for r in 0..<rows.length() => r + 0
      ].all(fn(r) {
        let mut value = 0
        for c in 0..<6 {
          if (mask & (1 << c)) != 0 {
            value += rows[r][c]
          }
        }
        value <= bounds[r]
      })
      if valid {
        let mut value = 0
        for c in 0..<6 {
          if (mask & (1 << c)) != 0 {
            value += costs[c]
          }
        }
        match best {
          None => best = Some(value)
          Some(previous) => if value > previous { best = Some(value) }
        }
      }
    }
    let p = make_problem(rows, bounds, costs)
    match (finish(p), best) {
      (Complete(candidate, proof), Some(expected)) => {
        assert_eq(candidate.value, @oracle.rational(expected, 1))
        assert_true(check_optimal(p, candidate, proof))
        assert_true(depth(proof, 0) <= 6)
      }
      (Infeasible(proof), None) => {
        assert_true(check_infeasible(p, proof))
        assert_true(depth(proof, 0) <= 6)
      }
      _ => fail("binary LP disagrees with exhaustive optimum")
    }
  }
}

///|
test "knapsack reduction agrees with row-DP for zero and positive weights" {
  for sample in 0..<16 {
    let weights = [ for i in 0..<5 => (sample * 3 + i * 7) % 5 ]
    let values = [ for i in 0..<5 => 1 + (sample * 5 + i * 3) % 7 ]
    let items = @oracle.chain(
      [
        for i in 0..<5 => {
          @dp.Item::{
            weight: @oracle.nat(weights[i]),
            value: @oracle.binary(values[i]),
          }
        }
      ],
    )
    for capacity in 0..<=8 {
      let expected = @dp.knapsack(items, @oracle.nat(capacity))
      let p = make_problem([weights], [capacity], values)
      match finish(p) {
        Complete(candidate, proof) => {
          assert_eq(
            candidate.value,
            @exact.whole(@exact.positive(expected.value)),
          )
          assert_true(check_optimal(p, candidate, proof))
        }
        _ => fail("empty knapsack assignment is feasible")
      }
    }
  }
}

///|
test "fractional relaxation forces branching; proof and candidate tampering fail" {
  let p = make_problem([[2]], [1], [1])
  let initial = start(p)
  assert_eq(run(initial, Zero), Paused(initial))
  let result = finish(p)
  assert_eq(run(initial, @oracle.nat(512)), result)
  match result {
    Complete(candidate, proof) => {
      assert_eq(candidate.assignment, @core.Cons(false, Nil))
      assert_eq(candidate.value, @oracle.rational(0, 1))
      assert_true(check_optimal(p, candidate, proof))
      assert_false(
        check_optimal(
          p,
          { ..candidate, assignment: @core.Cons(true, Nil), },
          proof,
        ),
      )
      assert_false(
        check_optimal(p, { ..candidate, value: @oracle.rational(1, 1), }, proof),
      )
      assert_false(check_infeasible(p, proof))
      match proof {
        Split(variable, left, right) => {
          assert_false(
            check_optimal(p, candidate, Split(variable, right, left)),
          )
          assert_false(
            check_optimal(p, candidate, Split(@oracle.nat(99), left, right)),
          )
        }
        _ => fail("root is fractional, so this proof needs a split")
      }
      assert_false(check_optimal(p, candidate, Excluded(Nil)))
    }
    _ => fail("zero is feasible and optimal")
  }
  let p = make_problem([[2], [-2]], [1, -1], [0])
  match finish(p) {
    Infeasible(proof) => {
      assert_true(check_infeasible(p, proof))
      assert_eq(depth(proof, 0), 1)
    }
    _ => fail("half is feasible over rationals but not over Booleans")
  }
  for p in [make_problem([], [], []), make_problem([[]], [0], [])] {
    match finish(p) {
      Complete(candidate, proof) => {
        assert_eq(candidate.assignment, Nil)
        assert_true(check_optimal(p, candidate, proof))
      }
      _ => fail("one empty Boolean assignment")
    }
  }
  let p = make_problem([[]], [-1], [])
  match finish(p) {
    Infeasible(proof) => assert_true(check_infeasible(p, proof))
    _ => fail("empty contradiction")
  }
}
