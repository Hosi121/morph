///|
fn review_boundary_problem() -> Problem {
  let x = review_polynomial([@oracle.rational(0, 1), @oracle.rational(1, 1)])
  let q = review_polynomial([@oracle.rational(-1, 1), @oracle.rational(257, 1)])
  prepare(Conjunction(Atom(x, AtLeastZero), Atom(q, AtMostZero))).unwrap()
}

///|
fn review_touching_machine(problem : Problem) -> Machine {
  let intervals = @oracle.chain([
    @sturm.Interval::{
      lower: @oracle.rational(-1, 1),
      upper: @oracle.rational(0, 1),
    },
    @sturm.Interval::{
      lower: @oracle.rational(0, 1),
      upper: @oracle.rational(1, 1),
    },
  ])
  { problem, phase: Separating(intervals), }
}

///|
test "independent realcad review half open lower roots are excluded and upper roots included" {
  let problem = review_boundary_problem()
  for upper in [@oracle.rational(1, 257), @oracle.rational(1, 1)] {
    let sample = AlgebraicPoint(@sturm.Interval::{
      lower: @oracle.rational(0, 1),
      upper,
    })
    let cell = classify(problem, sample).unwrap()
    assert_eq(@oracle.array(cell.signs), [@core.Greater, @core.Equal])
    assert_true(cell.holds)
    assert_eq(evaluate_sample(problem, sample), Some(true))
    assert_true(check_witness(problem, sample))
  }
  let left = AlgebraicPoint(@sturm.Interval::{
    lower: @oracle.rational(-1, 1),
    upper: @oracle.rational(0, 1),
  })
  assert_eq(@oracle.array(classify(problem, left).unwrap().signs), [
    @core.Equal,
    @core.Less,
  ])
  assert_eq(evaluate_sample(problem, left), Some(true))
  for
    interval in [
      @sturm.Interval::{
        lower: @oracle.rational(0, 1),
        upper: @oracle.rational(1, 512),
      },
      @sturm.Interval::{
        lower: @oracle.rational(-1, 1),
        upper: @oracle.rational(1, 257),
      },
      @sturm.Interval::{
        lower: @oracle.rational(0, 1),
        upper: @oracle.rational(0, 1),
      },
      @sturm.Interval::{
        lower: @oracle.rational(1, 257),
        upper: @oracle.rational(0, 1),
      },
    ] {
    assert_eq(evaluate_sample(problem, AlgebraicPoint(interval)), None)
  }
}

///|
test "independent realcad review touching gap persists for eight steps then separates exactly" {
  let problem = review_boundary_problem()
  let initial = review_touching_machine(problem)
  for fuel in 0..<9 {
    match run(initial, @oracle.nat(fuel)) {
      Paused({ phase: Separating(intervals), .. }) => {
        let intervals = @oracle.array(intervals)
        assert_eq(intervals[0].upper, @oracle.rational(0, 1))
        assert_eq(intervals[1].lower, @oracle.rational(0, 1))
      }
      _ => fail("gap appeared before a midpoint fell below1/257")
    }
  }
  match run(initial, @oracle.nat(9)) {
    Paused({ phase: Separating(intervals), .. }) => {
      let intervals = @oracle.array(intervals)
      assert_eq(intervals[0].upper, @oracle.rational(0, 1))
      assert_eq(intervals[1].lower, @oracle.rational(1, 512))
      assert_eq(intervals[1].upper, @oracle.rational(1, 256))
    }
    _ => fail("ninth refinement should create the strict gap")
  }
  match run(initial, @oracle.nat(16)) {
    Complete(result) => {
      assert_true(check(problem, certificate(result)) is Some(_))
      assert_eq(@oracle.array(cells(result)).map(fn(cell) { cell.holds }), [
        false, true, true, true, false,
      ])
    }
    _ => fail("bounded touching interval completion")
  }
}

///|
test "independent realcad review all fuel boundaries and phase resumes preserve exact decomposition" {
  let problem = review_boundary_problem()
  let initial = start(problem)
  let mut machine = initial
  let mut steps = 0
  let mut result : Decomposition? = None
  let states : Array[Machine] = []
  for _ in 0..<256 {
    states.push(machine)
    match step(machine) {
      Paused(next) => {
        machine = next
        steps += 1
      }
      Complete(done) => {
        steps += 1
        result = Some(done)
        break
      }
      Fault => fail("valid review input must not fault")
    }
  }
  let expected = result.unwrap()
  assert_true(steps > 0)
  for fuel in 0..<steps {
    match run(initial, @oracle.nat(fuel)) {
      Paused(state) => {
        assert_eq(run(state, @oracle.nat(0)), Paused(state))
        assert_eq(run(state, @oracle.nat(steps - fuel)), Complete(expected))
      }
      _ => fail("completeness before sufficient fuel")
    }
  }
  for extra in [0, 1, 7, 100] {
    assert_eq(run(initial, @oracle.nat(steps + extra)), Complete(expected))
  }
  for state in states {
    assert_eq(run(state, @oracle.nat(0)), Paused(state))
    assert_eq(run(state, @oracle.nat(256)), Complete(expected))
  }
}

///|
test "independent realcad review forged covers cells signs truth and samples are rejected" {
  let problem = review_boundary_problem()
  let result = match run(start(problem), @oracle.nat(256)) {
    Complete(result) => result
    _ => abort("review completion")
  }
  let good = certificate(result)
  let intervals = @oracle.array(good.roots)
  let cells = @oracle.array(good.cells)
  assert_true(check(problem, good) is Some(_))
  for
    bad_roots in [
      @core.Nil,
      @oracle.chain([intervals[0]]),
      @oracle.chain([intervals[1]]),
      @oracle.chain([intervals[1], intervals[0]]),
      @oracle.chain([intervals[0], intervals[0]]),
      @oracle.chain([intervals[0], intervals[1], intervals[1]]),
      @oracle.chain([
        @sturm.Interval::{
          lower: @oracle.rational(-1, 1),
          upper: @oracle.rational(1, 1),
        },
        intervals[1],
      ]),
      @oracle.chain([
        @sturm.Interval::{
          lower: @oracle.rational(0, 1),
          upper: @oracle.rational(0, 1),
        },
        intervals[1],
      ]),
      @oracle.chain([
        @sturm.Interval::{
          lower: @oracle.rational(0, 1),
          upper: @oracle.rational(-1, 1),
        },
        intervals[1],
      ]),
      @oracle.chain([
        @sturm.Interval::{
          lower: @oracle.rational(-1, 1),
          upper: @oracle.rational(0, 1),
        },
        @sturm.Interval::{
          lower: @oracle.rational(0, 1),
          upper: @oracle.rational(1, 1),
        },
      ]),
    ] {
    assert_true(check(problem, { ..good, roots: bad_roots, }) is None)
  }
  assert_true(check(problem, { ..good, cells: @core.Nil, }) is None)
  assert_true(
    check(problem, {
      ..good,
      cells: @oracle.chain(cells[:cells.length() - 1].to_owned()),
    })
    is None,
  )
  assert_true(
    check(problem, { ..good, cells: @core.append(good.cells, good.cells), })
    is None,
  )
  for i in 0..<cells.length() {
    let sign_array = @oracle.array(cells[i].signs)
    for j in 0..<sign_array.length() {
      for sign in [@core.Less, @core.Equal, @core.Greater] {
        if sign != sign_array[j] {
          let wrong_signs = sign_array.copy()
          wrong_signs[j] = sign
          let bad = cells.copy()
          bad[i] = { ..cells[i], signs: @oracle.chain(wrong_signs), }
          assert_true(
            check(problem, { ..good, cells: @oracle.chain(bad), }) is None,
          )
        }
      }
    }
    for wrong_signs in [@core.Nil, @core.append(cells[i].signs, cells[i].signs)] {
      let bad = cells.copy()
      bad[i] = { ..cells[i], signs: wrong_signs, }
      assert_true(
        check(problem, { ..good, cells: @oracle.chain(bad), }) is None,
      )
    }
    let wrong_truth = cells.copy()
    wrong_truth[i] = { ..cells[i], holds: !cells[i].holds, }
    assert_true(
      check(problem, { ..good, cells: @oracle.chain(wrong_truth), }) is None,
    )
    let wrong_sample = cells.copy()
    wrong_sample[i] = {
      ..cells[i],
      sample: match cells[i].sample {
        RationalPoint(point) =>
          RationalPoint(@exact.rational_add(point, @exact.rational_one()))
        AlgebraicPoint(_) => RationalPoint(@exact.rational_zero())
      },
    }
    assert_true(
      check(problem, { ..good, cells: @oracle.chain(wrong_sample), }) is None,
    )
  }
  // A certificate binds samples and signs to the owning formula/problem.
  let other = prepare(Negation(formula(problem))).unwrap()
  assert_true(check(other, good) is None)
}

///|
test "independent realcad review zero constant normalization and duplicated atoms stay exact" {
  let zero = review_polynomial([
    @oracle.rational(0, 7),
    @oracle.rational(0, 13),
    @oracle.rational(0, 29),
  ])
  let negative = review_polynomial([@oracle.rational(-13, 29)])
  let formula = Conjunction(
    Disjunction(Atom(zero, EqualZero), Atom(negative, GreaterZero)),
    Negation(Conjunction(Atom(zero, NotZero), Atom(negative, AtMostZero))),
  )
  let problem = prepare(formula).unwrap()
  assert_eq(@oracle.array(polynomials(problem)).length(), 2)
  let result = match run(start(problem), @oracle.nat(16)) {
    Complete(result) => result
    _ => abort("constant review completion")
  }
  assert_eq(@oracle.array(roots(result)).length(), 0)
  assert_eq(@oracle.array(cells(result)).length(), 1)
  assert_eq(@oracle.array(@oracle.array(cells(result))[0].signs), [
    @core.Equal,
    @core.Less,
  ])
  assert_true(universally_true(result))
  assert_true(check(problem, certificate(result)) is Some(_))
  assert_eq(
    evaluate_sample(problem, RationalPoint(@oracle.rational(257, 31))),
    Some(true),
  )
  assert_eq(
    evaluate_sample(
      problem,
      AlgebraicPoint(@sturm.Interval::{
        lower: @oracle.rational(-1, 1),
        upper: @oracle.rational(1, 1),
      }),
    ),
    None,
  )
}
