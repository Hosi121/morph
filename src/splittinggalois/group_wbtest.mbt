///|
fn sg_poly(coefficients : Array[Int32]) -> @poly.Polynomial {
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
fn sg_budget() -> @split.Budget {
  {
    algebra: {
      attempts: @oracle.nat(12),
      work: @oracle.nat(3000),
      coordinate: @oracle.nat(1000),
      comparison: @oracle.nat(1000),
      primes: @oracle.chain([2, 3, 5, 7, 11, 13].map(@oracle.binary)),
      lift: @oracle.nat(100),
      subset: @oracle.nat(500),
      verification: @oracle.nat(500),
      realization: @oracle.nat(1000),
    },
    primitive: @oracle.nat(12),
  }
}

///|
fn sg_real_field(
  coefficients : Array[Int32],
  lower : Int32,
  upper : Int32,
) -> @cf.Field {
  let budget = sg_budget().algebra
  match
    @minimal.normalize_root(
      {
        polynomial: sg_poly(coefficients),
        interval: {
          lower: @oracle.rational(lower, 1),
          upper: @oracle.rational(upper, 1),
        },
      },
      budget.primes,
      budget.lift,
      budget.subset,
      budget.verification,
    ).unwrap() {
    @minimal.Normalized(value, proof) =>
      @cf.field(@nf.field_result(value, proof, budget.verification).unwrap())
    _ => abort("finite field fixture must normalize")
  }
}

///|
fn sg_split(
  polynomial : @poly.Polynomial,
  field : @cf.Field,
  roots : @core.Chain[@split.Root],
) -> @split.Splitting {
  match
    @split.solve_from_roots(polynomial, field, roots, sg_budget()).unwrap() {
    @split.Ready(value, _) => value
    _ => abort("finite supplied-root fixture must finish")
  }
}

///|
fn sg_group(source : @split.Splitting) -> Group {
  match advance(start(source).unwrap(), @oracle.nat(30)).unwrap() {
    Ready(group, _) => group
    _ => abort("finite group fixture must finish")
  }
}

///|
fn sg_unit_roots(field : @cf.Field) -> @core.Chain[@split.Root] {
  @oracle.chain([
    @split.Root::{
      value: @cf.imaginary_unit(field),
      multiplicity: @oracle.nat(1),
    },
    @split.Root::{
      value: @cf.negate(@cf.imaginary_unit(field)),
      multiplicity: @oracle.nat(1),
    },
  ])
}

///|
fn sg_quartic_split() -> @split.Splitting {
  let field = sg_real_field([-2, 0, 0, 0, 1], 1, 2)
  let real = @cf.real_field(field)
  let a = @cf.element(field, @nf.generator(real).unwrap(), @nf.zero(real)).unwrap()
  let ia = @cf.multiply(@cf.imaginary_unit(field), a).unwrap()
  sg_split(
    sg_poly([-2, 0, 0, 0, 1]),
    field,
    @oracle.chain(
      [a, @cf.negate(a), ia, @cf.negate(ia)].map(fn(value) {
        @split.Root::{ value, multiplicity: @oracle.nat(1), }
      }),
    ),
  )
}

///|
fn sg_by_permutation(group : Group, expected : Array[Int32]) -> Automorphism {
  for value in @oracle.array(automorphisms(group)) {
    if permutation(value).equal(@oracle.chain(expected.map(@oracle.nat))) {
      return value
    }
  }
  abort("expected root action missing")
}

///|
test "rational splitting fields produce one map including the empty permutation" {
  let field = sg_real_field([0, 1], -1, 0)
  for
    split in [
      sg_split(sg_poly([7]), field, Nil),
      sg_split(
        sg_poly([-1, 0, 1]),
        field,
        @oracle.chain(
          [@cf.one(field), @cf.negate(@cf.one(field))].map(fn(value) {
            @split.Root::{ value, multiplicity: @oracle.nat(1), }
          }),
        ),
      ),
    ] {
    let initial = start(split).unwrap()
    let paused = match advance(initial, Zero).unwrap() {
      Paused(next) => next
      _ => abort("zero trial budget must pause")
    }
    match advance(paused, @oracle.nat(1)).unwrap() {
      Ready(group, proof) => {
        assert_eq(@oracle.int_of_nat(order(group)), 1)
        assert_true(check_result(split, group, proof))
        assert_true(
          equal(identity(group), @oracle.array(automorphisms(group))[0]),
        )
        assert_true(
          @cf.equal(
            apply(identity(group), @cf.one(field)).unwrap(),
            @cf.one(field),
          ),
        )
        assert_true(
          apply(identity(group), @cf.imaginary_unit(field)) is Err(NotInField),
        )
      }
      _ => abort("one permutation proves a rational group complete")
    }
  }
}

///|
test "quadratic C2 uses exact minimal field action and resumes at the next trial" {
  let field = sg_real_field([0, 1], -1, 0)
  let split = sg_split(sg_poly([1, 0, 1]), field, sg_unit_roots(field))
  let state = match advance(start(split).unwrap(), @oracle.nat(1)).unwrap() {
    Paused(next) => next
    _ => abort("a quadratic group needs two maps")
  }
  let (group, proof) = match advance(state, @oracle.nat(1)).unwrap() {
    Ready(group, proof) => (group, proof)
    _ => abort("second permutation completes C2")
  }
  assert_true(check_result(split, group, proof))
  assert_eq(@oracle.int_of_nat(order(group)), 2)
  let conjugation = sg_by_permutation(group, [1, 0])
  assert_true(
    equal(compose(group, conjugation, conjugation).unwrap(), identity(group)),
  )
  assert_true(equal(inverse(group, conjugation).unwrap(), conjugation))
  assert_true(
    @cf.equal(
      apply(conjugation, @cf.imaginary_unit(field)).unwrap(),
      @cf.negate(@cf.imaginary_unit(field)),
    ),
  )
  let rebuilt = from_certificate(split, proof).unwrap()
  assert_true(check_result(split, rebuilt, proof))
}

///|
test "quartic D4 has eight sound maps and the defining dihedral relations" {
  let split = sg_quartic_split()
  let paused = match advance(start(split).unwrap(), @oracle.nat(3)).unwrap() {
    Paused(next) => next
    _ => abort("three permutation trials cannot finish D4")
  }
  assert_eq(@oracle.int_of_nat(@core.length(paused.maps)), 2)
  let group = match advance(paused, @oracle.nat(30)).unwrap() {
    Ready(group, _) => group
    _ => abort("remaining D4 search must finish")
  }
  let proof = certificate(group)
  assert_eq(@oracle.int_of_nat(order(group)), 8)
  assert_true(check_result(split, group, proof))
  // Root order a,-a,ia,-ia; r(a)=ia and s is complex conjugation.
  let r = sg_by_permutation(group, [2, 3, 1, 0])
  let s = sg_by_permutation(group, [0, 1, 3, 2])
  let rr = compose(group, r, r).unwrap()
  assert_true(equal(compose(group, rr, rr).unwrap(), identity(group)))
  assert_false(equal(rr, identity(group)))
  assert_true(equal(compose(group, s, s).unwrap(), identity(group)))
  assert_true(
    equal(
      compose(group, s, compose(group, r, s).unwrap()).unwrap(),
      inverse(group, r).unwrap(),
    ),
  )
  // This is a perfectly coherent cyclic group of order eight on the same
  // labels. The independent substitution checker must reject its table.
  let cyclic = @oracle.chain(
    [
      for a in 0..<8 => {
        @oracle.chain([ for b in 0..<8 => @oracle.nat((a + b) % 8) ])
      }
    ],
  )
  let cyclic_inverses = @oracle.chain(
    [
      for a in 0..<8 => @oracle.nat((8 - a) % 8)
    ],
  )
  assert_false(
    check(split, {
      ..proof,
      table: cyclic,
      identity: Zero,
      inverses: cyclic_inverses,
    }),
  )
  let roots = @oracle.array(@split.roots(split))
  let x = @cf.add(roots[0].value, roots[2].value).unwrap()
  let y = @cf.multiply(roots[0].value, roots[2].value).unwrap()
  for automorphism in @oracle.array(automorphisms(group)) {
    let inv = inverse(group, automorphism).unwrap()
    assert_true(
      equal(compose(group, inv, automorphism).unwrap(), identity(group)),
    )
    assert_true(
      equal(compose(group, automorphism, inv).unwrap(), identity(group)),
    )
    assert_true(
      @cf.equal(apply(inv, apply(automorphism, x).unwrap()).unwrap(), x),
    )
    assert_true(
      @cf.equal(
        apply(automorphism, @cf.add(x, y).unwrap()).unwrap(),
        @cf.add(
          apply(automorphism, x).unwrap(),
          apply(automorphism, y).unwrap(),
        ).unwrap(),
      ),
    )
    assert_true(
      @cf.equal(
        apply(automorphism, @cf.multiply(x, y).unwrap()).unwrap(),
        @cf.multiply(
          apply(automorphism, x).unwrap(),
          apply(automorphism, y).unwrap(),
        ).unwrap(),
      ),
    )
  }
}

///|
test "certificate checks reject malformed actions source and returned payloads" {
  let field = sg_real_field([0, 1], -1, 0)
  let split = sg_split(sg_poly([1, 0, 1]), field, sg_unit_roots(field))
  let group = sg_group(split)
  let proof = certificate(group)
  let maps = @oracle.array(proof.maps)
  let one = @oracle.nat(1)
  assert_false(check(split, { ..proof, maps: Nil, }))
  assert_false(check(split, { ..proof, maps: Cons(maps[0], Nil), }))
  assert_false(
    check(split, { ..proof, maps: @oracle.chain([maps[0], maps[0]]), }),
  )
  for
    bad in [
      { ..maps[0], permutation: Nil, },
      { ..maps[0], permutation: @oracle.chain([Zero, Zero]), },
      { ..maps[0], permutation: @oracle.chain([Zero, @oracle.nat(2)]), },
      { ..maps[0], permutation: maps[1].permutation, },
      { ..maps[0], image: @cf.zero(field), },
      { ..maps[0], image: maps[1].image, },
    ] {
    assert_false(
      check(split, { ..proof, maps: @oracle.chain([bad, maps[1]]), }),
    )
  }
  assert_false(check(split, { ..proof, identity: one, }))
  assert_false(check(split, { ..proof, table: Nil, }))
  assert_false(
    check(split, {
      ..proof,
      table: @oracle.chain([
        @oracle.chain([Zero, Zero]),
        @oracle.chain([Zero, Zero]),
      ]),
    }),
  )
  assert_false(check(split, { ..proof, inverses: Nil, }))
  assert_false(check(split, { ..proof, inverses: @oracle.chain([one, Zero]), }))
  assert_false(
    check(split, {
      ..proof,
      source: { ..proof.source, source: sg_poly([-1, 0, 1]), },
    }),
  )
  let alternative = sg_split(
    sg_poly([1, 0, 1]),
    field,
    @core.reverse(sg_unit_roots(field)),
  )
  assert_true(
    @split.check_result(
      @split.source(alternative),
      field,
      alternative,
      @split.certificate(alternative),
    ),
  )
  assert_false(check(alternative, proof))
  assert_false(
    check(split, { ..proof, source: @split.certificate(alternative), }),
  )
  assert_false(check_result(split, { ..group, source: alternative, }, proof))
  assert_false(
    check_result(split, { ..group, proof: { ..proof, maps: Nil, }, }, proof),
  )
  assert_false(
    check_result(split, { ..group, proof: { ..proof, table: Nil, }, }, proof),
  )
  let fake = Automorphism::{ source: split, map: maps[1], }
  assert_false(check_result(split, { ..group, identity: fake, }, proof))
  assert_true(
    compose(group, { ..fake, map: { ..fake.map, permutation: Nil, }, }, fake)
    is Err(NotMember),
  )
  assert_true(
    inverse(group, { ..fake, source: alternative, }) is Err(NotMember),
  )
  assert_true(
    from_certificate(split, { ..proof, table: Nil, }) is Err(InvalidCertificate),
  )
}
