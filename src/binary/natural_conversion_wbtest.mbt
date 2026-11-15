///|
test "tail conversion and shared successor agree with integer values" {
  let mut unary = @core.Zero
  for value in 0..<=4096 {
    assert_eq(from_nat(unary), @oracle.binary(value))
    assert_eq(successor(@oracle.binary(value)), @oracle.binary(value + 1))
    unary = @core.Succ(unary)
  }
  for value in [8191, 8192, 20000, 65535, 100000] {
    assert_eq(from_nat(@oracle.nat(value)), @oracle.binary(value))
    assert_eq(@oracle.int_of_nat(to_nat(from_nat(@oracle.nat(value)))), value)
  }
}

///|
test "dedicated increment preserves suffix values and all carry lengths" {
  for width in 0..<=1024 {
    if width > 32 && width % 31 != 0 {
      continue
    }
    let power = power(@oracle.binary(2), @oracle.binary(width))
    let below = subtract(power, one()).unwrap()
    assert_eq(successor(below), power)
    assert_eq(successor(power), add(power, one()))
  }
}
