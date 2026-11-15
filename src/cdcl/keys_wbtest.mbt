///|
/// Structural division by a pair of successors. The accumulator stores the
/// unary quotient, and the Bool is the remainder.
fn prototype_halve_nat(value : @core.Nat) -> (@core.Nat, Bool) {
  fn visit(value : @core.Nat, quotient : @core.Nat) -> (@core.Nat, Bool) {
    match value {
      Zero => (quotient, false)
      Succ(Zero) => (quotient, true)
      Succ(Succ(rest)) => visit(rest, Succ(quotient))
    }
  }
  visit(value, Zero)
}

///|
fn prototype_nat_bits(value : @core.Nat) -> @core.Chain[Bool] {
  match value {
    Zero => Nil
    Succ(_) => {
      let (half, low) = prototype_halve_nat(value)
      Cons(low, prototype_nat_bits(half))
    }
  }
}

///|
fn prototype_binary_key(value : @core.Nat) -> @binary.Binary {
  @binary.from_bits(prototype_nat_bits(value))
}

///|
test "shared key conversion agrees with halving prototype and numeric oracle" {
  for value in 0..<=2048 {
    let unary = fuel(value)
    assert_eq(binary_key(unary), @oracle.binary(value))
    assert_eq(prototype_binary_key(unary), @oracle.binary(value))
    let (half, odd) = prototype_halve_nat(unary)
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
