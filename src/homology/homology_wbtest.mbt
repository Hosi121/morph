///|
fn inputs(faces : Array[Array[Int32]]) -> @core.Chain[@core.Chain[@core.Nat]] {
  @oracle.chain(faces.map(fn(face) { @oracle.chain(face.map(@oracle.nat)) }))
}

///|
fn generated(facets : Array[Array[Int32]]) -> Complex {
  closure(inputs(facets)).unwrap()
}

///|
fn completed(complex : Complex, degree : Int32) -> Certificate {
  match compute(complex, @oracle.nat(degree), @oracle.nat(2000)) {
    Computed(witness) => witness
    _ => abort("finite fixture must finish with a checked certificate")
  }
}

///|
fn expected_group(free : Int32, torsion : Array[Int32]) -> ResultGroup {
  {
    free_rank: @oracle.nat(free),
    torsion: @oracle.chain(torsion.map(@oracle.binary)),
  }
}

///|
fn int_rows(input : @matrix.Matrix[@exact.Integer]) -> Array[Array[Int32]] {
  @oracle.array(@matrix.rows(input)).map(fn(row) {
    @oracle.array(row).map(@oracle.int_of_integer)
  })
}

///|
// Independent test-only elimination over GF(2), using machine array arithmetic.
fn gf2_rank(input : @matrix.Matrix[@exact.Integer]) -> Int32 {
  let a = int_rows(input).map(fn(row) { row.map(fn(x) { x.abs() % 2 }) })
  let width = @oracle.int_of_nat(@matrix.width(input))
  let mut rank = 0
  for column in 0..<width {
    let mut pivot = -1
    for row in rank..<a.length() {
      if pivot < 0 && a[row][column] != 0 {
        pivot = row
      }
    }
    if pivot >= 0 {
      let temporary = a[rank]
      a[rank] = a[pivot]
      a[pivot] = temporary
      for row in (rank + 1)..<a.length() {
        if a[row][column] != 0 {
          for j in column..<width {
            a[row][j] = (a[row][j] + a[rank][j]) % 2
          }
        }
      }
      rank += 1
    }
  }
  rank
}

///|
fn gf2_betti(complex : Complex, k : Int32) -> Int32 {
  let a = boundary(complex, @oracle.nat(k)).unwrap()
  let b = boundary(complex, @oracle.nat(k + 1)).unwrap()
  @oracle.int_of_nat(@matrix.width(a)) - gf2_rank(a) - gf2_rank(b)
}

///|
fn verify(
  complex : Complex,
  degree : Int32,
  free : Int32,
  torsion : Array[Int32],
) -> Unit raise {
  let k = @oracle.nat(degree)
  let witness = completed(complex, degree)
  assert_eq(result(witness), expected_group(free, torsion))
  assert_true(check_result(complex, k, result(witness), witness))
  assert_true(boundary_squared_zero(complex, k))
  // Every cycle generator is tested directly in original simplex coordinates.
  let d = boundary(complex, k).unwrap()
  for vector in @oracle.array(cycle_basis(witness)) {
    let column = @matrix.matrix(
      @oracle.nat(1),
      @core.map(vector, fn(value) { @core.Cons(value, @core.Nil) }),
    ).unwrap()
    assert_true(zero_matrix(@matrix.multiply(d, column, integers()).unwrap()))
  }
}

///|
test "validation rejects noncanonical simplices missing faces and duplicate faces" {
  assert_eq(validate(inputs([[0, 1]])), None)
  assert_eq(validate(inputs([[0], [1], [0, 1], [0, 1]])), None)
  assert_eq(validate(inputs([[0], [1], [1, 0]])), None)
  assert_eq(validate(inputs([[0], [0, 0]])), None)
  assert_eq(validate(inputs([[]])), None)
  assert_eq(closure(inputs([[]])), None)
  assert_eq(closure(inputs([[1, 0]])), None)
  assert_eq(closure(inputs([[0, 0]])), None)
  let edge = generated([[0, 1]])
  assert_eq(validate(inputs([[1], [0, 1], [0]])), Some(edge))
  assert_eq(closure(inputs([[0, 1], [0, 1], [0]])), Some(edge))
}

///|
test "oriented boundary uses alternating deletion signs and unreduced zero map" {
  let triangle = generated([[0, 1, 2]])
  assert_eq(int_rows(boundary(triangle, @oracle.nat(1)).unwrap()), [
    [-1, -1, 0],
    [1, 0, -1],
    [0, 1, 1],
  ])
  assert_eq(int_rows(boundary(triangle, @oracle.nat(2)).unwrap()), [
    [1],
    [-1],
    [1],
  ])
  let d0 = boundary(triangle, @oracle.nat(0)).unwrap()
  assert_eq(@matrix.height(d0), @oracle.nat(0))
  assert_eq(@matrix.width(d0), @oracle.nat(3))
  let d3 = boundary(triangle, @oracle.nat(3)).unwrap()
  assert_eq(@matrix.height(d3), @oracle.nat(1))
  assert_eq(@matrix.width(d3), @oracle.nat(0))
  verify(triangle, 3, 0, [])
  verify(triangle, 7, 0, [])
}

///|
test "empty complex points disconnected components circle and filled triangle" {
  let empty = generated([])
  verify(empty, 0, 0, [])
  verify(empty, 1, 0, [])
  verify(generated([[12]]), 0, 1, [])
  verify(generated([[0], [4], [9]]), 0, 3, [])
  let circle = generated([[0, 1], [0, 2], [1, 2]])
  verify(circle, 0, 1, [])
  verify(circle, 1, 1, [])
  verify(circle, 2, 0, [])
  let filled = generated([[0, 1, 2]])
  verify(filled, 0, 1, [])
  verify(filled, 1, 0, [])
  verify(filled, 2, 0, [])
  let disconnected = generated([[0, 1], [0, 2], [1, 2], [8], [11, 12]])
  verify(disconnected, 0, 3, [])
  verify(disconnected, 1, 1, [])
}

///|
test "tetrahedral sphere and filled tetrahedron distinguish a top-dimensional cycle" {
  let sphere = generated([[0, 1, 2], [0, 1, 3], [0, 2, 3], [1, 2, 3]])
  verify(sphere, 0, 1, [])
  verify(sphere, 1, 0, [])
  verify(sphere, 2, 1, [])
  assert_eq(euler_characteristic(sphere), @oracle.integer(2))
  let solid = generated([[0, 1, 2, 3]])
  verify(solid, 0, 1, [])
  verify(solid, 1, 0, [])
  verify(solid, 2, 0, [])
  verify(solid, 3, 0, [])
}

///|
// Facets are the exact official Sage RealProjectivePlane example, with the
// increasing vertex order already given in that source (see research note).
fn projective_plane() -> Complex {
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
fn torus() -> Complex {
  generated([
    [0, 1, 2],
    [1, 2, 4],
    [1, 3, 4],
    [1, 3, 6],
    [0, 1, 5],
    [1, 5, 6],
    [2, 3, 5],
    [2, 4, 5],
    [2, 3, 6],
    [0, 2, 6],
    [0, 3, 4],
    [0, 3, 5],
    [4, 5, 6],
    [0, 4, 6],
  ])
}

///|
test "verified six vertex projective plane detects integral two torsion" {
  let plane = projective_plane()
  assert_eq(@core.length(simplices(plane, @oracle.nat(0))), @oracle.nat(6))
  assert_eq(@core.length(simplices(plane, @oracle.nat(1))), @oracle.nat(15))
  assert_eq(@core.length(simplices(plane, @oracle.nat(2))), @oracle.nat(10))
  verify(plane, 0, 1, [])
  verify(plane, 1, 0, [2])
  verify(plane, 2, 0, [])
  assert_eq(euler_characteristic(plane), @oracle.integer(1))
}

///|
test "verified seven vertex torus has two free one cycles and fundamental class" {
  let surface = torus()
  verify(surface, 0, 1, [])
  verify(surface, 1, 2, [])
  verify(surface, 2, 1, [])
  assert_eq(euler_characteristic(surface), @oracle.integer(0))
}

///|
test "certificate rejects changed source degree actual result and individual witnesses" {
  let circle = generated([[0, 1], [0, 2], [1, 2]])
  let k = @oracle.nat(1)
  let good = completed(circle, 1)
  let actual = result(good)
  let filled = generated([[0, 1, 2]])
  assert_false(check_result(filled, k, actual, good))
  assert_false(check_result(circle, @oracle.nat(0), actual, good))
  assert_false(check_result(circle, k, expected_group(0, []), good))
  assert_false(check_result(circle, k, expected_group(1, [2]), good))
  let wrong = expected_group(0, [2])
  assert_false(check_result(circle, k, wrong, { ..good, result: wrong, }))
  assert_false(check_result(circle, k, actual, { ..good, source: filled, }))
  assert_false(
    check_result(circle, k, actual, { ..good, result: expected_group(2, []), }),
  )
  assert_false(
    check_result(circle, k, actual, {
      ..good,
      right_inverse: @matrix.identity(@oracle.nat(3), integers()),
    }),
  )
  let bad_coordinates = @matrix.matrix(
    @oracle.nat(0),
    @core.replicate(@oracle.nat(2), @core.Nil),
  ).unwrap()
  assert_false(
    check_result(circle, k, actual, { ..good, coordinates: bad_coordinates, }),
  )
  let other = completed(filled, 1)
  assert_false(
    check_result(circle, k, actual, { ..good, image_form: other.image_form, }),
  )
  assert_false(
    check_result(circle, k, actual, {
      ..good,
      boundary_form: completed(circle, 0).boundary_form,
    }),
  )
  assert_eq(compute(circle, k, @oracle.nat(0)), BudgetExhausted)
}
