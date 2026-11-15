///|
/// Structural division by two. The Boolean is the remainder, without a binary numeral.
pub fn halve_nat(n : Nat) -> (Nat, Bool) {
  fn walk(fast : Nat, slow : Nat) -> (Nat, Bool) {
    match (fast, slow) {
      (Zero, _) => (slow, false)
      (Succ(Zero), Succ(tail)) => (tail, true)
      (Succ(Succ(rest)), Succ(tail)) => walk(rest, tail)
      // Initially fast=slow, and consuming two/one preserves fast <= slow.
      // Thus a positive fast with zero slow is unreachable.
      _ => (Zero, false)
    }
  }
  walk(n, n)
}

///|
pub fn half_nat(n : Nat) -> Nat {
  let (quotient, _) = halve_nat(n)
  quotient
}

///|
pub fn is_power_of_two_nat(n : Nat) -> Bool {
  match n {
    Zero => false
    Succ(Zero) => true
    Succ(Succ(_)) => {
      let (quotient, odd) = halve_nat(n)
      match odd {
        true => false
        false => is_power_of_two_nat(quotient)
      }
    }
  }
}
