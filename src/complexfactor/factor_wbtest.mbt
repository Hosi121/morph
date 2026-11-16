///|
fn cf_source(values : Array[(Int32, Int32)]) -> @poly.Polynomial {
  fn terms(index : Int32) -> @core.Chain[@poly.Term] {
    if index == values.length() {
      Nil
    } else {
      Cons(
        {
          coefficient: @oracle.rational(values[index].0, values[index].1),
          exponents: Cons(@oracle.nat(index), Nil),
        },
        terms(index + 1),
      )
    }
  }
  @poly.polynomial(Succ(Zero), terms(0)).unwrap()
}

///|
fn cf_primes() -> @core.Chain[@binary.Binary] {
  @oracle.chain([2, 3, 5, 7, 11, 13].map(@oracle.binary))
}

///|
fn cf_problem(source : @poly.Polynomial) -> Problem {
  match
    prepare(
      source,
      cf_primes(),
      @oracle.nat(40),
      @oracle.nat(128),
      @oracle.nat(128),
    ).unwrap() {
    Prepared(problem) => problem
    _ => abort("small factorization must complete and verify")
  }
}

///|
fn cf_finish(source : @poly.Polynomial) -> RootFamily {
  match
    run(start(cf_problem(source)), @oracle.nat(12), @oracle.nat(3000)).unwrap() {
    Complete(value) => value
    Paused(_, _) => abort("small factor roots must complete")
  }
}

///|
fn cf_assert_real(value : Root, expected : (Int32, Int32)) -> Unit raise {
  let bare = root(value)
  let coordinates = @oracle.array(@complexroots.coordinate_expressions(bare))
  let difference = @poly.subtract(
    coordinates[0],
    @poly.constant(Succ(Zero), @oracle.rational(expected.0, expected.1)),
  ).unwrap()
  assert_eq(
    @tarski.sign_at(@complexroots.parameter(bare), difference).unwrap().sign,
    Equal,
  )
  assert_eq(
    @tarski.sign_at(@complexroots.parameter(bare), coordinates[1]).unwrap().sign,
    Equal,
  )
}

///|
test "factor preparation preserves invalid, incomplete and undecided outcomes" {
  let linear = cf_source([(-1, 1), (1, 1)])
  assert_true(
    prepare(@poly.zero(Succ(Zero)), Nil, Zero, Zero, Zero)
    is Err(ZeroPolynomial),
  )
  assert_true(
    prepare(
      @poly.constant(Succ(Succ(Zero)), @exact.rational_one()),
      Nil,
      Zero,
      Zero,
      Zero,
    )
    is Err(NotUnivariate),
  )
  assert_true(
    prepare(linear, Nil, @oracle.nat(40), @oracle.nat(128), @oracle.nat(128))
    is Ok(FactorizationIncomplete(NoGoodPrime)),
  )
  assert_true(
    prepare(linear, cf_primes(), Zero, @oracle.nat(128), @oracle.nat(128))
    is Ok(FactorizationIncomplete(LiftBudget)),
  )
  assert_true(
    prepare(linear, cf_primes(), @oracle.nat(40), Zero, @oracle.nat(128))
    is Ok(FactorizationIncomplete(RecombinationBudget)),
  )
  let factorization = match
    prepare(linear, cf_primes(), @oracle.nat(40), @oracle.nat(128), Zero).unwrap() {
    VerificationUndecided(factorization) => factorization
    _ => abort("zero verification fuel must stay undecided")
  }
  assert_true(
    prepare_with_factorization(linear, factorization, @oracle.nat(128))
    is Ok(Prepared(_)),
  )
  assert_true(
    prepare_with_factorization(
      cf_source([(-2, 1), (1, 1)]),
      factorization,
      @oracle.nat(128),
    )
    is Err(InvalidFactorization),
  )
  let constant = cf_source([(7, 3)])
  let value = match run(start(cf_problem(constant)), Zero, Zero).unwrap() {
    Complete(value) => value
    _ => abort("constant has no root work")
  }
  assert_true(roots(value) is Nil)
  assert_eq(check_result(constant, value, certificate(value), Zero), Proven)
  assert_eq(check(cf_source([(8, 3)]), certificate(value), Zero), Refuted)
}

///|
test "rational nonmonic repeated factors retain exact values and original weights" {
  // (-5/7) * (2*z-1)^2 * (3*z+2).
  let polynomial = cf_source([(-10, 7), (25, 7), (20, 7), (-60, 7)])
  let value = cf_finish(polynomial)
  assert_true(source(value).equal(polynomial))
  let proof = certificate(value)
  assert_eq(proof.factorization.unit, @oracle.rational(-5, 7))
  assert_eq(check_result(polynomial, value, proof, @oracle.nat(128)), Proven)
  assert_eq(check_result(polynomial, value, proof, Zero), Undecided)
  let values = @oracle.array(roots(value))
  assert_eq(values.length(), 2)
  for item in values {
    match multiplicity(item) {
      Succ(Zero) => cf_assert_real(item, (-2, 3))
      Succ(Succ(Zero)) => cf_assert_real(item, (1, 2))
      _ => fail("unexpected original multiplicity")
    }
  }
}

///|
test "mixed repeated factor covers and payload bindings reject adversarial changes" {
  // (z^2+1)^2 * (z-1), without mixed Cartesian cross pairs.
  let polynomial = cf_source([(-1, 1), (1, 1), (-2, 1), (2, 1), (-1, 1), (1, 1)])
  let value = cf_finish(polynomial)
  let proof = certificate(value)
  assert_eq(check_result(polynomial, value, proof, @oracle.nat(128)), Proven)
  let found = @oracle.array(roots(value))
  assert_eq(found.length(), 3)
  assert_eq(
    found.filter(fn(item) { multiplicity(item).equal(@oracle.nat(2)) }).length(),
    2,
  )
  assert_eq(
    found.filter(fn(item) { multiplicity(item).equal(Succ(Zero)) }).length(),
    1,
  )
  for item in found {
    if multiplicity(item).equal(Succ(Zero)) {
      cf_assert_real(item, (1, 1))
    }
  }
  let changed_unit : Certificate = {
    ..proof,
    factorization: {
      ..proof.factorization,
      unit: @exact.rational_negate(proof.factorization.unit),
    },
  }
  assert_eq(
    check_result(
      polynomial,
      { ..value, proof: changed_unit, },
      changed_unit,
      @oracle.nat(128),
    ),
    Refuted,
  )
  let omitted : Certificate = {
    ..proof,
    covers: @core.drop(Succ(Zero), proof.covers),
  }
  assert_eq(
    check_result(
      polynomial,
      { ..value, proof: omitted, },
      omitted,
      @oracle.nat(128),
    ),
    Refuted,
  )
  let reversed : Certificate = { ..proof, covers: @core.reverse(proof.covers), }
  assert_eq(
    check_result(
      polynomial,
      { ..value, proof: reversed, },
      reversed,
      @oracle.nat(128),
    ),
    Refuted,
  )
  let covers = @oracle.array(proof.covers)
  let duplicated : Certificate = {
    ..proof,
    covers: @oracle.chain([covers[0], covers[0]]),
  }
  assert_eq(
    check_result(
      polynomial,
      { ..value, proof: duplicated, },
      duplicated,
      @oracle.nat(128),
    ),
    Refuted,
  )
  let factors = @oracle.array(proof.factorization.factors)
  let duplicate_factor : Certificate = {
    ..proof,
    factorization: {
      ..proof.factorization,
      factors: @oracle.chain([factors[0], factors[0]]),
    },
  }
  assert_eq(check(polynomial, duplicate_factor, @oracle.nat(128)), Refuted)
  let zero_weight : Certificate = {
    ..proof,
    factorization: {
      ..proof.factorization,
      factors: @oracle.chain([{ ..factors[0], multiplicity: Zero, }, factors[1]]),
    },
  }
  assert_eq(check(polynomial, zero_weight, @oracle.nat(128)), Refuted)
  let wrong_weight = {
    ..found[0],
    weight: @core.add(multiplicity(found[0]), Succ(Zero)),
  }
  assert_eq(
    check_result(
      polynomial,
      {
        ..value,
        roots: Cons(wrong_weight, @core.drop(Succ(Zero), roots(value))),
      },
      proof,
      @oracle.nat(128),
    ),
    Refuted,
  )
  assert_eq(
    check_result(
      polynomial,
      { ..value, roots: @core.reverse(roots(value)), },
      proof,
      @oracle.nat(128),
    ),
    Refuted,
  )
  assert_eq(
    check_result(
      polynomial,
      { ..value, roots: @core.drop(Succ(Zero), roots(value)), },
      proof,
      @oracle.nat(128),
    ),
    Refuted,
  )
  let duplicate_payload = {
    ..value,
    roots: @oracle.chain([found[0], found[0], found[2]]),
  }
  assert_eq(
    check_result(polynomial, duplicate_payload, proof, @oracle.nat(128)),
    Refuted,
  )
  let bad_index = { ..found[0], index: @oracle.nat(100), }
  assert_eq(
    check_result(
      polynomial,
      { ..value, roots: Cons(bad_index, @core.drop(Succ(Zero), roots(value))), },
      proof,
      @oracle.nat(128),
    ),
    Refuted,
  )
  // Same root set with a different source unit must still reconstruct exactly.
  let scaled = @poly.scale(polynomial, {
    coefficient: @oracle.rational(2, 1),
    exponents: Cons(Zero, Nil),
  }).unwrap()
  let source_attack : Certificate = { ..proof, source: scaled, }
  assert_eq(
    check_result(
      scaled,
      { ..value, source: scaled, proof: source_attack, },
      source_attack,
      @oracle.nat(128),
    ),
    Refuted,
  )
  // A foreign bare RootSet cannot replace a source-bound factor payload.
  let foreign = cf_finish(cf_source([(-2, 1), (1, 1)]))
  let foreign_root = @oracle.array(roots(foreign))[0]
  let payload_attack = { ..found[0], group: foreign_root.group, }
  assert_eq(
    check_result(
      polynomial,
      {
        ..value,
        roots: Cons(payload_attack, @core.drop(Succ(Zero), roots(value))),
      },
      proof,
      @oracle.nat(128),
    ),
    Refuted,
  )
}

///|
test "paused factor jobs retain completed groups and resume without false covers" {
  let polynomial = cf_source([(-1, 1), (0, 1), (1, 1)])
  let initial = start(cf_problem(polynomial))
  assert_true(run(initial, Zero, Zero) is Ok(Paused(_, ComputationFuel)))
  assert_true(run(initial, Zero, Succ(Zero)) is Ok(Paused(_, AttemptLimit)))
  fn finish(
    state : Search,
    count : Int32,
    retained : Bool,
  ) -> (RootFamily, Bool) {
    if count == 0 {
      abort("bounded resumptions exhausted")
    }
    match run(state, @oracle.nat(12), Succ(Zero)).unwrap() {
      Complete(value) => (value, retained || state.completed is Cons(_, _))
      Paused(next, _) =>
        finish(next, count - 1, retained || next.completed is Cons(_, _))
    }
  }
  let (value, retained) = finish(initial, 100, false)
  assert_true(retained)
  assert_eq(@oracle.array(roots(value)).length(), 2)
  assert_eq(
    check_result(polynomial, value, certificate(value), @oracle.nat(128)),
    Proven,
  )
}
