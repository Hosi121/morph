// Experimental decision-only value lookup; production remains unchanged.

///|
/// The assignment trie path already establishes variable identity.
fn index_value_direct(literal : Atom, values : Index[Assignment]) -> Value {
  match index_get(values, @binary.bits(literal.key)) {
    None => Unassigned
    Some(entry) =>
      match (entry.literal.positive, literal.positive) {
        (true, true) | (false, false) => True
        _ => False
      }
  }
}

///|
fn indexed_clause_using(
  clause : Lits,
  values : Index[Assignment],
  verify_key : Bool,
) -> ClauseState {
  match clause {
    Nil => Conflict
    Cons(literal, rest) =>
      match
        (match verify_key {
          true => index_value(literal, values)
          false => index_value_direct(literal, values)
        }) {
        True => Satisfied
        False => indexed_clause_using(rest, values, verify_key)
        Unassigned =>
          match indexed_clause_using(rest, values, verify_key) {
            Satisfied => Satisfied
            Conflict => Unit(literal)
            Unit(_) | Open(_) => Open(literal)
          }
      }
  }
}

///|
/// At quiescence the watch invariant excludes pending units and conflicts.
/// Keep the full database diagnostic in watch_decision_checked for tests.
fn watch_decision_using(
  db : Database,
  values : Index[Assignment],
  verify_key : Bool,
) -> Inspection {
  match db {
    Nil => Complete
    Cons(clause, rest) =>
      match indexed_clause_using(clause, values, verify_key) {
        Satisfied => watch_decision_using(rest, values, verify_key)
        Open(literal) => Decide(literal)
        Unit(_) | Conflict => Broken
      }
  }
}

///|
/// Finish a bucket incrementally, retaining the remaining IDs when a new
/// implied literal is returned. Clause moves remain valid after unassignment.
fn watch_inspect_with_keys(
  state : WatchState,
  db : Database,
  check_rest : Bool,
  verify_key : Bool,
) -> (Inspection, WatchState) {
  match state.empty {
    true => (Contradiction(Nil), state)
    false =>
      match state.units {
        Cons((literal, reason), rest) => {
          let state = { ..state, units: rest, }
          match index_value(literal, state.values) {
            True => watch_inspect_with_keys(state, db, check_rest, verify_key)
            False => (Contradiction(reason), state)
            Unassigned => (Propagate(literal, reason), state)
          }
        }
        Nil =>
          match state.active {
            None =>
              match @core.dequeue(state.pending) {
                None => {
                  let decision = match check_rest {
                    true => watch_decision_checked(db, state.values)
                    false => watch_decision_using(db, state.values, verify_key)
                  }
                  (decision, state)
                }
                Some((literal, pending)) => {
                  let literal = opposite(literal)
                  watch_inspect_with_keys(
                    {
                      ..state,
                      pending,
                      active: Some((literal, bucket(state, literal))),
                    },
                    db,
                    check_rest,
                    verify_key,
                  )
                }
              }
            Some((_, Nil)) =>
              watch_inspect_with_keys(
                { ..state, active: None, },
                db,
                check_rest,
                verify_key,
              )
            Some((false_watch, Cons(id, rest))) => {
              let state = { ..state, active: Some((false_watch, rest)), }
              match index_get(state.clauses, @binary.bits(id)) {
                None => (Broken, state)
                Some(clause) => {
                  let other = match same(clause.first, false_watch) {
                    true => clause.second
                    false => Some(clause.first)
                  }
                  match other {
                    None => (Contradiction(clause.literals), state)
                    Some(other) =>
                      match index_value(other, state.values) {
                        True =>
                          watch_inspect_with_keys(
                            state, db, check_rest, verify_key,
                          )
                        _ =>
                          match
                            replacement(
                              clause.literals,
                              false_watch,
                              other,
                              state.values,
                            ) {
                            Some(next) =>
                              watch_inspect_with_keys(
                                watch_move(
                                  state, clause, false_watch, next, other,
                                ),
                                db,
                                check_rest,
                                verify_key,
                              )
                            None =>
                              match index_value(other, state.values) {
                                False => (Contradiction(clause.literals), state)
                                Unassigned =>
                                  (Propagate(other, clause.literals), state)
                                True => (Broken, state)
                              }
                          }
                      }
                  }
                }
              }
            }
          }
      }
  }
}

///|
fn run_key_mode(
  search : Search,
  budget : @core.Nat,
  verify_key : Bool,
) -> (Status, Statistics) {
  match budget {
    Zero => (Paused(search), search.statistics)
    Succ(rest) => {
      let watched = search.watch.unwrap()
      let (inspection, watched) = watch_inspect_with_keys(
        watched,
        search.database,
        false,
        verify_key,
      )
      match transition({ ..search, watch: Some(watched), }, inspection) {
        (Paused(next), _) => run_key_mode(next, rest, verify_key)
        terminal => terminal
      }
    }
  }
}

///|
fn count_key_queries(
  db : Database,
  values : Index[Assignment],
) -> (Inspection, Int32, Int32) {
  let mut queries = 0
  let mut assigned = 0
  let lookup = fn(literal : Atom) {
    queries += 1
    match index_get(values, @binary.bits(literal.key)) {
      None => Unassigned
      Some(entry) => {
        assigned += 1
        match (entry.literal.positive, literal.positive) {
          (true, true) | (false, false) => True
          _ => False
        }
      }
    }
  }
  fn clause_state(clause : Lits) -> ClauseState {
    match clause {
      Nil => Conflict
      Cons(literal, rest) =>
        match lookup(literal) {
          True => Satisfied
          False => clause_state(rest)
          Unassigned =>
            match clause_state(rest) {
              Satisfied => Satisfied
              Conflict => Unit(literal)
              Unit(_) | Open(_) => Open(literal)
            }
        }
    }
  }
  fn visit(db : Database) -> Inspection {
    match db {
      Nil => Complete
      Cons(clause, rest) =>
        match clause_state(clause) {
          Satisfied => visit(rest)
          Open(literal) => Decide(literal)
          Unit(_) | Conflict => Broken
        }
    }
  }
  let result = visit(db)
  (result, queries, assigned)
}

///|
fn key_query_work(initial : Search) -> (Int32, Int32) raise {
  for state = initial, remaining = 200000, queries = 0, assigned = 0; remaining >
     0; {
    let (inspection, watched) = watch_inspect(
      state.watch.unwrap(),
      state.database,
    )
    let (queries, assigned) = match inspection {
      Decide(literal) => {
        let (counted, queries_here, assigned_here) = count_key_queries(
          state.database,
          watched.values,
        )
        match counted {
          Decide(expected) => assert_true(same(literal, expected))
          _ => fail("decision counter must select the same first open clause")
        }
        (queries + queries_here, assigned + assigned_here)
      }
      _ => (queries, assigned)
    }
    let (outcome, _) = transition(
      { ..state, watch: Some(watched), },
      inspection,
    )
    match outcome {
      Paused(next) => continue next, remaining - 1, queries, assigned
      Unsatisfiable(_) => break (queries, assigned)
      _ => fail("key-query counter miter must be refuted")
    }
  } nobreak {
    fail("key-query counter exhausted fuel")
  }
}

///|
test "same executable sixty-four-bit decision value lookup comparison" (
  b : @bench.T,
) {
  let cnf = @circuit.cnf(miter_formula(64))
  let initial = start(cnf)
  let budget = fuel(200000)
  let baseline = run_key_mode(initial, budget, true)
  assert_eq(baseline, run_key_mode(initial, budget, false))
  assert_eq(baseline, run_measured(initial, budget))
  let (queries, assigned) = key_query_work(initial)
  println(
    "decision-value-work width=64 queries=\{queries} redundant-key-comparisons=\{assigned}",
  )
  let (outcome, _) = baseline
  let (input, logged) = match outcome {
    Unsatisfiable(proof) => {
      let input = @ruplog.prepare(cnf)
      let logged = @ruplog.build_prepared(input, proof).unwrap()
      assert_true(@ruplog.check_prepared(input, logged))
      (input, logged)
    }
    _ => fail("compared miter must be refuted")
  }
  b.bench(
    fn() { b.keep(run_key_mode(initial, budget, true)) },
    name="checked-key decision values first control",
  )
  b.bench(
    fn() { b.keep(run_key_mode(initial, budget, false)) },
    name="trie-keyed decision values",
  )
  b.bench(
    fn() { b.keep(run_key_mode(initial, budget, false)) },
    name="trie-keyed repeated control",
  )
  b.bench(
    fn() { b.keep(run_key_mode(initial, budget, true)) },
    name="checked-key repeated control",
  )
  b.bench(
    fn() { b.keep(@ruplog.check_prepared(input, logged)) },
    name="unchanged prepared hinted checker control",
  )
}

///|
test "direct decision values preserve every paused state and final statistics" {
  for cnf in [pigeonhole(4, 3), @circuit.cnf(miter_formula(4))] {
    for state = start(cnf), count = 0 {
      assert_true(count < 10000)
      let checked = run_key_mode(state, fuel(1), true)
      assert_eq(checked, run_key_mode(state, fuel(1), false))
      assert_eq(checked, run_measured(state, fuel(1)))
      let (outcome, _) = checked
      match outcome {
        Paused(next) => continue next, count + 1
        Unsatisfiable(proof) => {
          assert_true(check_refutation(cnf, proof))
          break
        }
        _ => fail("decision-value comparison must end in UNSAT")
      }
    }
  }
}

///|
fn hinted_key_pipeline(
  cnf : @sat.Cnf,
  budget : @core.Nat,
  verify_key : Bool,
) -> Bool {
  let (outcome, _) = run_key_mode(start(cnf), budget, verify_key)
  match outcome {
    Unsatisfiable(proof) => {
      let input = @ruplog.prepare(cnf)
      match @ruplog.build_prepared(input, proof) {
        None => false
        Some(logged) => @ruplog.check_prepared(input, logged)
      }
    }
    _ => false
  }
}

///|
test "paired complete sixty-four-bit queries with alternating key lookup order" (
  b : @bench.T,
) {
  let cnf = @circuit.cnf(miter_formula(64))
  let budget = fuel(200000)
  let initial = start(cnf)
  let baseline = run_key_mode(initial, budget, true)
  assert_eq(baseline, run_key_mode(initial, budget, false))
  let (outcome, _) = baseline
  let (input, logged) = match outcome {
    Unsatisfiable(proof) => {
      let input = @ruplog.prepare(cnf)
      let logged = @ruplog.build_prepared(input, proof).unwrap()
      assert_true(@ruplog.check_prepared(input, logged))
      (input, logged)
    }
    _ => fail("paired miter must be refuted")
  }
  for pair in 0..<20 {
    let first_checked = pair % 2 == 0
    let started = @bench.monotonic_clock_start()
    let first = hinted_key_pipeline(cnf, budget, first_checked)
    let first_elapsed = @bench.monotonic_clock_end(started)
    let started = @bench.monotonic_clock_start()
    let second = hinted_key_pipeline(cnf, budget, !first_checked)
    let second_elapsed = @bench.monotonic_clock_end(started)
    b.keep(first)
    b.keep(second)
    assert_true(first)
    assert_true(second)
    let (checked, direct) = if first_checked {
      (first_elapsed, second_elapsed)
    } else {
      (second_elapsed, first_elapsed)
    }
    println(
      "key-query-pair index=\{pair} checked_first=\{first_checked} checked_ms=\{checked / 1000.0} direct_ms=\{direct / 1000.0} ratio=\{checked / direct}",
    )
  }
  b.bench(
    fn() { b.keep(@ruplog.check_prepared(input, logged)) },
    name="unchanged prepared hinted checker control",
  )
}
