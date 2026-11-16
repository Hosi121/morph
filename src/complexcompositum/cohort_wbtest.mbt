///|
fn test_poly(values : Array[Int32]) -> @poly.Polynomial {
  @poly.polynomial(
    @oracle.nat(1),
    @oracle.chain(
      [
        for i in 0..<values.length() => {
          @poly.Term::{
            coefficient: @oracle.rational(values[i], 1),
            exponents: Cons(@oracle.nat(i), Nil),
          }
        }
      ],
    ),
  ).unwrap()
}

///|
fn test_root(
  values : Array[Int32],
  lower : Int32,
  upper : Int32,
) -> @real.Number {
  @real.number({
    polynomial: test_poly(values),
    interval: {
      lower: @oracle.rational(lower, 1),
      upper: @oracle.rational(upper, 1),
    },
  }).unwrap()
}

///|
fn test_sqrt(n : Int32) -> @real.Number {
  test_root([-n, 0, 1], 1, n)
}

///|
fn test_rational(n : Int32) -> @real.Number {
  @real.rational(@oracle.rational(n, 1)).unwrap()
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
fn test_compose(inputs : @core.Chain[@cx.Number]) -> (Common, Certificate) {
  match compose(inputs, test_budget()).unwrap() {
    Ready(value, proof) => (value, proof)
    Paused(_, _) => abort("small ambient cohort unresolved")
  }
}

///|
test "empty and Gaussian rational cohorts use the degree two ambient field" {
  let (empty, empty_proof) = test_compose(Nil)
  assert_eq(@cf.degree(common_field(empty)), @oracle.nat(2))
  assert_true(elements(empty) is Nil)
  assert_eq(
    check_result(Nil, empty, empty_proof, @oracle.nat(512)),
    @zass.Proven,
  )
  let inputs = @oracle.chain([
    @cx.rational(@oracle.rational(2, 1), @oracle.rational(-3, 1)).unwrap(),
    @cx.rational(@oracle.rational(0, 1), @oracle.rational(1, 1)).unwrap(),
  ])
  let (value, proof) = test_compose(inputs)
  assert_eq(@cf.degree(common_field(value)), @oracle.nat(2))
  assert_true(@core.all(proof.steps, fn(step) { step is Rational(_) }))
  assert_eq(check_result(inputs, value, proof, @oracle.nat(512)), @zass.Proven)
  let values = @oracle.array(elements(value))
  let field = @cf.real_field(common_field(value))
  assert_true(
    @nf.equal(
      @cf.real_part(values[0]),
      @nf.rational(field, @oracle.rational(2, 1)),
    ),
  )
  assert_true(
    @nf.equal(
      @cf.imaginary_part(values[0]),
      @nf.rational(field, @oracle.rational(-3, 1)),
    ),
  )
}

///|
test "selected nonminimal roots normalize once and exact duplicates reuse ordered coordinates" {
  // (x^2-2)(x-3), selecting sqrt(2), is not already a minimal definition.
  let a = test_root([6, -2, -3, 1], 1, 2)
  let z = @cx.number(a, test_rational(1))
  let r = @cx.number(a, test_rational(0))
  for inputs in [@oracle.chain([z, r, z]), @oracle.chain([r, z])] {
    let (value, proof) = test_compose(inputs)
    assert_eq(@nf.degree(@cf.real_field(common_field(value))), @oracle.nat(2))
    assert_eq(
      check_result(inputs, value, proof, @oracle.nat(512)),
      @zass.Proven,
    )
    assert_eq(check(inputs, proof, Zero), @zass.Undecided)
    assert_eq(
      @oracle.array(
        @core.filter(proof.steps, fn(step) { step is Normalize(_) }),
      ).length(),
      1,
    )
    assert_eq(
      @oracle.array(@core.filter(proof.steps, fn(step) { step is Merge(_, _) })).length(),
      0,
    )
    assert_true(
      @oracle.array(@core.filter(proof.steps, fn(step) { step is Reuse(_) })).length() >=
      1,
    )
    let first = @oracle.array(elements(value))[0]
    let field = @cf.real_field(common_field(value))
    assert_true(
      @nf.equal(
        @nf.multiply(@cf.real_part(first), @cf.real_part(first)).unwrap(),
        @nf.rational(field, @oracle.rational(2, 1)),
      ),
    )
    let steps = @oracle.array(proof.steps)
    match steps[0] {
      Normalize(normalization) => {
        steps[0] = Normalize({ ..normalization, input: normalization.result, })
        assert_eq(
          check(
            inputs,
            { ..proof, steps: @oracle.chain(steps), },
            @oracle.nat(512),
          ),
          @zass.Refuted,
        )
      }
      _ => fail("expected nonminimal source normalization")
    }
  }
}

///|
test "nonminimal rational coordinates preserve constants across two normalizations" {
  let one = test_root([-1, 0, 1], 0, 1)
  let inputs = @oracle.chain([
    @cx.number(test_rational(7), one),
    @cx.number(test_sqrt(2), test_rational(0)),
  ])
  let (value, proof) = test_compose(inputs)
  let field = @cf.real_field(common_field(value))
  assert_eq(@nf.degree(field), @oracle.nat(2))
  assert_eq(check_result(inputs, value, proof, @oracle.nat(512)), @zass.Proven)
  let first = @oracle.array(elements(value))[0]
  assert_true(
    @nf.equal(@cf.real_part(first), @nf.rational(field, @oracle.rational(7, 1))),
  )
  assert_true(@nf.equal(@cf.imaginary_part(first), @nf.one(field)))
  assert_eq(
    @oracle.array(@core.filter(proof.steps, fn(step) { step is Normalize(_) })).length(),
    2,
  )
}

///|
test "pause retains rational prefix and initialization survives retry" {
  let input = @cx.number(test_rational(7), test_sqrt(2))
  let inputs : @core.Chain[@cx.Number] = Cons(input, Nil)
  let budget = test_budget()
  let pending = match
    compose(inputs, { ..budget, primes: Cons(@oracle.binary(2), Nil), }).unwrap() {
    Paused(build, NormalizationBudget(@minimal.NoGoodPrime)) => build
    _ => abort("expected normalization pause after rational prefix")
  }
  assert_eq(completed_coordinates(pending), @oracle.nat(1))
  let initial = pending.initial.unwrap()
  let (value, proof) = match advance(pending, budget).unwrap() {
    Ready(value, proof) => (value, proof)
    _ => abort("retry failed")
  }
  assert_eq(initial, proof.initial)
  assert_eq(check_result(inputs, value, proof, @oracle.nat(512)), @zass.Proven)
}

///|
test "independent coordinates transport old values retain prefix and reject forged witnesses" {
  let a = test_sqrt(2)
  let b = test_sqrt(3)
  let z = @cx.number(a, b)
  let inputs : @core.Chain[@cx.Number] = Cons(z, Cons(z, Nil))
  let budget = test_budget()
  let pending = match compose(inputs, { ..budget, attempts: Zero, }).unwrap() {
    Paused(build, MergeBudget(_)) => build
    _ => abort("expected merge pause")
  }
  assert_eq(completed_coordinates(pending), @oracle.nat(1))
  let prefix = @oracle.array(@core.reverse(pending.steps_rev))
  assert_true(prefix[0] is Normalize(_))
  let (value, proof) = match advance(pending, budget).unwrap() {
    Ready(value, proof) => (value, proof)
    _ => abort("independent coordinates unresolved")
  }
  let field = @cf.real_field(common_field(value))
  assert_eq(@nf.degree(field), @oracle.nat(4))
  assert_eq(@cf.degree(common_field(value)), @oracle.nat(8))
  let values = @oracle.array(elements(value))
  assert_true(@cf.equal(values[0], values[1]))
  let x = @cf.real_part(values[0])
  let y = @cf.imaginary_part(values[0])
  assert_true(
    @nf.equal(
      @nf.multiply(x, x).unwrap(),
      @nf.rational(field, @oracle.rational(2, 1)),
    ),
  )
  assert_true(
    @nf.equal(
      @nf.multiply(y, y).unwrap(),
      @nf.rational(field, @oracle.rational(3, 1)),
    ),
  )
  assert_eq(check_result(inputs, value, proof, @oracle.nat(512)), @zass.Proven)
  assert_eq(
    check_result(inputs, value, certificate(value), @oracle.nat(512)),
    @zass.Proven,
  )
  assert_eq(check(inputs, proof, Zero), @zass.Undecided)
  assert_eq(
    check(
      Cons(@cx.number(a, test_root([-3, 0, 1], -3, -1)), Cons(z, Nil)),
      proof,
      @oracle.nat(512),
    ),
    @zass.Refuted,
  )
  assert_eq(
    check(Cons(@cx.number(b, a), Cons(z, Nil)), proof, @oracle.nat(512)),
    @zass.Refuted,
  )
  assert_eq(
    check(
      inputs,
      {
        ..proof,
        sources: @core.reverse(@core.take(Succ(Zero), proof.sources)),
      },
      @oracle.nat(512),
    ),
    @zass.Refuted,
  )
  assert_eq(
    check(
      inputs,
      { ..proof, steps: @core.reverse(proof.steps), },
      @oracle.nat(512),
    ),
    @zass.Refuted,
  )
  let zero = @nf.representative(@nf.zero(field))
  assert_eq(
    check(
      inputs,
      {
        ..proof,
        coordinates: Cons(zero, @core.drop(Succ(Zero), proof.coordinates)),
      },
      @oracle.nat(512),
    ),
    @zass.Refuted,
  )
  assert_eq(
    check_result(
      inputs,
      { ..value, values: @core.map(value.values, @cf.conjugate), },
      proof,
      @oracle.nat(512),
    ),
    @zass.Refuted,
  )
  assert_eq(
    check_result(
      inputs,
      { ..value, values: Cons(@cf.zero(value.field), Nil), },
      proof,
      @oracle.nat(512),
    ),
    @zass.Refuted,
  )
  let steps = @oracle.array(proof.steps)
  let bad_reuse = steps.copy()
  bad_reuse[2] = Reuse(Succ(Zero))
  assert_eq(
    check(
      inputs,
      { ..proof, steps: @oracle.chain(bad_reuse), },
      @oracle.nat(512),
    ),
    @zass.Refuted,
  )
  match steps[1] {
    Merge(common, merge) => {
      let bad_merge = steps.copy()
      bad_merge[1] = Merge(common, {
        ..merge,
        left_embedding: merge.right_embedding,
      })
      assert_eq(
        check(
          inputs,
          { ..proof, steps: @oracle.chain(bad_merge), },
          @oracle.nat(512),
        ),
        @zass.Refuted,
      )
    }
    _ => fail("missing merge witness")
  }
}

///|
test "zeta three has a quadratic real ambient field and conjugate payload is rejected" {
  let half = @real.rational(@oracle.rational(-1, 2)).unwrap()
  let imaginary = @real.number({
    polynomial: @poly.polynomial(
      @oracle.nat(1),
      @oracle.chain([
        @poly.Term::{
          coefficient: @oracle.rational(-3, 1),
          exponents: Cons(Zero, Nil),
        },
        @poly.Term::{
          coefficient: @oracle.rational(4, 1),
          exponents: Cons(@oracle.nat(2), Nil),
        },
      ]),
    ).unwrap(),
    interval: { lower: @oracle.rational(0, 1), upper: @oracle.rational(1, 1), },
  }).unwrap()
  let inputs : @core.Chain[@cx.Number] = Cons(@cx.number(half, imaginary), Nil)
  let (value, proof) = test_compose(inputs)
  assert_eq(@cf.degree(common_field(value)), @oracle.nat(4))
  assert_eq(check_result(inputs, value, proof, @oracle.nat(512)), @zass.Proven)
  let z = @oracle.array(elements(value))[0]
  let cube = @cf.multiply(@cf.multiply(z, z).unwrap(), z).unwrap()
  assert_true(@cf.equal(cube, @cf.one(common_field(value))))
  assert_eq(
    check_result(
      inputs,
      { ..value, values: Cons(@cf.conjugate(z), Nil), },
      proof,
      @oracle.nat(512),
    ),
    @zass.Refuted,
  )
}

///|
test "already contained dependent coordinates keep degree two through successive transports" {
  let a = test_sqrt(2)
  let twice = test_root([-8, 0, 1], 2, 3)
  let opposite = test_root([-2, 0, 1], -2, -1)
  let inputs = @oracle.chain([
    @cx.number(a, twice),
    @cx.number(opposite, test_rational(0)),
  ])
  let (value, proof) = test_compose(inputs)
  let field = @cf.real_field(common_field(value))
  assert_eq(@nf.degree(field), @oracle.nat(2))
  assert_eq(check_result(inputs, value, proof, @oracle.nat(512)), @zass.Proven)
  let values = @oracle.array(elements(value))
  let x = @cf.real_part(values[0])
  assert_true(@nf.equal(@cf.imaginary_part(values[0]), @nf.add(x, x).unwrap()))
  assert_true(@nf.equal(@cf.real_part(values[1]), @nf.negate(x)))
  assert_true(@nf.is_zero(@cf.imaginary_part(values[1])))
  assert_eq(
    @oracle.array(@core.filter(proof.steps, fn(step) { step is Merge(_, _) })).length(),
    2,
  )
  let coordinates = @oracle.array(proof.coordinates)
  coordinates[0] = coordinates[1]
  assert_eq(
    check(
      inputs,
      { ..proof, coordinates: @oracle.chain(coordinates), },
      @oracle.nat(512),
    ),
    @zass.Refuted,
  )
  let (other, _) = test_compose(
    Cons(@cx.number(test_sqrt(3), test_rational(0)), Nil),
  )
  assert_eq(
    check(
      inputs,
      { ..proof, field: @cf.real_field(common_field(other)), },
      @oracle.nat(512),
    ),
    @zass.Refuted,
  )
  assert_eq(
    check_result(
      inputs,
      { ..value, field: common_field(other), },
      proof,
      @oracle.nat(512),
    ),
    @zass.Refuted,
  )
}
