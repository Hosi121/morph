///|
/// Independent host carryless arithmetic for fixed degrees at most 32.
fn bit_degree(n : Int64) -> Int32 {
  if n < 0 {
    abort("oracle bit degree requires nonnegative exact integer")
  }
  for x = n, d = -1; x != 0; {
    continue x >> 1, d + 1
  } nobreak {
    d
  }
}

///|
fn bit_mod(n : Int64, modulus : Int64) -> Int64 {
  if n < 0 || modulus <= 0 {
    abort("oracle remainder requires nonnegative dividend and positive modulus")
  }
  let d = bit_degree(modulus)
  for value = n; bit_degree(value) >= d; {
    continue value ^ (modulus << (bit_degree(value) - d))
  } nobreak {
    value
  }
}

///|
fn bit_multiply(a : Int64, b : Int64) -> Int64 {
  if a < 0 || b < 0 || bit_degree(a) + bit_degree(b) > 62 {
    abort("carryless oracle exceeds exact nonnegative Int64 range")
  }
  for x = a, y = b, result = 0L; y != 0; {
    let tail = y >> 1
    continue if tail == 0 {
        x
      } else {
        x << 1
      },
      tail,
      if (y & 1) == 1 {
        result ^ x
      } else {
        result
      }
  } nobreak {
    result
  }
}

///|
fn bit_power(base : Int64, exponent : Int32, modulus : Int64) -> Int64 {
  for x = bit_mod(base, modulus), n = exponent, result = bit_mod(1, modulus); n !=
     0; {
    continue bit_mod(bit_multiply(x, x), modulus),
      n / 2,
      if n % 2 == 1 {
        bit_mod(bit_multiply(result, x), modulus)
      } else {
        result
      }
  } nobreak {
    result
  }
}

///|
fn encoded(cs : Array[Int32]) -> @core.Chain[@binary.Binary] {
  @oracle.chain(cs.map(@oracle.binary))
}

///|
fn bit_coefficients(bits : Int64) -> Array[Int32] {
  Array::makei(bit_degree(bits) + 1, fn(i) { ((bits >> i) & 1).to_int() })
}

///|
fn polynomial(field : @primefield.Field, cs : Array[Int32]) -> @poly.Polynomial {
  @poly.polynomial(field, encoded(cs))
}

///|
fn json_polynomial(value : @poly.Polynomial) -> String {
  "[" +
  @oracle.array(@poly.coefficients(value))
  .map(fn(c) { @oracle.int_of_binary(c).to_string() })
  .join(",") +
  "]"
}

///|
fn checked(
  value : @poly.Polynomial,
  expected : Array[Int32],
  p : Int32,
) -> String {
  if @poly.coefficients(value) != encoded(expected) ||
    @oracle.int_of_binary(@poly.characteristic(value)) != p {
    abort("complete modular power differs from independent host oracle")
  }
  json_polynomial(value)
}

///|
fn bits_of(value : @poly.Polynomial) -> Int64 {
  let cs = @oracle.array(@poly.coefficients(value))
  for i = 0, result = 0L; i < cs.length(); {
    let n = @oracle.int_of_binary(cs[i])
    if n < 0 || n > 1 {
      abort("noncanonical binary coefficient")
    }
    continue i + 1, result | (n.to_int64() << i)
  } nobreak {
    result
  }
}

///|
fn certificate_json(
  value : @poly.Polynomial,
  proof : @poly.IrreducibilityCertificate,
) -> String {
  let modulus = bits_of(value)
  if @oracle.array(proof.frobenius).length() != 8 ||
    @oracle.array(proof.coprime).length() != 4 {
    abort("incorrect independent certificate shape")
  }
  let mut current = bit_mod(2, modulus)
  for item in @oracle.array(proof.frobenius) {
    current = bit_mod(bit_multiply(current, current), modulus)
    if bits_of(item) != current {
      abort("independent Frobenius orbit differs")
    }
  }
  if current != bit_mod(2, modulus) {
    abort("Frobenius orbit failed to close")
  }
  let powers = @oracle.array(proof.frobenius)
  for i, witness in @oracle.array(proof.coprime) {
    let left = bit_multiply(modulus, bits_of(witness.left))
    let right = bit_multiply(bits_of(powers[i]) ^ 2, bits_of(witness.right))
    if (left ^ right) != 1 || bits_of(witness.gcd) != 1 {
      abort("independent Bezout polynomial identity failed")
    }
  }
  if !@poly.check_irreducible(value, proof) {
    abort("existing irreducibility checker failed")
  }
  let orbit = "[" + powers.map(json_polynomial).join(",") + "]"
  let witnesses = "[" +
    @oracle.array(proof.coprime)
    .map(fn(w) {
      "[\{json_polynomial(w.gcd)},\{json_polynomial(w.left)},\{json_polynomial(w.right)}]"
    })
    .join(",") +
    "]"
  "[\{orbit},\{witnesses}]"
}

///|
/// Generic independent host polynomial arithmetic for the odd-prime control.
fn host_trim(cs : Array[Int32]) -> Array[Int32] {
  while !cs.is_empty() && cs[cs.length() - 1] == 0 {
    ignore(cs.pop())
  }
  cs
}

///|
fn host_product(
  a : Array[Int32],
  b : Array[Int32],
  p : Int32,
  modulus : Array[Int32],
) -> Array[Int32] {
  if a.is_empty() || b.is_empty() {
    return []
  }
  let result = Array::make(a.length() + b.length() - 1, 0)
  for i, x in a {
    for j, y in b {
      result[i + j] = (result[i + j] + x * y) % p
    }
  }
  for i = result.length() - 1; i >= modulus.length() - 1; i = i - 1 {
    let factor = result[i]
    for j, c in modulus {
      let k = i - modulus.length() + 1 + j
      result[k] = (result[k] - factor * c % p + p) % p
    }
  }
  host_trim(result)
}

///|
fn prepared(name : String) -> (Int32, () -> String) {
  match name {
    "dense-f2-power16" | "sparse-f2-power32" => {
      let high = name == "sparse-f2-power32"
      let field = @primefield.field(@oracle.binary(2)).unwrap()
      let base = if high { (1L << 31) | 9 } else { 65535L }
      let modulus = if high { (1L << 32) | 141 } else { (1L << 16) | 4107 }
      let exponent = if high { 65536 } else { 65535 }
      let a = polynomial(field, bit_coefficients(base).map(fn(c) { c + 4 }))
      let m = polynomial(field, bit_coefficients(modulus).map(fn(c) { c + 6 }))
      let expected = bit_coefficients(bit_power(base, exponent, modulus))
      (
        if high {
          80
        } else {
          300
        },
        fn() {
          checked(
            @poly.power_mod(a, @oracle.binary(exponent), m).unwrap(),
            expected,
            2,
          )
        },
      )
    }
    "irreducibility-setup8" => {
      let field = @primefield.field(@oracle.binary(2)).unwrap()
      let value = polynomial(field, bit_coefficients(283))
      (
        1200,
        fn() {
          let proof = @poly.irreducibility(value).unwrap().unwrap()
          let serialized = certificate_json(value, proof)
          let extension = @galois.extension(value, proof).unwrap()
          if @oracle.int_of_binary(@galois.cardinality(extension)) != 256 ||
            @oracle.int_of_nat(@galois.degree(extension)) != 8 ||
            @galois.modulus(extension) != value {
            abort("wrong checked Galois setup")
          }
          "[\{serialized},\{json_polynomial(@galois.modulus(extension))},256,8]"
        },
      )
    }
    "odd17-control" => {
      let field = @primefield.field(@oracle.binary(17)).unwrap()
      let cs = Array::makei(16, fn(i) { (i * 3 + 2) % 17 })
      let ms = Array::makei(18, fn(i) { if i == 0 || i == 17 { 1 } else { 0 } })
      let a = polynomial(field, cs)
      let m = polynomial(field, ms)
      let expected = for x = cs, n = 255, result = [1]; n != 0; {
        continue host_product(x, x, 17, ms),
          n / 2,
          if n % 2 == 1 {
            host_product(result, x, 17, ms)
          } else {
            result
          }
      } nobreak {
        result
      }
      (
        50,
        fn() {
          checked(
            @poly.power_mod(a, @oracle.binary(255), m).unwrap(),
            expected,
            17,
          )
        },
      )
    }
    "lowdegree-f2" => {
      let field = @primefield.field(@oracle.binary(2)).unwrap()
      let x = @poly.indeterminate(field)
      let m = polynomial(field, [1, 1])
      (
        40000,
        fn() {
          let a = checked(
            @poly.power_mod(x, @oracle.binary(31), m).unwrap(),
            [1],
            2,
          )
          let b = checked(
            @poly.power_mod(@poly.zero(field), @oracle.binary(0), m).unwrap(),
            [1],
            2,
          )
          let c = checked(
            @poly.power_mod(x, @oracle.binary(0), @poly.one(field)).unwrap(),
            [],
            2,
          )
          if @poly.power_mod(x, @oracle.binary(0), @poly.zero(field)) !=
            Err(@poly.ZeroDivisor) {
            abort("zero modulus error changed")
          }
          "[\{a},\{b},\{c}]"
        },
      )
    }
    "setup-one-shot-f2" => {
      let expected = bit_coefficients(bit_power(11, 13, 19))
      (
        20000,
        fn() {
          let field = @primefield.field(@oracle.binary(2)).unwrap()
          let a = polynomial(field, bit_coefficients(11).map(fn(c) { c + 4 }))
          let m = polynomial(field, bit_coefficients(19).map(fn(c) { c + 6 }))
          checked(
            @poly.power_mod(a, @oracle.binary(13), m).unwrap(),
            expected,
            2,
          )
        },
      )
    }
    _ => abort("unknown Frobenius square case")
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
