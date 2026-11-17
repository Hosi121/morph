// Independent host-integer oracles. Polynomial operations below use only the
// public API, and constructors receive the original unreduced coefficients.

///|
fn canonical_mod(value : Int64, p : Int32) -> Int32 {
  let modulus = p.to_int64()
  ((value % modulus + modulus) % modulus).to_int()
}

///|
fn canonical_trim(values : Array[Int32], p : Int32) -> Array[Int32] {
  let result = values.map(fn(value) { canonical_mod(value.to_int64(), p) })
  while !result.is_empty() && result[result.length() - 1] == 0 {
    ignore(result.pop())
  }
  result
}

///|
fn canonical_field(p : Int32) -> @primefield.Field {
  match @primefield.field(@oracle.binary(p)) {
    Some(field) => field
    None => abort("canonical oracle requires a prime")
  }
}

///|
fn canonical_polynomial(
  field : @primefield.Field,
  values : Array[Int32],
) -> Polynomial {
  polynomial(field, @oracle.chain(values.map(@oracle.binary)))
}

///|
fn[A] canonical_required(result : Result[A, PolyError]) -> A {
  match result {
    Ok(value) => value
    Err(_) => abort("canonical oracle operation failed")
  }
}

///|
fn canonical_assert(
  value : Polynomial,
  expected : Array[Int32],
  p : Int32,
) -> Unit raise {
  let actual = @oracle.array(coefficients(value)).map(@oracle.int_of_binary)
  assert_eq(actual, expected)
  assert_eq(@oracle.int_of_binary(characteristic(value)), p)
  for coefficient in actual {
    assert_true(coefficient >= 0 && coefficient < p)
  }
  assert_true(actual.is_empty() || actual[actual.length() - 1] != 0)
  assert_eq(is_zero(value), actual.is_empty())
}

///|
fn canonical_sum(
  a : Array[Int32],
  b : Array[Int32],
  p : Int32,
  sign : Int32,
) -> Array[Int32] {
  let result = Array::make(a.length().max(b.length()), 0)
  for i in 0..<result.length() {
    let x = if i < a.length() { a[i] } else { 0 }
    let y = if i < b.length() { b[i] } else { 0 }
    result[i] = canonical_mod(x.to_int64() + sign.to_int64() * y.to_int64(), p)
  }
  canonical_trim(result, p)
}

///|
fn canonical_product(
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
      // In particular, 65536 * 65536 exceeds a signed 32-bit integer.
      result[i + j] = canonical_mod(
        result[i + j].to_int64() + a[i].to_int64() * b[j].to_int64(),
        p,
      )
    }
  }
  canonical_trim(result, p)
}

///|
fn canonical_division(
  a : Array[Int32],
  b : Array[Int32],
  p : Int32,
) -> (Array[Int32], Array[Int32]) {
  let remainder = canonical_trim(a, p)
  let divisor = canonical_trim(b, p)
  if divisor.is_empty() {
    abort("canonical host divisor must be nonzero")
  }
  // Trial inversion is independent of the library's extended Euclid routine.
  let inverse = for candidate in 1..<p {
    if canonical_mod(
        candidate.to_int64() * divisor[divisor.length() - 1].to_int64(),
        p,
      ) ==
      1 {
      break candidate
    }
  } nobreak {
    abort("canonical host inverse must exist")
  }
  let quotient = Array::make(
    (remainder.length() - divisor.length() + 1).max(0),
    0,
  )
  while !remainder.is_empty() && remainder.length() >= divisor.length() {
    let shift = remainder.length() - divisor.length()
    let scalar = canonical_mod(
      remainder[remainder.length() - 1].to_int64() * inverse.to_int64(),
      p,
    )
    quotient[shift] = scalar
    for j in 0..<divisor.length() {
      remainder[shift + j] = canonical_mod(
        remainder[shift + j].to_int64() -
        scalar.to_int64() * divisor[j].to_int64(),
        p,
      )
    }
    while !remainder.is_empty() && remainder[remainder.length() - 1] == 0 {
      ignore(remainder.pop())
    }
  }
  (canonical_trim(quotient, p), remainder)
}

///|
test "canonical constructors unary operations and unreduced points match host integers" {
  for p in [2, 3, 5, 17, 257, 65537] {
    let field = canonical_field(p)
    canonical_assert(zero(field), [], p)
    canonical_assert(one(field), [1], p)
    canonical_assert(indeterminate(field), [0, 1], p)
    canonical_assert(constant(field, @oracle.binary(p * 3)), [], p)
    canonical_assert(constant(field, @oracle.binary(p * 3 - 1)), [p - 1], p)
    for
      input in [
        [],
        [0, p, p * 2, 0],
        [p + 1, p * 2, p - 1, p * 3],
        [p * 3 - 1, p + 1, 0, p * 2 + 1, 0, p * 3],
        [p - 1, 0, p - 1],
        [0, p - 1, 0, 1, p * 4],
      ] {
      let value = canonical_polynomial(field, input)
      let expected = canonical_trim(input, p)
      canonical_assert(value, expected, p)
      canonical_assert(negate(value), canonical_sum([], expected, p, -1), p)
      canonical_assert(negate(negate(value)), expected, p)
      canonical_assert(canonical_required(add(value, negate(value))), [], p)
      canonical_assert(canonical_required(subtract(value, value)), [], p)
      for scalar in [0, 1, p - 1, p, p + 1, p * 2 + 1] {
        canonical_assert(
          scale(value, @oracle.binary(scalar)),
          canonical_trim(
            expected.map(fn(c) {
              canonical_mod(c.to_int64() * scalar.to_int64(), p)
            }),
            p,
          ),
          p,
        )
      }
      canonical_assert(
        derivative(value),
        canonical_trim(
          [
            for i in 1..<expected.length() => {
              canonical_mod(i.to_int64() * expected[i].to_int64(), p)
            }
          ],
          p,
        ),
        p,
      )
      for point in [0, p - 1, p, p + 1, p * 2 + 3] {
        let evaluated = for i = expected.length() - 1, accumulator = 0; i >= 0; {
          continue i - 1,
            canonical_mod(
              accumulator.to_int64() * point.to_int64() + expected[i].to_int64(),
              p,
            )
        } nobreak {
          accumulator
        }
        assert_eq(
          @oracle.int_of_binary(evaluate(value, @oracle.binary(point))),
          evaluated,
        )
      }
    }
  }
}

///|
test "canonical sums exhaust small residue pairs and larger prime boundaries" {
  for p in [2, 3, 5, 17, 257, 65537] {
    let field = canonical_field(p)
    let alphabet = if p <= 17 {
      [
        for residue in 0..<p => residue
      ]
    } else {
      [0, 1, 2, p / 2, p / 2 + 1, p - 2, p - 1]
    }
    for a in alphabet {
      let left_input = [p + a, p * 2, p * 2 - 1, p * 3]
      let left = canonical_polynomial(field, left_input)
      canonical_assert(negate(left), canonical_sum([], left_input, p, -1), p)
      for b in alphabet {
        // Equal widths cancel the highest coefficient; the shorter operand
        // also exercises both immutable-tail reuse cases.
        let right_input = [p * 2 + b, p - 1, p * 2 + 1, p * 4]
        let right = canonical_polynomial(field, right_input)
        let short_input = [p * 2 + b]
        let short = canonical_polynomial(field, short_input)
        canonical_assert(
          canonical_required(add(left, right)),
          canonical_sum(left_input, right_input, p, 1),
          p,
        )
        canonical_assert(
          canonical_required(subtract(left, right)),
          canonical_sum(left_input, right_input, p, -1),
          p,
        )
        canonical_assert(
          canonical_required(add(left, short)),
          canonical_sum(left_input, short_input, p, 1),
          p,
        )
        canonical_assert(
          canonical_required(add(short, left)),
          canonical_sum(short_input, left_input, p, 1),
          p,
        )
        canonical_assert(
          canonical_required(subtract(short, left)),
          canonical_sum(short_input, left_input, p, -1),
          p,
        )
      }
    }
  }
}

///|
test "canonical products division and mismatch precedence match independent oracles" {
  for p in [2, 3, 5, 17, 257, 65537] {
    let field = canonical_field(p)
    for
      (a, b) in [
        ([], []),
        ([], [p - 1, 1]),
        ([p * 2 - 1, p + 1, p - 1, 1], [0, p * 2]),
        ([p * 2 - 1, p + 1, p - 1, 1], [p + 1, p * 2 - 1]),
        ([p - 1, 0, p - 1, 1], [p - 1, 0, p - 1]),
        ([p - 1], [p - 1, 1]),
        ([p - 1, 0, p - 1], [p - 1]),
        ([p - 1, 0, p - 1], [1]),
        ([p + 1, p * 2, p * 2 - 1], [p * 2 - 1, p + 1, 0, 1]),
      ] {
      let left = canonical_polynomial(field, a)
      let right = canonical_polynomial(field, b)
      canonical_assert(
        canonical_required(multiply(left, right)),
        canonical_product(a, b, p),
        p,
      )
      if canonical_trim(b, p).is_empty() {
        assert_eq(divide(left, right), Err(ZeroDivisor))
      } else {
        let expected = canonical_division(a, b, p)
        let actual = canonical_required(divide(left, right))
        canonical_assert(actual.quotient, expected.0, p)
        canonical_assert(actual.remainder, expected.1, p)
      }
    }
    let foreign = canonical_field(if p == 2 { 3 } else { 2 })
    for left in [zero(field), one(field)] {
      for right in [zero(foreign), one(foreign)] {
        assert_eq(add(left, right), Err(FieldMismatch))
        assert_eq(subtract(left, right), Err(FieldMismatch))
        assert_eq(multiply(left, right), Err(FieldMismatch))
        assert_eq(divide(left, right), Err(FieldMismatch))
      }
    }
  }
}
