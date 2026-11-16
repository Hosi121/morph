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
fn test_root(
  values : Array[(Int32, Int32)],
  lower : (Int32, Int32),
  upper : (Int32, Int32),
) -> @real.Number {
  @real.number({
    polynomial: test_poly(values),
    interval: {
      lower: @oracle.rational(lower.0, lower.1),
      upper: @oracle.rational(upper.0, upper.1),
    },
  }).unwrap()
}

///|
fn test_sqrt(n : Int32, negative : Bool) -> @real.Number {
  test_root(
    [(-n, 1), (0, 1), (1, 1)],
    if negative {
      (-n, 1)
    } else {
      (0, 1)
    },
    if negative {
      (0, 1)
    } else {
      (n, 1)
    },
  )
}

///|
fn test_budget() -> Budget {
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
fn test_compose(a : @real.Number, b : @real.Number) -> (Common, Certificate) {
  match compose(a, b, test_budget()).unwrap() {
    Composed(value, proof) => (value, proof)
    _ => abort("small compositum unresolved")
  }
}

///|
fn assert_equivalent(a : @real.Number, b : @real.Number) -> Unit raise {
  match @real.compare(a, b, @oracle.nat(128)).unwrap() {
    @real.Compared(order, proof) => {
      assert_eq(order, Equal)
      assert_true(@real.check_comparison_result(order, proof))
    }
    _ => fail("exact equality unresolved")
  }
}

///|
fn assert_mapping(input : @real.Number, value : @nf.Element) -> Unit raise {
  match @nf.realize(value, @oracle.nat(128)).unwrap() {
    @nf.RealReady(number, proof) => {
      assert_true(@nf.check_realization_result(value, number, proof))
      assert_equivalent(input, number)
    }
    _ => fail("common-field real image unresolved")
  }
}

///|
test "independent square roots share a primitive quartic field with checked maps" {
  let a = test_sqrt(2, false)
  let b = test_sqrt(3, false)
  let (value, proof) = test_compose(a, b)
  let f = common_field(value)
  let x = left_element(value)
  let y = right_element(value)
  assert_eq(@nf.degree(f), @oracle.nat(4))
  assert_eq(
    @nf.modulus(f),
    test_poly([(1, 1), (0, 1), (-10, 1), (0, 1), (1, 1)]),
  )
  assert_eq(@oracle.int_of_binary(proof.separation.augmentation.seed), 1)
  assert_true(
    @nf.equal(
      @nf.multiply(x, x).unwrap(),
      @nf.rational(f, @oracle.rational(2, 1)),
    ),
  )
  assert_true(
    @nf.equal(
      @nf.multiply(y, y).unwrap(),
      @nf.rational(f, @oracle.rational(3, 1)),
    ),
  )
  assert_eq(check_result(a, b, value, proof, @oracle.nat(512)), @zass.Proven)
  assert_mapping(a, x)
  assert_mapping(b, y)
  assert_eq(@oracle.array(proof.selection).length(), 4)
}

///|
test "dependent opposite and identical square roots reduce the Cartesian eliminant" {
  let a = test_sqrt(2, false)
  for b in [a, test_sqrt(2, true)] {
    let (value, proof) = test_compose(a, b)
    let f = common_field(value)
    assert_eq(@nf.degree(f), @oracle.nat(2))
    assert_eq(@oracle.int_of_binary(proof.separation.augmentation.seed), 2)
    assert_eq(@oracle.array(proof.selection).length(), 4)
    assert_eq(check_result(a, b, value, proof, @oracle.nat(512)), @zass.Proven)
    if @real.interval(b).upper.equal(@oracle.rational(0, 1)) {
      assert_true(
        @nf.equal(left_element(value), @nf.negate(right_element(value))),
      )
    } else {
      assert_true(@nf.equal(left_element(value), right_element(value)))
    }
    assert_mapping(a, left_element(value))
    assert_mapping(b, right_element(value))
  }
}

///|
test "rational constants and zero produce Q or the existing quadratic field" {
  let zero = @real.rational(@oracle.rational(0, 1)).unwrap()
  let half = @real.rational(@oracle.rational(1, 2)).unwrap()
  for
    (a, b, dimension) in [
      (zero, half, 1),
      (test_sqrt(2, false), half, 2),
      (zero, test_sqrt(2, false), 2),
    ] {
    let (value, proof) = test_compose(a, b)
    assert_eq(@nf.degree(common_field(value)), @oracle.nat(dimension))
    assert_eq(check_result(a, b, value, proof, @oracle.nat(512)), @zass.Proven)
    assert_mapping(a, left_element(value))
    assert_mapping(b, right_element(value))
  }
}

///|
test "source binding and public result payload reject conjugates and mixed fields" {
  let a = test_sqrt(2, false)
  let b = test_sqrt(3, false)
  let (value, p) = test_compose(a, b)
  assert_eq(
    check_result(test_sqrt(2, true), b, value, p, @oracle.nat(512)),
    @zass.Refuted,
  )
  assert_eq(check_result(b, a, value, p, @oracle.nat(512)), @zass.Refuted)
  assert_eq(
    check(
      a,
      b,
      { ..p, left: @real.root_certificate(test_sqrt(2, true)), },
      @oracle.nat(512),
    ),
    @zass.Refuted,
  )
  assert_eq(
    check(a, b, { ..p, selected: @oracle.nat(99), }, @oracle.nat(512)),
    @zass.Refuted,
  )
  assert_eq(
    check(a, b, { ..p, selection: Nil, }, @oracle.nat(512)),
    @zass.Refuted,
  )
  let rows = @oracle.array(p.selection)
  assert_eq(
    check(
      a,
      b,
      { ..p, selection: @core.reverse(p.selection), },
      @oracle.nat(512),
    ),
    @zass.Refuted,
  )
  let row = rows[0]
  let fake_rows = rows.copy()
  fake_rows[0] = {
    ..row,
    left_comparison: { ..row.left_comparison, order: Equal, },
    right_comparison: { ..row.right_comparison, order: Equal, },
  }
  assert_eq(
    check(a, b, { ..p, selection: @oracle.chain(fake_rows), }, @oracle.nat(512)),
    @zass.Refuted,
  )
  assert_eq(
    check(
      a,
      b,
      { ..p, left_equality: { ..p.left_equality, order: Less, }, },
      @oracle.nat(512),
    ),
    @zass.Refuted,
  )
  assert_eq(
    check(a, b, { ..p, left_embedding: p.right_embedding, }, @oracle.nat(512)),
    @zass.Refuted,
  )
  let (opposite, _) = test_compose(test_sqrt(2, true), test_sqrt(3, true))
  assert_eq(@nf.modulus(value.field), @nf.modulus(opposite.field))
  assert_eq(@nf.representative(value.left), @nf.representative(opposite.left))
  assert_false(@nf.same_field(value.field, opposite.field))
  assert_eq(
    check_result(a, b, { ..value, left: opposite.left, }, p, @oracle.nat(512)),
    @zass.Refuted,
  )
  let augmentation = p.separation.augmentation
  let wrong_source = @variety.ProblemDescription::{
    ..augmentation.source,
    inputs: @core.reverse(augmentation.source.inputs),
  }
  let wrong_problem = @variety.SeparationCertificate::{
    ..p.separation,
    augmentation: { ..augmentation, source: wrong_source, },
  }
  assert_eq(
    check(a, b, { ..p, separation: wrong_problem, }, @oracle.nat(512)),
    @zass.Refuted,
  )
  assert_eq(
    check(
      a,
      b,
      {
        ..p,
        separation: {
          ..p.separation,
          augmentation: { ..augmentation, seed: @oracle.binary(2), },
        },
      },
      @oracle.nat(512),
    ),
    @zass.Refuted,
  )
  assert_eq(
    check(
      a,
      b,
      { ..p, selection: @core.take(@oracle.nat(3), p.selection), },
      @oracle.nat(512),
    ),
    @zass.Refuted,
  )
  let (other, _) = test_compose(a, a)
  let mixed = Common::{ ..value, left: left_element(other), }
  assert_eq(check_result(a, b, mixed, p, @oracle.nat(512)), @zass.Refuted)
  assert_eq(
    check_result(
      a,
      b,
      { ..value, left: @nf.zero(value.field), },
      p,
      @oracle.nat(512),
    ),
    @zass.Refuted,
  )
  assert_eq(
    check_result(a, b, { ..value, field: other.field, }, p, @oracle.nat(512)),
    @zass.Refuted,
  )
}

///|
test "same algebraic number with a different nonminimal definition still shares degree two" {
  let a = test_root([(6, 1), (-2, 1), (-3, 1), (1, 1)], (1, 1), (2, 1)) // (x^2-2)(x-3)
  let b = test_sqrt(2, false)
  let (value, proof) = test_compose(a, b)
  assert_eq(@nf.degree(common_field(value)), @oracle.nat(2))
  assert_true(@nf.equal(left_element(value), right_element(value)))
  assert_eq(@oracle.array(proof.selection).length(), 6)
  assert_eq(check_result(a, b, value, proof, @oracle.nat(512)), @zass.Proven)
  assert_mapping(a, left_element(value))
  assert_mapping(b, right_element(value))
}

///|
test "cubic and quadratic independent generators share a sextic field" {
  let a = test_root([(-2, 1), (0, 1), (0, 1), (1, 1)], (1, 1), (2, 1))
  let b = test_sqrt(2, false)
  let (value, proof) = test_compose(a, b)
  assert_eq(@nf.degree(common_field(value)), @oracle.nat(6))
  assert_eq(check_result(a, b, value, proof, @oracle.nat(512)), @zass.Proven)
  assert_mapping(a, left_element(value))
  assert_mapping(b, right_element(value))
}

///|
test "stage budget exhaustion never produces a common field claim" {
  let a = test_sqrt(2, false)
  let b = test_sqrt(3, false)
  let budget = test_budget()
  match compose(a, b, { ..budget, attempts: Zero, }).unwrap() {
    Unresolved(SeparationBudget(@variety.AttemptLimit)) => ()
    _ => fail("zero separating attempts")
  }
  match compose(a, b, { ..budget, work: Zero, }).unwrap() {
    Unresolved(SeparationBudget(@variety.ComputationFuel)) => ()
    _ => fail("zero F4/isolation work")
  }
  match compose(a, b, { ..budget, coordinate: Zero, }).unwrap() {
    Unresolved(CoordinateBudget) => ()
    _ => fail("zero coordinate work")
  }
  match compose(a, b, { ..budget, primes: Nil, }).unwrap() {
    Unresolved(MinimalBudget(@minimal.NoGoodPrime)) => ()
    _ => fail("no good prime")
  }
  match compose(a, b, { ..budget, lift: Zero, }).unwrap() {
    Unresolved(MinimalBudget(@minimal.LiftBudget)) => ()
    _ => fail("zero Hensel work")
  }
  match compose(a, a, { ..budget, subset: Zero, }).unwrap() {
    Unresolved(MinimalBudget(@minimal.SubsetBudget)) => ()
    _ => fail("zero subset work")
  }
  match compose(a, a, { ..budget, verification: Zero, }).unwrap() {
    Unresolved(MinimalBudget(@minimal.VerificationBudget)) => ()
    _ => fail("zero irreducibility verification work")
  }
  match compose(a, b, { ..budget, realization: Zero, }).unwrap() {
    Unresolved(RealizationBudget) => ()
    _ => fail("zero final embedding work")
  }
  let wide = test_root([(-2, 1), (0, 1), (1, 1)], (-7, 5), (2, 1))
  match compose(wide, b, { ..budget, comparison: Zero, }).unwrap() {
    Unresolved(ComparisonBudget) => ()
    _ => fail("overlapping conjugate enclosure requires comparison work")
  }
  let (value, proof) = test_compose(a, a)
  assert_eq(check_result(a, a, value, proof, Zero), @zass.Undecided)
}

///|
fn assert_compositum_fixture(
  a : Array[(Int32, Int32)],
  alower : (Int32, Int32),
  aupper : (Int32, Int32),
  b : Array[(Int32, Int32)],
  blower : (Int32, Int32),
  bupper : (Int32, Int32),
  dimension : Int32,
  expected : Array[
    (Int32, Array[(Int32, Int32)], Array[(Int32, Int32)], Array[(Int32, Int32)]),
  ],
) -> Unit raise {
  let left = test_root(a, alower, aupper)
  let right = test_root(b, blower, bupper)
  let (value, proof) = test_compose(left, right)
  let field = common_field(value)
  assert_eq(@nf.degree(field), @oracle.nat(dimension))
  let seed = @oracle.int_of_binary(proof.separation.augmentation.seed)
  let mut found = false
  for (s, m, hx, hy) in expected {
    if seed == s {
      found = true
      assert_eq(@nf.modulus(field), test_poly(m))
      assert_eq(@nf.representative(left_element(value)), test_poly(hx))
      assert_eq(@nf.representative(right_element(value)), test_poly(hy))
    }
  }
  assert_true(found)
  assert_eq(
    check_result(left, right, value, proof, @oracle.nat(512)),
    @zass.Proven,
  )
  assert_mapping(left, left_element(value))
  assert_mapping(right, right_element(value))
}
