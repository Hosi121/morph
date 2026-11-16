///|
// Frozen integration contract for the public wrapper, which the root owns.
fn protected_nat_binary(n : @core.Nat) -> Binary {
  match n {
    Zero => zero()
    Succ(Zero) => one()
    _ => from_nat_grouped(n)
  }
}

///|
test "grouped unary quotient and low bits match integer division" {
  for value in 0..<=4096 {
    let (q, b0, b1, b2) = split_nat_grouped(@oracle.nat(value))
    assert_eq(@oracle.int_of_nat(q), value / 8)
    assert_eq(b0, value % 2 == 1)
    assert_eq(b1, value / 2 % 2 == 1)
    assert_eq(b2, value / 4 % 2 == 1)
  }
}

///|
test "grouped unary conversion preserves canonical Binary at radix boundaries" {
  for
    value in [
      0, 1, 7, 8, 9, 63, 64, 65, 511, 512, 513, 4095, 4096, 4097, 32767, 32768, 32769,
      200001,
    ] {
    let expected = @oracle.binary(value)
    assert_eq(from_nat_grouped(@oracle.nat(value)), expected)
    assert_eq(protected_nat_binary(@oracle.nat(value)), expected)
  }
}

///|
test "fixed shared binary converter compared with grouped production helper" (
  b : @bench.T,
) {
  for value in [0, 1, 64, 4096, 100000] {
    let n = @oracle.nat(value)
    b.bench(name="binary shared \{value}", fn() { b.keep(shared_nat_binary(n)) })
    b.bench(name="grouped production \{value}", fn() {
      b.keep(protected_nat_binary(n))
    })
  }
}

///|
test "hot unary values in batches to lengthen short timer samples" (
  b : @bench.T,
) {
  for value in [0, 1] {
    let n = @oracle.nat(value)
    b.bench(name="binary hot batch \{value}", fn() {
      for _ in 0..<128 {
        b.keep(shared_nat_binary(n))
      }
    })
    b.bench(name="grouped hot batch \{value}", fn() {
      for _ in 0..<128 {
        b.keep(protected_nat_binary(n))
      }
    })
  }
}
