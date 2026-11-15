///|
fn small_prime(p : Int32) -> @primality.Certificate {
  match p {
    2 => Two
    3 => Lucas(@oracle.binary(3), @oracle.binary(2), Cons(small_prime(2), Nil))
    5 =>
      Lucas(
        @oracle.binary(5),
        @oracle.binary(2),
        Cons(small_prime(2), Cons(small_prime(2), Nil)),
      )
    7 =>
      Lucas(
        @oracle.binary(7),
        @oracle.binary(3),
        Cons(small_prime(2), Cons(small_prime(3), Nil)),
      )
    _ => abort("small test prime")
  }
}

///|
test "complete factorization preserves all prime multiplicities and checks the product" {
  for factors in [[2], [2, 2], [2, 3], [3, 5, 7], [2, 3, 2, 5, 7, 2]] {
    let mut n = 1
    for p in factors {
      n = n * p
    }
    let certificates = @oracle.chain(factors.map(small_prime))
    let factorization = check_factorization(@oracle.binary(n), certificates).unwrap()
    assert_eq(factorization_value(factorization), @oracle.binary(n))
    assert_eq(
      @oracle.array(
        @core.map(prime_factors(factorization), fn(p) {
          @oracle.int_of_binary(@primality.value(p))
        }),
      ),
      factors,
    )
  }
}

///|
test "one has an empty factorization and zero has none" {
  let unit = check_factorization(@oracle.binary(1), Nil).unwrap()
  assert_eq(prime_factors(unit), Nil)
  assert_eq(factorization_value(unit), @oracle.binary(1))
  for n in 0..<128 {
    if n != 1 {
      assert_eq(check_factorization(@oracle.binary(n), Nil), None)
    }
  }
  assert_eq(
    check_factorization(@oracle.binary(0), Cons(small_prime(2), Nil)),
    None,
  )
}

///|
test "complete factorization rejects missing extra wrong and composite factors" {
  let number = @oracle.binary(12)
  let good = @oracle.chain([2, 2, 3].map(small_prime))
  assert_true(check_factorization(number, good) is Some(_))
  for factors in [[2, 3], [2, 2, 2, 3], [2, 2, 5], [3, 3]] {
    assert_eq(
      check_factorization(number, @oracle.chain(factors.map(small_prime))),
      None,
    )
  }
  let fake_six : @primality.Certificate = Lucas(
    @oracle.binary(6),
    @oracle.binary(5),
    Cons(small_prime(5), Nil),
  )
  assert_eq(
    check_factorization(number, Cons(small_prime(2), Cons(fake_six, Nil))),
    None,
  )
  let fake_two : @primality.Certificate = Lucas(
    @oracle.binary(2),
    @oracle.binary(0),
    Nil,
  )
  assert_eq(
    check_factorization(
      number,
      Cons(small_prime(2), Cons(fake_two, Cons(small_prime(3), Nil))),
    ),
    None,
  )
}
