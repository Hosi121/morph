///|
fn solve_reference_mode(search : Search) -> Outcome raise {
  let mut current = search
  for _ in 0..<20000 {
    match step(current) {
      Ok(Paused(next)) => current = next
      Ok(outcome) => return outcome
      Err(error) => fail("differential search error: \{error.to_repr()}")
    }
  }
  fail("differential transition limit exhausted; no decision inferred")
}

///|
fn compare_reference_modes(
  arity : Int32,
  source : @qf.Formula,
  expected : Bool,
) -> Unit raise {
  let problem = test_problem(arity, source)
  for initial in [start(problem), start_full(problem)] {
    match solve_reference_mode(initial) {
      Satisfiable(model) => {
        assert_true(expected)
        assert_true(check_model(problem, model))
        assert_eq(@cad.evaluate_formula(point(model), source), Ok(true))
        assert_eq(
          @core.length(@cad.coordinates(point(model))),
          @oracle.nat(arity),
        )
      }
      Unsatisfiable(proof) => {
        assert_false(expected)
        assert_true(check_refutation(problem, proof))
        for lemma in @oracle.array(proof.lemmas) {
          assert_true(lemma_clause(problem, lemma) is Some(_))
        }
      }
      Paused(_) => fail("no decision inferred from paused reference search")
    }
  }
}

///|
test "pruned and full theory search agree on nullification and mixed Boolean alternatives" {
  let x = test_polynomial(2, [(1, 1, [1, 0])])
  let product = test_polynomial(2, [(1, 1, [1, 1])])
  let product_one = test_polynomial(2, [(1, 1, [1, 1]), (-1, 1, [0, 0])])
  let y_one = test_polynomial(2, [(1, 1, [0, 1]), (-1, 1, [0, 0])])
  let cases : Array[(@qf.Formula, Bool)] = [
    (Conjunction(Atom(x, EqualZero), Atom(product, EqualZero)), true),
    (Conjunction(Atom(x, EqualZero), Atom(product_one, EqualZero)), false),
    (Conjunction(Atom(x, EqualZero), Atom(product_one, NotZero)), true),
    (
      Conjunction(
        Atom(x, EqualZero),
        Disjunction(Atom(product_one, EqualZero), Atom(y_one, EqualZero)),
      ),
      true,
    ),
    (
      Conjunction(
        Atom(x, EqualZero),
        Conjunction(
          Atom(product_one, EqualZero),
          Negation(Atom(y_one, EqualZero)),
        ),
      ),
      false,
    ),
    (
      Disjunction(
        Conjunction(Atom(x, EqualZero), Atom(product_one, EqualZero)),
        Conjunction(Atom(x, NotZero), Atom(y_one, EqualZero)),
      ),
      true,
    ),
  ]
  for entry in cases {
    let (source, expected) = entry
    compare_reference_modes(2, source, expected)
  }
}

///|
test "pruned and full theory search agree on constant and irrational models" {
  for arity in [0, 2] {
    compare_reference_modes(arity, @qf.Truth(true), true)
    compare_reference_modes(arity, @qf.Truth(false), false)
  }
  let square = test_polynomial(1, [(1, 1, [2]), (-2, 1, [0])])
  let x = test_polynomial(1, [(1, 1, [1])])
  compare_reference_modes(
    1,
    @qf.Conjunction(Atom(square, EqualZero), Atom(x, GreaterZero)),
    true,
  )
  compare_reference_modes(
    1,
    @qf.Conjunction(Atom(square, EqualZero), Atom(square, NotZero)),
    false,
  )
}

///|
fn assert_reference_mode(search : Search, full : Bool) -> Unit raise {
  match search.mode {
    FullCad => assert_true(full)
    PrunedCad => assert_false(full)
  }
  match search.phase {
    Theory(_, _, _, FullSolver(_)) => assert_true(full)
    Theory(_, _, _, PrunedSolver(_)) => assert_false(full)
    Boolean(_) => ()
  }
}

///|
test "both modes retain theory clauses and their selected solver through Boolean restarts" {
  let p = test_polynomial(1, [(1, 1, [2]), (1, 1, [0])])
  let q = test_polynomial(1, [(1, 1, [2]), (2, 1, [0])])
  let problem = test_problem(
    1,
    @qf.Disjunction(Atom(p, LessZero), Atom(q, LessZero)),
  )
  for full in [false, true] {
    let mut search = if full { start_full(problem) } else { start(problem) }
    let mut saw_restart = false
    let mut finished = false
    let mut conflicts = 0
    for _ in 0..<20000 {
      assert_reference_mode(search, full)
      let paused = match run(search, @core.Zero) {
        Ok(Paused(value)) => value
        _ => fail("zero fuel must preserve unfinished search")
      }
      assert_eq(transitions(paused), transitions(search))
      match run(paused, @oracle.nat(1)) {
        Ok(Paused(next)) => {
          assert_eq(transitions(next), @core.Succ(transitions(search)))
          let next_conflicts = @oracle.int_of_nat(theory_conflicts(next))
          assert_true(next_conflicts >= conflicts)
          if next_conflicts > conflicts {
            assert_true(next.phase is Boolean(_))
            assert_reference_mode(next, full)
            assert_eq(
              @core.length(next.formula),
              @core.add(@core.length(cnf(problem)), theory_conflicts(next)),
            )
            saw_restart = true
          }
          conflicts = next_conflicts
          search = next
        }
        Ok(Unsatisfiable(proof)) => {
          assert_true(check_refutation(problem, proof))
          assert_true(@oracle.int_of_nat(@core.length(proof.lemmas)) > 1)
          assert_true(saw_restart)
          finished = true
          break
        }
        Ok(_) => fail("positive squares cannot satisfy a negative alternative")
        Err(error) => fail("restart error: \{error.to_repr()}")
      }
    }
    assert_true(finished)
  }
}

///|
test "both modes propagate CAD preparation errors rather than claiming UNSAT" {
  let problem = test_problem(
    1,
    @qf.Atom(test_polynomial(1, [(1, 1, [1])]), EqualZero),
  )
  // A coherent source context must still agree with its arithmetic payload.
  // Here projection cannot even start because the deliberately forged arity
  // disagrees with the signed source polynomial.
  let malformed = {
    ..problem,
    context: { ..context(problem), arity: @core.Zero, },
  }
  for initial in [start(malformed), start_full(malformed)] {
    let mut search = initial
    let mut saw_error = false
    for _ in 0..<100 {
      match step(search) {
        Ok(Paused(next)) => search = next
        Err(CadFailure(WrongArity)) => {
          saw_error = true
          break
        }
        Err(error) => fail("unexpected error: \{error.to_repr()}")
        Ok(_) => fail("invalid input must not yield a satisfiability decision")
      }
    }
    assert_true(saw_error)
  }
}
