///|
struct OracleRootFixture {
  definition : Array[@exact.Rational]
  minimum : Array[@exact.Rational]
  lower : @exact.Rational
  upper : @exact.Rational
}

///|
struct OracleCohortFixture {
  degree : Int32
  real_minimum : Array[@exact.Rational]
  inputs : Array[(OracleRootFixture, OracleRootFixture)]
  alpha_terms : Array[(Int32, Bool, @exact.Rational)]
  values : Array[
    (Array[@exact.Rational], Array[@exact.Rational], Array[@exact.Rational]),
  ]
  products : Array[
    (Int32, Int32, Array[@exact.Rational], Array[@exact.Rational]),
  ]
  pause_merge : Bool
}

///|
fn oracle_poly(coefficients : Array[@exact.Rational]) -> @poly.Polynomial {
  @poly.polynomial(
    @oracle.nat(1),
    @oracle.chain(
      [
        for index, coefficient in coefficients => {
          @poly.Term::{ coefficient, exponents: Cons(@oracle.nat(index), Nil), }
        }
      ],
    ),
  ).unwrap()
}

///|
fn oracle_root(value : OracleRootFixture) -> @real.Number {
  @real.number({
    polynomial: oracle_poly(value.definition),
    interval: { lower: value.lower, upper: value.upper, },
  }).unwrap()
}

///|
fn oracle_budget() -> @comp.Budget {
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
fn oracle_evaluate(
  alpha : @nf.Element,
  coefficients : Array[@exact.Rational],
) -> @nf.Element {
  let field = @nf.parent(alpha)
  for index = coefficients.length() - 1, value = @nf.zero(field); index >= 0; {
    continue index - 1,
      @nf.add(
        @nf.multiply(value, alpha).unwrap(),
        @nf.rational(field, coefficients[index]),
      ).unwrap()
  } nobreak {
    value
  }
}

///|
fn oracle_complex_image(
  alpha : @nf.Element,
  real : Array[@exact.Rational],
  imaginary : Array[@exact.Rational],
) -> @cf.Element {
  @cf.element(
    @cf.field(@nf.parent(alpha)),
    oracle_evaluate(alpha, real),
    oracle_evaluate(alpha, imaginary),
  ).unwrap()
}

///|
fn oracle_assert_real(
  actual : @nf.Element,
  expected : OracleRootFixture,
) -> Unit raise {
  assert_eq(
    @nf.minimal_polynomial(actual).unwrap(),
    oracle_poly(expected.minimum),
  )
  match @nf.realize(actual, @oracle.nat(128)).unwrap() {
    @nf.RealReady(value, proof) => {
      assert_true(@nf.check_realization_result(actual, value, proof))
      match
        @real.compare(value, oracle_root(expected), @oracle.nat(128)).unwrap() {
        @real.Compared(order, comparison) => {
          assert_eq(order, @core.Equal)
          assert_true(@real.check_comparison_result(order, comparison))
        }
        _ => fail("independent selected-root comparison paused")
      }
    }
    _ => fail("independent coordinate realization paused")
  }
}

///|
fn oracle_assert_cohort(fixture : OracleCohortFixture) -> Unit raise {
  let inputs = @oracle.chain(
    fixture.inputs.map(fn(pair) {
      @cx.number(oracle_root(pair.0), oracle_root(pair.1))
    }),
  )
  let budget = oracle_budget()
  let progress = if fixture.pause_merge {
    match compose(inputs, { ..budget, attempts: @oracle.nat(0), }).unwrap() {
      Paused(build, MergeBudget(_)) => {
        assert_eq(completed_coordinates(build), @oracle.nat(1))
        advance(build, budget).unwrap()
      }
      _ => abort("independent coordinate merge should pause")
    }
  } else {
    compose(inputs, budget).unwrap()
  }
  let (common, proof) = match progress {
    Ready(common, proof) => (common, proof)
    _ => abort("finite independent cohort unresolved")
  }
  let source = common_field(common)
  let real_field = @cf.real_field(source)
  assert_eq(@cf.degree(source), @oracle.nat(fixture.degree))
  assert_eq(@nf.degree(real_field), @oracle.nat(fixture.degree / 2))
  assert_eq(check_result(inputs, common, proof, @oracle.nat(512)), @zass.Proven)
  assert_eq(
    check_result(inputs, common, certificate(common), @oracle.nat(512)),
    @zass.Proven,
  )
  assert_eq(check(inputs, proof, @oracle.nat(0)), @zass.Undecided)
  let actual = @oracle.array(elements(common))
  assert_eq(actual.length(), fixture.values.length())
  let mut alpha = @nf.zero(real_field)
  for (index, imaginary, coefficient) in fixture.alpha_terms {
    let component = if imaginary {
      @cf.imaginary_part(actual[index])
    } else {
      @cf.real_part(actual[index])
    }
    alpha = @nf.add(
      alpha,
      @nf.multiply(@nf.rational(real_field, coefficient), component).unwrap(),
    ).unwrap()
  }
  // This primitive was chosen externally; it need not be the producer's.
  assert_eq(
    @nf.minimal_polynomial(alpha).unwrap(),
    oracle_poly(fixture.real_minimum),
  )
  for index, expected in fixture.values {
    assert_true(@cf.same_field(@cf.parent(actual[index]), source))
    let external_image = oracle_complex_image(alpha, expected.0, expected.1)
    assert_true(@cf.equal(actual[index], external_image))
    assert_eq(
      @cf.minimal_polynomial(actual[index]).unwrap(),
      oracle_poly(expected.2),
    )
    oracle_assert_real(@cf.real_part(actual[index]), fixture.inputs[index].0)
    oracle_assert_real(
      @cf.imaginary_part(actual[index]),
      fixture.inputs[index].1,
    )
  }
  for (left, right, real, imaginary) in fixture.products {
    assert_true(
      @cf.equal(
        @cf.multiply(actual[left], actual[right]).unwrap(),
        oracle_complex_image(alpha, real, imaginary),
      ),
    )
  }
  if actual.length() > 0 {
    let bad_values = actual.copy()
    bad_values[0] = @cf.add(actual[0], @cf.one(source)).unwrap()
    assert_eq(
      check_result(
        inputs,
        { ..common, values: @oracle.chain(bad_values), },
        proof,
        @oracle.nat(512),
      ),
      @zass.Refuted,
    )
    let bad_coordinates = @oracle.array(proof.coordinates)
    bad_coordinates[0] = @poly.add(
      bad_coordinates[0],
      oracle_poly([@exact.rational_one()]),
    ).unwrap()
    assert_eq(
      check(
        inputs,
        { ..proof, coordinates: @oracle.chain(bad_coordinates), },
        @oracle.nat(512),
      ),
      @zass.Refuted,
    )
  }
}
