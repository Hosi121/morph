///|
fn run_analysis_mode(
  search : Search,
  budget : @core.Nat,
  indexed : Bool,
  skip_recount : Bool,
) -> (Status, Statistics) {
  match budget {
    Zero => (Paused(search), search.statistics)
    Succ(rest) => {
      let (inspection, search) = match search.watch {
        None => (inspect_database(search.database, search.trail), search)
        Some(watched) => {
          let (inspection, watched) = watch_inspect(watched, search.database)
          (inspection, { ..search, watch: Some(watched), })
        }
      }
      match transition_using(search, inspection, indexed, skip_recount) {
        (Paused(next), _) =>
          run_analysis_mode(next, rest, indexed, skip_recount)
        terminal => terminal
      }
    }
  }
}

///|
fn count_trail_lookup(trail : Trail, literal : Atom) -> (Assignment?, Int32) {
  fn visit(trail : Trail, count : Int32) -> (Assignment?, Int32) {
    match trail {
      Nil => (None, count)
      Cons(entry, rest) =>
        match same_key(entry.literal, literal) {
          true => (Some(entry), count + 1)
          false => visit(rest, count + 1)
        }
    }
  }
  visit(trail, 0)
}

///|
fn count_index_lookup(
  values : Index[Assignment],
  key : @core.Chain[Bool],
) -> (Assignment?, Int32) {
  fn visit(
    values : Index[Assignment],
    key : @core.Chain[Bool],
    count : Int32,
  ) -> (Assignment?, Int32) {
    match (values, key) {
      (Empty, _) => (None, count)
      (Branch(value, _, _), Nil) => (value, count + 1)
      (Branch(_, left, _), Cons(false, rest)) => visit(left, rest, count + 1)
      (Branch(_, _, right), Cons(true, rest)) => visit(right, rest, count + 1)
    }
  }
  visit(values, key, 0)
}

///|
fn count_analysis_work(
  initial : Search,
  skip_recount : Bool,
) -> (Int32, Int32, Int32) raise {
  let mut queries = 0
  let mut trail_entries = 0
  let mut trie_nodes = 0
  let mut inconsistent = false
  for state = initial, remaining = 200000; remaining > 0; {
    let watched = state.watch.unwrap()
    let (inspection, watched) = watch_inspect(watched, state.database)
    match inspection {
      Contradiction(conflict) => {
        let lookup = fn(literal : Atom) {
          let (linear, entries) = count_trail_lookup(state.trail, literal)
          let (indexed, nodes) = count_index_lookup(
            watched.values,
            @binary.bits(literal.key),
          )
          queries += 1
          trail_entries += entries
          trie_nodes += nodes
          if linear != indexed {
            inconsistent = true
          }
          indexed
        }
        let level = highest_level(conflict, lookup)
        match level {
          Zero => ()
          Succ(_) => {
            let candidate = match skip_recount {
              true => analyze_pivot_count(conflict, state.trail, lookup, level)
              false => analyze(conflict, state.trail, lookup, level)
            }
            let clause = candidate.unwrap()
            let literal = asserting(clause, lookup, level).unwrap()
            ignore(backjump_level(clause, lookup, literal))
          }
        }
      }
      _ => ()
    }
    let (outcome, _) = transition(
      { ..state, watch: Some(watched), },
      inspection,
    )
    match outcome {
      Paused(next) => continue next, remaining - 1
      Unsatisfiable(_) => break
      _ => fail("counted miter must be refuted")
    }
  } nobreak {
    fail("analysis counter exhausted fuel")
  }
  assert_false(inconsistent)
  (queries, trail_entries, trie_nodes)
}

///|
fn compare_analysis(width : Int32, b : @bench.T) -> Unit raise {
  let cnf = @circuit.cnf(miter_formula(width))
  let initial = start(cnf)
  let budget = fuel(200000)
  let baseline = run_analysis_mode(initial, budget, false, false)
  assert_eq(baseline, run_analysis_mode(initial, budget, true, false))
  assert_eq(baseline, run_analysis_mode(initial, budget, false, true))
  assert_eq(baseline, run_analysis_mode(initial, budget, true, true))
  assert_eq(baseline, run_measured(initial, budget))
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
  let (old_queries, old_entries, old_nodes) = count_analysis_work(
    initial, false,
  )
  let (new_queries, new_entries, new_nodes) = count_analysis_work(initial, true)
  println(
    "analysis-work width=\{width} repeated-count queries=\{old_queries} trail-entries=\{old_entries} trie-nodes=\{old_nodes}; skip-recount queries=\{new_queries} trail-entries=\{new_entries} trie-nodes=\{new_nodes}",
  )
  b.bench(
    fn() { b.keep(run_analysis_mode(initial, budget, false, false)) },
    name="linear lookup and repeated count",
  )
  b.bench(
    fn() { b.keep(run_analysis_mode(initial, budget, true, false)) },
    name="indexed lookup and repeated count",
  )
  b.bench(
    fn() { b.keep(run_analysis_mode(initial, budget, false, true)) },
    name="linear lookup with pivot-only count",
  )
  b.bench(
    fn() { b.keep(run_analysis_mode(initial, budget, true, true)) },
    name="indexed lookup with pivot-only count",
  )
  b.bench(
    fn() { b.keep(@ruplog.check_prepared(input, logged)) },
    name="unchanged prepared hinted checker control",
  )
}

///|
test "same executable sixteen-bit conflict analysis comparison" (b : @bench.T) {
  compare_analysis(16, b)
}

///|
test "same executable sixty-four-bit conflict analysis comparison" (
  b : @bench.T,
) {
  compare_analysis(64, b)
}

///|
test "all conflict strategies preserve every paused state and final statistics" {
  for formula in [pigeonhole(4, 3), @circuit.cnf(miter_formula(4))] {
    for state = start(formula), count = 0 {
      assert_true(count < 10000)
      let expected = run_analysis_mode(state, fuel(1), false, false)
      assert_eq(expected, run_analysis_mode(state, fuel(1), true, false))
      assert_eq(expected, run_analysis_mode(state, fuel(1), false, true))
      assert_eq(expected, run_analysis_mode(state, fuel(1), true, true))
      assert_eq(expected, run_measured(state, fuel(1)))
      let (outcome, _) = expected
      match outcome {
        Paused(next) => continue next, count + 1
        Unsatisfiable(proof) => {
          assert_true(check_refutation(formula, proof))
          break
        }
        _ => fail("transition comparison must end in UNSAT")
      }
    }
  }
}
