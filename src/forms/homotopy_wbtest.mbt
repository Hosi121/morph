///|
fn fraction_homotopy_fixture(
  count : Int32,
  grade : Int32,
  input : Array[(Array[(Int32, Int32, Array[Int32])], Array[Int32])],
  expected : Array[(Array[(Int32, Int32, Array[Int32])], Array[Int32])]?,
  remainder : Array[(Array[(Int32, Int32, Array[Int32])], Array[Int32])],
  closed : Bool,
) -> Unit raise {
  let value = fixture_form(count, grade, input)
  let actual = radial_homotopy(value).unwrap()
  match (actual, expected) {
    (None, None) => assert_eq(grade, 0)
    (Some(result), Some(coefficients)) => {
      assert_eq(variables(result), @oracle.nat(count))
      assert_eq(degree(result), @oracle.nat(grade - 1))
      assert_eq(terms(result), fixture_terms(count, coefficients))
    }
    _ => abort("homotopy negative-degree grading differs from host oracle")
  }
  let differential = exterior_derivative(value).unwrap()
  assert_eq(is_zero(differential), closed)
  let second = radial_homotopy(differential).unwrap().unwrap()
  let identity = match actual {
    None => second
    Some(first) => add(exterior_derivative(first).unwrap(), second).unwrap()
  }
  assert_eq(variables(identity), @oracle.nat(count))
  assert_eq(degree(identity), @oracle.nat(grade))
  assert_eq(terms(identity), fixture_terms(count, remainder))
  if grade == 0 {
    assert_eq(primitive(value), Err(ZeroDegree))
  } else if closed {
    let candidate = primitive(value).unwrap()
    assert_eq(terms(candidate), fixture_terms(count, expected.unwrap()))
    assert_true(check_primitive(value, candidate))
    assert_eq(exterior_derivative(candidate), Ok(value))
  } else {
    assert_eq(primitive(value), Err(NotClosed))
    assert_true(!check_primitive(value, actual.unwrap()))
  }
}

///|
test "mixed polynomial degrees require separate radial denominators" {
  let volume = fixture_form(2, 2, [([(1, 1, [0, 0]), (1, 1, [2, 0])], [0, 1])])
  let expected = fixture_form(2, 1, [
    ([(-1, 2, [0, 1]), (-1, 4, [2, 1])], [0]),
    ([(1, 2, [1, 0]), (1, 4, [3, 0])], [1]),
  ])
  assert_eq(radial_homotopy(volume), Ok(Some(expected)))
  assert_eq(primitive(volume), Ok(expected))
  assert_true(check_primitive(volume, expected))
  assert_true(!check_primitive(volume, zero(@oracle.nat(3), Succ(Zero))))
  assert_true(!check_primitive(volume, zero(@oracle.nat(2), Zero)))
  let nonclosed = fixture_form(2, 1, [([(1, 1, [1, 0])], [1])])
  assert_eq(primitive(nonclosed), Err(NotClosed))
  let constant = scalar(fixture_polynomial(2, [(1, 1, [0, 0])]))
  assert_eq(radial_homotopy(constant), Ok(None))
  assert_eq(primitive(constant), Err(ZeroDegree))
  assert_true(!check_primitive(constant, constant))
}
