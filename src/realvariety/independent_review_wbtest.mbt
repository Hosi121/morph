///|
fn rv_review_rat(
  negative : Bool,
  numerator : String,
  denominator : String,
) -> @exact.Rational {
  let n = @exact.positive(@oracle.binary_from_hex(numerator))
  @exact.ratio(
    if negative {
      @exact.negate(n)
    } else {
      n
    },
    @oracle.binary_from_hex(denominator),
  ).unwrap()
}

///|
fn rv_review_u(coefficients : Array[@exact.Rational]) -> @poly.Polynomial {
  @poly.polynomial(
    @oracle.nat(1),
    @oracle.chain(
      coefficients.mapi(fn(i, c) {
        @poly.Term::{
          coefficient: c,
          exponents: @core.Cons(@oracle.nat(i), @core.Nil),
        }
      }),
    ),
  ).unwrap()
}

///|
fn rv_review_p(
  variables : Int32,
  terms : Array[(@exact.Rational, Array[Int32])],
) -> @poly.Polynomial {
  @poly.polynomial(
    @oracle.nat(variables),
    @oracle.chain(
      terms.map(fn(term) {
        @poly.Term::{
          coefficient: term.0,
          exponents: @oracle.chain(term.1.map(@oracle.nat)),
        }
      }),
    ),
  ).unwrap()
}

///|
fn rv_review_basis(
  variables : Int32,
  inputs : Array[@poly.Polynomial],
) -> @f4.Basis {
  match
    @f4.f4(@oracle.nat(variables), @oracle.chain(inputs), @oracle.nat(300)).unwrap() {
    Complete(basis) => basis
    _ => abort("review F4 exceeded300 batch bound")
  }
}

///|
fn rv_review_shape(basis : @f4.Basis) -> Shape {
  match from_basis(basis).unwrap() {
    ShapeReady(shape) => shape
    _ => abort("review shape missing")
  }
}

///|
fn rv_review_solutions(shape : Shape) -> SolutionSet {
  match advance(isolate(shape), @oracle.nat(2048)) {
    Complete(value) => value
    _ => abort("review root coverage exceeded2048 nodes")
  }
}

///|
fn rv_review_coordinate(
  point : Point,
  index : Int32,
) -> (@real.Number, CoordinateCertificate) {
  match
    evaluate_coordinate(point, @oracle.nat(index), @oracle.nat(2048)).unwrap() {
    CoordinateReady(value, proof) => (value, proof)
    _ => abort("review coordinate exceeded2048 samples/refinements")
  }
}

///|
fn rv_review_contains(
  interval : @sturm.Interval,
  value : @exact.Rational,
) -> Bool {
  @exact.rational_compare(value, interval.lower) is Greater &&
  !(@exact.rational_compare(value, interval.upper) is Greater)
}

///|
fn rv_review_fixture(
  variables : Int32,
  inputs : Array[@poly.Polynomial],
  expected_g : @poly.Polynomial,
  expected_h : Array[@poly.Polynomial],
  roots : Array[@exact.Rational],
  norms : Array[@poly.Polynomial],
  values : Array[Array[@exact.Rational]],
) -> Unit raise {
  if variables == 2 {
    match extract(@oracle.nat(variables), @oracle.chain(inputs)).unwrap() {
      ShapeReady(raw) => {
        assert_true(check_shape(shape_certificate(raw)))
        assert_eq(shape_certificate(raw).eliminant, expected_g)
        assert_eq(@oracle.array(shape_certificate(raw).coordinates), expected_h)
      }
      _ => fail("one-coordinate triangular input is already a raw shape")
    }
  } else {
    assert_true(
      extract(@oracle.nat(variables), @oracle.chain(inputs)).unwrap()
      is Unsupported(NotShapePosition),
    )
  }
  let basis = rv_review_basis(variables, inputs)
  assert_true(@f4.verify(basis).unwrap())
  let shape = rv_review_shape(basis)
  let shape_proof = shape_certificate(shape)
  assert_true(check_basis_shape(basis, shape_proof))
  assert_eq(shape_proof.eliminant, expected_g)
  assert_eq(@oracle.array(shape_proof.coordinates), expected_h)
  let solutions = rv_review_solutions(shape)
  let proof = solution_certificate(solutions)
  assert_true(check_basis_solutions(basis, proof))
  assert_true(check_solutions_result(solutions, proof))
  let points = @oracle.array(points(solutions).unwrap())
  assert_eq(points.length(), roots.length())
  let degree = @oracle.int_of_nat(univariate_degree(expected_g).unwrap())
  for i in 0..<points.length() {
    let point = points[i]
    assert_true(rv_review_contains(@real.interval(parameter(point)), roots[i]))
    let count = roots
      .filter(fn(root) {
        rv_review_contains(@real.interval(parameter(point)), root)
      })
      .length()
    assert_eq(count, 1)
    assert_true(check_point_result(point, point_certificate(point)))
    for input in inputs {
      assert_eq(
        @poly.evaluate(input, @oracle.chain(values[i])),
        Some(@exact.rational_zero()),
      )
    }
    for coordinate in 0..<variables {
      let (value, proof) = rv_review_coordinate(point, coordinate)
      assert_true(check_coordinate_result(value, proof))
      assert_eq(proof.polynomial, norms[coordinate])
      assert_eq(
        @oracle.int_of_nat(univariate_degree(proof.polynomial).unwrap()),
        degree,
      )
      assert_eq(@oracle.array(proof.samples).length(), degree + 1)
      assert_true(
        rv_review_contains(@real.interval(value), values[i][coordinate]),
      )
      let rational = @real.rational(values[i][coordinate]).unwrap()
      match @real.compare(value, rational, @oracle.nat(0)).unwrap() {
        Compared(Equal, _) => ()
        _ => fail("Fraction coordinate value mismatch")
      }
      let wrong = @real.rational(
        @exact.rational_add(values[i][coordinate], @exact.rational_one()),
      ).unwrap()
      assert_false(check_coordinate_result(wrong, proof))
    }
  }
}
