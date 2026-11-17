///|
fn matrix(
  rows : Array[Array[Int32]],
  width : Int32,
) -> @matrix.Matrix[@exact.Integer] {
  @matrix.matrix(
    @oracle.nat(width),
    @oracle.chain(rows.map(fn(row) { @oracle.chain(row.map(@oracle.integer)) })),
  ).unwrap()
}

///|
fn identity(n : Int32) -> Array[Array[Int32]] {
  Array::makei(n, fn(i) {
    Array::makei(n, fn(j) { if i == j { 1 } else { 0 } })
  })
}

///|
fn product(
  a : Array[Array[Int32]],
  b : Array[Array[Int32]],
  width : Int32,
) -> Array[Array[Int32]] {
  a.map(fn(row) {
    Array::makei(width, fn(j) {
      let mut sum = 0
      for k in 0..<row.length() {
        sum += row[k] * b[k][j]
      }
      sum
    })
  })
}

///|
fn quoted(text : String) -> String {
  "\"" +
  text
  .replace_all(old="\\", new="\\\\")
  .replace_all(old="\"", new="\\\"")
  .replace_all(old="\n", new="\\n")
  .replace_all(old="\r", new="\\r")
  .replace_all(old="\t", new="\\t") +
  "\""
}

///|
fn emit(mode : String, iterations : Int32, full : String) -> Unit {
  println(
    "{\"case\":\{quoted(mode)},\"iterations\":\{iterations},\"complete_repr\":\{quoted(full)},\"checked\":true}",
  )
}

///|
fn direct(mode : String) -> Unit {
  let n = if mode == "many" { 8 } else { 4 }
  let width = if mode == "one" { 1 } else { 8 }
  let divisors = if n == 8 { [1, 1, 2, 2, 6, 6, 0, 0] } else { [1, 2, 6, 0] }
  let d = Array::makei(n, fn(i) {
    Array::makei(n, fn(j) { if i == j { divisors[i] } else { 0 } })
  })
  let u = identity(n)
  let ui = identity(n)
  let source_inverse = identity(width)
  if mode == "bases" {
    u[1][0] = 1
    ui[1][0] = -1
    u[3][2] = 1
    ui[3][2] = -1
    source_inverse[1][0] = -1
  }
  let original = matrix(product(ui, d, n), n)
  let diagonal = matrix(d, n)
  let left = matrix(u, n)
  let right = matrix(identity(n), n)
  let form = @smith.check(original, left, diagonal, right).unwrap()
  let input = Array::makei(n, fn(i) {
    Array::makei(width, fn(j) { (i * 7 + j * 11) % 23 - 11 })
  })
  let lift = product(product(u, input, width), source_inverse, width)
  let wanted = matrix(
    lift.mapi(fn(i, row) {
      row.map(fn(x) {
        let divisor = divisors[i]
        if divisor == 0 {
          x
        } else {
          (x % divisor + divisor) % divisor
        }
      })
    }),
    width,
  )
  let cycle = matrix(input, width)
  let inverse = matrix(source_inverse, width)
  let iterations = 1000
  for _ in 0..<iterations {
    if @ch.canonical_columns(form, cycle, inverse) != Some(wanted) {
      abort(
        "full direct result differs from independent host integer product/residue oracle",
      )
    }
  }
  emit(mode, iterations, "\{@debug.Repr((form, cycle, inverse, wanted))}")
}

///|
fn empty() -> Unit {
  let z = matrix([], 0)
  let id = matrix(identity(4), 4)
  let form = @smith.check(id, id, id, id).unwrap()
  let empty_rows = matrix([[], [], []], 0)
  let bad_columns = matrix([[1], [2], [3]], 1)
  let one = matrix([[1]], 1)
  let iterations = 5000
  for _ in 0..<iterations {
    if @ch.canonical_columns(form, empty_rows, z) != Some(empty_rows) ||
      @ch.canonical_columns(form, z, one) != None ||
      @ch.canonical_columns(form, bad_columns, one) != None {
      abort("empty and None contract mismatch")
    }
  }
  emit(
    "empty",
    iterations,
    "\{@debug.Repr((form, empty_rows, z, bad_columns, one, Some(empty_rows), (@ch.canonical_columns(form, z, one))))}",
  )
}

///|
fn complex(facets : Array[Array[Int32]]) -> @hom.Complex {
  @hom.closure(
    @oracle.chain(facets.map(fn(row) { @oracle.chain(row.map(@oracle.nat)) })),
  ).unwrap()
}

///|
fn completed(source : @hom.Complex, degree : Int32) -> @hom.Certificate {
  match @hom.compute(source, @oracle.nat(degree), @oracle.nat(3000)) {
    Computed(c) => c
    _ => abort("homology fixture did not complete")
  }
}

///|
fn induced() -> Unit {
  let source = complex([[0], [1], [2], [3]])
  let degree = @oracle.nat(0)
  let cert = completed(source, 0)
  let map = @sm.identity(source)
  let expected = matrix(identity(4), 4)
  let reference = @sm.induce(map, degree, cert, cert).unwrap()
  let iterations = 40
  for _ in 0..<iterations {
    let actual = @sm.induce(map, degree, cert, cert).unwrap()
    if actual != reference ||
      actual.classes != expected ||
      !@sm.check_induced(map, degree, expected, actual) ||
      @sm.induce(map, @oracle.nat(1), cert, cert) != None {
      abort("induced complete certificate/identity/None mismatch")
    }
  }
  emit("induced", iterations, "\{@debug.Repr(reference)}")
}

///|
fn connecting() -> Unit {
  let sub = complex([[0], [1]])
  let pair = @rel.pair(complex([[0, 1]]), sub).unwrap()
  let degree = @oracle.nat(1)
  let source = match @rel.compute(pair, degree, @oracle.nat(3000)) {
    Computed(c) => c
    _ => abort("relative fixture did not complete")
  }
  let target = completed(sub, 0)
  let expected = matrix([[-1], [1]], 1)
  let reference = @rel.connect(pair, degree, source, target).unwrap()
  let iterations = 40
  for _ in 0..<iterations {
    let actual = @rel.connect(pair, degree, source, target).unwrap()
    if actual != reference ||
      actual.classes != expected ||
      !@rel.check_connecting(pair, degree, expected, actual) ||
      @rel.connect(pair, @oracle.nat(0), source, target) != None {
      abort("connecting complete certificate/orientation/None mismatch")
    }
  }
  emit("connecting", iterations, "\{@debug.Repr(reference)}")
}

///|
fn main {
  let args = @env.args()
  match args[args.length() - 1] {
    "one" => direct("one")
    "many" => direct("many")
    "bases" => direct("bases")
    "empty" => empty()
    "induced" => induced()
    "connecting" => connecting()
    _ => abort("expected frozen smith context case")
  }
}
