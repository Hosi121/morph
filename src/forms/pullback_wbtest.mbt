///|
fn fixture_map(
  source : Int32,
  coordinates : Array[Array[(Int32, Int32, Array[Int32])]],
) -> PolynomialMap {
  polynomial_map(
    @oracle.nat(source),
    @oracle.chain(
      coordinates.map(fn(coordinate) { fixture_polynomial(source, coordinate) }),
    ),
  ).unwrap()
}

///|
fn fraction_pullback_fixture(
  source : Int32,
  target : Int32,
  grade : Int32,
  coordinates : Array[Array[(Int32, Int32, Array[Int32])]],
  input : Array[(Array[(Int32, Int32, Array[Int32])], Array[Int32])],
  expected : Array[(Array[(Int32, Int32, Array[Int32])], Array[Int32])],
) -> Unit raise {
  let mapping = fixture_map(source, coordinates)
  assert_eq(map_source(mapping), @oracle.nat(source))
  assert_eq(map_target(mapping), @oracle.nat(target))
  assert_eq(
    map_coordinates(mapping),
    @oracle.chain(coordinates.map(fn(p) { fixture_polynomial(source, p) })),
  )
  let value = fixture_form(target, grade, input)
  let actual = pullback(mapping, value).unwrap()
  assert_eq(variables(actual), @oracle.nat(source))
  assert_eq(degree(actual), @oracle.nat(grade))
  assert_eq(terms(actual), fixture_terms(source, expected))
  assert_eq(
    exterior_derivative(actual),
    pullback(mapping, exterior_derivative(value).unwrap()),
  )
}

///|
test "map dimensions and empty affine source or target remain explicit" {
  assert_eq(
    polynomial_map(Succ(Zero), Cons(@poly.zero(Zero), Nil)),
    Err(CoefficientDimension),
  )
  let empty_target = polynomial_map(@oracle.nat(2), Nil).unwrap()
  assert_eq(
    pullback(empty_target, scalar(fixture_polynomial(0, [(3, 2, [])]))),
    Ok(scalar(fixture_polynomial(2, [(3, 2, [0, 0])]))),
  )
  assert_eq(
    pullback(empty_target, zero(Zero, @oracle.nat(3))),
    Ok(zero(@oracle.nat(2), @oracle.nat(3))),
  )
  assert_eq(
    pullback(empty_target, zero(Succ(Zero), Zero)),
    Err(DimensionMismatch),
  )
  let point = fixture_map(0, [[(2, 1, [])], [(3, 1, [])]])
  let function = scalar(fixture_polynomial(2, [(1, 1, [1, 1])]))
  assert_eq(
    pullback(point, function),
    Ok(scalar(fixture_polynomial(0, [(6, 1, [])]))),
  )
  let area = fixture_form(2, 2, [([(1, 1, [0, 0])], [0, 1])])
  assert_eq(pullback(point, area), Ok(zero(Zero, @oracle.nat(2))))
}

///|
test "pullback composes contravariantly on polynomial maps" {
  let first = fixture_map(2, [
    [(1, 1, [2, 0])],
    [(1, 1, [0, 1]), (1, 1, [1, 0])],
  ])
  let second = fixture_map(1, [[(1, 1, [1])], [(1, 1, [2])]])
  let composed = fixture_map(1, [[(1, 1, [2])], [(1, 1, [2]), (1, 1, [1])]])
  let value = fixture_form(2, 1, [
    ([(1, 2, [1, 1])], [0]),
    ([(2, 3, [2, 0])], [1]),
  ])
  assert_eq(
    pullback(second, pullback(first, value).unwrap()),
    pullback(composed, value),
  )
}
