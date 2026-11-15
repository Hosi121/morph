///|
fn primitive_long() -> @binary.Binary {
  @binary.from_bits(
    @oracle.chain(
      Array::makei(2048, fn(i) { i == 2047 || (i * 17 + 3) % 11 < 6 }),
    ),
  )
}

///|
test "binary multiplication identity operands" (b : @bench.T) {
  let input = primitive_long()
  let zero = @binary.zero()
  let one = @binary.one()
  let two = @oracle.binary(2)
  b.bench(name="long times zero", fn() { b.keep(@binary.multiply(input, zero)) })
  b.bench(name="zero times long", fn() { b.keep(@binary.multiply(zero, input)) })
  b.bench(name="long times one", fn() { b.keep(@binary.multiply(input, one)) })
  b.bench(name="one times long", fn() { b.keep(@binary.multiply(one, input)) })
  b.bench(name="long times two", fn() { b.keep(@binary.multiply(input, two)) })
  b.bench(name="two times long", fn() { b.keep(@binary.multiply(two, input)) })
}

///|
test "binary division and gcd identities" (b : @bench.T) {
  let input = primitive_long()
  let one = @binary.one()
  let zero = @binary.zero()
  b.bench(name="long divided by one", fn() {
    b.keep(@binary.divmod(input, one))
  })
  b.bench(name="long divided by itself", fn() {
    b.keep(@binary.divmod(input, input))
  })
  b.bench(name="small divided by long", fn() {
    b.keep(@binary.divmod(one, input))
  })
  b.bench(name="gcd long one", fn() { b.keep(@binary.gcd(input, one)) })
  b.bench(name="gcd long itself", fn() { b.keep(@binary.gcd(input, input)) })
  b.bench(name="gcd zero long", fn() { b.keep(@binary.gcd(zero, input)) })
}

///|
test "binary compare equal and different words" (b : @bench.T) {
  let input = primitive_long()
  let copy = @binary.from_bits(@binary.bits(input))
  let low_changed = @binary.add(input, @binary.one())
  let high_changed = @binary.double(input)
  b.bench(name="equal 2048 bits", fn() { b.keep(@binary.compare(input, copy)) })
  b.bench(name="changed low bits", fn() {
    b.keep(@binary.compare(input, low_changed))
  })
  b.bench(name="different width", fn() {
    b.keep(@binary.compare(input, high_changed))
  })
}
