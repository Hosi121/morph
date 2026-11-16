///|
fn test_polynomial(
  variables : Int32,
  terms : Array[((Int32, Int32), Array[Int32])],
) -> @poly.Polynomial {
  @poly.polynomial(
    @oracle.nat(variables),
    @oracle.chain(
      terms.map(fn(pair) {
        {
          coefficient: @oracle.rational(pair.0.0, pair.0.1),
          exponents: @oracle.chain(pair.1.map(@oracle.nat)),
        }
      }),
    ),
  ).unwrap()
}

///|
fn test_univariate(values : Array[(Int32, Int32)]) -> @poly.Polynomial {
  @poly.polynomial(
    Succ(Zero),
    @oracle.chain(
      values.mapi(fn(i, pair) {
        {
          coefficient: @oracle.rational(pair.0, pair.1),
          exponents: Cons(@oracle.nat(i), Nil),
        }
      }),
    ),
  ).unwrap()
}

///|
fn test_basis(
  variables : Int32,
  inputs : Array[Array[((Int32, Int32), Array[Int32])]],
) -> @f4.Basis {
  let inputs = @oracle.chain(
    inputs.map(fn(p) { test_polynomial(variables, p) }),
  )
  match @f4.f4(@oracle.nat(variables), inputs, @oracle.nat(300)).unwrap() {
    Complete(basis) => basis
    _ => abort("unexpected F4 pause")
  }
}

///|
fn test_shape(basis : @f4.Basis) -> Shape {
  match from_basis(basis).unwrap() {
    ShapeReady(shape) => shape
    _ => abort("expected shape presentation")
  }
}

///|
fn test_solutions(shape : Shape) -> SolutionSet {
  match advance(isolate(shape), @oracle.nat(1024)) {
    Complete(result) => result
    _ => abort("unexpected root-isolation pause")
  }
}

///|
fn assert_parameter_equal(a : @real.Number, b : @real.Number) -> Unit raise {
  match @real.compare(a, b, Zero).unwrap() {
    Compared(Equal, proof) => assert_true(@real.check_comparison(proof))
    _ => fail("different algebraic parameters")
  }
}

///|
fn assert_variety_fixture(
  variables : Int32,
  inputs : Array[Array[((Int32, Int32), Array[Int32])]],
  eliminant : Array[(Int32, Int32)],
  coordinates : Array[Array[(Int32, Int32)]],
  intervals : Array[((Int32, Int32), (Int32, Int32))],
) -> Unit raise {
  let basis = test_basis(variables, inputs)
  assert_true(@f4.verify(basis).unwrap())
  let shape = test_shape(basis)
  let proof = shape_certificate(shape)
  assert_true(check_basis_shape(basis, proof))
  assert_eq(proof.eliminant, @poly.monic(test_univariate(eliminant)))
  assert_eq(@oracle.array(proof.coordinates), coordinates.map(test_univariate))
  for input in inputs {
    assert_true(
      @poly.is_zero(
        substitute_mod(
          test_polynomial(variables, input),
          proof.coordinates,
          proof.eliminant,
        ).unwrap(),
      ),
    )
  }
  assert_true(advance(isolate(shape), Zero) is Paused(_))
  let result = test_solutions(shape)
  let certificate = solution_certificate(result)
  assert_true(check_solutions(certificate))
  assert_true(check_basis_solutions(basis, certificate))
  let points = @oracle.array(points(result).unwrap())
  assert_eq(points.length(), intervals.length())
  for i in 0..<points.length() {
    let pair = intervals[i]
    let expected = @real.number({
      polynomial: test_univariate(eliminant),
      interval: {
        lower: @oracle.rational(pair.0.0, pair.0.1),
        upper: @oracle.rational(pair.1.0, pair.1.1),
      },
    }).unwrap()
    assert_parameter_equal(parameter(points[i]), expected)
    assert_true(check_point(point_certificate(points[i])))
    assert_eq(coordinate_expressions(points[i]), proof.coordinates)
    assert_true(
      coordinate_expression_at(points[i], @oracle.nat(variables)) is None,
    )
  }
  if points.length() > 0 {
    assert_false(check_solutions({ ..certificate, intervals: Nil, }))
    let first = @oracle.array(certificate.intervals)[0]
    assert_false(
      check_solutions({
        ..certificate,
        intervals: Cons(first, Cons(first, Nil)),
      }),
    )
  }
}

///|
fn assert_nonshape_fixture(
  variables : Int32,
  inputs : Array[Array[((Int32, Int32), Array[Int32])]],
  unit : Bool,
) -> Unit raise {
  let basis = test_basis(variables, inputs)
  match start_basis(basis).unwrap() {
    NoSolutions(proof) => {
      assert_true(unit)
      assert_true(check_unit(proof))
    }
    UnsupportedSystem(_) => assert_false(unit)
    _ => fail("unsupported or unit expected")
  }
}

///|
test "shape certificates reject fabricated provenance coordinates and extra constraints" {
  let basis = test_basis(2, [
    [((1, 1), [1, 0]), ((-1, 1), [0, 1])],
    [((1, 1), [0, 2]), ((-2, 1), [0, 0])],
  ])
  let shape = test_shape(basis)
  let proof = shape_certificate(shape)
  assert_true(check_shape(proof))
  let false_g = test_univariate([(-3, 1), (0, 1), (1, 1)])
  assert_false(check_shape({ ..proof, eliminant: false_g, }))
  assert_false(
    check_shape({ ..proof, basis: Cons(proof.eliminant_source, Nil), }),
  )
  assert_false(check_shape({ ..proof, coordinate_sources: Nil, }))
  let wrong_coordinate = test_univariate([(1, 1), (1, 1)])
  assert_false(
    check_shape({
      ..proof,
      coordinates: Cons(
        wrong_coordinate,
        Cons(parameter_polynomial().unwrap(), Nil),
      ),
    }),
  )
  let extra = test_polynomial(2, [((1, 1), [1, 0]), ((-1, 1), [0, 0])])
  assert_false(check_shape({ ..proof, basis: Cons(extra, proof.basis), }))
  assert_false(check_shape({ ..proof, variables: @oracle.nat(3), }))
  assert_true(
    shape_from_certificate({ ..proof, eliminant: false_g, })
    is Err(InvalidCertificate),
  )
  let result = test_solutions(shape)
  let points = @oracle.array(points(result).unwrap())
  let other = @real.rational(@oracle.rational(0, 1)).unwrap()
  assert_false(
    check_point({ shape: proof, parameter: @real.root_certificate(other), }),
  )
  let missing = @core.drop(Succ(Zero), solution_certificate(result).intervals)
  assert_false(check_solutions({ shape: proof, intervals: missing, }))
  assert_true(
    solutions_from_certificate({ shape: proof, intervals: missing, })
    is Err(InvalidCertificate),
  )
  assert_true(check_point(point_certificate(points[0])))
}

///|
test "raw mixed coordinate equations are unsupported until F4 derives shape rows" {
  let inputs = [
    test_polynomial(2, [((1, 1), [1, 1]), ((-1, 1), [0, 0])]),
    test_polynomial(2, [((1, 1), [0, 2]), ((-2, 1), [0, 0])]),
  ]
  assert_true(
    extract(@oracle.nat(2), @oracle.chain(inputs)).unwrap()
    is Unsupported(NotShapePosition),
  )
  let basis = match
    @f4.f4(@oracle.nat(2), @oracle.chain(inputs), @oracle.nat(100)).unwrap() {
    Complete(basis) => basis
    _ => abort("F4 pause")
  }
  let shape = test_shape(basis)
  assert_true(check_basis_shape(basis, shape_certificate(shape)))
  assert_eq(
    @oracle.array(shape_certificate(shape).coordinates)[0],
    test_univariate([(0, 1), (1, 2)]),
  )
}

///|
test "zero variables empty systems unit evidence and dimension errors stay explicit" {
  assert_eq(extract(Zero, Nil).unwrap(), Unsupported(NoParameter))
  assert_eq(extract(@oracle.nat(2), Nil).unwrap(), Unsupported(NoEliminant))
  let zero = @poly.zero(@oracle.nat(2))
  assert_eq(
    extract(@oracle.nat(2), Cons(zero, Nil)).unwrap(),
    Unsupported(NoEliminant),
  )
  assert_true(
    extract(@oracle.nat(3), Cons(zero, Nil)) is Err(DimensionMismatch),
  )
  let constant = @poly.constant(Zero, @oracle.rational(2, 1))
  match extract(Zero, Cons(constant, Nil)).unwrap() {
    UnitIdeal(proof) => {
      assert_true(check_unit(proof))
      assert_false(check_unit({ ..proof, witness: @poly.zero(Zero), }))
    }
    _ => fail("nonzero constant excludes every solution")
  }
}

///|
test "close roots retain paused work and never return a partial complete set" {
  let basis = test_basis(2, [
    [((1, 1), [1, 0]), ((-1, 1), [0, 1])],
    [((1, 1), [0, 2]), ((-2, 1), [0, 1]), ((524287, 524288), [0, 0])],
  ])
  let shape = test_shape(basis)
  let state = match advance(isolate(shape), Succ(Zero)) {
    Paused(state) => state
    _ => abort("close roots not separated after one node")
  }
  let result = match advance(state, @oracle.nat(1024)) {
    Complete(result) => result
    _ => abort("refinement did not finish")
  }
  assert_eq(@oracle.array(points(result).unwrap()).length(), 2)
  assert_true(check_basis_solutions(basis, solution_certificate(result)))
}
