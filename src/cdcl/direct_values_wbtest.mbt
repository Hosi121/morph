// Full key-verifying watch path frozen at 6b40942 for same-executable comparison.

///|
fn verified_index_value(literal : Atom, values : Index[Assignment]) -> Value {
  match index_get(values, @binary.bits(literal.key)) {
    None => Unassigned
    Some(entry) =>
      match same(entry.literal, literal) {
        true => True
        false => False
      }
  }
}

///|
fn verified_indexed_clause(
  clause : Lits,
  values : Index[Assignment],
) -> ClauseState {
  match clause {
    Nil => Conflict
    Cons(literal, rest) =>
      match verified_index_value(literal, values) {
        True => Satisfied
        False => verified_indexed_clause(rest, values)
        Unassigned =>
          match verified_indexed_clause(rest, values) {
            Satisfied => Satisfied
            Conflict => Unit(literal)
            Unit(_) | Open(_) => Open(literal)
          }
      }
  }
}

///|
fn verified_watch_decision_checked(
  db : Database,
  values : Index[Assignment],
) -> Inspection {
  fn visit(db : Database, candidate : Atom?) -> Inspection {
    match db {
      Nil =>
        match candidate {
          None => Complete
          Some(literal) => Decide(literal)
        }
      Cons(clause, rest) =>
        match verified_indexed_clause(clause, values) {
          Satisfied => visit(rest, candidate)
          Open(literal) =>
            match candidate {
              None => visit(rest, Some(literal))
              Some(_) => visit(rest, candidate)
            }
          Unit(_) | Conflict => Broken
        }
    }
  }
  visit(db, None)
}

///|
/// At quiescence the watch invariant excludes pending units and conflicts.
/// Keep the full database diagnostic in verified_watch_decision_checked for tests.
fn verified_watch_decision(
  db : Database,
  values : Index[Assignment],
) -> Inspection {
  match db {
    Nil => Complete
    Cons(clause, rest) =>
      match verified_indexed_clause(clause, values) {
        Satisfied => verified_watch_decision(rest, values)
        Open(literal) => Decide(literal)
        Unit(_) | Conflict => Broken
      }
  }
}

///|
fn verified_replacement(
  clause : Lits,
  false_watch : Atom,
  other : Atom,
  values : Index[Assignment],
) -> Atom? {
  match clause {
    Nil => None
    Cons(literal, rest) =>
      match same_key(literal, false_watch) || same_key(literal, other) {
        true => verified_replacement(rest, false_watch, other, values)
        false =>
          match verified_index_value(literal, values) {
            False => verified_replacement(rest, false_watch, other, values)
            _ => Some(literal)
          }
      }
  }
}

///|
/// Finish a bucket incrementally, retaining the remaining IDs when a new
/// implied literal is returned. Clause moves remain valid after unassignment.
fn verified_watch_inspect_using(
  state : WatchState,
  db : Database,
  check_rest : Bool,
) -> (Inspection, WatchState) {
  match state.empty {
    true => (Contradiction(Nil), state)
    false =>
      match state.units {
        Cons((literal, reason), rest) => {
          let state = { ..state, units: rest, }
          match verified_index_value(literal, state.values) {
            True => verified_watch_inspect_using(state, db, check_rest)
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
                    true => verified_watch_decision_checked(db, state.values)
                    false => verified_watch_decision(db, state.values)
                  }
                  (decision, state)
                }
                Some((literal, pending)) => {
                  let literal = opposite(literal)
                  verified_watch_inspect_using(
                    {
                      ..state,
                      pending,
                      active: Some((literal, bucket(state, literal))),
                    },
                    db,
                    check_rest,
                  )
                }
              }
            Some((_, Nil)) =>
              verified_watch_inspect_using(
                { ..state, active: None, },
                db,
                check_rest,
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
                      match verified_index_value(other, state.values) {
                        True =>
                          verified_watch_inspect_using(state, db, check_rest)
                        _ =>
                          match
                            verified_replacement(
                              clause.literals,
                              false_watch,
                              other,
                              state.values,
                            ) {
                            Some(next) =>
                              verified_watch_inspect_using(
                                watch_move(
                                  state, clause, false_watch, next, other,
                                ),
                                db,
                                check_rest,
                              )
                            None =>
                              match verified_index_value(other, state.values) {
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
fn run_verified_mode(
  search : Search,
  budget : @core.Nat,
) -> (Status, Statistics) {
  match budget {
    Zero => (Paused(search), search.statistics)
    Succ(rest) => {
      let (inspection, search) = match search.watch {
        None => (inspect_database(search.database, search.trail), search)
        Some(watched) => {
          let (inspection, watched) = verified_watch_inspect_using(
            watched,
            search.database,
            false,
          )
          (inspection, { ..search, watch: Some(watched), })
        }
      }
      match transition(search, inspection) {
        (Paused(next), _) => run_verified_mode(next, rest)
        terminal => terminal
      }
    }
  }
}

///|
test "direct polarity values agree for sparse prefix keys and every paused state" {
  let labels = [0, 1, 2, 3, 255, 256, 257, 65535]
  let queries = labels.map(fn(label) {
    let source = @oracle.nat(label)
    (
      atom({ variable: source, positive: false, }),
      atom({ variable: source, positive: true, }),
    )
  })
  for mask in 0..<256 {
    let mut values = Empty
    for index in 0..<labels.length() {
      if mask / (1 << index) % 2 == 1 {
        let (negative, positive) = queries[index]
        let literal = if index % 2 == 0 { positive } else { negative }
        values = index_put(values, @binary.bits(literal.key), {
          literal,
          level: Zero,
          reason: None,
        })
      }
    }
    for (negative, positive) in queries {
      for query in [negative, positive] {
        match
          (verified_index_value(query, values), index_value(query, values)) {
          (True, True) | (False, False) | (Unassigned, Unassigned) => ()
          _ =>
            fail("trie value lookup must preserve both polarities and absence")
        }
      }
    }
  }
  for cnf in [pigeonhole(4, 3), @circuit.cnf(miter_formula(4))] {
    for initial in [start(cnf), start_scanning(cnf)] {
      for state = initial, count = 0 {
        assert_true(count < 10000)
        let old = run_verified_mode(state, fuel(1))
        assert_eq(old, run_measured(state, fuel(1)))
        let (outcome, _) = old
        match outcome {
          Paused(next) => continue next, count + 1
          Unsatisfiable(proof) => {
            assert_true(check_refutation(cnf, proof))
            break
          }
          _ => fail("direct value comparison must be refuted")
        }
      }
    }
  }
}

///|
test "same executable global direct polarity lookup ABBA comparison" (
  b : @bench.T,
) {
  let cnf = @circuit.cnf(miter_formula(64))
  let initial = start(cnf)
  let budget = fuel(200000)
  let old = run_verified_mode(initial, budget)
  assert_eq(old, run_measured(initial, budget))
  let (outcome, _) = old
  let (input, logged) = match outcome {
    Unsatisfiable(proof) => {
      let input = @ruplog.prepare(cnf)
      let logged = @ruplog.build_prepared(input, proof).unwrap()
      assert_true(@ruplog.check_prepared(input, logged))
      (input, logged)
    }
    _ => fail("global direct value miter must be refuted")
  }
  b.bench(
    fn() { b.keep(run_verified_mode(initial, budget)) },
    name="verified values all watch paths first control",
  )
  b.bench(
    fn() { b.keep(run_measured(initial, budget)) },
    name="direct polarity all watch paths",
  )
  b.bench(
    fn() { b.keep(run_measured(initial, budget)) },
    name="direct polarity all watch paths repeated control",
  )
  b.bench(
    fn() { b.keep(run_verified_mode(initial, budget)) },
    name="verified values all watch paths repeated control",
  )
  b.bench(
    fn() { b.keep(@ruplog.check_prepared(input, logged)) },
    name="unchanged prepared hinted checker control",
  )
}

///|
fn direct_value_query(
  cnf : @sat.Cnf,
  budget : @core.Nat,
  direct : Bool,
) -> Bool {
  let (outcome, _) = if direct {
    run_measured(start(cnf), budget)
  } else {
    run_verified_mode(start(cnf), budget)
  }
  match outcome {
    Satisfiable(model) => @sat.check_model(cnf, model)
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
test "paired complete queries compare all direct watch values" (b : @bench.T) {
  let cnf = @circuit.cnf(miter_formula(64))
  let budget = fuel(200000)
  let initial = start(cnf)
  let old = run_verified_mode(initial, budget)
  assert_eq(old, run_measured(initial, budget))
  let (outcome, _) = old
  let (input, logged) = match outcome {
    Unsatisfiable(proof) => {
      let input = @ruplog.prepare(cnf)
      let logged = @ruplog.build_prepared(input, proof).unwrap()
      assert_true(@ruplog.check_prepared(input, logged))
      (input, logged)
    }
    _ => fail("global direct value miter must be refuted")
  }
  for pair in 0..<20 {
    let verified_first = pair % 2 == 0
    let started = @bench.monotonic_clock_start()
    let first = direct_value_query(cnf, budget, !verified_first)
    let first_elapsed = @bench.monotonic_clock_end(started)
    let started = @bench.monotonic_clock_start()
    let second = direct_value_query(cnf, budget, verified_first)
    let second_elapsed = @bench.monotonic_clock_end(started)
    b.keep(first)
    b.keep(second)
    assert_true(first)
    assert_true(second)
    let (verified, direct) = if verified_first {
      (first_elapsed, second_elapsed)
    } else {
      (second_elapsed, first_elapsed)
    }
    println(
      "all-values-pair index=\{pair} verified_first=\{verified_first} verified_ms=\{verified/1000.0} direct_ms=\{direct/1000.0} ratio=\{verified/direct}",
    )
  }
  b.bench(
    fn() { b.keep(@ruplog.check_prepared(input, logged)) },
    name="unchanged prepared hinted checker control",
  )
}

///|
fn direct_value_batch(
  formulas : Array[@sat.Cnf],
  budget : @core.Nat,
  direct : Bool,
) -> Bool {
  for cnf in formulas {
    if !direct_value_query(cnf, budget, direct) {
      return false
    }
  }
  true
}

///|
test "global direct values preserve small complete queries" (b : @bench.T) {
  let budget = fuel(200000)
  let pigeon = pigeonhole(6, 5)
  assert_eq(
    run_verified_mode(start(pigeon), budget),
    run_measured(start(pigeon), budget),
  )
  let cohort = []
  let mut seed = 31415
  for _ in 0..<1000 {
    let clauses = []
    for _ in 0..<24 {
      let values = []
      for _ in 0..<3 {
        seed = (seed * 61 + 17) % 65521
        let variable = seed % 6
        seed = (seed * 61 + 17) % 65521
        values.push(lit(variable, seed % 2 == 1))
      }
      clauses.push(values)
    }
    let formula = cnf(clauses)
    cohort.push(formula)
    assert_eq(
      run_verified_mode(start(formula), budget),
      run_measured(start(formula), budget),
    )
  }
  assert_true(direct_value_query(pigeon, budget, false))
  assert_true(direct_value_query(pigeon, budget, true))
  assert_true(direct_value_batch(cohort, budget, false))
  assert_true(direct_value_batch(cohort, budget, true))
  b.bench(
    fn() { b.keep(direct_value_query(pigeon, budget, false)) },
    name="pigeonhole key-verifying values",
  )
  b.bench(
    fn() { b.keep(direct_value_query(pigeon, budget, true)) },
    name="pigeonhole direct polarity values",
  )
  b.bench(
    fn() { b.keep(direct_value_batch(cohort, budget, false)) },
    name="thousand queries key-verifying values",
  )
  b.bench(
    fn() { b.keep(direct_value_batch(cohort, budget, true)) },
    name="thousand queries direct polarity values",
  )
}
