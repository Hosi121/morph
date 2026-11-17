///|
/// Host-only scheduling and independent integer oracles. The exact same source
/// builds against the baseline and optimized public APIs.
fn reduce_case(mode : String) -> Int32 {
  let p = if mode == "reduce-small" { 17 } else { 65537 }
  let inputs = match mode {
    "reduce-small" => [0, 1, 7, 8, 15, 16].map(@oracle.binary)
    "reduce-near" =>
      [65535, 65536, 65537, 65538, 131073, 131074].map(@oracle.binary)
    "reduce-unreduced" =>
      [1000000, 1234567, 7654321, 16000000].map(@oracle.binary)
    "reduce-256" =>
      [
        "123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef0", "ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff",
        "8000000000000000000000000000000000000000000000000000000000000001",
      ].map(@oracle.binary_from_hex)
    "reduce-1024" =>
      [
        "123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef0",
        "ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff",
      ].map(@oracle.binary_from_hex)
    _ => abort("unknown reduction mode")
  }
  // Independent positional recurrence uses machine integers only in this host.
  fn expected(bits : @core.Chain[Bool], p : Int32) -> Int32 {
    match bits {
      Nil => 0
      Cons(bit, tail) => (expected(tail, p) * 2 + (if bit { 1 } else { 0 })) % p
    }
  }
  let residues = inputs.map(fn(value) { expected(@binary.bits(value), p) })
  let m = @modular.modulus(@oracle.binary(p)).unwrap()
  let repetitions = match mode {
    "reduce-small" => 12000000
    "reduce-256" => 2000
    "reduce-1024" => 500
    _ => 300000
  }
  let mut checksum = 0
  for i in 0..<repetitions {
    let result = @modular.reduce(m, inputs[i % inputs.length()])
    checksum = (checksum + @oracle.int_of_binary(result)) % 1000000007
  }
  let mut wanted = 0
  for i in 0..<repetitions {
    wanted = (wanted + residues[i % residues.length()]) % 1000000007
  }
  if checksum != wanted {
    abort("reduction differs from integer oracle")
  }
  checksum
}

///|
fn arithmetic_case(mode : String) -> Int32 {
  let p = match mode {
    "field2" | "field2-unreduced" | "inverse2" => 2
    "field17" | "add17" => 17
    "field65537" | "add65537" => 65537
    _ => abort("unknown arithmetic mode")
  }
  let field = @primefield.field(@oracle.binary(p)).unwrap()
  let ops = @primefield.arithmetic(field)
  let values = if mode == "field2-unreduced" {
    [0, 1, 2, 3, 65536, 65537, 1234567, 7654321]
  } else {
    [0, 1, p - 1, p / 2, p / 2 + 1, 1, p - 2]
  }
  let inputs = values.map(@oracle.binary)
  let repetitions = match mode {
    "field2" | "field2-unreduced" | "inverse2" => 3000000
    "add17" => 1500000
    "add65537" => 500000
    "field65537" => 100000
    _ => 300000
  }
  let mut result = ops.one
  for i in 0..<repetitions {
    let a = inputs[i % inputs.length()]
    result = if mode == "inverse2" {
      match (ops.inverse)(a) {
        Some(value) => (ops.add)(result, value)
        None => (ops.negate)(result)
      }
    } else if mode == "add17" || mode == "add65537" {
      (ops.add)(result, a)
    } else {
      (ops.negate)((ops.subtract)((ops.multiply)((ops.add)(result, a), a), a))
    }
  }
  let mut expected = 1
  for i in 0..<repetitions {
    let a = values[i % values.length()] % p
    expected = if mode == "inverse2" {
      if a == 1 {
        (expected + 1) % p
      } else {
        (p - expected) % p
      }
    } else if mode == "add17" || mode == "add65537" {
      (expected + a) % p
    } else {
      // Reducing the add first keeps this independent oracle in Int32 range.
      let sum = (expected + a) % p
      let product = (sum.to_int64() * a.to_int64() % p.to_int64()).to_int()
      ((a - product) % p + p) % p
    }
  }
  let found = @oracle.int_of_binary(result)
  if found != expected {
    abort("field dictionary differs from integer oracle")
  }
  found
}

///|
fn polynomial_case(mode : String) -> Int32 {
  let p = if mode == "poly2" { 2 } else { 17 }
  let field = @primefield.field(@oracle.binary(p)).unwrap()
  let base_values = [1, p - 1, 1, 0, 1]
  let divisor_values = [1, 1, 0, 1, 0, 0, 0, 0, 1]
  let base = @fppoly.polynomial(
    field,
    @oracle.chain(base_values.map(@oracle.binary)),
  )
  let divisor = @fppoly.polynomial(
    field,
    @oracle.chain(divisor_values.map(@oracle.binary)),
  )
  let exponent = @oracle.binary(3)
  let repetitions = if p == 2 { 15000 } else { 1500 }
  let mut result = @fppoly.one(field)
  for _ in 0..<repetitions {
    result = @fppoly.power_mod(
      @fppoly.add(result, base).unwrap(),
      exponent,
      divisor,
    ).unwrap()
  }
  // Independent schoolbook polynomial arithmetic over machine residues.
  fn multiply_mod(
    a : Array[Int32],
    b : Array[Int32],
    d : Array[Int32],
    p : Int32,
  ) -> Array[Int32] {
    let product = Array::make(a.length() + b.length() - 1, 0)
    for i in 0..<a.length() {
      for j in 0..<b.length() {
        product[i + j] = (product[i + j] + a[i] * b[j]) % p
      }
    }
    for i = product.length() - 1; i >= d.length() - 1; i = i - 1 {
      let leading = product[i]
      for j in 0..<d.length() {
        let index = i - (d.length() - 1) + j
        product[index] = ((product[index] - leading * d[j]) % p + p) % p
      }
    }
    Array::makei(d.length() - 1, fn(i) {
      if i < product.length() {
        product[i]
      } else {
        0
      }
    })
  }
  let mut expected = [1, 0, 0, 0, 0, 0, 0, 0]
  for _ in 0..<repetitions {
    let sum = Array::makei(8, fn(i) {
      (
        expected[i] +
        (if i < base_values.length() { base_values[i] } else { 0 })
      ) %
      p
    })
    expected = multiply_mod(
      multiply_mod(sum, sum, divisor_values, p),
      sum,
      divisor_values,
      p,
    )
  }
  let actual = @oracle.array(@fppoly.coefficients(result)).map(
    @oracle.int_of_binary,
  )
  let padded = Array::makei(8, fn(i) {
    if i < actual.length() {
      actual[i]
    } else {
      0
    }
  })
  if padded != expected {
    abort("finite-field polynomial differs from integer oracle")
  }
  padded.fold(init=0, fn(a, b) { a * 3 + b })
}

///|
fn main {
  let args = @env.args()
  let mode = args[args.length() - 1]
  let checksum = if mode.has_prefix("reduce-") {
    reduce_case(mode)
  } else if mode == "poly2" || mode == "poly17" {
    polynomial_case(mode)
  } else {
    arithmetic_case(mode)
  }
  println("{\"mode\":\"\{mode}\",\"checksum\":\{checksum},\"checked\":true}")
}
