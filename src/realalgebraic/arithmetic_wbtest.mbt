///|
fn test_binary(a : Number, b : Number, operation : BinaryOperation) -> Number {
  let state = arithmetic_start(a, b, operation).unwrap()
  match arithmetic_advance(state, @oracle.nat(100)).unwrap() {
    ArithmeticReady(value, proof) => {
      guard check_arithmetic(proof) else { abort("invalid arithmetic proof") }
      value
    }
    _ => abort("unexpected arithmetic pause")
  }
}

///|
fn test_unary(a : Number, operation : UnaryOperation) -> Number {
  match
    unary_advance(unary_start(a, operation).unwrap(), @oracle.nat(100)).unwrap() {
    UnaryReady(value, proof) => {
      guard check_unary(proof) else { abort("invalid unary proof") }
      value
    }
    _ => abort("unexpected unary pause")
  }
}

///|
test "sqrt2 plus sqrt3 chooses the positive conjugate exactly" {
  let a = test_number([-2, 0, 1], (1, 1), (2, 1))
  let b = test_number([-3, 0, 1], (1, 1), (2, 1))
  let actual = test_binary(a, b, Sum)
  let expected = test_number([1, 0, -10, 0, 1], (3, 1), (4, 1))
  assert_compared(actual, expected, Equal, 0)
  assert_true(check_root(root_certificate(actual)))
  assert_compared(
    actual,
    rational(@oracle.rational(3, 1)).unwrap(),
    Greater,
    20,
  )
}

///|
test "product and cancellation handle repeated resultant roots and exact zero" {
  let a = test_number([-2, 0, 1], (1, 1), (2, 1))
  let square = test_binary(a, a, Product)
  assert_compared(square, rational(@oracle.rational(2, 1)).unwrap(), Equal, 0)
  let negative = test_unary(a, Negation)
  let cancelled = test_binary(a, negative, Sum)
  assert_compared(
    cancelled,
    rational(@oracle.rational(0, 1)).unwrap(),
    Equal,
    0,
  )
  let product = test_binary(a, test_number([-3, 0, 1], (1, 1), (2, 1)), Product)
  assert_compared(product, test_number([-6, 0, 1], (2, 1), (3, 1)), Equal, 0)
  assert_compared(
    test_binary(a, rational(@oracle.rational(0, 1)).unwrap(), Product),
    rational(@oracle.rational(0, 1)).unwrap(),
    Equal,
    0,
  )
}

///|
test "closed-extremum products and negation retain excluded-lower-bound roots" {
  let minus_one = test_number([1, 1], (-2, 1), (-1, 1))
  assert_compared(
    test_binary(minus_one, minus_one, Product),
    rational(@oracle.rational(1, 1)).unwrap(),
    Equal,
    0,
  )
  let two = test_number([-2, 1], (1, 1), (2, 1))
  assert_compared(
    test_unary(two, Negation),
    rational(@oracle.rational(-2, 1)).unwrap(),
    Equal,
    0,
  )
}

///|
test "inverse supports positive negative and reducible definitions with zero root" {
  let positive = test_number([-2, 0, 1], (1, 1), (2, 1))
  let reciprocal = test_unary(positive, Reciprocal)
  let expected = number({
    polynomial: test_polynomial([(-1, 2), (0, 1), (1, 1)]),
    interval: { lower: @oracle.rational(1, 2), upper: @oracle.rational(1, 1), },
  }).unwrap()
  assert_compared(reciprocal, expected, Equal, 0)
  let negative = test_number([-2, 0, 1], (-2, 1), (-1, 1))
  assert_compared(
    test_unary(negative, Reciprocal),
    test_unary(expected, Negation),
    Equal,
    0,
  )
  let has_zero = test_number([0, -2, 1], (1, 1), (3, 1))
  assert_compared(
    test_unary(has_zero, Reciprocal),
    rational(@oracle.rational(1, 2)).unwrap(),
    Equal,
    0,
  )
  let excludes_zero = test_number([0, -1, 1], (0, 1), (2, 1))
  assert_compared(
    test_unary(excludes_zero, Reciprocal),
    rational(@oracle.rational(1, 1)).unwrap(),
    Equal,
    0,
  )
  assert_true(
    inverse(rational(@oracle.rational(0, 1)).unwrap(), Zero) is Err(ZeroDivisor),
  )
}

///|
test "inverse refines across zero and safely resumes at a reciprocal endpoint root" {
  let half = test_number([-1, 2], (-1, 1), (1, 1))
  let state = match inverse(half, Zero).unwrap() {
    UnaryPaused(state) => state
    _ => abort("closed interval crossing zero must pause")
  }
  let waiting = match unary_advance(state, Succ(Zero)).unwrap() {
    UnaryPaused(state) => state
    _ => abort("lower endpoint still zero")
  }
  match unary_advance(waiting, @oracle.nat(5)).unwrap() {
    UnaryReady(value, proof) => {
      assert_true(check_unary(proof))
      assert_compared(
        value,
        rational(@oracle.rational(2, 1)).unwrap(),
        Equal,
        0,
      )
      assert_false(check_unary({ ..proof, operation: Negation, }))
    }
    _ => fail("nonzero inverse must finish")
  }
}

///|
test "arithmetic pause cannot manufacture a root and certificates bind the selected conjugate" {
  let a = test_number([-2, 0, 1], (1, 1), (2, 1))
  let b = test_number([-3, 0, 1], (1, 1), (2, 1))
  let initial = arithmetic_start(a, b, Sum).unwrap()
  assert_true(arithmetic_advance(initial, Zero).unwrap() is ArithmeticPaused(_))
  let state = match arithmetic_advance(initial, @oracle.nat(5)).unwrap() {
    ArithmeticPaused(state) => state
    _ => abort("five points do not isolate this initially wide sum")
  }
  match arithmetic_advance(state, @oracle.nat(20)).unwrap() {
    ArithmeticReady(value, proof) => {
      assert_true(check_arithmetic(proof))
      assert_compared(
        value,
        test_number([1, 0, -10, 0, 1], (3, 1), (4, 1)),
        Equal,
        0,
      )
      let wrong_conjugate = root_certificate(
        test_number([1, 0, -10, 0, 1], (-4, 1), (-3, 1)),
      )
      assert_true(check_root(wrong_conjugate))
      assert_false(check_arithmetic({ ..proof, result: wrong_conjugate, }))
      assert_false(
        check_arithmetic({
          ..proof,
          left_refined: {
            lower: @oracle.rational(-2, 1),
            upper: @oracle.rational(-1, 1),
          },
        }),
      )
      assert_false(
        check_arithmetic({
          ..proof,
          resultant: { ..proof.resultant, operation: Product, },
        }),
      )
    }
    _ => fail("resumed sum must finish")
  }
}

///|
test "division composes independently checked reciprocal and product certificates" {
  let a = test_number([-2, 0, 1], (1, 1), (2, 1))
  let b = test_number([-3, 0, 1], (1, 1), (2, 1))
  let state = match divide(a, b, Zero).unwrap() {
    DivisionPaused(state) => state
    _ => abort("zero budget cannot interpolate a quotient product")
  }
  match division_advance(state, @oracle.nat(100)).unwrap() {
    DivisionReady(value, proof) => {
      assert_true(check_quotient(proof))
      let expected = number({
        polynomial: test_polynomial([(-2, 3), (0, 1), (1, 1)]),
        interval: {
          lower: @oracle.rational(0, 1),
          upper: @oracle.rational(1, 1),
        },
      }).unwrap()
      assert_compared(value, expected, Equal, 0)
      assert_false(
        check_quotient({
          ..proof,
          reciprocal: { ..proof.reciprocal, operation: Negation, },
        }),
      )
      assert_false(
        check_quotient({
          ..proof,
          product: { ..proof.product, right: proof.product.left, },
        }),
      )
    }
    _ => fail("quotient did not finish")
  }
  assert_true(
    divide(a, rational(@oracle.rational(0, 1)).unwrap(), @oracle.nat(100))
    is Err(ZeroDivisor),
  )
  match divide(a, a, @oracle.nat(100)).unwrap() {
    DivisionReady(value, proof) => {
      assert_true(check_quotient(proof))
      assert_compared(
        value,
        rational(@oracle.rational(1, 1)).unwrap(),
        Equal,
        0,
      )
    }
    _ => fail("self quotient must finish")
  }
}

///|
fn fixture_number(
  polynomial : Array[(Int32, Int32)],
  lower : (Int32, Int32),
  upper : (Int32, Int32),
) -> Number {
  number({
    polynomial: test_polynomial(polynomial),
    interval: {
      lower: @oracle.rational(lower.0, lower.1),
      upper: @oracle.rational(upper.0, upper.1),
    },
  }).unwrap()
}

///|
fn assert_algebraic_fixture(
  p : Array[(Int32, Int32)],
  al : (Int32, Int32),
  au : (Int32, Int32),
  q : Array[(Int32, Int32)],
  bl : (Int32, Int32),
  bu : (Int32, Int32),
  operation : BinaryOperation?,
  expected : Array[(Int32, Int32)],
  lower : (Int32, Int32),
  upper : (Int32, Int32),
) -> Unit raise {
  let a = fixture_number(p, al, au)
  let b = fixture_number(q, bl, bu)
  let value = match operation {
    Some(operation) => test_binary(a, b, operation)
    None =>
      match divide(a, b, @oracle.nat(100)).unwrap() {
        DivisionReady(value, proof) => {
          guard check_quotient(proof) else { abort("bad quotient certificate") }
          value
        }
        _ => abort("unexpected quotient pause")
      }
  }
  assert_compared(value, fixture_number(expected, lower, upper), Equal, 0)
}

///|
fn assert_unary_fixture(
  p : Array[(Int32, Int32)],
  al : (Int32, Int32),
  au : (Int32, Int32),
  operation : UnaryOperation,
  expected : Array[(Int32, Int32)],
  lower : (Int32, Int32),
  upper : (Int32, Int32),
) -> Unit raise {
  let value = test_unary(fixture_number(p, al, au), operation)
  assert_compared(value, fixture_number(expected, lower, upper), Equal, 0)
}

///|
test "native fraction oracle exhausts a signed rational arithmetic grid" {
  let grid = [
    (-2, 1),
    (-3, 2),
    (-1, 1),
    (-2, 3),
    (-1, 2),
    (-1, 3),
    (0, 1),
    (1, 3),
    (1, 2),
    (2, 3),
    (1, 1),
    (3, 2),
    (2, 1),
  ]
  let mut checked = 0
  for (an, ad) in grid {
    let a = rational(@oracle.rational(an, ad)).unwrap()
    for (bn, bd) in grid {
      let b = rational(@oracle.rational(bn, bd)).unwrap()
      let sum_expected = rational(@oracle.rational(an * bd + bn * ad, ad * bd)).unwrap()
      let product_expected = rational(@oracle.rational(an * bn, ad * bd)).unwrap()
      assert_compared(test_binary(a, b, Sum), sum_expected, Equal, 0)
      assert_compared(test_binary(a, b, Product), product_expected, Equal, 0)
      checked += 2
      if bn != 0 {
        let numerator = an * bd * (if bn < 0 { -1 } else { 1 })
        let denominator = ad * bn.abs()
        let expected = rational(@oracle.rational(numerator, denominator)).unwrap()
        match divide(a, b, @oracle.nat(100)).unwrap() {
          DivisionReady(value, proof) => {
            assert_true(check_quotient(proof))
            assert_compared(value, expected, Equal, 0)
          }
          _ => fail("rational quotient must finish")
        }
        checked += 1
      }
    }
  }
  assert_eq(checked, 494)
}

///|
test "operation certificate checks bind normalization refinement and output intervals" {
  let a = test_number([-2, 0, 1], (1, 1), (2, 1))
  let b = test_number([-3, 0, 1], (1, 1), (2, 1))
  match add(a, b, @oracle.nat(100)).unwrap() {
    ArithmeticReady(_, proof) => {
      assert_false(
        check_arithmetic({
          ..proof,
          resultant: {
            ..proof.resultant,
            left: @poly.scale(proof.resultant.left, {
              coefficient: @oracle.rational(2, 1),
              exponents: Cons(Zero, Nil),
            }).unwrap(),
          },
        }),
      )
      let changed = {
        ..proof.result.interval,
        lower: @exact.rational_subtract(
          proof.result.interval.lower,
          @oracle.rational(1, 1000),
        ),
      }
      assert_true(check_root({ ..proof.result, interval: changed, }))
      assert_false(
        check_arithmetic({
          ..proof,
          result: { ..proof.result, interval: changed, },
        }),
      )
    }
    _ => fail("sum must finish")
  }
  match negate(a, @oracle.nat(100)).unwrap() {
    UnaryReady(_, proof) => {
      assert_false(
        check_unary({
          ..proof,
          refined: {
            lower: @oracle.rational(-2, 1),
            upper: @oracle.rational(-1, 1),
          },
        }),
      )
      assert_false(check_unary({ ..proof, result: root_certificate(a), }))
    }
    _ => fail("negation must finish")
  }
}

///|
test "result checkers bind public progress payloads to their exact certificates" {
  let a = test_number([-2, 0, 1], (1, 1), (2, 1))
  let b = test_number([-3, 0, 1], (1, 1), (2, 1))
  let wrong = rational(@oracle.rational(7, 1)).unwrap()
  match add(a, b, @oracle.nat(100)).unwrap() {
    ArithmeticReady(value, proof) => {
      assert_true(check_arithmetic(proof))
      assert_true(check_arithmetic_result(value, proof))
      let forged = ArithmeticReady(wrong, proof)
      match forged {
        ArithmeticReady(payload, certificate) =>
          assert_false(check_arithmetic_result(payload, certificate))
        _ => fail("forged payload variant")
      }
      let equivalent = refine(value, Succ(Zero)).unwrap()
      assert_compared(value, equivalent, Equal, 0)
      assert_false(check_arithmetic_result(equivalent, proof))
    }
    _ => fail("sum must finish")
  }
  match inverse(a, @oracle.nat(100)).unwrap() {
    UnaryReady(value, proof) => {
      assert_true(check_unary(proof))
      assert_true(check_unary_result(value, proof))
      let forged = UnaryReady(wrong, proof)
      match forged {
        UnaryReady(payload, certificate) =>
          assert_false(check_unary_result(payload, certificate))
        _ => fail("forged unary variant")
      }
    }
    _ => fail("inverse must finish")
  }
  match divide(a, b, @oracle.nat(100)).unwrap() {
    DivisionReady(value, proof) => {
      assert_true(check_quotient(proof))
      assert_true(check_quotient_result(value, proof))
      let forged = DivisionReady(wrong, proof)
      match forged {
        DivisionReady(payload, certificate) =>
          assert_false(check_quotient_result(payload, certificate))
        _ => fail("forged quotient variant")
      }
    }
    _ => fail("quotient must finish")
  }
  match compare(a, b, @oracle.nat(100)).unwrap() {
    Compared(order, proof) => {
      assert_true(check_comparison(proof))
      assert_true(check_comparison_result(order, proof))
      let forged = Compared(Greater, proof)
      match forged {
        Compared(payload, certificate) =>
          assert_false(check_comparison_result(payload, certificate))
        _ => fail("forged comparison variant")
      }
    }
    _ => fail("comparison must finish")
  }
}
