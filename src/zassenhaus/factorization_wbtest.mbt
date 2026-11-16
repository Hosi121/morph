///|
fn test_primes() -> @core.Chain[@binary.Binary] {
  @oracle.chain([4, 2, 3, 5, 7, 11, 13].map(@oracle.binary))
}

///|
fn test_factor(value : Polynomial) -> Factorization {
  match
    factor(value, test_primes(), @oracle.nat(40), @oracle.nat(128)).unwrap() {
    Complete(result) => result
    Incomplete(_) => abort("unexpected bounded factorization outcome")
  }
}

///|
fn assert_expected_factors(
  factors : @core.Chain[Factor],
  expected : Array[(Array[Int32], Int32)],
) -> Unit raise {
  let actual = @oracle.array(factors)
  assert_eq(actual.length(), expected.length())
  for f in actual {
    let matching = expected.filter(fn(pair) {
      pair.0 == test_native(f.polynomial)
    })
    assert_eq(matching.length(), 1)
    assert_eq(@oracle.int_of_nat(f.multiplicity), matching[0].1)
  }
}

///|
fn assert_factor_fixture(
  input : Array[Int32],
  content : Int32,
  expected : Array[(Array[Int32], Int32)],
) -> Unit raise {
  let value = test_polynomial(input)
  let result = test_factor(value)
  assert_eq(@oracle.int_of_integer(result.content), content)
  assert_expected_factors(result.factors, expected)
  assert_true(check_product(value, result))
  assert_eq(check_factorization(value, result, @oracle.nat(128)), Proven)
}

///|
fn assert_rational_fixture(
  input : Array[(Int32, Int32)],
  unit : (Int32, Int32),
  expected : Array[(Array[Int32], Int32)],
) -> Unit raise {
  let values = @oracle.chain(
    input.map(fn(pair) { @oracle.rational(pair.0, pair.1) }),
  )
  match
    factor_rational(values, test_primes(), @oracle.nat(40), @oracle.nat(128)).unwrap() {
    RationalComplete(result) => {
      assert_eq(result.unit, @oracle.rational(unit.0, unit.1))
      assert_expected_factors(result.factors, expected)
      assert_eq(
        check_rational_factorization(values, result, @oracle.nat(128)),
        Proven,
      )
      assert_eq(
        check_rational_factorization(
          values,
          {
            unit: @exact.rational_add(result.unit, @exact.rational_one()),
            factors: result.factors,
          },
          @oracle.nat(128),
        ),
        Refuted,
      )
    }
    _ => fail("expected complete rational factorization")
  }
}

///|
test "zero input is explicitly outside factorization domain" {
  assert_eq(square_free(zero()), Err(ZeroPolynomial))
  assert_eq(
    factor(zero(), test_primes(), @oracle.nat(20), @oracle.nat(64)),
    Err(ZeroPolynomial),
  )
  assert_eq(
    factor_rational(Nil, test_primes(), @oracle.nat(20), @oracle.nat(64)),
    Err(ZeroPolynomial),
  )
}

///|
test "bad prime selection and both algorithm budgets are explicit" {
  let value = test_polynomial([-1, 0, 1])
  assert_eq(
    factor(value, Nil, @oracle.nat(20), @oracle.nat(64)).unwrap(),
    Incomplete(NoGoodPrime),
  )
  assert_eq(
    factor(
      value,
      @oracle.chain([4, 6, 2].map(@oracle.binary)),
      @oracle.nat(20),
      @oracle.nat(64),
    ).unwrap(),
    Incomplete(NoGoodPrime),
  )
  assert_eq(
    factor(value, Cons(@oracle.binary(3), Nil), Zero, @oracle.nat(64)).unwrap(),
    Incomplete(LiftBudget),
  )
  assert_eq(
    factor(value, Cons(@oracle.binary(3), Nil), @oracle.nat(20), Zero).unwrap(),
    Incomplete(RecombinationBudget),
  )
  let result = test_factor(value)
  assert_eq(check_factorization(value, result, Zero), Undecided)
  let loses_degree = test_polynomial([2, 7, 6])
  assert_eq(
    factor(
      loses_degree,
      @oracle.chain([2, 3].map(@oracle.binary)),
      @oracle.nat(20),
      @oracle.nat(64),
    ).unwrap(),
    Incomplete(NoGoodPrime),
  )
  let succeeds = factor(
    loses_degree,
    @oracle.chain([2, 3, 5].map(@oracle.binary)),
    @oracle.nat(20),
    @oracle.nat(64),
  ).unwrap()
  assert_true(succeeds is Complete(_))
}

///|
test "product equality does not certify integer irreducibility" {
  let value = test_polynomial([-1, 0, 0, 0, 1])
  let actual = test_factor(value)
  let first = @oracle.array(actual.factors)[0]
  let forged : Factorization = {
    content: @oracle.integer(1),
    factors: Cons(
      {
        polynomial: value,
        multiplicity: Succ(Zero),
        certificate: first.certificate,
      },
      Nil,
    ),
  }
  assert_true(check_product(value, forged))
  assert_eq(
    check_irreducible(value, first.certificate, @oracle.nat(128)),
    Refuted,
  )
  assert_eq(check_factorization(value, forged, @oracle.nat(128)), Refuted)
}

///|
test "irreducibility certificate tampering and normalization are rejected" {
  let value = test_polynomial([1, 0, 0, 0, 1])
  let result = test_factor(value)
  let f = @oracle.array(result.factors)[0]
  assert_eq(check_irreducible(value, f.certificate, @oracle.nat(128)), Proven)
  assert_eq(
    check_irreducible(
      value,
      { lift: f.certificate.lift, finite_certificates: Nil, },
      @oracle.nat(128),
    ),
    Refuted,
  )
  let data = f.certificate.lift
  let short : LiftCertificate = {
    target: data.target,
    prime: data.prime,
    exponent: Succ(Zero),
    factors: data.factors,
    lifts: @core.map(data.factors, lift_representative),
  }
  assert_true(check_lift(short))
  assert_eq(
    check_irreducible(
      value,
      { lift: short, finite_certificates: f.certificate.finite_certificates, },
      @oracle.nat(128),
    ),
    Refuted,
  )
  assert_eq(
    check_irreducible(
      scale(value, @oracle.integer(2)),
      f.certificate,
      @oracle.nat(128),
    ),
    Refuted,
  )
  assert_eq(
    check_irreducible(negate(value), f.certificate, @oracle.nat(128)),
    Refuted,
  )
  assert_eq(check_irreducible(one(), f.certificate, @oracle.nat(128)), Refuted)
  assert_eq(
    check_irreducible(
      test_polynomial([2, 0, 1]),
      f.certificate,
      @oracle.nat(128),
    ),
    Refuted,
  )
  assert_eq(
    check_factorization(
      value,
      {
        content: result.content,
        factors: Cons(
          { polynomial: value, multiplicity: Zero, certificate: f.certificate, },
          Nil,
        ),
      },
      @oracle.nat(128),
    ),
    Refuted,
  )
  assert_false(
    check_product(value, {
      content: @oracle.integer(2),
      factors: result.factors,
    }),
  )
}

///|
test "square-free components preserve multiplicities and positive primitive normalization" {
  let value = test_polynomial([-12, -12, 36, 12, -36, 12])
  let sf = square_free(value).unwrap()
  let reconstructed = @core.fold_left(
    sf.components,
    test_polynomial([@oracle.int_of_integer(sf.content)]),
    fn(acc, f) { multiply(acc, power(f.polynomial, f.multiplicity)) },
  )
  assert_eq(reconstructed, value)
  for f in @oracle.array(sf.components) {
    assert_true(primitive_positive(f.polynomial))
    assert_eq(gcd(f.polynomial, derivative(f.polynomial)).unwrap(), one())
  }
}

///|
test "exact subset budget boundary cannot become a premature proof" {
  let value = test_polynomial([1, 0, 0, 0, 1])
  let primes = @core.Cons(@oracle.binary(3), @core.Nil)
  assert_eq(
    factor(value, primes, @oracle.nat(20), @oracle.nat(3)).unwrap(),
    Incomplete(RecombinationBudget),
  )
  let result = match
    factor(value, primes, @oracle.nat(20), @oracle.nat(4)).unwrap() {
    Complete(result) => result
    _ =>
      abort("four leaves must complete this two-factor modular decomposition")
  }
  let f = @oracle.array(result.factors)[0]
  assert_eq(@oracle.array(f.certificate.lift.factors).length(), 2)
  assert_eq(check_irreducible(value, f.certificate, @oracle.nat(3)), Undecided)
  assert_eq(check_irreducible(value, f.certificate, @oracle.nat(4)), Proven)
}

///|
test "precision equality requires one further prime-power lift" {
  let value = test_polynomial([1, 0, 0, 1])
  assert_eq(@oracle.int_of_binary(recombination_threshold(value)), 32)
  let initial = start_lift(
    value,
    Cons(test_fp(2, [1, 1]), Cons(test_fp(2, [1, 1, 1]), Nil)),
  ).unwrap()
  let equality = match
    lift_above(initial, @oracle.binary(32), @oracle.nat(4)).unwrap() {
    Suspended(state) => state
    _ => abort("m = threshold cannot suffice")
  }
  assert_eq(@oracle.int_of_binary(lift_modulus(equality)), 32)
  assert_true(check_lift(lift_certificate(equality)))
  let witnesses = finite_certificates(lift_certificate(equality).factors).unwrap()
  assert_eq(
    check_irreducible(
      test_polynomial([1, 1]),
      { lift: lift_certificate(equality), finite_certificates: witnesses, },
      @oracle.nat(4),
    ),
    Refuted,
  )
  let greater = match
    lift_above(equality, @oracle.binary(32), Succ(Zero)).unwrap() {
    Reached(state) => state
    _ => abort("next lift must exceed threshold")
  }
  assert_eq(@oracle.int_of_binary(lift_modulus(greater)), 64)
  assert_eq(
    check_irreducible(
      test_polynomial([1, 1]),
      { lift: lift_certificate(greater), finite_certificates: witnesses, },
      @oracle.nat(4),
    ),
    Proven,
  )
  assert_eq(
    factor(value, Cons(@oracle.binary(2), Nil), @oracle.nat(4), @oracle.nat(4)).unwrap(),
    Incomplete(LiftBudget),
  )
  assert_true(
    factor(value, Cons(@oracle.binary(2), Nil), @oracle.nat(5), @oracle.nat(4)).unwrap()
    is Complete(_),
  )
}

///|
test "finite-field witness payload and rational scaled-unit boundaries are checked" {
  let value = test_polynomial([1, 0, 0, 0, 1])
  let result = test_factor(value)
  let f = @oracle.array(result.factors)[0]
  let corrupt = @core.map(f.certificate.finite_certificates, fn(_) {
    (
      { frobenius: @core.Nil, coprime: @core.Nil, } :
      @fppoly.IrreducibilityCertificate)
  })
  assert_eq(
    check_irreducible(
      value,
      { lift: f.certificate.lift, finite_certificates: corrupt, },
      @oracle.nat(128),
    ),
    Refuted,
  )
  let coefficients = @oracle.chain(
    [1, 0, 0, 0, 1].map(fn(c) { @oracle.rational(c, 1) }),
  )
  assert_eq(
    check_rational_factorization(
      coefficients,
      { unit: @oracle.rational(1, 2), factors: result.factors, },
      @oracle.nat(128),
    ),
    Refuted,
  )
  let input = @oracle.chain([@oracle.rational(1, 6)])
  assert_eq(
    check_rational_factorization(
      input,
      { unit: @oracle.rational(1, 6), factors: Nil, },
      Zero,
    ),
    Proven,
  )
  assert_eq(
    check_rational_factorization(
      input,
      { unit: @oracle.rational(1, 5), factors: Nil, },
      Zero,
    ),
    Refuted,
  )
}

///|
test "content and repeated-factor normalization remain exact at negative leading coefficient" {
  let value = test_polynomial([-2, 0, 4, 0, -2])
  let decomposition = square_free(value).unwrap()
  assert_eq(@oracle.int_of_integer(decomposition.content), -2)
  assert_eq(@oracle.array(decomposition.components).length(), 1)
  let component = @oracle.array(decomposition.components)[0]
  assert_eq(test_native(component.polynomial), [-1, 0, 1])
  assert_eq(@oracle.int_of_nat(component.multiplicity), 2)
  let result = test_factor(value)
  assert_eq(@oracle.array(result.factors).length(), 2)
  assert_eq(check_factorization(value, result, @oracle.nat(16)), Proven)
}
