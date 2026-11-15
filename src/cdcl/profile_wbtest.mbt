///|
// Test-only stage clocks. No timing or counters enter the pure solver kernel.
fn sample_phases(
  initial : Search,
) -> (Status, Array[Int32], Array[Double], Array[Double]) raise {
  let counts = Array::make(5, 0)
  let inspection_time = Array::make(5, 0.0)
  let transition_time = Array::make(5, 0.0)
  for state = initial, remaining = 200000; remaining > 0; {
    let watched = match state.watch {
      None => fail("phase sampler requires the watched engine")
      Some(watched) => watched
    }
    let started = @bench.monotonic_clock_start()
    let (inspection, watched) = watch_inspect(watched, state.database)
    let elapsed_inspection = @bench.monotonic_clock_end(started)
    let kind = match inspection {
      Propagate(_, _) => 0
      Decide(_) => 1
      Contradiction(_) => 2
      Complete => 3
      Broken => 4
    }
    let started = @bench.monotonic_clock_start()
    let (outcome, _) = transition(
      { ..state, watch: Some(watched), },
      inspection,
    )
    let elapsed_transition = @bench.monotonic_clock_end(started)
    counts[kind] += 1
    inspection_time[kind] += elapsed_inspection
    transition_time[kind] += elapsed_transition
    match outcome {
      Paused(next) => continue next, remaining - 1
      terminal => break (terminal, counts, inspection_time, transition_time)
    }
  } nobreak {
    fail("phase sampler exhausted its declared transition budget")
  }
}

///|
fn measure_phases(width : Int32, b : @bench.T) -> Unit raise {
  let encoding = miter_formula(width)
  let cnf = @circuit.cnf(encoding)
  let initial = start(cnf)
  let budget = fuel(200000)
  let (outcome, counts, inspection_time, transition_time) = sample_phases(
    initial,
  )
  let (input, logged) = match outcome {
    Unsatisfiable(proof) => {
      let input = @ruplog.prepare(cnf)
      let logged = @ruplog.build_prepared(input, proof).unwrap()
      assert_true(@ruplog.check_prepared(input, logged))
      (input, logged)
    }
    _ => fail("profiled equivalent miter must be refuted")
  }
  let names = ["propagate", "decide", "conflict", "complete", "broken"]
  for kind in 0..<names.length() {
    println(
      "phase width=\{width} kind=\{names[kind]} count=\{counts[kind]} inspection_ms=\{inspection_time[kind] / 1000.0} transition_ms=\{transition_time[kind] / 1000.0}",
    )
  }
  b.bench(
    fn() { b.keep(run(initial, budget)) },
    name="uninstrumented search without startup",
  )
  b.bench(
    fn() { b.keep(@ruplog.check_prepared(input, logged)) },
    name="unchanged prepared hinted checker control",
  )
}

///|
test "phase profile of sixteen-bit watched miter" (b : @bench.T) {
  measure_phases(16, b)
}

///|
test "phase profile of sixty-four-bit watched miter" (b : @bench.T) {
  measure_phases(64, b)
}

///|
fn run_quiescence_mode(
  search : Search,
  budget : @core.Nat,
  check_rest : Bool,
) -> Status {
  match budget {
    Zero => Paused(search)
    Succ(rest) =>
      match search.watch {
        None => run(search, budget)
        Some(watched) => {
          let (inspection, watched) = watch_inspect_using(
            watched,
            search.database,
            check_rest,
          )
          let (outcome, _) = transition(
            { ..search, watch: Some(watched), },
            inspection,
          )
          match outcome {
            Paused(next) => run_quiescence_mode(next, rest, check_rest)
            terminal => terminal
          }
        }
      }
  }
}

///|
fn compare_quiescence(width : Int32, b : @bench.T) -> Unit raise {
  let cnf = @circuit.cnf(miter_formula(width))
  let initial = start(cnf)
  let budget = fuel(200000)
  let checked = run_quiescence_mode(initial, budget, true)
  let fast = run_quiescence_mode(initial, budget, false)
  assert_eq(checked, fast)
  let (counted, decisions, full_clauses, prefix_clauses) = count_decision_work(
    initial,
  )
  assert_eq(counted, fast)
  println(
    "decision-work width=\{width}, decisions=\{decisions}, full diagnostic clause inspections=\{full_clauses}, first-open clause inspections=\{prefix_clauses}",
  )
  match fast {
    Unsatisfiable(proof) =>
      assert_true(@ruplog.check(cnf, @ruplog.build(cnf, proof).unwrap()))
    _ => fail("equivalent miter must be refuted")
  }
  b.bench(
    fn() { b.keep(run_quiescence_mode(initial, budget, true)) },
    name="full quiescence diagnostic",
  )
  b.bench(
    fn() { b.keep(run_quiescence_mode(initial, budget, false)) },
    name="first open clause after watch quiescence",
  )
}

///|
fn first_open_work(db : Database, values : Index[Assignment]) -> Int32 {
  fn visit(db : Database, count : Int32) -> Int32 {
    match db {
      Nil => count
      Cons(clause, rest) =>
        match indexed_clause(clause, values) {
          Satisfied => visit(rest, count + 1)
          _ => count + 1
        }
    }
  }
  visit(db, 0)
}

///|
fn count_decision_work(initial : Search) -> (Status, Int32, Int32, Int32) raise {
  let original = @oracle.array(initial.database).length()
  for state = initial, remaining = 200000, decisions = 0, full = 0, prefix = 0; remaining >
     0; {
    let watched = match state.watch {
      None => fail("decision work counter requires watched search")
      Some(watched) => watched
    }
    let (inspection, watched) = watch_inspect(watched, state.database)
    let (decisions, full, prefix) = match inspection {
      Decide(_) =>
        (
          decisions + 1,
          full + original + @oracle.int_of_nat(state.statistics.learned),
          prefix + first_open_work(state.database, watched.values),
        )
      _ => (decisions, full, prefix)
    }
    let (outcome, _) = transition(
      { ..state, watch: Some(watched), },
      inspection,
    )
    match outcome {
      Paused(next) => continue next, remaining - 1, decisions, full, prefix
      terminal => break (terminal, decisions, full, prefix)
    }
  } nobreak {
    fail("decision work counter exhausted fuel")
  }
}

///|
test "same executable sixteen-bit quiescence comparison" (b : @bench.T) {
  compare_quiescence(16, b)
}

///|
test "same executable sixty-four-bit quiescence comparison" (b : @bench.T) {
  compare_quiescence(64, b)
}

///|
test "fast and diagnostic decisions preserve every resumable transition" {
  for state = start(pigeonhole(4, 3)), count = 0 {
    assert_true(count < 10000)
    let fast = run_quiescence_mode(state, fuel(1), false)
    let checked = run_quiescence_mode(state, fuel(1), true)
    assert_eq(fast, checked)
    assert_eq(fast, run(state, fuel(1)))
    match fast {
      Paused(next) => continue next, count + 1
      Unsatisfiable(proof) => {
        assert_true(check_refutation(pigeonhole(4, 3), proof))
        break
      }
      _ => fail("pigeonhole transition comparison must end in UNSAT")
    }
  }
}
