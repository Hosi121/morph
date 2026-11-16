///|
test "independent Z3 review attack coherent external irrational model source substitution fails" {
  let square_two = review_polynomial(2, [(1, 1, [2, 0]), (-2, 1, [0, 0])])
  let square_three = review_polynomial(2, [(1, 1, [2, 0]), (-3, 1, [0, 0])])
  let diagonal = review_polynomial(2, [(1, 1, [0, 1]), (-1, 1, [1, 0])])
  let source : @qf.Formula = Conjunction(
    Atom(square_two, EqualZero),
    Atom(diagonal, EqualZero),
  )
  let other_source : @qf.Formula = Conjunction(
    Atom(square_three, EqualZero),
    Atom(diagonal, EqualZero),
  )
  let problem = review_problem(2, source)
  let other = review_problem(2, other_source)
  let model = review_model(problem)
  let other_model = review_model(other)
  assert_eq(@cad.evaluate_formula(point(model), other_source), Ok(false))
  assert_eq(@cad.evaluate_formula(point(other_model), source), Ok(false))
  assert_false(check_model(other, { ..model, context: context(other), }))
  assert_false(
    check_model(problem, { ..other_model, context: context(problem), }),
  )
  assert_false(
    check_model(problem, {
      ..model,
      context: { ..model.context, source: other_source, },
    }),
  )
  assert_false(
    check_model(problem, {
      ..model,
      point: @cad.rational_point(
        @oracle.chain([@oracle.rational(0, 1), @oracle.rational(0, 1)]),
      ),
    }),
  )
}

///|
test "independent Z3 review attack coherent theory relabel cannot refute satisfiable Boolean alternative" {
  let px = review_polynomial(2, [(1, 1, [2, 0]), (1, 1, [0, 0])])
  let py = review_polynomial(2, [(1, 1, [0, 2]), (1, 1, [0, 0])])
  let impossible = review_problem(
    2,
    @qf.Disjunction(Atom(px, LessZero), Atom(py, LessZero)),
  )
  let satisfiable = review_problem(
    2,
    @qf.Disjunction(Atom(px, LessZero), Atom(py, GreaterZero)),
  )
  let proof = review_refutation(impossible)
  let _ = review_model(satisfiable)
  assert_true(@oracle.int_of_nat(@core.length(proof.lemmas)) > 1)
  let relabeled = @core.map(proof.lemmas, fn(lemma) {
    let signed = signed_formula(satisfiable, lemma.assignment).unwrap()
    let theory = @cad.prepare(arity(satisfiable), signed).unwrap()
    Lemma::{
      ..lemma,
      context: context(satisfiable),
      decomposition: {
        ..lemma.decomposition,
        arity: arity(satisfiable),
        formula: signed,
        projection: @cad.projection(theory),
      },
    }
  })
  assert_true(
    @core.any(relabeled, fn(lemma) { lemma_clause(satisfiable, lemma) is None }),
  )
  assert_false(
    check_refutation(satisfiable, {
      ..proof,
      context: context(satisfiable),
      lemmas: relabeled,
    }),
  )
  let first = @core.nth(proof.lemmas, @core.Zero).unwrap()
  let wrong_leaf = {
    ..first,
    decomposition: {
      ..first.decomposition,
      tree: review_flip_leaf(first.decomposition.tree),
    },
  }
  assert_true(lemma_clause(impossible, wrong_leaf) is None)
}

///|
test "independent Z3 review attack arithmetic Boolean refutation requires complete theory and final RUP payload" {
  let px = review_polynomial(2, [(1, 1, [2, 0]), (1, 1, [0, 0])])
  let py = review_polynomial(2, [(1, 1, [0, 2]), (1, 1, [0, 0])])
  let problem = review_problem(
    2,
    @qf.Disjunction(Atom(px, LessZero), Atom(py, LessZero)),
  )
  let proof = review_refutation(problem)
  assert_true(@oracle.int_of_nat(@core.length(proof.lemmas)) > 1)
  assert_false(@cdcl.check_refutation(cnf(problem), proof.propositional))
  assert_false(check_refutation(problem, { ..proof, lemmas: @core.Nil, }))
  assert_false(
    check_refutation(problem, {
      ..proof,
      lemmas: @core.drop(@oracle.nat(1), proof.lemmas),
    }),
  )
  match proof.propositional {
    @cdcl.Rup(steps) => {
      assert_true(@core.last(steps) is Some(Nil))
      assert_false(
        check_refutation(problem, {
          ..proof,
          propositional: @cdcl.Rup(review_drop_final(steps)),
        }),
      )
    }
  }
  assert_false(
    check_refutation(problem, {
      ..proof,
      context: { ..proof.context, arity: @oracle.nat(3), },
    }),
  )
}

///|
test "independent Z3 review attack opaque original source cannot borrow stronger Boolean CNF encoding" {
  let px = review_polynomial(2, [(1, 1, [2, 0]), (1, 1, [0, 0])])
  let py = review_polynomial(2, [(1, 1, [0, 2]), (1, 1, [0, 0])])
  let weaker_source : @qf.Formula = Disjunction(
    Atom(px, GreaterZero),
    Atom(py, LessZero),
  )
  let stronger_source : @qf.Formula = Conjunction(
    Atom(px, GreaterZero),
    Atom(py, LessZero),
  )
  let weaker = review_problem(2, weaker_source)
  let stronger = review_problem(2, stronger_source)
  let _ = review_model(weaker)
  let proof = review_refutation(stronger)
  assert_eq(atoms(weaker), atoms(stronger))
  let forged = Problem::{ ..weaker, encoding: stronger.encoding, }
  let relabeled = @core.map(proof.lemmas, fn(lemma) {
    Lemma::{ ..lemma, context: context(weaker), }
  })
  let forged_proof : Refutation = {
    ..proof,
    context: context(weaker),
    lemmas: relabeled,
  }
  assert_false(check_refutation(weaker, forged_proof))
  assert_false(check_refutation(forged, forged_proof))
  for lemma in @oracle.array(relabeled) {
    assert_true(lemma_clause(forged, lemma) is None)
  }
}
