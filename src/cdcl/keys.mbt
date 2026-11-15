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
