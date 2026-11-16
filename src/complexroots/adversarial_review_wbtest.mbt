///|
fn cr_review_u(coefficients : Array[(Int32, Int32)]) -> @poly.Polynomial {
  @poly.polynomial(
    @oracle.nat(1),
    @oracle.chain(
      coefficients.mapi(fn(index, value) {
        {
          coefficient: @oracle.rational(value.0, value.1),
          exponents: Cons(@oracle.nat(index), Nil),
        }
      }),
    ),
  ).unwrap()
}

///|
fn cr_review_solve(source : @poly.Polynomial) -> RootSet {
  match
    run(start(prepare(source).unwrap()), @oracle.nat(3), @oracle.nat(256)).unwrap() {
    Complete(value) => value
    _ => abort("independent quadratic review exceeded its finite budget")
  }
}

///|
fn cr_review_materialize(
  root : Root,
) -> (@complex.Number, MaterializationCertificate) {
  match materialize(root, @oracle.nat(32)).unwrap() {
    Materialized(value, proof) => (value, proof)
    _ => abort("independent quadratic coordinate budget")
  }
}

///|
/// Gaussian-rational Horner evaluation is independent of Cartesian expansion
/// and its recursive polynomial power/multiplication helpers.
fn cr_review_horner(
  coefficients : Array[(Int32, Int32)],
  x : @exact.Rational,
  y : @exact.Rational,
) -> (@exact.Rational, @exact.Rational) {
  let mut real = @exact.rational_zero()
  let mut imaginary = @exact.rational_zero()
  for offset in 0..<coefficients.length() {
    let coefficient = coefficients[coefficients.length() - offset - 1]
    let next_real = @exact.rational_add(
      @exact.rational_subtract(
        @exact.rational_multiply(real, x),
        @exact.rational_multiply(imaginary, y),
      ),
      @oracle.rational(coefficient.0, coefficient.1),
    )
    imaginary = @exact.rational_add(
      @exact.rational_multiply(real, y),
      @exact.rational_multiply(imaginary, x),
    )
    real = next_real
  }
  (real, imaginary)
}

///|
test "independent complex review Cartesian identity agrees with Gaussian rational Horner" {
  for
    coefficients in [
      [(0, 1)],
      [(-7, 3)],
      [(5, 2), (-3, 4), (1, 3)],
      [(2, 3), (0, 1), (-1, 2), (3, 5), (-2, 7), (1, 1)],
    ] {
    let expansion = cartesian(cr_review_u(coefficients)).unwrap()
    for sample in [((-2, 3), (4, 5)), ((0, 1), (-1, 1)), ((3, 2), (0, 1))] {
      let x = @oracle.rational(sample.0.0, sample.0.1)
      let y = @oracle.rational(sample.1.0, sample.1.1)
      let expected = cr_review_horner(coefficients, x, y)
      let coordinates : @core.Chain[@exact.Rational] = Cons(x, Cons(y, Nil))
      assert_eq(@poly.evaluate(expansion.real, coordinates), Some(expected.0))
      assert_eq(
        @poly.evaluate(expansion.imaginary, coordinates),
        Some(expected.1),
      )
    }
  }
  let zero = cr_review_u([(0, 1)])
  assert_true(prepare(zero) is Err(ZeroPolynomial))
  assert_false(
    check(zero, { source: zero, separation: None, multiplicities: Nil, }),
  )
  assert_true(
    cartesian(@poly.constant(Zero, @exact.rational_one())) is Err(NotUnivariate),
  )
}

///|
test "independent complex review repeated zero binds original scale and every derivative jet" {
  let source = cr_review_u([(0, 1), (0, 1), (1, 1)])
  let value = cr_review_solve(source)
  let proof = certificate(value)
  let first = @core.nth(proof.multiplicities, Zero).unwrap()
  let jets = @oracle.array(first.jets)
  assert_eq(jets.length(), 2)
  assert_eq(first.order, @oracle.nat(2))
  assert_eq(jets[0].real.sign, @core.Equal)
  assert_eq(jets[0].imaginary.sign, @core.Equal)
  assert_eq(jets[1].real.sign, @core.Greater)
  assert_eq(jets[1].imaginary.sign, @core.Equal)
  assert_true(check_result(source, value, proof))

  // All three polynomials have the same zero set and monic squarefree part.
  // Changing the outer source field cannot repair stale derivative witnesses.
  for
    other in [
      cr_review_u([(0, 1), (0, 1), (-3, 1)]),
      cr_review_u([(0, 1), (1, 1)]),
    ] {
    assert_eq(
      squarefree(prepare(other).unwrap()),
      squarefree(prepare(source).unwrap()),
    )
    assert_false(check(other, proof))
    assert_false(check(other, { ..proof, source: other, }))
    assert_false(from_certificate(other, { ..proof, source: other, }) is Ok(_))
  }

  let zero_query = cr_review_u([(0, 1)])
  let false_constant = @tarski.root_sign(first.parameter, cr_review_u([(3, 1)])).unwrap().certificate
  let foreign_root = @real.root_certificate(
    @real.rational(@oracle.rational(1, 1)).unwrap(),
  )
  // Some replacements are independently VALID Tarski proofs, but answer the
  // wrong derivative/query/root. Invalid bit edits cover the sign binding too.
  assert_true(
    @tarski.check_root_sign(
      first.parameter,
      false_constant.query,
      @core.Greater,
      false_constant,
    ),
  )
  let foreign_sign = @tarski.root_sign(foreign_root, zero_query).unwrap().certificate
  assert_true(
    @tarski.check_root_sign(foreign_root, zero_query, @core.Equal, foreign_sign),
  )
  for
    changed in [
      { ..first, order: Zero, },
      { ..first, order: @oracle.nat(3), },
      { ..first, jets: Nil, },
      { ..first, jets: Cons(jets[1], Nil), },
      { ..first, jets: @core.reverse(first.jets), },
      { ..first, jets: @core.append(first.jets, Cons(jets[1], Nil)), },
      {
        ..first,
        jets: Cons({ ..jets[0], real: false_constant, }, Cons(jets[1], Nil)),
      },
      {
        ..first,
        jets: Cons({ ..jets[0], imaginary: foreign_sign, }, Cons(jets[1], Nil)),
      },
      {
        ..first,
        jets: Cons(
          jets[0],
          Cons({ ..jets[1], real: { ..jets[1].real, sign: @core.Less, }, }, Nil),
        ),
      },
      {
        ..first,
        jets: Cons(
          jets[0],
          Cons(
            { ..jets[1], real: { ..jets[1].real, query: zero_query, }, },
            Nil,
          ),
        ),
      },
      {
        ..first,
        jets: Cons(
          jets[0],
          Cons(
            {
              ..jets[1],
              real: {
                ..jets[1].real,
                query_certificate: false_constant.query_certificate,
              },
            },
            Nil,
          ),
        ),
      },
      { ..first, parameter: foreign_root, },
    ] {
    assert_false(
      check(source, { ..proof, multiplicities: Cons(changed, Nil), }),
    )
  }

  // Rebuild an independently checked half-open cover ending exactly at zero.
  // The reduced coordinate expressions are both zero; p'(z)=2z reduces
  // to zero, while p''(z)=2 gives the hand-selected nonzero query below.
  let separation = proof.separation.unwrap()
  let endpoint = @sturm.Interval::{
    lower: @oracle.rational(-1, 1),
    upper: @oracle.rational(0, 1),
  }
  let parameter = { ..first.parameter, interval: endpoint, }
  let sign_zero = @tarski.root_sign(parameter, zero_query).unwrap().certificate
  assert_eq(
    @core.take(two(), separation.solutions.shape.coordinates),
    Cons(zero_query, Cons(zero_query, Nil)),
  )
  let manual_jets : @core.Chain[JetCertificate] = Cons(
    JetCertificate::{ real: sign_zero, imaginary: sign_zero, },
    Cons(
      JetCertificate::{
        real: @tarski.root_sign(parameter, cr_review_u([(2, 1)])).unwrap().certificate,
        imaginary: sign_zero,
      },
      Nil,
    ),
  )
  let endpoint_proof = {
    ..proof,
    separation: Some({
      ..separation,
      solutions: { ..separation.solutions, intervals: Cons(endpoint, Nil), },
    }),
    multiplicities: Cons(
      { parameter, order: @oracle.nat(2), jets: manual_jets, },
      Nil,
    ),
  }
  assert_true(check(source, endpoint_proof))
  let rebuilt = from_certificate(source, endpoint_proof).unwrap()
  assert_true(check_result(source, rebuilt, endpoint_proof))
  let excluded = @sturm.Interval::{
    lower: @oracle.rational(0, 1),
    upper: @oracle.rational(1, 1),
  }
  assert_false(
    check(source, {
      ..endpoint_proof,
      separation: Some({
        ..separation,
        solutions: { ..separation.solutions, intervals: Cons(excluded, Nil), },
      }),
    }),
  )
}

///|
test "independent complex review complete conjugate cover rejects permutations duplicates and context edits" {
  let source = cr_review_u([(2, 1), (-2, 1), (1, 1)])
  let value = cr_review_solve(source)
  let proof = certificate(value)
  let found = @oracle.array(roots(value))
  assert_eq(found.length(), 2)
  let separation = proof.separation.unwrap()
  let intervals = separation.solutions.intervals
  let interval_array = @oracle.array(intervals)
  for
    bad in [
      @core.Nil,
      @core.take(Succ(Zero), intervals),
      @core.reverse(intervals),
      Cons(interval_array[0], Cons(interval_array[0], Nil)),
      @core.append(intervals, intervals),
    ] {
    assert_false(
      check(source, {
        ..proof,
        separation: Some({
          ..separation,
          solutions: { ..separation.solutions, intervals: bad, },
        }),
      }),
    )
  }
  assert_false(
    check(source, {
      ..proof,
      multiplicities: @core.reverse(proof.multiplicities),
    }),
  )
  assert_false(
    check_result(
      source,
      { ..value, roots: @core.reverse(roots(value)), },
      proof,
    ),
  )
  assert_false(
    check_result(
      source,
      { ..value, roots: Cons(found[0], Cons(found[0], Nil)), },
      proof,
    ),
  )
  assert_false(
    check_result(
      source,
      {
        ..value,
        roots: Cons({ ..found[0], point: found[1].point, }, Cons(found[1], Nil)),
      },
      proof,
    ),
  )
  assert_false(
    check_result(
      source,
      {
        ..value,
        roots: Cons(
          { ..found[0], multiplicity: found[1].multiplicity, },
          Cons(found[1], Nil),
        ),
      },
      proof,
    ),
  )
  for projection in [@core.Zero, @core.Succ(@core.Zero), @oracle.nat(3)] {
    assert_false(
      check(source, {
        ..proof,
        separation: Some({ ..separation, projection, }),
      }),
    )
  }
  let coordinates = @oracle.array(separation.solutions.shape.coordinates)
  assert_false(
    check(source, {
      ..proof,
      separation: Some({
        ..separation,
        solutions: {
          ..separation.solutions,
          shape: {
            ..separation.solutions.shape,
            coordinates: @oracle.chain([
              coordinates[1],
              coordinates[0],
              coordinates[2],
            ]),
          },
        },
      }),
    }),
  )
  assert_false(
    check(source, {
      ..proof,
      separation: Some({
        ..separation,
        augmentation: {
          ..separation.augmentation,
          inputs: @core.reverse(separation.augmentation.inputs),
        },
      }),
    }),
  )
  assert_false(
    check(source, {
      ..proof,
      separation: Some({
        ..separation,
        groebner: { ..separation.groebner, combinations: Nil, },
      }),
    }),
  )
  let doubled = cr_review_u([(4, 1), (-4, 1), (2, 1)])
  assert_false(check(doubled, { ..proof, source: doubled, }))
  assert_true(
    check_result(source, from_certificate(source, proof).unwrap(), proof),
  )
}

///|
test "independent complex review materialization binds both coordinates root contexts and exact payloads" {
  let source = cr_review_u([(2, 1), (-2, 1), (1, 1)])
  let set = cr_review_solve(source)
  let found = @oracle.array(roots(set))
  let (number, proof) = cr_review_materialize(found[0])
  let (other, other_proof) = cr_review_materialize(found[1])
  assert_true(check_materialization(found[0], number, proof))
  assert_true(check_materialization(found[1], other, other_proof))
  // The independent closed-form oracle is 1-i,1+i. Verify exact equations
  // and opposite imaginary signs, without trusting the Cartesian producer.
  for value in [number, other] {
    assert_eq(
      @tarski.sign_at(@complex.real_part(value), cr_review_u([(-1, 1), (1, 1)])).unwrap().sign,
      @core.Equal,
    )
    assert_eq(
      @tarski.sign_at(
        @complex.imaginary_part(value),
        cr_review_u([(-1, 1), (0, 1), (1, 1)]),
      ).unwrap().sign,
      @core.Equal,
    )
  }
  let imaginary_sign = @tarski.sign_at(
      @complex.imaginary_part(number),
      cr_review_u([(0, 1), (1, 1)]),
    ).unwrap().sign
  let other_sign = @tarski.sign_at(
      @complex.imaginary_part(other),
      cr_review_u([(0, 1), (1, 1)]),
    ).unwrap().sign
  assert_true(
    (imaginary_sign is Less && other_sign is Greater) ||
    (imaginary_sign is Greater && other_sign is Less),
  )
  assert_false(check_materialization(found[0], other, proof))
  assert_false(check_materialization(found[0], number, other_proof))
  assert_false(
    check_materialization(found[0], number, { ..proof, real: other_proof.real, }),
  )
  assert_false(
    check_materialization(found[0], number, {
      ..proof,
      imaginary: other_proof.imaginary,
    }),
  )
  assert_false(
    check_materialization(
      found[0],
      @complex.number(
        @complex.real_part(number),
        @complex.imaginary_part(other),
      ),
      proof,
    ),
  )
  assert_false(
    check_materialization(found[0], number, {
      ..proof,
      real: { ..proof.real, index: Succ(Zero), },
    }),
  )
  assert_false(
    check_materialization(found[0], number, {
      ..proof,
      imaginary: { ..proof.imaginary, index: Zero, },
    }),
  )
  assert_false(
    check_materialization(found[0], number, {
      ..proof,
      imaginary: { ..proof.imaginary, result: other_proof.imaginary.result, },
    }),
  )
  assert_false(
    check_materialization(found[0], number, {
      ..proof,
      point: other_proof.point,
    }),
  )
  assert_false(
    check_materialization(found[0], number, {
      ..proof,
      source: cr_review_u([(4, 1), (-4, 1), (2, 1)]),
    }),
  )

  // Each coordinate proof still has a legitimate point and valid payload of
  // its own. The complex wrapper must reject mixing those two contexts.
  assert_true(
    @variety.check_coordinate_result(
      @complex.real_part(other),
      other_proof.real,
    ),
  )
  assert_false(
    check_materialization(
      found[0],
      @complex.number(
        @complex.real_part(other),
        @complex.imaginary_part(number),
      ),
      { ..proof, real: other_proof.real, },
    ),
  )

  // Zero fuel is idempotent; splitting every interpolation/refinement unit
  // must retain exactly the same final coordinate representation and proof.
  let initial = match materialize(found[0], Zero).unwrap() {
    MaterializationPaused(state) => state
    _ => abort("zero fuel must pause this quadratic materialization")
  }
  let mut state = initial
  let mut completed = false
  for _ in 0..<32 {
    if !completed {
      assert_true(
        materialize_advance(state, Zero).unwrap() is MaterializationPaused(_),
      )
      match materialize_advance(state, Succ(Zero)).unwrap() {
        MaterializationPaused(next) => state = next
        Materialized(actual, actual_proof) => {
          assert_eq(actual_proof, proof)
          assert_eq(
            @real.root_certificate(@complex.real_part(actual)),
            proof.real.result,
          )
          assert_eq(
            @real.root_certificate(@complex.imaginary_part(actual)),
            proof.imaginary.result,
          )
          assert_true(check_materialization(found[0], actual, actual_proof))
          completed = true
        }
      }
    }
  }
  assert_true(completed)
}

///|
test "independent complex review work and attempt units preserve pending jobs exactly" {
  let source = cr_review_u([(-1, 1), (1, 1)])
  let problem = prepare(source).unwrap()
  let initial = start_from(problem, @binary.zero())
  let zero_work = match run(initial, Succ(Zero), Zero).unwrap() {
    Paused(state, ComputationFuel) => state
    _ => abort("no work has been delegated")
  }
  match zero_work.phase {
    Separating(job) => assert_eq(@variety.attempted(job), Zero)
    _ => fail("nonconstant starts in separation")
  }
  let zero_attempts = match run(zero_work, Zero, Succ(Zero)).unwrap() {
    Paused(state, AttemptLimit) => state
    _ => abort("no new form may start without attempt allowance")
  }
  match zero_attempts.phase {
    Separating(job) => assert_eq(@variety.attempted(job), Zero)
    _ => fail("attempt limit must preserve separation state")
  }
  let mut state = match run(zero_attempts, Succ(Zero), Succ(Zero)).unwrap() {
    Paused(state, ComputationFuel) => state
    _ => abort("one unit starts and retains the linear first form")
  }
  let mut completed = false
  for _ in 0..<64 {
    if !completed {
      match state.phase {
        Separating(job) => assert_eq(@variety.attempted(job), Succ(Zero))
        _ => ()
      }
      match run(state, Zero, Succ(Zero)).unwrap() {
        Paused(next, ComputationFuel) => state = next
        Complete(value) => {
          assert_true(check_result(source, value, certificate(value)))
          assert_eq(@core.length(roots(value)), Succ(Zero))
          completed = true
        }
        _ => fail("resuming a live first form must not charge a second attempt")
      }
    }
  }
  assert_true(completed)

  let conjugate_source = cr_review_u([(1, 1), (0, 1), (1, 1)])
  let expected = cr_review_solve(conjugate_source)
  let separation = certificate(expected).separation.unwrap()
  let conjugate_problem = prepare(conjugate_source).unwrap()
  let points = @variety.projected_points(
    @variety.separation_from_certificate(conjugate_problem.variety, separation).unwrap(),
  ).unwrap()
  let completing = {
    problem: conjugate_problem,
    phase: Completing(separation, points, Nil),
  }
  assert_true(
    run(completing, Zero, Zero).unwrap() is Paused(_, ComputationFuel),
  )
  let halfway = match run(completing, Zero, Succ(Zero)).unwrap() {
    Paused(next, ComputationFuel) => next
    _ => abort("one multiplicity job leaves one pending root")
  }
  match halfway.phase {
    Completing(_, pending, accepted) => {
      assert_eq(@core.length(pending), Succ(Zero))
      assert_eq(@core.length(accepted), Succ(Zero))
    }
    _ => fail("completion phase must retain both lists")
  }
  match run(halfway, Zero, Succ(Zero)).unwrap() {
    Complete(actual) => {
      assert_eq(certificate(actual), certificate(expected))
      assert_true(check_result(conjugate_source, actual, certificate(expected)))
    }
    _ => fail("second multiplicity job exactly completes two roots")
  }
}

///|
test "independent complex review constant and zero certificates cannot cross the nonconstant boundary" {
  let source = cr_review_u([(-7, 3)])
  let constant = match
    run(start(prepare(source).unwrap()), Zero, Zero).unwrap() {
    Complete(value) => value
    _ => abort("nonzero constants complete without work or attempts")
  }
  let proof = certificate(constant)
  assert_true(check_result(source, constant, proof))
  assert_true(roots(constant) is Nil)
  for
    other in [
      cr_review_u([(0, 1)]),
      cr_review_u([(0, 1), (1, 1)]),
      cr_review_u([(1, 1), (0, 1), (1, 1)]),
    ] {
    assert_false(check(other, proof))
    assert_false(check(other, { ..proof, source: other, }))
    assert_false(from_certificate(other, { ..proof, source: other, }) is Ok(_))
  }
  assert_false(check_result(cr_review_u([(7, 3)]), constant, proof))
  let one_root = cr_review_solve(cr_review_u([(0, 1), (1, 1)]))
  assert_false(check(source, { ..certificate(one_root), source, }))
  assert_false(
    check_result(source, { ..constant, roots: roots(one_root), }, proof),
  )
}
