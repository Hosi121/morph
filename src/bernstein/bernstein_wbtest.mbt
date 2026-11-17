///|
fn test_poly(
  n : Int32,
  terms : Array[(@exact.Rational, Array[Int32])],
) -> @poly.Polynomial {
  match
    @poly.polynomial(
      @oracle.nat(n),
      @oracle.chain(
        terms.map(fn(pair) {
          @poly.Term::{
            coefficient: pair.0,
            exponents: @oracle.chain(pair.1.map(@oracle.nat)),
          }
        }),
      ),
    ) {
    Ok(p) => p
    Err(_) => abort("test polynomial")
  }
}

///|
fn test_box(
  axes : Array[(@exact.Rational, @exact.Rational)],
) -> @core.Chain[Axis] {
  @oracle.chain(axes.map(fn(pair) { Axis::{ lower: pair.0, upper: pair.1, } }))
}

///|
fn[A] required(result : Result[A, BernsteinError]) -> A {
  match result {
    Ok(value) => value
    Err(_) => abort("Bernstein test operation")
  }
}

///|
fn unit_box() -> @core.Chain[Axis] {
  test_box([(@oracle.rational(0, 1), @oracle.rational(1, 1))])
}

///|
fn degree(n : Int32) -> @core.Chain[@core.Nat] {
  @oracle.chain([@oracle.nat(n)])
}

///|
fn positive_quadratic() -> @poly.Polynomial {
  test_poly(1, [
    (@oracle.rational(1, 1), [2]),
    (@oracle.rational(-1, 1), [1]),
    (@oracle.rational(3, 8), [0]),
  ])
}

///|
fn verify_fixture(
  n : Int32,
  terms : Array[(@exact.Rational, Array[Int32])],
  axes : Array[(@exact.Rational, @exact.Rational)],
  degrees : Array[Int32],
  expected : Array[@exact.Rational],
) -> Unit raise {
  let p = test_poly(n, terms)
  let box = test_box(axes)
  let cert = required(bound(p, box, @oracle.chain(degrees.map(@oracle.nat))))
  assert_eq(
    @oracle.array(@core.map(cert.coefficients, fn(c) { c.value })),
    expected,
  )
  assert_true(check_bound(p, box, cert))
}

///|
test "dimensions, ordered box and covering degree are mandatory" {
  let p = positive_quadratic()
  assert_eq(bound(p, @core.Nil, degree(2)), Err(DimensionMismatch))
  assert_eq(bound(p, unit_box(), @core.Nil), Err(DimensionMismatch))
  assert_eq(bound(p, unit_box(), degree(1)), Err(InsufficientDegree))
  assert_eq(
    bound(
      p,
      test_box([(@oracle.rational(1, 1), @oracle.rational(1, 1))]),
      degree(2),
    ),
    Err(DegenerateBox),
  )
  assert_eq(
    bound(
      p,
      test_box([(@oracle.rational(2, 1), @oracle.rational(-1, 1))]),
      degree(2),
    ),
    Err(DegenerateBox),
  )
}

///|
test "bound checker rejects original-source, box, coefficient, tensor and bound tampering" {
  let p = positive_quadratic()
  let box = unit_box()
  let c = required(bound(p, box, degree(2)))
  assert_eq(c.lower, @oracle.rational(-1, 8))
  assert_eq(c.upper, @oracle.rational(3, 8))
  let different = test_poly(1, [(@oracle.rational(9, 1), [0])])
  assert_false(check_bound(different, box, c))
  let other_box = test_box([(@oracle.rational(-1, 1), @oracle.rational(1, 1))])
  assert_false(check_bound(p, other_box, c))
  assert_false(check_bound(p, box, { ..c, source: different, }))
  assert_false(check_bound(p, box, { ..c, box: other_box, }))
  assert_false(check_bound(p, box, { ..c, lower: @oracle.rational(1, 8), }))
  assert_false(check_bound(p, box, { ..c, upper: @oracle.rational(1, 1), }))
  assert_false(check_bound(p, box, { ..c, degrees: degree(3), }))
  assert_false(
    check_bound(p, box, { ..c, coefficients: @core.reverse(c.coefficients), }),
  )
  match c.coefficients {
    Cons(head, rest) => {
      assert_false(check_bound(p, box, { ..c, coefficients: rest, }))
      assert_false(
        check_bound(p, box, { ..c, coefficients: Cons(head, c.coefficients), }),
      )
      let changed : @core.Chain[Coefficient] = Cons(
        { ..head, value: @oracle.rational(7, 1), },
        rest,
      )
      let (lower, upper) = match extrema(changed) {
        Some(pair) => pair
        None => abort("nonempty")
      }
      // Updating extrema cannot conceal the false polynomial identity.
      assert_false(
        check_bound(p, box, { ..c, coefficients: changed, lower, upper, }),
      )
      assert_false(
        check_bound(p, box, {
          ..c,
          coefficients: Cons({ ..head, index: degree(8), }, rest),
        }),
      )
    }
    Nil => abort("nonempty")
  }
}

///|
test "one split proves a strictly positive quadratic; fuel zero pauses and resumes" {
  let p = positive_quadratic()
  let box = unit_box()
  let paused = required(certify(p, box, degree(2), Positive, @oracle.nat(0)))
  assert_true(check_outcome(p, box, Positive, paused))
  let state = match paused {
    Paused(state) => state
    _ => abort("expected pause")
  }
  assert_eq(
    tree_counts(state.tree),
    (@oracle.nat(0), @oracle.nat(0), @oracle.nat(1)),
  )
  let resumed = required(resume_search(state, @oracle.nat(1)))
  assert_eq(
    resumed,
    required(certify(p, box, degree(2), Positive, @oracle.nat(1))),
  )
  assert_true(check_outcome(p, box, Positive, resumed))
  let done = match resumed {
    Certified(state) => state
    _ => abort("expected certificate")
  }
  assert_eq(
    tree_counts(done.tree),
    (@oracle.nat(2), @oracle.nat(1), @oracle.nat(0)),
  )
  assert_eq(required(resume_search(done, @oracle.nat(0))), resumed)
  assert_false(check_outcome(p, box, Positive, Paused(done)))
  assert_false(check_outcome(p, box, Nonnegative, resumed))
}

///|
test "nonnegative and strict positive differ at a closed-box boundary" {
  let p = test_poly(1, [(@oracle.rational(1, 1), [1])])
  let box = unit_box()
  let nonnegative = required(
    certify(p, box, degree(1), Nonnegative, @oracle.nat(0)),
  )
  assert_true(check_outcome(p, box, Nonnegative, nonnegative))
  assert_true(
    match nonnegative {
      Certified(_) => true
      _ => false
    },
  )
  let strict = required(certify(p, box, degree(1), Positive, @oracle.nat(0)))
  let witness = match strict {
    Counterexample(_, w) => w
    _ => abort("boundary counterexample")
  }
  assert_eq(witness.point, @oracle.chain([@oracle.rational(0, 1)]))
  assert_true(check_outcome(p, box, Positive, strict))
  assert_false(check_witness(p, box, Nonnegative, witness))
  assert_false(
    check_witness(p, box, Positive, {
      ..witness,
      value: @oracle.rational(-1, 1),
    }),
  )
  assert_false(
    check_witness(p, box, Positive, {
      point: @oracle.chain([@oracle.rational(-1, 1)]),
      value: @oracle.rational(-1, 1),
    }),
  )
}

///|
test "negative midpoint is an evaluated witness, not a negative Bernstein coefficient" {
  let p = test_poly(1, [
    (@oracle.rational(1, 1), [2]),
    (@oracle.rational(-1, 1), [1]),
    (@oracle.rational(1, 8), [0]),
  ])
  let outcome = required(
    certify(p, unit_box(), degree(2), Nonnegative, @oracle.nat(0)),
  )
  assert_true(check_outcome(p, unit_box(), Nonnegative, outcome))
  match outcome {
    Counterexample(_, witness) => {
      assert_eq(witness.point, @oracle.chain([@oracle.rational(1, 2)]))
      assert_eq(witness.value, @oracle.rational(-1, 8))
    }
    _ => abort("expected midpoint witness")
  }
}

///|
test "non-dyadic zero remains honestly paused with an exhausted split budget" {
  let p = test_poly(1, [
    (@oracle.rational(1, 1), [2]),
    (@oracle.rational(-2, 3), [1]),
    (@oracle.rational(1, 9), [0]),
  ])
  let first = required(
    certify(p, unit_box(), degree(2), Nonnegative, @oracle.nat(2)),
  )
  let state = match first {
    Paused(state) => state
    _ => abort("inconclusive zero")
  }
  assert_true(check_outcome(p, unit_box(), Nonnegative, first))
  let (_, splits, _) = tree_counts(state.tree)
  assert_eq(splits, @oracle.nat(2))
  let second = required(resume_search(state, @oracle.nat(3)))
  let next = match second {
    Paused(state) => state
    _ => abort("still inconclusive")
  }
  let (_, splits, _) = tree_counts(next.tree)
  assert_eq(splits, @oracle.nat(5))
  assert_true(check_outcome(p, unit_box(), Nonnegative, second))
  let strict = required(
    certify(p, unit_box(), degree(2), Positive, @oracle.nat(3)),
  )
  assert_true(
    match strict {
      Paused(_) => true
      _ => false
    },
  )
  assert_true(check_outcome(p, unit_box(), Positive, strict))
}

///|
test "certificate tree checks source, claim, exact partition coverage, axis and leaf identities" {
  let p = positive_quadratic()
  let box = unit_box()
  let outcome = required(certify(p, box, degree(2), Positive, @oracle.nat(1)))
  let state = match outcome {
    Certified(state) => state
    _ => abort("certified")
  }
  let different = test_poly(1, [(@oracle.rational(-1, 1), [0])])
  assert_false(check_outcome(different, box, Positive, outcome))
  assert_false(check_outcome(p, @core.Nil, Positive, outcome))
  assert_false(
    check_outcome(p, box, Positive, Certified({ ..state, source: different, })),
  )
  assert_eq(
    resume_search({ ..state, source: different, }, @oracle.nat(0)),
    Err(InvalidCertificate),
  )
  match state.tree {
    Split(parent, axis, left, right) => {
      assert_false(
        check_outcome(
          p,
          box,
          Positive,
          Certified({ ..state, tree: Split(parent, axis, left, left), }),
        ),
      )
      assert_false(
        check_outcome(
          p,
          box,
          Positive,
          Certified({
            ..state,
            tree: Split(parent, @oracle.nat(1), left, right),
          }),
        ),
      )
      assert_false(
        check_outcome(
          p,
          box,
          Positive,
          Certified({ ..state, tree: Split(@core.Nil, axis, left, right), }),
        ),
      )
      assert_false(
        check_outcome(
          p,
          box,
          Positive,
          Certified({ ..state, tree: Open(box), }),
        ),
      )
      match left {
        Leaf(c) => {
          let forged = {
            ..state,
            tree: Split(
              parent,
              axis,
              Leaf({ ..c, lower: @oracle.rational(99, 1), }),
              right,
            ),
          }
          assert_false(check_outcome(p, box, Positive, Certified(forged)))
          assert_eq(
            resume_search(forged, @oracle.nat(1)),
            Err(InvalidCertificate),
          )
        }
        _ => abort("left certificate")
      }
    }
    _ => abort("split tree")
  }
}
