///|
test "remainder-only preserves dimension-before-zero and empty boundary cases" {
  let f = poly(2, [(1, [1, 0]), (2, [0, 0])])
  let z = zero(@oracle.nat(2))
  let wrong = zero(@oracle.nat(1))
  let cases = [
    (f, @oracle.chain([wrong, z]), Err(DimensionMismatch)),
    (z, @oracle.chain([wrong, z]), Err(DimensionMismatch)),
    (z, @oracle.chain([z, wrong]), Err(DimensionMismatch)),
    (z, @oracle.chain([z]), Err(ZeroDivisor)),
    (f, @oracle.chain([z]), Err(ZeroDivisor)),
    (f, Nil, Ok(f)),
    (z, Nil, Ok(z)),
  ]
  for (input, divisors, expected) in cases {
    assert_eq(normal_form(input, divisors), expected)
    assert_eq(
      normal_form(input, divisors),
      divide(input, divisors).map(fn(d) { d.remainder }),
    )
  }
  let constant = remainder_fixture(0, [(2, 3, [])])
  let divisor = remainder_fixture(0, [(-3, 2, [])])
  assert_eq(normal_form(constant, Cons(divisor, Nil)), Ok(zero(Zero)))
  assert_eq(normal_form(constant, Nil), Ok(constant))
}
