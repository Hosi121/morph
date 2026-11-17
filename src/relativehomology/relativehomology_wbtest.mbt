///|
fn generated(facets : Array[Array[Int32]]) -> @homology.Complex {
  @homology.closure(
    @oracle.chain(facets.map(fn(f) { @oracle.chain(f.map(@oracle.nat)) })),
  ).unwrap()
}

///|
fn example(k : Array[Array[Int32]], a : Array[Array[Int32]]) -> Pair {
  pair(generated(k), generated(a)).unwrap()
}

///|
fn completed(source : Pair, k : Int32) -> Certificate {
  match compute(source, @oracle.nat(k), @oracle.nat(3000)) {
    Computed(c) => c
    _ => abort("finite relative fixture must complete")
  }
}

///|
fn absolute_completed(
  source : @homology.Complex,
  k : Int32,
) -> @homology.Certificate {
  match @homology.compute(source, @oracle.nat(k), @oracle.nat(3000)) {
    Computed(c) => c
    _ => abort("finite absolute fixture must complete")
  }
}

///|
fn expected(free : Int32, torsion : Array[Int32]) -> @homology.ResultGroup {
  {
    free_rank: @oracle.nat(free),
    torsion: @oracle.chain(torsion.map(@oracle.binary)),
  }
}

///|
fn rows(m : @matrix.Matrix[@exact.Integer]) -> Array[Array[Int32]] {
  @oracle.array(@matrix.rows(m)).map(fn(row) {
    @oracle.array(row).map(@oracle.int_of_integer)
  })
}

///|
fn verify(
  source : Pair,
  k : Int32,
  free : Int32,
  torsion : Array[Int32],
) -> Certificate raise {
  let c = completed(source, k)
  assert_eq(c.result, expected(free, torsion))
  assert_true(check_result(source, @oracle.nat(k), c.result, c))
  assert_true(boundary_squared_zero(source, @oracle.nat(k)))
  c
}

///|
fn connecting(source : Pair, k : Int32) -> ConnectingMap raise {
  let s = completed(source, k)
  let t = absolute_completed(subcomplex(source), k - 1)
  let witness = connect(source, @oracle.nat(k), s, t).unwrap()
  assert_true(
    check_connecting(source, @oracle.nat(k), witness.classes, witness),
  )
  witness
}

///|
test "checked inclusion and unreduced empty identical and empty-subcomplex pairs" {
  assert_eq(pair(generated([[0, 1]]), generated([[0, 2]])), None)
  let empty = example([], [])
  ignore(verify(empty, 0, 0, []))
  ignore(verify(empty, 2, 0, []))
  let k = generated([[0, 1, 2]])
  let equal = pair(k, k).unwrap()
  ignore(verify(equal, 0, 0, []))
  ignore(verify(equal, 1, 0, []))
  ignore(verify(equal, 2, 0, []))
  let circle = generated([[0, 1], [0, 2], [1, 2]])
  let aempty = pair(circle, generated([])).unwrap()
  for k in 0..<4 {
    let r = completed(aempty, k)
    let h = absolute_completed(circle, k)
    assert_eq(r.result, h.result)
    assert_eq(
      boundary(aempty, @oracle.nat(k)),
      @homology.boundary(circle, @oracle.nat(k)),
    )
  }
  assert_eq(
    connect(
      empty,
      @oracle.nat(0),
      completed(empty, 0),
      absolute_completed(generated([]), 0),
    ),
    None,
  )
}

///|
test "disk boundary quotient and connecting fundamental class are an isomorphism" {
  let disk = example([[0, 1, 2]], [[0, 1], [0, 2], [1, 2]])
  ignore(verify(disk, 0, 0, []))
  ignore(verify(disk, 1, 0, []))
  ignore(verify(disk, 2, 1, []))
  assert_eq(rows(boundary(disk, @oracle.nat(2)).unwrap()), [])
  assert_eq(
    @matrix.width(boundary(disk, @oracle.nat(2)).unwrap()),
    @oracle.nat(1),
  )
  let delta = connecting(disk, 2)
  let m = rows(delta.classes)
  assert_eq(m.length(), 1)
  assert_eq(m[0].length(), 1)
  assert_eq(m[0][0].abs(), 1)
  assert_eq(rows(delta.boundary_cycles), [[1], [-1], [1]])
  let image = apply_connecting(delta, @oracle.chain([@oracle.integer(3)])).unwrap()
  assert_eq(@oracle.int_of_integer(@oracle.array(image)[0]).abs(), 3)
  let zero = connecting(pair(ambient(disk), ambient(disk)).unwrap(), 2)
  assert_eq(@matrix.width(zero.classes), @oracle.nat(0))
}

///|
test "interval endpoints connecting map is their difference with zero component sum" {
  let interval = example([[0, 1]], [[0], [1]])
  ignore(verify(interval, 1, 1, []))
  let delta = connecting(interval, 1)
  assert_eq(rows(delta.classes), [[-1], [1]])
  assert_eq(rows(delta.boundary_cycles), [[-1], [1]])
  let image = apply_connecting(delta, @oracle.chain([@oracle.integer(-4)])).unwrap()
  assert_eq(@oracle.array(image).map(@oracle.int_of_integer), [4, -4])
  assert_eq(apply_connecting(delta, @core.Nil), None)
  let path = example([[0, 1], [1, 2], [2, 3]], [[0, 1], [2, 3]])
  let path_delta = connecting(path, 1)
  assert_eq(path_delta.target_homology.result, expected(2, []))
  assert_eq(@matrix.height(path_delta.classes), @oracle.nat(4))
  // Full Smith coordinates retain unit slots; these must become canonical zero.
  let values = rows(path_delta.classes).map(fn(row) { row[0] })
  assert_eq(values.filter(fn(x) { x != 0 }).length(), 2)
  assert_eq(values.fold(init=0, fn(sum, x) { sum + x }), 0)
}

///|
test "nontrivial source Smith lift and representative independence" {
  let disk_points = example([[0, 1, 2]], [[0], [1], [2]])
  let delta = connecting(disk_points, 1)
  assert_eq(delta.source_homology.result, expected(2, []))
  assert_false(
    delta.source_left_inverse.equal(
      @matrix.identity(@oracle.nat(3), @chainhomology.integers()),
    ),
  )
  // First source Smith slot has order one; its image is zero even with arbitrary representatives.
  assert_eq(
    apply_connecting(
      delta,
      @oracle.chain([
        @oracle.integer(17),
        @oracle.integer(0),
        @oracle.integer(0),
      ]),
    ),
    Some(
      @oracle.chain([@oracle.integer(0), @oracle.integer(0), @oracle.integer(0)]),
    ),
  )
  let values = rows(delta.classes)
  for j in 0..<3 {
    assert_eq(values.fold(init=0, fn(sum, row) { sum + row[j] }), 0)
  }
  assert_true(rows(delta.boundary_descent).is_empty())
  let sphere = example([[0, 1, 2], [0, 1, 3], [0, 2, 3], [1, 2, 3]], [[0]])
  ignore(verify(sphere, 0, 0, []))
  ignore(verify(sphere, 1, 0, []))
  ignore(verify(sphere, 2, 1, []))
  let delta_sphere = connecting(sphere, 2)
  assert_eq(@matrix.height(delta_sphere.classes), @oracle.nat(0))
}

///|
fn projective_facets() -> Array[Array[Int32]] {
  [
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
  ]
}

///|
test "projective plane relative a point retains torsion and connecting kills it" {
  let p = example(projective_facets(), [[0]])
  ignore(verify(p, 0, 0, []))
  let s = verify(p, 1, 0, [2])
  ignore(verify(p, 2, 0, []))
  let delta = connecting(p, 1)
  assert_eq(delta.source_homology.result, s.result)
  assert_true(rows(delta.classes).all(fn(row) { row.all(fn(x) { x == 0 }) }))
  let tree = example(projective_facets(), [
    [0, 1],
    [0, 2],
    [0, 3],
    [0, 4],
    [0, 5],
  ])
  ignore(verify(tree, 1, 0, [2]))
}

///|
// Small independent integer determinant, confined to tests.
fn determinant(input : Array[Array[Int32]]) -> Int32 {
  if input.is_empty() {
    return 1
  }
  let a = input.map(fn(row) { row.copy() })
  let mut previous = 1
  let mut sign = 1
  for k in 0..<(a.length() - 1) {
    let mut pivot = k
    while a[pivot][k] == 0 {
      pivot = pivot + 1
    }
    if pivot != k {
      let row = a[k]
      a[k] = a[pivot]
      a[pivot] = row
      sign = -sign
    }
    let value = a[k][k]
    for i in (k + 1)..<a.length() {
      for j in (k + 1)..<a.length() {
        a[i][j] = (a[i][j] * value - a[i][k] * a[k][j]) / previous
      }
      a[i][k] = 0
    }
    previous = value
  }
  sign * a[a.length() - 1][a.length() - 1]
}

///|
test "RP2 relative its full one skeleton has index two connecting image" {
  let k = generated(projective_facets())
  let skeleton = @homology.validate(
    @core.filter(@homology.all_simplices(k), fn(s) {
      @core.compare(@core.length(s), @oracle.nat(3)) is Less
    }),
  ).unwrap()
  let p = pair(k, skeleton).unwrap()
  ignore(verify(p, 2, 10, []))
  let delta = connecting(p, 2)
  assert_eq(delta.target_homology.result, expected(10, []))
  let m = rows(delta.classes)
  assert_eq(m.length(), 10)
  assert_eq(determinant(m).abs(), 2)
  // It is the integral image lattice (index two), not an asserted multiplication
  // by two into a rank-one circle: the triangulated skeleton has cycle rank ten.
}

///|
test "relative and connecting certificates reject changed bindings and witnesses" {
  let p = example([[0, 1, 2]], [[0], [1], [2]])
  let k = @oracle.nat(1)
  let good = completed(p, 1)
  let q = example([[0, 1, 2]], [[0, 1], [0, 2], [1, 2]])
  assert_false(check_result(q, k, good.result, good))
  assert_false(check_result(p, @oracle.nat(0), good.result, good))
  assert_false(check_result(p, k, expected(7, []), good))
  assert_false(check_result(p, k, good.result, { ..good, source: q, }))
  assert_false(
    check_result(p, k, good.result, { ..good, chain: completed(q, 1).chain, }),
  )
  let delta = connecting(p, 1)
  let id = @matrix.identity(@oracle.nat(3), @chainhomology.integers())
  let zero = @matrix.matrix(
    @oracle.nat(3),
    @core.replicate(
      @oracle.nat(3),
      @core.replicate(@oracle.nat(3), @oracle.integer(0)),
    ),
  ).unwrap()
  assert_false(check_connecting(q, k, delta.classes, delta))
  assert_false(check_connecting(p, @oracle.nat(2), delta.classes, delta))
  assert_false(check_connecting(p, k, zero, delta))
  assert_false(
    check_connecting(p, k, delta.classes, { ..delta, classes: zero, }),
  )
  assert_false(check_connecting(p, k, delta.classes, { ..delta, source: q, }))
  assert_false(
    check_connecting(p, k, delta.classes, {
      ..delta,
      source_homology: completed(q, 1),
    }),
  )
  assert_false(
    check_connecting(p, k, delta.classes, {
      ..delta,
      target_homology: absolute_completed(ambient(p), 0),
    }),
  )
  assert_false(
    check_connecting(p, k, delta.classes, { ..delta, lifted_cycles: zero, }),
  )
  assert_false(
    check_connecting(p, k, delta.classes, { ..delta, boundary_cycles: zero, }),
  )
  assert_false(
    check_connecting(p, k, delta.classes, { ..delta, cycle_map: zero, }),
  )
  assert_false(
    check_connecting(p, k, delta.classes, { ..delta, source_left_inverse: id, }),
  )
  assert_false(
    check_connecting(p, k, delta.classes, { ..delta, boundary_descent: id, }),
  )
  assert_eq(
    apply_connecting({ ..delta, source_left_inverse: id, }, @core.Nil),
    None,
  )
  assert_eq(compute(p, k, @oracle.nat(0)), BudgetExhausted)
}

///|
test "nonzero boundary descent and empty connecting target are checked" {
  let p = example([[0, 1, 2]], [[0, 1]])
  let delta = connecting(p, 1)
  assert_eq(rows(delta.boundary_descent), [[-1]])
  let changed = @matrix.matrix(
    @oracle.nat(1),
    @oracle.chain([@oracle.chain([@oracle.integer(0)])]),
  ).unwrap()
  assert_false(
    check_connecting(p, @oracle.nat(1), delta.classes, {
      ..delta,
      boundary_descent: changed,
    }),
  )
  let c = example([[0, 1], [0, 2], [1, 2]], [])
  let empty_target = connecting(c, 1)
  assert_eq(@matrix.height(empty_target.classes), @oracle.nat(0))
  assert_eq(@matrix.width(empty_target.classes), @oracle.nat(1))
  assert_eq(
    apply_connecting(empty_target, @oracle.chain([@oracle.integer(5)])),
    Some(@core.Nil),
  )
}
