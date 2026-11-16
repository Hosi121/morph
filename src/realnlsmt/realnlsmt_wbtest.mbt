///|
fn test_polynomial(
  arity : Int32,
  terms : Array[(Int32, Int32, Array[Int32])],
) -> @polynomial.Polynomial {
  match
    @polynomial.polynomial(
      @oracle.nat(arity),
      @oracle.chain(
        terms.map(fn(term) {
          let (numerator, denominator, exponents) = term
          @polynomial.Term::{
            coefficient: @oracle.rational(numerator, denominator),
            exponents: @oracle.chain(exponents.map(@oracle.nat)),
          }
        }),
      ),
    ) {
    Ok(polynomial) => polynomial
    Err(_) => abort("invalid test polynomial")
  }
}

///|
fn test_problem(arity : Int32, formula : @qf.Formula) -> Problem {
  match prepare(@oracle.nat(arity), formula) {
    Ok(problem) => problem
    Err(_) => abort("unexpected preparation failure")
  }
}

///|
fn test_solve(problem : Problem) -> Outcome raise {
  let mut search = start(problem)
  for _ in 0..<20000 {
    match step(search) {
      Ok(Paused(next)) => search = next
      Ok(outcome) => return outcome
      Err(error) => {
        debug_inspect(error, content="no error expected")
        abort("unexpected SMT error")
      }
    }
  }
  abort("test transition limit exhausted")
}

///|
fn test_sat(problem : Problem) -> Model raise {
  match test_solve(problem) {
    Satisfiable(model) => {
      assert_true(check_model(problem, model))
      model
    }
    other => {
      debug_inspect(other, content="SAT expected")
      abort("SAT expected")
    }
  }
}

///|
fn test_unsat(problem : Problem) -> Refutation raise {
  match test_solve(problem) {
    Unsatisfiable(proof) => {
      assert_true(check_refutation(problem, proof))
      proof
    }
    other => {
      debug_inspect(other, content="UNSAT expected")
      abort("UNSAT expected")
    }
  }
}

///|
fn test_literal(variable : Int32, positive : Bool) -> @sat.Literal {
  { variable: @oracle.nat(variable), positive, }
}

///|
fn check_generated_fixture(source : @qf.Formula, expected : Bool) -> Unit raise {
  let problem = test_problem(1, source)
  match test_solve(problem) {
    Satisfiable(model) => {
      assert_true(expected)
      assert_true(check_model(problem, model))
    }
    Unsatisfiable(proof) => {
      assert_true(!expected)
      assert_true(check_refutation(problem, proof))
    }
    Paused(_) => abort("unexpected unfinished fixture")
  }
}

///|
test "source IDs distinguish polynomial relations and keep stable first occurrence" {
  let p = test_polynomial(1, [(1, 1, [2]), (-2, 1, [0])])
  let source : @qf.Formula = Conjunction(
    Atom(p, EqualZero),
    Disjunction(Atom(p, NotZero), Atom(p, EqualZero)),
  )
  let problem = test_problem(1, source)
  assert_eq(
    atoms(problem),
    @oracle.chain([
      Atom::{ polynomial: p, relation: EqualZero, },
      Atom::{ polynomial: p, relation: NotZero, },
    ]),
  )
  assert_eq(context(problem), Context::{ arity: @oracle.nat(1), source, })
  assert_eq(formula(problem), source)
  assert_eq(arity(problem), @oracle.nat(1))
  assert_true(
    @core.length(boolean_variables(cnf(problem))).not_equal(
      @core.length(atoms(problem)),
    ),
  )
  assert_eq(prepare(@oracle.nat(0), @qf.Atom(p, EqualZero)), Err(WrongArity))
  assert_eq(
    prepare(@oracle.nat(0), @qf.Disjunction(Truth(true), Atom(p, EqualZero))),
    Err(WrongArity),
  )
}

///|
test "empty arithmetic atom families and zero-dimensional inputs" {
  for arity in [0, 2] {
    let model = test_sat(test_problem(arity, @qf.Truth(true)))
    assert_eq(@core.length(@cad.coordinates(point(model))), @oracle.nat(arity))
    let proof = test_unsat(test_problem(arity, @qf.Truth(false)))
    assert_eq(proof.lemmas, @core.Nil)
  }
}

///|
test "nonlinear x squared below zero learns a CAD lemma and RUP refutation" {
  let square = test_polynomial(1, [(1, 1, [2])])
  let problem = test_problem(1, @qf.Atom(square, LessZero))
  let proof = test_unsat(problem)
  assert_eq(@core.length(proof.lemmas), @oracle.nat(1))
  let lemma = match proof.lemmas {
    Cons(lemma, Nil) => lemma
    _ => abort("one lemma expected")
  }
  assert_eq(lemma.assignment, @oracle.chain([test_literal(0, true)]))
  assert_eq(
    lemma_clause(problem, lemma),
    Some(@oracle.chain([test_literal(0, false)])),
  )
  assert_true(!@cdcl.check_refutation(cnf(problem), proof.propositional))
}

///|
test "positive square root of two has a checked exact nonlinear model" {
  let p = test_polynomial(1, [(1, 1, [2]), (-2, 1, [0])])
  let x = test_polynomial(1, [(1, 1, [1])])
  let problem = test_problem(
    1,
    @qf.Conjunction(Atom(p, EqualZero), Atom(x, GreaterZero)),
  )
  let model = test_sat(problem)
  assert_eq(
    @cad.evaluate_formula(point(model), @qf.Atom(p, EqualZero)),
    Ok(true),
  )
  assert_eq(
    @cad.evaluate_formula(point(model), @qf.Atom(x, GreaterZero)),
    Ok(true),
  )
}

///|
test "Boolean disjunction preserves the arithmetic meaning of source atoms" {
  let p = test_polynomial(1, [(1, 1, [2]), (-2, 1, [0])])
  let x = test_polynomial(1, [(1, 1, [1])])
  let problem = test_problem(
    1,
    @qf.Conjunction(
      Atom(p, EqualZero),
      Disjunction(Atom(x, LessZero), Atom(x, GreaterZero)),
    ),
  )
  let _ = test_sat(problem)
  let contradiction = test_problem(
    1,
    @qf.Conjunction(Atom(p, EqualZero), Atom(p, NotZero)),
  )
  assert_eq(@core.length(atoms(contradiction)), @oracle.nat(2))
  let proof = test_unsat(contradiction)
  assert_eq(@core.length(proof.lemmas), @oracle.nat(1))
}

///|
test "canonical completion rechecks CNF and rejects duplicate invalid and inconsistent IDs" {
  let cnf = @oracle.chain([
    @oracle.chain([test_literal(0, true), test_literal(1, true)]),
  ])
  assert_eq(
    complete_boolean(cnf, @oracle.chain([test_literal(0, true)])),
    Some(@oracle.chain([test_literal(0, true), test_literal(1, false)])),
  )
  assert_eq(complete_boolean(cnf, @core.Nil), None)
  assert_eq(
    complete_boolean(
      cnf,
      @oracle.chain([test_literal(0, true), test_literal(0, true)]),
    ),
    None,
  )
  assert_eq(
    complete_boolean(
      cnf,
      @oracle.chain([test_literal(0, true), test_literal(0, false)]),
    ),
    None,
  )
  assert_eq(
    complete_boolean(
      cnf,
      @oracle.chain([test_literal(0, true), test_literal(2, false)]),
    ),
    None,
  )
}

///|
test "models reject source context Boolean payload and real point substitution" {
  let p = test_polynomial(1, [(1, 1, [2]), (-2, 1, [0])])
  let problem = test_problem(1, @qf.Atom(p, EqualZero))
  let model = test_sat(problem)
  let other = test_problem(1, @qf.Atom(p, NotZero))
  assert_true(!check_model(other, model))
  assert_true(!check_model(problem, { ..model, context: context(other), }))
  assert_true(
    !check_model(problem, {
      ..model,
      context: { ..model.context, arity: @oracle.nat(0), },
    }),
  )
  assert_true(
    !check_model(problem, { ..model, point: @cad.rational_point(@core.Nil), }),
  )
  assert_true(
    !check_model(problem, {
      ..model,
      point: @cad.rational_point(@oracle.chain([@oracle.rational(0, 1)])),
    }),
  )
  assert_true(
    !check_model(problem, {
      ..model,
      booleans: @oracle.chain([test_literal(0, false)]),
    }),
  )
  assert_true(
    !check_model(problem, {
      ..model,
      booleans: @core.Cons(test_literal(0, false), booleans(model)),
    }),
  )
  assert_true(
    !check_model(problem, {
      ..model,
      booleans: @core.Cons(test_literal(99, true), booleans(model)),
    }),
  )
}

///|
test "theory lemmas and RUP proof reject detached coherent and payload substitutions" {
  let p = test_polynomial(1, [(1, 1, [2])])
  let problem = test_problem(1, @qf.Atom(p, LessZero))
  let proof = test_unsat(problem)
  let lemma = match proof.lemmas {
    Cons(lemma, Nil) => lemma
    _ => abort("one lemma expected")
  }
  assert_eq(
    lemma_clause(problem, {
      ..lemma,
      assignment: @oracle.chain([test_literal(0, false)]),
    }),
    None,
  )
  assert_eq(
    lemma_clause(problem, {
      ..lemma,
      assignment: @oracle.chain([test_literal(1, true)]),
    }),
    None,
  )
  assert_eq(
    lemma_clause(problem, {
      ..lemma,
      assignment: @oracle.chain([test_literal(0, true), test_literal(0, true)]),
    }),
    None,
  )
  assert_eq(lemma_clause(problem, { ..lemma, assignment: @core.Nil, }), None)
  assert_eq(
    lemma_clause(problem, {
      ..lemma,
      decomposition: { ..lemma.decomposition, arity: @oracle.nat(0), },
    }),
    None,
  )
  assert_eq(
    lemma_clause(problem, {
      ..lemma,
      decomposition: { ..lemma.decomposition, formula: @qf.Truth(false), },
    }),
    None,
  )
  assert_eq(
    lemma_clause(problem, {
      ..lemma,
      decomposition: { ..lemma.decomposition, tree: @cad.Leaf(false), },
    }),
    None,
  )
  let other_polynomial = test_polynomial(1, [(1, 1, [2]), (1, 1, [0])])
  let other = test_problem(1, @qf.Atom(other_polynomial, LessZero))
  assert_eq(lemma_clause(other, lemma), None)
  assert_eq(lemma_clause(other, { ..lemma, context: context(other), }), None)
  assert_true(!check_refutation(other, proof))
  assert_true(
    !check_refutation(other, {
      ..proof,
      context: context(other),
      lemmas: @oracle.chain([{ ..lemma, context: context(other), }]),
    }),
  )
  assert_true(!check_refutation(problem, { ..proof, lemmas: @core.Nil, }))
  assert_true(
    !check_refutation(problem, { ..proof, propositional: @cdcl.Rup(@core.Nil), }),
  )
  assert_true(
    !check_refutation(problem, {
      ..proof,
      propositional: @cdcl.Rup(
        @oracle.chain([@oracle.chain([test_literal(0, true)])]),
      ),
    }),
  )
}

///|
test "zero fuel and one-step continuation retain an unfinished search" {
  let problem = test_problem(
    1,
    @qf.Atom(test_polynomial(1, [(1, 1, [2])]), LessZero),
  )
  let initial = start(problem)
  let paused = match run(initial, @core.Zero) {
    Ok(Paused(search)) => search
    _ => abort("zero fuel must pause")
  }
  assert_eq(transitions(paused), @core.Zero)
  let mut search = paused
  let mut finished = false
  let mut saw_theory_conflict = false
  for _ in 0..<5000 {
    match run(search, @oracle.nat(1)) {
      Ok(Paused(next)) => {
        assert_eq(transitions(next), @core.Succ(transitions(search)))
        saw_theory_conflict = saw_theory_conflict ||
          @oracle.int_of_nat(theory_conflicts(next)) > 0
        search = next
      }
      Ok(Unsatisfiable(proof)) => {
        assert_true(check_refutation(problem, proof))
        finished = true
        break
      }
      _ => abort("unexpected continuation result")
    }
  }
  assert_true(finished)
  assert_true(saw_theory_conflict)
}

///|
test "three-variable sphere constraints have an exact nonlinear model" {
  let sphere = test_polynomial(3, [
    (1, 1, [2, 0, 0]),
    (1, 1, [0, 2, 0]),
    (1, 1, [0, 0, 2]),
    (-1, 1, [0, 0, 0]),
  ])
  let x = test_polynomial(3, [(1, 1, [1, 0, 0])])
  let y = test_polynomial(3, [(1, 1, [0, 1, 0])])
  let z = test_polynomial(3, [(1, 1, [0, 0, 1])])
  let source : @qf.Formula = Conjunction(
    Atom(sphere, EqualZero),
    Conjunction(
      Atom(x, GreaterZero),
      Conjunction(Atom(y, GreaterZero), Atom(z, GreaterZero)),
    ),
  )
  let problem = test_problem(3, source)
  let model = test_sat(problem)
  assert_eq(@cad.evaluate_formula(point(model), source), Ok(true))
  assert_eq(@core.length(@cad.coordinates(point(model))), @oracle.nat(3))
}

///|
test "three-variable sum of squares below zero has a checked refutation" {
  let sum = test_polynomial(3, [
    (1, 1, [2, 0, 0]),
    (1, 1, [0, 2, 0]),
    (1, 1, [0, 0, 2]),
  ])
  let problem = test_problem(3, @qf.Atom(sum, LessZero))
  let proof = test_unsat(problem)
  assert_eq(@core.length(proof.lemmas), @oracle.nat(1))
}
