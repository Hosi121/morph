///|
fn test_univariate(coefficients : Array[(Int32, Int32)]) -> @poly.Polynomial {
  fn terms(index : Int32) -> @core.Chain[@poly.Term] {
    if index == coefficients.length() {
      Nil
    } else {
      Cons(
        {
          coefficient: @oracle.rational(
            coefficients[index].0,
            coefficients[index].1,
          ),
          exponents: Cons(@oracle.nat(index), Nil),
        },
        terms(index + 1),
      )
    }
  }
  @poly.polynomial(Succ(Zero), terms(0)).unwrap()
}

///|
fn test_bivariate(
  terms : Array[((Int32, Int32), Array[Int32])],
) -> @poly.Polynomial {
  @poly.polynomial(
    @oracle.nat(2),
    @oracle.chain(
      terms.map(fn(term) {
        {
          coefficient: @oracle.rational(term.0.0, term.0.1),
          exponents: @oracle.chain(term.1.map(@oracle.nat)),
        }
      }),
    ),
  ).unwrap()
}

///|
fn test_roots(coefficients : Array[(Int32, Int32)]) -> RootSet {
  let problem = prepare(test_univariate(coefficients)).unwrap()
  match run(start(problem), @oracle.nat(12), @oracle.nat(3000)).unwrap() {
    Complete(value) => value
    Paused(_, _) => abort("small complex polynomial must finish")
  }
}

///|
fn in_box(
  root : Root,
  box : ((Int32, Int32), (Int32, Int32), (Int32, Int32), (Int32, Int32), Int32),
) -> Bool {
  let coordinates = @oracle.array(coordinate_expressions(root))
  let bounds = [(box.0, box.1), (box.2, box.3)]
  let alpha = parameter(root)
  for index in 0..<2 {
    let lower = @poly.subtract(
      coordinates[index],
      @poly.constant(
        Succ(Zero),
        @oracle.rational(bounds[index].0.0, bounds[index].0.1),
      ),
    ).unwrap()
    let upper = @poly.subtract(
      coordinates[index],
      @poly.constant(
        Succ(Zero),
        @oracle.rational(bounds[index].1.0, bounds[index].1.1),
      ),
    ).unwrap()
    if @tarski.sign_at(alpha, lower).unwrap().sign == @core.Less ||
      @tarski.sign_at(alpha, upper).unwrap().sign == @core.Greater {
      return false
    }
  }
  true
}

///|
fn assert_cartesian_fixture(
  coefficients : Array[(Int32, Int32)],
  expected_real : Array[((Int32, Int32), Array[Int32])],
  expected_imaginary : Array[((Int32, Int32), Array[Int32])],
) -> Unit raise {
  let expansion = cartesian(test_univariate(coefficients)).unwrap()
  assert_eq(expansion.real, test_bivariate(expected_real))
  assert_eq(expansion.imaginary, test_bivariate(expected_imaginary))
}

///|
/// Independent Fraction/SymPy fixtures supply equations and disjoint rational
/// coordinate boxes. Membership uses exact Tarski signs, never floating roots.
fn assert_complex_fixture(
  coefficients : Array[(Int32, Int32)],
  expected_real : Array[((Int32, Int32), Array[Int32])],
  expected_imaginary : Array[((Int32, Int32), Array[Int32])],
  boxes : Array[
    ((Int32, Int32), (Int32, Int32), (Int32, Int32), (Int32, Int32), Int32),
  ],
) -> Unit raise {
  let source = test_univariate(coefficients)
  let expansion = cartesian(source).unwrap()
  assert_eq(expansion.real, test_bivariate(expected_real))
  assert_eq(expansion.imaginary, test_bivariate(expected_imaginary))
  let value = test_roots(coefficients)
  let proof = certificate(value)
  assert_true(check_result(source, value, proof))
  let found = @oracle.array(roots(value))
  assert_eq(found.length(), boxes.length())
  for root in found {
    let matches = boxes.filter(fn(box) { in_box(root, box) })
    assert_eq(matches.length(), 1)
    assert_eq(@oracle.int_of_nat(multiplicity(root)), matches[0].4)
  }
  for box in boxes {
    assert_eq(found.filter(fn(root) { in_box(root, box) }).length(), 1)
  }
}

///|
test "zero and multivariate polynomials are rejected; constants have empty roots" {
  assert_true(prepare(@poly.zero(Succ(Zero))) is Err(ZeroPolynomial))
  assert_true(
    prepare(@poly.constant(two(), @exact.rational_one())) is Err(NotUnivariate),
  )
  let constant = test_univariate([(7, 3)])
  let value = match
    run(start(prepare(constant).unwrap()), Zero, Zero).unwrap() {
    Complete(value) => value
    _ => abort("nonzero constant is complete without work")
  }
  assert_true(roots(value) is Nil)
  assert_true(check_result(constant, value, certificate(value)))
  assert_false(check(test_univariate([(8, 3)]), certificate(value)))
}

///|
test "complex roots resume separating forms and computation without false empty sets" {
  let source = test_univariate([(1, 1), (0, 1), (1, 1)])
  let problem = prepare(source).unwrap()
  assert_true(
    run(start(problem), @oracle.nat(3), Zero).unwrap()
    is Paused(_, ComputationFuel),
  )
  assert_true(
    run(start(problem), Zero, @oracle.nat(100)).unwrap()
    is Paused(_, AttemptLimit),
  )
  let state = match
    run(start_from(problem, @binary.zero()), Succ(Zero), Succ(Zero)).unwrap() {
    Paused(state, ComputationFuel) => state
    _ => abort("one step must pause while retaining the first form")
  }
  let state = match run(state, Zero, @oracle.nat(1000)).unwrap() {
    Paused(state, AttemptLimit) => state
    _ => abort("first form does not distinguish the imaginary conjugates")
  }
  let value = match run(state, Succ(Zero), @oracle.nat(1000)).unwrap() {
    Complete(value) => value
    _ => abort("next form must separate i and -i")
  }
  assert_eq(@oracle.int_of_nat(@core.length(roots(value))), 2)
  assert_true(check_result(source, value, certificate(value)))
}

///|
test "complex cover and multiplicities reject altered input missing roots and fake jets" {
  let source = test_univariate([(1, 1), (0, 1), (2, 1), (0, 1), (1, 1)])
  let value = test_roots([(1, 1), (0, 1), (2, 1), (0, 1), (1, 1)])
  let proof = certificate(value)
  assert_true(check_result(source, value, proof))
  assert_false(
    check(test_univariate([(2, 1), (0, 1), (2, 1), (0, 1), (1, 1)]), proof),
  )
  assert_false(check(source, { ..proof, separation: None, }))
  assert_false(
    check(source, {
      ..proof,
      multiplicities: @core.drop(Succ(Zero), proof.multiplicities),
    }),
  )
  let first = @core.nth(proof.multiplicities, Zero).unwrap()
  assert_eq(@oracle.int_of_nat(first.order), 2)
  assert_false(
    check(source, {
      ..proof,
      multiplicities: Cons(
        { ..first, order: Succ(Zero), },
        @core.drop(Succ(Zero), proof.multiplicities),
      ),
    }),
  )
  assert_false(
    check(source, {
      ..proof,
      multiplicities: Cons(
        { ..first, jets: @core.drop(Succ(Zero), first.jets), },
        @core.drop(Succ(Zero), proof.multiplicities),
      ),
    }),
  )
  assert_false(check_result(source, { ..value, roots: Nil, }, proof))
  let separation = proof.separation.unwrap()
  assert_false(
    check(source, {
      ..proof,
      separation: Some({
        ..separation,
        solutions: {
          ..separation.solutions,
          intervals: @core.drop(Succ(Zero), separation.solutions.intervals),
        },
      }),
    }),
  )
}

///|
test "isolated complex roots materialize exact coordinates with bound certificates" {
  let value = test_roots([(1, 1), (0, 1), (1, 1)])
  let found = @oracle.array(roots(value))
  let paused = match materialize(found[0], Zero).unwrap() {
    MaterializationPaused(state) => state
    _ => abort("zero fuel keeps coordinate computation")
  }
  let (number, proof) = match
    materialize_advance(paused, @oracle.nat(100)).unwrap() {
    Materialized(number, proof) => (number, proof)
    _ => abort("quadratic coordinates should materialize")
  }
  assert_true(check_materialization(found[0], number, proof))
  assert_false(check_materialization(found[1], number, proof))
  assert_false(
    check_materialization(found[0], number, {
      ..proof,
      real: proof.imaginary,
      imaginary: proof.real,
    }),
  )
  let swapped = @complex.number(
    @complex.imaginary_part(number),
    @complex.real_part(number),
  )
  assert_false(check_materialization(found[0], swapped, proof))
}

///|
test "explicit separating seed changes search preference while both covers are checked" {
  let source = test_univariate([(1, 1), (0, 1), (1, 1)])
  let problem = prepare(source).unwrap()
  let preferred = match
    run(
      start_from(problem, @oracle.binary(2)),
      @oracle.nat(3),
      @oracle.nat(1000),
    ).unwrap() {
    Complete(value) => value
    _ => abort("explicit nonzero form must separate the quadratic")
  }
  let reference = match
    run(start_from(problem, @binary.zero()), @oracle.nat(3), @oracle.nat(1000)).unwrap() {
    Complete(value) => value
    _ => abort("explicit reference must separate the quadratic")
  }
  let first = certificate(preferred)
  let old = certificate(reference)
  assert_eq(
    @oracle.int_of_binary(first.separation.unwrap().augmentation.seed),
    2,
  )
  assert_eq(@oracle.int_of_binary(old.separation.unwrap().augmentation.seed), 1)
  assert_true(check_result(source, preferred, first))
  assert_true(check_result(source, reference, old))
  assert_eq(
    @oracle.array(roots(preferred)).length(),
    @oracle.array(roots(reference)).length(),
  )
}
