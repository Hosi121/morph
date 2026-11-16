///|
fn cp_poly(coefficients : Array[(Int32, Int32)]) -> @poly.Polynomial {
  @poly.polynomial(
    @oracle.nat(1),
    @oracle.chain(
      [
        for i, c in coefficients => {
          @poly.Term::{
            coefficient: @oracle.rational(c.0, c.1),
            exponents: Cons(@oracle.nat(i), Nil),
          }
        }
      ],
    ),
  ).unwrap()
}

///|
fn cp_integer_poly(coefficients : Array[Int32]) -> @poly.Polynomial {
  cp_poly(coefficients.map(fn(c) { (c, 1) }))
}

///|
fn cp_context(
  coefficients : Array[Int32],
  lower : (Int32, Int32),
  upper : (Int32, Int32),
) -> @cf.Field {
  let root = @real.number({
    polynomial: cp_integer_poly(coefficients),
    interval: {
      lower: @oracle.rational(lower.0, lower.1),
      upper: @oracle.rational(upper.0, upper.1),
    },
  }).unwrap()
  match
    @minimal.normalize(
      root,
      @oracle.chain([2, 3, 5, 7, 11, 13].map(@oracle.binary)),
      @oracle.nat(100),
      @oracle.nat(500),
      @oracle.nat(500),
    ).unwrap() {
    @minimal.Normalized(value, proof) =>
      @cf.field(@nf.field_result(value, proof, @oracle.nat(500)).unwrap())
    _ => abort("primitive test needs a verified real generator")
  }
}

///|
fn cp_sqrt2() -> @cf.Field {
  cp_context([-2, 0, 1], (1, 1), (2, 1))
}

///|
fn cp_element(
  field : @cf.Field,
  real : Array[(Int32, Int32)],
  imaginary : Array[(Int32, Int32)],
) -> @cf.Element {
  let k = @cf.real_field(field)
  @cf.element(
    field,
    @nf.element(k, cp_poly(real)).unwrap(),
    @nf.element(k, cp_poly(imaginary)).unwrap(),
  ).unwrap()
}

///|
fn cp_roundtrip(rep : Representation, value : @cf.Element) -> Unit raise {
  let result = to_polynomial(rep, value).unwrap()
  assert_true(
    check_conversion_for(rep, value, result.polynomial, result.certificate),
  )
  assert_true(
    @cf.equal(from_polynomial(rep, result.polynomial).unwrap(), value),
  )
  assert_eq(
    to_polynomial(rep, from_polynomial(rep, result.polynomial).unwrap()).unwrap().polynomial,
    result.polynomial,
  )
}

///|
fn cp_product(
  rep : Representation,
  a : @cf.Element,
  b : @cf.Element,
) -> Unit raise {
  let pa = to_polynomial(rep, a).unwrap().polynomial
  let pb = to_polynomial(rep, b).unwrap().polynomial
  let ab = @cf.multiply(a, b).unwrap()
  let polynomial_product = @poly.multiply(pa, pb).unwrap()
  assert_true(@cf.equal(from_polynomial(rep, polynomial_product).unwrap(), ab))
  assert_eq(
    to_polynomial(rep, ab).unwrap().polynomial,
    @poly.normal_form(polynomial_product, Cons(modulus(rep), Nil)).unwrap(),
  )
}

///|
test "QQ(i) and shifted rational primitive generators have absolute degree two" {
  let f = cp_context([0, 1], (-1, 1), (0, 1))
  let rep = prepare(f).unwrap()
  let proof = certificate(rep)
  assert_true(@cf.same_field(source(rep), f))
  assert_eq(degree(rep), @oracle.nat(2))
  assert_true(@cf.equal(generator(rep), @cf.imaginary_unit(f)))
  assert_eq(modulus(rep), cp_integer_poly([1, 0, 1]))
  assert_eq(real_generator_image(rep), cp_integer_poly([]))
  assert_eq(imaginary_unit_image(rep), cp_integer_poly([0, 1]))
  assert_eq(
    basis_matrix(rep),
    @matrix.identity(@oracle.nat(2), @algebra.rationals()),
  )
  assert_eq(inverse_basis_matrix(rep), basis_matrix(rep))
  assert_true(check(f, proof))
  assert_true(check_result(f, from_certificate(f, proof).unwrap(), proof))
  cp_roundtrip(rep, @cf.zero(f))
  cp_roundtrip(rep, @cf.one(f))
  cp_roundtrip(rep, @cf.imaginary_unit(f))
  cp_roundtrip(rep, cp_element(f, [(3, 2)], [(-5, 7)]))
  let shifted = cp_context([-3, 1], (2, 1), (4, 1))
  let other = prepare(shifted).unwrap()
  assert_eq(modulus(other), cp_integer_poly([10, -6, 1]))
  assert_eq(real_generator_image(other), cp_integer_poly([3]))
  assert_eq(imaginary_unit_image(other), cp_integer_poly([-3, 1]))
  assert_true(check(shifted, certificate(other)))
}

///|
test "sqrt2 plus i has explicit rational generator maps and canonical arithmetic" {
  let f = cp_sqrt2()
  let rep = prepare(f).unwrap()
  let theta = generator(rep)
  assert_eq(degree(rep), @oracle.nat(4))
  assert_eq(modulus(rep), cp_integer_poly([9, 0, -2, 0, 1]))
  assert_eq(
    real_generator_image(rep),
    cp_poly([(0, 1), (5, 6), (0, 1), (-1, 6)]),
  )
  assert_eq(
    imaginary_unit_image(rep),
    cp_poly([(0, 1), (1, 6), (0, 1), (1, 6)]),
  )
  assert_true(
    @cf.equal(
      from_polynomial(rep, real_generator_image(rep)).unwrap(),
      real_generator(f).unwrap(),
    ),
  )
  assert_true(
    @cf.equal(
      from_polynomial(rep, imaginary_unit_image(rep)).unwrap(),
      @cf.imaginary_unit(f),
    ),
  )
  assert_eq(
    to_polynomial(rep, theta).unwrap().polynomial,
    cp_integer_poly([0, 1]),
  )
  let a = cp_element(f, [(2, 3), (-5, 7)], [(11, 13), (1, 2)])
  let inverse = @cf.inverse(a).unwrap().unwrap()
  cp_roundtrip(rep, a)
  cp_roundtrip(rep, inverse)
  cp_roundtrip(rep, @cf.conjugate(theta))
  cp_product(rep, a, inverse)
  cp_product(rep, a, theta)
  cp_product(rep, @cf.zero(f), a)
  // High-degree input is reduced, but its noncanonical shape is never returned.
  let high = @poly.add(
    @poly.multiply(modulus(rep), cp_integer_poly([7, -2, 0, 0, 0, 0, 1])).unwrap(),
    cp_integer_poly([3, -4, 2]),
  ).unwrap()
  let value = from_polynomial(rep, high).unwrap()
  assert_eq(
    to_polynomial(rep, value).unwrap().polynomial,
    cp_integer_poly([3, -4, 2]),
  )
  assert_true(@cf.is_zero(from_polynomial(rep, modulus(rep)).unwrap()))
  assert_true(
    from_polynomial(rep, @poly.zero(@oracle.nat(2))) is Err(NotUnivariate),
  )
  assert_true(from_polynomial(rep, @poly.zero(Zero)) is Err(NotUnivariate))
}

///|
test "independent SymPy degree six and eight primitives and coordinate maps" {
  // SymPy exact quotient basis inversion for (a+i)^j, a^d=2, independently
  // gives these coefficients. Full external fixture inventory belongs to root.
  let cubic = prepare(cp_context([-2, 0, 0, 1], (1, 1), (2, 1))).unwrap()
  assert_eq(degree(cubic), @oracle.nat(6))
  assert_eq(modulus(cubic), cp_integer_poly([5, 12, 3, -4, 3, 0, 1]))
  assert_eq(
    real_generator_image(cubic),
    cp_poly([(91, 22), (100, 22), (-78, 22), (40, 22), (-9, 22), (12, 22)]),
  )
  assert_eq(
    imaginary_unit_image(cubic),
    cp_poly([(-91, 22), (-78, 22), (78, 22), (-40, 22), (9, 22), (-12, 22)]),
  )
  let quartic = prepare(cp_context([-2, 0, 0, 0, 1], (1, 1), (2, 1))).unwrap()
  assert_eq(degree(quartic), @oracle.nat(8))
  assert_eq(modulus(quartic), cp_integer_poly([1, 0, 28, 0, 2, 0, 4, 0, 1]))
  assert_eq(
    real_generator_image(quartic),
    cp_poly([
      (0, 1),
      (151, 24),
      (0, 1),
      (5, 24),
      (0, 1),
      (19, 24),
      (0, 1),
      (5, 24),
    ]),
  )
  assert_eq(
    imaginary_unit_image(quartic),
    cp_poly([
      (0, 1),
      (-127, 24),
      (0, 1),
      (-5, 24),
      (0, 1),
      (-19, 24),
      (0, 1),
      (-5, 24),
    ]),
  )
  for rep in [cubic, quartic] {
    let f = source(rep)
    assert_true(check(f, certificate(rep)))
    let a = cp_element(f, [(1, 1), (2, 3), (-1, 5)], [(0, 1), (3, 7)])
    let inverse = @cf.inverse(a).unwrap().unwrap()
    cp_roundtrip(rep, a)
    cp_roundtrip(rep, inverse)
    cp_product(rep, a, generator(rep))
    cp_product(rep, a, inverse)
    assert_eq(
      to_polynomial(rep, @cf.multiply(a, inverse).unwrap()).unwrap().polynomial,
      cp_integer_poly([1]),
    )
  }
}

///|
test "representation checker rejects wrong theta matrices minimum and images" {
  let f = cp_sqrt2()
  let rep = prepare(f).unwrap()
  let p = certificate(rep)
  let identity = @matrix.identity(degree(rep), @algebra.rationals())
  let small = @matrix.identity(@oracle.nat(1), @algebra.rationals())
  let wrong_modulus = cp_integer_poly([1, 0, 1])
  for
    forged in [
      { ..p, theta: @cf.one(f), },
      { ..p, theta: @cf.conjugate(p.theta), },
      { ..p, theta: @cf.negate(p.theta), },
      { ..p, basis: identity, },
      { ..p, basis: @matrix.transpose(p.basis), },
      { ..p, basis: p.inverse_basis, },
      { ..p, basis: small, },
      { ..p, inverse_basis: identity, },
      { ..p, inverse_basis: @matrix.transpose(p.inverse_basis), },
      { ..p, inverse_basis: small, },
      { ..p, modulus: wrong_modulus, },
      {
        ..p,
        modulus: @poly.multiply(p.modulus, cp_integer_poly([0, 1])).unwrap(),
      },
      {
        ..p,
        modulus: @poly.multiply(p.modulus, cp_integer_poly([2])).unwrap(),
      },
      { ..p, modulus: @poly.zero(@oracle.nat(2)), },
      { ..p, real_generator_image: p.imaginary_unit_image, },
      { ..p, imaginary_unit_image: p.real_generator_image, },
      {
        ..p,
        real_generator_image: @poly.add(p.real_generator_image, p.modulus).unwrap(),
      },
      { ..p, imaginary_unit_image: cp_integer_poly([1]), },
      { ..p, imaginary_unit_image: @poly.zero(@oracle.nat(2)), },
    ] {
    assert_false(check(f, forged))
    assert_true(from_certificate(f, forged) is Err(InvalidCertificate))
    assert_false(check_result(f, rep, forged))
  }
  // A completely coherent conjugate presentation is still the wrong theta.
  let conjugate = @cf.conjugate(p.theta)
  let basis = power_basis(f, conjugate).unwrap()
  let inverse_basis = @linear.inverse(basis).unwrap()
  let alternate : Certificate = {
    ..p,
    theta: conjugate,
    basis,
    inverse_basis,
    real_generator_image: coordinates_polynomial(
      inverse_basis,
      real_generator(f).unwrap(),
    ).unwrap(),
    imaginary_unit_image: coordinates_polynomial(
      inverse_basis,
      @cf.imaginary_unit(f),
    ).unwrap(),
  }
  assert_true(@cf.check_minimal_polynomial(conjugate, alternate.modulus))
  assert_false(check(f, alternate))
  assert_false(check_result(f, { proof: alternate, }, p))
  let altered : Representation = { proof: { ..p, inverse_basis: identity, }, }
  assert_false(check_result(f, altered, p))
}

///|
test "valid wrong source conjugates and refined contexts cannot share certificates" {
  let f = cp_sqrt2()
  let rep = prepare(f).unwrap()
  let p = certificate(rep)
  let input = generator(rep)
  let converted = to_polynomial(rep, input).unwrap()
  for
    g in [
      cp_context([-2, 0, 1], (-2, 1), (-1, 1)),
      cp_context([-2, 0, 1], (7, 5), (3, 2)),
      cp_context([-3, 0, 1], (1, 1), (2, 1)),
    ] {
    let other = prepare(g).unwrap()
    let q = certificate(other)
    assert_true(check(g, q))
    assert_false(check(f, q))
    assert_false(check(g, p))
    assert_false(check(f, { ..p, source: g, }))
    assert_false(check_result(f, other, p))
    assert_false(check_result(g, rep, p))
    assert_false(
      check_conversion_for(
        other,
        input,
        converted.polynomial,
        converted.certificate,
      ),
    )
    assert_false(
      check_conversion_for(
        rep,
        generator(other),
        converted.polynomial,
        converted.certificate,
      ),
    )
    assert_false(
      check_conversion_for(rep, input, converted.polynomial, {
        ..converted.certificate,
        representation: q,
      }),
    )
    assert_true(to_polynomial(rep, generator(other)) is Err(DifferentField))
  }
}

///|
test "conversion checker binds actual source result and canonical coordinates" {
  let f = cp_sqrt2()
  let rep = prepare(f).unwrap()
  let a = generator(rep)
  let result = to_polynomial(rep, a).unwrap()
  let p = result.certificate
  let one = cp_integer_poly([1])
  let padded = @poly.add(result.polynomial, modulus(rep)).unwrap()
  assert_true(@cf.equal(from_polynomial(rep, padded).unwrap(), a))
  assert_true(check_conversion_for(rep, a, result.polynomial, p))
  assert_false(check_conversion_for(rep, @cf.one(f), result.polynomial, p))
  assert_false(
    check_conversion_for(rep, @cf.conjugate(a), result.polynomial, p),
  )
  assert_false(check_conversion_for(rep, a, one, p))
  assert_false(
    check_conversion_for(rep, a, result.polynomial, { ..p, input: @cf.one(f), }),
  )
  assert_false(
    check_conversion_for(rep, a, result.polynomial, { ..p, polynomial: one, }),
  )
  assert_false(check_conversion_for(rep, a, one, { ..p, polynomial: one, }))
  assert_false(
    check_conversion_for(rep, a, padded, { ..p, polynomial: padded, }),
  )
  assert_false(
    check_conversion_for(rep, a, @poly.zero(@oracle.nat(2)), {
      ..p,
      polynomial: @poly.zero(@oracle.nat(2)),
    }),
  )
  assert_false(
    check_conversion_for(rep, a, result.polynomial, {
      ..p,
      representation: {
        ..p.representation,
        inverse_basis: @matrix.transpose(p.representation.inverse_basis),
      },
    }),
  )
  // Source and result are coherent with another conversion, yet the actual
  // caller-supplied source still decides what this proof is allowed to claim.
  let other = to_polynomial(rep, @cf.conjugate(a)).unwrap()
  assert_false(
    check_conversion_for(rep, a, other.polynomial, other.certificate),
  )
  assert_false(
    check_conversion_for(rep, @cf.conjugate(a), result.polynomial, p),
  )
  assert_false(
    check_conversion_for(rep, a, other.polynomial, {
      ..other.certificate,
      input: a,
    }),
  )
}
