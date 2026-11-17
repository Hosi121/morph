// Baseline modular power schedule using unchanged public divide as oracle.

///|
fn late_divide_product(
  a : Polynomial,
  b : Polynomial,
  modulus : Polynomial,
) -> Result[Polynomial, PolyError] {
  match divide(multiply_raw(a, b), modulus) {
    Err(error) => Err(error)
    Ok(division) => Ok(division.remainder)
  }
}

///|
fn late_divide_square(
  base : Polynomial,
  modulus : Polynomial,
) -> Result[Polynomial, PolyError] {
  if !characteristic_two(base.field) {
    return late_divide_product(base, base, modulus)
  }
  let square : Polynomial = {
    field: base.field,
    coefficients: char_two_square(base.coefficients, @binary.zero()),
  }
  match divide(square, modulus) {
    Err(error) => Err(error)
    Ok(division) => Ok(division.remainder)
  }
}

///|
fn late_divide_power_loop(
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
        true => late_divide_product(accumulator, base, modulus)
      }
      match (next, late_divide_square(base, modulus)) {
        (Ok(accumulator), Ok(square)) =>
          late_divide_power_loop(
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
fn late_divide_power_mod(
  base : Polynomial,
  exponent : @binary.Binary,
  modulus : Polynomial,
) -> Result[Polynomial, PolyError] {
  match compatible(base, modulus) {
    false => Err(FieldMismatch)
    true =>
      match (divide(base, modulus), divide(one(base.field), modulus)) {
        (Ok(base), Ok(unit)) =>
          late_divide_power_loop(
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
fn late_public_remainder(
  a : Polynomial,
  b : Polynomial,
) -> Result[Polynomial, PolyError] {
  match divide(a, b) {
    Err(e) => Err(e)
    Ok(d) => Ok(d.remainder)
  }
}

///|
test "private remainders exhaust small raw vectors against public division and host integers" {
  for p in [2, 3, 5] {
    let field = canonical_field(p)
    for code_a in 0..<(p * p * p) {
      let a = [code_a % p + p, code_a / p % p + p * 2, code_a / (p * p) + p]
      let left = canonical_polynomial(field, a)
      for code_b in 0..<(p * p) {
        let b = [code_b % p + p, code_b / p + p * 2]
        let right = canonical_polynomial(field, b)
        let actual = remainder_only(left, right)
        assert_eq(actual, late_public_remainder(left, right))
        if canonical_trim(b, p).is_empty() {
          assert_eq(actual, Err(ZeroDivisor))
        } else {
          canonical_assert(
            canonical_required(actual),
            canonical_division(a, b, p).1,
            p,
          )
        }
      }
    }
  }
}

///|
test "private remainder and power preserve constant inverse context and error precedence" {
  for p in [2, 3, 5, 17, 257] {
    let field = canonical_field(p)
    let foreign = canonical_field(if p == 2 { 3 } else { 2 })
    let values = [
      zero(field),
      one(field),
      canonical_polynomial(field, [p - 1, 0, 1, p - 1, 1]),
    ]
    let moduli = [
      zero(field),
      one(field),
      constant(field, @oracle.binary(p - 1)),
      canonical_polynomial(field, [1, 0, p - 1]),
      canonical_polynomial(field, [p - 1, 1, p - 1, 1, 1, p - 1]),
      zero(foreign),
    ]
    for a in values {
      for b in moduli {
        assert_eq(remainder_only(a, b), late_public_remainder(a, b))
        for exponent in [0, 1, 2, 3, 13] {
          assert_eq(
            power_mod(a, @oracle.binary(exponent), b),
            late_divide_power_mod(a, @oracle.binary(exponent), b),
          )
        }
      }
    }
  }
}
