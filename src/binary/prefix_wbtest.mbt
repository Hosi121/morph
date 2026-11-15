///|
test "large pairing prefix does not consume call stack" {
  let exponent = @oracle.nat(100000)
  let code = pair(exponent, @oracle.binary(5))
  match unpair(code) {
    None => fail("positive code must decode")
    Some((decoded, value)) => {
      assert_eq(@core.compare(exponent, decoded), @core.Equal)
      assert_eq(value, @oracle.binary(5))
    }
  }
}
