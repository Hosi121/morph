///|
fn assert_resultant_fixture(
  a : Array[(Int32, Int32)],
  b : Array[(Int32, Int32)],
  operation : BinaryOperation,
  expected : Array[(Int32, Int32)],
) -> Unit raise {
  let left = test_polynomial(a)
  let right = test_polynomial(b)
  let initial = resultant_start(left, right, operation).unwrap()
  assert_true(resultant_advance(initial, Zero).unwrap() is ResultantPaused(_))
  let proof = match resultant_advance(initial, @oracle.nat(100)).unwrap() {
    ResultantReady(proof) => proof
    _ => abort("unexpected resultant pause")
  }
  assert_eq(proof.polynomial, test_polynomial(expected))
  assert_true(check_resultant(proof))
  assert_false(check_resultant({ ..proof, samples: Nil, }))
  let wrong = @poly.add(proof.polynomial, test_integer_polynomial([1])).unwrap()
  assert_false(check_resultant({ ..proof, polynomial: wrong, }))
}

///|
test "resultant point fuel is exact and resumable" {
  let p = test_integer_polynomial([-2, 0, 1])
  let q = test_integer_polynomial([-3, 0, 1])
  let initial = resultant_start(p, q, Sum).unwrap()
  let state = match resultant_advance(initial, @oracle.nat(4)).unwrap() {
    ResultantPaused(state) => state
    _ => abort("degree four requires five points")
  }
  match resultant_advance(state, Succ(Zero)).unwrap() {
    ResultantReady(proof) => assert_true(check_resultant(proof))
    _ => fail("fifth point must complete")
  }
  assert_true(
    resultant_start(test_integer_polynomial([1]), q, Sum)
    is Err(InvalidDefinition),
  )
}
