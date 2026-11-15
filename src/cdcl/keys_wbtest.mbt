///|
/// Structural division by a pair of successors. The accumulator stores the
/// unary quotient, and the Bool is the remainder.
fn halve_nat(value : @core.Nat) -> (@core.Nat, Bool) {
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
fn nat_bits(value : @core.Nat) -> @core.Chain[Bool] {
  match value {
    Zero => Nil
    Succ(_) => {
      let (half, low) = halve_nat(value)
      Cons(low, nat_bits(half))
    }
  }
}

///|
fn binary_key(value : @core.Nat) -> @binary.Binary {
  @binary.from_bits(nat_bits(value))
}

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
