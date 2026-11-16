///|
test "dependent irrational diagonal has a checked shared-root union" {
  let x = polynomial_fixture(3, [(1, [2, 0, 0]), (-2, [0, 0, 0])])
  let xy = polynomial_fixture(3, [(1, [0, 1, 0]), (-1, [1, 0, 0])])
  let yz = polynomial_fixture(3, [(1, [0, 0, 1]), (-1, [0, 1, 0])])
  let z = polynomial_fixture(3, [(1, [0, 0, 2]), (-2, [0, 0, 0])])
  let formula = @qf.Conjunction(
    @qf.Atom(x, @qf.EqualZero),
    @qf.Conjunction(
      @qf.Atom(xy, @qf.EqualZero),
      @qf.Conjunction(@qf.Atom(yz, @qf.EqualZero), @qf.Atom(z, @qf.EqualZero)),
    ),
  )
  let problem = make_problem(3, formula)
  let result = finish(problem, 40000)
  assert_true(check_result(problem, result, certificate(result)))
  let qs : @core.Chain[@logic.Quantifier] = @oracle.chain([
    @logic.Quantifier::Exists,
    @logic.Quantifier::Exists,
    @logic.Quantifier::Exists,
  ])
  assert_eq(sentence(result, qs), Ok(true))
  match witness(result) {
    Ok(Some(point)) => assert_true(check_witness(problem, point))
    _ => fail("shared-root-union witness")
  }
}

///|
test "root union removes multiplicity but retains each original atom sign" {
  let square = polynomial_fixture(1, [(1, [4]), (-4, [2]), (4, [0])])
  let odd = polynomial_fixture(1, [(3, [3]), (-6, [1])])
  let negative = polynomial_fixture(1, [(-5, [2]), (10, [0])])
  let family = @oracle.chain([
    square,
    odd,
    negative,
    @poly.zero(@oracle.nat(1)),
    polynomial_fixture(1, [(-7, [0])]),
  ])
  let fibre = match prepare_fibre(rational_point(@core.Nil), family) {
    Ok(v) => v
    Err(_) => fail("union")
  }
  assert_eq(@tower.degree(fibre.root_polynomial), Some(@oracle.nat(3)))
  let count = @tower.count_between(fibre.system, {
    lower: @oracle.rational(-2, 1),
    upper: @oracle.rational(2, 1),
  }).unwrap()
  assert_eq(count.count, @oracle.nat(3))
  let signs = classify(fibre, RationalPoint(@oracle.rational(1, 1))).unwrap()
  assert_eq(
    signs,
    @oracle.chain([
      @core.Greater,
      @core.Less,
      @core.Greater,
      @core.Equal,
      @core.Less,
    ]),
  )
  let problem = make_problem(
    1,
    @qf.Conjunction(
      @qf.Atom(square, @qf.GreaterZero),
      @qf.Atom(negative, @qf.GreaterZero),
    ),
  )
  let result = finish(problem, 1000)
  assert_true(check_result(problem, result, certificate(result)))
  let qe = eliminate(result, @oracle.nat(1), @core.Nil).unwrap()
  for numerator in -6..<=6 {
    let point = rational_point(
      @core.Cons(@oracle.rational(numerator, 3), @core.Nil),
    )
    assert_eq(
      evaluate_formula(point, quantifier_free(qe)),
      Ok(numerator * numerator < 18),
    )
  }
}
