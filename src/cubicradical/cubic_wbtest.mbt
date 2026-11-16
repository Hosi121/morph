///|
fn test_poly(values : Array[(Int32, Int32)]) -> @poly.Polynomial {
  @poly.polynomial(
    @oracle.nat(1),
    @oracle.chain(
      [
        for i in 0..<values.length() => {
          @poly.Term::{
            coefficient: @oracle.rational(values[i].0, values[i].1),
            exponents: Cons(@oracle.nat(i), Nil),
          }
        }
      ],
    ),
  ).unwrap()
}

///|
fn test_source(q : (Int32, Int32), scale : (Int32, Int32)) -> @poly.Polynomial {
  test_poly([(-q.0 * scale.0, q.1 * scale.1), (0, 1), (0, 1), scale])
}

///|
fn test_budget() -> @comp.Budget {
  {
    attempts: @oracle.nat(6),
    work: @oracle.nat(1024),
    coordinate: @oracle.nat(128),
    comparison: @oracle.nat(128),
    primes: @oracle.chain([2, 3, 5, 7, 11, 13, 17, 19].map(@oracle.binary)),
    lift: @oracle.nat(40),
    subset: @oracle.nat(512),
    verification: @oracle.nat(512),
    realization: @oracle.nat(128),
  }
}

///|
fn test_compose(source : @poly.Polynomial) -> (Common, Certificate) {
  match compose(source, test_budget()).unwrap() {
    Ready(value, proof) => (value, proof)
    _ => abort("small binomial cubic unresolved")
  }
}

///|
fn assert_field_roots(source : @poly.Polynomial, value : Common) -> Unit raise {
  let values = @oracle.array(roots(value))
  assert_eq(values.length(), 3)
  for root in values {
    assert_true(@cf.is_zero(@cf.evaluate_polynomial(root, source).unwrap()))
  }
  assert_false(@cf.equal(values[0], values[1]))
  assert_false(@cf.equal(values[0], values[2]))
  assert_false(@cf.equal(values[1], values[2]))
  assert_true(@cf.equal(@cf.conjugate(values[1]), values[2]))
  assert_true(@nf.is_zero(@cf.imaginary_part(values[0])))
  let sum = @cf.add(@cf.add(values[0], values[1]).unwrap(), values[2]).unwrap()
  assert_true(@cf.is_zero(sum))
}

///|
test "eligibility rejects zero radicands malformed cubics and wrong dimensions" {
  for
    source in [
      test_poly([(0, 1), (0, 1), (0, 1), (1, 1)]),
      test_poly([(-2, 1), (1, 1), (0, 1), (1, 1)]),
      test_poly([(-2, 1), (0, 1), (1, 1)]),
      test_poly([(-2, 1)]),
      @poly.zero(@oracle.nat(1)),
      @poly.zero(@oracle.nat(2)),
    ] {
    assert_false(eligible(source))
    assert_true(start(source) is Err(Ineligible))
  }
  assert_true(eligible(test_source((2, 1), (-7, 3))))
}

///|
test "positive and negative cube roots produce three exact roots in degree twelve ambient fields" {
  for q in [(2, 1), (-2, 1)] {
    let source = test_source(q, (1, 1))
    let (value, proof) = test_compose(source)
    assert_eq(@cf.degree(common_field(value)), @oracle.nat(12))
    assert_eq(proof.radicand, @oracle.rational(q.0, q.1))
    assert_eq(
      check_result(source, value, proof, @oracle.nat(512)),
      @zass.Proven,
    )
    assert_eq(
      check_result(source, value, certificate(value), @oracle.nat(512)),
      @zass.Proven,
    )
    assert_eq(check(source, proof, Zero), @zass.Undecided)
    assert_field_roots(source, value)
  }
}

///|
test "rational cubes and nonmonic scaled sources preserve exact source binding" {
  for
    (q, scale, real_root) in [
      ((1, 1), (1, 1), (1, 1)),
      ((-1, 1), (1, 1), (-1, 1)),
      ((1, 8), (1, 1), (1, 2)),
      ((1, 8), (-7, 3), (1, 2)),
    ] {
    let source = test_source(q, scale)
    let (value, proof) = test_compose(source)
    assert_eq(@cf.degree(common_field(value)), @oracle.nat(4))
    assert_eq(proof.scale, @oracle.rational(scale.0, scale.1))
    assert_eq(proof.radicand, @oracle.rational(q.0, q.1))
    assert_eq(
      check_result(source, value, proof, @oracle.nat(512)),
      @zass.Proven,
    )
    let values = @oracle.array(roots(value))
    assert_true(
      @cf.equal(
        values[0],
        @cf.rational(
          common_field(value),
          @oracle.rational(real_root.0, real_root.1),
        ),
      ),
    )
    assert_field_roots(source, value)
    if scale != (1, 1) {
      assert_eq(
        check(@poly.monic(source), proof, @oracle.nat(512)),
        @zass.Refuted,
      )
    }
  }
}

///|
test "pauses retain isolated real cube roots through merge retries" {
  let source = test_source((2, 1), (1, 1))
  let budget = test_budget()
  let isolation = match
    compose(source, { ..budget, coordinate: Zero, }).unwrap() {
    Paused(search, IsolationBudget) => search
    _ => abort("expected isolation pause")
  }
  let pending = match
    advance(isolation, { ..budget, attempts: Zero, }).unwrap() {
    Paused(search, MergeBudget(_)) => search
    _ => abort("expected merge pause")
  }
  let alpha = match pending.phase {
    Merging(alpha) => @real.root_certificate(alpha)
    _ => abort("isolated cube root lost")
  }
  let (value, proof) = match advance(pending, budget).unwrap() {
    Ready(value, proof) => (value, proof)
    _ => abort("merge retry unresolved")
  }
  assert_eq(alpha, proof.cube_root)
  assert_eq(check_result(source, value, proof, @oracle.nat(512)), @zass.Proven)
  assert_field_roots(source, value)
}

///|
test "source root context composition formula and payload attacks are rejected" {
  let source = test_source((1, 1), (1, 1))
  let (value, proof) = test_compose(source)
  let (other, other_proof) = test_compose(test_source((-1, 1), (1, 1)))
  let fuel = @oracle.nat(512)
  assert_eq(check(test_source((-1, 1), (1, 1)), proof, fuel), @zass.Refuted)
  assert_eq(
    check(source, { ..proof, source: test_source((1, 1), (2, 1)), }, fuel),
    @zass.Refuted,
  )
  assert_eq(
    check(source, { ..proof, scale: @oracle.rational(2, 1), }, fuel),
    @zass.Refuted,
  )
  assert_eq(
    check(source, { ..proof, radicand: @oracle.rational(-1, 1), }, fuel),
    @zass.Refuted,
  )
  assert_eq(
    check(source, { ..proof, cube_root: other_proof.cube_root, }, fuel),
    @zass.Refuted,
  )
  assert_eq(
    check(source, { ..proof, common: other_proof.common, }, fuel),
    @zass.Refuted,
  )
  assert_eq(
    check(source, { ..proof, composition: other_proof.composition, }, fuel),
    @zass.Refuted,
  )
  assert_eq(
    check(source, { ..proof, field: common_field(other), }, fuel),
    @zass.Refuted,
  )
  assert_eq(
    check(source, { ..proof, roots: @core.reverse(proof.roots), }, fuel),
    @zass.Refuted,
  )
  assert_eq(
    check_result(
      source,
      { ..value, values: @core.reverse(value.values), },
      proof,
      fuel,
    ),
    @zass.Refuted,
  )
  assert_eq(
    check_result(source, { ..value, field: common_field(other), }, proof, fuel),
    @zass.Refuted,
  )
  assert_eq(check_result(source, other, proof, fuel), @zass.Refuted)
  let values = @oracle.array(proof.roots)
  values[1] = values[0]
  assert_eq(
    check(source, { ..proof, roots: @oracle.chain(values), }, fuel),
    @zass.Refuted,
  )
  assert_eq(
    check_result(source, { ..value, values: Nil, }, proof, fuel),
    @zass.Refuted,
  )
  let composition = proof.composition
  assert_eq(
    check(
      source,
      {
        ..proof,
        composition: {
          ..composition,
          right_embedding: composition.left_embedding,
        },
      },
      fuel,
    ),
    @zass.Refuted,
  )
  let root = proof.cube_root
  assert_eq(
    check(
      source,
      {
        ..proof,
        cube_root: {
          ..root,
          interval: {
            lower: @oracle.rational(-2, 1),
            upper: @oracle.rational(-1, 1),
          },
        },
      },
      fuel,
    ),
    @zass.Refuted,
  )
}
