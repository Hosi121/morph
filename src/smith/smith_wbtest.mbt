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
fn completed(input : @matrix.Matrix[@exact.Integer]) -> Decomposition {
  match run(start(input), @oracle.nat(2000)) {
    Done(form) => form
    _ => abort("small Smith computation must finish")
  }
}

///|
fn check_fixture(
  width : Int32,
  rows : Array[Array[Int32]],
  expected : Array[Array[Int32]],
) -> Unit raise {
  let input = imat(width, rows)
  let form = completed(input)
  assert_eq(original(form), input)
  assert_eq(diagonal(form), imat(width, expected))
  assert_eq(check(input, left(form), diagonal(form), right(form)), Some(form))
}

///|
test "two and three square Smith forms include divisibility repair and rank loss" {
  check_fixture(2, [[2, 4], [6, 8]], [[2, 0], [0, 4]])
  check_fixture(2, [[4, 0], [0, 6]], [[2, 0], [0, 12]])
  check_fixture(2, [[0, 6], [10, 0]], [[2, 0], [0, 30]])
  check_fixture(2, [[-2, 4], [-6, 8]], [[2, 0], [0, 4]])
  check_fixture(3, [[12, 6, 4], [3, 9, 6], [2, 16, 14]], [
    [1, 0, 0],
    [0, 10, 0],
    [0, 0, 30],
  ])
  let deficient = completed(imat(3, [[1, 2, 3], [2, 4, 6], [3, 6, 9]]))
  assert_eq(diagonal(deficient), imat(3, [[1, 0, 0], [0, 0, 0], [0, 0, 0]]))
  assert_eq(rank(deficient), @oracle.nat(1))
}

///|
test "zero dimensions rectangles and zero matrices retain their full shapes" {
  check_fixture(0, [], [])
  check_fixture(3, [], [])
  check_fixture(0, [[], [], []], [[], [], []])
  check_fixture(2, [[0, 0], [0, 0]], [[0, 0], [0, 0]])
  check_fixture(3, [[2, 4, 6], [8, 10, 12]], [[2, 0, 0], [0, 6, 0]])
  check_fixture(2, [[2, 8], [4, 10], [6, 12]], [[2, 0], [0, 6], [0, 0]])
  check_fixture(3, [[-6, 9, 15]], [[3, 0, 0]])
  check_fixture(1, [[-6], [9], [15]], [[3], [0], [0]])
}

///|
test "independent checker rejects equality unimodularity sign chain and shape violations" {
  let identity = imat(2, [[1, 0], [0, 1]])
  let good = imat(2, [[2, 0], [0, 6]])
  assert_true(check(good, identity, good, identity) is Some(_))
  assert_eq(check(good, identity, imat(2, [[2, 0], [0, 8]]), identity), None)
  let nonchain = imat(2, [[2, 0], [0, 3]])
  assert_eq(check(nonchain, identity, nonchain, identity), None)
  let badzero = imat(2, [[0, 0], [0, 2]])
  assert_eq(check(badzero, identity, badzero, identity), None)
  let off_diagonal = imat(2, [[2, 1], [0, 6]])
  assert_eq(check(off_diagonal, identity, off_diagonal, identity), None)
  let negative = imat(2, [[-2, 0], [0, 6]])
  assert_eq(check(good, imat(2, [[-1, 0], [0, 1]]), negative, identity), None)
  let nonunit = imat(2, [[2, 0], [0, 2]])
  assert_eq(check(identity, nonunit, nonunit, identity), None)
  assert_eq(check(identity, identity, nonunit, nonunit), None)
  let zeros = imat(2, [[0, 0], [0, 0]])
  assert_eq(check(zeros, zeros, zeros, identity), None)
  assert_eq(check(good, imat(1, [[1]]), good, identity), None)
}

///|
test "fuel partitions preserve all intermediate transforms and unimodularity" {
  let input = imat(3, [[6, 12, 18], [4, 10, 14], [2, 8, 16]])
  let machine = start(input)
  assert_eq(run(machine, @oracle.nat(0)), Paused(machine))
  for budget in 0..<64 {
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
        let product = @matrix.multiply(state.left, input, integers()).unwrap()
        assert_eq(
          @matrix.multiply(product, state.right, integers()),
          Some(state.current),
        )
        assert_true(unimodular(state.left))
        assert_true(unimodular(state.right))
      }
      Done(form) =>
        assert_eq(
          check(input, left(form), diagonal(form), right(form)),
          Some(form),
        )
      Fault(_) => abort("valid matrix must preserve all invariants")
    }
  }
}

///|
fn integer_gcd(a : Int32, b : Int32) -> Int32 {
  let mut x = a.abs()
  let mut y = b.abs()
  while y != 0 {
    let r = x % y
    x = y
    y = r
  }
  x
}

///|
test "all two square entries from minus two to two match integer determinantal divisors" {
  for a in -2..<3 {
    for b in -2..<3 {
      for c in -2..<3 {
        for d in -2..<3 {
          let g = integer_gcd(integer_gcd(a, b), integer_gcd(c, d))
          let determinant = (a * d - b * c).abs()
          let second = if g == 0 { 0 } else { determinant / g }
          let form = completed(imat(2, [[a, b], [c, d]]))
          assert_eq(
            @oracle.array(
              @core.map(invariant_factors(form), @oracle.int_of_binary),
            ),
            [g, second],
          )
        }
      }
    }
  }
}
