///|
test "independent realalgebraic review new arithmetic payload checker rejects wrong Numbers and wrong conjugates" {
  let one = rational(@oracle.rational(1, 1)).unwrap()
  let two = rational(@oracle.rational(2, 1)).unwrap()
  let unrelated = rational(@oracle.rational(4, 1)).unwrap()
  let (correct, proof) = review_ready_binary(one, two, Sum)
  assert_true(check_arithmetic_result(correct, proof))
  assert_true(check_arithmetic(proof))
  let packaged = ArithmeticReady(unrelated, proof)
  match packaged {
    ArithmeticReady(value, certificate) =>
      assert_false(check_arithmetic_result(value, certificate))
    _ => fail("ready wrapper")
  }
  let rebound = { ..proof, result: root_certificate(unrelated), }
  assert_false(check_arithmetic_result(unrelated, rebound))
  // The API deliberately binds the exact representation, not arbitrary equal
  // Number representations. This equal root has a different valid interval.
  let equivalent = test_number([-3, 1], (5, 2), (3, 1))
  assert_compared(equivalent, correct, Equal, 0)
  assert_false(check_arithmetic_result(equivalent, proof))
  let a = test_number([-1, 0, 1], (0, 1), (1, 1))
  let b = test_number([0, -2, 1], (0, 1), (2, 1))
  for op in [Sum, Product] {
    let (actual, certificate) = review_ready_binary(a, b, op)
    assert_true(check_arithmetic_result(actual, certificate))
    let wrong : RootCertificate = {
      polynomial: certificate.result.polynomial,
      interval: if op == Sum {
        { lower: @oracle.rational(3, 4), upper: @oracle.rational(1, 1), }
      } else {
        { lower: @oracle.rational(-1, 4), upper: @oracle.rational(0, 1), }
      },
    }
    let other_conjugate = number(wrong).unwrap()
    assert_true(check_root(root_certificate(other_conjugate)))
    assert_true(check_arithmetic(certificate))
    assert_false(check_arithmetic_result(other_conjugate, certificate))
    assert_false(
      check_arithmetic_result(other_conjugate, {
        ..certificate,
        result: root_certificate(other_conjugate),
      }),
    )
  }
}

///|
test "independent realalgebraic review new unary and quotient payload checkers reject good proof with another root" {
  let a = test_number([-1, 0, 1], (0, 1), (1, 1))
  let opposite = test_number([-1, 0, 1], (-2, 1), (-1, 1))
  let unrelated = rational(@oracle.rational(7, 3)).unwrap()
  for operation in [Negation, Reciprocal] {
    let (value, proof) = review_ready_unary(a, operation)
    assert_true(check_unary_result(value, proof))
    assert_false(check_unary_result(unrelated, proof))
    let wrong = if operation == Negation { a } else { opposite }
    assert_true(check_root(root_certificate(wrong)))
    assert_false(check_unary_result(wrong, proof))
    assert_false(
      check_unary_result(wrong, { ..proof, result: root_certificate(wrong), }),
    )
  }
  let b = test_number([0, -2, 1], (0, 1), (2, 1))
  match divide(a, b, @oracle.nat(100)).unwrap() {
    DivisionReady(value, proof) => {
      assert_true(check_quotient_result(value, proof))
      assert_true(check_quotient(proof))
      assert_false(check_quotient_result(unrelated, proof))
      let negative_half = number({
        polynomial: proof.product.result.polynomial,
        interval: {
          lower: @oracle.rational(-3, 4),
          upper: @oracle.rational(-1, 4),
        },
      }).unwrap()
      assert_false(check_quotient_result(negative_half, proof))
      assert_false(
        check_quotient_result(negative_half, {
          ..proof,
          product: { ..proof.product, result: root_certificate(negative_half), },
        }),
      )
    }
    _ => fail("small quotient must complete")
  }
}

///|
test "independent realalgebraic review new comparison payload checker binds all three orderings" {
  let one = rational(@oracle.rational(1, 1)).unwrap()
  let two = rational(@oracle.rational(2, 1)).unwrap()
  for
    (a, b, expected) in [
      (one, two, @core.Less),
      (two, one, @core.Greater),
      (one, one, @core.Equal),
    ] {
    match compare(a, b, Zero).unwrap() {
      Compared(order, proof) => {
        assert_eq(order, expected)
        assert_true(check_comparison_result(order, proof))
        for proposed in [@core.Less, @core.Equal, @core.Greater] {
          assert_eq(
            check_comparison_result(proposed, proof),
            proposed == expected,
          )
          if proposed != expected {
            assert_true(check_comparison(proof))
            assert_false(
              check_comparison_result(proposed, { ..proof, order: proposed, }),
            )
          }
        }
      }
      _ => fail("comparison must complete")
    }
  }
}
