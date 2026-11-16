///|
fn review_poly(
  field : Field,
  values : Array[@exact.Rational],
) -> Polynomial raise {
  must(
    polynomial(field, @oracle.chain(values.map(fn(v) { rational(field, v) }))),
  )
}

///|
fn review_sqrt2(positive : Bool) -> Extension raise {
  let base = rational_field()
  extension(
    p(base, [-2, 0, 1]),
    if positive {
      interval(1, 2)
    } else {
      interval(-2, -1)
    },
  )
}

///|
fn review_nested() -> Extension raise {
  let first = review_sqrt2(true)
  extension(
    must(
      polynomial(
        first.field,
        @oracle.chain([
          scalar_negate(first.generator),
          scalar_zero(first.field),
          scalar_one(first.field),
        ]),
      ),
    ),
    interval(1, 2),
  )
}

///|
fn review_eval(gen : Scalar, values : Array[@exact.Rational]) -> Scalar raise {
  must(evaluate(review_poly(scalar_field(gen), values), gen))
}

///|
fn review_rational_fixture(
  modulus : Array[@exact.Rational],
  span : @sturm.Interval,
  numerator : Array[@exact.Rational],
  denominator : Array[@exact.Rational],
  expected : @exact.Rational,
  sign : @core.Ordering,
) -> Unit raise {
  let ext = extension(review_poly(rational_field(), modulus), span)
  let a = review_eval(ext.generator, numerator)
  let b = review_eval(ext.generator, denominator)
  let actual = must(scalar_divide(a, b))
  equal_is(actual, rational(ext.field, expected))
  sign_is(actual, sign)
  let inv = must(scalar_inverse(b))
  equal_is(must(scalar_multiply(b, inv)), scalar_one(ext.field))
  if sign == @core.Equal {
    assert_true(scalar_inverse(actual) is Err(ZeroDivisor))
  }
}

///|
fn review_quadratic_fixture(
  positive : Bool,
  numerator : Array[@exact.Rational],
  denominator : Array[@exact.Rational],
  a : @exact.Rational,
  b : @exact.Rational,
  sign : @core.Ordering,
) -> Unit raise {
  let ext = review_sqrt2(positive)
  let top = review_eval(ext.generator, numerator)
  let bottom = review_eval(ext.generator, denominator)
  let actual = must(scalar_divide(top, bottom))
  let expected = review_eval(ext.generator, [a, b])
  equal_is(actual, expected)
  sign_is(actual, sign)
  assert_eq(must(scalar_compare(actual, scalar_zero(ext.field))), sign)
  equal_is(must(scalar_multiply(actual, bottom)), top)
  if sign != @core.Equal {
    equal_is(
      must(scalar_multiply(actual, must(scalar_inverse(actual)))),
      scalar_one(ext.field),
    )
  } else {
    assert_true(scalar_inverse(actual) is Err(ZeroDivisor))
  }
}

///|
fn review_query_fixture(
  source : Array[@exact.Rational],
  query : Array[@exact.Rational],
  span : @sturm.Interval,
  expected : Int32,
) -> Unit raise {
  let field = rational_field()
  let source = review_poly(field, source)
  let query = review_poly(field, query)
  let actual = must(rp_query(field, source.values, query.values, span))
  assert_eq(actual, @oracle.integer(expected))
}

///|
fn review_relative_count_fixture(
  depth : Int32,
  positive : Bool,
  values : Array[Array[@exact.Rational]],
  spans : Array[(@sturm.Interval, Int32)],
) -> Unit raise {
  let ext = if depth == 1 { review_sqrt2(positive) } else { review_nested() }
  let source = must(
    polynomial(
      ext.field,
      @oracle.chain(values.map(cs => review_eval(ext.generator, cs))),
    ),
  )
  let sys = must(system(source))
  assert_eq(degree(source), Some(@oracle.nat(values.length() - 1)))
  assert_true(check_system(source, system_certificate(sys)))
  for (span, expected) in spans {
    let cert = must(count_between(sys, span))
    assert_eq(cert.count, @oracle.nat(expected))
    assert_true(check_count(sys, span, @oracle.nat(expected), cert))
  }
}

///|
fn review_shifted_quadratic_fixture(
  modulus : Array[@exact.Rational],
  span : @sturm.Interval,
  queries : Array[(@exact.Rational, @exact.Rational, @core.Ordering)],
) -> Unit raise {
  let ext = extension(review_poly(rational_field(), modulus), span)
  for (constant, linear, expected) in queries {
    let value = must(
      scalar_add(
        rational(ext.field, constant),
        must(scalar_multiply(rational(ext.field, linear), ext.generator)),
      ),
    )
    sign_is(value, expected)
    if expected == @core.Equal {
      assert_true(scalar_inverse(value) is Err(ZeroDivisor))
    }
  }
}

///|
fn review_irrational_shift_fixture(
  upper : Bool,
  queries : Array[
    (Array[@exact.Rational], Array[@exact.Rational], @core.Ordering),
  ],
) -> Unit raise {
  let first = review_sqrt2(true)
  let definition = must(
    polynomial(
      first.field,
      @oracle.chain([
        scalar_one(first.field),
        must(scalar_multiply(s(first.field, -2), first.generator)),
        scalar_one(first.field),
      ]),
    ),
  )
  let ext = extension(
    definition,
    if upper {
      interval(2, 3)
    } else {
      interval(0, 1)
    },
  )
  for (constant, linear, expected) in queries {
    let d = must(embed(ext.field, review_eval(first.generator, constant)))
    let a = must(embed(ext.field, review_eval(first.generator, linear)))
    let value = must(scalar_add(d, must(scalar_multiply(a, ext.generator))))
    sign_is(value, expected)
    if expected == @core.Equal {
      assert_true(scalar_inverse(value) is Err(ZeroDivisor))
    }
  }
}
