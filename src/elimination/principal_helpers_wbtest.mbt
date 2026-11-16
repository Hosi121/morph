///|
fn principal_fixture(
  f : @core.Chain[@exact.Rational],
  g : @core.Chain[@exact.Rational],
  expected : @core.Chain[@exact.Rational],
  gcd : @core.Nat?,
) -> Unit raise {
  let ring = @berkowitz.rationals()
  let left = dense(f, ring)
  let right = dense(g, ring)
  let values = principal_coefficients(left, right, ring).unwrap()
  assert_eq(values, expected)
  assert_eq(@core.nth(values, @oracle.nat(0)), resultant(left, right, ring))
  match gcd {
    Some(degree) =>
      assert_eq(
        first_nonzero(values, @exact.rational_zero(), fn(a, b) { a == b }),
        Some(degree),
      )
    None => ()
  }
  for
    (index, value) in @oracle.array(expected).mapi(fn(i, value) { (i, value) }) {
    let k = @oracle.nat(index)
    let proof = principal_certificate(left, right, k, ring).unwrap()
    assert_true(
      check_principal(left, right, k, value, proof, ring, fn(a, b) { a == b }),
    )
    let wrong = @exact.rational_add(value, @exact.rational_one())
    assert_false(
      check_principal(left, right, k, wrong, proof, ring, fn(a, b) { a == b }),
    )
    assert_false(
      check_principal(
        left,
        right,
        k,
        value,
        { ..proof, index: @core.Succ(k), },
        ring,
        fn(a, b) { a == b },
      ),
    )
  }
  assert_true(
    principal_subresultant(
      left,
      right,
      @core.Succ(@core.minimum(nominal_degree(left), nominal_degree(right))),
      ring,
    )
    is None,
  )
}

///|
fn principal_variable_fixture(
  f : @poly.Polynomial,
  g : @poly.Polynomial,
  selected : Int32,
  n : Int32,
  m : Int32,
  coefficients : @core.Chain[@poly.Polynomial],
  expected : @core.Chain[@poly.Polynomial],
) -> Unit raise {
  let left = fixed_input(f, @oracle.nat(selected), @oracle.nat(n)).unwrap()
  let right = fixed_input(g, @oracle.nat(selected), @oracle.nat(m)).unwrap()
  assert_eq(coefficient_polynomials(left), Ok(coefficients))
  assert_eq(principal_coefficients_variable(left, right), Ok(expected))
  for
    (index, value) in @oracle.array(expected).mapi(fn(i, value) { (i, value) }) {
    let k = @oracle.nat(index)
    let proof = principal_variable_certificate(left, right, k).unwrap()
    assert_true(check_principal_variable(left, right, k, value, proof))
    let wrong = @poly.add(
      value,
      @poly.constant(@poly.variables(value), @exact.rational_one()),
    ).unwrap()
    assert_false(check_principal_variable(left, right, k, wrong, proof))
    assert_false(
      check_principal_variable(left, right, k, value, {
        ..proof,
        index: @core.Succ(k),
      }),
    )
    assert_false(
      check_principal_variable(left, right, k, value, {
        ..proof,
        left: fixed_input(f, @oracle.nat(selected), @oracle.nat(n + 1)).unwrap(),
      }),
    )
  }
}

///|
test "principal top same-degree constants and zero derivative conventions" {
  let ring = @berkowitz.rationals()
  let f = elimination_small([2, 4, 2])
  let g = elimination_small([6, 12, 6])
  assert_eq(
    principal_coefficients(f, g, ring),
    Some(
      @oracle.chain([
        @oracle.rational(0, 1),
        @oracle.rational(0, 1),
        @oracle.rational(1, 1),
      ]),
    ),
  )
  let zero = elimination_small([0])
  assert_eq(
    principal_coefficients(zero, zero, ring),
    Some(@oracle.chain([@exact.rational_one()])),
  )
  let constant = elimination_small([7])
  assert_eq(
    principal_coefficients(constant, derivative(constant, ring), ring),
    Some(@oracle.chain([@exact.rational_one()])),
  )
  let nominal_zero_derivative = elimination_small([0, 0])
  let values = principal_coefficients(f, nominal_zero_derivative, ring).unwrap()
  assert_eq(
    first_nonzero(values, @exact.rational_zero(), fn(a, b) { a == b }),
    None,
  )
}
