///|
fn imat(
  width : Int32,
  rows : Array[Array[Int32]],
) -> @matrix.Matrix[@exact.Integer] {
  @matrix.matrix(
    @oracle.nat(width),
    @oracle.chain(rows.map(fn(row) { @oracle.chain(row.map(@oracle.integer)) })),
  ).unwrap()
}

///|
fn completed(input : @matrix.Matrix[@exact.Integer]) -> Reduction {
  match run(start(input).unwrap(), @oracle.nat(2000)) {
    Done(result) => result
    _ => abort("small exact LLL must complete")
  }
}

///|
fn check_sympy(
  width : Int32,
  source : Array[Array[Int32]],
  u : Array[Array[Int32]],
  reduced : Array[Array[Int32]],
  expected_gram : GramSchmidt,
) -> Unit raise {
  let input = imat(width, source)
  let reduced = imat(width, reduced)
  let u_matrix = imat(source.length(), u)
  assert_eq(gram_schmidt(reduced), Some(expected_gram))
  assert_true(
    check_with_gram(input, u_matrix, reduced, expected_gram) is Some(_),
  )
  let generated = completed(input)
  assert_eq(
    check(input, transform(generated), basis(generated)),
    Some(generated),
  )
}

///|
test "nearest ties are exact and deterministic while half sized coefficients remain" {
  assert_eq(nearest(@oracle.rational(1, 2)), @oracle.integer(1))
  assert_eq(nearest(@oracle.rational(-1, 2)), @oracle.integer(-1))
  assert_eq(nearest(@oracle.rational(3, 2)), @oracle.integer(2))
  assert_eq(nearest(@oracle.rational(-3, 2)), @oracle.integer(-2))
  assert_eq(nearest(@oracle.rational(4, 3)), @oracle.integer(1))
  assert_eq(nearest(@oracle.rational(-4, 3)), @oracle.integer(-1))
  assert_eq(delta(), @oracle.rational(3, 4))
  assert_eq(
    basis(completed(imat(2, [[2, 0], [3, 2]]))),
    imat(2, [[2, 0], [-1, 2]]),
  )
  assert_eq(
    basis(completed(imat(2, [[2, 0], [-3, 2]]))),
    imat(2, [[2, 0], [1, 2]]),
  )
  let boundary = imat(3, [[2, 0, 0], [1, 1, 1]])
  assert_eq(basis(completed(boundary)), boundary)
}

///|
test "full row rank rectangular and empty bases are handled and dependent rows rejected" {
  for
    (width, rows) in [
      (3, [[1, 1, 1], [-1, 0, 2], [3, 5, 6]]),
      (4, [[1, 1, 1, 1], [1, 0, 2, 3]]),
      (4, [[1, 1, 1, 1], [1, 0, 2, 3], [5, 3, 1, 2]]),
      (2, [[-3, 4]]),
      (0, []),
      (3, []),
    ] {
    let input = imat(width, rows)
    let result = completed(input)
    assert_eq(original(result), input)
    assert_eq(check(input, transform(result), basis(result)), Some(result))
    assert_true(check_gram(basis(result), gram(result)))
  }
  for
    (width, rows) in [
      (2, [[0, 0]]),
      (2, [[1, 2], [2, 4]]),
      (1, [[1], [2]]),
      (0, [[]]),
    ] {
    assert_eq(start(imat(width, rows)), None)
  }
}

///|
test "checker independently rejects size Lovasz transform and Gram Schmidt violations" {
  let identity = imat(2, [[1, 0], [0, 1]])
  assert_true(check(identity, identity, identity) is Some(_))
  let size = imat(2, [[1, 0], [3, 1]])
  assert_eq(check(size, identity, size), None)
  let lovasz_bad = imat(2, [[10, 0], [0, 1]])
  assert_eq(check(lovasz_bad, identity, lovasz_bad), None)
  assert_eq(basis(completed(lovasz_bad)), imat(2, [[0, 1], [10, 0]]))
  let nonunit = imat(2, [[2, 0], [0, 2]])
  assert_eq(check(identity, nonunit, nonunit), None)
  assert_eq(check(identity, identity, imat(2, [[1, 0], [0, 2]])), None)
  assert_eq(check(identity, imat(1, [[1]]), identity), None)
  let valid = gram_schmidt(identity).unwrap()
  let badnorm : GramSchmidt = {
    ..valid,
    norms: @oracle.chain([@oracle.rational(2, 1), @oracle.rational(1, 1)]),
  }
  assert_false(check_gram(identity, badnorm))
  assert_eq(check_with_gram(identity, identity, identity, badnorm), None)
  let nonorthogonal : GramSchmidt = {
    orthogonal: @oracle.chain([
      @oracle.chain([@oracle.rational(1, 1), @oracle.rational(0, 1)]),
      @oracle.chain([@oracle.rational(1, 1), @oracle.rational(1, 1)]),
    ]),
    coefficients: @oracle.chain([Nil, @oracle.chain([@oracle.rational(-1, 1)])]),
    norms: @oracle.chain([@oracle.rational(1, 1), @oracle.rational(2, 1)]),
  }
  assert_false(check_gram(identity, nonorthogonal))
  let badmu : GramSchmidt = {
    ..valid,
    coefficients: @oracle.chain([Nil, @oracle.chain([@oracle.rational(1, 1)])]),
  }
  assert_false(check_gram(identity, badmu))
}

///|
test "fuel partitions preserve exact basis transforms and integral lattice equivalence" {
  let input = imat(3, [[1, 1, 1], [-1, 0, 2], [3, 5, 6]])
  let machine = start(input).unwrap()
  assert_eq(run(machine, @oracle.nat(0)), Paused(machine))
  for budget in 0..<80 {
    let once = run(machine, @oracle.nat(budget))
    let mut chunked = Paused(machine)
    for _ in 0..<budget {
      chunked = match chunked {
        Paused(next) => run(next, @oracle.nat(1))
        result => result
      }
    }
    assert_eq(chunked, once)
    match once {
      Paused(state) => {
        assert_eq(
          @matrix.multiply(state.transform, input, integers()),
          Some(state.basis),
        )
        assert_true(unimodular(state.transform))
        assert_true(check_gram(state.basis, gram_schmidt(state.basis).unwrap()))
      }
      Done(result) =>
        assert_eq(check(input, transform(result), basis(result)), Some(result))
      Fault(_) => abort("full rank integer basis must preserve its invariants")
    }
  }
}

///|
test "all full rank small two dimensional bases meet independent integer inequalities" {
  for a in -2..<3 {
    for b in -2..<3 {
      for c in -2..<3 {
        for d in -2..<3 {
          let input = imat(2, [[a, b], [c, d]])
          if a * d - b * c == 0 {
            assert_eq(start(input), None)
          } else {
            let result = completed(input)
            let rows = @oracle.array(@matrix.rows(basis(result))).map(fn(row) {
              @oracle.array(row).map(@oracle.int_of_integer)
            })
            let u = rows[0]
            let v = rows[1]
            let norm_u = u[0] * u[0] + u[1] * u[1]
            let norm_v = v[0] * v[0] + v[1] * v[1]
            let dot = u[0] * v[0] + u[1] * v[1]
            assert_true(2 * dot.abs() <= norm_u)
            assert_true(4 * norm_v >= 3 * norm_u)
            let t = @oracle.array(@matrix.rows(transform(result))).map(fn(row) {
              @oracle.array(row).map(@oracle.int_of_integer)
            })
            assert_eq((t[0][0] * t[1][1] - t[0][1] * t[1][0]).abs(), 1)
            assert_eq([t[0][0] * a + t[0][1] * c, t[0][0] * b + t[0][1] * d], u)
            assert_eq([t[1][0] * a + t[1][1] * c, t[1][0] * b + t[1][1] * d], v)
          }
        }
      }
    }
  }
}
