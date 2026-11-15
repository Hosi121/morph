///|
fn[A] required(result : Result[A, PolyError]) -> A {
  match result {
    Ok(value) => value
    Err(_) => abort("finite polynomial test operation")
  }
}

///|
fn test_field(p : Int32) -> @primefield.Field {
  match @primefield.field(@oracle.binary(p)) {
    Some(field) => field
    None => abort("finite polynomial test field")
  }
}

///|
fn native_mod(value : Int32, p : Int32) -> Int32 {
  (value % p + p) % p
}

///|
fn native_trim(values : Array[Int32], p : Int32) -> Array[Int32] {
  let result = values.map(fn(value) { native_mod(value, p) })
  while !result.is_empty() && result[result.length() - 1] == 0 {
    ignore(result.pop())
  }
  result
}

///|
fn test_polynomial(p : Int32, values : Array[Int32]) -> Polynomial {
  polynomial(
    test_field(p),
    @oracle.chain(
      values.map(fn(value) { @oracle.binary(native_mod(value, p)) }),
    ),
  )
}

///|
fn native(value : Polynomial) -> Array[Int32] {
  @oracle.array(coefficients(value)).map(@oracle.int_of_binary)
}

///|
fn native_add(a : Array[Int32], b : Array[Int32], p : Int32) -> Array[Int32] {
  let result = Array::make(a.length().max(b.length()), 0)
  for i in 0..<a.length() {
    result[i] += a[i]
  }
  for i in 0..<b.length() {
    result[i] += b[i]
  }
  native_trim(result, p)
}

///|
fn native_multiply(
  a : Array[Int32],
  b : Array[Int32],
  p : Int32,
) -> Array[Int32] {
  if a.is_empty() || b.is_empty() {
    return []
  }
  let result = Array::make(a.length() + b.length() - 1, 0)
  for i in 0..<a.length() {
    for j in 0..<b.length() {
      result[i + j] += a[i] * b[j]
    }
  }
  native_trim(result, p)
}

///|
fn native_divide(
  a : Array[Int32],
  b : Array[Int32],
  p : Int32,
) -> (Array[Int32], Array[Int32]) {
  let a = native_trim(a, p)
  let b = native_trim(b, p)
  assert_true(b.length() > 0) catch {
    _ => abort("native divisor")
  }
  let inverse = for candidate in 1..<p {
    if candidate * b[b.length() - 1] % p == 1 {
      break candidate
    }
  } nobreak {
    abort("native inverse")
  }
  let remainder = a.copy()
  let quotient = Array::make((a.length() - b.length() + 1).max(0), 0)
  while !remainder.is_empty() && remainder.length() >= b.length() {
    let shift = remainder.length() - b.length()
    let scalar = remainder[remainder.length() - 1] * inverse % p
    quotient[shift] = scalar
    for j in 0..<b.length() {
      remainder[shift + j] = native_mod(remainder[shift + j] - scalar * b[j], p)
    }
    while !remainder.is_empty() && remainder[remainder.length() - 1] == 0 {
      ignore(remainder.pop())
    }
  }
  (native_trim(quotient, p), remainder)
}

///|
fn native_power(base : Int32, exponent : Int32) -> Int32 {
  for i = 0, value = 1; i < exponent; {
    continue i + 1, value * base
  } nobreak {
    value
  }
}

///|
fn native_polynomial(code : Int32, p : Int32, width : Int32) -> Array[Int32] {
  let mut remaining = code
  [
    for _ in 0..<width => {
      let digit = remaining % p
      remaining /= p
      digit
    }
  ]
}

///|
// Enumerate all monic divisors, rather than repeat Euclid as a GCD oracle.
fn native_gcd(a : Array[Int32], b : Array[Int32], p : Int32) -> Array[Int32] {
  let a = native_trim(a, p)
  let b = native_trim(b, p)
  if a.is_empty() && b.is_empty() {
    return []
  }
  let bound = if a.is_empty() {
    b.length() - 1
  } else if b.is_empty() {
    a.length() - 1
  } else {
    a.length().min(b.length()) - 1
  }
  for degree = bound; degree >= 0; degree = degree - 1 {
    for code in 0..<native_power(p, degree) {
      let divisor = native_polynomial(code, p, degree)
      divisor.push(1)
      if native_divide(a, divisor, p).1.is_empty() &&
        native_divide(b, divisor, p).1.is_empty() {
        return divisor
      }
    }
  }
  abort("native gcd must include unit")
}

///|
test "finite polynomial arithmetic and Bezout exhaust small fields against native oracles" {
  for (p, width) in [(2, 4), (3, 3), (5, 2)] {
    let count = native_power(p, width)
    for a_code in 0..<count {
      let a = native_polynomial(a_code, p, width)
      let left = test_polynomial(p, a)
      for b_code in 0..<count {
        let b = native_polynomial(b_code, p, width)
        let right = test_polynomial(p, b)
        assert_eq(native(required(add(left, right))), native_add(a, b, p))
        assert_eq(
          native(required(multiply(left, right))),
          native_multiply(a, b, p),
        )
        assert_eq(
          required(subtract(left, right)),
          required(add(left, negate(right))),
        )
        let expected = native_gcd(a, b, p)
        assert_eq(native(required(gcd(left, right))), expected)
        let witness = required(extended_gcd(left, right))
        assert_eq(native(witness.gcd), expected)
        assert_eq(
          native_add(
            native_multiply(native(witness.left), a, p),
            native_multiply(native(witness.right), b, p),
            p,
          ),
          expected,
        )
        if !native_trim(b, p).is_empty() {
          let expected = native_divide(a, b, p)
          let division = required(divide(left, right))
          assert_eq(native(division.quotient), expected.0)
          assert_eq(native(division.remainder), expected.1)
          assert_eq(
            required(
              add(
                required(multiply(division.quotient, right)),
                division.remainder,
              ),
            ),
            left,
          )
        } else {
          assert_eq(divide(left, right), Err(ZeroDivisor))
        }
      }
    }
  }
}

///|
test "normalization evaluation and characteristic-dependent derivatives are exact" {
  for p in [2, 3, 5, 7] {
    let field = test_field(p)
    assert_eq(
      polynomial(
        field,
        @oracle.chain([@oracle.binary(p), @oracle.binary(p * 2)]),
      ),
      zero(field),
    )
    assert_eq(degree(zero(field)), None)
    assert_eq(leading(zero(field)), None)
    assert_eq(degree(one(field)), Some(@oracle.nat(0)))
    assert_eq(field_of(one(field)), field)
    assert_eq(characteristic(one(field)), @oracle.binary(p))
    for code in 0..<40 {
      let input = native_polynomial(code, p, 5)
      let value = test_polynomial(p, input)
      assert_eq(
        native(derivative(value)),
        native_trim([ for i in 1..<input.length() => i * input[i] ], p),
      )
      for point in 0..<(p * 2) {
        let expected = for i = input.length() - 1, accumulator = 0; i >= 0; {
          continue i - 1, (accumulator * point + input[i]) % p
        } nobreak {
          accumulator
        }
        assert_eq(
          @oracle.int_of_binary(evaluate(value, @oracle.binary(point))),
          expected,
        )
      }
      assert_eq(scale(value, @oracle.binary(p)), zero(field))
      if !is_zero(value) {
        assert_eq(leading(required(monic(value))), Some(@oracle.binary(1)))
      }
    }
    let pth_power = Array::make(p * 2 + 1, 0)
    pth_power[0] = 1
    pth_power[p] = p - 1
    pth_power[p * 2] = 1
    let value = test_polynomial(p, pth_power)
    assert_eq(derivative(value), zero(field))
    assert_eq(gcd(value, derivative(value)), monic(value))
  }
}

///|
test "binary modular powers match repeated native multiplication including constant moduli" {
  for
    (p, modulus) in [
      (2, [1, 1, 0, 1]),
      (3, [1, 0, 1]),
      (5, [2, 0, 1]),
      (7, [3]),
    ] {
    for code in 0..<20 {
      let base = native_polynomial(code, p, 4)
      for exponent in 0..<18 {
        let mut expected = native_divide([1], modulus, p).1
        for _ in 0..<exponent {
          expected = native_divide(
              native_multiply(expected, base, p),
              modulus,
              p,
            ).1
        }
        assert_eq(
          native(
            required(
              power_mod(
                test_polynomial(p, base),
                @oracle.binary(exponent),
                test_polynomial(p, modulus),
              ),
            ),
          ),
          expected,
        )
      }
    }
  }
}

///|
test "field mixing and zero polynomial divisors fail before arithmetic" {
  let a = one(test_field(2))
  let b = one(test_field(3))
  assert_false(a.equal(b))
  assert_true(a.not_equal(b))
  assert_eq(add(a, b), Err(FieldMismatch))
  assert_eq(subtract(a, b), Err(FieldMismatch))
  assert_eq(multiply(a, b), Err(FieldMismatch))
  assert_eq(divide(a, b), Err(FieldMismatch))
  assert_eq(gcd(a, b), Err(FieldMismatch))
  assert_eq(extended_gcd(a, b), Err(FieldMismatch))
  assert_eq(power_mod(a, @oracle.binary(0), b), Err(FieldMismatch))
  assert_eq(divide(zero(test_field(2)), zero(test_field(2))), Err(ZeroDivisor))
  assert_eq(
    power_mod(a, @oracle.binary(0), zero(test_field(2))),
    Err(ZeroDivisor),
  )
  assert_eq(monic(zero(test_field(2))), Ok(zero(test_field(2))))
}
