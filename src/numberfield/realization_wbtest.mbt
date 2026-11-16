///|
fn test_realize(value : Element) -> (@real.Number, RealCertificate) {
  match realize(value, @oracle.nat(100)).unwrap() {
    RealReady(number, proof) => (number, proof)
    RealPaused(_) => abort("small field embedding unresolved")
  }
}

///|
fn assert_real_equal(a : @real.Number, b : @real.Number) -> Unit raise {
  match @real.compare(a, b, @oracle.nat(200)).unwrap() {
    @real.Compared(order, proof) => {
      assert_eq(order, Equal)
      assert_true(@real.check_comparison_result(order, proof))
    }
    _ => fail("independent real equality unresolved")
  }
}

///|
test "power dependence proves genuine element minimality and rejects larger annihilator" {
  let f = test_sqrt2()
  let a = generator(f).unwrap()
  assert_eq(minimal_polynomial(a).unwrap(), test_integer_poly([-2, 0, 1]))
  assert_eq(
    minimal_polynomial(multiply(a, a).unwrap()).unwrap(),
    test_integer_poly([-2, 1]),
  )
  assert_eq(minimal_polynomial(zero(f)).unwrap(), test_integer_poly([0, 1]))
  assert_eq(minimal_polynomial(one(f)).unwrap(), test_integer_poly([-1, 1]))
  assert_true(check_minimal_polynomial(a, test_integer_poly([-2, 0, 1])))
  assert_false(check_minimal_polynomial(a, test_integer_poly([4, 0, -4, 0, 1])))
  assert_false(check_minimal_polynomial(a, test_integer_poly([-4, 0, 2])))
  assert_false(check_minimal_polynomial(a, test_integer_poly([-3, 0, 1])))
  assert_false(check_minimal_polynomial(a, test_integer_poly([0])))
  assert_false(
    check_minimal_polynomial(
      a,
      @poly.constant(@oracle.nat(2), test_rational(1, 1)),
    ),
  )
  let field4 = test_field(
    [(1, 1), (0, 1), (-10, 1), (0, 1), (1, 1)],
    (3, 1),
    (4, 1),
  )
  let b = multiply(generator(field4).unwrap(), generator(field4).unwrap()).unwrap()
  let minimal = test_integer_poly([1, -10, 1])
  assert_eq(minimal_polynomial(b).unwrap(), minimal)
  assert_true(check_minimal_polynomial(b, minimal))
  // The square annihilates b and degree 4 <= ambient degree 4, but rank 4 fails.
  let square = @poly.multiply(minimal, minimal).unwrap()
  assert_true(is_zero(evaluate_polynomial(b, square).unwrap()))
  assert_false(check_minimal_polynomial(b, square))
  let extra_factor = @poly.multiply(minimal, test_integer_poly([-42, 1])).unwrap()
  assert_true(is_zero(evaluate_polynomial(b, extra_factor).unwrap()))
  assert_false(check_minimal_polynomial(b, extra_factor))
}

///|
test "explicit real embedding binds generator rational inverse and cancellation" {
  assert_real_fixture(
    [(-2, 1), (0, 1), (1, 1)],
    (1, 1),
    (2, 1),
    [(2, 1)],
    [(-2, 1), (1, 1)],
    (1, 1),
    (3, 1),
  )
  let f = test_sqrt2()
  let a = generator(f).unwrap()
  for
    value in [
      zero(f),
      one(f),
      a,
      negate(a),
      multiply(a, a).unwrap(),
      inverse(a).unwrap().unwrap(),
      add(a, one(f)).unwrap(),
    ] {
    let (number, proof) = test_realize(value)
    assert_true(check_realization_result(value, number, proof))
    assert_eq(@real.definition(number), minimal_polynomial(value).unwrap())
    let direct = match @poly.terms(representative(value)) {
      Cons({ exponents: Cons(Zero, Nil), coefficient, }, Nil) =>
        @real.rational(coefficient).unwrap()
      Nil => @real.rational(test_rational(0, 1)).unwrap()
      _ => number
    }
    assert_real_equal(number, direct)
  }
  let (number, proof) = test_realize(a)
  assert_real_equal(number, @real.number(embedding(f)).unwrap())
  assert_true(check_realization_result(a, number, proof))
  let negative_field = test_field([(-2, 1), (0, 1), (1, 1)], (-2, 1), (-1, 1))
  let negative_generator = generator(negative_field).unwrap()
  let (negative_number, negative_proof) = test_realize(negative_generator)
  assert_true(
    check_realization_result(
      negative_generator, negative_number, negative_proof,
    ),
  )
  assert_real_equal(
    negative_number,
    @real.number(embedding(negative_field)).unwrap(),
  )
}

///|
test "embedding zero fuel pauses and resumption retains the exact root context" {
  let f = test_sqrt2()
  let a = negate(generator(f).unwrap())
  let state = match realize(a, Zero).unwrap() {
    RealPaused(state) => state
    _ => abort("zero fuel must pause")
  }
  let resumed = match realize_advance(state, @oracle.nat(100)).unwrap() {
    RealReady(number, proof) => {
      assert_true(check_realization_result(a, number, proof))
      number
    }
    _ => abort("resume did not finish")
  }
  let (direct, _) = test_realize(a)
  assert_eq(@real.root_certificate(resumed), @real.root_certificate(direct))
  let wider = test_field(
    [(1, 1), (0, 1), (-10, 1), (0, 1), (1, 1)],
    (0, 1),
    (1, 1),
  )
  let b = generator(wider).unwrap()
  let first = realize(b, @oracle.nat(1)).unwrap()
  match first {
    RealPaused(state) =>
      match realize_advance(state, @oracle.nat(100)).unwrap() {
        RealReady(number, proof) =>
          assert_true(check_realization_result(b, number, proof))
        _ => fail("quartic resumption")
      }
    _ => fail("broad quartic image should need refinement")
  }
}

///|
test "embedding checker rejects alternative conjugate payload and valid unrelated Number" {
  let f = test_sqrt2()
  let a = generator(f).unwrap()
  let (number, p) = test_realize(a)
  let other = @real.number({
    polynomial: test_integer_poly([-2, 0, 1]),
    interval: { lower: test_rational(-2, 1), upper: test_rational(-1, 1), },
  }).unwrap()
  assert_false(check_realization_result(a, other, p))
  assert_false(
    check_realization_result(a, @real.rational(test_rational(1, 1)).unwrap(), p),
  )
  assert_false(
    check_realization(a, { ..p, result: @real.root_certificate(other), }),
  )
  assert_false(check_realization(a, { ..p, input: representative(one(f)), }))
  assert_false(check_realization(one(f), p))
  assert_false(check_realization(negate(a), p))
  assert_false(
    check_realization(a, { ..p, context: @real.root_certificate(other), }),
  )
  assert_false(
    check_realization(a, { ..p, refined: @real.root_certificate(other), }),
  )
  let false_result = @real.rational(test_rational(42, 1)).unwrap()
  assert_false(
    check_realization(a, { ..p, result: @real.root_certificate(false_result), }),
  )
  // A valid interval selecting the right root still cannot exclude its image.
  let narrow = @real.number({
    polynomial: test_integer_poly([-2, 0, 1]),
    interval: { lower: test_rational(7, 5), upper: test_rational(3, 2), },
  }).unwrap()
  assert_false(
    check_realization(a, { ..p, result: @real.root_certificate(narrow), }),
  )
  assert_true(check_realization_result(a, number, p))
}

///|
test "closed interval image contains cancellation boundary zero and negative products" {
  for (lo, hi) in [(-2, 1), (-1, 0), (0, 1), (1, 2), (-3, 3)] {
    let interval = @sturm.Interval::{
      lower: test_rational(lo.to_int64(), 1),
      upper: test_rational(hi.to_int64(), 1),
    }
    for raw in [[0], [0, 1], [0, 0, 1], [-2, 0, 1], [1, -2, 1], [1, 0, -3, 1]] {
      let p = test_integer_poly(raw)
      let image = interval_image(p, interval)
      for numerator in (lo * 4)..<(hi * 4 + 1) {
        let x = test_rational(numerator.to_int64(), 4)
        let value = @poly.evaluate(p, Cons(x, Nil)).unwrap()
        assert_true(rational_leq(image.lower, value))
        assert_true(rational_leq(value, image.upper))
      }
    }
  }
}

///|
fn assert_real_fixture(
  m : Array[(Int64, Int64)],
  lower : (Int64, Int64),
  upper : (Int64, Int64),
  a : Array[(Int64, Int64)],
  expected_minimal : Array[(Int64, Int64)],
  result_lower : (Int64, Int64),
  result_upper : (Int64, Int64),
) -> Unit raise {
  let f = test_field(m, lower, upper)
  let value = element(f, test_poly(a)).unwrap()
  let minimal = minimal_polynomial(value).unwrap()
  assert_eq(minimal, test_poly(expected_minimal))
  assert_true(check_minimal_polynomial(value, minimal))
  let (number, proof) = test_realize(value)
  assert_eq(@real.definition(number), minimal)
  assert_true(check_realization_result(value, number, proof))
  let expected = @real.number({
    polynomial: test_poly(expected_minimal),
    interval: {
      lower: test_rational(result_lower.0, result_lower.1),
      upper: test_rational(result_upper.0, result_upper.1),
    },
  }).unwrap()
  assert_real_equal(number, expected)
}
