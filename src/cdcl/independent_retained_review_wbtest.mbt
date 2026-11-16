///|
fn retained_review_cnf(
  labels : Array[Int32],
  clauses : Array[Array[Int32]],
) -> @sat.Cnf {
  @oracle.chain(
    clauses.map(fn(clause) {
      @oracle.chain(
        clause.map(fn(code) {
          let index = if code > 0 { code - 1 } else { -code - 1 }
          @sat.Literal::{
            variable: @oracle.nat(labels[index]),
            positive: code > 0,
          }
        }),
      )
    }),
  )
}

///|
fn retained_review_statistics(
  before : Statistics,
  after : Statistics,
) -> Unit raise {
  assert_true(
    @oracle.int_of_nat(after.transitions) >=
    @oracle.int_of_nat(before.transitions),
  )
  assert_true(
    @oracle.int_of_nat(after.decisions) >= @oracle.int_of_nat(before.decisions),
  )
  assert_true(
    @oracle.int_of_nat(after.propagations) >=
    @oracle.int_of_nat(before.propagations),
  )
  assert_true(
    @oracle.int_of_nat(after.conflicts) >= @oracle.int_of_nat(before.conflicts),
  )
  assert_true(
    @oracle.int_of_nat(after.learned) >= @oracle.int_of_nat(before.learned),
  )
  assert_true(
    @oracle.int_of_nat(after.backjumps) >= @oracle.int_of_nat(before.backjumps),
  )
}

///|
fn retained_review_model(
  labels : Array[Int32],
  clauses : Array[Array[Int32]],
  model : @sat.Model,
) -> Unit raise {
  let values = @oracle.array(model)
  for index in 0..<values.length() {
    let variable = @oracle.int_of_nat(values[index].variable)
    assert_true(labels.contains(variable))
    for other in (index + 1)..<values.length() {
      assert_false(values[index].variable.equal(values[other].variable))
    }
  }
  // Check each original literal directly through the source label map, without
  // normalizing the clauses or consulting the solver's clause evaluator.
  for clause in clauses {
    let mut holds = false
    for code in clause {
      let logical = if code > 0 { code - 1 } else { -code - 1 }
      for entry in values {
        if @oracle.int_of_nat(entry.variable) == labels[logical] &&
          entry.positive == (code > 0) {
          holds = true
        }
      }
    }
    assert_true(holds)
  }
  for logical in 0..<labels.length() {
    let used = clauses.any(fn(clause) {
      clause.any(fn(code) { code.abs() == logical + 1 })
    })
    if used {
      assert_true(
        values.any(fn(entry) {
          @oracle.int_of_nat(entry.variable) == labels[logical]
        }),
      )
    }
  }
}

///|
fn retained_review_decision(
  labels : Array[Int32],
  clauses : Array[Array[Int32]],
  expected_models : Int32,
  status : IncrementalStatus,
) -> Search? raise {
  let formula = retained_review_cnf(labels, clauses)
  match status {
    Satisfiable(model, cursor) => {
      assert_true(expected_models > 0)
      retained_review_model(labels, clauses, model)
      assert_true(@sat.check_model(formula, model))
      Some(cursor)
    }
    Unsatisfiable(proof) => {
      assert_eq(expected_models, 0)
      assert_true(check_refutation(formula, proof))
      None
    }
    Paused(cursor) => Some(cursor)
    InvariantViolation =>
      fail("independent retained schedule found invariant violation")
  }
}

///|
fn retained_review_schedule(
  name : String,
  labels : Array[Int32],
  base : Array[Array[Int32]],
  additions : Array[Array[Int32]],
  budgets : Array[Int32],
  expected : Array[Int32],
) -> Unit raise {
  assert_eq(additions.length(), budgets.length())
  assert_eq(expected.length(), additions.length() + 1)
  for scanning in [false, true] {
    let clauses = base.copy()
    let initial = retained_review_cnf(labels, base)
    let mut state = if scanning {
      start_scanning(initial)
    } else {
      start(initial)
    }
    for prefix in 0..<=additions.length() {
      if prefix > 0 {
        let external = retained_review_cnf(labels, [additions[prefix - 1]])
        let clause = @oracle.array(external)[0]
        let before = state
        state = add_clause(state, clause)
        assert_eq(state.trail, before.trail)
        assert_eq(state.level, before.level)
        assert_eq(state.proof_rev, before.proof_rev)
        assert_eq(statistics(state), statistics(before))
        clauses.push(additions[prefix - 1])
      }
      let complete = run_incremental(state, @oracle.nat(2000))
      assert_false(complete is Paused(_), msg=name)
      ignore(
        retained_review_decision(labels, clauses, expected[prefix], complete),
      )
      match complete {
        Unsatisfiable(proof) => {
          if expected[0] > 0 {
            assert_false(check_refutation(initial, proof))
          }
          let steps = match proof {
            Rup(steps) => @oracle.array(steps)
          }
          assert_true(steps.length() > 0)
          let missing_empty = @oracle.chain(
            [
              for i in 0..<(steps.length() - 1) => steps[i]
            ],
          )
          assert_false(
            check_refutation(
              retained_review_cnf(labels, clauses),
              Rup(missing_empty),
            ),
          )
          let detached_true = retained_review_cnf(labels, [[1, -1]])
          assert_false(check_refutation(detached_true, proof))
        }
        _ => ()
      }
      let budget = if prefix == 0 { 1 } else { budgets[prefix - 1] }
      let advanced = run_incremental(state, @oracle.nat(budget))
      match
        retained_review_decision(labels, clauses, expected[prefix], advanced) {
        Some(next) => {
          retained_review_statistics(statistics(state), statistics(next))
          if budget == 0 {
            assert_eq(next, state)
          }
          state = next
        }
        // The pre-conflict immutable state still names all current input
        // clauses; adding another axiom branches from that valid continuation.
        None => ()
      }
    }
  }
}

///|
test "independent retained inserted unit reappears after a later nonroot backjump" {
  let labels = [0, 2, 7, 31, 255]
  let clauses = [[-1, 4], [2, 5]]
  let initial = retained_review_cnf(labels, clauses)
  let cursor = match run_incremental(start(initial), @oracle.nat(100)) {
    Satisfiable(_, cursor) => cursor
    _ => fail("base is satisfiable")
  }
  assert_true(@oracle.int_of_nat(cursor.level) >= 2)
  let new_unit = @oracle.array(retained_review_cnf(labels, [[3]]))[0]
  let cursor = add_clause(cursor, new_unit)
  let cursor = match run_incremental(cursor, @oracle.nat(1)) {
    Paused(cursor) => cursor
    _ => fail("new unit must propagate at current nonroot level")
  }
  assert_true(
    @oracle.array(cursor.trail).any(fn(entry) {
      @oracle.int_of_nat(entry.literal.source) == labels[2] &&
      @oracle.int_of_nat(entry.level) > 0
    }),
  )
  clauses.push([3])
  let conflict = @oracle.array(retained_review_cnf(labels, [[-2, 1]]))[0]
  let cursor = add_clause(cursor, conflict)
  clauses.push([-2, 1])
  let outcome = run_incremental(cursor, @oracle.nat(100))
  let finished = retained_review_decision(labels, clauses, 1, outcome).unwrap()
  assert_true(@oracle.int_of_nat(statistics(finished).backjumps) > 0)
  let model = match outcome {
    Satisfiable(model, _) => model
    _ => fail("expected SAT after backjump")
  }
  assert_true(
    @oracle.array(model).any(fn(lit) {
      @oracle.int_of_nat(lit.variable) == labels[2] && lit.positive
    }),
  )
  // Complete a stronger formula from this learned SAT continuation. Old RUP
  // additions remain an actual prefix of the final refutation after input
  // strengthening; they are not silently discarded at the candidate boundary.
  assert_true(finished.proof_rev is Cons(_, _))
  let old_steps = @oracle.array(@core.reverse(finished.proof_rev))
  let mut stronger = finished
  for external in [[2], [-1]] {
    stronger = add_clause(
      stronger,
      @oracle.array(retained_review_cnf(labels, [external]))[0],
    )
    clauses.push(external)
  }
  match run_incremental(stronger, @oracle.nat(100)) {
    Unsatisfiable(proof) => {
      assert_true(check_refutation(retained_review_cnf(labels, clauses), proof))
      assert_false(check_refutation(initial, proof))
      let steps = match proof {
        Rup(steps) => @oracle.array(steps)
      }
      assert_true(steps.length() > old_steps.length())
      for index in 0..<old_steps.length() {
        assert_eq(steps[index], old_steps[index])
      }
    }
    _ => fail("a=false and b=true conflict with the added implication")
  }
}

///|
test "independent retained additions while a watch bucket is active preserve every implication" {
  let labels = [0, 2, 7, 31, 255]
  let clauses = [[1], [-1, 2], [-1, 3], [-2, 4]]
  let initial = retained_review_cnf(labels, clauses)
  let mut state = start(initial)
  let mut found_active = false
  for _ in 0..<10 {
    match run_incremental(state, @oracle.nat(1)) {
      Paused(next) => state = next
      _ => fail("need paused active bucket")
    }
    match state.watch {
      Some(watch) =>
        if watch.active is Some(_) {
          found_active = true
          break
        }
      None => fail("watched mode required")
    }
  }
  assert_true(found_active)
  for external in [[-3, 5], [-5]] {
    state = add_clause(
      state,
      @oracle.array(retained_review_cnf(labels, [external]))[0],
    )
    clauses.push(external)
  }
  match run_incremental(state, @oracle.nat(100)) {
    Unsatisfiable(proof) => {
      assert_true(check_refutation(retained_review_cnf(labels, clauses), proof))
      assert_false(check_refutation(initial, proof))
      assert_false(
        check_refutation(
          retained_review_cnf(labels, [[1], [-1, 2], [-1, 3], [-2, 4], [-5]]),
          proof,
        ),
      )
      assert_false(
        check_refutation(initial, Rup(@core.Cons(@core.Nil, @core.Nil))),
      )
    }
    _ => fail("source implies c and new clauses require not c")
  }
}
