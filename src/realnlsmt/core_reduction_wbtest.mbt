///|
fn core_solve(initial : Search) -> (Outcome, Search) raise {
  let mut state = initial
  for _ in 0..<100000 {
    match step(state) {
      Ok(Paused(next)) => state = next
      Ok(answer) => return (answer, state)
      Err(error) => fail("core search error: \{error.to_repr()}")
    }
  }
  fail("bounded core regression exhausted fuel; no UNSAT inferred")
}

///|
test "cover reduction learns six unit theory clauses instead of sixty-three complete assignments" {
  let problem = test_problem(0, impossible_alternatives(6, true))
  for reducing in [true, false] {
    let (answer, terminal) = core_solve(
      if reducing {
        start_core(problem)
      } else {
        start_retained(problem)
      },
    )
    match answer {
      Unsatisfiable(proof) => {
        assert_true(check_refutation(problem, proof))
        assert_eq(
          @core.length(proof.lemmas),
          @oracle.nat(if reducing { 6 } else { 63 }),
        )
        assert_eq(boolean_restarts(terminal), @core.Zero)
        if reducing {
          assert_true(@oracle.int_of_nat(core_probes(terminal)) > 0)
          assert_true(@oracle.int_of_nat(core_literals_removed(terminal)) > 0)
          for lemma in @oracle.array(proof.lemmas) {
            assert_eq(@core.length(lemma.assignment), @oracle.nat(1))
            assert_eq(
              @core.length(lemma_clause(problem, lemma).unwrap()),
              @oracle.nat(1),
            )
          }
        } else {
          assert_eq(core_probes(terminal), @core.Zero)
          assert_eq(core_literals_removed(terminal), @core.Zero)
        }
        assert_false(@cdcl.check_refutation(cnf(problem), proof.propositional))
      }
      _ => fail("positive constants cannot be negative")
    }
  }
}

///|
test "nonlinear independent impossible atoms use original checked covers for smaller conflicts" {
  let problem = test_problem(1, impossible_alternatives(4, false))
  let (reduced, _) = core_solve(start_core(problem))
  let (whole, _) = core_solve(start_retained(problem))
  let reduced = match reduced {
    Unsatisfiable(proof) => proof
    _ => fail("squares UNSAT")
  }
  let whole = match whole {
    Unsatisfiable(proof) => proof
    _ => fail("reference squares UNSAT")
  }
  assert_true(check_refutation(problem, reduced))
  assert_true(check_refutation(problem, whole))
  assert_eq(@core.length(reduced.lemmas), @oracle.nat(4))
  assert_eq(@core.length(whole.lemmas), @oracle.nat(15))
  for lemma in @oracle.array(reduced.lemmas) {
    assert_eq(@core.length(lemma.assignment), @oracle.nat(1))
    let signed = signed_formula(problem, lemma.assignment).unwrap()
    let checked = @cad.check_cover(arity(problem), signed, lemma.decomposition).unwrap()
    assert_true(
      @cad.check_result(@cad.problem_of(checked), checked, lemma.decomposition),
    )
    assert_eq(
      @cad.sentence(checked, @oracle.chain([@logic.Quantifier::Exists])),
      Ok(false),
    )
    // The wider certified projection remains a helper partition. A detached
    // canonical Problem still fixes its own different exact projection.
    let canonical = @cad.prepare(arity(problem), signed).unwrap()
    if !@cad.projection(canonical).equal(lemma.decomposition.projection) {
      assert_true(@cad.check(canonical, lemma.decomposition) is None)
    }
  }
}

///|
test "joint bilinear conflicts retain both necessary signed atoms" {
  let x = test_polynomial(2, [(1, 1, [1, 0])])
  let xy_one = test_polynomial(2, [(1, 1, [1, 1]), (-1, 1, [0, 0])])
  let problem = test_problem(
    2,
    @qf.Conjunction(@qf.Atom(x, EqualZero), @qf.Atom(xy_one, EqualZero)),
  )
  let (answer, terminal) = core_solve(start_core(problem))
  match answer {
    Unsatisfiable(proof) => {
      assert_true(check_refutation(problem, proof))
      assert_eq(@core.length(proof.lemmas), @oracle.nat(1))
      let lemma = @oracle.array(proof.lemmas)[0]
      assert_eq(@core.length(lemma.assignment), @oracle.nat(2))
      assert_eq(core_literals_removed(terminal), @core.Zero)
      assert_eq(core_probes(terminal), @oracle.nat(2))
      for kept in @oracle.array(lemma.assignment) {
        let singleton = @oracle.chain([kept])
        assert_true(
          lemma_clause(problem, { ..lemma, assignment: singleton, }) is None,
        )
      }
    }
    _ => fail("x=0 and xy=1 are incompatible")
  }
}

///|
test "core probes are resumable and preserve the original cover across successful deletions" {
  let problem = test_problem(0, impossible_alternatives(4, true))
  let mut state = start(problem)
  let mut saw_reduction = false
  let mut saw_success = false
  let mut done = false
  for _ in 0..<10000 {
    match state.phase {
      Reducing(_, cursor, core) => {
        saw_reduction = true
        match run(state, @core.Zero).unwrap() {
          Paused(paused) => {
            assert_eq(transitions(paused), transitions(state))
            assert_eq(core_probes(paused), core_probes(state))
            match paused.phase {
              Reducing(_, preserved, frozen) => {
                assert_true(preserved.equal(cursor))
                assert_eq(
                  @cad.certificate(frozen.cover),
                  @cad.certificate(core.cover),
                )
                assert_eq(frozen.assignment, core.assignment)
                assert_eq(frozen.pending, core.pending)
              }
              _ => fail("zero fuel cannot complete a pending reduction")
            }
          }
          _ => fail("zero fuel cannot decide")
        }
      }
      _ => ()
    }
    match step(state).unwrap() {
      Paused(next) => {
        let before = @oracle.int_of_nat(core_probes(state))
        let after = @oracle.int_of_nat(core_probes(next))
        assert_true(after >= before && after <= before + 1)
        if @oracle.int_of_nat(core_literals_removed(next)) >
          @oracle.int_of_nat(core_literals_removed(state)) {
          saw_success = true
          match (state.phase, next.phase) {
            (Reducing(_, _, old), Reducing(_, _, current)) => {
              assert_eq(
                @cad.certificate(current.cover),
                @cad.certificate(old.cover),
              )
              assert_eq(
                @core.length(current.assignment),
                @core.subtract(@core.length(old.assignment), @oracle.nat(1)),
              )
            }
            _ => fail("successful probe keeps an explicit continuation")
          }
        }
        state = next
      }
      Unsatisfiable(proof) => {
        assert_true(check_refutation(problem, proof))
        done = true
        break
      }
      _ => fail("impossible constants are UNSAT")
    }
  }
  assert_true(saw_reduction && saw_success && done)
}

///|
test "core reduction preserves exact SAT models and rejects altered source or lemma polarity" {
  let x = test_polynomial(1, [(1, 1, [1])])
  let problem = test_problem(
    1,
    @qf.Disjunction(impossible_alternatives(3, false), @qf.Atom(x, AtLeastZero)),
  )
  for initial in [start_core(problem), start_retained(problem)] {
    let (answer, _) = core_solve(initial)
    match answer {
      Satisfiable(model) => {
        assert_true(check_model(problem, model))
        assert_eq(
          @cad.evaluate_formula(point(model), formula(problem)),
          Ok(true),
        )
      }
      _ => fail("x=0 is an exact model")
    }
  }
  let no = test_problem(0, impossible_alternatives(3, true))
  let (answer, _) = core_solve(start_core(no))
  let proof = match answer {
    Unsatisfiable(proof) => proof
    _ => fail("constants UNSAT")
  }
  let lemma = @oracle.array(proof.lemmas)[0]
  assert_true(lemma_clause(no, lemma) is Some(_))
  let flipped = {
    ..lemma,
    assignment: @core.map(lemma.assignment, @sat.negate),
  }
  assert_true(lemma_clause(no, flipped) is None)
  assert_true(lemma_clause(no, { ..lemma, assignment: @core.Nil, }) is None)
  assert_false(check_refutation(no, { ..proof, lemmas: @core.Nil, }))
  let other = test_problem(0, @qf.Truth(true))
  assert_false(check_refutation(other, { ..proof, context: context(other), }))
}
