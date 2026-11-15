///|
test "normal short and 128-bit division distribution" (b : @bench.T) {
  let pairs = Array::makei(64, fn(i) {
    (@oracle.binary(7 + i * 113), @oracle.binary(3 + i * 17 % 97))
  })
  b.bench(name="64 short divisions", fn() {
    for pair in pairs {
      b.keep(@binary.divmod(pair.0, pair.1))
    }
  })
  b.bench(name="64 short gcd", fn() {
    for pair in pairs {
      b.keep(@binary.gcd(pair.0, pair.1))
    }
  })
  let a = @oracle.binary_from_hex("d59b8c50c9174c3a71293ab167cd89ef")
  let divisor = @oracle.binary_from_hex("b1234567a789cf13")
  b.bench(name="128 by 64 bits", fn() { b.keep(@binary.divmod(a, divisor)) })
  b.bench(name="gcd 128 and 64 bits", fn() { b.keep(@binary.gcd(a, divisor)) })
}
