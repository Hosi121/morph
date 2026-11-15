///|
test "halving conversion agrees with independent repeated-increment conversion" {
  for value in 0..<=2048 {
    let unary = fuel(value)
    assert_eq(binary_key(unary), @binary.from_nat(unary))
    let (half, odd) = halve_nat(unary)
    assert_eq(@oracle.int_of_nat(half), value / 2)
    assert_eq(odd, value % 2 == 1)
  }
  for value in [4095, 4096, 4097, 10000, 16384] {
    assert_eq(binary_key(fuel(value)), @oracle.binary(value))
  }
}

///|
test "normalized binary structural equality agrees with ordering for all small key pairs" {
  for left in 0..<256 {
    for right in 0..<256 {
      let a = @oracle.binary(left)
      let b = @oracle.binary(right)
      assert_eq(a.equal(b), @binary.compare(a, b) is Equal)
    }
  }
}
