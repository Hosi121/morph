///|
/// Frozen host-only harness. Integer matrices and Boolean sparse sets provide
/// expected results without using production arithmetic or sparse XOR.
fn imat(
  width : Int32,
  rows : Array[Array[Int32]],
) -> @matrix.Matrix[@exact.Integer] {
  @matrix.matrix(
    @oracle.nat(width),
    @oracle.chain(rows.map(fn(row) { @oracle.chain(row.map(@oracle.integer)) })),
  ).unwrap()
}

///|
fn host_matrix(matrix : @matrix.Matrix[@exact.Integer]) -> Array[Array[Int32]] {
  @oracle.array(@matrix.rows(matrix)).map(fn(row) {
    @oracle.array(row).map(@oracle.int_of_integer)
  })
}

///|
fn identity(n : Int32) -> Array[Array[Int32]] {
  Array::makei(n, fn(i) {
    Array::makei(n, fn(j) { if i == j { 1 } else { 0 } })
  })
}

///|
fn swap_rows(a : Array[Array[Int32]], i : Int32, j : Int32) -> Unit {
  let x = a[i]
  a[i] = a[j]
  a[j] = x
}

///|
fn add_rows(a : Array[Array[Int32]], i : Int32, j : Int32, q : Int32) -> Unit {
  let source = a[j].copy()
  for k in 0..<a[i].length() {
    a[i][k] += q * source[k]
  }
}

///|
fn swap_cols(a : Array[Array[Int32]], i : Int32, j : Int32) -> Unit {
  for row in a {
    let x = row[i]
    row[i] = row[j]
    row[j] = x
  }
}

///|
fn add_cols(a : Array[Array[Int32]], i : Int32, j : Int32, q : Int32) -> Unit {
  for row in a {
    row[i] += q * row[j]
  }
}

///|
/// The legacy Euclidean schedule in independent machine integers. Keeping its
/// operation order lets the frozen CLI compare complete U and V, not just D.
fn smith_oracle(
  input : Array[Array[Int32]],
  width : Int32,
) -> (Array[Array[Int32]], Array[Array[Int32]], Array[Array[Int32]]) {
  let a = input.map(fn(row) { row.copy() })
  let u = identity(a.length())
  let v = identity(width)
  let mut k = 0
  let mut steps = 0
  while k < a.length() && k < width {
    steps += 1
    if steps > 1000 {
      abort("host Smith schedule exceeded bound")
    }
    if a[k][k] == 0 {
      let mut found = false
      for i in k..<a.length() {
        for j in k..<width {
          if !found && a[i][j] != 0 {
            swap_rows(a, k, i)
            swap_rows(u, k, i)
            swap_cols(a, k, j)
            swap_cols(v, k, j)
            found = true
          }
        }
      }
      if !found {
        break
      }
      continue
    }
    let mut acted = false
    for i in (k + 1)..<a.length() {
      if !acted && a[i][k] != 0 {
        let q = -(a[i][k] / a[k][k])
        add_rows(a, i, k, q)
        add_rows(u, i, k, q)
        if a[i][k] != 0 {
          swap_rows(a, i, k)
          swap_rows(u, i, k)
        }
        acted = true
      }
    }
    if acted {
      continue
    }
    for j in (k + 1)..<width {
      if !acted && a[k][j] != 0 {
        let q = -(a[k][j] / a[k][k])
        add_cols(a, j, k, q)
        add_cols(v, j, k, q)
        if a[k][j] != 0 {
          swap_cols(a, j, k)
          swap_cols(v, j, k)
        }
        acted = true
      }
    }
    if acted {
      continue
    }
    for i in (k + 1)..<a.length() {
      for j in (k + 1)..<width {
        if !acted && a[i][j] % a[k][k] != 0 {
          add_rows(a, k, i, 1)
          add_rows(u, k, i, 1)
          acted = true
        }
      }
    }
    if acted {
      continue
    }
    if a[k][k] < 0 {
      for j in 0..<width {
        a[k][j] = -a[k][j]
      }
      for j in 0..<u[k].length() {
        u[k][j] = -u[k][j]
      }
    }
    k += 1
  }
  (u, a, v)
}

///|
fn ints(values : Array[Int32]) -> String {
  "[" + values.map(fn(x) { x.to_string() }).join(",") + "]"
}

///|
fn nested(values : Array[Array[Int32]]) -> String {
  "[" + values.map(ints).join(",") + "]"
}

///|
fn smith_case(mode : String) -> (Array[Array[Int32]], Int32, Int32) {
  match mode {
    "smith-small" => ([[2, 4], [6, 8]], 2, 30000)
    "smith-rectangular" =>
      ([[2, 4, 6, 8, 10, 12], [8, 10, 12, 14, 16, 18]], 6, 6000)
    "smith-dense" =>
      ([[12, 6, 4, 2], [3, 9, 6, 8], [2, 16, 14, 6], [4, 2, 10, 12]], 4, 4000)
    _ => abort("unknown Smith case")
  }
}

///|
fn bench_smith(mode : String) -> Unit {
  let (rows, width, iterations) = smith_case(mode)
  let (u, d, v) = smith_oracle(rows, width)
  let input = imat(width, rows)
  let expected_u = imat(rows.length(), u)
  let expected_d = imat(width, d)
  let expected_v = imat(width, v)
  let fuel = @oracle.nat(2000)
  for _ in 0..<iterations {
    match @smith.run(@smith.start(input), fuel) {
      @smith.Done(result) =>
        if @smith.original(result) != input ||
          @smith.left(result) != expected_u ||
          @smith.diagonal(result) != expected_d ||
          @smith.right(result) != expected_v ||
          @smith.check(
            input,
            @smith.left(result),
            @smith.diagonal(result),
            @smith.right(result),
          ) !=
          Some(result) {
          abort(
            "Smith full witness differs from host integer schedule or checker",
          )
        }
      _ => abort("Smith public reduction did not complete")
    }
  }
  // Exercise host conversion too; the result itself is emitted in full.
  if host_matrix(expected_d) != d {
    abort("integer round trip failed")
  }
  println(
    "{\"case\":\"\{mode}\",\"iterations\":\{iterations},\"u\":\{nested(u)},\"d\":\{nested(d)},\"v\":\{nested(v)},\"checked\":true}",
  )
}

///|
fn simplices(mode : String) -> (Array[Array[Int32]], Int32) {
  let n = match mode {
    "persistence-tiny" => 2
    "persistence-sparse" => 12
    "persistence-collisions" => 7
    _ => abort("unknown persistence case")
  }
  let result = Array::makei(n, fn(i) { [i] })
  for i in 0..<n {
    for j in (i + 1)..<n {
      if mode != "persistence-sparse" || j == i + 1 {
        result.push([i, j])
      }
    }
  }
  if mode == "persistence-collisions" {
    for i in 0..<n {
      for j in (i + 1)..<n {
        for k in (j + 1)..<n {
          result.push([i, j, k])
        }
      }
    }
  }
  (
    result,
    match mode {
      "persistence-tiny" => 40000
      "persistence-sparse" => 4000
      _ => 600
    },
  )
}

///|
fn sparse(bits : Array[Bool]) -> Array[Int32] {
  let result = []
  for i, bit in bits {
    if bit {
      result.push(i)
    }
  }
  result
}

///|
fn bits_xor(a : Array[Bool], b : Array[Bool]) -> Unit {
  for i in 0..<a.length() {
    a[i] = a[i] != b[i]
  }
}

///|
fn low(a : Array[Bool]) -> Int32 {
  let mut result = -1
  for i, bit in a {
    if bit {
      result = i
    }
  }
  result
}

///|
/// Dense Boolean sets intentionally use neither production sparse lists nor
/// the candidate pivot index. The scan is newest first, as in the baseline.
fn persistence_oracle(
  input : Array[Array[Int32]],
  source : @ph.Filtration,
) -> @ph.Certificate {
  let size = input.length()
  let reduced : Array[Array[Bool]] = []
  let change : Array[Array[Bool]] = []
  let pairings : Array[@ph.Pairing] = []
  for j, simplex in input {
    let r = Array::make(size, false)
    let v = Array::make(size, false)
    v[j] = true
    if simplex.length() > 1 {
      for omit in 0..<simplex.length() {
        let face = []
        for index, vertex in simplex {
          if index != omit {
            face.push(vertex)
          }
        }
        for i in 0..<j {
          if input[i] == face {
            r[i] = true
          }
        }
      }
    }
    while low(r) >= 0 {
      let pivot = low(r)
      let mut owner = -1
      for i = j - 1; i >= 0; i = i - 1 {
        if owner < 0 && low(reduced[i]) == pivot {
          owner = i
        }
      }
      if owner < 0 {
        break
      }
      bits_xor(r, reduced[owner])
      bits_xor(v, change[owner])
    }
    if low(r) >= 0 {
      pairings.push({ birth: @oracle.nat(low(r)), death: @oracle.nat(j), })
    }
    reduced.push(r)
    change.push(v)
  }
  let bars : Array[@ph.Bar] = []
  for i, r in reduced {
    if low(r) < 0 {
      let mut death = -1
      for pair in pairings {
        if @oracle.int_of_nat(pair.birth) == i {
          death = @oracle.int_of_nat(pair.death)
        }
      }
      if death < 0 || death != i {
        bars.push({
          dimension: @oracle.nat(input[i].length() - 1),
          birth: @oracle.rational(i, 1),
          death: if death < 0 {
            None
          } else {
            Some(@oracle.rational(death, 1))
          },
          birth_simplex: @oracle.nat(i),
          death_simplex: if death < 0 {
            None
          } else {
            Some(@oracle.nat(death))
          },
        })
      }
    }
  }
  {
    source,
    reduced: @oracle.chain(
      reduced.map(fn(bits) { @oracle.chain(sparse(bits).map(@oracle.nat)) }),
    ),
    change: @oracle.chain(
      change.map(fn(bits) { @oracle.chain(sparse(bits).map(@oracle.nat)) }),
    ),
    pairings: @oracle.chain(pairings),
    bars: @oracle.chain(bars),
  }
}

///|
fn host_columns(
  columns : @core.Chain[@core.Chain[@core.Nat]],
) -> Array[Array[Int32]] {
  @oracle.array(columns).map(fn(column) {
    @oracle.array(column).map(@oracle.int_of_nat)
  })
}

///|
fn bench_persistence(mode : String) -> Unit {
  let (input, iterations) = simplices(mode)
  let source = @ph.validate(
    @oracle.chain(
      input.mapi(fn(i, simplex) {
        @ph.Entry::{
          simplex: @oracle.chain(simplex.map(@oracle.nat)),
          grade: @oracle.rational(i, 1),
        }
      }),
    ),
  ).unwrap()
  let expected = persistence_oracle(input, source)
  if !@ph.check_result(source, expected.bars, expected) {
    abort("independent dense-set witness rejected")
  }
  let fuel = @oracle.nat(4000)
  let columns = @oracle.nat(1000)
  for _ in 0..<iterations {
    match @ph.run(@ph.start(source), fuel, columns) {
      @ph.Done(result) =>
        if result != expected ||
          !@ph.check_result(source, @ph.barcode(result), result) {
          abort(
            "persistence full witness differs from dense-set oracle or checker",
          )
        }
      _ => abort("persistence public reduction did not complete")
    }
  }
  let pairs = @oracle.array(expected.pairings).map(fn(pair) {
    [@oracle.int_of_nat(pair.birth), @oracle.int_of_nat(pair.death)]
  })
  let bars = @oracle.array(expected.bars).map(fn(bar) {
    [
      @oracle.int_of_nat(bar.dimension),
      @oracle.int_of_nat(bar.birth_simplex),
      match bar.death_simplex {
        None => -1
        Some(x) => @oracle.int_of_nat(x)
      },
    ]
  })
  println(
    "{\"case\":\"\{mode}\",\"iterations\":\{iterations},\"simplices\":\{nested(input)},\"reduced\":\{nested(host_columns(expected.reduced))},\"change\":\{nested(host_columns(expected.change))},\"pairs\":\{nested(pairs)},\"bars\":\{nested(bars)},\"grades\":\"simplex index / 1\",\"checked\":true}",
  )
}

///|
fn main {
  let args = @env.args()
  let mode = args[args.length() - 1]
  match mode {
    "smith-small" | "smith-rectangular" | "smith-dense" => bench_smith(mode)
    "persistence-tiny" | "persistence-sparse" | "persistence-collisions" =>
      bench_persistence(mode)
    _ => abort("expected one of six frozen structural cases")
  }
}
