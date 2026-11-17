///|
/// Host-only exact convolution, with Int64 products before modular reduction.
fn product(a : Array[Int32], b : Array[Int32], p : Int32) -> Array[Int32] {
  if a.is_empty() || b.is_empty() {
    return []
  }
  let out = Array::make(a.length() + b.length() - 1, 0)
  for i, x in a {
    for j, y in b {
      out[i + j] = ((out[i + j].to_int64() + x.to_int64() * y.to_int64()) %
      p.to_int64()).to_int()
    }
  }
  while !out.is_empty() && out[out.length() - 1] == 0 {
    ignore(out.pop())
  }
  out
}

///|
fn encoded(cs : Array[Int32]) -> @core.Chain[@binary.Binary] {
  @oracle.chain(cs.map(@oracle.binary))
}

///|
fn checked(
  value : @poly.Polynomial,
  expected : Array[Int32],
  p : Int32,
) -> String {
  if @poly.coefficients(value) != encoded(expected) ||
    @oracle.int_of_binary(@poly.characteristic(value)) != p {
    abort("full coefficients differ from independent Int64 convolution")
  }
  "[" +
  @oracle.array(@poly.coefficients(value))
  .map(fn(x) { @oracle.int_of_binary(x).to_string() })
  .join(",") +
  "]"
}

///|
fn prepared(name : String) -> (Int32, () -> String) {
  match name {
    "sparse257"
    | "dense65537"
    | "unit17-upper"
    | "gf2-control"
    | "tiny17"
    | "zero257" => {
      let p = match name {
        "dense65537" => 65537
        "sparse257" | "zero257" => 257
        "gf2-control" => 2
        _ => 17
      }
      let field = @primefield.field(@oracle.binary(p)).unwrap()
      let a = match name {
        "sparse257" =>
          Array::makei(65, fn(i) {
            if i % 16 == 0 {
              2 * p + (i * 7 + 3) % (p - 2) + 2
            } else {
              p * 3
            }
          })
        "unit17-upper" => Array::make(33, p * 2 + 1)
        "dense65537" => Array::makei(17, fn(i) { p - 1 - i * 1973 % 60000 })
        "zero257" => Array::makei(65, fn(i) { p - 1 - i * 3 % 200 })
        "tiny17" => [2, 16]
        _ => Array::makei(49, fn(i) { (i * 17 + 3) % 7 })
      }
      let b = match name {
        "sparse257" => Array::makei(33, fn(i) { 200 + i * 7 % 57 })
        "unit17-upper" => Array::makei(17, fn(i) { 2 + i % 15 })
        "dense65537" => Array::makei(13, fn(i) { p - 2 - i * 3251 % 60000 })
        "zero257" => []
        "tiny17" => [15]
        _ => Array::makei(33, fn(i) { (i * 5 + 2) % 11 })
      }
      let left = @poly.polynomial(field, encoded(a))
      let right = @poly.polynomial(field, encoded(b))
      let expected = product(a, b, p)
      let power_base = @poly.polynomial(field, encoded([1, 1]))
      let modulus = @poly.polynomial(
        field,
        encoded(
          Array::makei(18, fn(i) { if i == 0 || i == 17 { 1 } else { 0 } }),
        ),
      )
      let binomial = Array::makei(14, fn(k) {
        for i = 0, coefficient = 1L; i < k; {
          continue i + 1, coefficient * (13 - i).to_int64() / (i + 1).to_int64()
        } nobreak {
          (coefficient % 17).to_int()
        }
      })
      let count = match name {
        "dense65537" => 80
        "sparse257" => 100
        "unit17-upper" => 300
        "zero257" => 5000
        "tiny17" => 30000
        _ => 3000
      }
      (
        count,
        fn() {
          let direct = checked(
            @poly.multiply(left, right).unwrap(),
            expected,
            p,
          )
          if name == "unit17-upper" {
            let powered = @poly.power_mod(
              power_base,
              @oracle.binary(13),
              modulus,
            ).unwrap()
            "[\{direct},\{checked(powered, binomial, p)}]"
          } else if name == "zero257" {
            let other = checked(@poly.multiply(right, left).unwrap(), [], p)
            "[\{direct},\{other}]"
          } else {
            direct
          }
        },
      )
    }
    _ => abort("unknown canonical convolution case")
  }
}

///|
fn main {
  let args = @env.args()
  let name = args[args.length() - 1]
  let (iterations, operation) = prepared(name)
  let expected = operation()
  let start = @bench.monotonic_clock_start()
  for _ in 0..<iterations {
    if operation() != expected {
      abort("complete checked output changed")
    }
  }
  let elapsed_us = @bench.monotonic_clock_end(start)
  println(
    "{\"case\":\"\{name}\",\"iterations\":\{iterations},\"result\":\{expected},\"elapsed_us\":\{elapsed_us},\"checked\":true}",
  )
}
