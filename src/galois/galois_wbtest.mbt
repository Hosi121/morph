///|
fn[A] required(result : Result[A, FieldError]) -> A {
  match result {
    Ok(value) => value
    Err(_) => abort("extension test operation")
  }
}

///|
fn[A] poly_required(result : Result[A, @fppoly.PolyError]) -> A {
  match result {
    Ok(value) => value
    Err(_) => abort("extension test polynomial")
  }
}

///|
fn test_prime(p : Int32) -> @primefield.Field {
  match @primefield.field(@oracle.binary(p)) {
    Some(value) => value
    None => abort("extension test prime")
  }
}

///|
fn test_polynomial(
  p : Int32,
  coefficients : Array[Int32],
) -> @fppoly.Polynomial {
  @fppoly.polynomial(
    test_prime(p),
    @oracle.chain(coefficients.map(@oracle.binary)),
  )
}

///|
fn test_certificate(
  polynomial : @fppoly.Polynomial,
) -> @fppoly.IrreducibilityCertificate {
  match poly_required(@fppoly.irreducibility(polynomial)) {
    Some(value) => value
    None => abort("extension test irreducibility")
  }
}

///|
fn test_field(p : Int32, coefficients : Array[Int32]) -> Field {
  let polynomial = test_polynomial(p, coefficients)
  match extension(polynomial, test_certificate(polynomial)) {
    Some(value) => value
    None => abort("extension test field")
  }
}

///|
fn test_element(field : Field, coefficients : Array[Int32]) -> Element {
  required(
    element(
      field,
      @fppoly.polynomial(
        prime_field(field),
        @oracle.chain(coefficients.map(@oracle.binary)),
      ),
    ),
  )
}

///|
fn native(value : Element) -> Array[Int32] {
  @oracle.array(@fppoly.coefficients(representative(value))).map(
    @oracle.int_of_binary,
  )
}

///|
fn trim(values : Array[Int32], p : Int32) -> Array[Int32] {
  let result = values.map(fn(value) { (value % p + p) % p })
  while !result.is_empty() && result[result.length() - 1] == 0 {
    ignore(result.pop())
  }
  result
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
  trim(result, p)
}

///|
fn native_reduce(
  values : Array[Int32],
  modulus : Array[Int32],
  p : Int32,
) -> Array[Int32] {
  let remainder = trim(values, p)
  while remainder.length() >= modulus.length() {
    let shift = remainder.length() - modulus.length()
    let scalar = remainder[remainder.length() - 1]
    for j in 0..<modulus.length() {
      remainder[shift + j] = (
          (remainder[shift + j] - scalar * modulus[j]) % p + p
        ) %
        p
    }
    while !remainder.is_empty() && remainder[remainder.length() - 1] == 0 {
      ignore(remainder.pop())
    }
  }
  remainder
}

///|
fn native_multiply(
  a : Array[Int32],
  b : Array[Int32],
  modulus : Array[Int32],
  p : Int32,
) -> Array[Int32] {
  if a.is_empty() || b.is_empty() {
    return []
  }
  let product = Array::make(a.length() + b.length() - 1, 0)
  for i in 0..<a.length() {
    for j in 0..<b.length() {
      product[i + j] += a[i] * b[j]
    }
  }
  native_reduce(product, modulus, p)
}

///|
fn native_power(
  value : Array[Int32],
  exponent : Int32,
  modulus : Array[Int32],
  p : Int32,
) -> Array[Int32] {
  for i = 0, result = [1]; i < exponent; {
    continue i + 1, native_multiply(result, value, modulus, p)
  } nobreak {
    result
  }
}

///|
fn digits(code : Int32, p : Int32, width : Int32) -> Array[Int32] {
  let mut remaining = code
  trim(
    [
      for _ in 0..<width => {
        let digit = remaining % p
        remaining /= p
        digit
      }
    ],
    p,
  )
}

///|
fn assert_extension_fixture(
  p : Int32,
  modulus : Array[Int32],
  a : Array[Int32],
  b : Array[Int32],
  product : Array[Int32],
  reciprocal : Array[Int32],
  expected_trace : Int32,
  expected_norm : Int32,
) -> Unit raise {
  let field = test_field(p, modulus)
  let a = test_element(field, a)
  let b = test_element(field, b)
  assert_eq(native(required(multiply(a, b))), product)
  assert_eq(native(required(inverse(a))), reciprocal)
  assert_eq(@oracle.int_of_binary(required(trace(a))), expected_trace)
  assert_eq(@oracle.int_of_binary(required(norm(a))), expected_norm)
}

///|
test "all pairs in seven finite extensions agree with native quotient-ring arithmetic" {
  for
    (p, polynomial) in [
      (2, [1, 1, 1]),
      (2, [1, 1, 0, 1]),
      (3, [1, 0, 1]),
      (2, [1, 1, 0, 0, 1]),
      (5, [2, 0, 1]),
      (3, [1, 2, 0, 1]),
      (7, [1, 0, 1]),
    ] {
    let field = test_field(p, polynomial)
    let width = polynomial.length() - 1
    let count = @oracle.int_of_binary(cardinality(field))
    assert_eq(degree(field), @oracle.nat(width))
    assert_eq(characteristic(field), @oracle.binary(p))
    assert_eq(modulus(field), test_polynomial(p, polynomial))
    let values = [
      for code in 0..<count => test_element(field, digits(code, p, width))
    ]
    let reciprocals = [
      for code in 0..<count => {
        if code == 0 {
          []
        } else {
          let coefficients = digits(code, p, width)
          for candidate in 1..<count {
            let inverse = digits(candidate, p, width)
            if native_multiply(coefficients, inverse, polynomial, p) == [1] {
              break inverse
            }
          } nobreak {
            abort("native extension inverse must exist")
          }
        }
      }
    ]
    for a in 0..<count {
      let left = digits(a, p, width)
      if a == 0 {
        assert_eq(inverse(values[a]), Err(ZeroDivisor))
      } else {
        assert_eq(native(required(inverse(values[a]))), reciprocals[a])
        assert_eq(
          required(power(values[a], @oracle.binary(count - 1))),
          one(field),
        )
      }
      assert_eq(required(power(values[a], @oracle.binary(count))), values[a])
      assert_eq(required(power(values[a], @oracle.binary(0))), one(field))
      let mut conjugate = left
      let mut expected_trace : Array[Int32] = []
      let mut expected_norm = [1]
      for _ in 0..<width {
        expected_trace = native_add(expected_trace, conjugate, p)
        expected_norm = native_multiply(expected_norm, conjugate, polynomial, p)
        conjugate = native_power(conjugate, p, polynomial, p)
      }
      assert_eq(conjugate, left)
      assert_true(expected_trace.length() <= 1)
      assert_true(expected_norm.length() <= 1)
      assert_eq(
        @oracle.int_of_binary(required(trace(values[a]))),
        if expected_trace.is_empty() {
          0
        } else {
          expected_trace[0]
        },
      )
      assert_eq(
        @oracle.int_of_binary(required(norm(values[a]))),
        if expected_norm.is_empty() {
          0
        } else {
          expected_norm[0]
        },
      )
      assert_eq(
        native(required(frobenius(values[a]))),
        native_power(left, p, polynomial, p),
      )
      for b in 0..<count {
        let right = digits(b, p, width)
        assert_eq(
          native(required(add(values[a], values[b]))),
          native_add(left, right, p),
        )
        assert_eq(
          native(required(subtract(values[a], values[b]))),
          native_add(left, right.map(fn(coefficient) { -coefficient }), p),
        )
        assert_eq(
          native(required(multiply(values[a], values[b]))),
          native_multiply(left, right, polynomial, p),
        )
        if b == 0 {
          assert_eq(divide(values[a], values[b]), Err(ZeroDivisor))
        } else {
          assert_eq(
            native(required(divide(values[a], values[b]))),
            native_multiply(left, reciprocals[b], polynomial, p),
          )
        }
      }
    }
  }
}

///|
test "extension construction validates certificates and does not make proofs field identities" {
  let polynomial = test_polynomial(2, [1, 1, 1])
  let certificate = test_certificate(polynomial)
  let field = test_field(2, [1, 1, 1])
  let powers = @oracle.array(certificate.frobenius)
  let witness = @oracle.array(certificate.coprime)[0]
  let difference = poly_required(
    @fppoly.subtract(powers[0], @fppoly.indeterminate(test_prime(2))),
  )
  let alternative = {
    ..certificate,
    coprime: @core.Cons(
      {
        ..witness,
        left: poly_required(@fppoly.add(witness.left, difference)),
        right: poly_required(@fppoly.subtract(witness.right, polynomial)),
      },
      Nil,
    ),
  }
  assert_true(@fppoly.check_irreducible(polynomial, alternative))
  assert_eq(extension(polynomial, alternative), Some(field))
  assert_eq(
    extension(polynomial, { ..certificate, frobenius: @core.Nil, }),
    None,
  )
  assert_eq(extension(test_polynomial(2, []), certificate), None)
  assert_eq(extension(test_polynomial(2, [1]), certificate), None)
  assert_eq(extension(test_polynomial(2, [1, 0, 1]), certificate), None)
  let odd = test_polynomial(3, [1, 0, 1])
  assert_eq(
    extension(@fppoly.scale(odd, @oracle.binary(2)), test_certificate(odd)),
    None,
  )
  assert_eq(
    element(field, test_polynomial(3, [1])),
    Err(PolynomialError(@fppoly.FieldMismatch)),
  )
}

///|
test "field presentations remain separate and algebra generators need not be primitive" {
  let a = test_field(2, [1, 1, 0, 1])
  let b = test_field(2, [1, 0, 1, 1])
  assert_eq(cardinality(a), cardinality(b))
  assert_false(a.equal(b))
  assert_true(a.not_equal(b))
  assert_eq(add(one(a), one(b)), Err(FieldMismatch))
  assert_eq(subtract(one(a), one(b)), Err(FieldMismatch))
  assert_eq(multiply(zero(a), zero(b)), Err(FieldMismatch))
  assert_eq(divide(one(a), zero(b)), Err(FieldMismatch))
  let nine = test_field(3, [1, 0, 1])
  let root = required(generator(nine))
  assert_eq(required(power(root, @oracle.binary(2))), negate(one(nine)))
  assert_eq(required(power(root, @oracle.binary(4))), one(nine))
  assert_eq(cardinality(nine), @oracle.binary(9))
  assert_eq(field_of(root), nine)
  assert_eq(required(element(nine, modulus(nine))), zero(nine))
  assert_eq(constant(nine, @oracle.binary(12)), zero(nine))
}

///|
test "degree-one extensions reduce to prime fields including the zero algebra generator" {
  for (p, polynomial, root) in [(2, [0, 1], 0), (3, [1, 1], 2), (5, [2, 1], 3)] {
    let field = test_field(p, polynomial)
    assert_eq(required(generator(field)), constant(field, @oracle.binary(root)))
    assert_eq(cardinality(field), @oracle.binary(p))
    for value in 0..<p {
      let value = constant(field, @oracle.binary(value))
      assert_eq(trace(value), norm(value))
      assert_eq(required(frobenius(value)), value)
    }
  }
}
