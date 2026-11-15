///|
test "shared addition suffixes retain exact canonical values" {
  for a in 0..<256 {
    for b in 0..<256 {
      assert_eq(
        add(@oracle.binary(a), @oracle.binary(b)),
        @oracle.binary(a + b),
      )
    }
  }
  for width in [32, 63, 128, 512, 2048] {
    let high = power(@oracle.binary(2), @oracle.binary(width))
    for low in 0..<32 {
      let expected = @oracle.chain(
        Array::makei(width + 1, fn(index) {
          index == width || (index < 5 && ((low >> index) & 1) != 0)
        }),
      )
      assert_eq(bits(add(high, @oracle.binary(low))), expected)
      assert_eq(bits(add(@oracle.binary(low), high)), expected)
    }
    let all = subtract(high, one()).unwrap()
    assert_eq(add(all, one()), high)
    assert_eq(add(zero(), high), high)
  }
}
