///|
fn rebuilding_halve_nat(n : @core.Nat) -> (@core.Nat, Bool) {
  fn walk(rest : @core.Nat, quotient : @core.Nat) -> (@core.Nat, Bool) {
    match rest {
      Zero => (quotient, false)
      Succ(Zero) => (quotient, true)
      Succ(Succ(tail)) => walk(tail, Succ(quotient))
    }
  }
  walk(n, Zero)
}

///|
fn rebuilding_half_nat(n : @core.Nat) -> @core.Nat {
  let (half, _) = rebuilding_halve_nat(n)
  half
}

///|
fn rebuilding_nat_binary(n : @core.Nat) -> Binary {
  fn convert(n : @core.Nat) -> @core.Chain[Bool] {
    match n {
      Zero => Nil
      Succ(_) => {
        let (half, low) = rebuilding_halve_nat(n)
        Cons(low, convert(half))
      }
    }
  }
  { bits: convert(n), }
}

///|
fn shared_halve_nat(n : @core.Nat) -> (@core.Nat, Bool) {
  fn walk(fast : @core.Nat, slow : @core.Nat) -> (@core.Nat, Bool) {
    match (fast, slow) {
      (Zero, _) => (slow, false)
      (Succ(Zero), Succ(tail)) => (tail, true)
      (Succ(Succ(rest)), Succ(tail)) => walk(rest, tail)
      _ => (Zero, false)
    }
  }
  walk(n, n)
}

///|
fn shared_half_nat(n : @core.Nat) -> @core.Nat {
  fn walk(fast : @core.Nat, slow : @core.Nat) -> @core.Nat {
    match (fast, slow) {
      (Zero, _) => slow
      (Succ(Zero), Succ(tail)) => tail
      (Succ(Succ(rest)), Succ(tail)) => walk(rest, tail)
      _ => Zero
    }
  }
  walk(n, n)
}

///|
fn shared_nat_binary(n : @core.Nat) -> Binary {
  fn convert(n : @core.Nat) -> @core.Chain[Bool] {
    match n {
      Zero => Nil
      Succ(_) => {
        let (half, low) = shared_halve_nat(n)
        Cons(low, convert(half))
      }
    }
  }
  { bits: convert(n), }
}

///|
test "two-speed Nat traversal preserves the exact half and remainder" {
  for value in 0..<=4096 {
    let n = @oracle.nat(value)
    let (half, odd) = shared_halve_nat(n)
    assert_eq(@oracle.int_of_nat(half), value / 2)
    assert_eq(odd, value % 2 == 1)
    assert_eq(@oracle.int_of_nat(shared_half_nat(n)), value / 2)
    assert_eq(shared_nat_binary(n), @oracle.binary(value))
  }
}

///|
test "shared Nat tails compared with rebuilding the quotient" (b : @bench.T) {
  for value in [64, 4096, 100000] {
    let n = @oracle.nat(value)
    b.bench(name="rebuild half \{value}", fn() {
      b.keep(rebuilding_half_nat(n))
    })
    b.bench(name="shared tuple half \{value}", fn() {
      b.keep(@core.halve_nat(n))
    })
    b.bench(name="shared bare half \{value}", fn() {
      b.keep(shared_half_nat(n))
    })
    b.bench(name="rebuild from_nat \{value}", fn() {
      b.keep(rebuilding_nat_binary(n))
    })
    b.bench(name="shared from_nat \{value}", fn() { b.keep(from_nat(n)) })
  }
}
