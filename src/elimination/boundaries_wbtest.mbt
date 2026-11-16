///|
fn elimination_small(values : Array[Int32]) -> Fixed[@exact.Rational] {
  dense(
    @oracle.chain(values.map(fn(x) { @oracle.rational(x, 1) })),
    @berkowitz.rationals(),
  )
}

///|
test "elimination nominal constants zero nil and checked lengths" {
  let ring = @berkowitz.rationals()
  let empty : @core.Chain[@exact.Rational] = @core.Nil
  assert_true(fixed(@oracle.nat(0), empty) is None)
  assert_true(
    fixed(@oracle.nat(2), @oracle.chain([@exact.rational_one()])) is None,
  )
  let zero = dense(@core.Nil, ring)
  assert_eq(nominal_degree(zero), @oracle.nat(0))
  assert_eq(coefficients(zero), @oracle.chain([@exact.rational_zero()]))
  assert_eq(resultant(zero, zero, ring), Some(@exact.rational_one()))
  assert_true(bezout(zero, zero, ring) is None)
  let cubic = elimination_small([0, 0, 1, 2])
  assert_eq(
    resultant(elimination_small([3]), cubic, ring),
    Some(@oracle.rational(27, 1)),
  )
  assert_eq(resultant(zero, cubic, ring), Some(@exact.rational_zero()))
  assert_eq(
    discriminant(elimination_small([0, 3, 2]), ring),
    Some(@oracle.rational(9, 1)),
  )
  assert_eq(
    discriminant(elimination_small([3, 2]), ring),
    Some(@exact.rational_one()),
  )
}

///|
test "elimination ring-map specialization retains a vanished leading coefficient" {
  let mod4 : @berkowitz.Ring[Int32] = {
    semiring: {
      zero: 0,
      one: 1,
      plus: fn(a, b) { (a + b) % 4 },
      times: fn(a, b) { a * b % 4 },
    },
    negate: fn(a) { (4 - a) % 4 },
  }
  let mod2 : @berkowitz.Ring[Bool] = {
    semiring: {
      zero: false,
      one: true,
      plus: fn(a, b) { a != b },
      times: fn(a, b) { a && b },
    },
    negate: fn(a) { a },
  }
  let f = dense(@oracle.chain([2, 1]), mod4)
  let g = dense(@oracle.chain([1, 3]), mod4)
  let map = fn(a : Int32) { a % 2 != 0 }
  let ff = map_coefficients(f, map)
  let gg = map_coefficients(g, map)
  assert_eq(nominal_degree(ff), @oracle.nat(1))
  assert_true(check_specialization(f, ff, map, fn(a, b) { a == b }))
  assert_false(
    check_specialization(f, dense(@oracle.chain([true]), mod2), map, fn(a, b) {
      a == b
    }),
  )
  assert_eq(resultant(ff, gg, mod2), Some(map(resultant(f, g, mod4).unwrap())))
  assert_eq(discriminant(ff, mod2), Some(map(discriminant(f, mod4).unwrap())))
}

///|
test "elimination bounded identity alone is weaker than resultant equality" {
  let ring = @berkowitz.rationals()
  let f = elimination_small([1, 1])
  let g = elimination_small([1, 2])
  let proof = bezout(f, g, ring).unwrap()
  assert_eq(proof.value, @exact.rational_one())
  let zero = @exact.rational_zero()
  let trivial = {
    ..proof,
    value: zero,
    u: @oracle.chain([zero]),
    v: @oracle.chain([zero]),
  }
  assert_true(
    check_bezout_identity(f, g, zero, trivial, ring, fn(a, b) { a == b }),
  )
  assert_false(check_resultant(f, g, zero, ring, fn(a, b) { a == b }))
  assert_false(
    check_bezout_identity(g, f, proof.value, proof, ring, fn(a, b) { a == b }),
  )
  let padded = elimination_small([0, 1, 1])
  assert_false(
    check_bezout_identity(padded, g, proof.value, proof, ring, fn(a, b) {
      a == b
    }),
  )
}

///|
test "elimination validated QQ inputs reject variable degree and dimension changes" {
  let f = elimination_poly(2, [
    (@oracle.rational(1, 1), [0, 2]),
    (@oracle.rational(1, 1), [1, 0]),
  ])
  assert_eq(fixed_input(f, @oracle.nat(1), @oracle.nat(1)), Err(DegreeTooSmall))
  assert_eq(input(f, @oracle.nat(2)), Err(InvalidVariable))
  assert_eq(
    input(@poly.zero(@oracle.nat(0)), @oracle.nat(0)),
    Err(InvalidVariable),
  )
  let left = input(f, @oracle.nat(1)).unwrap()
  let other = input(f, @oracle.nat(0)).unwrap()
  assert_eq(eliminate(left, other), Err(DimensionMismatch))
  let one_variable = input(
    elimination_poly(1, [(@oracle.rational(1, 1), [1])]),
    @oracle.nat(0),
  ).unwrap()
  assert_eq(eliminate(left, one_variable), Err(DimensionMismatch))
  let constant = input(@poly.zero(@oracle.nat(2)), @oracle.nat(1)).unwrap()
  assert_eq(projection_identity(constant, constant), Err(ConstantPairIdentity))
  assert_eq(
    discriminate(constant),
    Ok(@poly.constant(@oracle.nat(1), @exact.rational_one())),
  )
}

///|
test "elimination QQ fixed specialization is distinct from recomputing actual degree" {
  let one = @oracle.rational(1, 1)
  let f = elimination_poly(2, [(one, [1, 1]), (one, [0, 0])])
  let g = elimination_poly(2, [(one, [0, 1]), (one, [0, 0])])
  let expected = elimination_poly(1, [
    (one, [1]),
    (@oracle.rational(-1, 1), [0]),
  ])
  assert_eq(resultant_variable(f, g, @oracle.nat(1)), Ok(expected))
  let specialized = @poly.constant(@oracle.nat(2), one)
  let nominal = fixed_input(specialized, @oracle.nat(1), @oracle.nat(1)).unwrap()
  let actual = input(specialized, @oracle.nat(1)).unwrap()
  let right = input(g, @oracle.nat(1)).unwrap()
  let minus_one = @poly.constant(@oracle.nat(1), @oracle.rational(-1, 1))
  assert_eq(eliminate(nominal, right), Ok(minus_one))
  assert_eq(eliminate(actual, right), Ok(@poly.constant(@oracle.nat(1), one)))
  let proof = projection_identity(nominal, right).unwrap()
  assert_true(check_projection_result(nominal, right, minus_one, proof))
  assert_false(check_projection_identity(actual, right, minus_one, proof))
  assert_false(
    check_projection_identity(
      input(f, @oracle.nat(1)).unwrap(),
      right,
      minus_one,
      proof,
    ),
  )
}

///|
test "elimination QQ identity payload arity bounds and determinant value are separate" {
  let one = @oracle.rational(1, 1)
  let f = elimination_poly(2, [(one, [0, 1]), (one, [0, 0])])
  let g = elimination_poly(2, [(one, [0, 1]), (@oracle.rational(2, 1), [0, 0])])
  let left = input(f, @oracle.nat(1)).unwrap()
  let right = input(g, @oracle.nat(1)).unwrap()
  let proof = projection_identity(left, right).unwrap()
  let zero = @poly.zero(@oracle.nat(1))
  let trivial = {
    ..proof,
    value: zero,
    u: @poly.zero(@oracle.nat(2)),
    v: @poly.zero(@oracle.nat(2)),
  }
  assert_true(check_projection_identity(left, right, zero, trivial))
  assert_false(check_projection_result(left, right, zero, trivial))
  assert_false(
    check_projection_identity(left, right, proof.value, {
      ..proof,
      u: @poly.zero(@oracle.nat(3)),
    }),
  )
  assert_false(
    check_projection_identity(left, right, proof.value, {
      ..proof,
      value: @poly.zero(@oracle.nat(2)),
    }),
  )
  let y = elimination_poly(2, [(one, [0, 1])])
  assert_false(
    check_projection_identity(left, right, proof.value, { ..proof, u: y, }),
  )
  assert_false(check_projection_identity(right, left, proof.value, proof))
}

///|
test "elimination private coefficient factory preserves its checked homogeneous arity" {
  let one = @oracle.rational(1, 1)
  let p = elimination_poly(3, [
    (one, [1, 2, 1]),
    (one, [2, 0, 0]),
    (one, [0, 0, 0]),
  ])
  let converted = as_coefficients(input(p, @oracle.nat(1)).unwrap()).unwrap()
  let ring = coefficient_ring(@oracle.nat(2))
  for coefficient in @oracle.array(coefficients(converted)) {
    let product = (ring.semiring.times)(coefficient, ring.semiring.one)
    assert_true(
      @core.all(product.terms, fn(term) {
        @core.length(term.exponents) == @oracle.nat(2)
      }),
    )
    assert_true(coefficient_polynomial(product, @oracle.nat(2)) is Ok(_))
  }
  let foreign : Coefficient = {
    terms: @oracle.chain([
      @poly.Term::{
        coefficient: one,
        exponents: @oracle.chain([@oracle.nat(0)]),
      },
    ]),
  }
  assert_eq(
    coefficient_polynomial(foreign, @oracle.nat(2)),
    Err(InternalDimension),
  )
}
