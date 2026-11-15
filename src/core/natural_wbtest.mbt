///|
fn half_test_int(n : Nat) -> Int32 {
  fn walk(n : Nat, count : Int32) -> Int32 {
    match n {
      Zero => count
      Succ(rest) => walk(rest, count + 1)
    }
  }
  walk(n, 0)
}

///|
test "Nat halving and power-of-two checks use direct unary structure" {
  let mut n = Zero
  for value in 0..<=4096 {
    let (half, odd) = halve_nat(n)
    assert_eq(half_test_int(half), value / 2)
    assert_eq(odd, value % 2 == 1)
    assert_eq(compare(half_nat(n), half), Equal)
    assert_eq(is_power_of_two_nat(n), value > 0 && (value & (value - 1)) == 0)
    n = Succ(n)
  }
  let mut big = Zero
  for _ in 0..<200001 {
    big = Succ(big)
  }
  let (half, odd) = halve_nat(big)
  assert_eq(half_test_int(half), 100000)
  assert_true(odd)
}
