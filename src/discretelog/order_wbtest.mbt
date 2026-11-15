///|
fn factored(n : Int32) -> @factor.Factorization {
  let mut rest = n
  let certificates : Array[@primality.Certificate] = []
  for q in 2..<=n {
    while rest % q == 0 {
      certificates.push(
        match q {
          2 => log_prime_2()
          3 => log_prime_3()
          5 => log_prime_5()
          7 => log_prime_7()
          11 => log_prime_11()
          13 => log_prime_13()
          17 => log_prime_17()
          _ => abort("small order factor")
        },
      )
      rest = rest / q
    }
  }
  @factor.check_factorization(@oracle.binary(n), @oracle.chain(certificates)).unwrap()
}

///|
test "exact multiplicative order certificates match all small integer orders" {
  for p in [2, 3, 5, 7, 11, 13, 17, 19] {
    let f = @primefield.field(@oracle.binary(p)).unwrap()
    for g in 1..<p {
      let mut power = g % p
      let mut expected = 1
      while power != 1 {
        power = power * g % p
        expected = expected + 1
      }
      for d in 1..<p {
        let proof = exact_order(f, @oracle.binary(g), factored(d))
        match proof {
          None => assert_true(d != expected)
          Some(order) => {
            assert_eq(d, expected)
            assert_eq(order_value(order), @oracle.binary(expected))
            assert_eq(order_base(order), @oracle.binary(g))
            assert_eq(order_field(order), f)
            assert_eq(
              @factor.factorization_value(order_factorization(order)),
              @oracle.binary(expected),
            )
          }
        }
      }
    }
  }
}

///|
test "checked order distinguishes subgroup coverage from a user chosen smaller bound" {
  let f = @primefield.field(@oracle.binary(7)).unwrap()
  let order = exact_order(f, @oracle.binary(9), factored(3)).unwrap()
  assert_eq(order_base(order), @oracle.binary(2))
  let instance = subgroup_problem(order, @oracle.binary(4)).unwrap()
  assert_eq(limit(instance), @oracle.binary(3))
  assert_eq(
    baby_step_giant_step(instance).map(exponent),
    Some(@oracle.binary(2)),
  )
  assert_eq(
    baby_step_giant_step(subgroup_problem(order, @oracle.binary(3)).unwrap()),
    None,
  )
  assert_eq(exact_order(f, @oracle.binary(2), factored(6)), None)
  assert_eq(exact_order(f, @oracle.binary(1), factored(3)), None)
  assert_eq(exact_order(f, @oracle.binary(0), factored(1)), None)
}

///|
test "large certified order and the unit-order GF two boundary are accepted" {
  let f = @primefield.from_prime(@primality.check(log_prime_65537()).unwrap()).unwrap()
  let certificates = @core.replicate(@oracle.nat(16), log_prime_2())
  let factors = @factor.check_factorization(@oracle.binary(65536), certificates).unwrap()
  let order = exact_order(f, @oracle.binary(3), factors).unwrap()
  assert_eq(order_value(order), @oracle.binary(65536))
  let two = @primefield.field(@oracle.binary(2)).unwrap()
  let unit = exact_order(two, @binary.one(), factored(1)).unwrap()
  assert_eq(order_value(unit), @binary.one())
}
