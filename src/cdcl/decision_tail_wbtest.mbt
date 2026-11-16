// Tail decision evaluator retained after no native search benefit.

///|
fn tail_clause_pending(
  clause : Lits,
  values : Index[Assignment],
  pending : ClauseState,
) -> ClauseState {
  match clause {
    Nil => pending
    Cons(literal, rest) =>
      match verified_index_value(literal, values) {
        True => Satisfied
        False => tail_clause_pending(rest, values, pending)
        Unassigned =>
          match pending {
            Satisfied => Satisfied
            Conflict => tail_clause_pending(rest, values, Unit(literal))
            Unit(first) => tail_clause_pending(rest, values, Open(first))
            Open(_) => tail_clause_pending(rest, values, pending)
          }
      }
  }
}

///|
fn tail_clause(clause : Lits, values : Index[Assignment]) -> ClauseState {
  tail_clause_pending(clause, values, Conflict)
}

///|
/// Finish a bucket incrementally, retaining the remaining IDs when a new
/// implied literal is returned. Clause moves remain valid after unassignment.
fn tail_watch_inspect_using(
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
          match index_value(literal, state.values) {
            True => tail_watch_inspect_using(state, db, check_rest)
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
                    false => tail_decision(db, state.values)
                  }
                  (decision, state)
                }
                Some((literal, pending)) => {
                  let literal = opposite(literal)
                  tail_watch_inspect_using(
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
              tail_watch_inspect_using(
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
                      match index_value(other, state.values) {
                        True => tail_watch_inspect_using(state, db, check_rest)
                        _ =>
                          match
                            replacement(
                              clause.literals,
                              false_watch,
                              other,
                              state.values,
                            ) {
                            Some(next) =>
                              tail_watch_inspect_using(
                                watch_move(
                                  state, clause, false_watch, next, other,
                                ),
                                db,
                                check_rest,
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
fn tail_decision(db : Database, values : Index[Assignment]) -> Inspection {
  match db {
    Nil => Complete
    Cons(clause, rest) =>
      match tail_clause(clause, values) {
        Satisfied => tail_decision(rest, values)
        Open(literal) => Decide(literal)
        Unit(_) | Conflict => Broken
      }
  }
}

///|
fn run_tail_mode(search : Search, budget : @core.Nat) -> (Status, Statistics) {
  match budget {
    Zero => (Paused(search), search.statistics)
    Succ(rest) => {
      let (inspection, search) = match search.watch {
        None => (inspect_database(search.database, search.trail), search)
        Some(watched) => {
          let (inspection, watched) = tail_watch_inspect_using(
            watched,
            search.database,
            false,
          )
          (inspection, { ..search, watch: Some(watched), })
        }
      }
      match transition(search, inspection) {
        (Paused(next), _) => run_tail_mode(next, rest)
        terminal => terminal
      }
    }
  }
}

///|
test "tail decision evaluator retains first unassigned literal and complete clause status" {
  for encoded in 0..<27 {
    let clause = normalize(ternary_clause(encoded, 3)).unwrap()
    for assignment in 0..<27 {
      let mut values = Empty
      let mut digits = assignment
      for variable in 0..<3 {
        let digit = digits % 3
        digits /= 3
        if digit != 0 {
          let literal = atom(lit(variable, digit == 1))
          values = index_put(values, @binary.bits(literal.key), {
            literal,
            level: Zero,
            reason: None,
          })
        }
      }
      match
        (
          indexed_clause_using(clause, values, true),
          tail_clause(clause, values),
        ) {
        (Satisfied, Satisfied) | (Conflict, Conflict) => ()
        (Unit(old), Unit(next)) => assert_eq(old, next)
        (Open(old), Open(next)) => assert_eq(old, next)
        _ => fail("decision evaluator must preserve the complete clause state")
      }
    }
  }
  let atoms = []
  let mut source = @core.Zero
  for variable in 0..<20000 {
    atoms.push(Atom::{ key: @oracle.binary(variable), source, positive: true, })
    source = @core.Succ(source)
  }
  let clause = @oracle.chain(atoms)
  match tail_clause(clause, Empty) {
    Open(first) => assert_eq(@oracle.int_of_binary(first.key), 0)
    _ => fail("long open clause must retain its first literal")
  }
}

///|
test "tail decision prototype preserves every paused state" {
  for cnf in [pigeonhole(4, 3), @circuit.cnf(miter_formula(4))] {
    for initial in [start(cnf), start_scanning(cnf)] {
      for state = initial, count = 0 {
        assert_true(count < 10000)
        let old = run_measured(state, fuel(1))
        assert_eq(old, run_tail_mode(state, fuel(1)))
        let (outcome, _) = old
        match outcome {
          Paused(next) => continue next, count + 1
          Unsatisfiable(proof) => {
            assert_true(check_refutation(cnf, proof))
            break
          }
          _ => fail("tail decision comparison must be refuted")
        }
      }
    }
  }
}

///|
test "same executable recursive and tail decision evaluation" (b : @bench.T) {
  let cnf = @circuit.cnf(miter_formula(64))
  let initial = start(cnf)
  let budget = fuel(200000)
  let old = run_key_mode(initial, budget, true)
  assert_eq(old, run_tail_mode(initial, budget))
  let (outcome, _) = old
  let (input, logged) = match outcome {
    Unsatisfiable(proof) => {
      let input = @ruplog.prepare(cnf)
      let logged = @ruplog.build_prepared(input, proof).unwrap()
      assert_true(@ruplog.check_prepared(input, logged))
      (input, logged)
    }
    _ => fail("decision-tail miter must be refuted")
  }
  b.bench(
    fn() { b.keep(run_key_mode(initial, budget, true)) },
    name="recursive decision evaluator first control",
  )
  b.bench(
    fn() { b.keep(run_tail_mode(initial, budget)) },
    name="tail decision evaluator",
  )
  b.bench(
    fn() { b.keep(run_tail_mode(initial, budget)) },
    name="tail decision evaluator repeated control",
  )
  b.bench(
    fn() { b.keep(run_key_mode(initial, budget, true)) },
    name="recursive decision evaluator repeated control",
  )
  b.bench(
    fn() { b.keep(@ruplog.check_prepared(input, logged)) },
    name="unchanged prepared hinted checker control",
  )
}
