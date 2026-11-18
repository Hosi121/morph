///|
fn inputs(facets : Array[Array[Int32]]) -> @core.Chain[@core.Chain[@core.Nat]] {
  @oracle.chain(facets.map(fn(face) { @oracle.chain(face.map(@oracle.nat)) }))
}

///|
fn generated(facets : Array[Array[Int32]]) -> @homology.Complex {
  @homology.closure(inputs(facets)).unwrap()
}

///|
fn assignments(
  pairs : Array[(Int32, Int32)],
) -> @core.Chain[(@core.Nat, @core.Nat)] {
  @oracle.chain(
    pairs.map(fn(pair) {
      let (from, to) = pair
      (@oracle.nat(from), @oracle.nat(to))
    }),
  )
}

///|
fn ivec(values : Array[Int32]) -> @core.Chain[@exact.Integer] {
  @oracle.chain(values.map(@oracle.integer))
}

///|
fn imat(
  values : Array[Array[Int32]],
  width : Int32,
) -> @matrix.Matrix[@exact.Integer] {
  @matrix.matrix(@oracle.nat(width), @oracle.chain(values.map(ivec))).unwrap()
}

///|
fn int_rows(matrix : @matrix.Matrix[@exact.Integer]) -> Array[Array[Int32]] {
  @oracle.array(@matrix.rows(matrix)).map(fn(row) {
    @oracle.array(row).map(@oracle.int_of_integer)
  })
}

///|
fn completed(
  complex : @homology.Complex,
  degree : Int32,
) -> @homology.Certificate {
  match @homology.compute(complex, @oracle.nat(degree), @oracle.nat(2000)) {
    Computed(witness) => witness
    _ => abort("finite homology fixture must complete")
  }
}

///|
fn circle() -> @homology.Complex {
  generated([[0, 1], [0, 2], [1, 2]])
}

///|
fn projective_plane() -> @homology.Complex {
  generated([
    [0, 1, 2],
    [0, 2, 3],
    [0, 1, 5],
    [0, 4, 5],
    [0, 3, 4],
    [1, 2, 4],
    [1, 3, 4],
    [1, 3, 5],
    [2, 3, 5],
    [2, 4, 5],
  ])
}

///|
test "vertex function is total unique exact-domain and simplex preserving" {
  let edge = generated([[0, 1]])
  let point = generated([[8]])
  assert_eq(check(edge, point, assignments([(0, 8)])), None)
  assert_eq(check(edge, point, assignments([(0, 8), (0, 8)])), None)
  assert_eq(check(edge, point, assignments([(0, 8), (1, 8), (2, 8)])), None)
  assert_eq(check(edge, point, assignments([(0, 8), (2, 8)])), None)
  assert_eq(check(edge, point, assignments([(0, 8), (1, 9)])), None)
  let disconnected = generated([[0], [1]])
  assert_eq(check(edge, disconnected, assignments([(0, 0), (1, 1)])), None)
  let triangle = generated([[0, 1, 2]])
  // All target edges exist, but the source triangle image is missing.
  assert_eq(
    check(triangle, circle(), assignments([(0, 0), (1, 1), (2, 2)])),
    None,
  )
  let collapse = check(edge, point, assignments([(1, 8), (0, 8)])).unwrap()
  assert_eq(source(collapse), edge)
  assert_eq(target(collapse), point)
  assert_eq(vertices(collapse), assignments([(0, 8), (1, 8)]))
  assert_eq(int_rows(chain_map(collapse, @oracle.nat(0)).unwrap()), [[1, 1]])
  let f1 = chain_map(collapse, @oracle.nat(1)).unwrap()
  assert_eq(@matrix.height(f1), @oracle.nat(0))
  assert_eq(@matrix.width(f1), @oracle.nat(1))
  assert_true(chain_identity(collapse, @oracle.nat(0)))
  assert_true(chain_identity(collapse, @oracle.nat(1)))
  let empty = generated([])
  assert_eq(
    check(empty, point, assignments([])),
    Some({
      source_complex: empty,
      target_complex: point,
      assignments: @core.Nil,
    }),
  )
  assert_eq(check(point, empty, assignments([(8, 8)])), None)
}

///|
test "orientation reversal collapse and composition preserve chain identities" {
  let c = circle()
  let reflection = check(c, c, assignments([(0, 1), (1, 0), (2, 2)])).unwrap()
  assert_eq(int_rows(chain_map(reflection, @oracle.nat(1)).unwrap()), [
    [-1, 0, 0],
    [0, 0, 1],
    [0, 1, 0],
  ])
  let double = compose(reflection, reflection).unwrap()
  assert_eq(double, identity(c))
  let edge = generated([[0, 1]])
  let collapse = check(c, edge, assignments([(0, 1), (1, 0), (2, 0)])).unwrap()
  let point = generated([[5]])
  let finish = check(edge, point, assignments([(0, 5), (1, 5)])).unwrap()
  assert_eq(compose(reflection, collapse), None)
  let collapsed = compose(finish, collapse).unwrap()
  assert_eq(compose(identity(edge), collapse), Some(collapse))
  assert_eq(compose(collapse, identity(c)), Some(collapse))
  for k in 0..<5 {
    let degree = @oracle.nat(k)
    assert_true(chain_identity(reflection, degree))
    assert_true(chain_identity(collapse, degree))
    assert_true(chain_identity(collapsed, degree))
    assert_eq(
      @matrix.multiply(
        chain_map(finish, degree).unwrap(),
        chain_map(collapse, degree).unwrap(),
        @chainhomology.integers(),
      ),
      chain_map(collapsed, degree),
    )
    assert_eq(
      @matrix.multiply(
        chain_map(reflection, degree).unwrap(),
        chain_map(reflection, degree).unwrap(),
        @chainhomology.integers(),
      ),
      chain_map(double, degree),
    )
  }
  let k = @oracle.nat(1)
  assert_true(check_chain_map(reflection, k, chain_map(reflection, k).unwrap()))
  assert_false(
    check_chain_map(reflection, k, chain_map(identity(c), k).unwrap()),
  )
}

///|
test "circle homology identity reflection degree minus one and filled inclusion" {
  let c = circle()
  let h = completed(c, 1)
  let k = @oracle.nat(1)
  let id = induce(identity(c), k, h, h).unwrap()
  assert_eq(int_rows(id.classes), [[1]])
  assert_eq(apply(id, ivec([3])), Some(ivec([3])))
  let reflection = check(c, c, assignments([(0, 1), (1, 0), (2, 2)])).unwrap()
  let reflected = induce(reflection, k, h, h).unwrap()
  assert_eq(int_rows(reflected.classes), [[-1]])
  assert_eq(apply(reflected, ivec([3])), Some(ivec([-3])))
  assert_eq(
    apply(reflected, apply(reflected, ivec([3])).unwrap()),
    apply(id, ivec([3])),
  )
  let filled = generated([[0, 1, 2]])
  let inclusion = check(c, filled, assignments([(0, 0), (1, 1), (2, 2)])).unwrap()
  let killed = induce(inclusion, k, h, completed(filled, 1)).unwrap()
  assert_eq(int_rows(killed.classes), [[0]])
  assert_eq(apply(killed, ivec([7])), Some(ivec([0])))
  assert_eq(apply(id, ivec([])), None)
  assert_eq(apply(id, ivec([1, 2])), None)
}

///|
test "edge collapse induces identity on its free H0 class including unit slots" {
  let edge = generated([[0, 1]])
  let point = generated([[4]])
  let map = check(edge, point, assignments([(0, 4), (1, 4)])).unwrap()
  let induced = induce(
    map,
    @oracle.nat(0),
    completed(edge, 0),
    completed(point, 0),
  ).unwrap()
  assert_eq(int_rows(induced.classes), [[0, 1]])
  assert_eq(apply(induced, ivec([0, 1])), Some(ivec([1])))
  assert_eq(apply(induced, ivec([9, -3])), Some(ivec([-3])))
  let empty = generated([])
  let empty_to_point = check(empty, point, assignments([])).unwrap()
  let empty_h0 = induce(
    empty_to_point,
    @oracle.nat(0),
    completed(empty, 0),
    completed(point, 0),
  ).unwrap()
  assert_eq(@matrix.width(empty_h0.classes), @oracle.nat(0))
  assert_eq(int_rows(empty_h0.classes), [[]])
  assert_eq(apply(empty_h0, ivec([])), Some(ivec([0])))
  let beyond = induce(
    identity(edge),
    @oracle.nat(4),
    completed(edge, 4),
    completed(edge, 4),
  ).unwrap()
  assert_eq(int_rows(beyond.classes), [])
  assert_eq(@matrix.width(beyond.classes), @oracle.nat(0))
  assert_eq(apply(beyond, ivec([])), Some(ivec([])))
}

///|
test "different source and target Smith bases apply both coordinate changes" {
  let points = generated([[0], [1]])
  let h = completed(points, 0)
  let form = h.image_form
  let s = {
    ..h,
    image_form: @smith.check(
      @smith.original(form),
      imat([[1, 1], [0, 1]], 2),
      @smith.diagonal(form),
      @smith.right(form),
    ).unwrap(),
  }
  let t = {
    ..h,
    image_form: @smith.check(
      @smith.original(form),
      imat([[1, 0], [1, 1]], 2),
      @smith.diagonal(form),
      @smith.right(form),
    ).unwrap(),
  }
  assert_true(@homology.check_result(points, @oracle.nat(0), s.result, s))
  assert_true(@homology.check_result(points, @oracle.nat(0), t.result, t))
  let changed = induce(identity(points), @oracle.nat(0), s, t).unwrap()
  assert_eq(int_rows(changed.classes), [[1, -1], [1, 0]])
  assert_eq(apply(changed, ivec([2, 3])), Some(ivec([-1, 2])))
  let back = induce(identity(points), @oracle.nat(0), t, s).unwrap()
  assert_eq(
    apply(back, apply(changed, ivec([2, 3])).unwrap()),
    Some(ivec([2, 3])),
  )
}

///|
test "projective plane H1 identity reduces minus one to one in C2" {
  let plane = projective_plane()
  let h = completed(plane, 1)
  assert_eq(@oracle.array(h.result.torsion).map(@oracle.int_of_binary), [2])
  let induced = induce(identity(plane), @oracle.nat(1), h, h).unwrap()
  let positive = Array::make(10, 0)
  positive[9] = 1
  let negative = Array::make(10, 0)
  negative[9] = -1
  assert_eq(apply(induced, ivec(positive)), Some(ivec(positive)))
  assert_eq(apply(induced, ivec(negative)), Some(ivec(positive)))
  let twice = Array::make(10, 0)
  twice[9] = 2
  assert_eq(apply(induced, ivec(twice)), Some(ivec(Array::make(10, 0))))
}

///|
test "induced checker binds maps degree actual result and every witness field" {
  let c = circle()
  let k = @oracle.nat(1)
  let h = completed(c, 1)
  let map = identity(c)
  let good = induce(map, k, h, h).unwrap()
  let reflection = check(c, c, assignments([(0, 1), (1, 0), (2, 2)])).unwrap()
  let wrong = imat([[-1]], 1)
  assert_true(check_induced(map, k, good.classes, good))
  assert_false(check_induced(reflection, k, good.classes, good))
  assert_false(check_induced(map, @oracle.nat(0), good.classes, good))
  assert_false(check_induced(map, k, wrong, good))
  assert_false(
    check_induced(map, k, good.classes, { ..good, map: reflection, }),
  )
  assert_false(
    check_induced(map, k, good.classes, { ..good, degree: @oracle.nat(0), }),
  )
  assert_false(
    check_induced(map, k, good.classes, {
      ..good,
      source_homology: completed(c, 0),
    }),
  )
  assert_false(
    check_induced(map, k, good.classes, {
      ..good,
      target_homology: completed(c, 0),
    }),
  )
  assert_false(
    check_induced(map, k, good.classes, { ..good, source_left_inverse: wrong, }),
  )
  assert_false(
    check_induced(map, k, good.classes, { ..good, cycle_map: wrong, }),
  )
  assert_false(check_induced(map, k, good.classes, { ..good, classes: wrong, }))
  assert_eq(apply({ ..good, classes: wrong, }, ivec([1])), None)
  let filled = generated([[0, 1, 2]])
  assert_eq(induce(map, k, completed(filled, 1), h), None)
  assert_eq(induce(map, k, h, completed(filled, 1)), None)
  assert_eq(induce(map, @oracle.nat(0), h, h), None)
  let changed = {
    ..h,
    result: { free_rank: @oracle.nat(4), torsion: @core.Nil, },
  }
  assert_eq(induce(map, k, changed, h), None)
  assert_eq(induce(map, k, h, changed), None)
}
