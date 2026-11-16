///|
fn test_rational(real : (Int32, Int32), imaginary : (Int32, Int32)) -> Number {
  rational(
    @oracle.rational(real.0, real.1),
    @oracle.rational(imaginary.0, imaginary.1),
  ).unwrap()
}

///|
fn test_real(
  coefficients : Array[Int32],
  lower : (Int32, Int32),
  upper : (Int32, Int32),
) -> @realalgebraic.Number {
  let terms = coefficients.mapi(fn(i, c) {
    @poly.Term::{
      coefficient: @oracle.rational(c, 1),
      exponents: Cons(@oracle.nat(i), Nil),
    }
  })
  @realalgebraic.number({
    polynomial: @poly.polynomial(Succ(Zero), @oracle.chain(terms)).unwrap(),
    interval: {
      lower: @oracle.rational(lower.0, lower.1),
      upper: @oracle.rational(upper.0, upper.1),
    },
  }).unwrap()
}

///|
fn test_run(
  left : Number,
  right : Number,
  operation : Operation,
) -> (Number, ArithmeticCertificate) {
  match run(left, right, operation, @oracle.nat(250)).unwrap() {
    ArithmeticReady(value, proof) => {
      guard check_arithmetic_for(left, right, operation, value, proof) else {
        abort("arithmetic certificate rejected")
      }
      (value, proof)
    }
    ArithmeticPaused(_) => abort("arithmetic fixture unexpectedly paused")
  }
}

///|
fn assert_same(left : Number, right : Number) -> Unit raise {
  match equal(left, right, @oracle.nat(80)).unwrap() {
    EqualityReady(result, proof) => {
      assert_true(result)
      assert_true(check_equality_for(left, right, result, proof))
    }
    EqualityPaused(_) => fail("equality unexpectedly paused")
  }
}

///|
test "Gaussian rational grid agrees with independent integer formulas" {
  // Coordinates share denominator two. Expected numerators are computed with
  // host integers only in this test, independently of the production formulas.
  let grid = [(0, 0), (1, -2), (-3, 1), (2, 2)]
  let mut count = 0
  for (a, b) in grid {
    let left = test_rational((a, 2), (b, 2))
    for (c, d) in grid {
      let right = test_rational((c, 2), (d, 2))
      let (sum, sum_proof) = test_run(left, right, Addition)
      assert_same(sum, test_rational((a + c, 2), (b + d, 2)))
      assert_true(@core.all(sum_proof.steps, fn(s) { s is RationalStep(_) }))
      let (difference, _) = test_run(left, right, Subtraction)
      assert_same(difference, test_rational((a - c, 2), (b - d, 2)))
      let (product, _) = test_run(left, right, Multiplication)
      assert_same(
        product,
        test_rational((a * c - b * d, 4), (a * d + b * c, 4)),
      )
      count += 3
      if c == 0 && d == 0 {
        assert_true(
          divide(left, right, Zero) is Err(@realalgebraic.ZeroDivisor),
        )
      } else {
        let (quotient, _) = test_run(left, right, Division)
        assert_same(
          quotient,
          test_rational(
            (a * c + b * d, c * c + d * d),
            (b * c - a * d, c * c + d * d),
          ),
        )
        count += 1
      }
    }
  }
  assert_eq(count, 60)
}

///|
test "imaginary unit square and conjugation have exact signed coordinates" {
  let i = test_rational((0, 1), (1, 1))
  let minus_one = test_rational((-1, 1), (0, 1))
  let (square, _) = test_run(i, i, Multiplication)
  assert_same(square, minus_one)
  let z = test_rational((-3, 2), (4, 3))
  match conjugate(z, @oracle.nat(1)).unwrap() {
    ArithmeticReady(value, proof) => {
      assert_same(value, test_rational((-3, 2), (-4, 3)))
      assert_true(check_arithmetic_for(z, z, Conjugation, value, proof))
      assert_true(proof.result.real.equal(proof.left.real))
    }
    _ => fail("one rational conjugation instruction must finish")
  }
  match negate(z, @oracle.nat(2)).unwrap() {
    ArithmeticReady(value, proof) => {
      assert_same(value, test_rational((3, 2), (-4, 3)))
      assert_true(check_arithmetic_for(z, z, Negation, value, proof))
    }
    _ => fail("two rational negation instructions must finish")
  }
}

///|
test "sqrt2 plus sqrt3 and mixed algebraic multiplication select true roots" {
  let zero = @realalgebraic.rational(@oracle.rational(0, 1)).unwrap()
  let one = @realalgebraic.rational(@oracle.rational(1, 1)).unwrap()
  let sqrt2 = test_real([-2, 0, 1], (7, 5), (3, 2))
  let sqrt3 = test_real([-3, 0, 1], (5, 3), (7, 4))
  let a = number(sqrt2, zero)
  let b = number(sqrt3, one)
  let (sum, _) = test_run(a, b, Addition)
  let expected_sum = number(test_real([1, 0, -10, 0, 1], (3, 1), (4, 1)), one)
  assert_same(sum, expected_sum)
  let (product, proof) = test_run(a, b, Multiplication)
  assert_same(product, number(test_real([-6, 0, 1], (2, 1), (3, 1)), sqrt2))
  assert_true(@core.any(proof.steps, fn(s) { s is BinaryStep(_) }))
  let (difference, _) = test_run(a, a, Subtraction)
  assert_true(is_zero(difference))
}

///|
test "algebraic division by a real rational binds both quotient coordinates" {
  let zero = @realalgebraic.rational(@oracle.rational(0, 1)).unwrap()
  let one = @realalgebraic.rational(@oracle.rational(1, 1)).unwrap()
  let a = number(test_real([-2, 0, 1], (7, 5), (3, 2)), one)
  let b = test_rational((2, 1), (0, 1))
  let (quotient, proof) = test_run(a, b, Division)
  assert_same(
    quotient,
    number(
      test_real([-1, 0, 2], (2, 3), (3, 4)),
      @realalgebraic.rational(@oracle.rational(1, 2)).unwrap(),
    ),
  )
  assert_true(@core.any(proof.steps, fn(s) { s is DivisionStep(_) }))
  let numerator = number(zero, one)
  let (complex_quotient, _) = test_run(numerator, a, Division)
  // i/(sqrt2+i) = (1+sqrt2*i)/3.
  assert_same(
    complex_quotient,
    number(
      @realalgebraic.rational(@oracle.rational(1, 3)).unwrap(),
      test_real([-2, 0, 9], (2, 5), (1, 2)),
    ),
  )
}

///|
test "rational fuel boundary and repeated single units preserve completed work" {
  let a = test_rational((1, 2), (2, 3))
  let b = test_rational((3, 4), (-4, 5))
  let initial = arithmetic_start(a, b, Division).unwrap()
  assert_true(arithmetic_advance(initial, Zero).unwrap() is ArithmeticPaused(_))
  let waiting = match arithmetic_advance(initial, @oracle.nat(5)).unwrap() {
    ArithmeticPaused(state) => state
    _ => abort("division has twelve rational instructions")
  }
  assert_eq(@oracle.int_of_nat(@core.length(waiting.values)), 5)
  assert_eq(@oracle.int_of_nat(@core.length(waiting.proofs)), 5)
  let mut progress = ArithmeticPaused(waiting)
  for _ in 0..<7 {
    progress = match progress {
      ArithmeticPaused(state) => arithmetic_advance(state, Succ(Zero)).unwrap()
      _ => abort("division cannot finish before twelve startups")
    }
  }
  match progress {
    ArithmeticReady(value, proof) => {
      let (single, direct) = test_run(a, b, Division)
      assert_true(certificate(value).equal(certificate(single)))
      assert_true(proof.equal(direct))
    }
    _ => fail("division must finish at twelve units")
  }
}

///|
test "algebraic pause resumes active resultants without inventing a result" {
  let zero = @realalgebraic.rational(@oracle.rational(0, 1)).unwrap()
  let a = number(test_real([-2, 0, 1], (1, 1), (2, 1)), zero)
  let b = number(test_real([-3, 0, 1], (1, 1), (2, 1)), zero)
  let waiting = match add(a, b, Succ(Zero)).unwrap() {
    ArithmeticPaused(state) => state
    _ => abort("one startup cannot finish the resultant")
  }
  assert_true(waiting.active is Some(BinaryJob(_)))
  assert_true(waiting.values is Nil)
  match arithmetic_advance(waiting, @oracle.nat(60)).unwrap() {
    ArithmeticReady(value, proof) => {
      assert_true(check_arithmetic_for(a, b, Addition, value, proof))
      assert_same(
        value,
        number(test_real([1, 0, -10, 0, 1], (3, 1), (4, 1)), zero),
      )
    }
    _ => fail("resumed sum must finish")
  }
}

///|
test "arithmetic certificates reject changed sources formulas traces and payloads" {
  let a = test_rational((1, 2), (2, 3))
  let b = test_rational((3, 4), (-4, 5))
  let wrong = test_rational((7, 1), (1, 1))
  let (value, proof) = test_run(a, b, Multiplication)
  assert_false(check_arithmetic_for(b, a, Multiplication, value, proof))
  assert_false(check_arithmetic_for(a, b, Addition, value, proof))
  assert_false(check_arithmetic_result(wrong, proof))
  assert_false(check_arithmetic({ ..proof, left: certificate(wrong), }))
  assert_false(check_arithmetic({ ..proof, right: certificate(wrong), }))
  assert_false(check_arithmetic({ ..proof, operation: Division, }))
  assert_false(check_arithmetic({ ..proof, result: certificate(wrong), }))
  assert_false(
    check_arithmetic({
      ..proof,
      steps: Cons(
        RationalStep(certificate(wrong).real),
        @core.drop(Succ(Zero), proof.steps),
      ),
    }),
  )
  assert_false(
    check_arithmetic({ ..proof, steps: @core.reverse(proof.steps), }),
  )
  assert_false(
    check_arithmetic({ ..proof, steps: @core.drop(Succ(Zero), proof.steps), }),
  )
  assert_false(
    check_arithmetic({
      ..proof,
      steps: Cons(RationalStep(certificate(wrong).real), proof.steps),
    }),
  )
  let first = @core.nth(proof.steps, Zero).unwrap()
  assert_false(
    check_arithmetic({
      ..proof,
      steps: Cons(first, @core.drop(Succ(Succ(Zero)), proof.steps)),
    }),
  )
  let refined = number(
    @realalgebraic.refine(value.real, Succ(Zero)).unwrap(),
    value.imaginary,
  )
  assert_same(value, refined)
  assert_false(check_arithmetic_result(refined, proof))
}

///|
test "zero detection and division errors respect the selected algebraic root" {
  let zero = test_real([0, -2, 1], (-1, 1), (0, 1))
  let two = test_real([0, -2, 1], (1, 1), (3, 1))
  let z = number(zero, zero)
  let nonzero = number(zero, two)
  let excluded_zero = number(test_real([0, -1, 1], (0, 1), (2, 1)), zero)
  assert_true(is_zero(z))
  assert_false(is_zero(nonzero))
  assert_false(is_zero(excluded_zero))
  assert_true(divide(nonzero, z, Zero) is Err(@realalgebraic.ZeroDivisor))
  let (value, proof) = test_run(z, nonzero, Division)
  assert_true(is_zero(value))
  assert_true(check_arithmetic_for(z, nonzero, Division, value, proof))
}

///|
test "embedded real witnesses reject a valid wrong conjugate and changed operation" {
  let zero = @realalgebraic.rational(@oracle.rational(0, 1)).unwrap()
  let a = number(test_real([-2, 0, 1], (1, 1), (2, 1)), zero)
  let b = number(test_real([-3, 0, 1], (1, 1), (2, 1)), zero)
  let (_, proof) = test_run(a, b, Addition)
  let wrong = number(test_real([1, 0, -10, 0, 1], (-4, 1), (-3, 1)), zero)
  assert_true(check_number(certificate(wrong)))
  match proof.steps {
    Cons(BinaryStep(child), rest) => {
      let forged = { ..child, result: certificate(wrong).real, }
      assert_false(
        check_arithmetic({
          ..proof,
          steps: Cons(BinaryStep(forged), rest),
          result: certificate(wrong),
        }),
      )
      assert_false(
        check_arithmetic({
          ..proof,
          steps: Cons(
            BinaryStep({
              ..child,
              resultant: {
                ..child.resultant,
                operation: @realalgebraic.Product,
              },
            }),
            rest,
          ),
        }),
      )
      assert_false(
        check_arithmetic({
          ..proof,
          steps: Cons(BinaryStep({ ..child, left: certificate(b).real, }), rest),
        }),
      )
    }
    _ => fail("the first algebraic sum must contain its real witness")
  }
  let bad_source = {
    ..proof.left.real,
    interval: { lower: @oracle.rational(3, 1), upper: @oracle.rational(4, 1), },
  }
  assert_false(check_number({ ..proof.left, real: bad_source, }))
}

///|
test "numeric equality survives changed definition and binds its bool result" {
  let zero = @realalgebraic.rational(@oracle.rational(0, 1)).unwrap()
  let a = number(test_real([-2, 0, 1], (1, 1), (2, 1)), zero)
  // (x*x-2)*(x-3): same sqrt2, additional distinct root outside its interval.
  let b = number(test_real([6, -2, -3, 1], (7, 5), (3, 2)), zero)
  assert_false(certificate(a).equal(certificate(b)))
  match equal(a, b, Zero).unwrap() {
    EqualityReady(result, proof) => {
      assert_true(result)
      assert_true(check_equality_for(a, b, true, proof))
      assert_false(check_equality_result(false, proof))
      assert_false(check_equality({ ..proof, equal: false, }))
      assert_false(check_equality({ ..proof, left: proof.right, }))
      assert_false(
        check_equality({ ..proof, real: { ..proof.real, order: Less, }, }),
      )
    }
    _ => fail("common-root equality needs no refinement")
  }
  let close = number(test_real([-2049, 0, 1024], (1, 1), (2, 1)), zero)
  let waiting = match equal(a, close, Zero).unwrap() {
    EqualityPaused(state) => state
    _ => abort("overlap without a common root is undecided")
  }
  match equality_advance(waiting, @oracle.nat(25)).unwrap() {
    EqualityReady(result, proof) => {
      assert_false(result)
      assert_true(check_equality_for(a, close, false, proof))
      assert_false(check_equality_for(close, a, false, proof))
    }
    _ => fail("distinct nearby algebraic roots must separate")
  }
  let ai = number(zero, a.real)
  let bi = number(zero, close.real)
  let waiting_imaginary = match equal(ai, bi, Zero).unwrap() {
    EqualityPaused(state) => state
    _ => abort("imaginary comparison also preserves an undecided state")
  }
  assert_true(waiting_imaginary.phase is ImaginaryCoordinate(_, _))
  match equality_advance(waiting_imaginary, @oracle.nat(25)).unwrap() {
    EqualityReady(result, proof) => {
      assert_false(result)
      assert_true(check_equality_for(ai, bi, false, proof))
      assert_false(check_equality({ ..proof, imaginary: proof.real, }))
    }
    _ => fail("resumed imaginary coordinates must separate")
  }
}
