///|
test "run arithmetic versus bit lists on a long homogeneous block" (
  b : @bench.T,
) {
  let ordinary = @binary.subtract(
    @binary.power(@oracle.binary(2), @oracle.binary(2048)),
    @binary.one(),
  ).unwrap()
  let compressed = from_binary(ordinary)
  b.bench(name="bits add one", fn() {
    b.keep(@binary.add(ordinary, @binary.one()))
  })
  b.bench(name="runs add one", fn() { b.keep(add(compressed, one())) })
  b.bench(name="bits school square", fn() {
    b.keep(@binary.multiply(ordinary, ordinary))
  })
  b.bench(name="bits Karatsuba square", fn() {
    b.keep(@binary.karatsuba(ordinary, ordinary))
  })
  b.bench(name="runs square", fn() { b.keep(multiply(compressed, compressed)) })
}

///|
test "run arithmetic versus bit lists on alternating inputs" (b : @bench.T) {
  let a = @binary.from_bits(
    @oracle.chain(Array::makei(256, fn(i) { i == 255 || i % 2 == 0 })),
  )
  let other = @binary.from_bits(
    @oracle.chain(Array::makei(256, fn(i) { i == 255 || i % 5 < 2 })),
  )
  let ca = from_binary(a)
  let cb = from_binary(other)
  b.bench(name="bits add", fn() { b.keep(@binary.add(a, other)) })
  b.bench(name="runs add", fn() { b.keep(add(ca, cb)) })
  b.bench(name="bits multiply", fn() { b.keep(@binary.multiply(a, other)) })
  b.bench(name="runs multiply", fn() { b.keep(multiply(ca, cb)) })
}

///|
test "square a block whose length is two to the thousandth" (b : @bench.T) {
  let exponent = @binary.power(@oracle.binary(2), @oracle.binary(1000))
  let value = from_runs(@core.Cons({ bit: true, length: exponent, }, Nil))
  b.bench(fn() { b.keep(multiply(value, value)) })
}
