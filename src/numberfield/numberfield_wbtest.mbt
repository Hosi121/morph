///|
fn test_binary64(n : Int64) -> @binary.Binary {
  fn bits(n : Int64) -> @core.Chain[Bool] {
    if n == 0 {
      Nil
    } else {
      Cons(n % 2 == 1, bits(n / 2))
    }
  }
  if n < 0 {
    abort("negative fixture magnitude")
  }
  @binary.from_bits(bits(n))
}

///|
fn test_rational(n : Int64, d : Int64) -> @exact.Rational {
  let numerator = @exact.positive(test_binary64(if n < 0 { -n } else { n }))
  @exact.ratio(
    if n < 0 {
      @exact.negate(numerator)
    } else {
      numerator
    },
    test_binary64(d),
  ).unwrap()
}

///|
fn test_poly(values : Array[(Int64, Int64)]) -> @poly.Polynomial {
  @poly.polynomial(
    @oracle.nat(1),
    @oracle.chain(
      [
        for i in 0..<values.length() => {
          @poly.Term::{
            coefficient: test_rational(values[i].0, values[i].1),
            exponents: @oracle.chain([@oracle.nat(i)]),
          }
        }
      ],
    ),
  ).unwrap()
}

///|
fn test_integer_poly(values : Array[Int32]) -> @poly.Polynomial {
  test_poly(values.map(fn(c) { (c.to_int64(), 1) }))
}

///|
fn test_normalized(
  values : Array[(Int64, Int64)],
  lower : (Int64, Int64),
  upper : (Int64, Int64),
) -> (@real.Number, @minimal.Certificate) {
  let input = @real.number({
    polynomial: test_poly(values),
    interval: {
      lower: test_rational(lower.0, lower.1),
      upper: test_rational(upper.0, upper.1),
    },
  }).unwrap()
  match
    @minimal.normalize(
      input,
      @oracle.chain([2, 3, 5, 7, 11, 13].map(@oracle.binary)),
      @oracle.nat(40),
      @oracle.nat(256),
      @oracle.nat(256),
    ).unwrap() {
    @minimal.Normalized(value, proof) => (value, proof)
    _ => abort("normalization fixture unresolved")
  }
}

///|
fn test_field(
  values : Array[(Int64, Int64)],
  lower : (Int64, Int64),
  upper : (Int64, Int64),
) -> Field {
  let (value, proof) = test_normalized(values, lower, upper)
  field_result(value, proof, @oracle.nat(256)).unwrap()
}

///|
fn test_sqrt2() -> Field {
  test_field([(-2, 1), (0, 1), (1, 1)], (1, 1), (2, 1))
}

///|
test "checked quotient square root arithmetic and exact Euclid certificate" {
  let f = test_sqrt2()
  assert_eq(degree(f), @oracle.nat(2))
  let a = generator(f).unwrap()
  assert_true(equal(multiply(a, a).unwrap(), rational(f, test_rational(2, 1))))
  assert_true(equal(add(a, negate(a)).unwrap(), zero(f)))
  assert_true(
    equal(
      element(f, test_integer_poly([0, 0, 1])).unwrap(),
      rational(f, test_rational(2, 1)),
    ),
  )
  let inv = inverse_with_certificate(a).unwrap().unwrap()
  assert_true(check_inverse_result(a, inv.value, inv.certificate))
  assert_eq(representative(inv.value), test_poly([(0, 1), (1, 2)]))
  assert_true(equal(multiply(a, inv.value).unwrap(), one(f)))
  assert_eq(trace(a).unwrap(), test_rational(0, 1))
  assert_eq(norm(a).unwrap(), test_rational(-2, 1))
  assert_true(inverse(zero(f)).unwrap() is None)
  assert_true(divide(one(f), zero(f)).unwrap() is None)
}

///|
test "field constructors bind irreducibility selected embedding and Number payload" {
  let (number, proof) = test_normalized(
    [(-2, 1), (0, 1), (1, 1)],
    (1, 1),
    (2, 1),
  )
  assert_true(field_result(number, proof, @oracle.nat(256)) is Ok(_))
  let other = @real.number({
    polynomial: proof.result.polynomial,
    interval: { lower: test_rational(-2, 1), upper: test_rational(-1, 1), },
  }).unwrap()
  assert_true(field_result(other, proof, @oracle.nat(256)) is Err(_))
  let fake = @minimal.Certificate::{
    ..proof,
    result: @real.root_certificate(other),
  }
  assert_true(field(fake, @oracle.nat(256)) is Err(_))
  let rational_other = @real.rational(test_rational(3, 1)).unwrap()
  assert_true(field_result(rational_other, proof, @oracle.nat(256)) is Err(_))
  assert_true(
    field({ ..proof, selected: @oracle.nat(42), }, @oracle.nat(256)) is Err(_),
  )
  assert_true(
    field(
      {
        ..proof,
        result: { ..proof.result, polynomial: test_integer_poly([-4, 0, 1]), },
      },
      @oracle.nat(256),
    )
    is Err(_),
  )
  assert_true(field(proof, @oracle.nat(0)) is Err(_))
}

///|
test "separate fields conjugates and refined embeddings cannot mix" {
  let f = test_sqrt2()
  let same = field(certificate(f), @oracle.nat(256)).unwrap()
  assert_true(same_field(f, same))
  assert_true(equal(generator(f).unwrap(), generator(same).unwrap()))
  let other = test_field([(-2, 1), (0, 1), (1, 1)], (-2, 1), (-1, 1))
  let different = test_field([(-3, 1), (0, 1), (1, 1)], (1, 1), (2, 1))
  let refined = test_field([(-2, 1), (0, 1), (1, 1)], (7, 5), (3, 2))
  for g in [other, different, refined] {
    assert_false(same_field(f, g))
    let a = generator(f).unwrap()
    let b = generator(g).unwrap()
    assert_false(equal(a, b))
    match add(a, b) {
      Err(DifferentField) => ()
      _ => fail("mixed add")
    }
    match subtract(a, b) {
      Err(DifferentField) => ()
      _ => fail("mixed subtract")
    }
    match multiply(a, b) {
      Err(DifferentField) => ()
      _ => fail("mixed multiply")
    }
    match divide(a, zero(g)) {
      Err(DifferentField) => ()
      _ => fail("mixed divide")
    }
  }
  assert_true(element(f, @poly.zero(@oracle.nat(2))) is Err(_))
}

///|
test "inverse checker rejects forged Bezout input inverse context and payload" {
  let f = test_sqrt2()
  let a = add(generator(f).unwrap(), one(f)).unwrap()
  let result = inverse_with_certificate(a).unwrap().unwrap()
  let p = result.certificate
  assert_true(check_inverse_result(a, result.value, p))
  assert_false(check_inverse_result(a, one(f), p))
  assert_false(check_inverse_result(one(f), result.value, p))
  assert_false(
    check_inverse_result(a, result.value, {
      ..p,
      inverse: representative(one(f)),
    }),
  )
  assert_false(
    check_inverse_result(a, result.value, {
      ..p,
      input: representative(one(f)),
    }),
  )
  assert_false(
    check_inverse_result(a, result.value, {
      ..p,
      cofactor: test_integer_poly([42]),
    }),
  )
  let g = test_field([(-2, 1), (0, 1), (1, 1)], (-2, 1), (-1, 1))
  assert_false(
    check_inverse_result(a, result.value, { ..p, context: embedding(g), }),
  )
  assert_false(check_inverse_result(a, element(g, p.inverse).unwrap(), p))
  let fake_modulus_multiple = @poly.add(p.inverse, modulus(f)).unwrap()
  assert_false(
    check_inverse_result(a, result.value, {
      ..p,
      inverse: fake_modulus_multiple,
    }),
  )
}

///|
test "rational and zero generators yield degree one fields" {
  let cases : Array[(Int64, Int64)] = [(0, 1), (2, 1), (-7, 3)]
  for (n, d) in cases {
    let f = test_field([(-n, d), (1, 1)], (n - d, d), (n, d))
    let a = generator(f).unwrap()
    assert_eq(degree(f), @oracle.nat(1))
    assert_true(equal(a, rational(f, test_rational(n, d))))
    assert_eq(trace(a).unwrap(), test_rational(n, d))
    assert_eq(norm(a).unwrap(), test_rational(n, d))
    assert_eq(
      @oracle.array(@matrix.rows(multiplication_matrix(a).unwrap())).length(),
      1,
    )
  }
}

///|
fn assert_field_fixture(
  m : Array[(Int64, Int64)],
  lower : (Int64, Int64),
  upper : (Int64, Int64),
  aa : Array[(Int64, Int64)],
  bb : Array[(Int64, Int64)],
  cc : Array[(Int64, Int64)],
  residue : Array[(Int64, Int64)],
  sum : Array[(Int64, Int64)],
  difference : Array[(Int64, Int64)],
  product : Array[(Int64, Int64)],
  inverted : Array[(Int64, Int64)]?,
  expected_trace : (Int64, Int64),
  expected_norm : (Int64, Int64),
  expected_matrix : Array[Array[(Int64, Int64)]],
) -> Unit raise {
  let f = test_field(m, lower, upper)
  let a = element(f, test_poly(aa)).unwrap()
  let b = element(f, test_poly(bb)).unwrap()
  let c = element(f, test_poly(cc)).unwrap()
  assert_eq(representative(a), test_poly(residue))
  assert_eq(representative(add(a, b).unwrap()), test_poly(sum))
  assert_eq(representative(subtract(a, b).unwrap()), test_poly(difference))
  assert_eq(representative(multiply(a, b).unwrap()), test_poly(product))
  assert_eq(
    trace(a).unwrap(),
    test_rational(expected_trace.0, expected_trace.1),
  )
  assert_eq(norm(a).unwrap(), test_rational(expected_norm.0, expected_norm.1))
  assert_eq(
    @matrix.rows(multiplication_matrix(a).unwrap()),
    @oracle.chain(
      expected_matrix.map(fn(row) {
        @oracle.chain(row.map(fn(c) { test_rational(c.0, c.1) }))
      }),
    ),
  )
  assert_true(equal(add(a, b).unwrap(), add(b, a).unwrap()))
  assert_true(equal(multiply(a, b).unwrap(), multiply(b, a).unwrap()))
  assert_true(
    equal(
      add(add(a, b).unwrap(), c).unwrap(),
      add(a, add(b, c).unwrap()).unwrap(),
    ),
  )
  assert_true(
    equal(
      multiply(multiply(a, b).unwrap(), c).unwrap(),
      multiply(a, multiply(b, c).unwrap()).unwrap(),
    ),
  )
  assert_true(
    equal(
      multiply(a, add(b, c).unwrap()).unwrap(),
      add(multiply(a, b).unwrap(), multiply(a, c).unwrap()).unwrap(),
    ),
  )
  assert_true(equal(multiply(a, one(f)).unwrap(), a))
  assert_true(equal(add(a, zero(f)).unwrap(), a))
  assert_true(equal(add(a, negate(a)).unwrap(), zero(f)))
  assert_eq(
    trace(add(a, b).unwrap()).unwrap(),
    @exact.rational_add(trace(a).unwrap(), trace(b).unwrap()),
  )
  assert_eq(
    norm(multiply(a, b).unwrap()).unwrap(),
    @exact.rational_multiply(norm(a).unwrap(), norm(b).unwrap()),
  )
  match (inverted, inverse_with_certificate(a).unwrap()) {
    (None, None) => assert_true(is_zero(a))
    (Some(expected), Some(result)) => {
      assert_eq(representative(result.value), test_poly(expected))
      assert_true(check_inverse_result(a, result.value, result.certificate))
      assert_true(equal(multiply(a, result.value).unwrap(), one(f)))
      assert_true(equal(inverse(result.value).unwrap().unwrap(), a))
      assert_true(equal(divide(a, a).unwrap().unwrap(), one(f)))
    }
    _ => fail("inverse oracle disagreement")
  }
}

///|
test "product identity alone cannot construct a field with reducible modulus" {
  let full = [-2, 0, -1, 0, 1] // (t^2-2)(t^2+1)
  let (_, actual) = test_normalized(
    full.map(fn(c) { (c.to_int64(), 1) }),
    (1, 1),
    (2, 1),
  )
  let factor = @core.nth(actual.factorization.factors, actual.selected).unwrap()
  let forged_factor : @zass.Factor = {
    polynomial: @zass.polynomial(@oracle.chain(full.map(@oracle.integer))),
    multiplicity: Succ(Zero),
    certificate: factor.certificate,
  }
  assert_true(
    @zass.check_product(forged_factor.polynomial, {
      content: @oracle.integer(1),
      factors: Cons(forged_factor, Nil),
    }),
  )
  let result = @real.RootCertificate::{
    polynomial: test_integer_poly(full),
    interval: actual.result.interval,
  }
  let forged = @minimal.Certificate::{
    ..actual,
    factorization: {
      unit: test_rational(1, 1),
      factors: Cons(forged_factor, Nil),
    },
    selected: Zero,
    result,
  }
  assert_true(@real.check_root(result))
  match field(forged, @oracle.nat(256)) {
    Err(InvalidCertificate) => ()
    _ => fail("reducible quotient accepted as a field")
  }
}
