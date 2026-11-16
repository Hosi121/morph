// Value-first replacement requires the active watch literal to be false.

///|
fn replacement_value_first(
  clause : Lits,
  false_watch : Atom,
  other : Atom,
  values : Index[Assignment],
) -> Atom? {
  match clause {
    Nil => None
    Cons(literal, rest) =>
      match index_value(literal, values) {
        False => replacement_value_first(rest, false_watch, other, values)
        True | Unassigned =>
          match same_key(literal, other) {
            true => replacement_value_first(rest, false_watch, other, values)
            false => Some(literal)
          }
      }
  }
}

///|
/// Finish a bucket incrementally, retaining the remaining IDs when a new
/// implied literal is returned. Clause moves remain valid after unassignment.
fn replacement_watch_inspect(
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
            True => replacement_watch_inspect(state, db, check_rest)
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
                    false => watch_decision(db, state.values)
                  }
                  (decision, state)
                }
                Some((literal, pending)) => {
                  let literal = opposite(literal)
                  replacement_watch_inspect(
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
              replacement_watch_inspect(
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
                        True => replacement_watch_inspect(state, db, check_rest)
                        _ =>
                          match
                            replacement_value_first(
                              clause.literals,
                              false_watch,
                              other,
                              state.values,
                            ) {
                            Some(next) =>
                              replacement_watch_inspect(
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
fn run_replacement_mode(
  search : Search,
  budget : @core.Nat,
) -> (Status, Statistics) {
  match budget {
    Zero => (Paused(search), search.statistics)
    Succ(rest) => {
      let (inspection, search) = match search.watch {
        None => (inspect_database(search.database, search.trail), search)
        Some(watched) => {
          let (inspection, watched) = replacement_watch_inspect(
            watched,
            search.database,
            false,
          )
          (inspection, { ..search, watch: Some(watched), })
        }
      }
      match transition(search, inspection) {
        (Paused(next), _) => run_replacement_mode(next, rest)
        terminal => terminal
      }
    }
  }
}

///|
test "value-first replacement preserves first available literal under its false-watch precondition" {
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
      for first in @oracle.array(clause) {
        for other in @oracle.array(clause) {
          if !same_key(first, other) && index_value(first, values) is False {
            assert_eq(
              replacement(clause, first, other, values),
              replacement_value_first(clause, first, other, values),
            )
          }
        }
      }
    }
  }
  for cnf in [pigeonhole(4, 3), @circuit.cnf(miter_formula(4))] {
    for state = start(cnf), count = 0 {
      assert_true(count < 10000)
      assert_watch(state)
      let old = run_measured(state, fuel(1))
      assert_eq(old, run_replacement_mode(state, fuel(1)))
      let (outcome, _) = old
      match outcome {
        Paused(next) => continue next, count + 1
        Unsatisfiable(proof) => {
          assert_true(check_refutation(cnf, proof))
          break
        }
        _ => fail("replacement comparison must be refuted")
      }
    }
  }
}

///|
test "same executable replacement evaluation ABBA comparison" (b : @bench.T) {
  let cnf = @circuit.cnf(miter_formula(64))
  let initial = start(cnf)
  let budget = fuel(200000)
  let old = run_measured(initial, budget)
  assert_eq(old, run_replacement_mode(initial, budget))
  let (outcome, _) = old
  let (input, logged) = match outcome {
    Unsatisfiable(proof) => {
      let input = @ruplog.prepare(cnf)
      let logged = @ruplog.build_prepared(input, proof).unwrap()
      assert_true(@ruplog.check_prepared(input, logged))
      (input, logged)
    }
    _ => fail("replacement miter must be refuted")
  }
  b.bench(
    fn() { b.keep(run_measured(initial, budget)) },
    name="key-first replacement first control",
  )
  b.bench(
    fn() { b.keep(run_replacement_mode(initial, budget)) },
    name="value-first replacement",
  )
  b.bench(
    fn() { b.keep(run_replacement_mode(initial, budget)) },
    name="value-first replacement repeated control",
  )
  b.bench(
    fn() { b.keep(run_measured(initial, budget)) },
    name="key-first replacement repeated control",
  )
  b.bench(
    fn() { b.keep(@ruplog.check_prepared(input, logged)) },
    name="unchanged prepared hinted checker control",
  )
}
