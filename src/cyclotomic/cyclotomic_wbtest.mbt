///|
fn[A] required(result : Result[A, CyclotomicError]) -> A {
  match result {
    Ok(value) => value
    Err(_) => abort("cyclotomic test operation failed")
  }
}

///|
fn test_field(n : Int32) -> Field {
  match field(@oracle.nat(n)) {
    Some(value) => value
    None => abort("cyclotomic test field")
  }
}

///|
fn test_polynomial(values : Array[(Int32, Int32)]) -> @polynomial.Polynomial {
  let terms = [
    for exponent in 0..<values.length() => {
      let (numerator, denominator) = values[exponent]
      @polynomial.Term::{
        coefficient: @oracle.rational(numerator, denominator),
        exponents: @core.Cons(@oracle.nat(exponent), Nil),
      }
    }
  ]
  match @polynomial.polynomial(@oracle.nat(1), @oracle.chain(terms)) {
    Ok(value) => value
    Err(_) => abort("cyclotomic test polynomial")
  }
}

///|
fn test_element(field : Field, values : Array[Int32]) -> Element {
  required(
    element(field, test_polynomial(values.map(fn(value) { (value, 1) }))),
  )
}

///|
fn assert_fixture(
  n : Int32,
  input : Array[(Int32, Int32)],
  other : Array[(Int32, Int32)],
  expected_product : Array[(Int32, Int32)],
  expected_inverse : Array[(Int32, Int32)],
  expected_conjugate : Array[(Int32, Int32)],
) -> Unit raise {
  let field = test_field(n)
  let value = required(element(field, test_polynomial(input)))
  let other = required(element(field, test_polynomial(other)))
  assert_eq(
    representative(required(multiply(value, other))),
    test_polynomial(expected_product),
  )
  let inverted = required(inverse(value))
  assert_eq(representative(inverted), test_polynomial(expected_inverse))
  assert_eq(required(multiply(value, inverted)), one(field))
  assert_eq(required(multiply(inverted, value)), one(field))
  assert_eq(
    representative(required(conjugate(value))),
    test_polynomial(expected_conjugate),
  )
  assert_eq(required(conjugate(required(conjugate(value)))), value)
}

///|
test "power-of-two presentations reject bad orders and distinguish rational copies" {
  for n in 0..<34 {
    let expected = n > 0 && (n & (n - 1)) == 0
    assert_eq(field(@oracle.nat(n)) is Some(_), expected)
  }
  let first = test_field(1)
  let second = test_field(2)
  assert_eq(@oracle.int_of_nat(degree(first)), 1)
  assert_eq(@oracle.int_of_nat(degree(second)), 1)
  assert_eq(generator(first), one(first))
  assert_eq(generator(second), negate(one(second)))
  assert_eq(required(conjugate(generator(first))), generator(first))
  assert_eq(required(conjugate(generator(second))), generator(second))
  assert_eq(defining_polynomial(first), test_polynomial([(-1, 1), (1, 1)]))
  assert_eq(defining_polynomial(second), test_polynomial([(1, 1), (1, 1)]))
  assert_eq(add(one(first), one(second)), Err(FieldMismatch))
  assert_eq(subtract(one(first), one(second)), Err(FieldMismatch))
  assert_eq(multiply(one(first), one(second)), Err(FieldMismatch))
  assert_eq(divide(one(first), zero(second)), Err(FieldMismatch))
}

///|
test "canonical reductions, primitive roots and exact conjugation through order 32" {
  for n in [1, 2, 4, 8, 16, 32] {
    let field = test_field(n)
    let d = if n == 1 { 1 } else { n / 2 }
    assert_eq(@oracle.int_of_nat(order(field)), n)
    assert_eq(@oracle.int_of_nat(degree(field)), d)
    assert_eq(required(element(field, defining_polynomial(field))), zero(field))
    let root = generator(field)
    assert_eq(required(power(root, @oracle.binary(n))), one(field))
    if n > 1 {
      assert_eq(
        required(power(root, @oracle.binary(n / 2))),
        negate(one(field)),
      )
    }
    assert_eq(required(multiply(root, required(conjugate(root)))), one(field))
    for exponent in 0..<(n * 3) {
      let input = Array::make(exponent + 1, 0)
      input[exponent] = 1
      let expected = Array::make(d, 0)
      expected[exponent % d] = if n == 1 || exponent / d % 2 == 0 {
        1
      } else {
        -1
      }
      assert_eq(test_element(field, input), test_element(field, expected))
    }
  }
}

///|
test "Gaussian rationals exhaust ternary coefficients against independent pair arithmetic" {
  let field = test_field(4)
  for a in -1..<=1 {
    for b in -1..<=1 {
      let left = test_element(field, [a, b])
      assert_eq(required(conjugate(left)), test_element(field, [a, -b]))
      assert_eq(required(subtract(left, left)), zero(field))
      if a != 0 || b != 0 {
        let norm = a * a + b * b
        assert_eq(
          representative(required(inverse(left))),
          test_polynomial([(a, norm), (-b, norm)]),
        )
      }
      for c in -1..<=1 {
        for d in -1..<=1 {
          let right = test_element(field, [c, d])
          assert_eq(
            required(add(left, right)),
            test_element(field, [a + c, b + d]),
          )
          assert_eq(
            required(multiply(left, right)),
            test_element(field, [a * c - b * d, a * d + b * c]),
          )
        }
      }
    }
  }
}

///|
test "zero division, multivariate input and cross-field arithmetic fail explicitly" {
  let field = test_field(8)
  let other = test_field(4)
  assert_eq(inverse(zero(field)), Err(ZeroDivisor))
  assert_eq(divide(one(field), zero(field)), Err(ZeroDivisor))
  assert_eq(divide(zero(field), one(field)), Ok(zero(field)))
  assert_eq(required(power(zero(field), @oracle.binary(0))), one(field))
  assert_eq(add(one(field), one(other)), Err(FieldMismatch))
  assert_eq(multiply(zero(field), zero(other)), Err(FieldMismatch))
  for dimensions in [0, 2, 3] {
    assert_eq(
      element(field, @polynomial.zero(@oracle.nat(dimensions))),
      Err(PolynomialError(@polynomial.DimensionMismatch)),
    )
  }
}

///|
test "field laws and conjugation preserve exact rational coefficients" {
  for n in [1, 2, 4, 8, 16] {
    let field = test_field(n)
    let root = generator(field)
    let a = required(add(root, rational(field, @oracle.rational(2, 3))))
    let b = required(
      subtract(required(power(root, @oracle.binary(3))), one(field)),
    )
    let c = rational(field, @oracle.rational(-3, 5))
    assert_eq(
      required(multiply(a, required(add(b, c)))),
      required(add(required(multiply(a, b)), required(multiply(a, c)))),
    )
    assert_eq(required(divide(required(multiply(a, b)), a)), b)
    assert_eq(
      required(conjugate(required(multiply(a, b)))),
      required(multiply(required(conjugate(a)), required(conjugate(b)))),
    )
    assert_eq(
      required(conjugate(required(add(a, b)))),
      required(add(required(conjugate(a)), required(conjugate(b)))),
    )
    assert_eq(field_of(a), field)
  }
}
