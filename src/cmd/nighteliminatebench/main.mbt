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
/// A product of unit triangular host matrices guarantees full row rank, making
/// the complete transform uniquely determined independently of producer order.
fn dense_rows(
  height : Int32,
  width : Int32,
  offset : Int32,
) -> Array[Array[Bool]] {
  let lower = Array::makei(height, fn(i) {
    Array::makei(height, fn(j) {
      i == j || (i > j && (i * 17 + j * 11 + i * j * 7) % 13 < 7)
    })
  })
  let upper = Array::makei(height, fn(i) {
    Array::makei(height, fn(j) {
      i == j || (i < j && (i * 19 + j * 7 + i * j * 3) % 11 < 6)
    })
  })
  let active = product(lower, upper, height)
  Array::makei(height, fn(i) {
    Array::makei(width, fn(j) {
      if j < offset {
        false
      } else if j < offset + height {
        active[i][j - offset]
      } else {
        (i * 19 + j * 11 + i * j * 7) % 13 < 7
      }
    })
  })
}

///|
fn fixture(mode : String) -> (Array[Array[Bool]], Int32, Int32) {
  match mode {
    "rref-tiny" => ([[false, true, true], [true, true, false]], 3, 400000)
    "rref-sparse" => (identity(24), 24, 5000)
    "rref-dense" => (dense_rows(24, 24, 0), 24, 2000)
    "rref-wide" => (dense_rows(12, 48, 20), 48, 2000)
    "factor-dense" => (dense_rows(24, 24, 0), 24, 400)
    "css-validate" => (dense_rows(16, 24, 0), 24, 400)
    _ => abort("unknown frozen elimination case")
  }
}

///|
fn host_certificate(source : @matrix.Matrix[Bool]) -> @gf2.Certificate {
  let rows = host(source)
  let width = @oracle.int_of_nat(@matrix.width(source))
  let height = rows.length()
  let units = identity(height)
  let augmented = rows.mapi(fn(i, row) { row + units[i] })
  let (reduced, pivots) = rref(augmented, width + height)
  if pivots.length() != height || pivots.any(fn(pivot) { pivot >= width }) {
    abort("host fixture must have full row rank")
  }
  let coefficients = reduced.map(fn(row) {
    Array::makei(width, fn(j) { row[j] })
  })
  let transform = reduced.map(fn(row) {
    Array::makei(height, fn(j) { row[width + j] })
  })
  {
    source,
    reduced: matrix(width, coefficients),
    transform: matrix(height, transform),
    inverse_transform: matrix(height, host_inverse(transform)),
    pivots: @oracle.chain(pivots.map(@oracle.nat)),
  }
}

///|
fn bench(mode : String) -> Unit {
  let (rows, width, iterations) = fixture(mode)
  let source = matrix(width, rows)
  let expected = host_certificate(source)
  let expected_result : @rowreduce.Reduction[Bool] = {
    matrix: expected.reduced,
    pivots: expected.pivots,
    factor: true,
  }
  check_rank(
    source,
    expected.reduced,
    expected.transform,
    expected.inverse_transform,
    expected.pivots,
  )
  if !@gf2.check_certificate(source, expected_result, expected) {
    abort("host full rank certificate rejected")
  }
  let empty = matrix(width, [])
  let empty_proof = host_certificate(empty)
  let mut payload = rank_json(
    source,
    expected.reduced,
    expected.transform,
    expected.inverse_transform,
    expected.pivots,
  )
  for _ in 0..<iterations {
    match mode {
      "factor-dense" => {
        let factor = @gf2.factor(source).unwrap()
        let actual = @gf2.certificate(factor).unwrap()
        if @gf2.reduction(factor) != expected_result ||
          actual != expected ||
          !@gf2.check_certificate(source, expected_result, actual) {
          abort("factor complete transform/certificate mismatch")
        }
      }
      "css-validate" => {
        let code = @css.validate(source, empty).unwrap()
        let proof = @css.certificate(code)
        let parameters = @css.parameters(code)
        let x = proof.x_rank
        let z = proof.z_rank
        if parameters.physical != @oracle.nat(width) ||
          parameters.rank_x != @oracle.nat(rows.length()) ||
          parameters.rank_z != @core.Zero ||
          parameters.logical != @oracle.nat(width - rows.length()) ||
          x.source != expected.source ||
          x.reduced != expected.reduced ||
          x.transform != expected.transform ||
          x.inverse_transform != expected.inverse_transform ||
          x.pivots != expected.pivots ||
          z.source != empty_proof.source ||
          z.reduced != empty_proof.reduced ||
          z.transform != empty_proof.transform ||
          z.inverse_transform != empty_proof.inverse_transform ||
          z.pivots != empty_proof.pivots ||
          !@css.check_parameters(code, parameters, proof) {
          abort("CSS complete parameter/rank certificate mismatch")
        }
      }
      _ =>
        if @gf2.rref(source) != Some(expected_result) {
          abort("RREF full matrix or pivot order mismatch")
        }
    }
  }
  if mode == "css-validate" {
    payload = "{\"x_rank\":\{payload},\"z_rank\":\{rank_json(empty,empty_proof.reduced,empty_proof.transform,empty_proof.inverse_transform,empty_proof.pivots)},\"physical\":\{width},\"rank_x\":\{rows.length()},\"rank_z\":0,\"logical\":\{width-rows.length()}}"
  }
  println(
    "{\"case\":\"\{mode}\",\"iterations\":\{iterations},\"full_result\":\{payload},\"checked\":true}",
  )
}

///|
fn main {
  let args = @env.args()
  bench(args[args.length() - 1])
}
