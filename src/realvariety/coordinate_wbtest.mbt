///|
fn test_big_rational(value : (Bool, String, String)) -> @exact.Rational {
  let magnitude = @exact.positive(@oracle.binary_from_hex(value.1))
  let numerator = if value.0 { @exact.negate(magnitude) } else { magnitude }
  @exact.ratio(numerator, @oracle.binary_from_hex(value.2)).unwrap()
}

///|
fn test_big_univariate(
  values : Array[(Bool, String, String)],
) -> @poly.Polynomial {
  @poly.polynomial(
    Succ(Zero),
    @oracle.chain(
      values.mapi(fn(i, c) {
        {
          coefficient: test_big_rational(c),
          exponents: Cons(@oracle.nat(i), Nil),
        }
      }),
    ),
  ).unwrap()
}

///|
fn assert_coordinate_fixture(
  variables : Int32,
  inputs : Array[Array[((Int32, Int32), Array[Int32])]],
  point_index : Int32,
  coordinate_index : Int32,
  characteristic : Array[(Bool, String, String)],
  minimum : Array[(Bool, String, String)],
  lower : (Bool, String, String),
  upper : (Bool, String, String),
) -> Unit raise {
  let shape = test_shape(test_basis(variables, inputs))
  let solutions = test_solutions(shape)
  let point = @oracle.array(points(solutions).unwrap())[point_index]
  let expected = @real.number({
    polynomial: test_big_univariate(minimum),
    interval: {
      lower: test_big_rational(lower),
      upper: test_big_rational(upper),
    },
  }).unwrap()
  match
    evaluate_coordinate(point, @oracle.nat(coordinate_index), @oracle.nat(256)).unwrap() {
    CoordinateReady(value, proof) => {
      assert_true(check_coordinate_result(value, proof))
      assert_eq(proof.polynomial, test_big_univariate(characteristic))
      assert_parameter_equal(value, expected)
      assert_true(
        @core.compare(
          univariate_degree(proof.polynomial).unwrap(),
          univariate_degree(shape_certificate(shape).eliminant).unwrap(),
        ) !=
        Greater,
      )
      assert_false(
        check_coordinate_result(
          @real.rational(@oracle.rational(7, 1)).unwrap(),
          proof,
        ),
      )
    }
    _ => fail("coordinate materialization unexpectedly paused")
  }
}

///|
test "coordinate sample fuel boundary and result payload binding are explicit" {
  let shape = test_shape(
    test_basis(2, [
      [((1, 1), [1, 0]), ((-1, 1), [0, 2])],
      [((1, 1), [0, 2]), ((-2, 1), [0, 0])],
    ]),
  )
  let solutions = test_solutions(shape)
  let point = @oracle.array(points(solutions).unwrap())[0]
  assert_true(
    check_solutions_result(solutions, solution_certificate(solutions)),
  )
  assert_true(check_point_result(point, point_certificate(point)))
  let initial = coordinate_start(point, Zero).unwrap()
  assert_true(coordinate_advance(initial, Zero).unwrap() is CoordinatePaused(_))
  let state = match coordinate_advance(initial, @oracle.nat(2)).unwrap() {
    CoordinatePaused(state) => state
    _ => abort("degree two requires three characteristic samples")
  }
  match coordinate_advance(state, Succ(Zero)).unwrap() {
    CoordinateReady(value, proof) => {
      assert_true(check_coordinate_result(value, proof))
      assert_parameter_equal(
        value,
        @real.rational(@oracle.rational(2, 1)).unwrap(),
      )
      let wrong = @real.rational(@oracle.rational(3, 1)).unwrap()
      let forged = CoordinateReady(wrong, proof)
      match forged {
        CoordinateReady(payload, proof) =>
          assert_false(check_coordinate_result(payload, proof))
        _ => fail("forged progress")
      }
      assert_false(check_coordinate({ ..proof, samples: Nil, }))
      assert_false(check_coordinate({ ..proof, index: @oracle.nat(2), }))
    }
    _ => fail("constant coordinate needs no extra refinement")
  }
  assert_true(
    evaluate_coordinate(point, @oracle.nat(2), @oracle.nat(100))
    is Err(InvalidCoordinate),
  )
}

///|
test "coordinate checker rejects a valid wrong conjugate and out-of-source refinement" {
  let shape = test_shape(
    test_basis(2, [
      [((1, 1), [1, 0]), ((-1, 1), [0, 1])],
      [((1, 1), [0, 2]), ((-2, 1), [0, 0])],
    ]),
  )
  let solutions = test_solutions(shape)
  let points = @oracle.array(points(solutions).unwrap())
  assert_false(check_point_result(points[0], point_certificate(points[1])))
  match evaluate_coordinate(points[1], Zero, @oracle.nat(100)).unwrap() {
    CoordinateReady(value, proof) => {
      assert_true(check_coordinate_result(value, proof))
      let negative = @real.root_certificate(parameter(points[0]))
      assert_true(@real.check_root(negative))
      assert_false(check_coordinate({ ..proof, result: negative, }))
      assert_false(check_coordinate({ ..proof, refined: negative.interval, }))
      let vanish = @poly.multiply(
        test_univariate([(0, 1), (1, 1)]),
        @poly.multiply(
          test_univariate([(-1, 1), (1, 1)]),
          test_univariate([(-2, 1), (1, 1)]),
        ).unwrap(),
      ).unwrap()
      let forged = @poly.add(proof.polynomial, vanish).unwrap()
      for x in 0..<3 {
        assert_eq(
          @poly.evaluate(forged, Cons(@oracle.rational(x, 1), Nil)),
          @poly.evaluate(proof.polynomial, Cons(@oracle.rational(x, 1), Nil)),
        )
      }
      assert_false(check_coordinate({ ..proof, polynomial: forged, }))
    }
    _ => fail("positive coordinate must finish")
  }
}

///|
test "coordinate refinement phase pauses after samples and zero coordinates remain exact" {
  let basis = test_basis(2, [
    [((1, 1), [1, 0])],
    [((1, 1), [0, 2]), ((-2, 1), [0, 0])],
  ])
  let shape = test_shape(basis)
  let point = @oracle.array(points(test_solutions(shape)).unwrap())[1]
  match evaluate_coordinate(point, Zero, @oracle.nat(3)).unwrap() {
    CoordinateReady(value, proof) => {
      assert_eq(proof.polynomial, test_univariate([(0, 1), (0, 1), (1, 1)]))
      assert_true(check_coordinate_result(value, proof))
      assert_parameter_equal(
        value,
        @real.rational(@oracle.rational(0, 1)).unwrap(),
      )
    }
    _ => fail("zero coordinate should finish immediately after three samples")
  }
  let initial = coordinate_start(point, Succ(Zero)).unwrap()
  let state = match coordinate_advance(initial, @oracle.nat(3)).unwrap() {
    CoordinatePaused(state) => state
    _ => abort("wide coordinate enclosure must retain refinement work")
  }
  match coordinate_advance(state, @oracle.nat(20)).unwrap() {
    CoordinateReady(value, proof) => {
      assert_true(check_coordinate_result(value, proof))
      assert_parameter_equal(value, parameter(point))
    }
    _ => fail("coordinate refinement did not finish")
  }
}

///|
test "large coordinate powers reduce before materialization and keep degree bound" {
  let inputs = [
    test_polynomial(2, [((1, 1), [1, 0]), ((-1, 1), [0, 17])]),
    test_polynomial(2, [((1, 1), [0, 2]), ((-2, 1), [0, 0])]),
  ]
  let shape = match extract(@oracle.nat(2), @oracle.chain(inputs)).unwrap() {
    ShapeReady(shape) => shape
    _ => abort("explicit high-power shape must be accepted")
  }
  assert_eq(
    @oracle.array(shape_certificate(shape).coordinates)[0],
    test_univariate([(0, 1), (256, 1)]),
  )
  let point = @oracle.array(points(test_solutions(shape)).unwrap())[1]
  match evaluate_coordinate(point, Zero, @oracle.nat(100)).unwrap() {
    CoordinateReady(value, proof) => {
      assert_eq(
        proof.polynomial,
        test_univariate([(-131072, 1), (0, 1), (1, 1)]),
      )
      assert_true(check_coordinate_result(value, proof))
      let expected = @real.number({
        polynomial: proof.polynomial,
        interval: {
          lower: @oracle.rational(362, 1),
          upper: @oracle.rational(363, 1),
        },
      }).unwrap()
      assert_parameter_equal(value, expected)
    }
    _ => fail("high-power coordinate must materialize")
  }
}

///|
test "unit and solution payload certificates are bound to the requested basis" {
  let unit_basis = test_basis(2, [
    [((1, 1), [1, 0])],
    [((1, 1), [0, 1])],
    [((1, 1), [1, 0]), ((-1, 1), [0, 0])],
  ])
  let shape_basis = test_basis(2, [
    [((1, 1), [1, 0]), ((-1, 1), [0, 1])],
    [((1, 1), [0, 2]), ((-2, 1), [0, 0])],
  ])
  match start_basis(unit_basis).unwrap() {
    NoSolutions(proof) => {
      assert_true(check_basis_unit(unit_basis, proof))
      assert_false(check_basis_unit(shape_basis, proof))
    }
    _ => fail("unit ideal expected")
  }
  let solutions = test_solutions(test_shape(shape_basis))
  assert_true(
    check_solutions_result(solutions, solution_certificate(solutions)),
  )
  let other_basis = test_basis(2, [
    [((1, 1), [1, 0]), ((-1, 1), [0, 1])],
    [((1, 1), [0, 2]), ((-3, 1), [0, 0])],
  ])
  let other = test_solutions(test_shape(other_basis))
  assert_false(check_solutions_result(other, solution_certificate(solutions)))
  assert_false(
    check_basis_solutions(other_basis, solution_certificate(solutions)),
  )
}
