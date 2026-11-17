///|
test "benchmark integer JSON hex round trips every small value and long bit lengths" {
  for n in 0..<=1024 {
    let value = @oracle.binary(n)
    assert_eq(@oracle.binary_from_hex(binary_hex(value)), value)
  }
  for
    text in [
      "1", "8", "10", "123456789abcdef", "100000000000000000000000000000000000000000000000011",
    ] {
    let value = @oracle.binary_from_hex(text)
    assert_eq(binary_hex(value), text)
    assert_eq(@oracle.binary_from_hex(binary_hex(value)), value)
  }
  assert_eq(binary_hex(@binary.zero()), "0")
  assert_eq(rational_json(q(-1, 3)), "[true,\"1\",\"3\"]")
  assert_eq(rational_json(q(0, 1)), "[false,\"0\",\"1\"]")
}
