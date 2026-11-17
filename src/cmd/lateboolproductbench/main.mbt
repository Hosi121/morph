///|
/// Frozen host-only integer-indexed Boolean oracle. Production kernels remain
/// immutable ADTs; the executable deliberately shares no nullspace helper.
fn matrix(width : Int32, rows : Array[Array[Bool]]) -> @matrix.Matrix[Bool] {
  @matrix.matrix(@oracle.nat(width), @oracle.chain(rows.map(@oracle.chain))).unwrap()
}

///|
fn host(input : @matrix.Matrix[Bool]) -> Array[Array[Bool]] {
  @oracle.array(@matrix.rows(input)).map(@oracle.array)
}

///|
fn identity(n : Int32) -> Array[Array[Bool]] {
  Array::makei(n, fn(i) { Array::makei(n, fn(j) { i == j }) })
}

///|
fn product(
  a : Array[Array[Bool]],
  b : Array[Array[Bool]],
  width : Int32,
) -> Array[Array[Bool]] {
  a.map(fn(row) {
    Array::makei(width, fn(j) {
      let mut bit = false
      for k in 0..<row.length() {
        bit = bit != (row[k] && b[k][j])
      }
      bit
    })
  })
}

///|
fn transpose(rows : Array[Array[Bool]], width : Int32) -> Array[Array[Bool]] {
  Array::makei(width, fn(j) { rows.map(fn(row) { row[j] }) })
}

///|
fn rref(
  rows : Array[Array[Bool]],
  width : Int32,
) -> (Array[Array[Bool]], Array[Int32]) {
  let rows = rows.map(fn(row) { row.copy() })
  let pivots = []
  let mut top = 0
  for column in 0..<width {
    let mut chosen = top
    while chosen < rows.length() && !rows[chosen][column] {
      chosen += 1
    }
    if chosen < rows.length() {
      let tmp = rows[top]
      rows[top] = rows[chosen]
      rows[chosen] = tmp
      for target in 0..<rows.length() {
        if target != top && rows[target][column] {
          for j in 0..<width {
            rows[target][j] = rows[target][j] != rows[top][j]
          }
        }
      }
      pivots.push(column)
      top += 1
    }
  }
  (rows, pivots)
}

///|
fn nullspace(rows : Array[Array[Bool]], width : Int32) -> Array[Array[Bool]] {
  let (reduced, pivots) = rref(rows, width)
  let result = []
  for free in 0..<width {
    if !pivots.contains(free) {
      let vector = Array::make(width, false)
      vector[free] = true
      for i, pivot in pivots {
        vector[pivot] = reduced[i][free]
      }
      result.push(vector)
    }
  }
  result
}

///|
fn host_inverse(rows : Array[Array[Bool]]) -> Array[Array[Bool]] {
  let n = rows.length()
  let augmented = rows.mapi(fn(i, row) { row + identity(n)[i] })
  let (result, pivots) = rref(augmented, n + n)
  if pivots.length() != n {
    abort("host basis inverse does not exist")
  }
  result.map(fn(row) { Array::makei(n, fn(j) { row[n + j] }) })
}

///|
fn ints(xs : Array[Int32]) -> String {
  "[" + xs.map(fn(x) { x.to_string() }).join(",") + "]"
}

///|
fn encoded(rows : Array[Array[Bool]]) -> String {
  "[" +
  rows.map(fn(row) { ints(row.map(fn(x) { if x { 1 } else { 0 } })) }).join(",") +
  "]"
}

///|
fn encoded_matrix(input : @matrix.Matrix[Bool]) -> String {
  "{\"width\":\{@oracle.int_of_nat(@matrix.width(input))},\"rows\":\{encoded(host(input))}}"
}

///|
fn rank_json(
  source : @matrix.Matrix[Bool],
  reduced : @matrix.Matrix[Bool],
  transform : @matrix.Matrix[Bool],
  inverse_transform : @matrix.Matrix[Bool],
  pivots : @core.Chain[@core.Nat],
) -> String {
  "{\"source\":\{encoded_matrix(source)},\"reduced\":\{encoded_matrix(reduced)},\"transform\":\{encoded_matrix(transform)},\"inverse_transform\":\{encoded_matrix(inverse_transform)},\"pivots\":\{ints(@oracle.array(pivots).map(@oracle.int_of_nat))}}"
}

///|
fn check_rank(
  source : @matrix.Matrix[Bool],
  reduced : @matrix.Matrix[Bool],
  transform : @matrix.Matrix[Bool],
  inverse_transform : @matrix.Matrix[Bool],
  pivots : @core.Chain[@core.Nat],
) -> Unit {
  let rows = host(source)
  let width = @oracle.int_of_nat(@matrix.width(source))
  let (wanted, wanted_pivots) = rref(rows, width)
  let u = host(transform)
  let v = host(inverse_transform)
  if host(reduced) != wanted ||
    @oracle.array(pivots).map(@oracle.int_of_nat) != wanted_pivots ||
    product(u, rows, width) != wanted ||
    product(u, v, rows.length()) != identity(rows.length()) ||
    product(v, u, rows.length()) != identity(rows.length()) {
    abort("complete rank certificate differs from host matrix oracle")
  }
}

///|
fn torus() -> @hom.Complex {
  let facets = [
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
  ]
  @hom.closure(
    @oracle.chain(facets.map(fn(face) { @oracle.chain(face.map(@oracle.nat)) })),
  ).unwrap()
}

///|
/// Incidence comes from host face deletion in the public simplex order,
/// without calling production boundary, coboundary or sparse operators.
fn coboundary(source : @hom.Complex, degree : Int32) -> Array[Array[Bool]] {
  let from = @oracle.array(@hom.simplices(source, @oracle.nat(degree))).map(fn(
    face,
  ) {
    @oracle.array(face).map(@oracle.int_of_nat)
  })
  let to = @oracle.array(@hom.simplices(source, @oracle.nat(degree + 1))).map(fn(
    face,
  ) {
    @oracle.array(face).map(@oracle.int_of_nat)
  })
  to.map(fn(simplex) {
    from.map(fn(face) {
      let mut found = false
      for omit in 0..<simplex.length() {
        let removed = []
        for j, vertex in simplex {
          if j != omit {
            removed.push(vertex)
          }
        }
        if removed == face {
          found = true
        }
      }
      found
    })
  })
}

///|
fn select_columns(
  rows : Array[Array[Bool]],
  indices : Array[Int32],
) -> Array[Array[Bool]] {
  indices.map(fn(index) { rows.map(fn(row) { row[index] }) })
}

///|
fn bench_cohomology(mode : String) -> Unit {
  let source = if mode == "cohomology-circle" {
    @hom.closure(
      @oracle.chain(
        [[0, 1], [0, 2], [1, 2]].map(fn(face) {
          @oracle.chain(face.map(@oracle.nat))
        }),
      ),
    ).unwrap()
  } else {
    torus()
  }
  let degree = @oracle.nat(1)
  let delta = coboundary(source, 1)
  let previous = coboundary(source, 0)
  let n = previous.length()
  let vertices = @oracle.array(@hom.simplices(source, @oracle.nat(0))).length()
  let (_, outgoing_pivots) = rref(delta, n)
  let (_, incoming_pivots) = rref(previous, vertices)
  let boundaries = select_columns(previous, incoming_pivots)
  let candidates = transpose(boundaries + nullspace(delta, n), n)
  let (_, cycle_pivots) = rref(
    candidates,
    boundaries.length() + n - outgoing_pivots.length(),
  )
  let cycles = select_columns(candidates, cycle_pivots)
  let complements = select_columns(identity(n), outgoing_pivots)
  let basis = transpose(cycles + complements, n)
  let inverse = host_inverse(basis)
  let coordinates = product(inverse, previous, vertices)
  let representatives = Array::makei(cycles.length() - boundaries.length(), fn(
    i,
  ) {
    cycles[boundaries.length() + i]
  })
  let expected = @co.Group::{
    rank: @oracle.nat(if mode == "cohomology-circle" { 1 } else { 2 }),
    coboundaries: @oracle.chain(boundaries.map(@oracle.chain)),
    representatives: @oracle.chain(representatives.map(@oracle.chain)),
  }
  let iterations = if mode == "cohomology-circle" { 5000 } else { 200 }
  let reference = @co.certificate(@co.compute(source, degree).unwrap())
  for _ in 0..<iterations {
    let space = @co.compute(source, degree).unwrap()
    let proof = @co.certificate(space)
    if @co.result(space) != expected ||
      proof.result != expected ||
      proof.source != source ||
      proof.degree != degree ||
      host(proof.basis) != basis ||
      host(proof.inverse_basis) != inverse ||
      host(proof.incoming_coordinates) != coordinates ||
      host(proof.outgoing_rank.source) != delta ||
      host(proof.incoming_rank.source) != previous ||
      proof != reference ||
      !@co.check_result(source, degree, expected, proof) {
      abort("cohomology complete basis/certificate differs from host oracle")
    }
  }
  let a = reference.outgoing_rank
  let b = reference.incoming_rank
  check_rank(a.source, a.reduced, a.transform, a.inverse_transform, a.pivots)
  check_rank(b.source, b.reduced, b.transform, b.inverse_transform, b.pivots)
  let full = "{\"outgoing\":\{rank_json(a.source,a.reduced,a.transform,a.inverse_transform,a.pivots)},\"incoming\":\{rank_json(b.source,b.reduced,b.transform,b.inverse_transform,b.pivots)},\"basis\":\{encoded(basis)},\"inverse_basis\":\{encoded(inverse)},\"incoming_coordinates\":\{encoded(coordinates)},\"boundaries\":\{encoded(boundaries)},\"representatives\":\{encoded(representatives)}}"
  println(
    "{\"case\":\"\{mode}\",\"iterations\":\{iterations},\"betti\":\{@oracle.int_of_nat(expected.rank)},\"certificate\":\{full},\"checked\":true}",
  )
}

///|
fn product_fixtures(
  mode : String,
) -> (Array[(Array[Array[Bool]], Int32, Array[Array[Bool]], Int32)], Int32) {
  match mode {
    "tiny-and-shapes" =>
      (
        [
          (
            [[true, false, true], [false, true, true]],
            3,
            [[true, false], [true, true], [false, true]],
            2,
          ),
          (
            [],
            3,
            [
              [true, false, true, false],
              [false, true, false, true],
              [true, true, false, false],
            ],
            4,
          ),
          ([[], [], []], 0, [], 4),
          ([[true, false], [false, true]], 2, [[], []], 0),
          ([], 0, [], 0),
          ([], 2, [], 3),
          ([[true]], 1, [[true], [false]], 1),
          ([[true, false]], 2, [], 0),
          ([[]], 0, [], 0),
        ],
        20000,
      )
    "sparse" =>
      (
        [
          (
            Array::makei(24, fn(i) {
              Array::makei(32, fn(j) { j == i || j == (i * 7 + 3) % 32 })
            }),
            32,
            Array::makei(32, fn(i) { Array::makei(16, fn(j) { j == i % 16 }) }),
            16,
          ),
        ],
        1000,
      )
    "dense" | "zero" =>
      (
        [
          (
            Array::makei(24, fn(i) {
              Array::makei(32, fn(j) {
                mode != "zero" && (i * 17 + j * 11 + i * j * 7) % 13 < 7
              })
            }),
            32,
            Array::makei(32, fn(i) {
              Array::makei(24, fn(j) { (i * 13 + j * 19 + i * j * 3) % 11 < 6 })
            }),
            24,
          ),
        ],
        1000,
      )
    _ => abort("unknown product fixture")
  }
}

///|
fn optional_matrix(value : @matrix.Matrix[Bool]?) -> String {
  match value {
    None => "null"
    Some(value) => encoded_matrix(value)
  }
}

///|
fn bench_product(mode : String) -> Unit {
  let (fixtures, iterations) = product_fixtures(mode)
  let prepared = fixtures.map(fn(fixture) {
    let (left, width, right, out_width) = fixture
    let a = matrix(width, left)
    let b = matrix(out_width, right)
    let expected = if width == right.length() {
      Some(matrix(out_width, product(left, right, out_width)))
    } else {
      None
    }
    // Old generic callbacks are retained as a separate oracle; the complete
    // host result includes dimensions even when there are no rows or columns.
    if @matrix.multiply(a, b, @gf2.scalars()) != expected {
      abort("host and old generic matrix products disagree")
    }
    (a, b, expected)
  })
  for _ in 0..<iterations {
    for fixture in prepared {
      let (a, b, expected) = fixture
      if @gf2.multiply(a, b) != expected {
        abort(
          "complete Bool product or dimensions differ from independent oracle",
        )
      }
    }
  }
  let outputs = prepared
    .map(fn(fixture) {
      let (a, b, expected) = fixture
      "{\"left\":\{encoded_matrix(a)},\"right\":\{encoded_matrix(b)},\"result\":\{optional_matrix(expected)}}"
    })
    .join(",")
  println(
    "{\"case\":\"\{mode}\",\"iterations\":\{iterations},\"outputs\":[\{outputs}],\"checked\":true}",
  )
}

///|
fn main {
  let args = @env.args()
  let mode = args[args.length() - 1]
  match mode {
    "tiny-and-shapes" | "sparse" | "dense" | "zero" => bench_product(mode)
    "cohomology-circle" | "cohomology-torus" => bench_cohomology(mode)
    _ => abort("expected one of six frozen Bool product/consumer cases")
  }
}
