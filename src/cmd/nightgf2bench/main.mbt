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
fn fixture(mode : String) -> (Array[Array[Bool]], Int32, Int32) {
  match mode {
    "tiny" => ([[true, false, true]], 3, 500000)
    "sparse" =>
      (
        Array::makei(8, fn(i) {
          Array::makei(32, fn(j) { j == i * 3 || j == 25 + i % 7 })
        }),
        32,
        2000,
      )
    "dense" | "solve-reuse" | "solve-setup" => {
      let rows = Array::makei(16, fn(i) {
        Array::makei(32, fn(j) {
          if j % 2 == 0 {
            j / 2 == i
          } else {
            (i * 29 + j * 17 + i * j * 7) % 11 < 6
          }
        })
      })
      (rows, 32, if mode == "dense" || mode == "solve-reuse" { 2000 } else { 500 })
    }
    _ => abort("unknown matrix fixture")
  }
}

///|
fn bench_matrix(mode : String) -> Unit {
  let (rows, width, iterations) = fixture(mode)
  let source = matrix(width, rows)
  let expected = @oracle.chain(nullspace(rows, width).map(@oracle.chain))
  let prepared = @gf2.factor(source).unwrap()
  let proof = @gf2.certificate(prepared).unwrap()
  check_rank(
    source,
    proof.reduced,
    proof.transform,
    proof.inverse_transform,
    proof.pivots,
  )
  if !@gf2.check_certificate(source, @gf2.reduction(prepared), proof) {
    abort("original factor checker rejected")
  }
  let expected_particular = @oracle.chain(Array::make(width, false))
  let rhs = @oracle.chain(Array::make(rows.length(), false))
  let wanted : @rowreduce.Solution[Bool] = if expected is Nil {
    Unique(expected_particular)
  } else {
    Affine(expected_particular, expected)
  }
  for _ in 0..<iterations {
    if mode == "solve-reuse" || mode == "solve-setup" {
      let factor = if mode == "solve-setup" {
        @gf2.factor(source).unwrap()
      } else {
        prepared
      }
      if @gf2.solve_factor(factor, rhs) != Some(wanted) {
        abort("complete affine solution differs from host oracle")
      }
      if mode == "solve-setup" {
        let witness = @gf2.certificate(factor).unwrap()
        if witness != proof ||
          !@gf2.check_certificate(source, @gf2.reduction(factor), witness) {
          abort("setup certificate changed")
        }
      }
    } else if @gf2.nullspace_factor(prepared) != expected {
      abort("complete ordered nullspace differs from host oracle")
    }
  }
  println(
    "{\"case\":\"\{mode}\",\"iterations\":\{iterations},\"basis\":\{encoded(@oracle.array(expected).map(@oracle.array))},\"particular\":\{encoded([@oracle.array(expected_particular)])},\"factor\":\{rank_json(source, proof.reduced, proof.transform, proof.inverse_transform, proof.pivots)},\"checked\":true}",
  )
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
fn bench_cohomology() -> Unit {
  let source = torus()
  let degree = @oracle.nat(1)
  let delta = coboundary(source, 1)
  let previous = coboundary(source, 0)
  let n = previous.length()
  let (_, outgoing_pivots) = rref(delta, n)
  let (_, incoming_pivots) = rref(previous, 7)
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
  let coordinates = product(inverse, previous, 7)
  let representatives = Array::makei(cycles.length() - boundaries.length(), fn(
    i,
  ) {
    cycles[boundaries.length() + i]
  })
  let expected = @co.Group::{
    rank: @oracle.nat(2),
    coboundaries: @oracle.chain(boundaries.map(@oracle.chain)),
    representatives: @oracle.chain(representatives.map(@oracle.chain)),
  }
  let iterations = 200
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
    "{\"case\":\"cohomology-torus\",\"iterations\":\{iterations},\"betti\":2,\"certificate\":\{full},\"checked\":true}",
  )
}

///|
fn main {
  let args = @env.args()
  let mode = args[args.length() - 1]
  match mode {
    "tiny" | "sparse" | "dense" | "solve-reuse" | "solve-setup" =>
      bench_matrix(mode)
    "cohomology-torus" => bench_cohomology()
    _ => abort("expected a frozen night GF2 case")
  }
}
