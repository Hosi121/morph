///|
/// Independent machine-integer monic long division for the finite coordinate
/// and multiplication-matrix fixtures. Production polynomial arithmetic is not
/// used to compute the expected coefficient arrays.
fn kernel_remainder(
  values : Array[Int64],
  monic : Array[Int64],
) -> Array[Int64] {
  let d = monic.length() - 1
  let remainder = values.copy()
  for k = values.length() - 1; k >= d; k = k - 1 {
    let c = remainder[k]
    for j in 0..<=d {
      remainder[k - d + j] = remainder[k - d + j] - c * monic[j]
    }
  }
  [
    for i in 0..<d => if i < remainder.length() { remainder[i] } else { 0L }
  ]
}

///|
test "coordinate scan matches independent reduced sparse dense zero and degree one vectors" {
  let fixtures : Array[(Field, Array[Int64])] = [
    (test_field([(0, 1), (1, 1)], (-1, 1), (0, 1)), [0, 1]),
    (test_sqrt2(), [-2, 0, 1]),
    (
      test_field([(1, 1), (0, 1), (-10, 1), (0, 1), (1, 1)], (3, 1), (4, 1)),
      [1, 0, -10, 0, 1],
    ),
  ]
  for (f, monic) in fixtures {
    let d = monic.length() - 1
    let values : Array[Array[Int64]] = [
      [],
      [0],
      [1],
      [-2, 0, 0, 1],
      [1, -1, 2, -2, 1, 0, -1, 1, -1],
    ]
    for input in values {
      let a = element(f, test_poly(input.map(fn(n) { (n, 1L) }))).unwrap()
      let expected = kernel_remainder(input, monic).map(fn(n) {
        test_rational(n, 1)
      })
      assert_eq(coordinates(a), @oracle.chain(expected))
      // Frozen old d-full-scans path remains an explicit finite comparison.
      assert_eq(
        coordinates(a),
        @core.map(@core.indices(degree(f)), fn(i) {
          @poly.univariate_coefficient(representative(a), i)
        }),
      )
      assert_eq(@core.length(coordinates(a)), @oracle.nat(d))
      let expected_rows = [
        for i in 0..<d => {
          [
            for j in 0..<d => {
              let shifted = [
                for k in 0..<(input.length() + j) => {
                  if k < j {
                    0L
                  } else {
                    input[k - j]
                  }
                }
              ]
              test_rational(kernel_remainder(shifted, monic)[i], 1)
            }
          ]
        }
      ]
      assert_eq(
        @matrix.rows(multiplication_matrix(a).unwrap()),
        @oracle.chain(expected_rows.map(@oracle.chain)),
      )
    }
    let fractions : Array[(Int64, Int64)] = [
      for i in 0..<d => if i % 2 == 0 { (-1L, 3L) } else { (0L, 1L) }
    ]
    let a = element(f, test_poly(fractions)).unwrap()
    assert_eq(
      coordinates(a),
      @oracle.chain(fractions.map(fn(pair) { test_rational(pair.0, pair.1) })),
    )
  }
}
