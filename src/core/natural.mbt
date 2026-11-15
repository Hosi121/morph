///|
/// Structural division by two. The Boolean is the remainder, without a binary numeral.
pub fn halve_nat(n : Nat) -> (Nat, Bool) {
  fn walk(rest : Nat, quotient : Nat) -> (Nat, Bool) {
    match rest {
      Zero => (quotient, false)
      Succ(Zero) => (quotient, true)
      Succ(Succ(tail)) => walk(tail, Succ(quotient))
    }
  }
  walk(n, Zero)
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
