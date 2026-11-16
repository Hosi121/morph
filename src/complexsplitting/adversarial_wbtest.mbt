///|
fn review_qpoly(coefficients : Array[(Int32, Int32)]) -> @poly.Polynomial {
  @poly.polynomial(
    @oracle.nat(1),
    @oracle.chain(
      [
        for index, coefficient in coefficients => {
          @poly.Term::{
            coefficient: @oracle.rational(coefficient.0, coefficient.1),
            exponents: Cons(@oracle.nat(index), Nil),
          }
        }
      ],
    ),
  ).unwrap()
}

///|
fn review_root(value : @cf.Element, multiplicity : Int32) -> Root {
  { value, multiplicity: @oracle.nat(multiplicity), }
}

///|
fn review_weighted_roots(ambient : @cf.Field) -> @core.Chain[Root] {
  let imaginary = @cf.imaginary_unit(ambient)
  @oracle.chain([
    review_root(imaginary, 2),
    review_root(@cf.negate(imaginary), 2),
    review_root(@cf.one(ambient), 1),
  ])
}

///|
fn review_finish(
  polynomial : @poly.Polynomial,
  ambient : @cf.Field,
  values : @core.Chain[Root],
) -> Splitting {
  match solve_from_roots(polynomial, ambient, values, split_budget()).unwrap() {
    Ready(value, _) => value
    _ =>
      abort("bounded supplied-root review requires no further primitive trials")
  }
}

///|
fn review_images(
  representation : @sub.Representation,
  values : @core.Chain[Root],
) -> @core.Chain[RootImage] {
  @core.map(values, fn(root) {
    let converted = @sub.to_polynomial(representation, root.value).unwrap()
    RootImage::{
      polynomial: converted.polynomial,
      multiplicity: root.multiplicity,
      conversion: converted.certificate,
    }
  })
}

///|
fn review_primitive(
  field : @sub.Field,
) -> (@sub.Representation, @sub.PrimitiveCertificate) {
  match
    @sub.primitive_advance(@sub.primitive_start(field), @oracle.nat(8)).unwrap() {
    @sub.PrimitiveReady(value, proof) => (value, proof)
    _ =>
      abort("bounded review subfield needs a primitive candidate below eight")
  }
}

///|
fn review_reject(
  polynomial : @poly.Polynomial,
  ambient : @cf.Field,
  value : Splitting,
  forged : Certificate,
) -> Unit raise {
  assert_false(check(polynomial, ambient, forged))
  assert_false(check_result(polynomial, ambient, value, forged))
  assert_true(
    from_certificate(polynomial, ambient, forged) is Err(InvalidCertificate),
  )
}

///|
test "review unequal rational multiplicities require the exact first nonzero jet" {
  let ambient = split_real_field([0, 1], -1, 1)
  let polynomial = split_poly([1, -1, -1, 1])
  let one = @cf.one(ambient)
  let negative = @cf.negate(one)
  let values = @oracle.chain([review_root(one, 2), review_root(negative, 1)])
  let result = review_finish(polynomial, ambient, values)
  let proof = certificate(result)
  assert_eq(degree(result), @oracle.nat(1))
  assert_true(check_result(polynomial, ambient, result, proof))
  let derivative = @poly.derivative(polynomial, @oracle.nat(0)).unwrap()
  let second = @poly.derivative(derivative, @oracle.nat(0)).unwrap()
  assert_true(@cf.is_zero(@cf.evaluate_polynomial(one, derivative).unwrap()))
  assert_true(
    @cf.equal(
      @cf.evaluate_polynomial(negative, derivative).unwrap(),
      @cf.rational(ambient, @oracle.rational(4, 1)),
    ),
  )
  assert_true(
    @cf.equal(
      @cf.evaluate_polynomial(one, second).unwrap(),
      @cf.rational(ambient, @oracle.rational(4, 1)),
    ),
  )
  let swapped = @oracle.chain([review_root(one, 1), review_root(negative, 2)])
  assert_eq(
    @core.fold_left(swapped, @core.Zero, fn(sum, root) {
      @core.add(sum, root.multiplicity)
    }),
    @oracle.nat(3),
  )
  for
    invalid in [
      swapped,
      @oracle.chain([review_root(one, 3)]),
      @oracle.chain([
        review_root(one, 1),
        review_root(one, 1),
        review_root(negative, 1),
      ]),
      @oracle.chain([review_root(one, 0), review_root(negative, 3)]),
      @oracle.chain([review_root(one, 2)]),
    ] {
    assert_true(
      start_from_roots(polynomial, ambient, invalid) is Err(InvalidRoots),
    )
    review_reject(polynomial, ambient, result, { ..proof, roots: invalid, })
  }
  let images = @oracle.array(root_images(result))
  assert_eq(images[0].polynomial, split_poly([1]))
  assert_eq(images[1].polynomial, split_poly([-1]))
  review_reject(polynomial, ambient, result, {
    ..proof,
    images: @oracle.chain([
      { ..images[0], multiplicity: @oracle.nat(1), },
      { ..images[1], multiplicity: @oracle.nat(2), },
    ]),
  })
}

///|
test "review weighted Gaussian roots reject degree preserving multiplicity exchanges" {
  let ambient = split_real_field([0, 1], -1, 1)
  let polynomial = split_poly([-1, 1, -2, 2, -1, 1])
  let values = review_weighted_roots(ambient)
  let result = review_finish(polynomial, ambient, values)
  let proof = certificate(result)
  assert_eq(degree(result), @oracle.nat(2))
  assert_eq(modulus(result), split_poly([2, -2, 1]))
  assert_true(check_result(polynomial, ambient, result, proof))
  let imaginary = @cf.imaginary_unit(ambient)
  let negative = @cf.negate(imaginary)
  let one = @cf.one(ambient)
  let derivative = @poly.derivative(polynomial, @oracle.nat(0)).unwrap()
  let second = @poly.derivative(derivative, @oracle.nat(0)).unwrap()
  assert_true(
    @cf.is_zero(@cf.evaluate_polynomial(imaginary, derivative).unwrap()),
  )
  assert_false(@cf.is_zero(@cf.evaluate_polynomial(imaginary, second).unwrap()))
  assert_true(
    @cf.equal(
      @cf.evaluate_polynomial(one, derivative).unwrap(),
      @cf.rational(ambient, @oracle.rational(4, 1)),
    ),
  )
  for
    invalid in [
      @oracle.chain([
        review_root(imaginary, 1),
        review_root(negative, 2),
        review_root(one, 2),
      ]),
      @oracle.chain([
        review_root(imaginary, 3),
        review_root(negative, 1),
        review_root(one, 1),
      ]),
      @oracle.chain([review_root(imaginary, 2), review_root(negative, 3)]),
      @oracle.chain([
        review_root(imaginary, 2),
        review_root(negative, 1),
        review_root(one, 1),
        review_root(@cf.zero(ambient), 1),
      ]),
      @oracle.chain([review_root(imaginary, 2), review_root(negative, 2)]),
      @core.append(values, Cons(review_root(one, 0), Nil)),
    ] {
    assert_true(
      start_from_roots(polynomial, ambient, invalid) is Err(InvalidRoots),
    )
    review_reject(polynomial, ambient, result, { ..proof, roots: invalid, })
  }
  let images = @oracle.array(proof.images)
  for (root, image) in @oracle.array(@core.zip(values, proof.images).unwrap()) {
    assert_eq(root.multiplicity, image.multiplicity)
    assert_true(
      @sub.check_conversion_for(
        representation(result),
        root.value,
        image.polynomial,
        image.conversion,
      ),
    )
    assert_true(
      @cf.equal(
        @sub.from_polynomial(representation(result), image.polynomial).unwrap(),
        root.value,
      ),
    )
  }
  assert_eq(images[0].polynomial, split_poly([-1, 1]))
  assert_eq(images[1].polynomial, split_poly([1, -1]))
  assert_eq(images[2].polynomial, split_poly([1]))
}

///|
test "review original nonmonic scale and rational coefficients bind every public checker" {
  let ambient = split_real_field([0, 1], -1, 1)
  let monic = split_poly([1, -1, -1, 1])
  let scaled = review_qpoly([(7, 3), (-7, 3), (-7, 3), (7, 3)])
  let negative = split_poly([-6, 6, 6, -6])
  let one = @cf.one(ambient)
  let values = @oracle.chain([
    review_root(one, 2),
    review_root(@cf.negate(one), 1),
  ])
  let original = review_finish(monic, ambient, values)
  let scaled_result = review_finish(scaled, ambient, values)
  let negative_result = review_finish(negative, ambient, values)
  for
    (polynomial, result) in [
      (scaled, scaled_result),
      (negative, negative_result),
    ] {
    let proof = certificate(result)
    assert_eq(source(result), polynomial)
    assert_true(check_result(polynomial, ambient, result, proof))
    assert_true(
      check_result(
        polynomial,
        ambient,
        from_certificate(polynomial, ambient, proof).unwrap(),
        proof,
      ),
    )
    assert_false(check(monic, ambient, proof))
    assert_false(check_result(monic, ambient, result, proof))
    assert_false(check_result(polynomial, ambient, original, proof))
    assert_false(
      check_result(polynomial, ambient, result, certificate(original)),
    )
    assert_true(
      from_certificate(monic, ambient, proof) is Err(InvalidCertificate),
    )
    review_reject(polynomial, ambient, result, { ..proof, source: monic, })
  }
}

///|
test "review valid alternate primitive and quotient certificates cannot be swapped" {
  let ambient = split_real_field([0, 1], -1, 1)
  let polynomial = split_poly([-1, 1, -2, 2, -1, 1])
  let values = review_weighted_roots(ambient)
  let result = review_finish(polynomial, ambient, values)
  let proof = certificate(result)
  let imaginary = @cf.imaginary_unit(ambient)
  let twice = @cf.multiply(
    imaginary,
    @cf.rational(ambient, @oracle.rational(2, 1)),
  ).unwrap()
  let scaled_field = @sub.generate(ambient, Cons(twice, Nil)).unwrap()
  let (_, scaled_proof) = review_primitive(scaled_field)
  let alternate_proof : @sub.PrimitiveCertificate = {
    ..scaled_proof,
    field: proof.generated,
    candidate: @oracle.nat(2),
  }
  let alternate = @sub.from_primitive_certificate(
    generated_field(result),
    alternate_proof,
  ).unwrap()
  assert_true(
    @sub.check_primitive_result(
      generated_field(result),
      alternate,
      alternate_proof,
    ),
  )
  assert_eq(@sub.modulus(alternate), split_poly([5, -2, 1]))
  let alternate_images = review_images(alternate, values)
  let alternate_certificate : Certificate = {
    ..proof,
    primitive: alternate_proof,
    images: alternate_images,
  }
  assert_true(check(polynomial, ambient, alternate_certificate))
  let imported = from_certificate(polynomial, ambient, alternate_certificate).unwrap()
  assert_true(
    check_result(polynomial, ambient, imported, alternate_certificate),
  )
  assert_false(check_result(polynomial, ambient, result, alternate_certificate))
  assert_false(check_result(polynomial, ambient, imported, proof))
  let alternate_array = @oracle.array(alternate_images)
  let images = @oracle.array(proof.images)
  assert_eq(alternate_array[0].polynomial, review_qpoly([(-1, 2), (1, 2)]))
  assert_eq(alternate_array[1].polynomial, review_qpoly([(1, 2), (-1, 2)]))
  for
    forged in [
      { ..proof, primitive: alternate_proof, },
      { ..proof, images: alternate_images, },
      {
        ..proof,
        images: @oracle.chain([
          { ..images[0], conversion: alternate_array[0].conversion, },
          images[1],
          images[2],
        ]),
      },
      {
        ..proof,
        images: @oracle.chain([
          { ..images[0], polynomial: alternate_array[0].polynomial, },
          images[1],
          images[2],
        ]),
      },
    ] {
    review_reject(polynomial, ambient, result, forged)
  }
  let noncanonical = @poly.add(images[0].polynomial, modulus(result)).unwrap()
  assert_true(
    @cf.equal(
      @sub.from_polynomial(representation(result), noncanonical).unwrap(),
      imaginary,
    ),
  )
  review_reject(polynomial, ambient, result, {
    ..proof,
    images: @oracle.chain([
      {
        ..images[0],
        polynomial: noncanonical,
        conversion: { ..images[0].conversion, polynomial: noncanonical, },
      },
      images[1],
      images[2],
    ]),
  })
  assert_false(
    check_result(
      polynomial,
      ambient,
      { ..result, representation: alternate, },
      proof,
    ),
  )
  assert_false(
    check_result(
      polynomial,
      ambient,
      { ..result, proof: alternate_certificate, },
      proof,
    ),
  )
  assert_false(
    check_result(
      polynomial,
      ambient,
      { ..result, representation: alternate, proof: alternate_certificate, },
      proof,
    ),
  )
}

///|
test "review coherent alternative field and complete private payload swaps are bound" {
  let ambient = split_real_field([0, 1], -1, 1)
  let polynomial = split_poly([-1, 1, -2, 2, -1, 1])
  let values = review_weighted_roots(ambient)
  let result = review_finish(polynomial, ambient, values)
  let proof = certificate(result)
  let alternative_generated : @sub.Certificate = {
    ..proof.generated,
    basis: @core.reverse(proof.generated.basis),
    monomials: @core.reverse(proof.generated.monomials),
  }
  let alternative_field = @sub.from_certificate(
    ambient,
    root_values(values),
    alternative_generated,
  ).unwrap()
  let (alternative_representation, alternative_primitive) = review_primitive(
    alternative_field,
  )
  assert_eq(alternative_primitive.candidate, @oracle.nat(0))
  assert_eq(@sub.modulus(alternative_representation), split_poly([1, 0, 1]))
  let alternative_proof : Certificate = {
    ..proof,
    generated: alternative_generated,
    primitive: alternative_primitive,
    images: review_images(alternative_representation, values),
  }
  let complete : Splitting = {
    proof: alternative_proof,
    field: alternative_field,
    representation: alternative_representation,
  }
  assert_true(check(polynomial, ambient, alternative_proof))
  assert_true(check_result(polynomial, ambient, complete, alternative_proof))
  for
    impostor in [
      { ..result, field: alternative_field, },
      { ..result, representation: alternative_representation, },
      { ..result, proof: alternative_proof, },
      {
        ..result,
        field: alternative_field,
        representation: alternative_representation,
      },
      { ..result, field: alternative_field, proof: alternative_proof, },
      {
        ..result,
        representation: alternative_representation,
        proof: alternative_proof,
      },
      complete,
    ] {
    assert_false(check_result(polynomial, ambient, impostor, proof))
  }
  assert_false(check_result(polynomial, ambient, result, alternative_proof))
}

///|
test "review larger and foreign ambient contexts cannot replace the minimal generated field" {
  let ambient = split_real_field([-2, 0, 1], 1, 2)
  let foreign = split_real_field([0, 1], -1, 1)
  let polynomial = split_poly([-1, 1, -2, 2, -1, 1])
  let values = review_weighted_roots(ambient)
  let result = review_finish(polynomial, ambient, values)
  let proof = certificate(result)
  assert_eq(@cf.degree(ambient), @oracle.nat(4))
  assert_eq(degree(result), @oracle.nat(2))
  assert_true(check_result(polynomial, ambient, result, proof))
  let k = @cf.real_field(ambient)
  let alpha = @cf.element(ambient, @nf.generator(k).unwrap(), @nf.zero(k)).unwrap()
  assert_false(@sub.contains(generated_field(result), alpha))
  let large = @sub.generate(
    ambient,
    @core.append(root_values(values), Cons(alpha, Nil)),
  ).unwrap()
  assert_eq(@sub.degree(large), @oracle.nat(4))
  review_reject(polynomial, ambient, result, {
    ..proof,
    generated: @sub.certificate(large),
  })
  let i = @cf.imaginary_unit(ambient)
  let oversized : @sub.Certificate = {
    source: ambient,
    generators: root_values(values),
    degree: @oracle.nat(4),
    basis: @oracle.chain([
      @cf.one(ambient),
      i,
      alpha,
      @cf.multiply(i, alpha).unwrap(),
    ]),
    monomials: @oracle.chain([
      @oracle.chain([0, 0, 0].map(@oracle.nat)),
      @oracle.chain([1, 0, 0].map(@oracle.nat)),
      @oracle.chain([0, 0, 1].map(@oracle.nat)),
      @oracle.chain([1, 0, 1].map(@oracle.nat)),
    ]),
  }
  assert_false(@sub.check(ambient, root_values(values), oversized))
  review_reject(polynomial, ambient, result, { ..proof, generated: oversized, })
  assert_false(
    check_result(polynomial, ambient, { ..result, field: large, }, proof),
  )
  let foreign_values = review_weighted_roots(foreign)
  let foreign_result = review_finish(polynomial, foreign, foreign_values)
  let foreign_proof = certificate(foreign_result)
  assert_true(check_result(polynomial, foreign, foreign_result, foreign_proof))
  assert_false(check(polynomial, ambient, foreign_proof))
  assert_false(check_result(polynomial, ambient, foreign_result, foreign_proof))
  assert_false(check_result(polynomial, foreign, result, proof))
  assert_true(
    start_from_roots(polynomial, ambient, foreign_values) is Err(InvalidRoots),
  )
  review_reject(polynomial, ambient, result, { ..proof, ambient: foreign, })
  review_reject(polynomial, ambient, result, { ..proof, roots: foreign_values, })
  assert_false(
    check_result(
      polynomial,
      ambient,
      { ..result, field: generated_field(foreign_result), },
      proof,
    ),
  )
  assert_false(
    check_result(
      polynomial,
      ambient,
      { ..result, representation: representation(foreign_result), },
      proof,
    ),
  )
  assert_false(
    check_result(
      polynomial,
      ambient,
      { ..result, proof: foreign_proof, },
      proof,
    ),
  )
  assert_false(
    check_result(
      polynomial,
      ambient,
      Splitting::{
        field: generated_field(foreign_result),
        representation: representation(foreign_result),
        proof: foreign_proof,
      },
      proof,
    ),
  )
}
