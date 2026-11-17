///|
// Original exponent loop and public guards retained with generic multiply.
fn late_legacy_power_loop(
  base : Polynomial,
  exponent : @binary.Binary,
  modulus : Polynomial,
  accumulator : Polynomial,
) -> Result[Polynomial, PolyError] {
  match @binary.is_zero(exponent) {
    true => Ok(accumulator)
    false => {
      let next = match @binary.odd(exponent) {
        false => Ok(accumulator)
        true => product_remainder(accumulator, base, modulus)
      }
      match (next, product_remainder(base, base, modulus)) {
        (Ok(accumulator), Ok(square)) =>
          late_legacy_power_loop(
            square,
            @binary.half(exponent),
            modulus,
            accumulator,
          )
        (Err(error), _) | (_, Err(error)) => Err(error)
      }
    }
  }
}

///|
fn late_legacy_power_mod(
  base : Polynomial,
  exponent : @binary.Binary,
  modulus : Polynomial,
) -> Result[Polynomial, PolyError] {
  match compatible(base, modulus) {
    false => Err(FieldMismatch)
    true =>
      match (divide(base, modulus), divide(one(base.field), modulus)) {
        (Ok(base), Ok(unit)) =>
          late_legacy_power_loop(
            base.remainder,
            exponent,
            modulus,
            unit.remainder,
          )
        (Err(error), _) | (_, Err(error)) => Err(error)
      }
  }
}

///|
fn late_bit_degree(n : Int64) -> Int32 {
  if n < 0 {
    abort("negative exact bit oracle input")
  }
  for n = n, result = -1; n != 0; {
    continue n >> 1, result + 1
  } nobreak {
    result
  }
}

///|
fn late_bit_mod(n : Int64, modulus : Int64) -> Int64 {
  if n < 0 || modulus <= 0 {
    abort("invalid exact bit remainder input")
  }
  for n = n; late_bit_degree(n) >= late_bit_degree(modulus); {
    continue n ^ (modulus << (late_bit_degree(n) - late_bit_degree(modulus)))
  } nobreak {
    n
  }
}

///|
fn late_bit_product(a : Int64, b : Int64) -> Int64 {
  if a < 0 || b < 0 || late_bit_degree(a) + late_bit_degree(b) > 62 {
    abort("exact bit oracle range exceeded")
  }
  for a = a, b = b, out = 0L; b != 0; {
    let tail = b >> 1
    continue if tail == 0 {
        a
      } else {
        a << 1
      },
      tail,
      if (b & 1) == 1 {
        out ^ a
      } else {
        out
      }
  } nobreak {
    out
  }
}

///|
fn late_bit_power(base : Int64, exponent : Int32, modulus : Int64) -> Int64 {
  for base = late_bit_mod(base, modulus), exponent = exponent, result = late_bit_mod(
          1, modulus,
        ); exponent != 0; {
    continue late_bit_mod(late_bit_product(base, base), modulus),
      exponent / 2,
      if exponent % 2 == 1 {
        late_bit_mod(late_bit_product(result, base), modulus)
      } else {
        result
      }
  } nobreak {
    result
  }
}

///|
fn late_bits(n : Int64) -> Array[Int32] {
  Array::makei(late_bit_degree(n) + 1, fn(i) { ((n >> i) & 1).to_int() })
}

///|
test "Frobenius square exhausts raw canonicalized polynomials against unchanged multiply and bits" {
  let field = canonical_field(2)
  for mask in 0..<1024 {
    let value = canonical_polynomial(
      field,
      late_bits(mask.to_int64()).map(fn(c) { c + 4 }),
    )
    let raw_square = char_two_square(coefficients(value), @binary.zero())
    let actual = polynomial(field, raw_square)
    canonical_assert(
      actual,
      late_bits(late_bit_product(mask.to_int64(), mask.to_int64())),
      2,
    )
    assert_eq(actual, canonical_required(multiply(value, value)))
    assert_eq(raw_square, coefficients(actual))
  }
}

///|
test "known binary squares preserve exact modular powers for all small nonzero moduli" {
  let field = canonical_field(2)
  for modulus_bits in 1..<32 {
    let modulus = canonical_polynomial(
      field,
      late_bits(modulus_bits.to_int64()).map(fn(c) { c + 6 }),
    )
    for base_bits in 0..<32 {
      let base = canonical_polynomial(
        field,
        late_bits(base_bits.to_int64()).map(fn(c) { c + 4 }),
      )
      for exponent in [0, 1, 2, 3, 8, 13] {
        let actual = canonical_required(
          power_mod(base, @oracle.binary(exponent), modulus),
        )
        canonical_assert(
          actual,
          late_bits(
            late_bit_power(
              base_bits.to_int64(),
              exponent,
              modulus_bits.to_int64(),
            ),
          ),
          2,
        )
        assert_eq(
          Ok(actual),
          late_legacy_power_mod(base, @oracle.binary(exponent), modulus),
        )
      }
    }
  }
}

///|
test "square optimization leaves odd prime and exponent zero error order unchanged" {
  for p in [2, 3, 5, 17] {
    let field = canonical_field(p)
    let foreign = canonical_field(if p == 2 { 3 } else { 2 })
    for
      base in [
        zero(field),
        one(field),
        indeterminate(field),
        canonical_polynomial(field, [p + 1, p - 1, 1]),
      ] {
      for
        modulus in [
          zero(field),
          one(field),
          canonical_polynomial(field, [1, 1]),
          canonical_polynomial(field, [1, 0, 1]),
          zero(foreign),
        ] {
        for exponent in [0, 1, 2, 13] {
          assert_eq(
            power_mod(base, @oracle.binary(exponent), modulus),
            late_legacy_power_mod(base, @oracle.binary(exponent), modulus),
          )
        }
      }
    }
  }
}
