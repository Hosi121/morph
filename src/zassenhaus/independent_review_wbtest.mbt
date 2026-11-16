///|
// Independent reviewer tests. No production solver/checker implementation changes.
fn review_abs(x : Int32) -> Int32 {
  if x < 0 {
    -x
  } else {
    x
  }
}

///|
fn review_gcd(a : Int32, b : Int32) -> Int32 {
  let mut x = review_abs(a)
  let mut y = review_abs(b)
  while y != 0 {
    let r = x % y
    x = y
    y = r
  }
  x
}

///|
fn review_trim(values : Array[Int32]) -> Array[Int32] {
  let result = values.copy()
  while result.length() > 0 && result[result.length() - 1] == 0 {
    ignore(result.pop())
  }
  result
}

///|
fn review_multiply(a : Array[Int32], b : Array[Int32]) -> Array[Int32] {
  if a.length() == 0 || b.length() == 0 {
    return []
  }
  let result = Array::make(a.length() + b.length() - 1, 0)
  for i in 0..<a.length() {
    for j in 0..<b.length() {
      result[i + j] += a[i] * b[j]
    }
  }
  review_trim(result)
}

///|
fn review_content(values : Array[Int32]) -> Int32 {
  let mut content = 0
  for x in values {
    content = review_gcd(content, x)
  }
  content
}

///|
// Rational root theorem is a complete reducibility oracle only in degree two or
// three. Clear denominators while evaluating each candidate, avoiding Float.
fn review_has_rational_root(values : Array[Int32]) -> Bool {
  if values[0] == 0 {
    return true
  }
  let n = values.length() - 1
  let constant = review_abs(values[0])
  let leading = review_abs(values[n])
  for numerator in -constant..<=constant {
    if numerator == 0 || constant % numerator != 0 {
      continue
    }
    for denominator in 1..<=leading {
      if leading % denominator != 0 {
        continue
      }
      let mut result = values[n]
      let mut denominator_power = 1
      for j in 1..<=n {
        denominator_power *= denominator
        result = result * numerator + values[n - j] * denominator_power
      }
      if result == 0 {
        return true
      }
    }
  }
  false
}

///|
fn review_factor(value : Polynomial, primes : Array[Int32]) -> Factorization {
  match
    factor(
      value,
      @oracle.chain(primes.map(@oracle.binary)),
      @oracle.nat(24),
      @oracle.nat(256),
    ).unwrap() {
    Complete(result) => result
    _ => abort("independent review expected complete factorization")
  }
}

///|
fn review_validate_small(values : Array[Int32]) -> Unit raise {
  let value = test_polynomial(values)
  let result = review_factor(value, [2, 3, 5, 7, 11, 13])
  assert_eq(check_factorization(value, result, @oracle.nat(256)), Proven)
  let factors = @oracle.array(result.factors)
  let mut product = [@oracle.int_of_integer(result.content)]
  for factor in factors {
    let cs = test_native(factor.polynomial)
    assert_true(cs.length() >= 2)
    assert_true(cs[cs.length() - 1] > 0)
    assert_eq(review_content(cs), 1)
    if cs.length() > 2 {
      assert_false(review_has_rational_root(cs))
    }
    let multiplicity = @oracle.int_of_nat(factor.multiplicity)
    assert_true(multiplicity > 0)
    for _ in 0..<multiplicity {
      product = review_multiply(product, cs)
    }
  }
  assert_eq(product, review_trim(values))
  let irreducible = !review_has_rational_root(values)
  if irreducible {
    assert_eq(factors.length(), 1)
    assert_eq(@oracle.int_of_nat(factors[0].multiplicity), 1)
    assert_eq(test_native(factors[0].polynomial), values)
  } else {
    assert_true(
      factors.length() > 1 || @oracle.int_of_nat(factors[0].multiplicity) > 1,
    )
    // Claiming the whole reducible input as a single irreducible factor must fail.
    let forged : Factorization = {
      content: @oracle.integer(1),
      factors: Cons(
        {
          polynomial: value,
          multiplicity: Succ(Zero),
          certificate: factors[0].certificate,
        },
        Nil,
      ),
    }
    assert_true(check_product(value, forged))
    assert_eq(check_factorization(value, forged, @oracle.nat(256)), Refuted)
  }
}

///|
test "independent review exhaustive small primitive quadratics and cubics rational root oracle" {
  let mut checked = 0
  for leading in 1..<=3 {
    for b in -3..<=3 {
      for c in -3..<=3 {
        let quadratic = [c, b, leading]
        if review_content(quadratic) == 1 {
          review_validate_small(quadratic)
          checked += 1
        }
      }
    }
    for b in -2..<=2 {
      for c in -2..<=2 {
        for d in -2..<=2 {
          let cubic = [d, c, b, leading]
          if review_content(cubic) == 1 {
            review_validate_small(cubic)
            checked += 1
          }
        }
      }
    }
  }
  assert_true(checked > 400)
}

///|
test "independent review coefficient bound and leading coefficient threshold on enumerated products" {
  let mut checked = 0
  for a in 1..<=4 {
    for b in -4..<=4 {
      let g = [b, a]
      if review_content(g) != 1 {
        continue
      }
      for c in 1..<=4 {
        for d in -4..<=4 {
          let h = [d, c]
          if review_content(h) != 1 {
            continue
          }
          let f = review_multiply(g, h)
          let p = test_polynomial(f)
          let expected = (1 << (f.length() - 1)) *
            f.fold(init=0, fn(acc, x) { acc + review_abs(x) })
          let bound = @oracle.int_of_binary(coefficient_bound(p))
          assert_eq(bound, expected)
          assert_eq(
            @oracle.int_of_binary(recombination_threshold(p)),
            2 * a * c * expected,
          )
          for v in g {
            assert_true(review_abs(v) <= bound)
          }
          for v in h {
            assert_true(review_abs(v) <= bound)
          }
          checked += 1
        }
      }
    }
  }
  assert_true(checked > 500)
  assert_eq(@oracle.int_of_binary(coefficient_bound(zero())), 0)
  assert_eq(@oracle.int_of_binary(recombination_threshold(zero())), 0)
}

///|
fn review_mod(x : Int32, m : Int32) -> Int32 {
  let r = x % m
  if r < 0 {
    r + m
  } else {
    r
  }
}

///|
fn review_inverse(a : Int32, m : Int32) -> Int32 {
  let mut old_r = a
  let mut r = m
  let mut old_s = 1
  let mut s = 0
  while r != 0 {
    let q = old_r / r
    let next_r = old_r - q * r
    let next_s = old_s - q * s
    old_r = r
    r = next_r
    old_s = s
    s = next_s
  }
  if old_r != 1 {
    abort("review inverse requires coprimality")
  }
  review_mod(old_s, m)
}

///|
fn review_scale_mod(
  values : Array[Int32],
  scalar : Int32,
  m : Int32,
) -> Array[Int32] {
  values.map(fn(x) {
    let r = (x.to_int64() * scalar.to_int64() % m.to_int64()).to_int()
    review_mod(r, m)
  })
}

///|
fn review_multiply_mod(
  a : Array[Int32],
  b : Array[Int32],
  m : Int32,
) -> Array[Int32] {
  if a.length() == 0 || b.length() == 0 {
    return []
  }
  let result = Array::make(a.length() + b.length() - 1, 0)
  for i in 0..<a.length() {
    for j in 0..<b.length() {
      result[i + j] = ((
        result[i + j].to_int64() + a[i].to_int64() * b[j].to_int64()
      ) %
      m.to_int64()).to_int()
    }
  }
  review_trim(result)
}

///|
fn review_primitive(values : Array[Int32]) -> Array[Int32] {
  let trimmed = review_trim(values)
  if trimmed.length() == 0 {
    return []
  }
  let content = review_content(trimmed) *
    (if trimmed[trimmed.length() - 1] < 0 { -1 } else { 1 })
  trimmed.map(fn(x) { x / content })
}

///|
test "independent review direct modular inverses verify nonmonic Hensel lifts and every subset recovery" {
  let mut lift_checks = 0
  let mut recovery_checks = 0
  for sample in 0..<48 {
    let prime = [3, 5, 7][sample % 3]
    let count = 2 + sample % 2
    let pool = []
    for a in 1..<=4 {
      for b in -4..<=4 {
        if a % prime != 0 && review_gcd(a, b) == 1 {
          pool.push([b, a])
        }
      }
    }
    let qs = []
    let constants = []
    for k in 0..<pool.length() {
      let q = pool[(k + sample) % pool.length()]
      let c = review_mod(q[0] * review_inverse(q[1], prime), prime)
      if !constants.contains(c) && qs.length() < count {
        qs.push(q)
        constants.push(c)
      }
    }
    assert_eq(qs.length(), count)
    let unit = [-2, -1, 1, 2][sample % 4]
    let mut f = [unit]
    for q in qs {
      f = review_multiply(f, q)
    }
    let target = test_polynomial(f)
    let seeds = @oracle.chain(
      qs.map(fn(q) {
        test_fp(prime, review_scale_mod(q, review_inverse(q[1], prime), prime))
      }),
    )
    let initial = start_lift(target, seeds).unwrap()
    let mut lifted = initial
    let mut m = prime
    for exponent in 1..<=5 {
      if exponent > 1 {
        lifted = lift_step(lifted).unwrap()
        m *= prime
      }
      let certificate = lift_certificate(lifted)
      assert_true(check_lift(certificate))
      assert_eq(@oracle.int_of_binary(lift_modulus(lifted)), m)
      let gs = @oracle.array(certificate.lifts).map(test_native)
      let mut product = [1]
      for i in 0..<count {
        assert_eq(
          gs[i],
          review_scale_mod(qs[i], review_inverse(qs[i][1], m), m),
        )
        product = review_multiply_mod(product, gs[i], m)
      }
      assert_eq(
        review_scale_mod(product, f[f.length() - 1], m),
        f.map(fn(c) { review_mod(c, m) }),
      )
      lift_checks += 1
    }
    let complete = match
      lift_above(lifted, recombination_threshold(target), @oracle.nat(24)).unwrap() {
      Reached(value) => value
      _ => abort("review lifting failed to reach reconstruction precision")
    }
    let modulus = @oracle.int_of_binary(lift_modulus(complete))
    let lifts = @oracle.array(lift_certificate(complete).lifts)
    for mask in 1..<((1 << count) - 1) {
      let mut expected = [1]
      let mut modular_product = [1]
      let mut symbolic_product = one()
      for i in 0..<count {
        if (mask & (1 << i)) != 0 {
          expected = review_multiply(expected, qs[i])
          modular_product = review_multiply_mod(
            modular_product,
            test_native(lifts[i]),
            modulus,
          )
          symbolic_product = multiply(symbolic_product, lifts[i])
        }
      }
      let centered = review_scale_mod(
        modular_product,
        f[f.length() - 1],
        modulus,
      ).map(fn(c) {
        if c.to_int64() * 2L > modulus.to_int64() {
          c - modulus
        } else {
          c
        }
      })
      assert_eq(review_primitive(centered), review_primitive(expected))
      assert_eq(
        test_native(recovered(symbolic_product, target, complete.modulus)),
        review_primitive(expected),
      )
      recovery_checks += 1
    }
  }
  assert_eq(lift_checks, 240)
  assert_eq(recovery_checks, 192)
}

///|
fn review_irreducibility_certificate(
  lifted : Lift,
) -> IrreducibilityCertificate {
  let data = lift_certificate(lifted)
  {
    lift: data,
    finite_certificates: @core.map(data.factors, fn(f) {
      @fppoly.irreducibility(f).unwrap().unwrap()
    }),
  }
}

///|
test "independent review strict threshold and every full subset exhaustion fuel boundary" {
  // x^4+x+2 has no rational root; no monic quadratic factor can satisfy
  // b*d=2 and b+d=a^2. Its reduction mod 2 has three coprime factors.
  let value = test_polynomial([2, 1, 0, 0, 1])
  let seed = start_lift(
    value,
    @oracle.chain([
      test_fp(2, [0, 1]),
      test_fp(2, [1, 1]),
      test_fp(2, [1, 1, 1]),
    ]),
  ).unwrap()
  assert_eq(@oracle.int_of_binary(recombination_threshold(value)), 128)
  let at_boundary = match
    lift_above(seed, @oracle.binary(127), @oracle.nat(6)).unwrap() {
    Reached(lifted) => lifted
    _ => abort("must reach exponent seven")
  }
  assert_eq(@oracle.int_of_binary(lift_modulus(at_boundary)), 128)
  assert_true(check_lift(lift_certificate(at_boundary)))
  assert_eq(
    check_irreducible(
      value,
      review_irreducibility_certificate(at_boundary),
      @oracle.nat(8),
    ),
    Refuted,
  )
  assert_true(
    lift_above(seed, recombination_threshold(value), @oracle.nat(6)).unwrap()
    is Suspended(_),
  )
  let above = lift_step(at_boundary).unwrap()
  let certificate = review_irreducibility_certificate(above)
  assert_eq(@oracle.int_of_binary(lift_modulus(above)), 256)
  for fuel in 0..<8 {
    assert_eq(
      check_irreducible(value, certificate, @oracle.nat(fuel)),
      Undecided,
    )
    assert_eq(
      factor(
        value,
        @oracle.chain([@oracle.binary(2)]),
        @oracle.nat(7),
        @oracle.nat(fuel),
      ).unwrap(),
      Incomplete(RecombinationBudget),
    )
  }
  assert_eq(check_irreducible(value, certificate, @oracle.nat(8)), Proven)
  let complete = factor(
    value,
    @oracle.chain([@oracle.binary(2)]),
    @oracle.nat(7),
    @oracle.nat(8),
  ).unwrap()
  assert_true(complete is Complete(_))
  assert_eq(
    factor(
      value,
      @oracle.chain([@oracle.binary(2)]),
      @oracle.nat(6),
      @oracle.nat(8),
    ).unwrap(),
    Incomplete(LiftBudget),
  )
}

///|
fn review_divides(value : Array[Int32], divisor : Array[Int32]) -> Bool {
  let remainder = review_trim(value)
  let d = review_trim(divisor)
  if d.length() == 0 {
    return false
  }
  while remainder.length() >= d.length() {
    let coefficient = remainder[remainder.length() - 1]
    let leading = d[d.length() - 1]
    if coefficient % leading != 0 {
      return false
    }
    let q = coefficient / leading
    let offset = remainder.length() - d.length()
    for i in 0..<d.length() {
      remainder[offset + i] -= q * d[i]
    }
    while remainder.length() > 0 && remainder[remainder.length() - 1] == 0 {
      ignore(remainder.pop())
    }
  }
  remainder.length() == 0
}

///|
test "independent review reducible polynomial requiring grouped modular factors rejects at exact first witness leaf" {
  // Sophie Germain: x^4+4=(x^2-2x+2)(x^2+2x+2).
  // Modulo 5 there are four linear factors; no singleton is an integer divisor.
  let values = [4, 0, 0, 0, 1]
  let value = test_polynomial(values)
  let complete = review_factor(value, [5])
  assert_eq(@oracle.int_of_nat(@core.length(complete.factors)), 2)
  let certificate = @oracle.array(complete.factors)[0].certificate
  let data = certificate.lift
  let lifts = @oracle.array(data.lifts).map(test_native)
  assert_eq(lifts.length(), 4)
  let m = @oracle.int_of_binary(prime_power(data.prime, data.exponent))
  let mut first_witness = -1
  for ordinal in 0..<16 {
    let mut product = [1]
    let mut cardinality = 0
    for i in 0..<4 {
      if (ordinal & (1 << (3 - i))) != 0 {
        product = review_multiply_mod(product, lifts[i], m)
        cardinality += 1
      }
    }
    let candidate = review_primitive(
      product.map(fn(c) { if c * 2 > m { c - m } else { c } }),
    )
    let witness = candidate.length() > 1 &&
      candidate.length() < values.length() &&
      review_divides(values, candidate)
    if cardinality == 1 {
      assert_false(witness)
    }
    if witness && first_witness == -1 {
      first_witness = ordinal
    }
  }
  assert_true(first_witness >= 3)
  for fuel in 0..<=16 {
    assert_eq(
      check_irreducible(value, certificate, @oracle.nat(fuel)),
      if fuel <= first_witness {
        Undecided
      } else {
        Refuted
      },
    )
    let factored = factor(
      value,
      @oracle.chain([@oracle.binary(5)]),
      @oracle.nat(24),
      @oracle.nat(fuel),
    ).unwrap()
    if fuel < 16 {
      assert_eq(factored, Incomplete(RecombinationBudget))
    } else {
      assert_true(factored is Complete(_))
    }
  }
  let forged : Factorization = {
    content: @oracle.integer(1),
    factors: Cons(
      { polynomial: value, multiplicity: Succ(Zero), certificate, },
      Nil,
    ),
  }
  assert_true(check_product(value, forged))
  assert_eq(check_factorization(value, forged, @oracle.nat(16)), Refuted)
}

///|
test "independent review congruent reducible target cannot reuse an irreducibility certificate below its recomputed bound" {
  let value = test_polynomial([2, 1, 0, 0, 1])
  let lifted = match
    lift_above(
      start_lift(
        value,
        @oracle.chain([
          test_fp(2, [0, 1]),
          test_fp(2, [1, 1]),
          test_fp(2, [1, 1, 1]),
        ]),
      ).unwrap(),
      @oracle.binary(128),
      @oracle.nat(7),
    ).unwrap() {
    Reached(lifted) => lifted
    _ => abort("expected precision 256")
  }
  let certificate = review_irreducibility_certificate(lifted)
  // -19 is an exact root of x^4+x-130302. The two targets are congruent mod 256.
  let forged_target = test_polynomial([-130302, 1, 0, 0, 1])
  assert_true(review_divides(test_native(forged_target), [19, 1]))
  let forged : IrreducibilityCertificate = {
    ..certificate,
    lift: { ..certificate.lift, target: forged_target, },
  }
  assert_true(check_lift(forged.lift))
  assert_eq(check_irreducible(forged_target, forged, @oracle.nat(8)), Refuted)
  let scaled : IrreducibilityCertificate = {
    ..certificate,
    lift: { ..certificate.lift, target: scale(value, @oracle.integer(3)), },
  }
  assert_true(check_lift(scaled.lift))
  assert_eq(check_irreducible(value, scaled, @oracle.nat(8)), Refuted)
}

///|
test "independent review lift certificate fields are untrusted and malformed residues degrees and finite proofs fail closed" {
  let target = test_polynomial([2, 7, 6])
  let initial = start_lift(
    target,
    @oracle.chain([test_fp(5, [3, 1]), test_fp(5, [4, 1])]),
  ).unwrap()
  let lifted = match
    lift_above(initial, recombination_threshold(target), @oracle.nat(12)).unwrap() {
    Reached(lifted) => lifted
    _ => abort("expected sufficient precision")
  }
  let certificate = review_irreducibility_certificate(lifted)
  let data = certificate.lift
  let gs = @oracle.array(data.lifts)
  let fs = @oracle.array(data.factors)
  let m = @oracle.int_of_binary(lift_modulus(lifted))
  let wrong_lifts = [
    @oracle.chain([add(gs[0], one()), gs[1]]),
    @oracle.chain([add(gs[0], test_polynomial([m])), gs[1]]),
    @oracle.chain([scale(gs[0], @oracle.integer(2)), gs[1]]),
    @oracle.chain([negate(gs[0]), gs[1]]),
    @oracle.chain([gs[1], gs[0]]),
    @oracle.chain([gs[0]]),
  ]
  for lifts in wrong_lifts {
    assert_false(check_lift({ ..data, lifts, }))
  }
  assert_false(check_lift({ ..data, exponent: Zero, }))
  for prime in [0, 1, 4, 25, 7] {
    assert_false(check_lift({ ..data, prime: @oracle.binary(prime), }))
  }
  assert_false(
    check_lift({ ..data, factors: @oracle.chain([test_fp(5, [1]), fs[1]]), }),
  )
  assert_false(
    check_lift({ ..data, factors: @oracle.chain([test_fp(3, [1, 1]), fs[1]]), }),
  )
  assert_false(
    check_lift({
      ..data,
      factors: @oracle.chain([fs[0], fs[0]]),
      lifts: @oracle.chain([gs[0], gs[0]]),
    }),
  )
  assert_false(check_lift({ ..data, target: add(data.target, one()), }))
  assert_false(
    check_lift({ ..data, target: scale(data.target, @oracle.integer(5)), }),
  )
  let first = @oracle.array(review_factor(target, [5]).factors)[0]
  assert_eq(
    check_irreducible(
      first.polynomial,
      { ..certificate, finite_certificates: Nil, },
      @oracle.nat(16),
    ),
    Refuted,
  )
  assert_eq(
    check_irreducible(
      first.polynomial,
      {
        ..certificate,
        finite_certificates: @core.map(certificate.finite_certificates, fn(_) {
          { frobenius: Nil, coprime: Nil, }
        }),
      },
      @oracle.nat(16),
    ),
    Refuted,
  )
}

///|
test "independent review reducible but coprime grouped seeds lift correctly without certifying irreducibility" {
  let q = [2, 5, 2]
  let r = [1, 0, 3]
  let values = review_multiply(q, r)
  let target = test_polynomial(values)
  let seed = start_lift(
    target,
    @oracle.chain([
      test_fp(5, review_scale_mod(q, review_inverse(2, 5), 5)),
      test_fp(5, review_scale_mod(r, review_inverse(3, 5), 5)),
    ]),
  ).unwrap()
  let complete = match
    lift_above(seed, recombination_threshold(target), @oracle.nat(12)).unwrap() {
    Reached(lifted) => lifted
    _ => abort("expected sufficient grouped seed precision")
  }
  let data = lift_certificate(complete)
  assert_true(check_lift(data))
  let m = @oracle.int_of_binary(lift_modulus(complete))
  let gs = @oracle.array(data.lifts).map(test_native)
  assert_eq(gs[0], review_scale_mod(q, review_inverse(2, m), m))
  assert_eq(gs[1], review_scale_mod(r, review_inverse(3, m), m))
  assert_eq(
    @fppoly.irreducibility(@oracle.array(data.factors)[0]).unwrap(),
    None,
  )
  let forged : IrreducibilityCertificate = {
    lift: data,
    finite_certificates: @core.map(data.factors, fn(_) {
      { frobenius: Nil, coprime: Nil, }
    }),
  }
  assert_eq(check_irreducible(target, forged, @oracle.nat(4)), Refuted)
}
