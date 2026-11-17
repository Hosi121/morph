///|
fn complex(facets : Array[Array[Int32]]) -> @homology.Complex {
  @homology.closure(
    @oracle.chain(facets.map(fn(face) { @oracle.chain(face.map(@oracle.nat)) })),
  ).unwrap()
}

///|
fn bits(values : Array[Bool]) -> @core.Chain[Bool] {
  @oracle.chain(values)
}

///|
test "explicit cocycle quotient has complete invertible basis certificates" {
  let circle = complex([[0, 1], [0, 2], [1, 2]])
  for degree in 0..<4 {
    let space = compute(circle, @oracle.nat(degree)).unwrap()
    let group = result(space)
    assert_eq(@oracle.int_of_nat(group.rank), if degree < 2 { 1 } else { 0 })
    assert_true(
      check_result(circle, @oracle.nat(degree), group, certificate(space)),
    )
    for vector in @oracle.array(group.representatives) {
      let value = coordinates(space, vector).unwrap()
      assert_eq(representative(space, value), Some(vector))
    }
    for vector in @oracle.array(group.coboundaries) {
      assert_true(zero_vector(coordinates(space, vector).unwrap()))
    }
  }
  let point = compute(complex([[0]]), @oracle.nat(0)).unwrap()
  assert_eq(result(point).rank, @oracle.nat(1))
  assert_eq(coordinates(point, bits([true])), Some(bits([true])))
  assert_eq(coordinates(point, bits([])), None)
  let interval = compute(complex([[0, 1]]), @oracle.nat(0)).unwrap()
  assert_eq(coordinates(interval, bits([true, false])), None)
  let empty = compute(complex([]), @oracle.nat(0)).unwrap()
  assert_eq(result(empty).rank, @oracle.nat(0))
  assert_eq(coordinates(empty, bits([])), Some(bits([])))
}

///|
test "cohomology certificate binds actual group source degree and identities" {
  let source = complex([[0, 1], [0, 2], [1, 2]])
  let space = compute(source, @oracle.nat(1)).unwrap()
  let witness = certificate(space)
  let actual = result(space)
  assert_false(check_result(source, @oracle.nat(0), actual, witness))
  assert_false(check_result(complex([[0, 1]]), @oracle.nat(1), actual, witness))
  assert_false(
    check_result(
      source,
      @oracle.nat(1),
      { ..actual, rank: @oracle.nat(0), },
      witness,
    ),
  )
  assert_false(
    check_result(source, @oracle.nat(1), actual, {
      ..witness,
      inverse_basis: witness.incoming_coordinates,
    }),
  )
  assert_false(
    check_result(source, @oracle.nat(1), actual, {
      ..witness,
      outgoing_rank: witness.incoming_rank,
    }),
  )
  assert_false(
    check_result(source, @oracle.nat(1), actual, {
      ..witness,
      result: { ..actual, representatives: Nil, },
    }),
  )
}

///|
test "basis checker accepts a new representative with a complete transported inverse" {
  let source = complex([[0, 1], [0, 2], [1, 2]])
  let space = compute(source, @oracle.nat(1)).unwrap()
  let old = certificate(space)
  // Add the first coboundary to H's representative. This involutory change
  // is verified by matrix identities rather than matching solver output.
  let change = @matrix.matrix(
    @oracle.nat(3),
    @oracle.chain([mask_bits(3, 5), mask_bits(3, 2), mask_bits(3, 4)]),
  ).unwrap()
  let basis = @matrix.multiply(old.basis, change, @csscode.scalars()).unwrap()
  let inverse_basis = @matrix.multiply(
    change,
    old.inverse_basis,
    @csscode.scalars(),
  ).unwrap()
  let incoming_coordinates = @matrix.multiply(
    change,
    old.incoming_coordinates,
    @csscode.scalars(),
  ).unwrap()
  let group = {
    ..old.result,
    representatives: @core.drop(@oracle.nat(2), columns(basis)),
  }
  let moved = {
    ..old,
    result: group,
    basis,
    inverse_basis,
    incoming_coordinates,
  }
  assert_true(check_result(source, @oracle.nat(1), group, moved))
  let imported = validate_certificate(source, @oracle.nat(1), group, moved).unwrap()
  let chosen = representative(imported, mask_bits(1, 1)).unwrap()
  assert_eq(
    equivalent(space, chosen, representative(space, mask_bits(1, 1)).unwrap()),
    Some(true),
  )
  assert_false(
    check_result(source, @oracle.nat(1), group, {
      ..moved,
      inverse_basis: old.inverse_basis,
    }),
  )
}

///|
test "paired forged results cannot bypass the basis and image identities" {
  let source = complex([[0, 1], [0, 2], [1, 2]])
  let space = compute(source, @oracle.nat(1)).unwrap()
  let good = certificate(space)
  let bad = {
    ..good.result,
    representatives: @core.Cons(mask_bits(3, 0), Nil),
  }
  assert_false(
    check_result(source, @oracle.nat(1), bad, { ..good, result: bad, }),
  )
  let zero_basis = @matrix.matrix(
    @oracle.nat(3),
    @oracle.chain([mask_bits(3, 0), mask_bits(3, 0), mask_bits(3, 0)]),
  ).unwrap()
  assert_false(
    check_result(source, @oracle.nat(1), good.result, {
      ..good,
      basis: zero_basis,
      inverse_basis: zero_basis,
    }),
  )
  assert_false(
    check_result(source, @oracle.nat(1), good.result, {
      ..good,
      incoming_coordinates: zero_basis,
    }),
  )
}
