///|
fn matrix(
  values : Array[Array[Int32]],
  width : Int32,
) -> @matrix.Matrix[@exact.Integer] {
  @matrix.matrix(
    @oracle.nat(width),
    @oracle.chain(
      values.map(fn(row) { @oracle.chain(row.map(@oracle.integer)) }),
    ),
  ).unwrap()
}

///|
test "matrix pair engine distinguishes integral torsion from rational rank" {
  let a = matrix([[0, 0]], 2)
  let b = matrix([[2], [0]], 1)
  let c = match compute(a, b, @oracle.nat(100)) {
    Computed(c) => c
    _ => abort("finite matrix pair completes")
  }
  assert_eq(c.result.free_rank, @oracle.nat(1))
  assert_eq(c.result.torsion, @oracle.chain([@oracle.binary(2)]))
  assert_true(check_result(a, b, c.result, c))
  assert_false(check_result(matrix([[0, 0], [0, 0]], 2), b, c.result, c))
  assert_false(check_result(a, matrix([[3], [0]], 1), c.result, c))
  assert_false(
    check_result(a, b, { ..c.result, free_rank: @oracle.nat(0), }, c),
  )
  assert_false(
    check_result(a, b, c.result, { ..c, coordinates: matrix([[0], [0]], 1), }),
  )
  assert_eq(compute(a, b, @oracle.nat(0)), BudgetExhausted)
}

///|
test "noncomposable and nonchain matrix pairs are rejected before Smith search" {
  assert_eq(
    compute(matrix([[1]], 1), matrix([[2]], 1), @oracle.nat(0)),
    InvalidWitness,
  )
  assert_eq(
    compute(matrix([[0]], 1), matrix([[0], [0]], 1), @oracle.nat(10)),
    InvalidWitness,
  )
}
