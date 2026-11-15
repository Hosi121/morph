///|
fn small_gcd(a : Int32, b : Int32) -> Int32 {
  let mut x = a.abs()
  let mut y = b.abs()
  while y != 0 {
    let remainder = x % y
    x = y
    y = remainder
  }
  x
}

///|
test "partial-factor Pocklington agrees with independent integer conditions" {
  for n in 2..<128 {
    let full = @oracle.array(predecessor_factors(n))
    for count in 0..<=full.length() {
      let prefix = [ for i in 0..<count => full[i] ]
      let values = prefix.map(fn(c) { @oracle.int_of_binary(candidate(c)) })
      let mut product = 1
      for q in values {
        product = product * q
      }
      for a in 0..<n {
        let expected = n > 2 &&
          n % 2 == 1 &&
          product * product > n &&
          integer_power(a, n - 1, n) == 1 &&
          values.all(fn(q) {
            small_gcd(integer_power(a, (n - 1) / q, n) - 1, n) == 1
          })
        match
          check_pocklington(
            @oracle.binary(n),
            @oracle.binary(a),
            @oracle.chain(prefix),
          ) {
          None => assert_false(expected)
          Some(prime) => {
            assert_true(expected)
            assert_true(trial_prime(n))
            assert_eq(value(prime), @oracle.binary(n))
          }
        }
      }
    }
  }
}

///|
test "partial factors can prove a prime while incomplete Lucas trees fail" {
  let n = @oracle.binary(65537)
  let witness = @oracle.binary(3)
  let factors = @core.replicate(@oracle.nat(9), Two)
  assert_eq(check(Lucas(n, witness, factors)), None)
  assert_eq(check_pocklington(n, witness, factors).map(value), Some(n))
  assert_eq(
    check_pocklington(n, witness, @core.replicate(@oracle.nat(8), Two)),
    None,
  )
  assert_eq(check_pocklington(n, @oracle.binary(1), factors), None)
  assert_eq(check_pocklington(n, @oracle.binary(0), factors), None)
  assert_eq(check_pocklington(n, witness, Cons(cert_3(), factors)), None)
  let fake_two = Lucas(@oracle.binary(2), @oracle.binary(0), Nil)
  assert_eq(check_pocklington(n, witness, Cons(fake_two, factors)), None)
  assert_eq(
    check_pocklington(n, witness, @core.replicate(@oracle.nat(17), Two)),
    None,
  )
}

///|
test "large partial factor proof uses gcd conditions instead of mere inequality" {
  let n = @oracle.binary(998244353)
  let factors = @core.replicate(@oracle.nat(15), Two)
  assert_eq(
    check_pocklington(n, @oracle.binary(3), factors).map(value),
    Some(n),
  )
  assert_eq(
    check_pocklington(
      n,
      @oracle.binary(3),
      @core.replicate(@oracle.nat(14), Two),
    ),
    None,
  )
  // 561 is Carmichael. A full-size partial factor and Fermat congruence alone
  // must not turn a nonunit order condition into a false primality proof.
  let composite = @oracle.binary(561)
  let partial = @core.append(
    @core.replicate(@oracle.nat(4), Two),
    Cons(cert_5(), Nil),
  )
  let modulus = @modular.modulus(composite).unwrap()
  let base = @oracle.binary(5)
  assert_eq(@modular.power(modulus, base, @oracle.binary(560)), @binary.one())
  assert_false(
    @modular.power(modulus, base, @oracle.binary(280)) == @binary.one(),
  )
  assert_false(
    @modular.power(modulus, base, @oracle.binary(112)) == @binary.one(),
  )
  assert_eq(check_pocklington(composite, @oracle.binary(5), partial), None)
}
