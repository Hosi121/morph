///|
/// Frozen public-API harness: compatible with original 2e33ef5. Machine
/// arithmetic is used only for fixture scheduling and independent exact oracles.
fn polynomial(coefficients : Array[Int32]) -> @poly.Polynomial {
  @poly.polynomial(
    @oracle.nat(1),
    @oracle.chain(
      [
        for i, coefficient in coefficients => {
          @poly.Term::{
            coefficient: @oracle.rational(coefficient, 1),
            exponents: Cons(@oracle.nat(i), Nil),
          }
        }
      ],
    ),
  ).unwrap()
}

///|
fn checked_field(d : Int32) -> @nf.Field {
  let coefficients = if d == 1 { [0, 1] } else { [1, 0, -10, 0, 1] }
  let root : @real.RootCertificate = {
    polynomial: polynomial(coefficients),
    interval: {
      lower: @oracle.rational(if d == 1 { -1 } else { 3 }, 1),
      upper: @oracle.rational(if d == 1 { 0 } else { 4 }, 1),
    },
  }
  match
    @minimal.normalize_root(
      root,
      @oracle.chain([2, 3, 5, 7, 11, 13].map(@oracle.binary)),
      @oracle.nat(40),
      @oracle.nat(256),
      @oracle.nat(256),
    ).unwrap() {
    @minimal.Normalized(value, proof) =>
      @nf.field_result(value, proof, @oracle.nat(256)).unwrap()
    _ => abort("fixture normalization unresolved")
  }
}

///|
/// Independent dense schoolbook product and monic long division, using
/// t^4 = 10*t^2 - 1; integer fixtures keep every operation within Int range.
fn oracle_product(a : Array[Int32], b : Array[Int32]) -> Array[Int32] {
  let product = Array::make(7, 0)
  for i in 0..<4 {
    for j in 0..<4 {
      product[i + j] = product[i + j] + a[i] * b[j]
    }
  }
  for k = 6; k >= 4; k = k - 1 {
    let c = product[k]
    product[k] = 0
    product[k - 2] = product[k - 2] + 10 * c
    product[k - 4] = product[k - 4] - c
  }
  [
    for i in 0..<4 => product[i]
  ]
}

///|
fn vector(values : Array[Int32]) -> @core.Chain[@exact.Rational] {
  @oracle.chain(values.map(fn(x) { @oracle.rational(x, 1) }))
}

///|
fn render(values : Array[Int32]) -> String {
  "[" + values.map(fn(x) { x.to_string() }).join(",") + "]"
}

///|
fn check_polynomial(actual : @nf.Element, expected : @poly.Polynomial) -> Unit {
  if @nf.representative(actual) != expected {
    abort("full canonical polynomial differs from independent oracle")
  }
}

///|
fn main {
  let args = @env.args()
  let mode = args[args.length() - 1]
  let d = if mode == "addsub-d1" || mode == "coords-zero-d1" { 1 } else { 4 }
  let field = checked_field(d)
  let complex = @cf.field(field)
  let aa = if d == 1 { [3] } else { [1, -2, 1, 1] }
  let bb = if d == 1 { [-3] } else { [-1, 2, 2, -1] }
  let sparse = mode == "coords-sparse-d4"
  let aa = if sparse { [0, 0, 0, 1] } else { aa }
  let bb = if sparse { [1, 0, 0, 0] } else { bb }
  let aa = if mode == "coords-zero-d1" { [0] } else { aa }
  let bb = if mode == "coords-zero-d1" { [0] } else { bb }
  let a = @nf.element(field, polynomial(aa)).unwrap()
  let b = @nf.element(field, polynomial(bb)).unwrap()
  let z = @cf.element(complex, a, b).unwrap()
  let sum = [ for i in 0..<d => aa[i] + bb[i] ]
  let difference = [ for i in 0..<d => aa[i] - bb[i] ]
  let product = if d == 4 { oracle_product(aa, bb) } else { [aa[0] * bb[0]] }
  let square_real = if d == 4 {
    let ac = oracle_product(aa, aa)
    let bd = oracle_product(bb, bb)
    [
      for i in 0..<4 => ac[i] - bd[i]
    ]
  } else {
    [0]
  }
  let square_imaginary = if d == 4 {
    oracle_product(aa, bb).map(fn(x) { 2 * x })
  } else {
    [0]
  }
  let expected_sum = polynomial(sum)
  let expected_difference = polynomial(difference)
  let expected_product = polynomial(product)
  let expected_coordinates = @core.append(vector(aa), vector(bb))
  let expected_square = @core.append(
    vector(square_real),
    vector(square_imaginary),
  )
  let columns = [
    for j in 0..<d => {
      let basis = [ for i in 0..<d => if i == j { 1 } else { 0 } ]
      if d == 4 {
        oracle_product(aa, basis)
      } else {
        [aa[0]]
      }
    }
  ]
  let rows = [ for i in 0..<d => [ for j in 0..<d => columns[j][i] ] ]
  let expected_rows = @oracle.chain(rows.map(vector))
  let repetitions = match mode {
    "addsub-d4" => 50000
    "addsub-d1" => 750000
    "coords-sparse-d4" => 500000
    "coords-dense-d4" => 300000
    "coords-zero-d1" => 750000
    "matrix-d4" => 5000
    "multiply-control-d4" => 15000
    "complex-square-d4" => 5000
    _ => abort("unknown nf kernel benchmark case")
  }
  fn perform() -> Unit {
    match mode {
      "addsub-d4" | "addsub-d1" => {
        check_polynomial(@nf.add(a, b).unwrap(), expected_sum)
        check_polynomial(@nf.subtract(a, b).unwrap(), expected_difference)
        check_polynomial(@nf.add(a, @nf.negate(a)).unwrap(), polynomial([0]))
      }
      "coords-sparse-d4" | "coords-dense-d4" | "coords-zero-d1" =>
        if @cf.coordinates(z) != expected_coordinates {
          abort("full QQ coordinate vector differs from independent oracle")
        }
      "matrix-d4" =>
        if @matrix.rows(@nf.multiplication_matrix(a).unwrap()) != expected_rows {
          abort("full multiplication matrix differs from independent oracle")
        }
      "multiply-control-d4" =>
        check_polynomial(@nf.multiply(a, b).unwrap(), expected_product)
      "complex-square-d4" =>
        if @cf.coordinates(@cf.multiply(z, z).unwrap()) != expected_square {
          abort(
            "full complex square coordinates differ from independent oracle",
          )
        }
      _ => abort("unreachable case")
    }
  }
  // Setup verifies the real embedding and irreducibility through field_result.
  // Every warmup/timed result is checked in full; no checksum-only comparisons.
  perform()
  let started = @bench.monotonic_clock_start()
  for _ in 0..<repetitions {
    perform()
  }
  let elapsed_us = @bench.monotonic_clock_end(started)
  let expected = match mode {
    "addsub-d4" | "addsub-d1" =>
      "[" + render(sum) + "," + render(difference) + ",[0]]"
    "coords-sparse-d4" | "coords-dense-d4" | "coords-zero-d1" =>
      "[" + render(aa) + "," + render(bb) + "]"
    "matrix-d4" => "[" + rows.map(render).join(",") + "]"
    "multiply-control-d4" => render(product)
    "complex-square-d4" =>
      "[" + render(square_real) + "," + render(square_imaginary) + "]"
    _ => "[]"
  }
  println(
    "{\"case\":\"\{mode}\",\"iterations\":\{repetitions},\"degree\":\{d},\"expected_full_outputs\":\{expected},\"elapsed_us\":\{elapsed_us},\"checked\":true}",
  )
}
