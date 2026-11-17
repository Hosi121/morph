///|
fn ct_old_rational(field : Field, value : @exact.Rational) -> Representation {
  match field.context {
    Rationals => Base(value)
    Extension(parent, _, _) =>
      Fraction(
        Cons(ct_old_rational(parent, value), Nil),
        Cons(ct_old_rational(parent, @exact.rational_one()), Nil),
      )
  }
}

///|
fn ct_extension(field : Field, quadratic : Bool, negative : Bool) -> Extension {
  let integers = if quadratic { [-2, 0, 1] } else { [-1, 1] }
  let input = polynomial(
    field,
    @oracle.chain(
      integers.map(fn(n) { rational(field, @oracle.rational(n, 1)) }),
    ),
  ).unwrap()
  let span : @sturm.Interval = {
    lower: @oracle.rational(
      if negative {
        -2
      } else if quadratic {
        1
      } else {
        0
      },
      1,
    ),
    upper: @oracle.rational(
      if negative {
        -1
      } else if quadratic {
        2
      } else {
        1
      },
      1,
    ),
  }
  adjoin(root_in_interval(system(input).unwrap(), span).unwrap()).unwrap()
}

///|
fn ct_field(depth : Int32) -> Field {
  let mut field = rational_field()
  for _ in 0..<depth {
    field = ct_extension(field, false, false).field
  }
  field
}

///|
fn ct_assert_rep(
  value : Representation,
  depth : Int32,
  numerator : Int32,
  denominator : Int32,
) -> Unit raise {
  if depth == 0 {
    match value {
      Base(q) => {
        assert_eq(@oracle.int_of_integer(@exact.numerator(q)), numerator)
        assert_eq(@oracle.int_of_binary(@exact.denominator(q)), denominator)
      }
      _ => fail("expected Base at tower depth zero")
    }
  } else {
    match value {
      Fraction(Cons(n, Nil), Cons(d, Nil)) => {
        ct_assert_rep(n, depth - 1, numerator, denominator)
        ct_assert_rep(d, depth - 1, 1, 1)
      }
      _ => fail("expected exact singleton Fraction tower shape")
    }
  }
}

///|
fn ct_assert_sample(
  field : Field,
  depth : Int32,
  n : Int32,
  d : Int32,
  expected_n : Int32,
  expected_d : Int32,
) -> Unit raise {
  let q = @oracle.rational(n, d)
  let value = rational(field, q)
  assert_true(representative(value).equal(ct_old_rational(field, q)))
  ct_assert_rep(representative(value), depth, expected_n, expected_d)
  let sign : @core.Ordering = if expected_n < 0 {
    Less
  } else if expected_n == 0 {
    Equal
  } else {
    Greater
  }
  let result = scalar_sign(value).unwrap()
  assert_true(result.sign.equal(sign))
  assert_true(check_scalar(value, sign, result.certificate))
  let wrong : @core.Ordering = if sign.equal(Equal) { Greater } else { Equal }
  assert_false(check_scalar(value, wrong, result.certificate))
}

///|
test "conversion constants retain exact old shape at depths zero through four" {
  for depth in 0..<5 {
    let field = ct_field(depth)
    let unit = scalar_one(field)
    let zero = scalar_zero(field)
    assert_true(
      representative(unit).equal(ct_old_rational(field, @exact.rational_one())),
    )
    assert_true(
      representative(zero).equal(ct_old_rational(field, @exact.rational_zero())),
    )
    ct_assert_rep(representative(unit), depth, 1, 1)
    ct_assert_rep(representative(zero), depth, 0, 1)
    match coefficients(one(field)) {
      Cons(c, Nil) => assert_true(representative(c).equal(representative(unit)))
      _ => fail("polynomial one must have one exact coefficient")
    }
  }
}

///|
test "conversion constants retain selected root context and reject mixed fields" {
  let positive = ct_extension(rational_field(), true, false)
  let negative = ct_extension(rational_field(), true, true)
  let a = rational(positive.field, @oracle.rational(2, 3))
  let b = rational(negative.field, @oracle.rational(2, 3))
  assert_true(representative(a).equal(representative(b)))
  assert_false(same_field(positive.field, negative.field))
  assert_true(scalar_multiply(a, b) is Err(DifferentField))
  let proof = scalar_sign(a).unwrap()
  assert_false(check_scalar(b, Greater, proof.certificate))
}

///|
test "conversion constants feed ordinary nonunit multiplication and deep one" {
  let first = ct_extension(rational_field(), true, false)
  let second = ct_extension(first.field, true, false)
  let a = rational(second.field, @oracle.rational(2, 3))
  let b = rational(second.field, @oracle.rational(-5, 7))
  let product = scalar_multiply(a, b).unwrap()
  ct_assert_rep(representative(product), 2, -10, 21)
  assert_true(
    representative(product).equal(
      ct_old_rational(second.field, @oracle.rational(-10, 21)),
    ),
  )
  let unit = scalar_one(second.field)
  assert_true(
    scalar_multiply(second.generator, unit).unwrap().equal(second.generator),
  )
  assert_true(
    scalar_multiply(unit, second.generator).unwrap().equal(second.generator),
  )
  let proof = scalar_sign(product).unwrap()
  assert_true(check_scalar(product, Less, proof.certificate))
}
