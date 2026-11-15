///|
test "Lucas certificate check 65537 excluding certificate construction" (
  b : @bench.T,
) {
  let certificate = cert_65537()
  b.bench(fn() { b.keep(check(certificate)) })
}

///|
test "trial division 65537 excluding input construction" (b : @bench.T) {
  let n = @oracle.binary(65537)
  b.bench(fn() { b.keep(@modular.is_prime(n)) })
}

///|
test "Lucas certificate check 998244353 excluding certificate construction" (
  b : @bench.T,
) {
  let certificate = cert_998244353()
  b.bench(fn() { b.keep(check(certificate)) })
}

///|
test "trial division 998244353 excluding input construction" (b : @bench.T) {
  let n = @oracle.binary(998244353)
  b.bench(fn() { b.keep(@modular.is_prime(n)) })
}

///|
test "composite screen 1373653 bases two three five" (b : @bench.T) {
  let n = @oracle.binary(1373653)
  let bases = @oracle.chain([2, 3, 5].map(@oracle.binary))
  b.bench(fn() { b.keep(screen(n, bases)) })
}

///|
test "trial composite decision 1373653 excluding input construction" (
  b : @bench.T,
) {
  let n = @oracle.binary(1373653)
  b.bench(fn() { b.keep(@modular.is_prime(n)) })
}

///|
test "composite screen 100160063 base two" (b : @bench.T) {
  let n = @oracle.binary(100160063)
  let bases : @core.Chain[@binary.Binary] = Cons(@oracle.binary(2), Nil)
  b.bench(fn() { b.keep(screen(n, bases)) })
}

///|
test "trial composite decision 100160063 excluding input construction" (
  b : @bench.T,
) {
  let n = @oracle.binary(100160063)
  b.bench(fn() { b.keep(@modular.is_prime(n)) })
}

///|
test "Pocklington 998244353 partial factor two to fifteen" (b : @bench.T) {
  let n = @oracle.binary(998244353)
  let witness = @oracle.binary(3)
  let factors = @core.replicate(@oracle.nat(15), Two)
  b.bench(fn() { b.keep(check_pocklington(n, witness, factors)) })
}
