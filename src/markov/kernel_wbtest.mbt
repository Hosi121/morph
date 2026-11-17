///|
fn fraction_vector(
  values : Array[(Int32, Int32)],
) -> @core.Chain[@exact.Rational] {
  @oracle.chain(
    values.map(fn(value) {
      let (n, d) = value
      @oracle.rational(n, d)
    }),
  )
}

///|
fn fraction_rows(
  rows : Array[Array[(Int32, Int32)]],
) -> @core.Chain[@core.Chain[@exact.Rational]] {
  @oracle.chain(rows.map(fraction_vector))
}

///|
fn fraction_kernel_fixture(
  rows : Array[Array[(Int32, Int32)]],
  exponent : Int32,
  expected : Array[Array[(Int32, Int32)]],
  initial : Array[(Int32, Int32)],
  evolved : Array[(Int32, Int32)],
) -> Unit raise {
  let value = kernel(fraction_rows(rows)).unwrap()
  let iterated = power(value, @oracle.binary(exponent)).unwrap()
  assert_eq(@matrix.rows(transitions(iterated)), fraction_rows(expected))
  assert_eq(states(value), @oracle.nat(rows.length()))
  assert_eq(
    evolve_steps(value, fraction_vector(initial), @oracle.binary(exponent)),
    Ok(fraction_vector(evolved)),
  )
  assert_true(
    check_evolution(
      iterated,
      fraction_vector(initial),
      fraction_vector(evolved),
    ),
  )
  let next = compose(iterated, value).unwrap()
  assert_true(check_composition(iterated, value, next))
}

///|
fn fraction_composition_fixture(
  a : Array[Array[(Int32, Int32)]],
  b : Array[Array[(Int32, Int32)]],
  expected : Array[Array[(Int32, Int32)]],
) -> Unit raise {
  let first = kernel(fraction_rows(a)).unwrap()
  let second = kernel(fraction_rows(b)).unwrap()
  let result = compose(first, second).unwrap()
  assert_eq(@matrix.rows(transitions(result)), fraction_rows(expected))
  assert_true(check_composition(first, second, result))
}

///|
test "kernel construction and distribution boundaries are exact" {
  assert_eq(kernel(Nil), Err(EmptyStateSpace))
  assert_eq(identity(Zero), Err(EmptyStateSpace))
  assert_eq(kernel(fraction_rows([[(1, 1), (0, 1)]])), Err(NonSquare))
  assert_eq(kernel(fraction_rows([[(1, 1)], []])), Err(NonSquare))
  assert_eq(kernel(fraction_rows([[(-1, 1)]])), Err(NegativeProbability))
  assert_eq(kernel(fraction_rows([[(2, 1)]])), Err(NotNormalized))
  assert_eq(kernel(fraction_rows([[(0, 1)]])), Err(NotNormalized))
  let value = identity(@oracle.nat(2)).unwrap()
  assert_eq(evolve(value, Nil), Err(DimensionMismatch))
  assert_eq(
    evolve(value, fraction_vector([(-1, 1), (2, 1)])),
    Err(NegativeProbability),
  )
  assert_eq(
    evolve(value, fraction_vector([(1, 3), (1, 3)])),
    Err(NotNormalized),
  )
  assert_eq(
    compose(value, identity(@oracle.nat(1)).unwrap()),
    Err(DimensionMismatch),
  )
  assert_true(!check_evolution(value, Nil, Nil))
  assert_true(
    !check_evolution(
      value,
      fraction_vector([(1, 1), (0, 1)]),
      fraction_vector([(0, 1), (1, 1)]),
    ),
  )
}

///|
test "composition order is the row-distribution convention" {
  let swap = kernel(fraction_rows([[(0, 1), (1, 1)], [(1, 1), (0, 1)]])).unwrap()
  let reset = kernel(fraction_rows([[(1, 1), (0, 1)], [(1, 1), (0, 1)]])).unwrap()
  assert_eq(compose(swap, reset), Ok(reset))
  assert_eq(
    compose(reset, swap),
    Ok(kernel(fraction_rows([[(0, 1), (1, 1)], [(0, 1), (1, 1)]])).unwrap()),
  )
  assert_true(!check_composition(reset, swap, reset))
  assert_eq(
    power(swap, @oracle.binary(2)),
    Ok(identity(@oracle.nat(2)).unwrap()),
  )
  assert_eq(power(swap, @oracle.binary(65537)), Ok(swap))
}
