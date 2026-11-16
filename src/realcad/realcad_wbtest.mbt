///|
fn poly(coefficients : Array[Int32]) -> @polynomial.Polynomial {
  @polynomial.polynomial(
    @oracle.nat(1),
    @oracle.chain(
      [
        for i in 0..<coefficients.length() => {
          @polynomial.Term::{
            coefficient: @oracle.rational(coefficients[i], 1),
            exponents: @core.Cons(@oracle.nat(i), Nil),
          }
        }
      ],
    ),
  ).unwrap()
}

///|
fn solve(input : Formula) -> Decomposition raise {
  let problem = prepare(input).unwrap()
  match run(start(problem), @oracle.nat(4096)) {
    Complete(result) => {
      assert_true(check(problem, certificate(result)) is Some(_))
      match witness(result) {
        Some(sample) => assert_true(check_witness(problem, sample))
        None => ()
      }
      match counterexample(result) {
        Some(sample) => assert_eq(evaluate_sample(problem, sample), Some(false))
        None => ()
      }
      result
    }
    _ => abort("small real decomposition did not finish")
  }
}

///|
test "irrational-only solutions and universal Boolean combinations" {
  let p = poly([-2, 0, 1])
  let x = poly([0, 1])
  let problem = prepare(Conjunction(Atom(p, EqualZero), Atom(x, GreaterZero))).unwrap()
  let result = solve(formula(problem))
  assert_false(universally_true(result))
  match witness(result).unwrap() {
    RationalPoint(_) => fail("sqrt(2) is not represented by a rational sample")
    AlgebraicPoint(interval) => {
      assert_eq(evaluate_sample(problem, AlgebraicPoint(interval)), Some(true))
      assert_eq(
        @exact.rational_compare(interval.upper, @oracle.rational(0, 1)),
        Greater,
      )
    }
  }
  assert_true(
    witness(solve(Conjunction(Atom(p, EqualZero), Atom(p, GreaterZero))))
    is None,
  )
  let q = poly([-3, 0, 1])
  assert_true(
    universally_true(
      solve(Disjunction(Atom(p, GreaterZero), Atom(q, LessZero))),
    ),
  )
  assert_false(
    universally_true(
      solve(Conjunction(Atom(p, GreaterZero), Atom(q, LessZero))),
    ),
  )
  assert_true(
    witness(solve(Conjunction(Atom(p, GreaterZero), Atom(q, LessZero))))
    is Some(_),
  )
}

///|
test "constant zero, nonzero constants, negation and validation of arity" {
  for truth in [false, true] {
    let result = solve(Truth(truth))
    assert_eq(@oracle.array(cells(result)).length(), 1)
    assert_eq(universally_true(result), truth)
    assert_eq(witness(result) is Some(_), truth)
  }
  let zero = poly([0])
  for
    relation in [
      LessZero,
      AtMostZero,
      EqualZero,
      NotZero,
      AtLeastZero,
      GreaterZero,
    ] {
    let expected = match relation {
      AtMostZero | EqualZero | AtLeastZero => true
      _ => false
    }
    assert_eq(universally_true(solve(Atom(zero, relation))), expected)
    assert_eq(
      universally_true(solve(Negation(Atom(zero, relation)))),
      !expected,
    )
  }
  assert_true(universally_true(solve(Atom(poly([-3]), LessZero))))
  assert_true(witness(solve(Atom(poly([-3]), GreaterZero))) is None)
  assert_eq(
    prepare(Atom(@polynomial.zero(@oracle.nat(2)), EqualZero)),
    Err(NotUnivariate),
  )
  assert_eq(
    prepare(
      Atom(
        @polynomial.constant(@oracle.nat(0), @oracle.rational(1, 1)),
        GreaterZero,
      ),
    ),
    Err(NotUnivariate),
  )
}

///|
test "shared and repeated roots, touching isolation endpoints and resumable fuel" {
  let p = poly([1, -2, 1])
  let q = poly([-2, 1, 1])
  let formula = Disjunction(Atom(p, AtLeastZero), Atom(q, LessZero))
  let problem = prepare(formula).unwrap()
  let initial = start(problem)
  assert_eq(run(initial, Zero), Paused(initial))
  let expected = solve(formula)
  assert_true(universally_true(expected))
  assert_eq(@oracle.array(roots(expected)).length(), 2)
  assert_eq(@oracle.array(cells(expected)).length(), 5)
  let mut state = initial
  let mut completed = false
  for _ in 0..<4096 {
    match run(state, @oracle.nat(1)) {
      Paused(next) => state = next
      Complete(actual) => {
        assert_eq(actual, expected)
        completed = true
        break
      }
      Fault => fail("unexpected exact arithmetic invariant failure")
    }
  }
  assert_true(completed)
  assert_eq(
    @oracle.array(
      polynomials(
        prepare(Conjunction(Atom(p, EqualZero), Atom(p, NotZero))).unwrap(),
      ),
    ).length(),
    1,
  )
}

///|
test "certificate coverage, ordering, signs, samples and truth are checked" {
  let p = poly([-2, 0, 1])
  let problem = prepare(Atom(p, EqualZero)).unwrap()
  let result = solve(formula(problem))
  let good = certificate(result)
  assert_true(check(problem, good) is Some(_))
  assert_true(check(problem, { ..good, roots: Nil, }) is None)
  assert_true(
    check(problem, { ..good, roots: @core.reverse(good.roots), }) is None,
  )
  assert_true(check(problem, { ..good, cells: Nil, }) is None)
  let array = @oracle.array(good.cells)
  for i in 0..<array.length() {
    let fake = array.copy()
    fake[i] = { ..fake[i], holds: !fake[i].holds, }
    assert_true(check(problem, { ..good, cells: @oracle.chain(fake), }) is None)
    fake[i] = { ..array[i], signs: Nil, }
    assert_true(check(problem, { ..good, cells: @oracle.chain(fake), }) is None)
    fake[i] = { ..array[i], sample: RationalPoint(@oracle.rational(99, 1)), }
    assert_true(check(problem, { ..good, cells: @oracle.chain(fake), }) is None)
  }
  for
    interval in [
      @sturm.Interval::{
        lower: @oracle.rational(-3, 1),
        upper: @oracle.rational(3, 1),
      },
      @sturm.Interval::{
        lower: @oracle.rational(0, 1),
        upper: @oracle.rational(1, 1),
      },
      @sturm.Interval::{
        lower: @oracle.rational(1, 1),
        upper: @oracle.rational(0, 1),
      },
    ] {
    assert_eq(evaluate_sample(problem, AlgebraicPoint(interval)), None)
  }
  assert_false(check_witness(problem, RationalPoint(@oracle.rational(0, 1))))
}
