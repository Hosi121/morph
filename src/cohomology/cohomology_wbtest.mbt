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
