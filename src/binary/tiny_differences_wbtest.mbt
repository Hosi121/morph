///|
test "selected difference dispatch matches all byte values and underflows" {
  for a in 0..<256 {
    for b in 0..<256 {
      let expected = if a < b { None } else { Some(@oracle.binary(a - b)) }
      assert_eq(
        subtract_adaptively(@oracle.binary(a), @oracle.binary(b)),
        expected,
      )
    }
  }
  for width in [64, 127, 512, 2048] {
    let value = power(@oracle.binary(2), @oracle.binary(width))
    assert_eq(subtract_adaptively(value, value), Some(zero()))
    assert_eq(subtract_adaptively(value, zero()), Some(value))
    assert_eq(subtract_adaptively(zero(), value), None)
    assert_eq(subtract_adaptively(value, one()), subtract(value, one()))
    assert_eq(subtract_adaptively(one(), value), None)
  }
}
