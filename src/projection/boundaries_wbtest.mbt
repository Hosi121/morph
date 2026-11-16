///|
fn projection_test_atoms() -> @core.Chain[@poly.Polynomial] {
  let one = @oracle.rational(1, 1)
  @oracle.chain([
    elimination_poly(2, [(one, [1, 0])]),
    elimination_poly(2, [(one, [0, 1]), (one, [0, 0])]),
  ])
}

///|
test "projection binds atoms method variable and every coefficient payload" {
  let original = projection_test_atoms()
  let selected = @oracle.nat(1)
  let plan = full_collins(original, selected).unwrap()
  let proof = certificate(plan)
  assert_eq(mode(plan), CollinsProjection)
  assert_true(check(CollinsProjection, original, selected, proof))
  assert_true(checked(CollinsProjection, original, selected, proof) is Some(_))
  assert_false(check(ProductProjection, original, selected, proof))
  assert_false(check(CollinsProjection, original, @oracle.nat(0), proof))
  let changed = @core.Cons(@poly.zero(@oracle.nat(2)), original)
  assert_false(check(CollinsProjection, changed, selected, proof))
  let foreign = product_projection(original, selected).unwrap()
  assert_false(
    check_result(CollinsProjection, original, selected, foreign, proof),
  )
  let false_coefficient = @poly.constant(
    @oracle.nat(1),
    @oracle.rational(17, 13),
  )
  assert_false(
    check(CollinsProjection, original, selected, {
      ..proof,
      coefficients: @core.Cons(false_coefficient, proof.coefficients),
    }),
  )
  assert_false(
    check(CollinsProjection, original, selected, {
      ..proof,
      principal: @core.Nil,
    }),
  )
  assert_false(
    check(CollinsProjection, original, selected, {
      ..proof,
      product: Some(@poly.zero(@oracle.nat(2))),
    }),
  )
}

///|
test "projection nullified product retains nonnull original atoms for lifting" {
  let original = projection_test_atoms()
  let plan = product_projection(original, @oracle.nat(1)).unwrap()
  let zero = @oracle.rational(0, 1)
  let source = product(plan).unwrap()
  assert_eq(@poly.evaluate(source, @oracle.chain([zero, zero])), Some(zero))
  let originals = @oracle.array(atoms(plan))
  assert_eq(originals.length(), 2)
  assert_eq(
    @poly.evaluate(originals[1], @oracle.chain([zero, zero])),
    Some(@oracle.rational(1, 1)),
  )
  assert_true(full_collins(original, @oracle.nat(1)) is Ok(_))
}

///|
test "projection sparse reducta preserve content and repeated factors" {
  let one = @oracle.rational(1, 1)
  let p = elimination_poly(2, [(one, [1, 3]), (one, [2, 1]), (one, [0, 0])])
  let actual = @oracle.array(reducta(p, @oracle.nat(1)).unwrap())
  assert_eq(actual.length(), 3)
  assert_eq(actual[0], p)
  assert_eq(actual[1], elimination_poly(2, [(one, [2, 1]), (one, [0, 0])]))
  assert_eq(actual[2], @poly.constant(@oracle.nat(2), one))
  assert_eq(reducta(@poly.zero(@oracle.nat(2)), @oracle.nat(1)), Ok(@core.Nil))
}

///|
test "projection rejects arity variable mistakes and handles empty atoms" {
  assert_true(full_collins(@core.Nil, @oracle.nat(2)) is Err(InvalidVariable))
  let wrong = @core.Cons(@poly.zero(@oracle.nat(1)), @core.Nil)
  assert_true(full_collins(wrong, @oracle.nat(1)) is Err(WrongArity))
  let empty = full_collins(@core.Nil, @oracle.nat(1)).unwrap()
  assert_eq(polynomials(empty), @core.Nil)
  assert_eq(product(empty), None)
  let empty_product = product_projection(@core.Nil, @oracle.nat(1)).unwrap()
  assert_eq(
    product(empty_product),
    Some(@poly.constant(@oracle.nat(2), @oracle.rational(1, 1))),
  )
}
