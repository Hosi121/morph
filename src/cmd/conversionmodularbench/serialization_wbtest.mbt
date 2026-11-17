///|
test "modular benchmark serializes complete arbitrary-width numbers" {
  for n in 0..<=1024 {
    let value = @oracle.binary(n)
    let text = binary_json(value)
    assert_eq(
      @oracle.binary_from_hex(text[1:text.length() - 1].to_owned()),
      value,
    )
  }
  for
    hex in [
      "1", "8", "10", "10001", "123456789abcdef", "100000000000000000000000000000000000000000000000011",
    ] {
    assert_eq(binary_json(@oracle.binary_from_hex(hex)), "\"" + hex + "\"")
  }
}
