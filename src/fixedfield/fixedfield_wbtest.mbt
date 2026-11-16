///|
fn ff_poly(coefficients : Array[Int32]) -> @poly.Polynomial {
  @poly.polynomial(
    @oracle.nat(1),
    @oracle.chain(
      [
        for i, c in coefficients => {
          @poly.Term::{
            coefficient: @oracle.rational(c, 1),
            exponents: Cons(@oracle.nat(i), Nil),
          }
        }
      ],
    ),
  ).unwrap()
}

///|
fn ff_context(
  coefficients : Array[Int32],
  lower : Int32,
  upper : Int32,
) -> @cf.Field {
  let root = @real.number({
    polynomial: ff_poly(coefficients),
    interval: {
      lower: @oracle.rational(lower, 1),
      upper: @oracle.rational(upper, 1),
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
    _ => abort("fixed-field test requires a checked real generator")
  }
}

///|
fn ff_alpha(field : @cf.Field) -> @cf.Element {
  @cf.element(
    field,
    @nf.generator(@cf.real_field(field)).unwrap(),
    @nf.zero(@cf.real_field(field)),
  ).unwrap()
}

///|
fn ff_quartic() -> @aut.Group {
  let f = ff_context([-2, 0, 0, 0, 1], 1, 2)
  let a = ff_alpha(f)
  let ia = @cf.multiply(@cf.imaginary_unit(f), a).unwrap()
  @aut.prepare(f, @oracle.chain([a, ia, @cf.negate(a), @cf.negate(ia)])).unwrap()
}

///|
fn ff_members(indices : Array[Int32]) -> @core.Chain[@core.Nat] {
  @oracle.chain(indices.map(@oracle.nat))
}

///|
fn ff_roundtrip(field : Field, value : @cf.Element) -> Unit raise {
  assert_true(contains(field, value))
  let vector = coordinates(field, value).unwrap()
  assert_eq(@core.length(vector), degree(field))
  assert_true(@cf.equal(from_coordinates(field, vector).unwrap(), value))
  assert_eq(
    coordinates(field, from_coordinates(field, vector).unwrap()).unwrap(),
    vector,
  )
}

///|
test "D4 subgroup invariants are complete and identify six familiar fields" {
  let g = ff_quartic()
  let f = @aut.source(g)
  let a = ff_alpha(f)
  let i = @cf.imaginary_unit(f)
  let aa = @cf.multiply(a, a).unwrap()
  for
    (indices, dimension, present, absent) in [
      ([0], 8, a, @cf.zero(f)),
      ([0, 1, 2, 3, 4, 5, 6, 7], 1, @cf.one(f), a),
      ([0, 2, 4, 6], 2, i, a),
      ([0, 1], 4, a, i),
      ([0, 4], 4, aa, a),
      ([0, 1, 4, 5], 2, aa, i),
    ] {
    let field = prepare(g, ff_members(indices)).unwrap()
    let p = certificate(field)
    assert_eq(degree(field), @oracle.nat(dimension))
    assert_eq(members(field), ff_members(indices))
    assert_true(check(g, p))
    assert_true(check_result(g, field, p))
    assert_true(check_result(g, from_certificate(g, p).unwrap(), p))
    assert_eq(@core.add(p.rank, p.degree), @cf.degree(f))
    assert_eq(@core.multiply(p.degree, @core.length(p.members)), @cf.degree(f))
    ff_roundtrip(field, present)
    ff_roundtrip(field, @cf.zero(f))
    ff_roundtrip(field, @cf.rational(f, @oracle.rational(-7, 3)))
    for basis_value in @oracle.array(basis(field)) {
      ff_roundtrip(field, basis_value)
    }
    if dimension < 8 {
      assert_false(contains(field, absent))
      assert_true(coordinates(field, absent) is Err(NotFixed))
    }
    let normalized = prepare(
      g,
      @core.append(@core.reverse(ff_members(indices)), ff_members(indices)),
    ).unwrap()
    assert_eq(members(normalized), ff_members(indices))
  }
  let central = prepare(g, ff_members([0, 4])).unwrap()
  ff_roundtrip(central, i)
  ff_roundtrip(central, @cf.multiply(aa, i).unwrap())
  assert_true(@aut.check_result(f, group(central), @aut.certificate(g)))
}

///|
test "D4 reflection fixes alpha times one plus i with quartic minimum" {
  let g = ff_quartic()
  let f = @aut.source(g)
  let field = prepare(g, ff_members([0, 3])).unwrap()
  let a = ff_alpha(f)
  let theta = @cf.multiply(
    a,
    @cf.add(@cf.one(f), @cf.imaginary_unit(f)).unwrap(),
  ).unwrap()
  assert_eq(degree(field), @oracle.nat(4))
  assert_eq(@cf.minimal_polynomial(theta).unwrap(), ff_poly([8, 0, 0, 0, 1]))
  ff_roundtrip(field, theta)
  assert_false(contains(field, a))
  assert_false(contains(field, @cf.imaginary_unit(f)))
  let theta_inverse = @cf.inverse(theta).unwrap().unwrap()
  ff_roundtrip(field, theta_inverse)
  ff_roundtrip(field, @cf.multiply(theta, theta_inverse).unwrap())
  ff_roundtrip(field, @cf.multiply(theta, theta).unwrap())
  ff_roundtrip(field, @cf.add(theta, theta_inverse).unwrap())
  let supplied = @oracle.chain([
    @oracle.rational(-3, 7),
    @oracle.rational(5, 11),
    @oracle.rational(2, 3),
    @oracle.rational(-13, 2),
  ])
  assert_eq(
    coordinates(field, from_coordinates(field, supplied).unwrap()).unwrap(),
    supplied,
  )
  assert_true(from_coordinates(field, Nil) is Err(DimensionMismatch))
  assert_true(
    from_coordinates(
      field,
      @core.replicate(@oracle.nat(5), @exact.rational_zero()),
    )
    is Err(DimensionMismatch),
  )
}

///|
test "only supplied actual subgroups are accepted without generating closure" {
  let g = ff_quartic()
  for indices in [[], [1], [0, 2], [0, 2, 4], [0, 2, 3], [0, 8], [9]] {
    assert_true(prepare(g, ff_members(indices)) is Err(InvalidSubgroup))
  }
  let q = @aut.source(g)
  let c = ff_context([-2, 0, 1], 1, 2)
  let other = ff_alpha(c)
  let field = prepare(g, ff_members([0])).unwrap()
  assert_false(contains(field, other))
  assert_true(coordinates(field, other) is Err(DifferentField))
  assert_false(@cf.same_field(q, @cf.parent(other)))
}

///|
test "certificates reject omitted dependent nonfixed bases and forged matrices" {
  let g = ff_quartic()
  let f = @aut.source(g)
  let field = prepare(g, ff_members([0, 1, 4, 5])).unwrap()
  let p = certificate(field)
  let one = @cf.one(f)
  let identity = @matrix.matrix(
    @cf.degree(f),
    @core.replicate(
      @matrix.height(p.constraints),
      @core.replicate(@cf.degree(f), @exact.rational_zero()),
    ),
  ).unwrap()
  for
    forged in [
      { ..p, degree: @oracle.nat(1), },
      { ..p, degree: @oracle.nat(3), },
      { ..p, rank: Zero, },
      { ..p, basis: Cons(one, Nil), },
      { ..p, basis: @oracle.chain([one, one]), },
      { ..p, basis: @oracle.chain([one, ff_alpha(f)]), },
      { ..p, basis: Nil, degree: Zero, },
      { ..p, members: ff_members([0]), },
      { ..p, members: ff_members([5, 4, 1, 0]), },
      { ..p, members: ff_members([0, 0, 1, 4, 5]), },
      { ..p, actions: Nil, },
      { ..p, actions: @core.reverse(p.actions), },
      { ..p, constraints: identity, },
      { ..p, constraints: @matrix.transpose(p.constraints), },
      { ..p, group: { ..p.group, identity: @oracle.nat(1), }, },
      { ..p, group: { ..p.group, inverses: Nil, }, },
    ] {
    assert_false(check(g, forged))
    assert_false(check_result(g, field, forged))
    assert_true(from_certificate(g, forged) is Err(InvalidCertificate))
    assert_false(check_result(g, { group: g, proof: forged, }, p))
  }
  // A different independent spanning basis is a valid proof, but cannot be
  // substituted for the actual returned field's particular coordinate system.
  let alternative = { ..p, basis: @core.reverse(p.basis), }
  assert_true(check(g, alternative))
  assert_false(check_result(g, field, alternative))
  assert_true(
    check_result(g, from_certificate(g, alternative).unwrap(), alternative),
  )
}

///|
test "source and actual returned payload bind certificate validation" {
  let g = ff_quartic()
  let f = @aut.source(g)
  let field = prepare(g, ff_members([0, 1])).unwrap()
  let p = certificate(field)
  let alternate = prepare(g, ff_members([0, 3])).unwrap()
  assert_true(check(g, certificate(alternate)))
  assert_false(check_result(g, alternate, p))
  assert_false(check_result(g, field, certificate(alternate)))
  let c = ff_context([-2, 0, 1], 1, 2)
  let ca = ff_alpha(c)
  let other_group = @aut.prepare(c, @oracle.chain([ca, @cf.negate(ca)])).unwrap()
  let other = prepare(other_group, ff_members([0, 1])).unwrap()
  assert_false(check(other_group, p))
  assert_false(check(g, certificate(other)))
  assert_false(check(g, { ..p, source: c, }))
  assert_false(check(g, { ..p, group: @aut.certificate(other_group), }))
  assert_false(
    check(g, {
      ..p,
      basis: @oracle.chain([
        @cf.one(c),
        ca,
        @cf.imaginary_unit(c),
        @cf.multiply(ca, @cf.imaginary_unit(c)).unwrap(),
      ]),
    }),
  )
  assert_false(check_result(g, { group: other_group, proof: p, }, p))
  assert_false(check_result(other_group, field, p))
  // Root order is part of the actual numbered group, even in the same source.
  let reordered = @aut.prepare(f, @core.reverse(@aut.roots(g))).unwrap()
  assert_false(check(reordered, p))
  assert_false(check(g, { ..p, group: @aut.certificate(reordered), }))
  assert_false(check_result(g, { group: reordered, proof: p, }, p))
  // A conjugate real embedding has the same modulus and ambient dimension.
  let negative = ff_context([-2, 0, 0, 0, 1], -2, -1)
  let na = ff_alpha(negative)
  let nia = @cf.multiply(na, @cf.imaginary_unit(negative)).unwrap()
  let negative_group = @aut.prepare(
    negative,
    @oracle.chain([na, nia, @cf.negate(na), @cf.negate(nia)]),
  ).unwrap()
  let negative_field = prepare(negative_group, ff_members([0, 1])).unwrap()
  assert_true(check(negative_group, certificate(negative_field)))
  assert_false(check(g, certificate(negative_field)))
  assert_false(check(negative_group, p))
  assert_false(check(g, { ..p, source: negative, }))
  assert_false(contains(field, na))
  assert_true(coordinates(field, na) is Err(DifferentField))
  assert_true(@cf.same_field(f, p.source))
}
