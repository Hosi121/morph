///|
fn carryless_native_degree(value : Int32) -> Int32 {
  for rest = value, degree = -1; rest > 0; {
    continue rest >> 1, degree + 1
  } nobreak {
    degree
  }
}

///|
// Full native product then top-degree long division: independent from the
// fixed-width shift/reduce multiplication kernel.
fn carryless_native_remainder(value : Int32, modulus : Int32) -> Int32 {
  let degree = carryless_native_degree(modulus)
  for value = value; carryless_native_degree(value) >= degree; {
    continue value ^ (modulus << (carryless_native_degree(value) - degree))
  } nobreak {
    value
  }
}

///|
fn carryless_native_multiply(a : Int32, b : Int32, modulus : Int32) -> Int32 {
  let product = for rest = b, shifted = a, accumulator = 0; rest > 0; {
    continue rest >> 1,
      shifted << 1,
      if (rest & 1) == 1 {
        accumulator ^ shifted
      } else {
        accumulator
      }
  } nobreak {
    accumulator
  }
  carryless_native_remainder(product, modulus)
}

///|
fn carryless_native_irreducible(modulus : Int32, degree : Int32) -> Bool {
  for divisor_degree in 1..<(degree / 2 + 1) {
    for lower in 0..<(1 << divisor_degree) {
      if carryless_native_remainder(modulus, (1 << divisor_degree) | lower) == 0 {
        return false
      }
    }
  }
  true
}

///|
fn carryless_symbol(field : Field, value : Int32, width : Int32) -> Element {
  test_element(field, [ for bit in 0..<width => (value >> bit) & 1 ])
}

///|
test "fixed-width products exhaust every binary field presentation through degree five" {
  for degree in 1..<6 {
    let q = 1 << degree
    for lower in 0..<q {
      let modulus = q | lower
      if carryless_native_irreducible(modulus, degree) {
        let field = test_field(
          2,
          [
            for bit in 0..<(degree + 1) => (modulus >> bit) & 1
          ],
        )
        let values = [
          for code in 0..<q => carryless_symbol(field, code, degree)
        ]
        for a in 0..<q {
          for b in 0..<q {
            let expected = carryless_native_multiply(a, b, modulus)
            assert_eq(
              char_two_native(required(multiply(values[a], values[b]))),
              expected,
            )
            assert_eq(
              char_two_native(binary_field_product(values[a], values[b])),
              expected,
            )
          }
        }
      }
    }
  }
  let x = test_field(2, [0, 1])
  let x_plus_one = test_field(2, [1, 1])
  assert_eq(multiply(one(x), zero(x_plus_one)), Err(FieldMismatch))
  assert_eq(multiply(zero(x), one(x_plus_one)), Err(FieldMismatch))
}

///|
fn carryless_native_power(
  value : Int32,
  exponent : Int32,
  modulus : Int32,
) -> Int32 {
  for base = value, exponent = exponent, result = 1; exponent > 0; {
    continue carryless_native_multiply(base, base, modulus),
      exponent / 2,
      if exponent % 2 == 1 {
        carryless_native_multiply(result, base, modulus)
      } else {
        result
      }
  } nobreak {
    result
  }
}

///|
test "fixed-width products cross the octet boundary in GF1024" {
  let modulus = 0x409
  assert_true(carryless_native_irreducible(modulus, 10))
  let field = test_field(2, [ for bit in 0..<11 => (modulus >> bit) & 1 ])
  for i in 0..<128 {
    let a = (i * 37 + 11) % 1024
    let b = (i * i * 19 + 7) % 1024
    assert_eq(
      char_two_native(
        required(
          multiply(
            carryless_symbol(field, a, 10),
            carryless_symbol(field, b, 10),
          ),
        ),
      ),
      carryless_native_multiply(a, b, modulus),
    )
  }
  for code in [1, 2, 83, 1023] {
    let value = carryless_symbol(field, code, 10)
    let reciprocal = required(inverse(value))
    assert_eq(
      char_two_native(reciprocal),
      carryless_native_power(code, 1022, modulus),
    )
    assert_eq(required(multiply(value, reciprocal)), one(field))
  }
}
