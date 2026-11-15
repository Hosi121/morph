///|
test "addition with zero and a much shorter operand" (b : @bench.T) {
  let long = @binary.power(@oracle.binary(2), @oracle.binary(2047))
  let short = @oracle.binary(5)
  b.bench(name="2048-bit plus zero", fn() {
    b.keep(@binary.add(long, @binary.zero()))
  })
  b.bench(name="2048-bit plus 5", fn() { b.keep(@binary.add(long, short)) })
}

///|
test "addition through a long carry chain" (b : @bench.T) {
  let all = @binary.subtract(
    @binary.power(@oracle.binary(2), @oracle.binary(2048)),
    @binary.one(),
  ).unwrap()
  b.bench(fn() { b.keep(@binary.add(all, @binary.one())) })
}

///|
test "same-width dense 512-bit addition" (b : @bench.T) {
  let a = @binary.from_bits(
    @oracle.chain(Array::makei(512, fn(i) { i == 511 || i % 7 < 4 })),
  )
  let b_value = @binary.from_bits(
    @oracle.chain(Array::makei(512, fn(i) { i == 511 || i % 11 < 5 })),
  )
  b.bench(fn() { b.keep(@binary.add(a, b_value)) })
}
