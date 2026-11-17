///|
/// Host-only independent integer oracle. Kernel functions retain symbolic ADTs.
fn residue(n : Int64, p : Int32) -> Int32 {
  let p = p.to_int64()
  ((n % p + p) % p).to_int()
}

///|
fn trim(xs : Array[Int32], p : Int32) -> Array[Int32] {
  let out = xs.map(fn(x) { residue(x.to_int64(), p) })
  while !out.is_empty() && out[out.length() - 1] == 0 {
    ignore(out.pop())
  }
  out
}

///|
fn product(a : Array[Int32], b : Array[Int32], p : Int32) -> Array[Int32] {
  if a.is_empty() || b.is_empty() {
    return []
  }
  let out = Array::make(a.length() + b.length() - 1, 0)
  for i, x in a {
    for j, y in b {
      out[i + j] = residue(
        out[i + j].to_int64() + x.to_int64() * y.to_int64(),
        p,
      )
    }
  }
  trim(out, p)
}

///|
fn sum(a : Array[Int32], b : Array[Int32], p : Int32) -> Array[Int32] {
  trim(
    Array::makei(a.length().max(b.length()), fn(i) {
      (if i < a.length() { a[i] } else { 0 }) +
      (if i < b.length() { b[i] } else { 0 })
    }),
    p,
  )
}

///|
fn chain(xs : Array[Int32]) -> @core.Chain[@binary.Binary] {
  @oracle.chain(xs.map(@oracle.binary))
}

///|
fn checked(
  value : @poly.Polynomial,
  expected : Array[Int32],
  p : Int32,
) -> String {
  if @poly.coefficients(value) != chain(expected) ||
    @oracle.int_of_binary(@poly.characteristic(value)) != p {
    abort("complete canonical result differs from independent integer oracle")
  }
  "[" +
  @oracle.array(@poly.coefficients(value))
  .map(fn(x) { @oracle.int_of_binary(x).to_string() })
  .join(",") +
  "]"
}

///|
fn raw_polynomial(
  field : @primefield.Field,
  xs : Array[Int32],
) -> @poly.Polynomial {
  @poly.polynomial(field, chain(xs))
}

///|
fn prepared(name : String) -> (Int32, () -> String) {
  match name {
    "multiply65537-dense" | "multiply257-unit" | "one-shot17" => {
      let p = if name == "multiply65537-dense" {
        65537
      } else if name == "multiply257-unit" {
        257
      } else {
        17
      }
      let a = if p == 65537 {
        Array::makei(17, fn(i) { 65536 - i * 1973 % 60000 })
      } else if p == 257 {
        Array::makei(33, fn(i) {
          if i % 4 == 0 {
            0
          } else if i % 4 == 1 {
            1
          } else if i % 4 == 2 {
            256
          } else {
            1
          }
        })
      } else {
        [2, 3, 4, 5, 6, 7, 8, 9, 10]
      }
      let b = if p == 65537 {
        Array::makei(13, fn(i) { 65535 - i * 3251 % 60000 })
      } else if p == 257 {
        Array::makei(17, fn(i) {
          if i % 3 == 0 {
            256
          } else if i % 3 == 1 {
            1
          } else {
            0
          }
        })
      } else {
        [16, 15, 14, 13, 12]
      }
      let expected = product(a, b, p)
      let field = @primefield.field(@oracle.binary(p)).unwrap()
      let left = raw_polynomial(field, a)
      let right = raw_polynomial(field, b)
      (
        if p == 65537 {
          80
        } else if p == 257 {
          300
        } else {
          3000
        },
        fn() {
          if name == "one-shot17" {
            let field = @primefield.field(@oracle.binary(p)).unwrap()
            checked(
              @poly.multiply(raw_polynomial(field, a), raw_polynomial(field, b)).unwrap(),
              expected,
              p,
            )
          } else {
            checked(@poly.multiply(left, right).unwrap(), expected, p)
          }
        },
      )
    }
    "scale257-unreduced" => {
      let p = 257
      let field = @primefield.field(@oracle.binary(p)).unwrap()
      let xs = Array::makei(33, fn(i) {
        if i % 4 == 0 {
          0
        } else {
          (i * 17 + 1) % p
        }
      })
      let input = raw_polynomial(field, xs)
      let huge = @binary.add(
        @binary.power(@oracle.binary(2), @oracle.binary(127)),
        @oracle.binary(35),
      )
      let huge_residue = for i = 0, power = 1; i < 127; {
        continue i + 1, power * 2 % p
      } nobreak {
        (power + 35) % p
      }
      let scalars = [
        @oracle.binary(0),
        @oracle.binary(1),
        @oracle.binary(256),
        @oracle.binary(257),
        @oracle.binary(258),
        @oracle.binary(7),
        huge,
      ]
      let residues = [0, 1, 256, 0, 1, 7, huge_residue]
      let expected = residues.map(fn(s) {
        trim(xs.map(fn(x) { residue(x.to_int64() * s.to_int64(), p) }), p)
      })
      (
        300,
        fn() {
          "[" +
          [
            for i, scalar in scalars => {
              checked(@poly.scale(input, scalar), expected[i], p)
            }
          ].join(",") +
          "]"
        },
      )
    }
    "divide17-d24" => {
      let p = 17
      let field = @primefield.field(@oracle.binary(p)).unwrap()
      let d = [1, 0, 16, 1, 0, 1, 4, 0, 1]
      let q = [1, 2, 0, 16, 1, 0, 4, 1, 16, 0, 1, 2, 0, 16, 4, 0, 1]
      let r = [16, 0, 1, 0, 6, 2, 0, 1]
      let a = sum(product(d, q, p), r, p)
      let divisor = raw_polynomial(field, d)
      let dividend = raw_polynomial(field, a)
      // Exact host reconstruction fixes both quotient and proper remainder.
      if r.length() >= d.length() {
        abort("invalid independent division fixture")
      }
      (
        500,
        fn() {
          let result = @poly.divide(dividend, divisor).unwrap()
          let quotient = checked(result.quotient, q, p)
          let remainder = checked(result.remainder, r, p)
          "[\{quotient},\{remainder}]"
        },
      )
    }
    "gf2-control" => {
      let p = 2
      let field = @primefield.field(@oracle.binary(p)).unwrap()
      let a = Array::makei(49, fn(i) { (i * 7 + 3) % 13 })
      let b = Array::makei(33, fn(i) { (i * 5 + 2) % 11 })
      let left = raw_polynomial(field, a)
      let right = raw_polynomial(field, b)
      let expected_product = product(a, b, p)
      let expected_scale = trim(a, p)
      let derivative = trim([ for i in 1..<a.length() => i * a[i] ], p)
      let huge = @binary.add(
        @binary.power(@oracle.binary(2), @oracle.binary(127)),
        @oracle.binary(35),
      )
      let expected_point = a.fold(init=0, fn(acc, x) { (acc + x) % p })
      (
        1000,
        fn() {
          let product = checked(
            @poly.multiply(left, right).unwrap(),
            expected_product,
            p,
          )
          let scaled = checked(@poly.scale(left, huge), expected_scale, p)
          let differentiated = checked(@poly.derivative(left), derivative, p)
          let point = @oracle.int_of_binary(@poly.evaluate(left, huge))
          if point != expected_point {
            abort("unreduced GF2 evaluation differs from independent oracle")
          }
          "[\{product},\{scaled},\{differentiated},\{point}]"
        },
      )
    }
    _ => abort("unknown finite-prime polynomial benchmark")
  }
}

///|
fn main {
  let args = @env.args()
  let name = args[args.length() - 1]
  let (iterations, operation) = prepared(name)
  let expected = operation()
  let started = @bench.monotonic_clock_start()
  for _ in 0..<iterations {
    if operation() != expected {
      abort("full checked output changed")
    }
  }
  let elapsed_us = @bench.monotonic_clock_end(started)
  println(
    "{\"case\":\"\{name}\",\"iterations\":\{iterations},\"result\":\{expected},\"elapsed_us\":\{elapsed_us},\"checked\":true}",
  )
}
