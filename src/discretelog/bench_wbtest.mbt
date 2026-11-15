///|
fn benchmark_problem(p : Int32, e : Int32, bound : Int32) -> Problem {
  let certificate = match p {
    65537 => log_prime_65537()
    998244353 => log_prime_998244353()
    _ => abort("benchmark prime")
  }
  let field = @primefield.from_prime(@primality.check(certificate).unwrap()).unwrap()
  let modulus = @primefield.modulus(field)
  let target = @modular.power(modulus, @oracle.binary(3), @oracle.binary(e))
  problem(field, @oracle.binary(3), target, @oracle.binary(bound)).unwrap()
}

///|
test "BSGS prime 65537 exponent 10000 bound 16384" (b : @bench.T) {
  let instance = benchmark_problem(65537, 10000, 16384)
  assert_eq(
    baby_step_giant_step(instance).map(exponent),
    Some(@oracle.binary(10000)),
  )
  b.bench(fn() { b.keep(baby_step_giant_step(instance)) })
}

///|
test "naive prime 65537 exponent 10000 bound 16384" (b : @bench.T) {
  let instance = benchmark_problem(65537, 10000, 16384)
  assert_eq(naive(instance).map(exponent), Some(@oracle.binary(10000)))
  b.bench(fn() { b.keep(naive(instance)) })
}

///|
test "BSGS prime 998244353 exponent 50000 bound 65536" (b : @bench.T) {
  let instance = benchmark_problem(998244353, 50000, 65536)
  assert_eq(
    baby_step_giant_step(instance).map(exponent),
    Some(@oracle.binary(50000)),
  )
  b.bench(fn() { b.keep(baby_step_giant_step(instance)) })
}

///|
test "naive prime 998244353 exponent 50000 bound 65536" (b : @bench.T) {
  let instance = benchmark_problem(998244353, 50000, 65536)
  assert_eq(naive(instance).map(exponent), Some(@oracle.binary(50000)))
  b.bench(fn() { b.keep(naive(instance)) })
}
