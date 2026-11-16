///|
fn review_sqrt_two(positive : Bool) -> @tower.Extension {
  let base = @tower.rational_field()
  let poly = @tower.polynomial(
    base,
    @oracle.chain(
      [-2, 0, 1].map(fn(n) { @tower.rational(base, @oracle.rational(n, 1)) }),
    ),
  ).unwrap()
  let span = if positive {
    @sturm.Interval::{
      lower: @oracle.rational(1, 1),
      upper: @oracle.rational(2, 1),
    }
  } else {
    @sturm.Interval::{
      lower: @oracle.rational(-2, 1),
      upper: @oracle.rational(-1, 1),
    }
  }
  @tower.adjoin(
    @tower.root_in_interval(@tower.system(poly).unwrap(), span).unwrap(),
  ).unwrap()
}

///|
test "independent irrational output sections are evaluated at exact conjugate points" {
  let a = polynomial_fixture(2, [(1, [2, 1]), (-2, [0, 1]), (-1, [0, 0])])
  let b = polynomial_fixture(2, [(1, [2, 2]), (-2, [0, 2])])
  let c = polynomial_fixture(3, [
    (1, [2, 0, 1]),
    (-2, [0, 0, 1]),
    (1, [0, 1, 0]),
  ])
  let specs = [
    (
      2,
      @qf.Atom(a, @qf.EqualZero),
      @oracle.chain([@logic.Quantifier::Exists]),
      false,
    ),
    (
      2,
      @qf.Atom(b, @qf.AtLeastZero),
      @oracle.chain([@logic.Quantifier::Forall]),
      true,
    ),
    (
      3,
      @qf.Atom(c, @qf.EqualZero),
      @oracle.chain([@logic.Quantifier::Exists, @logic.Quantifier::Forall]),
      true,
    ),
  ]
  for (arity, matrix, quantifiers, expected) in specs {
    let problem = make_problem(arity, matrix)
    let value = finish(problem, 100000)
    let output = eliminate(value, @oracle.nat(1), quantifiers).unwrap()
    assert_true(
      check_elimination_result(
        problem,
        @oracle.nat(1),
        quantifiers,
        output,
        elimination_certificate(output),
      ),
    )
    for positive in [true, false] {
      let ext = review_sqrt_two(positive)
      let sample = point(ext.field, @oracle.chain([ext.generator])).unwrap()
      assert_eq(evaluate_formula(sample, quantifier_free(output)), Ok(expected))
    }
  }
}

///|
test "independent negative eighth root witness binds sign coordinates and context" {
  let equation = polynomial_fixture(1, [(1, [8]), (-3, [0])])
  let coordinate = polynomial_fixture(1, [(1, [1])])
  let matrix = @qf.Conjunction(
    @qf.Atom(equation, @qf.EqualZero),
    @qf.Atom(coordinate, @qf.LessZero),
  )
  let problem = make_problem(1, matrix)
  let value = finish(problem, 20000)
  assert_true(check_result(problem, value, certificate(value)))
  let selected = witness(value).unwrap().unwrap()
  let z = @core.nth(coordinates(selected), @oracle.nat(0)).unwrap()
  assert_eq(@tower.scalar_sign(z).unwrap().sign, @core.Less)
  assert_eq(
    @tower.scalar_equal(
      scalar_power(z, @oracle.nat(8)).unwrap(),
      @tower.rational(point_field(selected), @oracle.rational(3, 1)),
    ),
    Ok(true),
  )
  assert_true(check_witness(problem, selected))
  let conjugate = point(
    point_field(selected),
    @oracle.chain([@tower.scalar_negate(z)]),
  ).unwrap()
  assert_eq(
    @tower.scalar_equal(
      scalar_power(@tower.scalar_negate(z), @oracle.nat(8)).unwrap(),
      @tower.rational(point_field(selected), @oracle.rational(3, 1)),
    ),
    Ok(true),
  )
  assert_false(check_witness(problem, conjugate))
  assert_false(
    check_witness(problem, Point::{ ..selected, coordinates: @core.Nil, }),
  )
  assert_false(
    check_witness(problem, Point::{
      ..selected,
      field: @tower.rational_field(),
    }),
  )
  let unrelated = review_sqrt_two(true)
  assert_true(
    point(point_field(selected), @oracle.chain([unrelated.generator]))
    is Err(TowerFailure(DifferentField)),
  )
}

///|
test "independent public proof bundles reject coherent alternate endpoint truths" {
  let p = polynomial_fixture(1, [(1, [1]), (-1, [0])])
  let original = make_problem(1, @qf.Atom(p, @qf.GreaterZero))
  let foreign = make_problem(1, @qf.Atom(p, @qf.AtLeastZero))
  let good = finish(original, 500)
  let other = finish(foreign, 500)
  let proof = certificate(good)
  assert_eq(proof.projection, certificate(other).projection)
  assert_true(
    check(original, { ..proof, tree: certificate(other).tree, }) is None,
  )
  let quantifiers = @oracle.chain([@logic.Quantifier::Exists])
  let qe = eliminate(good, @core.Zero, quantifiers).unwrap()
  let other_qe = eliminate(other, @core.Zero, quantifiers).unwrap()
  assert_eq(quantifier_free(qe), @qf.Truth(true))
  assert_eq(quantifier_free(other_qe), @qf.Truth(true))
  let forged = EliminationCertificate::{
    decomposition: proof,
    encoding: elimination_certificate(other_qe).encoding,
  }
  assert_true(
    check_elimination(original, @core.Zero, quantifiers, forged) is None,
  )
  assert_false(
    check_elimination_result(
      original,
      @core.Zero,
      quantifiers,
      Elimination::{ ..qe, encoding: other_qe.encoding, },
      elimination_certificate(qe),
    ),
  )
  assert_false(
    check_elimination_result(
      original,
      @core.Zero,
      quantifiers,
      Elimination::{ ..qe, decomposition: other, },
      elimination_certificate(qe),
    ),
  )
}
