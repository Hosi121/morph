///|
fn char_two_symbol(field : Field, value : Int32) -> Element {
  test_element(field, [ for bit in 0..<8 => (value >> bit) & 1 ])
}

///|
fn char_two_native(value : Element) -> Int32 {
  let coefficients = native(value)
  for i = coefficients.length() - 1, result = 0; i >= 0; {
    continue i - 1, (result << 1) | coefficients[i]
  } nobreak {
    result
  }
}

///|
fn char_two_native_product(a : Int32, b : Int32, modulus : Int32) -> Int32 {
  let mut a = a
  let mut b = b
  let mut result = 0
  while b > 0 {
    if (b & 1) != 0 {
      result = result ^ a
    }
    a = a << 1
    if (a & 256) != 0 {
      a = a ^ modulus
    }
    b = b >> 1
  }
  result
}

///|
fn char_two_native_power(
  value : Int32,
  exponent : Int32,
  modulus : Int32,
) -> Int32 {
  for base = value, rest = exponent, result = 1; rest > 0; {
    continue char_two_native_product(base, base, modulus),
      rest / 2,
      if rest % 2 == 1 {
        char_two_native_product(result, base, modulus)
      } else {
        result
      }
  } nobreak {
    result
  }
}

///|
test "all GF256 products and inverses match native carryless reduction for AES and RS moduli" {
  for
    (modulus, polynomial) in [
      (283, [1, 1, 0, 1, 1, 0, 0, 0, 1]),
      (285, [1, 0, 1, 1, 1, 0, 0, 0, 1]),
    ] {
    let field = test_field(2, polynomial)
    let values = [ for code in 0..<256 => char_two_symbol(field, code) ]
    for a in 0..<256 {
      for b in 0..<256 {
        assert_eq(
          char_two_native_product(a, b, modulus),
          carryless_native_multiply(a, b, modulus),
        )
        assert_eq(
          char_two_native(required(multiply(values[a], values[b]))),
          char_two_native_product(a, b, modulus),
        )
      }
      if a == 0 {
        assert_eq(inverse(values[a]), Err(ZeroDivisor))
      } else {
        assert_eq(
          char_two_native(required(inverse(values[a]))),
          char_two_native_power(a, 254, modulus),
        )
      }
    }
  }
}
