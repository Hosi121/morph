///|
test "Phase I finds lower-bounded feasible points, exact equalities and contradictions" {
  for
    p in [
      make_problem([[-1], [1]], [-1, 3], [1]),
      make_problem([[-1], [1], [-2], [0]], [-2, 2, -4, 0], [-1]),
      make_problem([[-1, 0], [0, -1], [1, 1]], [-1, -2, 5], [2, 3]),
      make_problem([[-1, -1], [1, 1]], [-2, 2], [1, 1]),
    ] {
    let mut state = start(p)
    let mut done = false
    let mut steps = 0
    while !done {
      assert_true(steps < 128)
      steps += 1
      match run(state, @oracle.nat(1)) {
        Paused(rest) => state = rest
        Optimal(certificate) => {
          assert_true(check_optimum(p, certificate))
          done = true
        }
        _ => fail("expected feasible bounded LP")
      }
    }
  }
  for
    p in [
      make_problem([[1], [-1]], [1, -2], [0]),
      make_problem([[0]], [-1], [1]),
      make_problem([[]], [-1], []),
      make_problem([[1, 1], [-1, -1]], [1, -2], [1, 1]),
    ] {
    match finish(p) {
      Infeasible(proof) => {
        assert_true(check_infeasible(p, proof))
        assert_false(check_infeasible(p, Nil))
        assert_false(
          check_infeasible(p, @core.map(proof, @exact.rational_negate)),
        )
      }
      _ => fail("expected exact Farkas contradiction")
    }
  }
  let p = make_problem([[-1]], [-1], [1])
  match finish(p) {
    Unbounded(ray) => assert_true(check_ray(p, ray))
    _ => fail("lower bound does not give an upper bound")
  }
}

///|
test "Phase I canonicalization and every resumed state preserve primal feasibility" {
  let p = make_problem([[-1, 0], [0, -1], [1, 1], [-1, -1]], [-1, -1, 4, -2], [
    2, 1,
  ])
  let initial = start(p)
  let complete = run(initial, @oracle.nat(64))
  assert_eq(complete, finish(p))
  match complete {
    Optimal(result) => {
      assert_eq(result.value, @oracle.rational(7, 1))
      assert_true(check_optimum(p, result))
    }
    _ => fail("bounded rational LP")
  }
  // The Phase I starting point is feasible for the augmented system, not the original.
  let mut state = initial
  let mut done = false
  while !done {
    assert_true(@core.all(state.rows, fn(row) { nonnegative(row.value) }))
    match run(state, @oracle.nat(1)) {
      Paused(next) => state = next
      _ => done = true
    }
  }
}
