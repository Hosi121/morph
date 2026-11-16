///|
fn fraction_matrix(
  entries : Array[Array[(Int32, Int32)]],
) -> @matrix.Matrix[@exact.Rational] {
  @matrix.matrix(
    @oracle.nat(if entries.is_empty() { 0 } else { entries[0].length() }),
    @oracle.chain(
      entries.map(fn(row) {
        @oracle.chain(
          row.map(fn(pair) {
            let (n, d) = pair
            @oracle.rational(n, d)
          }),
        )
      }),
    ),
  ).unwrap()
}

///|
fn assert_leibniz_fixture(
  entries : Array[Array[(Int32, Int32)]],
  coefficients : Array[(Int32, Int32)],
  expected_adjugate : Array[Array[(Int32, Int32)]],
) -> Unit raise {
  let ring = rationals()
  let matrix = fraction_matrix(entries)
  let expected = @oracle.chain(
    coefficients.map(fn(pair) {
      let (n, d) = pair
      @oracle.rational(n, d)
    }),
  )
  assert_eq(characteristic(matrix, ring), Some(expected))
  assert_eq(adjugate(matrix, ring), Some(fraction_matrix(expected_adjugate)))
  assert_eq(determinant(matrix, ring), @linear.determinant(matrix))
  let dimension = @matrix.height(matrix)
  let zero = @matrix.matrix(
    dimension,
    @core.replicate(
      dimension,
      @core.replicate(dimension, @exact.rational_zero()),
    ),
  ).unwrap()
  assert_eq(evaluate_matrix(expected, matrix, ring.semiring), Some(zero))
}
