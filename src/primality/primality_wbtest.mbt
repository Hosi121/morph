///|
fn trial_prime(n : Int32) -> Bool {
  n >= 2 && ![ for d in 2..<n => n % d == 0 ].contains(true)
}

///|
test "certificate coverage agrees with independent trial division and old API" {
  for n in 0..<128 {
    let expected = trial_prime(n)
    assert_eq(@modular.is_prime(@oracle.binary(n)), expected)
    match fixture(n) {
      None => assert_false(expected)
      Some(certificate) => {
        assert_eq(candidate(certificate), @oracle.binary(n))
        assert_eq(check(certificate).map(value), Some(@oracle.binary(n)))
        assert_true(expected)
      }
    }
  }
}

///|
test "complete true factors cannot certify small composites with any witness" {
  for n in 2..<128 {
    if !trial_prime(n) {
      for a in 0..<n {
        assert_eq(
          check(
            Lucas(@oracle.binary(n), @oracle.binary(a), predecessor_factors(n)),
          ),
          None,
        )
      }
    }
  }
}

///|
test "missing excess nondividing and composite child factors are rejected" {
  let p = @oracle.binary(7)
  let a = @oracle.binary(3)
  let two = cert_2()
  let three = cert_3()
  let good : @core.Chain[Certificate] = Cons(two, Cons(three, Nil))
  assert_eq(check(Lucas(p, a, good)).map(value), Some(p))
  assert_eq(check(Lucas(p, a, Nil)), None)
  assert_eq(check(Lucas(p, a, Cons(two, Nil))), None)
  assert_eq(check(Lucas(p, a, Cons(two, good))), None)
  assert_eq(check(Lucas(p, a, Cons(cert_5(), Nil))), None)
  let fake_six = Lucas(
    @oracle.binary(6),
    @oracle.binary(5),
    Cons(cert_5(), Nil),
  )
  assert_eq(check(Lucas(p, a, Cons(fake_six, Nil))), None)
  let fake_three = Lucas(@oracle.binary(3), @oracle.binary(1), Cons(two, Nil))
  assert_eq(check(Lucas(p, a, Cons(two, Cons(fake_three, Nil)))), None)
}

///|
test "invalid candidate and wrong witnesses are rejected while multiplicities matter" {
  for n in 0..<2 {
    assert_eq(check(Lucas(@oracle.binary(n), @oracle.binary(1), Nil)), None)
  }
  let factors : @core.Chain[Certificate] = Cons(cert_2(), Cons(cert_2(), Nil))
  assert_eq(
    check(Lucas(@oracle.binary(5), @oracle.binary(2), factors)).map(value),
    Some(@oracle.binary(5)),
  )
  assert_eq(check(Lucas(@oracle.binary(5), @oracle.binary(1), factors)), None)
  assert_eq(check(Lucas(@oracle.binary(5), @oracle.binary(0), factors)), None)
  assert_eq(check(Lucas(@oracle.binary(5), @oracle.binary(5), factors)), None)
  assert_eq(check(Lucas(@oracle.binary(5), @oracle.binary(4), factors)), None)
  assert_eq(
    check(Lucas(@oracle.binary(5), @oracle.binary(2), Cons(cert_2(), Nil))),
    None,
  )
}
