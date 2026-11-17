///|
fn fixture_vector(
  count : Int32,
  input : Array[Array[(Int32, Int32, Array[Int32])]],
) -> VectorField {
  vector_field(
    @oracle.nat(count),
    @oracle.chain(
      input.map(fn(coefficient) { fixture_polynomial(count, coefficient) }),
    ),
  ).unwrap()
}

///|
fn fraction_cartan_fixture(
  count : Int32,
  grade : Int32,
  input : Array[(Array[(Int32, Int32, Array[Int32])], Array[Int32])],
  coefficients : Array[Array[(Int32, Int32, Array[Int32])]],
  expected_interior : Array[(Array[(Int32, Int32, Array[Int32])], Array[Int32])]?,
  expected_lie : Array[(Array[(Int32, Int32, Array[Int32])], Array[Int32])],
) -> Unit raise {
  let value = fixture_form(count, grade, input)
  let vector = fixture_vector(count, coefficients)
  assert_eq(vector_variables(vector), @oracle.nat(count))
  assert_eq(
    vector_components(vector),
    @oracle.chain(coefficients.map(fn(p) { fixture_polynomial(count, p) })),
  )
  let interior = contract(vector, value).unwrap()
  match (interior, expected_interior) {
    (None, None) => assert_eq(grade, 0)
    (Some(actual), Some(expected)) => {
      assert_eq(variables(actual), @oracle.nat(count))
      assert_eq(degree(actual), @oracle.nat(grade - 1))
      assert_eq(terms(actual), fixture_terms(count, expected))
      match contract(vector, actual).unwrap() {
        None => assert_eq(grade, 1)
        Some(twice) => assert_true(is_zero(twice))
      }
    }
    _ => abort("contraction grading differs from host oracle")
  }
  let actual = lie_derivative(vector, value).unwrap()
  assert_eq(variables(actual), variables(value))
  assert_eq(degree(actual), degree(value))
  assert_eq(terms(actual), fixture_terms(count, expected_lie))
  assert_eq(
    exterior_derivative(actual),
    lie_derivative(vector, exterior_derivative(value).unwrap()),
  )
}

///|
test "vector validation and compatibility precede contraction zero cases" {
  assert_eq(vector_field(@oracle.nat(2), Nil), Err(DimensionMismatch))
  assert_eq(
    vector_field(Succ(Zero), Cons(@poly.zero(Zero), Nil)),
    Err(CoefficientDimension),
  )
  let point = vector_field(Zero, Nil).unwrap()
  assert_eq(contract(point, zero(Succ(Zero), Zero)), Err(DimensionMismatch))
  assert_eq(
    lie_derivative(point, zero(Succ(Zero), Zero)),
    Err(DimensionMismatch),
  )
  assert_eq(contract(point, zero(Zero, Zero)), Ok(None))
  assert_eq(
    contract(point, zero(Zero, @oracle.nat(3))),
    Ok(Some(zero(Zero, @oracle.nat(2)))),
  )
  assert_eq(lie_derivative(point, zero(Zero, Zero)), Ok(zero(Zero, Zero)))
}

///|
test "Cartan calculus on functions and nonconstant vector fields" {
  let vector = fixture_vector(2, [[(1, 1, [0, 1])], [(1, 1, [2, 0])]])
  let one_form = fixture_form(2, 1, [([(1, 1, [1, 0])], [1])])
  assert_eq(
    contract(vector, one_form),
    Ok(Some(scalar(fixture_polynomial(2, [(1, 1, [3, 0])])))),
  )
  let lie = lie_derivative(vector, one_form).unwrap()
  assert_eq(
    terms(lie),
    fixture_terms(2, [([(2, 1, [2, 0])], [0]), ([(1, 1, [0, 1])], [1])]),
  )
  let function = scalar(fixture_polynomial(2, [(1, 1, [1, 1])]))
  assert_eq(contract(vector, function), Ok(None))
  assert_eq(
    lie_derivative(vector, function),
    Ok(scalar(fixture_polynomial(2, [(1, 1, [3, 0]), (1, 1, [0, 2])]))),
  )
}
