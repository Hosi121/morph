///|
// Retained original generic row construction as a second oracle.
fn night_legacy_convolution(
  modulus : @modular.Modulus,
  a : @core.Chain[@binary.Binary],
  b : @core.Chain[@binary.Binary],
) -> @core.Chain[@binary.Binary] {
  match a {
    Nil => Nil
    Cons(head, tail) =>
      add_coefficients(
        modulus,
        @core.map(b, fn(coefficient) {
          multiply_reduced(modulus, head, coefficient)
        }),
        Cons(@binary.zero(), night_legacy_convolution(modulus, tail, b)),
      )
  }
}

///|
fn night_check_convolution(
  field : @primefield.Field,
  a : Array[Int32],
  b : Array[Int32],
  p : Int32,
) -> Unit raise {
  let left = canonical_polynomial(field, a)
  let right = canonical_polynomial(field, b)
  let actual = canonical_required(multiply(left, right))
  canonical_assert(actual, canonical_product(a, b, p), p)
  assert_eq(
    coefficients(actual),
    trim_reduced(
      night_legacy_convolution(
        @primefield.modulus(field),
        coefficients(left),
        coefficients(right),
      ),
    ),
  )
}

///|
test "night convolution exhausts small row pairs and canonical prime boundaries" {
  for p in [2, 3, 5, 17, 257, 65537] {
    let field = canonical_field(p)
    let alphabet = if p <= 5 {
      [
        for x in 0..<p => x
      ]
    } else {
      [0, 1, 2, p - 1]
    }
    for a in alphabet {
      for b in alphabet {
        for c in alphabet {
          for d in alphabet {
            night_check_convolution(
              field,
              [p + a, p * 2 + b],
              [p * 3 + c, p + d],
              p,
            )
          }
        }
      }
    }
  }
}

///|
test "night convolution wide zero unit sparse rows and mismatch first behavior" {
  for p in [2, 3, 17, 257, 65537] {
    let field = canonical_field(p)
    for width in [0, 1, 2, 17, 65] {
      let sparse = Array::makei(width, fn(i) {
        if i % 16 == 0 {
          p * 2 + p - 1
        } else {
          p * 3
        }
      })
      let units = Array::makei(width, fn(i) {
        if i % 3 == 0 {
          p * 2
        } else {
          p * 2 + 1
        }
      })
      let dense = Array::makei(9, fn(i) { p + (i * 7 + 2) % p })
      for a in [sparse, units] {
        night_check_convolution(field, a, dense, p)
        night_check_convolution(field, dense, a, p)
        night_check_convolution(field, a, [], p)
        night_check_convolution(field, [], a, p)
        night_check_convolution(field, a, [1], p)
      }
    }
    let foreign = canonical_field(if p == 2 { 3 } else { 2 })
    for a in [zero(field), one(field)] {
      for b in [zero(foreign), one(foreign)] {
        assert_eq(multiply(a, b), Err(FieldMismatch))
        assert_eq(multiply(b, a), Err(FieldMismatch))
      }
    }
  }
}
