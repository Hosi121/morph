///|
test "test natural adapters do not spend call stack proportional to value" {
  for value in [0, 1, 8192, 20000, 65535, 100000] {
    assert_eq(int_of_nat(nat(value)), value)
  }
}
