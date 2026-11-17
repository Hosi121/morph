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
  let d = if mode == "degree1-control" { 1 } else { 4 }
  let original = checked_field(d)
  let proof = @nf.certificate(original)
  let fuel = @oracle.nat(256)
  let sparse = mode == "sparse-no-reduction"
  let aa = if d == 1 {
    [3]
  } else if sparse {
    [0, 1, 0, 0]
  } else {
    [1, -2, 1, 1]
  }
  let bb = if d == 1 {
    [-3]
  } else if sparse {
    [2, 0, 0, 0]
  } else {
    [-1, 2, 2, -1]
  }
  let pa = polynomial(aa)
  let pb = polynomial(bb)
  let a = @nf.element(original, pa).unwrap()
  let b = @nf.element(original, pb).unwrap()
  let complex = @cf.field(original)
  let z = @cf.element(complex, a, b).unwrap()
  let product = if d == 4 { oracle_product(aa, bb) } else { [aa[0] * bb[0]] }
  let expected_product = polynomial(product)
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
  let expected_square = @core.append(
    vector(square_real),
    vector(square_imaginary),
  )
  let iterations = match mode {
    "dense-repeat" => 40000
    "sparse-no-reduction" => 500000
    "degree1-control" => 600000
    "field-setup-only" => 2000
    "setup-one-shot" => 2000
    "complex-square" => 10000
    _ => abort("unknown night NF case")
  }
  fn checked_setup() -> @nf.Field {
    let result = @nf.field(proof, fuel).unwrap()
    if @nf.certificate(result) != proof ||
      @nf.embedding(result) != proof.result ||
      @nf.modulus(result) != proof.result.polynomial ||
      @nf.degree(result) != @oracle.nat(d) {
      abort("field setup changed full certificate or embedding context")
    }
    result
  }
  fn perform() -> Unit {
    match mode {
      "field-setup-only" => ignore(checked_setup())
      "setup-one-shot" => {
        let field = checked_setup()
        let left = @nf.element(field, pa).unwrap()
        let right = @nf.element(field, pb).unwrap()
        check_polynomial(@nf.multiply(left, right).unwrap(), expected_product)
      }
      "complex-square" =>
        if @cf.coordinates(@cf.multiply(z, z).unwrap()) != expected_square {
          abort("full complex square differs from independent machine oracle")
        }
      _ => check_polynomial(@nf.multiply(a, b).unwrap(), expected_product)
    }
  }
  // The setup-only and one-shot cases repeat certificate verification and all
  // preparation inside this interval. Other cases include their checked setup
  // once in whole-process timing; the inner interval measures checked repeats.
  perform()
  let started = @bench.monotonic_clock_start()
  for _ in 0..<iterations {
    perform()
  }
  let elapsed_us = @bench.monotonic_clock_end(started)
  let expected = if mode == "field-setup-only" {
    render([1, 0, -10, 0, 1])
  } else if mode == "complex-square" {
    "[" + render(square_real) + "," + render(square_imaginary) + "]"
  } else {
    render(product)
  }
  println(
    "{\"case\":\"\{mode}\",\"iterations\":\{iterations},\"degree\":\{d},\"expected_full_outputs\":\{expected},\"elapsed_us\":\{elapsed_us},\"checked\":true}",
  )
}
