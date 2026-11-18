///|
test "structured covariance survives Gaussian construction without changing measure equality" {
  let a = @positiveform.positive_definite(
    matrix(
      @oracle.chain([
        @oracle.chain([q(2, 1), q(1, 3)]),
        @oracle.chain([q(1, 3), q(3, 2)]),
      ]),
      2,
    ),
  ).unwrap()
  let b = @positiveform.positive_definite(
    matrix(@oracle.chain([@oracle.chain([q(4, 3)])]), 1),
  ).unwrap()
  let form = a
    .direct_sum(b)
    .scale(@positiveform.positive_scalar(q(3, 2)).unwrap())
  let mu = @oracle.chain([q(1, 2), q(-2, 3), q(3, 4)])
  let structured = gaussian_from_form(mu, form).unwrap()
  let dense = gaussian(mu, form.matrix().unwrap()).unwrap()
  assert_eq(structured, dense)
  assert_eq(covariance_form(structured), form)
  assert_true(covariance_form(dense).equivalent(form))
  assert_eq(precision_form(structured).matrix(), Ok(precision(structured)))
  assert_eq(precision_form(structured).inverse(), form)
  for exponents in [[2, 1, 0], [1, 0, 2], [0, 2, 4]] {
    let exponents = @oracle.chain(exponents.map(@oracle.nat))
    assert_eq(moment(structured, exponents), moment(dense, exponents))
  }
  assert_true(gaussian_from_form(@core.Nil, form) is Err(DimensionMismatch))
}
