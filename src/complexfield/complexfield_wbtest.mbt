///|
fn cf_rational(n : Int32, d : Int32) -> @exact.Rational {
  @exact.ratio(@oracle.integer(n), @oracle.binary(d)).unwrap()
}

///|
fn cf_poly(coefficients : Array[(Int32, Int32)]) -> @poly.Polynomial {
  @poly.polynomial(
    @oracle.nat(1),
    @oracle.chain(
      [
        for i, c in coefficients => {
          @poly.Term::{
            coefficient: cf_rational(c.0, c.1),
            exponents: @oracle.chain([@oracle.nat(i)]),
          }
        }
      ],
    ),
  ).unwrap()
}

///|
fn cf_integer_poly(coefficients : Array[Int32]) -> @poly.Polynomial {
  cf_poly(coefficients.map(fn(c) { (c, 1) }))
}

///|
fn cf_real_field(
  coefficients : Array[Int32],
  lower : (Int32, Int32),
  upper : (Int32, Int32),
) -> @nf.Field {
  let root = @real.number({
    polynomial: cf_integer_poly(coefficients),
    interval: {
      lower: cf_rational(lower.0, lower.1),
      upper: cf_rational(upper.0, upper.1),
    },
  }).unwrap()
  match
    @minimal.normalize(
      root,
      @oracle.chain([2, 3, 5, 7, 11, 13].map(@oracle.binary)),
      @oracle.nat(40),
      @oracle.nat(256),
      @oracle.nat(256),
    ).unwrap() {
    @minimal.Normalized(value, proof) =>
      @nf.field_result(value, proof, @oracle.nat(256)).unwrap()
    _ => abort("complex field test normalization unresolved")
  }
}

///|
fn cf_sqrt2() -> Field {
  field(cf_real_field([-2, 0, 1], (1, 1), (2, 1)))
}

///|
fn cf_alpha(f : Field) -> Element {
  element(f, @nf.generator(real_field(f)).unwrap(), @nf.one(real_field(f))).unwrap()
}

///|
test "Q(i) is a checked two dimensional field" {
  let k = cf_real_field([0, 1], (-1, 1), (0, 1))
  let f = field(k)
  assert_true(@nf.same_field(k, real_field(f)))
  assert_true(same_field(f, field(k)))
  assert_eq(degree(f), @oracle.nat(2))
  let i = imaginary_unit(f)
  assert_true(same_field(parent(i), f))
  assert_true(@nf.is_zero(real_part(i)))
  assert_true(@nf.equal(imaginary_part(i), @nf.one(k)))
  assert_true(equal(multiply(i, i).unwrap(), negate(one(f))))
  assert_true(equal(conjugate(i), negate(i)))
  assert_true(equal(inverse(i).unwrap().unwrap(), negate(i)))
  assert_true(equal(add(i, negate(i)).unwrap(), zero(f)))
  assert_true(equal(divide(i, i).unwrap().unwrap(), one(f)))
  assert_true(inverse(zero(f)).unwrap() is None)
  assert_true(divide(i, zero(f)).unwrap() is None)
  assert_eq(minimal_polynomial(i).unwrap(), cf_integer_poly([1, 0, 1]))
  assert_eq(trace(i).unwrap(), cf_rational(0, 1))
  assert_eq(norm(i).unwrap(), cf_rational(1, 1))
  let r = rational(f, cf_rational(-7, 3))
  assert_true(@nf.equal(real_part(r), @nf.rational(k, cf_rational(-7, 3))))
  assert_true(@nf.is_zero(imaginary_part(r)))
  assert_eq(minimal_polynomial(r).unwrap(), cf_poly([(7, 3), (1, 1)]))
  assert_eq(minimal_polynomial(zero(f)).unwrap(), cf_integer_poly([0, 1]))
}

///|
test "sqrt2 plus i has degree four and exact field invariants" {
  let f = cf_sqrt2()
  let k = real_field(f)
  let alpha = cf_alpha(f)
  let minimum = cf_integer_poly([9, 0, -2, 0, 1])
  assert_eq(degree(f), @oracle.nat(4))
  assert_eq(minimal_polynomial(alpha).unwrap(), minimum)
  assert_true(check_minimal_polynomial(alpha, minimum))
  assert_eq(trace(alpha).unwrap(), cf_rational(0, 1))
  assert_eq(norm(alpha).unwrap(), cf_rational(9, 1))
  assert_true(check_trace(alpha, cf_rational(0, 1)))
  assert_true(check_norm(alpha, cf_rational(9, 1)))
  assert_true(
    @nf.equal(
      relative_trace(alpha).unwrap(),
      @nf.add(@nf.generator(k).unwrap(), @nf.generator(k).unwrap()).unwrap(),
    ),
  )
  assert_true(
    @nf.equal(relative_norm(alpha).unwrap(), @nf.rational(k, cf_rational(3, 1))),
  )
  assert_true(
    equal(
      multiply(alpha, conjugate(alpha)).unwrap(),
      rational(f, cf_rational(3, 1)),
    ),
  )
  let inverted = inverse_with_certificate(alpha).unwrap().unwrap()
  assert_true(check_inverse_result(alpha, inverted.value, inverted.certificate))
  assert_eq(
    @nf.representative(real_part(inverted.value)),
    cf_poly([(0, 1), (1, 3)]),
  )
  assert_eq(
    @nf.representative(imaginary_part(inverted.value)),
    cf_poly([(-1, 3)]),
  )
  assert_true(equal(inverse(inverted.value).unwrap().unwrap(), alpha))
  let expected = [[0, 2, -1, 0], [1, 0, 0, -1], [1, 0, 0, 2], [0, 1, 1, 0]]
  assert_eq(
    @matrix.rows(multiplication_matrix(alpha).unwrap()),
    @oracle.chain(
      expected.map(fn(row) {
        @oracle.chain(row.map(fn(c) { cf_rational(c, 1) }))
      }),
    ),
  )
  let square = multiply(alpha, alpha).unwrap()
  assert_eq(@nf.representative(real_part(square)), cf_integer_poly([1]))
  assert_eq(@nf.representative(imaginary_part(square)), cf_integer_poly([0, 2]))
}

///|
test "ambient field trace differs from the trace of an element minimum" {
  let k = cf_real_field([-3, 0, 1], (1, 1), (2, 1))
  let f = field(k)
  let half = @nf.rational(k, cf_rational(1, 2))
  let zeta = element(
    f,
    @nf.negate(half),
    @nf.multiply(@nf.generator(k).unwrap(), half).unwrap(),
  ).unwrap()
  assert_eq(degree(f), @oracle.nat(4))
  assert_eq(minimal_polynomial(zeta).unwrap(), cf_integer_poly([1, 1, 1]))
  assert_eq(trace(zeta).unwrap(), cf_rational(-2, 1))
  assert_eq(norm(zeta).unwrap(), cf_rational(1, 1))
  assert_true(check_trace(zeta, cf_rational(-2, 1)))
  assert_true(check_norm(zeta, cf_rational(1, 1)))
  assert_false(check_trace(zeta, cf_rational(-1, 1)))
  assert_false(check_norm(zeta, cf_rational(-1, 1)))
  assert_true(
    equal(multiply(multiply(zeta, zeta).unwrap(), zeta).unwrap(), one(f)),
  )
  assert_eq(minimal_polynomial(one(f)).unwrap(), cf_integer_poly([-1, 1]))
  assert_eq(trace(one(f)).unwrap(), cf_rational(4, 1))
  assert_eq(norm(one(f)).unwrap(), cf_rational(1, 1))
  let a = element(f, @nf.generator(k).unwrap(), @nf.zero(k)).unwrap()
  assert_eq(minimal_polynomial(a).unwrap(), cf_integer_poly([-3, 0, 1]))
  assert_eq(norm(a).unwrap(), cf_rational(9, 1))
}

///|
test "different real conjugates and refined contexts reject all mixing" {
  let f = cf_sqrt2()
  let a = cf_alpha(f)
  let candidates = [
    cf_real_field([-2, 0, 1], (-2, 1), (-1, 1)),
    cf_real_field([-2, 0, 1], (7, 5), (3, 2)),
    cf_real_field([-3, 0, 1], (1, 1), (2, 1)),
  ]
  for k in candidates {
    let g = field(k)
    let b = imaginary_unit(g)
    assert_false(same_field(f, g))
    assert_false(equal(a, b))
    assert_true(
      element(f, @nf.zero(k), @nf.zero(real_field(f))) is Err(DifferentField),
    )
    assert_true(
      element(f, @nf.zero(real_field(f)), @nf.zero(k)) is Err(DifferentField),
    )
    assert_true(add(a, b) is Err(DifferentField))
    assert_true(subtract(a, b) is Err(DifferentField))
    assert_true(multiply(a, b) is Err(DifferentField))
    assert_true(divide(a, zero(g)) is Err(DifferentField))
  }
}

///|
test "inverse checker rejects forged source result context and Bezout payload" {
  let f = cf_sqrt2()
  let a = cf_alpha(f)
  let inverse = inverse_with_certificate(a).unwrap().unwrap()
  let p = inverse.certificate
  assert_true(check_inverse_result(a, inverse.value, p))
  assert_false(check_inverse_result(one(f), inverse.value, p))
  assert_false(check_inverse_result(a, one(f), p))
  assert_false(check_inverse_result(a, inverse.value, { ..p, input: one(f), }))
  assert_false(check_inverse_result(a, inverse.value, { ..p, value: one(f), }))
  assert_false(
    check_inverse_result(a, inverse.value, {
      ..p,
      denominator_inverse: @nf.one(real_field(f)),
    }),
  )
  assert_false(
    check_inverse_result(a, inverse.value, {
      ..p,
      denominator_certificate: {
        ..p.denominator_certificate,
        cofactor: cf_integer_poly([42]),
      },
    }),
  )
  assert_false(
    check_inverse_result(a, inverse.value, {
      ..p,
      denominator_certificate: {
        ..p.denominator_certificate,
        input: cf_integer_poly([1]),
      },
    }),
  )
  let g = field(cf_real_field([-2, 0, 1], (-2, 1), (-1, 1)))
  let other = cf_alpha(g)
  let other_inverse = inverse_with_certificate(other).unwrap().unwrap()
  assert_false(
    check_inverse_result(a, inverse.value, other_inverse.certificate),
  )
  assert_false(check_inverse_result(a, other_inverse.value, p))
  assert_false(
    check_inverse_result(a, inverse.value, {
      ..p,
      denominator_certificate: {
        ..p.denominator_certificate,
        context: @nf.embedding(real_field(g)),
      },
    }),
  )
}

///|
test "minimality checker rejects annihilating padded and forged polynomials" {
  let f = cf_sqrt2()
  let k = real_field(f)
  let a = element(f, @nf.generator(k).unwrap(), @nf.zero(k)).unwrap()
  let minimum = cf_integer_poly([-2, 0, 1])
  assert_true(check_minimal_polynomial(a, minimum))
  // Degree three remains below ambient dimension four: rank, not the bound,
  // must reject this true annihilator (t^2-2)(t-1).
  let padded = @poly.multiply(minimum, cf_integer_poly([-1, 1])).unwrap()
  assert_true(is_zero(evaluate_polynomial(a, padded).unwrap()))
  assert_false(check_minimal_polynomial(a, padded))
  let excessive = @poly.multiply(minimum, cf_integer_poly([0, 0, 0, 0, 1])).unwrap()
  assert_false(check_minimal_polynomial(a, excessive))
  assert_false(check_minimal_polynomial(a, cf_integer_poly([-4, 0, 2])))
  assert_false(check_minimal_polynomial(a, cf_integer_poly([-3, 0, 1])))
  assert_false(check_minimal_polynomial(a, cf_integer_poly([1])))
  assert_false(check_minimal_polynomial(a, cf_integer_poly([])))
  assert_false(check_minimal_polynomial(a, @poly.zero(@oracle.nat(2))))
  assert_false(check_minimal_polynomial(cf_alpha(f), minimum))
}

///|
test "checkers reject internally forged inconsistent element contexts" {
  let f = cf_sqrt2()
  let k = cf_real_field([-3, 0, 1], (1, 1), (2, 1))
  let a = cf_alpha(f)
  let forged : Element = { ..a, imaginary: @nf.zero(k), }
  assert_false(equal(forged, forged))
  assert_true(add(a, forged) is Err(DifferentField))
  assert_true(inverse(forged) is Err(DifferentField))
  assert_true(minimal_polynomial(forged) is Err(DifferentField))
  assert_true(
    equal(
      evaluate_polynomial(forged, @poly.zero(@oracle.nat(1))).unwrap(),
      zero(f),
    ),
  )
  assert_true(evaluate_polynomial(forged, cf_integer_poly([1])) is None)
  assert_false(check_minimal_polynomial(forged, cf_integer_poly([-2, 0, 1])))
  assert_false(check_trace(forged, cf_rational(0, 1)))
  assert_false(check_norm(forged, cf_rational(4, 1)))
  let result = inverse_with_certificate(a).unwrap().unwrap()
  assert_false(check_inverse_result(forged, result.value, result.certificate))
}
