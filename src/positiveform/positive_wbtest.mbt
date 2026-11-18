///|
fn q(n : Int32, d : Int32) -> @exact.Rational {
  @oracle.rational(n, d)
}

///|
fn vector(values : Array[(Int32, Int32)]) -> @core.Chain[@exact.Rational] {
  @oracle.chain(values.map(fn(pair) { q(pair.0, pair.1) }))
}

///|
fn matrix(
  values : Array[Array[(Int32, Int32)]],
  width : Int32,
) -> @matrix.Matrix[@exact.Rational] {
  @matrix.matrix(@oracle.nat(width), @oracle.chain(values.map(vector))).unwrap()
}

///|
test "positive scalar closure and inverse retain strict positivity" {
  assert_eq(positive_scalar(q(0, 1)), None)
  assert_eq(positive_scalar(q(-1, 7)), None)
  for a in 1..<=7 {
    let value = positive_scalar(q(a, 9)).unwrap()
    assert_eq(value.inverse().value(), q(9, a))
    assert_eq(value.inverse().inverse(), value)
    assert_eq(value.multiply(value.inverse()), one())
    assert_eq(value.power(@oracle.nat(3)).value(), q(a * a * a, 729))
  }
}

///|
test "exhaustive symmetric two by two forms match the independent principal minor criterion" {
  for a in -3..<=3 {
    for b in -3..<=3 {
      for c in -3..<=3 {
        let input = matrix([[(a, 1), (b, 1)], [(b, 1), (c, 1)]], 2)
        let determinant = a * c - b * b
        let actual = positive_definite(input)
        if a > 0 && determinant > 0 {
          let form = actual.unwrap()
          assert_eq(form.determinant().value(), q(determinant, 1))
          assert_eq(form.matrix(), Ok(input))
          let inverse = matrix(
            [
              [(c, determinant), (-b, determinant)],
              [(-b, determinant), (a, determinant)],
            ],
            2,
          )
          assert_eq(form.inverse().matrix(), Ok(inverse))
          assert_eq(
            form.solve(vector([(2, 1), (-3, 1)])),
            Some(
              vector([
                (2 * c + 3 * b, determinant),
                (-2 * b - 3 * a, determinant),
              ]),
            ),
          )
          assert_eq(form.inverse().inverse(), form)
        } else {
          assert_true(actual is Err(NotPositiveDefinite))
        }
      }
    }
  }
}

///|
test "rational Gram forms reuse solves and agree with independent elimination" {
  for n in 0..<=5 {
    let rows = Array::makei(n, fn(i) {
      Array::makei(n, fn(j) {
        let mut entry = if i == j { i + 2 } else { 0 }
        for k in 0..<n {
          entry += ((k + 2 * i) % 5 - 2) * ((k + 2 * j) % 5 - 2)
        }
        (entry, 3)
      })
    })
    let input = matrix(rows, n)
    let form = positive_definite(input).unwrap()
    assert_eq(form.inverse().matrix(), Ok(@linear.inverse(input).unwrap()))
    assert_eq(form.determinant().value(), @linear.determinant(input).unwrap())
    for t in 0..<3 {
      let rhs = @oracle.chain(Array::makei(n, fn(i) { q(i - t, i + 1) }))
      let solution = form.solve(rhs).unwrap()
      assert_eq(form.apply(solution), Some(rhs))
      assert_eq(form.inverse().apply(rhs), Some(solution))
      assert_eq(form.inverse().solve(solution), Some(rhs))
      assert_true(
        @exact.rational_compare(form.determinant().value(), q(0, 1)) is Greater,
      )
    }
    assert_eq(
      form.solve(@core.Cons(q(1, 1), @core.replicate(@oracle.nat(n), q(0, 1)))),
      None,
    )
  }
}

///|
test "inverse scale and direct sum keep canonical construction and skip dense factorization" {
  let a = positive_definite(matrix([[(4, 3), (2, 5)], [(2, 5), (7, 2)]], 2)).unwrap()
  let b = positive_definite(matrix([[(3, 7)]], 1)).unwrap()
  let empty = positive_definite(matrix([], 0)).unwrap()
  let two = positive_scalar(q(2, 1)).unwrap()
  assert_true(a.inverse().structure is Inverse(_))
  assert_eq(a.scale(two).scale(two.inverse()), a)
  assert_eq(a.inverse().scale(two).inverse(), a.scale(two.inverse()))
  assert_eq(a.direct_sum(empty), a)
  assert_eq(empty.direct_sum(a), a)
  assert_eq(empty.inverse(), empty)
  let sum = a.direct_sum(b).direct_sum(b)
  assert_eq(sum, a.direct_sum(b.direct_sum(b)))
  match sum.structure {
    Blocks(blocks) => assert_eq(@core.length(blocks), @oracle.nat(3))
    _ => abort("block structure was erased")
  }
  let expected = matrix(
    [
      [(4, 3), (2, 5), (0, 1), (0, 1)],
      [(2, 5), (7, 2), (0, 1), (0, 1)],
      [(0, 1), (0, 1), (3, 7), (0, 1)],
      [(0, 1), (0, 1), (0, 1), (3, 7)],
    ],
    4,
  )
  assert_eq(sum.matrix(), Ok(expected))
  assert_eq(sum.inverse().matrix(), Ok(@linear.inverse(expected).unwrap()))
  assert_eq(sum.inverse().inverse(), sum)
  assert_eq(sum.determinant().value(), @linear.determinant(expected).unwrap())
  let rhs = vector([(1, 1), (-2, 3), (4, 5), (6, 7)])
  assert_eq(sum.apply(sum.solve(rhs).unwrap()), Some(rhs))
  assert_eq(sum.scale(two).apply(sum.scale(two).solve(rhs).unwrap()), Some(rhs))
  assert_eq(
    sum.scale(two).determinant().value(),
    @exact.rational_multiply(q(16, 1), sum.determinant().value()),
  )
}

///|
test "shape symmetry singularity and indefinite forms are distinct" {
  assert_true(
    positive_definite(matrix([[(1, 1), (0, 1)]], 2)) is Err(NotSquare),
  )
  assert_true(
    positive_definite(matrix([[(1, 1), (1, 1)], [(0, 1), (1, 1)]], 2))
    is Err(NotSymmetric),
  )
  assert_true(
    positive_definite(matrix([[(1, 1), (1, 1)], [(1, 1), (1, 1)]], 2))
    is Err(NotPositiveDefinite),
  )
  assert_true(
    positive_definite(matrix([[(-1, 1), (0, 1)], [(0, 1), (-1, 1)]], 2))
    is Err(NotPositiveDefinite),
  )
}
