///|
test "zero and unit division keep field and zero divisor error precedence" {
  for p in [2, 3, 5] {
    let field = test_field(p)
    let foreign = test_field(if p == 2 { 3 } else { 2 })
    let value = test_polynomial(p, [1, 2, 1])
    let empty = zero(field)
    assert_eq(divide(empty, empty), Err(ZeroDivisor))
    assert_eq(divide(empty, zero(foreign)), Err(FieldMismatch))
    assert_eq(divide(empty, one(foreign)), Err(FieldMismatch))
    assert_eq(divide(value, one(foreign)), Err(FieldMismatch))
    assert_eq(required(divide(value, one(field))), {
      quotient: value,
      remainder: empty,
    })
    assert_eq(required(divide(empty, value)), {
      quotient: empty,
      remainder: empty,
    })
  }
}
