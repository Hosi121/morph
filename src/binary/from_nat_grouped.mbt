///|
/// The result is the shared unary quotient followed by its three low bits.
/// fast consumes eight Succs while slow consumes seven; both start at n.
fn split_nat_grouped(n : @core.Nat) -> (@core.Nat, Bool, Bool, Bool) {
  fn walk(fast : @core.Nat, slow : @core.Nat) -> (@core.Nat, Bool, Bool, Bool) {
    match (fast, slow) {
      (Zero, tail) => (tail, false, false, false)
      (Succ(Zero), Succ(tail)) => (tail, true, false, false)
      (Succ(Succ(Zero)), Succ(Succ(tail))) => (tail, false, true, false)
      (Succ(Succ(Succ(Zero))), Succ(Succ(Succ(tail)))) =>
        (tail, true, true, false)
      (Succ(Succ(Succ(Succ(Zero)))), Succ(Succ(Succ(Succ(tail))))) =>
        (tail, false, false, true)
      (Succ(Succ(Succ(Succ(Succ(Zero))))), Succ(Succ(Succ(Succ(Succ(tail)))))) =>
        (tail, true, false, true)
      (
        Succ(Succ(Succ(Succ(Succ(Succ(Zero)))))),
        Succ(Succ(Succ(Succ(Succ(Succ(tail)))))),
      ) => (tail, false, true, true)
      (
        Succ(Succ(Succ(Succ(Succ(Succ(Succ(Zero))))))),
        Succ(Succ(Succ(Succ(Succ(Succ(Succ(tail))))))),
      ) => (tail, true, true, true)
      (
        Succ(Succ(Succ(Succ(Succ(Succ(Succ(Succ(rest)))))))),
        Succ(Succ(Succ(Succ(Succ(Succ(Succ(tail))))))),
      ) => walk(rest, tail)
      _ => (Zero, false, false, false)
    }
  }
  walk(n, n)
}

///|
/// Emit three bits per unary scan; low_bit removes only redundant high zeros.
fn from_nat_grouped(n : @core.Nat) -> Binary {
  fn convert(n : @core.Nat) -> @core.Chain[Bool] {
    match n {
      Zero => Nil
      Succ(_) => {
        let (q, b0, b1, b2) = split_nat_grouped(n)
        low_bit(b0, low_bit(b1, low_bit(b2, convert(q))))
      }
    }
  }
  { bits: convert(n), }
}
