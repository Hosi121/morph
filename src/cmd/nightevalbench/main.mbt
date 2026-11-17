///|
/// Independent host integer Horner; all intermediate products fit Int64.
fn evaluate_oracle(cs : Array[Int32], point : Int32, p : Int32) -> Int32 {
  for i = cs.length() - 1, acc = 0; i >= 0; {
    continue i - 1,
      ((acc.to_int64() * point.to_int64() + cs[i].to_int64()) % p.to_int64()).to_int()
  } nobreak {
    acc
  }
}

///|
fn power_residue(exponent : Int32, suffix : Int32, p : Int32) -> Int32 {
  for i = 0, acc = 1; i < exponent; {
    continue i + 1, acc * 2 % p
  } nobreak {
    (acc + suffix) % p
  }
}

///|
fn encoded(xs : Array[Int32]) -> @core.Chain[@binary.Binary] {
  @oracle.chain(xs.map(@oracle.binary))
}

///|
fn json_ints(xs : Array[Int32]) -> String {
  "[" + xs.map(fn(x) { x.to_string() }).join(",") + "]"
}

///|
fn polynomial(field : @primefield.Field, cs : Array[Int32]) -> @poly.Polynomial {
  @poly.polynomial(field, encoded(cs))
}

///|
fn checked(
  value : @poly.Polynomial,
  point : @binary.Binary,
  expected : Int32,
) -> Int32 {
  let actual = @oracle.int_of_binary(@poly.evaluate(value, point))
  if actual != expected {
    abort("evaluation differs from independent host Horner")
  }
  actual
}

///|
fn prepared(name : String) -> (Int32, () -> String) {
  match name {
    "odd65537-reduced" | "odd257-unreduced" | "gf2-mixed" => {
      let p = if name == "odd65537-reduced" {
        65537
      } else if name == "odd257-unreduced" {
        257
      } else {
        2
      }
      let field = @primefield.field(@oracle.binary(p)).unwrap()
      let cs = if p == 65537 {
        Array::makei(33, fn(i) { 65536 - i * 1973 % 60000 })
      } else {
        Array::makei(49, fn(i) { (i * 17 + 3) % (p * 3 + 1) })
      }
      let value = polynomial(field, cs)
      let huge = @binary.add(
        @binary.power(@oracle.binary(2), @oracle.binary(511)),
        @oracle.binary(19),
      )
      let even_huge = @binary.add(
        @binary.power(@oracle.binary(2), @oracle.binary(511)),
        @oracle.binary(18),
      )
      let points = if p == 65537 {
        [@oracle.binary(2), @oracle.binary(32768), @oracle.binary(65536)]
      } else {
        [
          @oracle.binary(0),
          @oracle.binary(1),
          @oracle.binary(p - 1),
          @oracle.binary(p),
          @oracle.binary(p + 1),
          huge,
          even_huge,
        ]
      }
      let residues = if p == 65537 {
        [2, 32768, 65536]
      } else {
        [
          0,
          1,
          p - 1,
          0,
          1,
          power_residue(511, 19, p),
          power_residue(511, 18, p),
        ]
      }
      let expected = residues.map(fn(x) { evaluate_oracle(cs, x, p) })
      (
        if p == 65537 {
          200
        } else if p == 257 {
          25
        } else {
          9000
        },
        fn() {
          json_ints(
            [
              for i, point in points => checked(value, point, expected[i])
            ],
          )
        },
      )
    }
    "tiny-constant" => {
      let field = @primefield.field(@oracle.binary(17)).unwrap()
      let empty = @poly.zero(field)
      let constant = @poly.constant(field, @oracle.binary(16))
      let huge = @binary.add(
        @binary.power(@oracle.binary(2), @oracle.binary(511)),
        @oracle.binary(19),
      )
      (
        150000,
        fn() {
          json_ints([
            checked(empty, huge, 0),
            checked(constant, huge, 16),
            checked(empty, @oracle.binary(0), 0),
            checked(constant, @oracle.binary(1), 16),
          ])
        },
      )
    }
    "setup-one-shot17" => {
      let cs = [16, 4]
      let point = @oracle.binary(17 * 5 + 7)
      let expected = evaluate_oracle(cs, 7, 17)
      (
        30000,
        fn() {
          let field = @primefield.field(@oracle.binary(17)).unwrap()
          let value = polynomial(field, cs)
          checked(value, point, expected).to_string()
        },
      )
    }
    "listdecode-encode17" => {
      let field = @primefield.field(@oracle.binary(17)).unwrap()
      let points = Array::makei(17, fn(i) { i })
      let plan = @listdecode.plan(
        field,
        encoded(points),
        encoded(points),
        @oracle.nat(8),
        @oracle.nat(16),
        @oracle.nat(1),
        @oracle.nat(15),
      ).unwrap()
      if !@listdecode.valid(@listdecode.validate(plan)) {
        abort("invalid consumer plan")
      }
      let message = [16, 0, 7, 1, 4, 9, 2, 15]
      let input = encoded(message)
      let expected = points.map(fn(x) { evaluate_oracle(message, x, 17) })
      let expected_word = encoded(expected)
      (
        1500,
        fn() {
          let result = @listdecode.encode(plan, input).unwrap()
          if result != expected_word {
            abort("listdecode codeword differs from independent host Horner")
          }
          json_ints(@oracle.array(result).map(@oracle.int_of_binary))
        },
      )
    }
    _ => abort("unknown finite-prime Horner case")
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
