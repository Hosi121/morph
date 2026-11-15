///|
test "primefield 65537 exact trial construction" (b : @bench.T) {
  let n = @oracle.binary(65537)
  b.bench(fn() { b.keep(field(n)) })
}

///|
test "primefield 65537 from previously checked Prime" (b : @bench.T) {
  let prime = @primality.check(certificate(65537)).unwrap()
  b.bench(fn() { b.keep(from_prime(prime)) })
}

///|
test "primefield 65537 including Lucas check from supplied certificate" (
  b : @bench.T,
) {
  let certificate = certificate(65537)
  b.bench(fn() {
    b.keep(
      match @primality.check(certificate) {
        None => None
        Some(prime) => from_prime(prime)
      },
    )
  })
}

///|
test "primefield 998244353 exact trial construction" (b : @bench.T) {
  let n = @oracle.binary(998244353)
  b.bench(fn() { b.keep(field(n)) })
}

///|
test "primefield 998244353 from previously checked Prime" (b : @bench.T) {
  let prime = @primality.check(certificate(998244353)).unwrap()
  b.bench(fn() { b.keep(from_prime(prime)) })
}

///|
test "primefield 998244353 including Lucas check from supplied certificate" (
  b : @bench.T,
) {
  let certificate = certificate(998244353)
  b.bench(fn() {
    b.keep(
      match @primality.check(certificate) {
        None => None
        Some(prime) => from_prime(prime)
      },
    )
  })
}
