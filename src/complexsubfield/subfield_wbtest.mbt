///|
fn sf_poly(coefficients : Array[Int32]) -> @poly.Polynomial {
  @poly.polynomial(
    @oracle.nat(1),
    @oracle.chain(
      [
        for index, coefficient in coefficients => {
          @poly.Term::{
            coefficient: @oracle.rational(coefficient, 1),
            exponents: Cons(@oracle.nat(index), Nil),
          }
        }
      ],
    ),
  ).unwrap()
}

///|
fn sf_context(
  coefficients : Array[Int32],
  lower : Int32,
  upper : Int32,
) -> @cf.Field {
  let root : @real.RootCertificate = {
    polynomial: sf_poly(coefficients),
    interval: {
      lower: @oracle.rational(lower, 1),
      upper: @oracle.rational(upper, 1),
    },
  }
  match
    @minimal.normalize_root(
      root,
      @oracle.chain([2, 3, 5, 7, 11, 13].map(@oracle.binary)),
      @oracle.nat(100),
      @oracle.nat(500),
      @oracle.nat(500),
    ).unwrap() {
    @minimal.Normalized(value, proof) =>
      @cf.field(@nf.field_result(value, proof, @oracle.nat(500)).unwrap())
    _ => abort("subfield tests require a checked real minimum")
  }
}

///|
fn sf_alpha(field : @cf.Field) -> @cf.Element {
  @cf.element(
    field,
    @nf.generator(@cf.real_field(field)).unwrap(),
    @nf.zero(@cf.real_field(field)),
  ).unwrap()
}

///|
fn sf_monomials(
  values : Array[Array[Int32]],
) -> @core.Chain[@core.Chain[@core.Nat]] {
  @oracle.chain(values.map(fn(row) { @oracle.chain(row.map(@oracle.nat)) }))
}

///|
fn sf_roundtrip(field : Field, value : @cf.Element) -> Unit raise {
  assert_true(contains(field, value))
  let vector = coordinates(field, value).unwrap()
  assert_eq(@core.length(vector), degree(field))
  assert_true(@cf.equal(from_coordinates(field, vector).unwrap(), value))
}

///|
fn sf_representation(field : Field) -> Representation {
  match primitive_advance(primitive_start(field), @oracle.nat(5)).unwrap() {
    PrimitiveReady(value, _) => value
    _ => abort("small test field must have a primitive candidate below five")
  }
}

///|
test "Gaussian ambient and rational or empty generators give exact degrees" {
  let source = sf_context([0, 1], -1, 1)
  assert_eq(@cf.degree(source), @oracle.nat(2))
  let imaginary = @cf.imaginary_unit(source)
  let gaussian = generate(source, Cons(imaginary, Nil)).unwrap()
  assert_eq(degree(gaussian), @oracle.nat(2))
  assert_true(
    check_result(source, generators(gaussian), gaussian, certificate(gaussian)),
  )
  sf_roundtrip(gaussian, imaginary)
  let representation = sf_representation(gaussian)
  assert_eq(modulus(representation), sf_poly([2, -2, 1]))
  let converted = to_polynomial(representation, imaginary).unwrap()
  assert_eq(converted.polynomial, sf_poly([-1, 1]))
  assert_true(
    check_conversion_for(
      representation,
      imaginary,
      converted.polynomial,
      converted.certificate,
    ),
  )
  for
    values in [
      @core.Chain::Nil,
      Cons(@cf.rational(source, @oracle.rational(7, 3)), Nil),
      @oracle.chain([
        @cf.zero(source),
        @cf.one(source),
        @cf.rational(source, @oracle.rational(-9, 2)),
      ]),
    ] {
    let field = generate(source, values).unwrap()
    assert_eq(degree(field), @oracle.nat(1))
    assert_true(check_result(source, values, field, certificate(field)))
    assert_false(contains(field, imaginary))
    sf_roundtrip(field, @cf.rational(source, @oracle.rational(-13, 7)))
    let ready = primitive_advance(primitive_start(field), @oracle.nat(1)).unwrap()
    guard ready is PrimitiveReady(result, proof) else {
      abort("rational subfield is ready at candidate zero")
    }
    assert_eq(proof.candidate, @oracle.nat(0))
    assert_true(check_primitive_result(field, result, proof))
    assert_eq(modulus(result), sf_poly([-1, 1]))
  }
}

///|
test "proper quadratic spans and independent generators in degree four" {
  let source = sf_context([-2, 0, 1], 1, 2)
  let a = sf_alpha(source)
  let i = @cf.imaginary_unit(source)
  for
    (values, dimension, present, absent) in [
      (@oracle.chain([a]), 2, a, i),
      (@oracle.chain([i]), 2, i, a),
      (@oracle.chain([a, a, @cf.negate(a)]), 2, a, i),
      (@oracle.chain([a, i]), 4, @cf.multiply(a, i).unwrap(), @cf.zero(source)),
    ] {
    let field = generate(source, values).unwrap()
    let proof = certificate(field)
    assert_eq(degree(field), @oracle.nat(dimension))
    assert_true(@cf.same_field(ambient(field), source))
    assert_true(check_result(source, values, field, proof))
    assert_true(
      check_result(
        source,
        values,
        from_certificate(source, values, proof).unwrap(),
        proof,
      ),
    )
    for value in @oracle.array(basis(field)) {
      sf_roundtrip(field, value)
    }
    sf_roundtrip(field, present)
    sf_roundtrip(field, @cf.inverse(present).unwrap().unwrap())
    if dimension < 4 {
      assert_false(contains(field, absent))
      assert_true(coordinates(field, absent) is Err(NotInSubfield))
    }
    assert_true(from_coordinates(field, Nil) is Err(DimensionMismatch))
    assert_true(
      from_coordinates(
        field,
        @core.replicate(@oracle.nat(dimension + 1), @exact.rational_zero()),
      )
      is Err(DimensionMismatch),
    )
  }
}

///|
test "zeta three generates a quadratic subfield inside degree four" {
  let source = sf_context([-3, 0, 1], 1, 2)
  let a = sf_alpha(source)
  let i = @cf.imaginary_unit(source)
  let zeta = @cf.multiply(
    @cf.add(@cf.negate(@cf.one(source)), @cf.multiply(a, i).unwrap()).unwrap(),
    @cf.rational(source, @oracle.rational(1, 2)),
  ).unwrap()
  assert_eq(@cf.minimal_polynomial(zeta).unwrap(), sf_poly([1, 1, 1]))
  let field = generate(source, Cons(zeta, Nil)).unwrap()
  assert_eq(degree(field), @oracle.nat(2))
  assert_false(contains(field, a))
  assert_false(contains(field, i))
  sf_roundtrip(field, zeta)
  sf_roundtrip(field, @cf.multiply(zeta, zeta).unwrap())
  let representation = sf_representation(field)
  assert_eq(modulus(representation), sf_poly([1, -1, 1]))
  assert_eq(
    to_polynomial(representation, zeta).unwrap().polynomial,
    sf_poly([-1, 1]),
  )
}

///|
test "quartic proper subfield in degree eight keeps rectangular coordinates" {
  let source = sf_context([-2, 0, 0, 0, 1], 1, 2)
  let a = sf_alpha(source)
  let theta = @cf.multiply(
    a,
    @cf.add(@cf.one(source), @cf.imaginary_unit(source)).unwrap(),
  ).unwrap()
  assert_eq(@cf.minimal_polynomial(theta).unwrap(), sf_poly([8, 0, 0, 0, 1]))
  let field = generate(source, Cons(theta, Nil)).unwrap()
  assert_eq(degree(field), @oracle.nat(4))
  assert_eq(@cf.degree(source), @oracle.nat(8))
  sf_roundtrip(field, theta)
  sf_roundtrip(field, @cf.inverse(theta).unwrap().unwrap())
  assert_false(contains(field, a))
  assert_false(contains(field, @cf.imaginary_unit(source)))
  let representation = sf_representation(field)
  let proof = primitive_certificate(representation)
  assert_eq(@matrix.height(proof.power_basis), @oracle.nat(8))
  assert_eq(@matrix.width(proof.power_basis), @oracle.nat(4))
  assert_true(check_primitive_result(field, representation, proof))
  for value in @oracle.array(basis(field)) {
    let conversion = to_polynomial(representation, value).unwrap()
    assert_true(
      check_conversion_for(
        representation,
        value,
        conversion.polynomial,
        conversion.certificate,
      ),
    )
    assert_true(
      @cf.equal(
        from_polynomial(representation, conversion.polynomial).unwrap(),
        value,
      ),
    )
  }
  assert_true(to_polynomial(representation, a) is Err(NotInSubfield))
}

///|
test "closure provenance independence and complete actual field payload are checked" {
  let source = sf_context([-2, 0, 1], 1, 2)
  let a = sf_alpha(source)
  let i = @cf.imaginary_unit(source)
  let values : @core.Chain[@cf.Element] = Cons(a, Nil)
  let field = generate(source, values).unwrap()
  let proof = certificate(field)
  let one = @cf.one(source)
  let alternate : Certificate = {
    ..proof,
    basis: @oracle.chain([a, one]),
    monomials: sf_monomials([[1], [0]]),
  }
  assert_true(check(source, values, alternate))
  assert_true(
    check_result(
      source,
      values,
      from_certificate(source, values, alternate).unwrap(),
      alternate,
    ),
  )
  assert_false(check_result(source, values, field, alternate))
  let ambient_basis = @oracle.chain([one, a, i, @cf.multiply(a, i).unwrap()])
  for
    forged in [
      { ..proof, degree: @oracle.nat(1), },
      { ..proof, degree: @oracle.nat(3), },
      { ..proof, basis: Nil, monomials: Nil, degree: @oracle.nat(0), },
      { ..proof, basis: @oracle.chain([one, one]), },
      {
        ..proof,
        basis: @oracle.chain([a, @cf.multiply(a, a).unwrap()]),
        monomials: sf_monomials([[1], [2]]),
      },
      {
        ..proof,
        basis: Cons(one, Nil),
        monomials: sf_monomials([[0]]),
        degree: @oracle.nat(1),
      },
      { ..proof, monomials: Nil, },
      { ..proof, monomials: sf_monomials([[0], [0]]), },
      { ..proof, monomials: sf_monomials([[0, 0], [1, 0]]), },
      {
        ..proof,
        basis: ambient_basis,
        degree: @oracle.nat(4),
        monomials: sf_monomials([[0], [1], [2], [3]]),
      },
      { ..proof, generators: Cons(i, Nil), },
    ] {
    assert_false(check(source, values, forged))
    assert_false(check_result(source, values, field, forged))
    assert_true(
      from_certificate(source, values, forged) is Err(InvalidCertificate),
    )
  }
  let impostor : Field = { proof: alternate, }
  assert_false(check_result(source, values, impostor, proof))
  let missing : Certificate = {
    ..proof,
    basis: Cons(a, Nil),
    monomials: sf_monomials([[1]]),
    degree: @oracle.nat(1),
  }
  assert_false(check(source, values, missing))
  assert_false(check(source, Cons(i, Nil), proof))
  assert_false(check(source, @oracle.chain([a, a]), proof))
}

///|
test "primitive budget pauses at the next exact trial and resumes deterministically" {
  let source = sf_context([-2, 0, 1], 1, 2)
  let field = generate(source, Cons(sf_alpha(source), Nil)).unwrap()
  let start = primitive_start(field)
  assert_eq(primitive_next_candidate(start), @oracle.nat(0))
  guard primitive_advance(start, @oracle.nat(0)).unwrap()
    is PrimitivePaused(still) else {
    abort("zero budget must pause")
  }
  assert_eq(primitive_next_candidate(still), @oracle.nat(0))
  guard primitive_advance(still, @oracle.nat(1)).unwrap()
    is PrimitivePaused(next) else {
    abort("candidate zero is rational")
  }
  assert_eq(primitive_next_candidate(next), @oracle.nat(1))
  guard primitive_advance(next, @oracle.nat(0)).unwrap()
    is PrimitivePaused(same) else {
    abort("zero budget must preserve next candidate")
  }
  assert_eq(primitive_next_candidate(same), @oracle.nat(1))
  guard primitive_advance(same, @oracle.nat(1)).unwrap()
    is PrimitiveReady(value, proof) else {
    abort("candidate one is primitive")
  }
  assert_eq(proof.candidate, @oracle.nat(1))
  assert_eq(modulus(value), sf_poly([-1, -2, 1]))
  assert_true(check_primitive_result(field, value, proof))
  guard primitive_advance(start, @oracle.nat(2)).unwrap()
    is PrimitiveReady(direct, direct_proof) else {
    abort("two trials must find candidate one")
  }
  assert_true(same_primitive_certificate(proof, direct_proof))
  assert_true(check_primitive_result(field, direct, proof))
}

///|
test "a nonzero bad primitive candidate is skipped without a fixed trial cap" {
  let source = sf_context([-2, 0, 1], 1, 2)
  let a = sf_alpha(source)
  let i = @cf.imaginary_unit(source)
  let ai = @cf.multiply(a, i).unwrap()
  let last = @cf.subtract(@cf.subtract(i, a).unwrap(), ai).unwrap()
  let field = generate(source, @oracle.chain([a, ai, last])).unwrap()
  assert_eq(degree(field), @oracle.nat(4))
  assert_true(
    @cf.equal(
      candidate_element(field, @oracle.nat(1)).unwrap(),
      @cf.add(@cf.one(source), i).unwrap(),
    ),
  )
  guard primitive_advance(primitive_start(field), @oracle.nat(2)).unwrap()
    is PrimitivePaused(next) else {
    abort("candidates zero and one lie in proper subfields")
  }
  assert_eq(primitive_next_candidate(next), @oracle.nat(2))
  guard primitive_advance(next, @oracle.nat(1)).unwrap()
    is PrimitiveReady(value, proof) else {
    abort("candidate two must generate the quartic field")
  }
  assert_eq(proof.candidate, @oracle.nat(2))
  assert_true(check_primitive_result(field, value, proof))
  assert_true(
    from_primitive_certificate(field, { ..proof, candidate: @oracle.nat(1), })
    is Err(InvalidCertificate),
  )
}

///|
test "primitive and conversion certificates bind source modulus and actual result" {
  let source = sf_context([-2, 0, 1], 1, 2)
  let a = sf_alpha(source)
  let field = generate(source, Cons(a, Nil)).unwrap()
  let representation = sf_representation(field)
  let proof = primitive_certificate(representation)
  assert_true(check_primitive(field, proof))
  assert_true(
    check_primitive_result(
      field,
      from_primitive_certificate(field, proof).unwrap(),
      proof,
    ),
  )
  let changed_field = generate(source, Cons(@cf.imaginary_unit(source), Nil)).unwrap()
  for
    forged in [
      { ..proof, field: certificate(changed_field), },
      { ..proof, candidate: @oracle.nat(0), },
      { ..proof, theta: @cf.negate(proof.theta), },
      { ..proof, modulus: sf_poly([-2, 0, 1]), },
      {
        ..proof,
        modulus: @poly.multiply(proof.modulus, sf_poly([1, 1])).unwrap(),
      },
      { ..proof, power_basis: @matrix.transpose(proof.power_basis), },
    ] {
    assert_false(check_primitive(field, forged))
    assert_false(check_primitive_result(field, representation, forged))
    assert_true(
      from_primitive_certificate(field, forged) is Err(InvalidCertificate),
    )
  }
  let impostor : Representation = { ..representation, field: changed_field, }
  assert_false(check_primitive_result(field, impostor, proof))
  assert_false(check_primitive_result(changed_field, representation, proof))
  let conversion = to_polynomial(representation, a).unwrap()
  let polynomial = conversion.polynomial
  assert_eq(polynomial, sf_poly([-1, 1]))
  assert_true(
    check_conversion_for(representation, a, polynomial, conversion.certificate),
  )
  for
    forged in [
      { ..conversion.certificate, input: @cf.negate(a), },
      { ..conversion.certificate, polynomial: sf_poly([1]), },
      {
        ..conversion.certificate,
        representation: { ..proof, candidate: @oracle.nat(0), },
      },
    ] {
    assert_false(check_conversion_for(representation, a, polynomial, forged))
  }
  assert_false(
    check_conversion_for(
      representation,
      @cf.negate(a),
      polynomial,
      conversion.certificate,
    ),
  )
  assert_false(
    check_conversion_for(
      representation,
      a,
      sf_poly([1]),
      conversion.certificate,
    ),
  )
  let noncanonical = @poly.add(polynomial, modulus(representation)).unwrap()
  assert_true(
    @cf.equal(from_polynomial(representation, noncanonical).unwrap(), a),
  )
  assert_false(
    check_conversion_for(representation, a, noncanonical, {
      ..conversion.certificate,
      polynomial: noncanonical,
    }),
  )
  assert_true(
    @cf.is_zero(
      from_polynomial(representation, modulus(representation)).unwrap(),
    ),
  )
  assert_true(
    to_polynomial(representation, @cf.imaginary_unit(source))
    is Err(NotInSubfield),
  )
  let multivariate = @poly.constant(@oracle.nat(2), @exact.rational_one())
  assert_true(
    from_polynomial(representation, multivariate) is Err(NotUnivariate),
  )
  assert_false(
    check_conversion_for(representation, a, multivariate, {
      ..conversion.certificate,
      polynomial: multivariate,
    }),
  )
}

///|
test "foreign sources and generator order are rejected at all boundaries" {
  let source = sf_context([-2, 0, 1], 1, 2)
  let foreign = sf_context([-3, 0, 1], 1, 2)
  let a = sf_alpha(source)
  let i = @cf.imaginary_unit(source)
  let x = sf_alpha(foreign)
  let values = @oracle.chain([a, i])
  let field = generate(source, values).unwrap()
  let proof = certificate(field)
  assert_true(generate(source, Cons(x, Nil)) is Err(DifferentField))
  assert_false(check(foreign, values, proof))
  assert_false(check(source, @core.reverse(values), proof))
  assert_false(check(source, values, { ..proof, source: foreign, }))
  assert_false(contains(field, x))
  assert_true(coordinates(field, x) is Err(DifferentField))
  assert_false(check_result(foreign, values, field, proof))
  let representation = sf_representation(field)
  assert_true(to_polynomial(representation, x) is Err(DifferentField))
  let conversion = to_polynomial(representation, a).unwrap()
  assert_false(
    check_conversion_for(
      representation,
      x,
      conversion.polynomial,
      conversion.certificate,
    ),
  )
  let foreign_field = generate(foreign, Cons(x, Nil)).unwrap()
  assert_false(
    check_primitive_result(
      foreign_field,
      representation,
      primitive_certificate(representation),
    ),
  )
}
