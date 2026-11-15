///|
fn make_problem(
  a : Array[Array[Int32]],
  b : Array[Int32],
  c : Array[Int32],
) -> Problem {
  let matrix = @matrix.matrix(
    @oracle.nat(c.length()),
    @oracle.chain(
      a.map(fn(row) { @oracle.chain(row.map(fn(x) { @oracle.rational(x, 1) })) }),
    ),
  ).unwrap()
  problem(
    matrix,
    @oracle.chain(b.map(fn(x) { @oracle.rational(x, 1) })),
    @oracle.chain(c.map(fn(x) { @oracle.rational(x, 1) })),
  ).unwrap()
}

///|
fn finish(p : Problem) -> Progress {
  let mut state = start(p)
  for _ in 0..<128 {
    match run(state, @oracle.nat(1)) {
      Paused(next) => state = next
      result => return result
    }
  }
  abort("simplex exceeded test pivot bound")
}

///|
test "exact primal/dual optimum, resumable pivots and forged certificates" {
  let p = make_problem([[1, 1], [1, 0], [0, 1]], [4, 2, 3], [3, 2])
  let initial = start(p)
  assert_eq(run(initial, Zero), Paused(initial))
  let complete = run(initial, @oracle.nat(20))
  assert_eq(complete, finish(p))
  assert_eq(run(initial, @oracle.nat(20)), complete)
  match complete {
    Optimal(certificate) => {
      assert_true(check_optimum(p, certificate))
      assert_eq(certificate.value, @oracle.rational(10, 1))
      assert_eq(
        certificate.primal,
        @oracle.chain([2, 2].map(fn(n) { @oracle.rational(n, 1) })),
      )
      assert_false(
        check_optimum(p, { ..certificate, value: @oracle.rational(11, 1), }),
      )
      assert_false(check_optimum(p, { ..certificate, dual: Nil, }))
      assert_false(
        check_optimum(p, {
          ..certificate,
          primal: @oracle.chain([4, 0].map(fn(n) { @oracle.rational(n, 1) })),
        }),
      )
    }
    _ => fail("bounded problem")
  }
  let p = make_problem([[2, 1], [1, 2]], [4, 4], [1, 1])
  match finish(p) {
    Optimal(certificate) => {
      assert_true(check_optimum(p, certificate))
      assert_eq(certificate.value, @oracle.rational(8, 3))
    }
    _ => fail("fractional optimum")
  }
}

///|
test "unbounded after a pivot, zero dimensions and checked domain" {
  let p = make_problem([[1, -1]], [1], [1, 2])
  match finish(p) {
    Unbounded(ray) => {
      assert_true(check_ray(p, ray))
      assert_false(
        check_ray(p, {
          ..ray,
          direction: @oracle.chain([
            @oracle.rational(0, 1),
            @oracle.rational(0, 1),
          ]),
        }),
      )
      assert_false(
        check_ray(p, {
          ..ray,
          direction: @oracle.chain([
            @oracle.rational(-1, 1),
            @oracle.rational(0, 1),
          ]),
        }),
      )
      assert_false(
        check_ray(p, {
          ..ray,
          point: @oracle.chain([@oracle.rational(9, 1), @oracle.rational(0, 1)]),
        }),
      )
    }
    _ => fail("expected a certified ray")
  }
  for
    p in [
      make_problem([], [], []),
      make_problem([[], []], [0, 2], []),
      make_problem([[0, 0]], [0], [-1, -2]),
    ] {
    match finish(p) {
      Optimal(certificate) => {
        assert_eq(certificate.value, @exact.rational_zero())
        assert_true(check_optimum(p, certificate))
      }
      _ => fail("zero optimum")
    }
  }
  let p = make_problem([], [], [1])
  match finish(p) {
    Unbounded(ray) => assert_true(check_ray(p, ray))
    _ => fail("unconstrained positive objective")
  }
  let a = @matrix.matrix(
    @oracle.nat(1),
    @oracle.chain([@oracle.chain([@oracle.rational(1, 1)])]),
  ).unwrap()
  assert_eq(
    problem(
      a,
      @oracle.chain([@oracle.rational(-1, 1)]),
      @oracle.chain([@oracle.rational(1, 1)]),
    ),
    None,
  )
  assert_eq(problem(a, Nil, @oracle.chain([@oracle.rational(1, 1)])), None)
  assert_eq(problem(a, @oracle.chain([@oracle.rational(1, 1)]), Nil), None)
}

///|
test "Bland's rule escapes the classical degenerate cycling tableau" {
  let coefficients = [
    [
      @oracle.rational(1, 2),
      @oracle.rational(-11, 2),
      @oracle.rational(-5, 2),
      @oracle.rational(9, 1),
    ],
    [
      @oracle.rational(1, 2),
      @oracle.rational(-3, 2),
      @oracle.rational(-1, 2),
      @oracle.rational(1, 1),
    ],
    [
      @oracle.rational(1, 1),
      @oracle.rational(0, 1),
      @oracle.rational(0, 1),
      @oracle.rational(0, 1),
    ],
  ]
  let p = problem(
    @matrix.matrix(
      @oracle.nat(4),
      @oracle.chain(coefficients.map(@oracle.chain)),
    ).unwrap(),
    @oracle.chain([0, 0, 1].map(fn(n) { @oracle.rational(n, 1) })),
    @oracle.chain([10, -57, -9, -24].map(fn(n) { @oracle.rational(n, 1) })),
  ).unwrap()
  match finish(p) {
    Optimal(certificate) => {
      assert_eq(certificate.value, @oracle.rational(1, 1))
      assert_true(check_optimum(p, certificate))
    }
    _ => fail("Bland should terminate at the bounded optimum")
  }
}
