///|
fn rational_matrix(
  rows : Array[Array[Int32]],
) -> @matrix.Matrix[@exact.Rational] {
  @matrix.matrix(
    @oracle.nat(if rows.is_empty() { 0 } else { rows[0].length() }),
    @oracle.chain(
      rows.map(fn(row) {
        @oracle.chain(row.map(fn(x) { @oracle.rational(x, 1) }))
      }),
    ),
  ).unwrap()
}

///|
fn int_ring(modulus : Int32) -> Ring[Int32] {
  {
    semiring: {
      zero: 0,
      one: 1,
      plus: fn(a, b) { (a + b) % modulus },
      times: fn(a, b) { a * b % modulus },
    },
    negate: fn(x) { (modulus - x) % modulus },
  }
}

///|
test "empty square scalar triangular and invalid dimensions" {
  let q = rationals()
  let empty = rational_matrix([])
  assert_eq(characteristic(empty, q), Some(Cons(@oracle.rational(1, 1), Nil)))
  assert_eq(determinant(empty, q), Some(@oracle.rational(1, 1)))
  assert_eq(adjugate(empty, q), Some(empty))
  let scalar = rational_matrix([[7]])
  assert_eq(
    characteristic(scalar, q),
    Some(@oracle.chain([@oracle.rational(1, 1), @oracle.rational(-7, 1)])),
  )
  assert_eq(adjugate(scalar, q), Some(rational_matrix([[1]])))
  let a = rational_matrix([[2, 99, -3], [0, 3, -12], [0, 0, -1]])
  assert_eq(
    characteristic(a, q),
    Some(@oracle.chain([1, -4, 1, 6].map(fn(x) { @oracle.rational(x, 1) }))),
  )
  assert_eq(determinant(a, q), Some(@oracle.rational(-6, 1)))
  let rectangular = rational_matrix([[1, 2, 3], [4, 5, 6]])
  assert_eq(characteristic(rectangular, q), None)
  assert_eq(determinant(rectangular, q), None)
  assert_eq(adjugate(rectangular, q), None)
  assert_eq(evaluate_matrix(Nil, rectangular, q.semiring), None)
  let no_rows = @matrix.matrix(@oracle.nat(3), Nil).unwrap()
  assert_eq(characteristic(no_rows, q), None)
}

///|
test "all three by three binary matrices over fields and zero divisor rings" {
  for mask in 0..<512 {
    let entries = [
      for i in 0..<3 => [ for j in 0..<3 => (mask >> (3 * i + j)) & 1 ]
    ]
    let exact_matrix = @matrix.matrix(
      @oracle.nat(3),
      @oracle.chain(
        entries.map(fn(row) { @oracle.chain(row.map(@oracle.integer)) }),
      ),
    ).unwrap()
    let expected = @oracle.array(
      characteristic(exact_matrix, integers()).unwrap(),
    ).map(@oracle.int_of_integer)
    for modulus in [2, 4, 6] {
      let ring = int_ring(modulus)
      let matrix = @matrix.matrix(
        @oracle.nat(3),
        @oracle.chain(entries.map(@oracle.chain)),
      ).unwrap()
      let coeffs = characteristic(matrix, ring).unwrap()
      assert_eq(
        @oracle.array(coeffs),
        expected.map(fn(x) { (x % modulus + modulus) % modulus }),
      )
      let zero = @matrix.matrix(
        @oracle.nat(3),
        @oracle.chain([
          @oracle.chain([0, 0, 0]),
          @oracle.chain([0, 0, 0]),
          @oracle.chain([0, 0, 0]),
        ]),
      ).unwrap()
      assert_eq(evaluate_matrix(coeffs, matrix, ring.semiring), Some(zero))
      let adj = adjugate(matrix, ring).unwrap()
      let det = determinant(matrix, ring).unwrap()
      let diagonal = @matrix.matrix(
        @oracle.nat(3),
        @oracle.chain([
          @oracle.chain([det, 0, 0]),
          @oracle.chain([0, det, 0]),
          @oracle.chain([0, 0, det]),
        ]),
      ).unwrap()
      assert_eq(@matrix.multiply(matrix, adj, ring.semiring), Some(diagonal))
      assert_eq(@matrix.multiply(adj, matrix, ring.semiring), Some(diagonal))
    }
  }
}

///|
test "zero divisor determinant and singular adjugate retain information" {
  let ring = int_ring(6)
  let a = @matrix.matrix(
    @oracle.nat(2),
    @oracle.chain([@oracle.chain([2, 0]), @oracle.chain([0, 3])]),
  ).unwrap()
  assert_eq(characteristic(a, ring), Some(@oracle.chain([1, 1, 0])))
  assert_eq(determinant(a, ring), Some(0))
  assert_eq(
    adjugate(a, ring),
    @matrix.matrix(
      @oracle.nat(2),
      @oracle.chain([@oracle.chain([3, 0]), @oracle.chain([0, 2])]),
    ),
  )
}
