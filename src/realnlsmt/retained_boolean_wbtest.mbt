///|
fn impossible_alternatives(count : Int32, constant : Bool) -> @qf.Formula {
  let mut source : @qf.Formula = @qf.Truth(false)
  for index in 0..<count {
    let p = if constant {
      test_polynomial(0, [(index + 1, 1, [])])
    } else {
      test_polynomial(1, [(1, 1, [2]), (index + 1, 1, [0])])
    }
    source = @qf.Disjunction(source, @qf.Atom(p, @qf.LessZero))
  }
  source
}

///|
test "retained Boolean continuation exactly extends the cursor after every checked theory conflict" {
  let problem = test_problem(0, impossible_alternatives(4, true))
  for retained in [true, false] {
    let mut state = if retained {
      start(problem)
    } else {
      start_restarting(problem)
    }
    let mut saw_conflicts = 0
    let mut saw_retained_decisions = false
    let mut done = false
    for _ in 0..<20000 {
      let cursor = match state.phase {
        Theory(_, _, cursor, _) | Reducing(_, cursor, _) => Some(cursor)
        Boolean(_) => None
      }
      match step(state).unwrap() {
        Paused(next) => {
          if @core.length(next.lemmas_rev) != @core.length(state.lemmas_rev) {
            saw_conflicts += 1
            let cursor = cursor.unwrap()
            let lemma = @oracle.array(next.lemmas_rev)[0]
            let clause = lemma_clause(problem, lemma).unwrap()
            let after = match next.phase {
              Boolean(value) => value
              _ => fail("theory conflict must return to Boolean search")
            }
            if retained {
              assert_true(after.equal(@cdcl.add_clause(cursor, clause)))
              assert_eq(@cdcl.statistics(after), @cdcl.statistics(cursor))
              if @oracle.int_of_nat(@cdcl.statistics(after).decisions) > 0 {
                saw_retained_decisions = true
              }
              assert_eq(boolean_restarts(next), @core.Zero)
            } else {
              assert_true(after.equal(@cdcl.start(next.formula)))
              assert_eq(@cdcl.statistics(after).transitions, @core.Zero)
              assert_eq(boolean_restarts(next), theory_conflicts(next))
            }
          }
          state = next
        }
        Unsatisfiable(proof) => {
          assert_true(check_refutation(problem, proof))
          assert_true(saw_conflicts > 1)
          assert_eq(@core.length(proof.lemmas), @oracle.nat(saw_conflicts))
          if retained {
            assert_true(saw_retained_decisions)
          }
          // External theory clauses have separate CAD justifications. Their
          // consequence cannot be presented as a refutation of Boolean CNF alone.
          assert_false(
            @cdcl.check_refutation(cnf(problem), proof.propositional),
          )
          done = true
          break
        }
        _ => fail("positive constants are never negative")
      }
    }
    assert_true(done)
  }
}

///|
test "retained and restarting searches agree on several conflicts and a later exact model" {
  let x = test_polynomial(1, [(1, 1, [1])])
  let square = test_polynomial(1, [(1, 1, [2]), (-2, 1, [0])])
  let impossible = impossible_alternatives(3, false)
  let cases : Array[(@qf.Formula, Bool)] = [
    (impossible, false),
    (@qf.Disjunction(impossible, @qf.Atom(x, @qf.AtLeastZero)), true),
    (
      @qf.Conjunction(
        @qf.Atom(square, @qf.EqualZero),
        @qf.Disjunction(impossible, @qf.Atom(x, @qf.GreaterZero)),
      ),
      true,
    ),
    (
      @qf.Conjunction(
        @qf.Atom(x, @qf.EqualZero),
        @qf.Negation(@qf.Atom(x, @qf.EqualZero)),
      ),
      false,
    ),
  ]
  for entry in cases {
    let (source, expected) = entry
    let problem = test_problem(1, source)
    for initial in [start(problem), start_restarting(problem)] {
      assert_eq(boolean_restarts(initial), @core.Zero)
      match solve_reference_mode(initial) {
        Satisfiable(model) => {
          assert_true(expected)
          assert_true(check_model(problem, model))
          assert_eq(@cad.evaluate_formula(point(model), source), Ok(true))
        }
        Unsatisfiable(proof) => {
          assert_false(expected)
          assert_true(check_refutation(problem, proof))
          if @oracle.array(proof.lemmas).length() > 0 {
            assert_false(
              check_refutation(problem, { ..proof, lemmas: @core.Nil, }),
            )
            let other = test_problem(1, @qf.Truth(true))
            assert_false(
              check_refutation(other, { ..proof, context: context(other), }),
            )
          }
        }
        Paused(_) => fail("bounded regression must finish")
      }
    }
  }
}

///|
test "retained candidate cursor survives arbitrary theory pauses and zero fuel" {
  let problem = test_problem(0, impossible_alternatives(3, true))
  let mut state = start(problem)
  let mut witnessed_theory = false
  for _ in 0..<1000 {
    match state.phase {
      Theory(_, _, cursor, _) => {
        witnessed_theory = true
        match run(state, @core.Zero).unwrap() {
          Paused(paused) => {
            assert_eq(transitions(paused), transitions(state))
            match paused.phase {
              Theory(_, _, same_cursor, _) =>
                assert_true(same_cursor.equal(cursor))
              _ => fail("fuel zero cannot drop the Boolean cursor")
            }
          }
          _ => fail("fuel zero is undecided")
        }
      }
      _ => ()
    }
    match step(state).unwrap() {
      Paused(next) => state = next
      Unsatisfiable(proof) => {
        assert_true(check_refutation(problem, proof))
        break
      }
      _ => fail("expected a constant arithmetic contradiction")
    }
  }
  assert_true(witnessed_theory)
}
