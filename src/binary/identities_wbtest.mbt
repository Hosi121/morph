///|
test "identity dispatch preserves division by zero and exact boundary values" {
  assert_eq(divmod(zero(), zero()), None)
  assert_eq(divmod(one(), zero()), None)
  for value in 0..<4096 {
    let n = @oracle.binary(value)
    for factor in 0..<=3 {
      assert_eq(
        multiply(n, @oracle.binary(factor)),
        @oracle.binary(value * factor),
      )
      assert_eq(
        multiply(@oracle.binary(factor), n),
        @oracle.binary(value * factor),
      )
    }
    assert_eq(divmod(n, one()), Some((n, zero())))
    assert_eq(
      divmod(n, @oracle.binary(2)),
      Some((@oracle.binary(value / 2), @oracle.binary(value % 2))),
    )
    assert_eq(gcd(n, one()), one())
    assert_eq(gcd(one(), n), one())
    assert_eq(gcd(n, zero()), n)
    assert_eq(gcd(zero(), n), n)
    assert_eq(gcd(n, n), n)
    if value != 0 {
      assert_eq(divmod(n, n), Some((one(), zero())))
    }
  }
}

///|
test "identities share semantic values for independently constructed large words" {
  let raw = @oracle.chain(Array::makei(4096, fn(i) { i == 4095 || i % 7 < 4 }))
  let a = from_bits(raw)
  let b = from_bits(@core.append(raw, @core.Cons(false, Nil)))
  assert_eq(compare(a, b), @core.Equal)
  assert_eq(divmod(a, b), Some((one(), zero())))
  assert_eq(gcd(a, b), a)
  assert_eq(multiply(a, one()), a)
  assert_eq(multiply(one(), a), a)
  assert_eq(multiply(a, @oracle.binary(2)), double(a))
  assert_eq(multiply(@oracle.binary(2), a), double(a))
  assert_eq(divmod(a, @oracle.binary(2)), Some((half(a), one())))
  assert_eq(divmod(@oracle.binary(3), a), Some((zero(), @oracle.binary(3))))
}
