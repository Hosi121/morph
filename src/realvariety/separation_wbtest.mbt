///|
fn test_problem(
  variables : Int32,
  inputs : Array[Array[((Int32, Int32), Array[Int32])]],
) -> Problem {
  problem(
    @oracle.nat(variables),
    @oracle.chain(inputs.map(fn(p) { test_polynomial(variables, p) })),
  ).unwrap()
}

///|
fn grid_problem(a : Int32, b : Int32) -> Problem {
  test_problem(2, [
    [((1, 1), [2, 0]), ((-a, 1), [0, 0])],
    [((1, 1), [0, 2]), ((-b, 1), [0, 0])],
  ])
}

///|
fn test_separate(source : Problem, attempts : Int32) -> SeparatedSet {
  match
    separation_advance(
      separation_start(source),
      @oracle.nat(attempts),
      @oracle.nat(1000),
    ).unwrap() {
    Separated(value) => value
    _ => abort("expected a separated finite system")
  }
}

///|
test "separating grid tries zero one then two and projects exactly four points" {
  let source = grid_problem(1, 1)
  let state = match
    separation_advance(
      separation_start(source),
      @oracle.nat(2),
      @oracle.nat(1000),
    ).unwrap() {
    SeparationPaused(state, AttemptLimit) => state
    _ => abort("first two forms must not be shape")
  }
  assert_eq(@oracle.int_of_nat(attempted(state)), 2)
  assert_eq(@oracle.int_of_binary(next_seed(state)), 2)
  assert_eq(
    @oracle.array(failed_attempts(state)).map(fn(a) {
      @oracle.int_of_binary(a.seed)
    }),
    [0, 1],
  )
  let value = match
    separation_advance(state, Succ(Zero), @oracle.nat(1000)).unwrap() {
    Separated(value) => value
    _ => abort("seed two separates the grid")
  }
  let proof = separation_certificate(value)
  assert_true(check_separation_result(source, value, proof))
  assert_eq(
    proof.solutions.shape.eliminant,
    test_univariate([(9, 1), (0, 1), (-10, 1), (0, 1), (1, 1)]),
  )
  assert_eq(@oracle.int_of_binary(proof.augmentation.seed), 2)
  let points = @oracle.array(projected_points(value).unwrap())
  assert_eq(points.length(), 4)
  let expected = [(-1, -1), (1, -1), (-1, 1), (1, 1)]
  for i in 0..<points.length() {
    assert_eq(@oracle.int_of_nat(projected_dimension(points[i])), 2)
    assert_eq(
      @oracle.array(projected_coordinate_expressions(points[i])).length(),
      2,
    )
    assert_true(
      check_projected_point_result(
        source,
        points[i],
        projected_point_certificate(points[i]),
      ),
    )
    for j in 0..<2 {
      match
        evaluate_projected_coordinate(
          points[i],
          @oracle.nat(j),
          @oracle.nat(100),
        ).unwrap() {
        CoordinateReady(coordinate, certificate) => {
          assert_true(
            check_projected_coordinate_result(
              source,
              points[i],
              coordinate,
              certificate,
            ),
          )
          let expected_value = if j == 0 {
            expected[i].0
          } else {
            expected[i].1
          }
          assert_parameter_equal(
            coordinate,
            @real.rational(@oracle.rational(expected_value, 1)).unwrap(),
          )
        }
        _ => fail("projected coordinate must finish")
      }
    }
    assert_true(
      evaluate_projected_coordinate(points[i], @oracle.nat(2), @oracle.nat(100))
      is Err(InvalidCoordinate),
    )
  }
}

///|
test "independent square roots separate at seed one" {
  let source = grid_problem(2, 3)
  let value = test_separate(source, 2)
  let proof = separation_certificate(value)
  assert_eq(@oracle.int_of_binary(proof.augmentation.seed), 1)
  assert_eq(
    proof.solutions.shape.eliminant,
    test_univariate([(1, 1), (0, 1), (-10, 1), (0, 1), (1, 1)]),
  )
  assert_true(check_separation_result(source, value, proof))
  assert_eq(@oracle.array(projected_points(value).unwrap()).length(), 4)
}

///|
test "nonradical and positive dimensional searches pause without false no-solutions" {
  let nonradical = grid_problem(0, 0)
  let state = match
    separation_advance(
      separation_start(nonradical),
      @oracle.nat(3),
      @oracle.nat(1000),
    ).unwrap() {
    SeparationPaused(state, AttemptLimit) => state
    _ => abort("nonmonogenic local algebra must not be silently solved")
  }
  assert_eq(@oracle.int_of_nat(attempted(state)), 3)
  assert_eq(@oracle.array(failed_attempts(state)).length(), 3)
  assert_true(
    separation_advance(state, Succ(Zero), @oracle.nat(1000)).unwrap()
    is SeparationPaused(_, AttemptLimit),
  )
  let positive = test_problem(2, [[((1, 1), [1, 0]), ((-1, 1), [0, 1])]])
  assert_true(
    separation_advance(
      separation_start(positive),
      @oracle.nat(2),
      @oracle.nat(1000),
    ).unwrap()
    is SeparationPaused(_, AttemptLimit),
  )
}

///|
test "attempt and computation fuel resume the exact candidate" {
  let source = grid_problem(2, 3)
  assert_true(
    separation_advance(separation_start(source), Zero, @oracle.nat(100)).unwrap()
    is SeparationPaused(_, AttemptLimit),
  )
  let state = match
    separation_advance(separation_start(source), Succ(Zero), Zero).unwrap() {
    SeparationPaused(state, ComputationFuel) => state
    _ => abort("zero work fuel must retain F4 work")
  }
  assert_eq(@oracle.int_of_nat(attempted(state)), 1)
  let first_done = match
    separation_advance(state, Zero, @oracle.nat(1000)).unwrap() {
    SeparationPaused(state, AttemptLimit) => state
    _ => abort("resuming cannot start an unauthorized extra attempt")
  }
  assert_eq(@oracle.int_of_nat(attempted(first_done)), 1)
  let second = match
    separation_advance(first_done, Succ(Zero), Succ(Zero)).unwrap() {
    SeparationPaused(state, ComputationFuel) => state
    _ => abort("one F4 step does not finish seed one")
  }
  assert_eq(@oracle.int_of_nat(attempted(second)), 2)
  match separation_advance(second, Zero, @oracle.nat(1000)).unwrap() {
    Separated(value) => {
      assert_true(
        check_separation_result(source, value, separation_certificate(value)),
      )
      assert_eq(
        @oracle.int_of_binary(separation_certificate(value).augmentation.seed),
        1,
      )
    }
    _ => fail("same candidate should resume to completion")
  }
}

///|
test "separation proofs bind exact source augmentation graph F4 inputs and projection" {
  let source = grid_problem(1, 1)
  let other_source = grid_problem(2, 3)
  let value = test_separate(source, 3)
  let other_value = test_separate(other_source, 2)
  let proof = separation_certificate(value)
  let other = separation_certificate(other_value)
  assert_true(check_separation(source, proof))
  assert_false(check_separation(other_source, proof))
  assert_false(check_separation_result(source, other_value, proof))
  assert_false(
    check_augmentation(other_source, {
      ..proof.augmentation,
      source: problem_description(other_source),
    }),
  )
  assert_false(
    check_separation(other_source, {
      ..proof,
      augmentation: augment(other_source, proof.augmentation.seed).unwrap(),
    }),
  )
  assert_false(check_separation(source, { ..proof, groebner: other.groebner, }))
  assert_false(
    check_separation(source, {
      ..proof,
      groebner: other.groebner,
      solutions: other.solutions,
    }),
  )
  assert_false(check_separation(source, { ..proof, projection: Succ(Zero), }))
  assert_false(
    check_separation(source, {
      ..proof,
      augmentation: { ..proof.augmentation, variables: @oracle.nat(4), },
    }),
  )
  assert_false(
    check_augmentation(source, {
      ..proof.augmentation,
      seed: @oracle.binary(1),
    }),
  )
  assert_false(
    check_augmentation(source, {
      ..proof.augmentation,
      relation: @poly.zero(@oracle.nat(3)),
    }),
  )
  assert_false(
    check_augmentation(source, {
      ..proof.augmentation,
      inputs: @core.reverse(proof.augmentation.inputs),
    }),
  )
  assert_false(
    check_separation(source, {
      ..proof,
      solutions: {
        ..proof.solutions,
        intervals: @core.drop(Succ(Zero), proof.solutions.intervals),
      },
    }),
  )
  assert_true(
    separation_from_certificate(other_source, proof) is Err(InvalidCertificate),
  )
  let point = @oracle.array(projected_points(value).unwrap())[0]
  let other_point = @oracle.array(projected_points(other_value).unwrap())[0]
  assert_false(
    check_projected_point(other_source, projected_point_certificate(point)),
  )
  assert_false(
    check_projected_point_result(
      source,
      other_point,
      projected_point_certificate(point),
    ),
  )
  match evaluate_projected_coordinate(point, Zero, @oracle.nat(100)).unwrap() {
    CoordinateReady(coordinate, certificate) => {
      assert_true(
        check_projected_coordinate_result(
          source, point, coordinate, certificate,
        ),
      )
      assert_false(
        check_projected_coordinate_result(
          other_source, point, coordinate, certificate,
        ),
      )
      assert_false(
        check_projected_coordinate_result(
          source, other_point, coordinate, certificate,
        ),
      )
    }
    _ => fail("source coordinate must materialize")
  }
  match
    evaluate_coordinate(point.full, @oracle.nat(2), @oracle.nat(100)).unwrap() {
    CoordinateReady(auxiliary, certificate) => {
      assert_true(check_coordinate_result(auxiliary, certificate))
      assert_false(
        check_projected_coordinate_result(source, point, auxiliary, certificate),
      )
    }
    _ => fail("auxiliary t coordinate must materialize")
  }
}

///|
test "unit graph certificates and a real-empty separated set remain distinct" {
  let unit = test_problem(1, [[((1, 1), [1])], [((1, 1), [1]), ((-1, 1), [0])]])
  let different_unit = test_problem(1, [
    [((1, 1), [1])],
    [((1, 1), [1]), ((-2, 1), [0])],
  ])
  match
    separation_advance(separation_start(unit), Succ(Zero), @oracle.nat(100)).unwrap() {
    SeparationNoSolutions(proof) => {
      assert_true(check_separation_unit(unit, proof))
      assert_false(check_separation_unit(different_unit, proof))
      assert_false(
        check_separation_unit(different_unit, {
          ..proof,
          augmentation: augment(different_unit, proof.augmentation.seed).unwrap(),
        }),
      )
      assert_false(check_separation_unit(unit, { ..proof, projection: Zero, }))
    }
    _ => fail("unit original system has no augmented solutions")
  }
  let empty_real = grid_problem(-1, -1)
  let value = test_separate(empty_real, 3)
  assert_eq(@oracle.array(projected_points(value).unwrap()).length(), 0)
  assert_true(
    check_separation_result(empty_real, value, separation_certificate(value)),
  )
  assert_eq(
    separation_certificate(value).solutions.shape.eliminant,
    test_univariate([(9, 1), (0, 1), (10, 1), (0, 1), (1, 1)]),
  )
}

///|
test "augmentation keeps all exponent positions and signed rational coefficients" {
  let source = test_problem(3, [[((2, 3), [2, 0, 1]), ((-5, 7), [0, 3, 0])]])
  let augmented = augment(source, @oracle.binary(2)).unwrap()
  assert_true(check_augmentation(source, augmented))
  assert_eq(@oracle.int_of_nat(augmented.variables), 4)
  assert_eq(
    @oracle.array(augmented.inputs)[0],
    test_polynomial(4, [((2, 3), [2, 0, 1, 0]), ((-5, 7), [0, 3, 0, 0])]),
  )
  assert_eq(
    augmented.relation,
    test_polynomial(4, [
      ((1, 1), [0, 0, 0, 1]),
      ((-1, 1), [1, 0, 0, 0]),
      ((-2, 1), [0, 1, 0, 0]),
      ((-4, 1), [0, 0, 1, 0]),
    ]),
  )
  let zero_seed = augment(source, @oracle.binary(0)).unwrap()
  assert_eq(
    zero_seed.relation,
    test_polynomial(4, [((1, 1), [0, 0, 0, 1]), ((-1, 1), [1, 0, 0, 0])]),
  )
  assert_true(problem(Zero, Nil) is Err(DimensionMismatch))
  assert_true(
    problem(@oracle.nat(2), problem_description(source).inputs)
    is Err(DimensionMismatch),
  )
}

///|
fn assert_search_fixture(
  variables : Int32,
  inputs : Array[Array[((Int32, Int32), Array[Int32])]],
  attempts : Int32,
  seed : Int32,
  originally_shape : Bool,
  eliminant : Array[(Bool, String, String)],
  coordinates : Array[Array[(Bool, String, String)]],
  intervals : Array[((Bool, String, String), (Bool, String, String))],
) -> Unit raise {
  let source = test_problem(variables, inputs)
  let original_basis = test_basis(variables, inputs)
  assert_eq(
    from_basis(original_basis).unwrap() is ShapeReady(_),
    originally_shape,
  )
  let value = test_separate(source, attempts)
  let proof = separation_certificate(value)
  assert_eq(@oracle.int_of_binary(proof.augmentation.seed), seed)
  assert_true(check_separation_result(source, value, proof))
  assert_eq(proof.solutions.shape.eliminant, test_big_univariate(eliminant))
  assert_eq(
    @oracle.array(
      @core.take(@oracle.nat(variables), proof.solutions.shape.coordinates),
    ),
    coordinates.map(test_big_univariate),
  )
  let projected = @oracle.array(projected_points(value).unwrap())
  assert_eq(projected.length(), intervals.length())
  for i in 0..<projected.length() {
    let pair = intervals[i]
    let expected = @real.number({
      polynomial: test_big_univariate(eliminant),
      interval: {
        lower: test_big_rational(pair.0),
        upper: test_big_rational(pair.1),
      },
    }).unwrap()
    assert_parameter_equal(projected_parameter(projected[i]), expected)
    assert_eq(
      @oracle.array(projected_coordinate_expressions(projected[i])),
      coordinates.map(test_big_univariate),
    )
    assert_true(
      check_projected_point_result(
        source,
        projected[i],
        projected_point_certificate(projected[i]),
      ),
    )
  }
}

///|
fn assert_search_stopped_fixture(
  variables : Int32,
  inputs : Array[Array[((Int32, Int32), Array[Int32])]],
  attempts : Int32,
  unit : Bool,
) -> Unit raise {
  let source = test_problem(variables, inputs)
  match
    separation_advance(
      separation_start(source),
      @oracle.nat(attempts),
      @oracle.nat(1000),
    ).unwrap() {
    SeparationPaused(state, AttemptLimit) => {
      assert_false(unit)
      assert_eq(@oracle.int_of_nat(attempted(state)), attempts)
      assert_eq(@oracle.array(failed_attempts(state)).length(), attempts)
    }
    SeparationNoSolutions(proof) => {
      assert_true(unit)
      assert_true(check_separation_unit(source, proof))
    }
    _ => fail("bounded unsupported/unit search expected")
  }
}
