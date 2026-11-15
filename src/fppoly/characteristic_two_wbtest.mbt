///|
test "characteristic two canonicalizes unreduced huge coefficients and scalar parity" {
  let field = test_field(2)
  let even = @binary.power(@oracle.binary(2), @oracle.binary(1000))
  let odd = @binary.successor(even)
  let value = polynomial(field, @oracle.chain([even, odd, even, odd, even]))
  assert_eq(value, test_polynomial(2, [0, 1, 0, 1]))
  assert_eq(negate(value), value)
  assert_eq(scale(value, odd), value)
  assert_eq(scale(value, even), zero(field))
  assert_eq(monic(value), Ok(value))
  assert_eq(required(divide(value, one(field))), {
    quotient: value,
    remainder: zero(field),
  })
  assert_eq(required(extended_gcd(value, zero(field))), {
    gcd: value,
    left: one(field),
    right: zero(field),
  })
  let foreign = test_polynomial(3, [0, 1, 0, 1])
  assert_eq(add(value, foreign), Err(FieldMismatch))
  assert_eq(multiply(value, foreign), Err(FieldMismatch))
  assert_eq(divide(value, zero(test_field(3))), Err(FieldMismatch))
}
