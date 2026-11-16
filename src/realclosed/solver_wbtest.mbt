///|
fn p(
  variables : Int32,
  terms : Array[(Int32, Array[Int32])],
) -> @poly.Polynomial raise {
  match
    @poly.polynomial(
      @oracle.nat(variables),
      @oracle.chain(
        terms.map(fn(term) {
          let (coefficient, powers) = term
          @poly.Term::{
            coefficient: @oracle.rational(coefficient, 1),
            exponents: @oracle.chain(powers.map(@oracle.nat)),
          }
        }),
      ),
    ) {
    Ok(value) => value
    Err(_) => fail("fixture polynomial")
  }
}

///|
fn solve(free : Int32, source : @logic.Formula) -> Solution raise {
  let problem = match prepare(@oracle.nat(free), source) {
    Ok(v) => v
    Err(_) => fail("prepare")
  }
  match run(start(problem), @oracle.nat(50000)) {
    Ok(Complete(value)) => value
    Ok(Paused(_)) => fail("transition budget")
    Err(_) => fail("solver error")
  }
}

///|
test "closed nonlinear sentences pass through normalization CAD and output checking" {
  let squares = p(2, [(1, [0, 2]), (-1, [2, 0])])
  let source = @logic.Formula::Forall(
    @logic.Formula::Exists(@logic.Atom(squares, @qf.EqualZero)),
  )
  let result = solve(0, source)
  assert_eq(truth(result), Some(true))
  assert_eq(quantifier_free(result), @qf.Truth(true))
  assert_true(check_result(@core.Zero, source, result, certificate(result)))
  let q = p(1, [(1, [2])])
  let false_source = @logic.Negation(
    @logic.Formula::Forall(@logic.Atom(q, @qf.AtLeastZero)),
  )
  assert_eq(truth(solve(0, false_source)), Some(false))
}

///|
test "three alternating real quantifiers preserve the different scopes" {
  let inequality = p(3, [(1, [0, 2, 0]), (1, [0, 0, 2]), (-1, [1, 0, 0])])
  let true_source = @logic.Formula::Forall(
    @logic.Formula::Exists(
      @logic.Formula::Forall(@logic.Atom(inequality, @qf.AtLeastZero)),
    ),
  )
  let false_source = @logic.Formula::Exists(
    @logic.Formula::Forall(
      @logic.Formula::Exists(@logic.Atom(inequality, @qf.AtMostZero)),
    ),
  )
  let yes = solve(0, true_source)
  let no = solve(0, false_source)
  assert_eq(truth(yes), Some(true))
  assert_eq(truth(no), Some(false))
  assert_true(check_result(@core.Zero, true_source, yes, certificate(yes)))
  assert_true(check_result(@core.Zero, false_source, no, certificate(no)))
}

///|
test "free-variable QE returns an exact circle projection formula" {
  let circle = p(2, [(1, [2, 0]), (1, [0, 2]), (-1, [0, 0])])
  let source = @logic.Formula::Exists(@logic.Atom(circle, @qf.EqualZero))
  let result = solve(1, source)
  assert_eq(truth(result), None)
  assert_true(check_result(@oracle.nat(1), source, result, certificate(result)))
  for numerator in -8..<=8 {
    let point = @cad.rational_point(
      @core.Cons(@oracle.rational(numerator, 4), @core.Nil),
    )
    assert_eq(
      @cad.evaluate_formula(point, quantifier_free(result)),
      Ok(numerator * numerator <= 16),
    )
  }
}

///|
test "independent sibling binders share lexical arity without capturing one another" {
  let bound_minus_free = p(2, [(1, [0, 1]), (-1, [1, 0])])
  let source = @logic.Conjunction(
    @logic.Formula::Exists(@logic.Atom(bound_minus_free, @qf.EqualZero)),
    @logic.Formula::Exists(@logic.Atom(bound_minus_free, @qf.GreaterZero)),
  )
  let result = solve(1, source)
  assert_true(check_result(@oracle.nat(1), source, result, certificate(result)))
  for x in -3..<=3 {
    let point = @cad.rational_point(
      @core.Cons(@oracle.rational(x, 2), @core.Nil),
    )
    assert_eq(@cad.evaluate_formula(point, quantifier_free(result)), Ok(true))
  }
  assert_eq(@oracle.int_of_nat(@logic.variables(prenex(result.problem))), 3)
}

///|
test "whole proof substitutions, returned values, arity and persistent continuations" {
  let source = @logic.Formula::Exists(
    @logic.Atom(p(1, [(1, [2]), (-2, [0])]), @qf.EqualZero),
  )
  let problem = match prepare(@core.Zero, source) {
    Ok(v) => v
    Err(_) => fail("prepare")
  }
  let initial = start(problem)
  assert_true(run(initial, @core.Zero) is Ok(Paused(_)))
  let middle = match run(initial, @oracle.nat(3)) {
    Ok(Paused(v)) => v
    _ => fail("continuation")
  }
  let result = match run(middle, @oracle.nat(5000)) {
    Ok(Complete(v)) => v
    _ => fail("completion")
  }
  assert_eq(truth(result), Some(true))
  let wrong_source = @logic.Formula::Exists(
    @logic.Atom(p(1, [(1, [2]), (1, [0])]), @qf.EqualZero),
  )
  let wrong = solve(0, wrong_source)
  assert_eq(truth(wrong), Some(false))
  assert_true(check(@core.Zero, source, certificate(wrong)) is None)
  assert_false(check_result(@core.Zero, source, wrong, certificate(result)))
  assert_true(check(@oracle.nat(1), source, certificate(result)) is None)
  let proof = certificate(result)
  assert_true(
    check(@core.Zero, source, {
      ..proof,
      normalization: certificate(wrong).normalization,
    })
    is None,
  )
  assert_true(
    check(@core.Zero, source, {
      ..proof,
      elimination: certificate(wrong).elimination,
    })
    is None,
  )
  assert_true(
    prepare(@core.Zero, @logic.Atom(p(1, [(1, [1])]), @qf.EqualZero))
    is Err(FormulaFailure(ArityMismatch)),
  )
}
