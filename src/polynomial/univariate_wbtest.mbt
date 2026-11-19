///|
test "generic Horner retains zero dimensional rejection and callback failures" {
  let z = @exact.rational_zero()
  let o = @exact.rational_one()
  let fail_operation : (@exact.Rational, @exact.Rational) -> Result[
    @exact.Rational,
    Unit,
  ] = fn(_, _) { Err(()) }
  assert_eq(
    evaluate_in(
      o,
      zero(@oracle.nat(1)),
      z,
      fn(x) { x },
      fail_operation,
      fail_operation,
    ),
    Some(z),
  )
  assert_true(
    evaluate_in(
      o,
      zero(@oracle.nat(2)),
      z,
      fn(x) { x },
      fail_operation,
      fail_operation,
    )
    is None,
  )
  let constant = constant(@oracle.nat(1), o)
  assert_true(
    evaluate_in(o, constant, z, fn(x) { x }, fail_operation, fail_operation)
    is None,
  )
  assert_eq(univariate_coefficient(constant, Zero), o)
  assert_eq(univariate_degree(constant), Some(Zero))
  assert_eq(univariate_degree(zero(@oracle.nat(1))), None)
}
