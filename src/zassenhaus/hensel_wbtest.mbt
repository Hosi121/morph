///|
fn test_polynomial(values : Array[Int32]) -> Polynomial {
  polynomial(@oracle.chain(values.map(@oracle.integer)))
}

///|
fn test_native(value : Polynomial) -> Array[Int32] {
  @oracle.array(coefficients(value)).map(@oracle.int_of_integer)
}

///|
fn test_fp(prime : Int32, values : Array[Int32]) -> @fppoly.Polynomial {
  @fppoly.polynomial(
    @primefield.field(@oracle.binary(prime)).unwrap(),
    @oracle.chain(values.map(@oracle.binary)),
  )
}

///|
fn assert_lift_fixture(
  input : Array[Int32],
  prime : Int32,
  exponent : Int32,
  factors : Array[Array[Int32]],
  expected : Array[Array[Int32]],
) -> Unit raise {
  let initial = start_lift(
    test_polynomial(input),
    @oracle.chain(factors.map(fn(f) { test_fp(prime, f) })),
  ).unwrap()
  assert_true(check_lift(lift_certificate(initial)))
  let lifted = for state = initial, k = 1; k < exponent; {
    let next = lift_step(state).unwrap()
    assert_true(check_lift(lift_certificate(next)))
    assert_eq(@oracle.int_of_nat(lift_certificate(next).exponent), k + 1)
    continue next, k + 1
  } nobreak {
    state
  }
  let actual = @oracle.array(lift_certificate(lifted).lifts).map(test_native)
  assert_eq(actual, expected)
  let certificate = lift_certificate(lifted)
  assert_false(
    check_lift({
      target: certificate.target,
      prime: certificate.prime,
      exponent: Zero,
      factors: certificate.factors,
      lifts: certificate.lifts,
    }),
  )
  assert_false(
    check_lift({
      target: add(certificate.target, one()),
      prime: certificate.prime,
      exponent: certificate.exponent,
      factors: certificate.factors,
      lifts: certificate.lifts,
    }),
  )
  assert_false(
    check_lift({
      target: certificate.target,
      prime: @oracle.binary(prime * prime),
      exponent: certificate.exponent,
      factors: certificate.factors,
      lifts: certificate.lifts,
    }),
  )
  assert_false(
    check_lift({
      target: certificate.target,
      prime: certificate.prime,
      exponent: certificate.exponent,
      factors: certificate.factors,
      lifts: Nil,
    }),
  )
}

///|
test "invalid modular seeds and degree-losing primes are rejected" {
  assert_eq(
    start_lift(test_polynomial([1, 2]), Cons(test_fp(2, [1]), Nil)),
    Err(InvalidLift),
  )
  let duplicate = test_fp(3, [1, 1])
  assert_eq(
    start_lift(
      test_polynomial([1, 2, 1]),
      Cons(duplicate, Cons(duplicate, Nil)),
    ),
    Err(InvalidLift),
  )
  assert_eq(
    start_lift(
      test_polynomial([-1, 0, 1]),
      Cons(test_fp(3, [1, 1]), Cons(test_fp(5, [4, 1]), Nil)),
    ),
    Err(InvalidLift),
  )
  assert_eq(start_lift(zero(), Nil), Err(InvalidLift))
}

///|
test "lifting fuel suspends and resume preserves exact prime powers" {
  let initial = start_lift(
    test_polynomial([-1, 0, 1]),
    Cons(test_fp(3, [1, 1]), Cons(test_fp(3, [2, 1]), Nil)),
  ).unwrap()
  let threshold = @oracle.binary(80)
  assert_eq(lift_above(initial, threshold, Zero).unwrap(), Suspended(initial))
  match lift_above(initial, threshold, @oracle.nat(3)).unwrap() {
    Reached(completed) => {
      assert_eq(@oracle.int_of_binary(lift_modulus(completed)), 81)
      assert_true(check_lift(lift_certificate(completed)))
    }
    _ => fail("must reach 3^4")
  }
}

///|
test "lift certificates reject noncanonical residues and altered degrees" {
  let initial = start_lift(
    test_polynomial([-1, 0, 1]),
    Cons(test_fp(3, [1, 1]), Cons(test_fp(3, [2, 1]), Nil)),
  ).unwrap()
  let certificate = lift_certificate(lift_step(initial).unwrap())
  let lifts = @oracle.array(certificate.lifts)
  let modulus = @oracle.int_of_binary(lift_modulus(lift_step(initial).unwrap()))
  let noncanonical = add(lifts[0], test_polynomial([modulus]))
  assert_false(
    check_lift({
      target: certificate.target,
      prime: certificate.prime,
      exponent: certificate.exponent,
      factors: certificate.factors,
      lifts: Cons(noncanonical, Cons(lifts[1], Nil)),
    }),
  )
  let nonmonic = scale(lifts[0], @oracle.integer(2))
  assert_false(
    check_lift({
      target: certificate.target,
      prime: certificate.prime,
      exponent: certificate.exponent,
      factors: certificate.factors,
      lifts: Cons(nonmonic, Cons(lifts[1], Nil)),
    }),
  )
  let extra_degree = add(lifts[0], test_polynomial([0, 0, modulus]))
  assert_false(
    check_lift({
      target: certificate.target,
      prime: certificate.prime,
      exponent: certificate.exponent,
      factors: certificate.factors,
      lifts: Cons(extra_degree, Cons(lifts[1], Nil)),
    }),
  )
  let missing = @core.Cons(test_fp(3, [1, 1]), @core.Nil)
  assert_eq(start_lift(certificate.target, missing), Err(InvalidLift))
}

///|
test "standalone binary Hensel supports reducible but coprime modular blocks" {
  let target = test_polynomial([2, 0, 3, 0, 1])
  let initial = start_lift(
    target,
    Cons(test_fp(7, [1, 0, 1]), Cons(test_fp(7, [2, 0, 1]), Nil)),
  ).unwrap()
  let state = lift_step(lift_step(initial).unwrap()).unwrap()
  assert_true(check_lift(lift_certificate(state)))
  assert_eq(@oracle.array(lift_certificate(state).lifts).map(test_native), [
    [1, 0, 1],
    [2, 0, 1],
  ])
}
