///|
test "Nat to Binary 4096, input construction excluded" (b : @bench.T) {
  let input = @oracle.nat(4096)
  b.bench(fn() { b.keep(@binary.from_nat(input)) })
}

///|
test "successor of an even 2048-bit value" (b : @bench.T) {
  let input = @binary.power(@oracle.binary(2), @oracle.binary(2047))
  b.bench(fn() { b.keep(@binary.successor(input)) })
}

///|
test "successor of 2048 low one bits" (b : @bench.T) {
  let input = @binary.subtract(
    @binary.power(@oracle.binary(2), @oracle.binary(2048)),
    @binary.one(),
  ).unwrap()
  b.bench(fn() { b.keep(@binary.successor(input)) })
}
