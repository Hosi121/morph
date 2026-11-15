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
