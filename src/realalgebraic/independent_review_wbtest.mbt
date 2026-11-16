///|
fn assert_review_resultant(
  a : Array[(Int32, Int32)],
  b : Array[(Int32, Int32)],
  operation : BinaryOperation,
  expected : Array[(Int32, Int32)],
  samples : Array[(Int32, Int32)],
) -> Unit raise {
  let left = test_polynomial(a)
  let right = test_polynomial(b)
  let state = resultant_start(left, right, operation).unwrap()
  let bound = (a.length() - 1) * (b.length() - 1)
  let pending = match resultant_advance(state, @oracle.nat(bound)).unwrap() {
    ResultantPaused(state) => state
    _ => abort("independent bound requires one additional sample")
  }
  let proof = match resultant_advance(pending, Succ(Zero)).unwrap() {
    ResultantReady(proof) => proof
    _ => abort("independent bound completed but producer paused")
  }
  assert_eq(proof.polynomial, test_polynomial(expected))
  assert_eq(
    proof.samples,
    @oracle.chain(samples.map(fn(p) { @oracle.rational(p.0, p.1) })),
  )
  assert_true(check_resultant(proof))
  // Degree-bound attack: a different polynomial agreeing at every sample.
  let vanishing = for i = 0, p = test_integer_polynomial([1]); i <= bound; {
    continue i + 1, @poly.multiply(p, test_integer_polynomial([-i, 1])).unwrap()
  } nobreak {
    p
  }
  let forged = @poly.add(proof.polynomial, vanishing).unwrap()
  for i in 0..<=bound {
    assert_eq(
      @poly.evaluate(forged, @oracle.chain([@oracle.rational(i, 1)])),
      @poly.evaluate(proof.polynomial, @oracle.chain([@oracle.rational(i, 1)])),
    )
  }
  assert_false(check_resultant({ ..proof, polynomial: forged, }))
  assert_false(
    check_resultant({ ..proof, samples: @core.drop(Succ(Zero), proof.samples), }),
  )
  assert_false(
    check_resultant({
      ..proof,
      samples: @core.append(
        proof.samples,
        @oracle.chain([@oracle.rational(0, 1)]),
      ),
    }),
  )
  match proof.samples {
    Cons(first, rest) =>
      assert_false(
        check_resultant({
          ..proof,
          samples: Cons(@exact.rational_add(first, @exact.rational_one()), rest),
        }),
      )
    _ => fail("resultant proof requires samples")
  }
}

///|
fn review_interval(lower : Int32, upper : Int32) -> @sturm.Interval {
  { lower: @oracle.rational(lower, 2), upper: @oracle.rational(upper, 2), }
}

///|
test "independent realalgebraic review 882 closed product sum enclosures and reciprocal padding formulas" {
  let keys = [-4, -2, -1, 0, 1, 2, 4]
  let mut binary_checks = 0
  let mut inverse_checks = 0
  for li in 0..<keys.length() {
    for ui in (li + 1)..<keys.length() {
      let l = keys[li]
      let u = keys[ui]
      let a = review_interval(l, u)
      let neg = unary_interval(a, Negation).unwrap()
      assert_eq(neg.lower, @oracle.rational(-u - (u - l), 2))
      assert_eq(neg.upper, @oracle.rational(-l + (u - l), 2))
      let inverse = unary_interval(a, Reciprocal)
      if l > 0 || u < 0 {
        let bounds = inverse.unwrap()
        assert_eq(bounds.lower, @oracle.rational(4 * l - 2 * u, l * u))
        assert_eq(bounds.upper, @oracle.rational(4 * u - 2 * l, l * u))
      } else {
        assert_eq(inverse, None)
      }
      inverse_checks += 1
      for rli in 0..<keys.length() {
        for rui in (rli + 1)..<keys.length() {
          let r = keys[rli]
          let s = keys[rui]
          let b = review_interval(r, s)
          let padding = u - l + (s - r)
          let corners = [l * r, l * s, u * r, u * s]
          let mut smallest = corners[0]
          let mut largest = corners[0]
          for c in corners {
            if c < smallest {
              smallest = c
            }
            if c > largest {
              largest = c
            }
          }
          let product = binary_interval(a, b, Product)
          let pl = smallest - 2 * padding
          let pu = largest + 2 * padding
          assert_eq(product.lower, @oracle.rational(pl, 4))
          assert_eq(product.upper, @oracle.rational(pu, 4))
          let sum = binary_interval(a, b, Sum)
          let sl = 2 * l + 2 * r - 2 * padding
          let su = 2 * u + 2 * s + 2 * padding
          assert_eq(sum.lower, @oracle.rational(sl, 4))
          assert_eq(sum.upper, @oracle.rational(su, 4))
          // Test actual included upper endpoints and interior midpoints. All
          // four selected values must lie STRICTLY inside the padded ranges.
          for av in [2 * u, l + u] {
            for bv in [2 * s, r + s] {
              assert_true(4 * pl < av * bv && av * bv < 4 * pu)
              assert_true(sl < av + bv && av + bv < su)
            }
          }
          binary_checks += 2
        }
      }
    }
  }
  assert_eq(binary_checks, 882)
  assert_eq(inverse_checks, 21)
}

///|
fn review_ready_binary(
  a : Number,
  b : Number,
  op : BinaryOperation,
) -> (Number, ArithmeticCertificate) {
  match
    arithmetic_advance(arithmetic_start(a, b, op).unwrap(), @oracle.nat(100)).unwrap() {
    ArithmeticReady(number, proof) => (number, proof)
    _ => abort("independent review arithmetic did not complete")
  }
}

///|
fn review_ready_unary(
  a : Number,
  op : UnaryOperation,
) -> (Number, UnaryCertificate) {
  match unary_advance(unary_start(a, op).unwrap(), @oracle.nat(100)).unwrap() {
    UnaryReady(number, proof) => (number, proof)
    _ => abort("independent review unary did not complete")
  }
}

///|
test "independent realalgebraic review nonminimal rational roots upper endpoints and valid wrong result certificates" {
  let as_ = [
    test_number([-1, 0, 1], (-2, 1), (-1, 1)),
    test_number([-1, 0, 1], (0, 1), (1, 1)),
  ]
  let bs = [
    test_number([0, -2, 1], (-1, 1), (0, 1)),
    test_number([0, -2, 1], (0, 1), (2, 1)),
  ]
  for ai in 0..<2 {
    for bi in 0..<2 {
      let a = [-1, 1][ai]
      let b = [0, 2][bi]
      for op in [Sum, Product] {
        let (value, proof) = review_ready_binary(as_[ai], bs[bi], op)
        let expected = if op == Sum { a + b } else { a * b }
        assert_true(check_arithmetic(proof))
        assert_compared(
          value,
          rational(@oracle.rational(expected, 1)).unwrap(),
          Equal,
          0,
        )
        let roots = if op == Sum { [-1, 1, 3] } else { [-2, 0, 2] }
        for wrong in roots {
          if wrong == expected {
            continue
          }
          let other : RootCertificate = {
            polynomial: proof.result.polynomial,
            interval: {
              lower: @oracle.rational(4 * wrong - 1, 4),
              upper: @oracle.rational(wrong, 1),
            },
          }
          assert_true(check_root(other))
          assert_false(check_arithmetic({ ..proof, result: other, }))
        }
        let unrelated = root_certificate(
          rational(@oracle.rational(19, 3)).unwrap(),
        )
        assert_true(check_root(unrelated))
        assert_false(check_arithmetic({ ..proof, result: unrelated, }))
        let same_value_other_interval : RootCertificate = {
          polynomial: proof.result.polynomial,
          interval: {
            lower: @oracle.rational(4 * expected - 1, 4),
            upper: @oracle.rational(expected, 1),
          },
        }
        assert_true(check_root(same_value_other_interval))
        assert_false(
          check_arithmetic({ ..proof, result: same_value_other_interval, }),
        )
        assert_false(
          check_arithmetic({ ..proof, left_refined: interval(as_[1 - ai]), }),
        )
        assert_false(
          check_arithmetic({
            ..proof,
            resultant: {
              ..proof.resultant,
              operation: if op == Sum {
                Product
              } else {
                Sum
              },
            },
          }),
        )
      }
    }
  }
  assert_true(inverse(bs[0], @oracle.nat(100)) is Err(ZeroDivisor))
  let (half, inverse_proof) = review_ready_unary(bs[1], Reciprocal)
  assert_true(check_unary(inverse_proof))
  assert_compared(half, rational(@oracle.rational(1, 2)).unwrap(), Equal, 0)
  // Zero is present in the definition but excluded at the lower interval end.
  let nonminimal_half = test_number([0, -1, 2], (0, 1), (1, 1))
  assert_true(inverse(nonminimal_half, Zero).unwrap() is UnaryPaused(_))
  let (twice, proof) = review_ready_unary(nonminimal_half, Reciprocal)
  assert_true(check_unary(proof))
  assert_compared(twice, rational(@oracle.rational(2, 1)).unwrap(), Equal, 0)
}

///|
test "independent realalgebraic review irrational cancellation opposite conjugates and zero factors in nonminimal definitions" {
  for d in [2, 3] {
    let positive = test_number([0, -d, 0, 1], (1, 1), (2, 1))
    let negative = test_number([-d, 0, 1], (-2, 1), (-1, 1))
    let (sum, sp) = review_ready_binary(positive, negative, Sum)
    assert_true(check_arithmetic(sp))
    assert_compared(sum, rational(@oracle.rational(0, 1)).unwrap(), Equal, 0)
    let (product, pp) = review_ready_binary(positive, negative, Product)
    assert_true(check_arithmetic(pp))
    assert_compared(
      product,
      rational(@oracle.rational(-d, 1)).unwrap(),
      Equal,
      0,
    )
    let (inverse, ip) = review_ready_unary(positive, Reciprocal)
    assert_true(check_unary(ip))
    let expected = test_number([-1, 0, d], (0, 1), (1, 1))
    assert_compared(inverse, expected, Equal, 0)
    let (negated, np) = review_ready_unary(positive, Negation)
    assert_true(check_unary(np))
    assert_compared(negated, negative, Equal, 0)
    let wrong = root_certificate(expected)
    assert_true(check_root(wrong))
    assert_false(check_unary({ ..np, result: wrong, }))
    let opposite = test_number([-1, 0, d], (-1, 1), (0, 1))
    assert_false(check_unary({ ..ip, result: root_certificate(opposite), }))
    // Repeated nonminimal defining factors normalize to the same selected root.
    let repeated = test_number([0, d * d, 0, -2 * d, 0, 1], (1, 1), (2, 1))
    assert_compared(repeated, positive, Equal, 0)
  }
}

///|
test "independent realalgebraic review proof-only checker does not authenticate a separately supplied Number payload" {
  let a = rational(@oracle.rational(1, 1)).unwrap()
  let b = rational(@oracle.rational(2, 1)).unwrap()
  let wrong = rational(@oracle.rational(4, 1)).unwrap()
  let (correct, proof) = review_ready_binary(a, b, Sum)
  assert_true(check_arithmetic(proof))
  assert_eq(root_certificate(correct), proof.result)
  assert_false(root_certificate(wrong).equal(proof.result))
  // The public enum can package an independently valid, unrelated Number with
  // a good certificate. The existing checker intentionally sees only proof.
  let substituted = ArithmeticReady(wrong, proof)
  match substituted {
    ArithmeticReady(value, certificate) => {
      assert_true(check_arithmetic(certificate))
      assert_false(root_certificate(value).equal(certificate.result))
    }
    _ => fail("constructed ready wrapper")
  }
  match compare(a, b, Zero).unwrap() {
    Compared(order, comparison_proof) => {
      assert_eq(order, Less)
      assert_true(check_comparison(comparison_proof))
      let substituted_order = Compared(Greater, comparison_proof)
      match substituted_order {
        Compared(value, proof) => {
          assert_true(check_comparison(proof))
          assert_false(value.equal(proof.order))
        }
        _ => fail("constructed comparison wrapper")
      }
    }
    _ => fail("rational comparison must complete")
  }
  let (negative, unary_proof) = review_ready_unary(a, Negation)
  assert_true(check_unary(unary_proof))
  assert_eq(root_certificate(negative), unary_proof.result)
  assert_false(root_certificate(wrong).equal(unary_proof.result))
  match divide(a, b, @oracle.nat(20)).unwrap() {
    DivisionReady(value, quotient_proof) => {
      assert_true(check_quotient(quotient_proof))
      assert_eq(root_certificate(value), quotient_proof.product.result)
      assert_false(root_certificate(wrong).equal(quotient_proof.product.result))
    }
    _ => fail("small quotient must complete")
  }
}
