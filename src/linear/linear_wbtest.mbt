///|
fn matrix(
  xs : Array[Array[Int32]],
  width~ : Int32 = -1,
) -> @matrix.Matrix[@exact.Rational] {
  let n = if width >= 0 {
    width
  } else if xs.is_empty() {
    0
  } else {
    xs[0].length()
  }
  match
    @matrix.matrix(
      @oracle.nat(n),
      @oracle.chain(
        xs.map(fn(row) {
          @oracle.chain(row.map(fn(x) { @oracle.rational(x, 1) }))
        }),
      ),
    ) {
    Some(m) => m
    None => abort("test matrix")
  }
}

///|
fn vector(xs : Array[Int32]) -> @core.Chain[@exact.Rational] {
  @oracle.chain(xs.map(fn(x) { @oracle.rational(x, 1) }))
}

///|
fn apply(
  a : @matrix.Matrix[@exact.Rational],
  x : @core.Chain[@exact.Rational],
) -> @core.Chain[@exact.Rational] {
  @core.map(@matrix.rows(a), fn(row) {
    match @core.zip(row, x) {
      None => abort("test vector size")
      Some(pairs) =>
        @core.fold_left(pairs, @exact.rational_zero(), fn(sum, pair) {
          @exact.rational_add(sum, @exact.rational_multiply(pair.0, pair.1))
        })
    }
  })
}

///|
test "exact determinant and inverse exhaust all ternary two by two matrices" {
  for a in -1..<=1 {
    for b in -1..<=1 {
      for c in -1..<=1 {
        for d in -1..<=1 {
          let input = matrix([[a, b], [c, d]])
          let expected = a * d - b * c
          assert_eq(determinant(input), Some(@oracle.rational(expected, 1)))
          match inverse(input) {
            None => assert_eq(expected, 0)
            Some(inv) => {
              assert_true(expected != 0)
              assert_eq(
                @matrix.multiply(input, inv, @algebra.rationals()),
                Some(@matrix.identity(@oracle.nat(2), @algebra.rationals())),
              )
              assert_eq(
                @matrix.multiply(inv, input, @algebra.rationals()),
                Some(@matrix.identity(@oracle.nat(2), @algebra.rationals())),
              )
            }
          }
        }
      }
    }
  }
  assert_eq(determinant(matrix([])), Some(@exact.rational_one()))
  assert_eq(inverse(matrix([])), Some(matrix([])))
  assert_eq(determinant(matrix([[1, 2, 3]])), None)
  for family in 0..<30 {
    let a = [
      for i in 0..<3 => {
        [
          for j in 0..<3 => {
            (family * 11 + i * 7 + j * 3 + i * j * family) % 7 - 3
          }
        ]
      }
    ]
    let det = a[0][0] * (a[1][1] * a[2][2] - a[1][2] * a[2][1]) -
      a[0][1] * (a[1][0] * a[2][2] - a[1][2] * a[2][0]) +
      a[0][2] * (a[1][0] * a[2][1] - a[1][1] * a[2][0])
    assert_eq(determinant(matrix(a)), Some(@oracle.rational(det, 1)))
  }
}

///|
test "linear solver returns unique, affine and inconsistent results" {
  assert_eq(
    solve(matrix([[2, 1], [1, -1]]), vector([5, 1])),
    Some(Unique(vector([2, 1]))),
  )
  let a = matrix([[1, 2, 3], [2, 4, 6]])
  match solve(a, vector([4, 8])) {
    Some(Affine(particular, basis)) => {
      assert_eq(apply(a, particular), vector([4, 8]))
      assert_eq(particular, vector([4, 0, 0]))
      assert_eq(basis, @oracle.chain([vector([-2, 1, 0]), vector([-3, 0, 1])]))
      assert_eq(@oracle.array(basis).length(), 2)
      for v in @oracle.array(basis) {
        assert_eq(apply(a, v), vector([0, 0]))
      }
    }
    _ => fail("expected affine solution")
  }
  assert_eq(solve(a, vector([4, 9])), Some(Inconsistent))
  assert_eq(solve(a, vector([4])), None)
  match solve(matrix([], width=3), Nil) {
    Some(Affine(particular, basis)) => {
      assert_eq(particular, vector([0, 0, 0]))
      assert_eq(@oracle.array(basis).length(), 3)
    }
    _ => fail("empty equations leave all variables free")
  }
  assert_eq(solve(matrix([]), Nil), Some(Unique(Nil)))
  assert_eq(solve(matrix([[]], width=0), vector([1])), Some(Inconsistent))
}

///|
test "rectangular systems generated from known solutions preserve exact witnesses" {
  for height in 1..<=3 {
    for width in 1..<=3 {
      for family in 0..<12 {
        let a = matrix(
          [
            for i in 0..<height => {
              [
                for j in 0..<width => (i * 7 + j * 3 + family * 11) % 7 - 3
              ]
            }
          ],
        )
        let known = vector([ for j in 0..<width => j - 1 ])
        let rhs = apply(a, known)
        match solve(a, rhs) {
          Some(Unique(solution)) => assert_eq(apply(a, solution), rhs)
          Some(Affine(particular, basis)) => {
            assert_eq(apply(a, particular), rhs)
            for v in @oracle.array(basis) {
              assert_eq(apply(a, v), vector(Array::make(height, 0)))
            }
          }
          _ => fail("consistent generated system rejected")
        }
      }
    }
  }
}
