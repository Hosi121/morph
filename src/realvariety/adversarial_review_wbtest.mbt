///|
fn rv_review_small(values : Array[Int32]) -> @poly.Polynomial {
  rv_review_u(values.map(fn(value) { @oracle.rational(value, 1) }))
}

///|
fn rv_review_main_inputs() -> Array[@poly.Polynomial] {
  [
    rv_review_p(2, [
      (@oracle.rational(1, 1), [1, 0]),
      (@oracle.rational(-1, 1), [0, 2]),
      (@oracle.rational(1, 1), [0, 0]),
    ]),
    rv_review_p(2, [
      (@oracle.rational(1, 1), [0, 3]),
      (@oracle.rational(-3, 1), [0, 2]),
      (@oracle.rational(2, 1), [0, 1]),
    ]),
  ]
}

///|
fn rv_review_embed(value : @poly.Polynomial) -> @poly.Polynomial {
  @poly.polynomial(
    @oracle.nat(2),
    @core.map(@poly.terms(value), fn(term) {
      { ..term, exponents: @core.Cons(@core.Zero, term.exponents), }
    }),
  ).unwrap()
}

///|
test "independent realvariety review proves both ideal directions and binds verified F4 inputs" {
  let inputs = rv_review_main_inputs()
  let basis = rv_review_basis(2, inputs)
  let shape = rv_review_shape(basis)
  let proof = shape_certificate(shape)
  assert_true(check_basis_shape(basis, proof))
  let changed_inputs = @oracle.chain([
    inputs[0],
    rv_review_embed(@poly.add(proof.eliminant, rv_review_small([1])).unwrap()),
  ])
  assert_false(
    @f4.check(@oracle.nat(2), changed_inputs, @f4.certificate(basis)).unwrap(),
  )

  let extra = rv_review_p(2, [(@oracle.rational(1, 1), [1, 0])])
  // The selected shape rows still exist, but the extra basis equation rejects
  // parameters0 and2. Only checking selected rows would miss this restriction.
  assert_false(check_shape({ ..proof, basis: @core.Cons(extra, proof.basis), }))
  let restricted = rv_review_basis(2, [extra, ..inputs])
  assert_false(check_basis_shape(restricted, proof))
  assert_eq(
    @oracle.array(
      points(rv_review_solutions(rv_review_shape(restricted))).unwrap(),
    ).length(),
    1,
  )
  let old_solutions = rv_review_solutions(shape)
  assert_false(
    check_basis_solutions(restricted, solution_certificate(old_solutions)),
  )
  // Retaining only generators that vanish modulo g is not enough: selected
  // coordinate provenance must still come from the supplied basis.
  assert_false(
    check_shape({
      ..proof,
      basis: @core.Cons(proof.eliminant_source, @core.Nil),
    }),
  )
  assert_false(check_shape({ ..proof, basis: proof.coordinate_sources, }))
  assert_false(check_shape({ ..proof, coordinate_sources: @core.Nil, }))
  let factor = rv_review_small([0, -1, 1])
  assert_false(check_shape({ ..proof, eliminant: factor, }))
  let factor_source = rv_review_embed(factor)
  assert_false(
    check_shape({ ..proof, eliminant: factor, eliminant_source: factor_source, }),
  )
  // This altered RAW problem really adds g'(t)=0 and thus removes parameter2.
  // It is valid for its own equations, but must not certify the original basis.
  let narrowed = {
    ..proof,
    basis: @core.Cons(factor_source, proof.basis),
    eliminant: factor,
    eliminant_source: factor_source,
    coordinates: @oracle.chain([
      rv_review_small([-1, 1]),
      rv_review_small([0, 1]),
    ]),
  }
  assert_true(check_shape(narrowed))
  assert_false(check_basis_shape(basis, narrowed))
  // Conversely, proposed g(t)*(t-3) is an actual added row, but the original g
  // does not vanish modulo it, so the full-basis substitution check rejects it.
  let larger = @poly.multiply(proof.eliminant, rv_review_small([-3, 1])).unwrap()
  let larger_source = rv_review_embed(larger)
  assert_false(
    check_shape({
      ..proof,
      basis: @core.Cons(larger_source, proof.basis),
      eliminant: larger,
      eliminant_source: larger_source,
    }),
  )
  // A redundant consequence changes the raw row list but not the ideal.
  let redundant = @poly.multiply(inputs[0], inputs[1]).unwrap()
  let extended = { ..proof, basis: @core.Cons(redundant, proof.basis), }
  assert_true(check_shape(extended))
  assert_false(check_basis_shape(basis, extended))
  let changed_h = @poly.add(
    @oracle.array(proof.coordinates)[0],
    rv_review_small([1]),
  ).unwrap()
  assert_false(
    check_shape({
      ..proof,
      coordinates: @core.Cons(
        changed_h,
        @core.Cons(rv_review_small([0, 1]), @core.Nil),
      ),
    }),
  )
}

///|
test "independent realvariety review unit evidence is portable only through a verified matching unit basis" {
  let shape_basis = rv_review_basis(2, rv_review_main_inputs())
  let x = rv_review_p(2, [(@oracle.rational(1, 1), [1, 0])])
  let x_minus_one = rv_review_p(2, [
    (@oracle.rational(1, 1), [1, 0]),
    (@oracle.rational(-1, 1), [0, 0]),
  ])
  let x_minus_two = rv_review_p(2, [
    (@oracle.rational(1, 1), [1, 0]),
    (@oracle.rational(-2, 1), [0, 0]),
  ])
  let unit1 = rv_review_basis(2, [x, x_minus_one])
  let unit2 = rv_review_basis(2, [x, x_minus_two])
  let proof = match start_basis(unit1).unwrap() {
    NoSolutions(proof) => proof
    _ => abort("review unit basis")
  }
  assert_true(check_unit(proof))
  assert_true(check_basis_unit(unit1, proof))
  // Both original ideals independently certify the same reduced unit basis.
  assert_true(check_basis_unit(unit2, proof))
  assert_false(check_basis_unit(shape_basis, proof))
  assert_false(check_unit({ ..proof, witness: @poly.zero(@oracle.nat(2)), }))
  assert_false(check_unit({ ..proof, basis: @core.Nil, }))
  let foreign_constant = @poly.constant(@oracle.nat(2), @oracle.rational(7, 13))
  assert_false(check_unit({ ..proof, witness: foreign_constant, }))
  assert_true(
    check_unit({
      ..proof,
      basis: @core.Cons(foreign_constant, proof.basis),
      witness: foreign_constant,
    }),
  )
  assert_false(
    check_basis_unit(shape_basis, {
      ..proof,
      basis: @core.Cons(foreign_constant, proof.basis),
      witness: foreign_constant,
    }),
  )
}

///|
test "independent realvariety review complete root covers allow touching and reject missing duplicated or foreign roots" {
  let basis = rv_review_basis(2, rv_review_main_inputs())
  let shape = rv_review_shape(basis)
  let solutions = rv_review_solutions(shape)
  let good = solution_certificate(solutions)
  let intervals = @oracle.chain([
    @sturm.Interval::{
      lower: @oracle.rational(-1, 1),
      upper: @oracle.rational(0, 1),
    },
    @sturm.Interval::{
      lower: @oracle.rational(0, 1),
      upper: @oracle.rational(1, 1),
    },
    @sturm.Interval::{
      lower: @oracle.rational(1, 1),
      upper: @oracle.rational(2, 1),
    },
  ])
  // No open-cell samples are needed in RUR, so strict gaps are unnecessary.
  let touching = { ..good, intervals, }
  assert_true(check_solutions(touching))
  let alternative = solutions_from_certificate(touching).unwrap()
  assert_true(check_solutions_result(alternative, touching))
  assert_eq(@oracle.array(points(alternative).unwrap()).length(), 3)
  for
    bad in [
      @core.Nil,
      @core.take(@oracle.nat(2), intervals),
      @core.reverse(intervals),
      @core.append(intervals, intervals),
    ] {
    assert_false(check_solutions({ ..good, intervals: bad, }))
  }
  let array = @oracle.array(intervals)
  assert_false(
    check_solutions({
      ..good,
      intervals: @oracle.chain([array[0], array[0], array[2]]),
    }),
  )
  assert_false(
    check_solutions({
      ..good,
      intervals: @oracle.chain([
        array[0],
        array[1],
        @sturm.Interval::{
          lower: @oracle.rational(2, 1),
          upper: @oracle.rational(3, 1),
        },
      ]),
    }),
  )
  let points = @oracle.array(points(alternative).unwrap())
  let first = point_certificate(points[0])
  assert_true(check_point(first))
  let foreign = @real.rational(@oracle.rational(3, 1)).unwrap()
  assert_true(@real.check_root(@real.root_certificate(foreign)))
  assert_false(
    check_point({ ..first, parameter: @real.root_certificate(foreign), }),
  )
  assert_false(check_point_result(points[1], first))
  let refined = @real.refine(parameter(points[0]), @oracle.nat(1)).unwrap()
  let same_value = { ..points[0], parameter: refined, }
  assert_true(check_point(point_certificate(same_value)))
  assert_false(check_point_result(same_value, first))
  assert_false(
    check_solutions_result(alternative, { ..good, intervals: @core.Nil, }),
  )
}

///|
test "independent realvariety review norm samples degree cap and result payload all have separate obligations" {
  let shape = rv_review_shape(rv_review_basis(2, rv_review_main_inputs()))
  let solutions = rv_review_solutions(shape)
  let pts = @oracle.array(points(solutions).unwrap())
  let (value, proof) = rv_review_coordinate(pts[0], 0)
  assert_true(check_coordinate_result(value, proof))
  let (wrong, other_proof) = rv_review_coordinate(pts[2], 0)
  assert_true(check_coordinate_result(wrong, other_proof))
  assert_false(check_coordinate_result(wrong, proof))
  assert_false(check_coordinate({ ..proof, point: point_certificate(pts[2]), }))
  assert_false(check_coordinate({ ..proof, index: @oracle.nat(1), }))
  assert_false(check_coordinate({ ..proof, index: @oracle.nat(2), }))
  let samples = @oracle.array(proof.samples)
  assert_false(check_coordinate({ ..proof, samples: @core.Nil, }))
  assert_false(
    check_coordinate({
      ..proof,
      samples: @core.append(
        proof.samples,
        @core.Cons(@exact.rational_zero(), @core.Nil),
      ),
    }),
  )
  let changed = samples.copy()
  changed[0] = @exact.rational_add(changed[0], @exact.rational_one())
  assert_false(check_coordinate({ ..proof, samples: @oracle.chain(changed), }))
  let vanish = rv_review_small([0, -6, 11, -6, 1])
  let forged = @poly.add(proof.polynomial, vanish).unwrap()
  for i in 0..<4 {
    assert_eq(
      @poly.evaluate(forged, @core.Cons(@oracle.rational(i, 1), @core.Nil)),
      Some(samples[i]),
    )
  }
  assert_false(check_coordinate({ ..proof, polynomial: forged, }))
  assert_false(check_coordinate({ ..proof, result: other_proof.result, }))
  assert_false(
    check_coordinate({
      ..proof,
      refined: point_certificate(pts[2]).parameter.interval,
    }),
  )
  let payload = CoordinateReady(wrong, proof)
  match payload {
    CoordinateReady(number, certificate) =>
      assert_false(check_coordinate_result(number, certificate))
    _ => fail("review payload shape")
  }
}

///|
test "independent realvariety review nonradical norm keeps multiplicities even when the zero set is unchanged" {
  let inputs = [
    rv_review_p(2, [(@oracle.rational(1, 1), [1, 0])]),
    rv_review_p(2, [(@oracle.rational(1, 1), [0, 4])]),
  ]
  let shape = rv_review_shape(rv_review_basis(2, inputs))
  let points = @oracle.array(points(rv_review_solutions(shape)).unwrap())
  assert_eq(points.length(), 1)
  let (value, proof) = rv_review_coordinate(points[0], 0)
  assert_eq(proof.polynomial, rv_review_small([0, 0, 0, 0, 1]))
  assert_true(check_coordinate_result(value, proof))
  let reduced = rv_review_small([0, 1])
  let forged_samples = @oracle.chain(
    [
      for i in 0..<5 => @oracle.rational(i, 1)
    ],
  )
  // Same valid Number root0 and same degree<=4, but not the norm polynomial.
  assert_false(
    check_coordinate({ ..proof, polynomial: reduced, samples: forged_samples, }),
  )
  assert_false(check_coordinate({ ..proof, polynomial: reduced, }))
  assert_true(@real.check_root(proof.result))
}

///|
test "independent realvariety review all coordinate fuel boundaries separate sampling from conjugate refinement" {
  let inputs = [
    rv_review_p(2, [
      (@oracle.rational(1, 1), [1, 0]),
      (@oracle.rational(-1, 1), [0, 1]),
    ]),
    rv_review_p(2, [
      (@oracle.rational(1, 1), [0, 3]),
      (@oracle.rational(-3, 1), [0, 2]),
      (@oracle.rational(2, 1), [0, 1]),
    ]),
  ]
  let shape = rv_review_shape(rv_review_basis(2, inputs))
  let point = point_from_certificate({
    shape: shape_certificate(shape),
    parameter: {
      polynomial: @sturm.squarefree(shape.system),
      interval: {
        lower: @oracle.rational(0, 1),
        upper: @oracle.rational(1, 1),
      },
    },
  }).unwrap()
  let initial = coordinate_start(point, @oracle.nat(0)).unwrap()
  let (expected, expected_proof) = match
    coordinate_advance(initial, @oracle.nat(5)).unwrap() {
    CoordinateReady(value, proof) => (value, proof)
    _ => abort("review degree3 needs4 samples and one root refinement")
  }
  assert_true(check_coordinate_result(expected, expected_proof))
  assert_eq(expected_proof.refined.lower, @oracle.rational(1, 2))
  assert_eq(expected_proof.refined.upper, @oracle.rational(1, 1))
  assert_eq(expected_proof.result.interval.lower, @oracle.rational(0, 1))
  assert_eq(expected_proof.result.interval.upper, @oracle.rational(3, 2))
  for fuel in 0..<5 {
    let paused = match coordinate_advance(initial, @oracle.nat(fuel)).unwrap() {
      CoordinatePaused(state) => state
      _ => abort("review must preserve incomplete sampling/refinement")
    }
    if fuel < 4 {
      assert_eq(@oracle.int_of_nat(paused.point), fuel)
      assert_eq(@oracle.int_of_nat(paused.remaining), 4 - fuel)
    } else {
      assert_eq(@oracle.int_of_nat(paused.remaining), 0)
      assert_true(paused.output is Some(_))
    }
    assert_true(
      coordinate_advance(paused, @oracle.nat(0)).unwrap() is CoordinatePaused(_),
    )
    match coordinate_advance(paused, @oracle.nat(5 - fuel)).unwrap() {
      CoordinateReady(value, proof) => {
        assert_eq(proof, expected_proof)
        assert_eq(
          @real.root_certificate(value),
          @real.root_certificate(expected),
        )
      }
      _ => fail("review resumed coordinate changed completion boundary")
    }
  }
  for fuel in [5, 6, 20] {
    match coordinate_advance(initial, @oracle.nat(fuel)).unwrap() {
      CoordinateReady(value, proof) => {
        assert_eq(proof, expected_proof)
        assert_true(check_coordinate_result(value, proof))
      }
      _ => fail("review surplus fuel must complete identically")
    }
  }
  let foreign_point_proof = {
    ..expected_proof,
    point: {
      ..point_certificate(point),
      parameter: {
        polynomial: @sturm.squarefree(shape.system),
        interval: {
          lower: @oracle.rational(1, 1),
          upper: @oracle.rational(2, 1),
        },
      },
    },
  }
  assert_true(check_point(foreign_point_proof.point))
  assert_false(check_coordinate(foreign_point_proof))
}
