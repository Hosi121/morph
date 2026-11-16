///|
fn ca_poly(coefficients : Array[(Int32, Int32)]) -> @poly.Polynomial {
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
fn ca_context(
  coefficients : Array[Int32],
  lower : (Int32, Int32),
  upper : (Int32, Int32),
) -> @cf.Field {
  let root = @real.number({
    polynomial: ca_poly(coefficients.map(fn(c) { (c, 1) })),
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
    _ => abort("automorphism test requires checked real minimum")
  }
}

///|
fn ca_sqrt2() -> @cf.Field {
  ca_context([-2, 0, 1], (1, 1), (2, 1))
}

///|
fn ca_element(
  field : @cf.Field,
  real : Array[(Int32, Int32)],
  imaginary : Array[(Int32, Int32)],
) -> @cf.Element {
  let k = @cf.real_field(field)
  @cf.element(
    field,
    @nf.element(k, ca_poly(real)).unwrap(),
    @nf.element(k, ca_poly(imaginary)).unwrap(),
  ).unwrap()
}

///|
fn ca_quartic_roots(field : @cf.Field) -> @core.Chain[@cf.Element] {
  let alpha = real_generator(field).unwrap()
  let ia = @cf.multiply(@cf.imaginary_unit(field), alpha).unwrap()
  @oracle.chain([alpha, @cf.negate(alpha), ia, @cf.negate(ia)])
}

///|
fn ca_table(
  values : Array[Array[Int32]],
) -> @core.Chain[@core.Chain[@core.Nat]] {
  @oracle.chain(values.map(fn(row) { @oracle.chain(row.map(@oracle.nat)) }))
}

///|
fn ca_abstract_laws(
  table : Array[Array[Int32]],
  identity : Int32,
  inverses : Array[Int32],
) -> Unit raise {
  for a in 0..<table.length() {
    assert_eq(table[identity][a], a)
    assert_eq(table[a][identity], a)
    assert_eq(table[a][inverses[a]], identity)
    assert_eq(table[inverses[a]][a], identity)
    for b in 0..<table.length() {
      for c in 0..<table.length() {
        assert_eq(table[table[a][b]][c], table[a][table[b][c]])
      }
    }
  }
}

///|
fn ca_validate(group : Group) -> Unit raise {
  let field = source(group)
  let maps = @oracle.array(automorphisms(group))
  let table = @oracle.array(composition_table(group))
    .map(@oracle.array)
    .map(fn(row) { row.map(@oracle.int_of_nat) })
  let proof = certificate(group)
  assert_eq(maps.length(), @oracle.int_of_nat(order(group)))
  assert_true(check(field, proof))
  assert_true(
    check_result(field, from_certificate(field, proof).unwrap(), proof),
  )
  ca_abstract_laws(
    table,
    @oracle.int_of_nat(proof.identity),
    @oracle.array(proof.inverses).map(@oracle.int_of_nat),
  )
  let a = ca_element(field, [(1, 2), (2, 3), (-3, 5), (4, 7)], [
    (5, 11),
    (-6, 13),
    (7, 17),
    (8, 19),
  ])
  let b = ca_element(field, [(-2, 7), (3, 5), (4, 3)], [(1, 2), (2, 1), (-3, 7)])
  let sum = @cf.add(a, b).unwrap()
  let product = @cf.multiply(a, b).unwrap()
  let alpha = real_generator(field).unwrap()
  let i = @cf.imaginary_unit(field)
  for index, map in maps {
    assert_true(
      @cf.equal(apply(map, @cf.zero(field)).unwrap(), @cf.zero(field)),
    )
    assert_true(@cf.equal(apply(map, @cf.one(field)).unwrap(), @cf.one(field)))
    assert_true(
      @cf.equal(
        apply(map, @cf.rational(field, @oracle.rational(7, 13))).unwrap(),
        @cf.rational(field, @oracle.rational(7, 13)),
      ),
    )
    assert_true(@cf.equal(apply(map, alpha).unwrap(), real_image(map)))
    assert_true(@cf.equal(apply(map, i).unwrap(), imaginary_image(map)))
    let ma = apply(map, a).unwrap()
    let mb = apply(map, b).unwrap()
    assert_true(@cf.equal(apply(map, sum).unwrap(), @cf.add(ma, mb).unwrap()))
    assert_true(
      @cf.equal(apply(map, product).unwrap(), @cf.multiply(ma, mb).unwrap()),
    )
    let inv = inverse(group, map).unwrap()
    assert_true(equal(compose(group, map, inv).unwrap(), identity(group)))
    assert_true(equal(compose(group, inv, map).unwrap(), identity(group)))
    assert_true(@cf.equal(apply(inv, ma).unwrap(), a))
    for j, other in maps {
      let composed = compose(group, map, other).unwrap()
      assert_true(equal(composed, maps[table[index][j]]))
      assert_true(
        @cf.equal(
          apply(composed, a).unwrap(),
          apply(map, apply(other, a).unwrap()).unwrap(),
        ),
      )
      if index != j {
        assert_false(equal(map, other))
      }
    }
  }
}

///|
test "QQ(i) has exactly identity and conjugation" {
  let field = ca_context([0, 1], (-1, 1), (0, 1))
  let supplied : @core.Chain[@cf.Element] = Cons(@cf.zero(field), Nil)
  let group = prepare(field, supplied).unwrap()
  assert_true(@cf.same_field(source(group), field))
  assert_true(same_roots(roots(group), supplied))
  assert_eq(order(group), @oracle.nat(2))
  assert_eq(composition_table(group), ca_table([[0, 1], [1, 0]]))
  let maps = @oracle.array(automorphisms(group))
  assert_true(equal(identity(group), maps[0]))
  assert_true(equal(conjugation(group), maps[1]))
  let value = ca_element(field, [(2, 3)], [(-4, 5)])
  assert_true(@cf.equal(apply(identity(group), value).unwrap(), value))
  assert_true(
    @cf.equal(apply(conjugation(group), value).unwrap(), @cf.conjugate(value)),
  )
  ca_validate(group)
}

///|
test "Gal(Q(sqrt2,i)/Q) is V4 with independent sign changes" {
  let field = ca_sqrt2()
  let alpha = real_generator(field).unwrap()
  let group = prepare(field, @oracle.chain([alpha, @cf.negate(alpha)])).unwrap()
  assert_eq(order(group), @oracle.nat(4))
  assert_eq(
    composition_table(group),
    ca_table([[0, 1, 2, 3], [1, 0, 3, 2], [2, 3, 0, 1], [3, 2, 1, 0]]),
  )
  for left in @oracle.array(automorphisms(group)) {
    assert_true(equal(compose(group, left, left).unwrap(), identity(group)))
    for right in @oracle.array(automorphisms(group)) {
      assert_true(
        equal(
          compose(group, left, right).unwrap(),
          compose(group, right, left).unwrap(),
        ),
      )
    }
  }
  ca_validate(group)
  let reordered = prepare(field, @oracle.chain([@cf.negate(alpha), alpha])).unwrap()
  assert_eq(certificate(reordered).identity, @oracle.nat(2))
  assert_eq(certificate(reordered).conjugation, @oracle.nat(3))
  assert_true(equal(identity(reordered), identity(group)))
  assert_false(check_result(field, group, certificate(reordered)))
  assert_false(check_result(field, reordered, certificate(group)))
  assert_true(check(field, certificate(reordered)))
}

///|
test "Gal(t4 minus two over Q) is D4 with left after right composition" {
  let field = ca_context([-2, 0, 0, 0, 1], (1, 1), (2, 1))
  let supplied = ca_quartic_roots(field)
  let group = prepare(field, supplied).unwrap()
  assert_eq(order(group), @oracle.nat(8))
  let maps = @oracle.array(automorphisms(group))
  let r = maps[4]
  let tau = conjugation(group)
  let r2 = compose(group, r, r).unwrap()
  let r3 = compose(group, r2, r).unwrap()
  assert_true(equal(r2, maps[2]))
  assert_true(equal(r3, maps[6]))
  assert_true(equal(compose(group, r3, r).unwrap(), identity(group)))
  assert_true(equal(compose(group, tau, tau).unwrap(), identity(group)))
  assert_true(
    equal(
      compose(group, compose(group, tau, r).unwrap(), tau).unwrap(),
      inverse(group, r).unwrap(),
    ),
  )
  let alpha = real_generator(field).unwrap()
  let ia = @cf.multiply(@cf.imaginary_unit(field), alpha).unwrap()
  // The supplied quartic roots generate i=ia/alpha, so this source really is
  // the minimal splitting field of t^4-2, not just a larger containing field.
  assert_true(
    @cf.equal(
      @cf.divide(ia, alpha).unwrap().unwrap(),
      @cf.imaginary_unit(field),
    ),
  )
  assert_true(@cf.equal(real_image(r), ia))
  assert_true(@cf.equal(imaginary_image(r), @cf.imaginary_unit(field)))
  assert_true(
    @cf.equal(apply(compose(group, r, tau).unwrap(), alpha).unwrap(), ia),
  )
  assert_true(
    @cf.equal(
      apply(compose(group, tau, r).unwrap(), alpha).unwrap(),
      @cf.negate(ia),
    ),
  )
  assert_false(
    equal(compose(group, r, tau).unwrap(), compose(group, tau, r).unwrap()),
  )
  let original = @oracle.array(supplied)
  for map in maps {
    let action = original.map(fn(root) { apply(map, root).unwrap() })
    for index, root in action {
      assert_true(original.any(fn(candidate) { @cf.equal(candidate, root) }))
      for j in 0..<index {
        assert_false(@cf.equal(action[j], root))
      }
    }
  }
  ca_validate(group)
}

///|
test "missing duplicate foreign and nonsplit cubic roots are rejected" {
  let field = ca_sqrt2()
  let alpha = real_generator(field).unwrap()
  let other = ca_context([-3, 0, 1], (1, 1), (2, 1))
  for
    supplied in [
      @core.Nil,
      @core.Cons(alpha, Nil),
      @oracle.chain([alpha, alpha]),
      @oracle.chain([alpha, @cf.one(field)]),
      @oracle.chain([alpha, @cf.negate(alpha), @cf.one(field)]),
      @oracle.chain([alpha, real_generator(other).unwrap()]),
    ] {
    assert_true(prepare(field, supplied) is Err(InvalidRoots))
  }
  let cubic = ca_context([-2, 0, 0, 1], (1, 1), (2, 1))
  let a = real_generator(cubic).unwrap()
  // Q(cuberoot(2),i) does not contain the other two cubic roots. These plausible
  // supplied candidates must fail exact annihilation, not count as a splitting.
  let candidates = @oracle.chain([
    a,
    @cf.negate(a),
    @cf.multiply(@cf.imaginary_unit(cubic), a).unwrap(),
  ])
  assert_true(prepare(cubic, candidates) is Err(InvalidRoots))
  assert_true(prepare(cubic, Cons(a, Nil)) is Err(InvalidRoots))
}

///|
test "certificate checker rejects swapped images indices and tables despite abstract group laws" {
  let field = ca_sqrt2()
  let alpha = real_generator(field).unwrap()
  let group = prepare(field, @oracle.chain([alpha, @cf.negate(alpha)])).unwrap()
  let p = certificate(group)
  let images = @oracle.array(p.images)
  let swapped : Image = {
    real: images[0].imaginary,
    imaginary: images[0].real,
  }
  let cyclic_table = [[0, 1, 2, 3], [1, 2, 3, 0], [2, 3, 0, 1], [3, 0, 1, 2]]
  let cyclic_inverses = [0, 3, 2, 1]
  ca_abstract_laws(cyclic_table, 0, cyclic_inverses)
  let coherent_abstract_forgery : Certificate = {
    ..p,
    table: ca_table(cyclic_table),
    inverses: @oracle.chain(cyclic_inverses.map(@oracle.nat)),
  }
  for
    forged in [
      { ..p, roots: Nil, },
      { ..p, roots: @oracle.chain([alpha, alpha]), },
      { ..p, roots: @oracle.chain([alpha, @cf.one(field)]), },
      { ..p, images: Nil, },
      {
        ..p,
        images: @oracle.chain([swapped, images[1], images[2], images[3]]),
      },
      {
        ..p,
        images: @oracle.chain([images[1], images[0], images[2], images[3]]),
      },
      { ..p, images: @oracle.chain([images[0], images[1], images[2]]), },
      { ..p, table: Nil, },
      { ..p, table: ca_table([[0, 1, 2, 3], [1, 0, 3, 2], [2, 3, 0, 1]]), },
      {
        ..p,
        table: ca_table([[0, 1, 2, 3], [1, 0, 3, 2], [2, 3, 0, 1], [3, 2, 1, 9]]),
      },
      { ..p, identity: @oracle.nat(1), },
      { ..p, conjugation: @oracle.nat(2), },
      { ..p, conjugation: @oracle.nat(4), },
      { ..p, inverses: Nil, },
      {
        ..p,
        inverses: @oracle.chain([
          @oracle.nat(0),
          @oracle.nat(2),
          @oracle.nat(1),
          @oracle.nat(3),
        ]),
      },
      coherent_abstract_forgery,
    ] {
    assert_false(check(field, forged))
    assert_true(from_certificate(field, forged) is Err(InvalidCertificate))
    assert_false(check_result(field, group, forged))
  }
  assert_false(
    check_result(field, { ..group, identity: conjugation(group), }, p),
  )
  assert_false(
    check_result(field, { ..group, conjugation: identity(group), }, p),
  )
  let not_member : Automorphism = {
    field,
    images: { real: @cf.one(field), imaginary: @cf.imaginary_unit(field), },
  }
  assert_true(compose(group, identity(group), not_member) is Err(NotMember))
  assert_true(inverse(group, not_member) is Err(NotMember))
}

///|
test "source and payload swaps and all cross context operations reject" {
  let field = ca_sqrt2()
  let alpha = real_generator(field).unwrap()
  let group = prepare(field, @oracle.chain([alpha, @cf.negate(alpha)])).unwrap()
  let p = certificate(group)
  for
    other in [
      ca_context([-2, 0, 1], (-2, 1), (-1, 1)),
      ca_context([-2, 0, 1], (7, 5), (3, 2)),
      ca_context([-3, 0, 1], (1, 1), (2, 1)),
    ] {
    let beta = real_generator(other).unwrap()
    let other_group = prepare(other, @oracle.chain([beta, @cf.negate(beta)])).unwrap()
    let q = certificate(other_group)
    assert_true(check(other, q))
    assert_false(check(field, q))
    assert_false(check(other, p))
    assert_false(check(field, { ..p, source: other, }))
    assert_false(check_result(field, other_group, p))
    assert_false(check_result(field, group, q))
    assert_false(check_result(other, group, p))
    assert_false(equal(identity(group), identity(other_group)))
    assert_true(apply(identity(group), @cf.zero(other)) is Err(DifferentField))
    assert_true(
      compose(group, identity(other_group), identity(group))
      is Err(DifferentField),
    )
    assert_true(
      compose(group, identity(group), identity(other_group))
      is Err(DifferentField),
    )
    assert_true(inverse(group, identity(other_group)) is Err(DifferentField))
    let malformed : Automorphism = {
      ..identity(group),
      images: { real: beta, imaginary: @cf.imaginary_unit(field), },
    }
    assert_false(equal(malformed, malformed))
    assert_true(apply(malformed, @cf.one(field)) is Err(DifferentField))
    assert_false(
      check_result(field, { ..group, identity: identity(other_group), }, p),
    )
  }
}
