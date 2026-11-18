///|
fn binary_hex(value : @binary.Binary) -> String {
  let bits = @oracle.array(@core.reverse(@binary.bits(value)))
  if bits.is_empty() {
    return "0"
  }
  let padded = Array::make((4 - bits.length() % 4) % 4, false)
  for bit in bits {
    padded.push(bit)
  }
  @oracle.hex_bits(@oracle.chain(padded))
}

///|
fn rational_json(value : @exact.Rational) -> String {
  let n = @exact.numerator(value)
  "[\{@exact.negative(n)},\"\{binary_hex(@exact.magnitude(n))}\",\"\{binary_hex(@exact.denominator(value))}\"]"
}

///|
fn vector_json(value : @core.Chain[@exact.Rational]) -> String {
  "[" + @oracle.array(value).map(rational_json).join(",") + "]"
}

///|
fn matrix_json(value : @matrix.Matrix[@exact.Rational]) -> String {
  "[" + @oracle.array(@matrix.rows(value)).map(vector_json).join(",") + "]"
}

///|
fn covariance(
  n : Int32,
  diagonal : Bool,
  shift : Int32,
) -> @matrix.Matrix[@exact.Rational] {
  let rows = Array::makei(n, fn(i) {
    @oracle.chain(
      Array::makei(n, fn(j) {
        let mut value = if i == j { i + 2 + shift } else { 0 }
        if !diagonal {
          for k in 0..<n {
            value += ((k + 2 * i) % 5 - 2) * ((k + 2 * j) % 5 - 2)
          }
        }
        @oracle.rational(value, 3)
      }),
    )
  })
  @matrix.matrix(@oracle.nat(n), @oracle.chain(rows)).unwrap()
}

///|
fn main {
  let args = @env.args()
  let name = args[args.length() - 1]
  let (n, diagonal, iterations) = match name {
    "diag2" => (2, true, 50)
    "dense3" => (3, false, 20)
    "dense6" => (6, false, 5)
    _ => abort("unknown case")
  }
  let covariances = Array::makei(3, fn(shift) { covariance(n, diagonal, shift) })
  let mean = @oracle.chain(
    Array::makei(n, fn(i) { @oracle.rational(i + 1, i + 2) }),
  )
  let answers = []
  for i in 0..<iterations {
    let value = @gaussian.gaussian(mean, covariances[i % 3]).unwrap()
    answers.push(
      "{\"mean\":" +
      vector_json(@gaussian.mean(value)) +
      ",\"covariance\":" +
      matrix_json(@gaussian.covariance(value)) +
      ",\"precision\":" +
      matrix_json(@gaussian.precision(value)) +
      "}",
    )
  }
  println(
    "{\"case\":\"\{name}\",\"iterations\":\{iterations},\"results\":[" +
    answers.join(",") +
    "]}",
  )
}
