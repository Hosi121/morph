///|
fn run_maintenance_mode(
  search : Search,
  budget : @core.Nat,
  mode : Maintenance,
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
      match transition_maintaining(search, inspection, true, false, mode) {
        (Paused(next), _) => run_maintenance_mode(next, rest, mode)
        terminal => terminal
      }
    }
  }
}

///|
test "same executable sixty-four-bit conflict maintenance comparison" (
  b : @bench.T,
) {
  let cnf = @circuit.cnf(miter_formula(64))
  let initial = start(cnf)
  let budget = fuel(200000)
  let baseline = run_maintenance_mode(initial, budget, FlatRebuild)
  assert_eq(baseline, run_maintenance_mode(initial, budget, SharedSuffix))
  assert_eq(baseline, run_maintenance_mode(initial, budget, SharedValues))
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
  b.bench(
    fn() { b.keep(run_maintenance_mode(initial, budget, FlatRebuild)) },
    name="filter trail and rebuild assignments",
  )
  b.bench(
    fn() { b.keep(run_maintenance_mode(initial, budget, SharedSuffix)) },
    name="share trail suffix and rebuild assignments",
  )
  b.bench(
    fn() { b.keep(run_maintenance_mode(initial, budget, SharedValues)) },
    name="share trail suffix and assignment trie",
  )
  b.bench(
    fn() { b.keep(@ruplog.check_prepared(input, logged)) },
    name="unchanged prepared hinted checker control",
  )
}

///|
test "maintenance alternatives preserve every paused state including canonical value indices" {
  for cnf in [pigeonhole(4, 3), @circuit.cnf(miter_formula(4))] {
    for initial in [start(cnf), start_scanning(cnf)] {
      for state = initial, count = 0 {
        assert_true(count < 10000)
        let baseline = run_maintenance_mode(state, fuel(1), FlatRebuild)
        assert_eq(baseline, run_maintenance_mode(state, fuel(1), SharedSuffix))
        assert_eq(baseline, run_maintenance_mode(state, fuel(1), SharedValues))
        assert_eq(baseline, run_measured(state, fuel(1)))
        let (outcome, _) = baseline
        match outcome {
          Paused(next) => continue next, count + 1
          Unsatisfiable(proof) => {
            assert_true(check_refutation(cnf, proof))
            break
          }
          _ => fail("maintenance comparison must end in UNSAT")
        }
      }
    }
  }
}

///|
test "trie removal equals fresh construction for every subset and preserves sparse prefix keys" {
  let powers = [1, 2, 4, 8, 16, 32, 64, 128]
  for mask in 0..<256 {
    let mut original : Index[@binary.Binary] = Empty
    for variable in 0..<8 {
      if mask / powers[variable] % 2 == 1 {
        let key = @oracle.binary(variable)
        original = index_put(original, @binary.bits(key), key)
      }
    }
    for removed in 0..<9 {
      let mut rebuilt : Index[@binary.Binary] = Empty
      for variable in 0..<8 {
        if variable != removed && mask / powers[variable] % 2 == 1 {
          let key = @oracle.binary(variable)
          rebuilt = index_put(rebuilt, @binary.bits(key), key)
        }
      }
      assert_eq(
        index_remove(original, @binary.bits(@oracle.binary(removed))),
        rebuilt,
      )
    }
  }
  let labels = [0, 1, 2, 3, 255, 256, 257, 65535]
  let mut original : Index[@binary.Binary] = Empty
  for label in labels {
    let key = @oracle.binary(label)
    original = index_put(original, @binary.bits(key), key)
  }
  for removed in 0..<labels.length() {
    original = index_remove(
      original,
      @binary.bits(@oracle.binary(labels[removed])),
    )
    let mut rebuilt : Index[@binary.Binary] = Empty
    for remaining in (removed + 1)..<labels.length() {
      let key = @oracle.binary(labels[remaining])
      rebuilt = index_put(rebuilt, @binary.bits(key), key)
    }
    assert_eq(original, rebuilt)
  }
  assert_eq(original, Empty)
}

///|
test "suffix backjump agrees with filtering on ordered trails at every cutoff" {
  for offset in [0, 16] {
    let trail : Trail = @oracle.chain(
      [
        for index in 0..<16 => {
          Assignment::{
            literal: atom(lit(index, true)),
            level: @oracle.nat(offset + 7 - index / 2),
            reason: None,
          }
        }
      ],
    )
    for cutoff in 0..<25 {
      assert_eq(
        backjump_shared(trail, @oracle.nat(cutoff)),
        backjump(trail, @oracle.nat(cutoff)),
      )
    }
  }
}

///|
fn maintenance_query(
  cnf : @sat.Cnf,
  budget : @core.Nat,
  mode : Maintenance,
) -> Bool {
  let (outcome, _) = run_maintenance_mode(start(cnf), budget, mode)
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
test "paired complete sixty-four-bit queries with alternating maintenance order" (
  b : @bench.T,
) {
  let cnf = @circuit.cnf(miter_formula(64))
  let initial = start(cnf)
  let budget = fuel(200000)
  let baseline = run_maintenance_mode(initial, budget, FlatRebuild)
  assert_eq(baseline, run_maintenance_mode(initial, budget, SharedValues))
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
    let rebuild_first = pair % 2 == 0
    let first_mode = if rebuild_first { FlatRebuild } else { SharedValues }
    let second_mode = if rebuild_first { SharedValues } else { FlatRebuild }
    let started = @bench.monotonic_clock_start()
    let first = maintenance_query(cnf, budget, first_mode)
    let first_elapsed = @bench.monotonic_clock_end(started)
    let started = @bench.monotonic_clock_start()
    let second = maintenance_query(cnf, budget, second_mode)
    let second_elapsed = @bench.monotonic_clock_end(started)
    b.keep(first)
    b.keep(second)
    assert_true(first)
    assert_true(second)
    let (rebuild, shared) = if rebuild_first {
      (first_elapsed, second_elapsed)
    } else {
      (second_elapsed, first_elapsed)
    }
    println(
      "maintenance-pair index=\{pair} rebuild_first=\{rebuild_first} rebuild_ms=\{rebuild/1000.0} shared_ms=\{shared/1000.0} ratio=\{rebuild/shared}",
    )
  }
  b.bench(
    fn() { b.keep(@ruplog.check_prepared(input, logged)) },
    name="unchanged prepared hinted checker control",
  )
}

///|
fn maintenance_batch(
  formulas : Array[@sat.Cnf],
  budget : @core.Nat,
  mode : Maintenance,
) -> Bool {
  for formula in formulas {
    if !maintenance_query(formula, budget, mode) {
      return false
    }
  }
  true
}

///|
test "pigeonhole and deterministic three-SAT complete queries under both maintenance modes" (
  b : @bench.T,
) {
  let pigeon = pigeonhole(6, 5)
  let budget = fuel(200000)
  let initial = start(pigeon)
  assert_eq(
    run_maintenance_mode(initial, budget, FlatRebuild),
    run_maintenance_mode(initial, budget, SharedValues),
  )
  assert_true(maintenance_query(pigeon, budget, FlatRebuild))
  assert_true(maintenance_query(pigeon, budget, SharedValues))
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
    let initial = start(formula)
    assert_eq(
      run_maintenance_mode(initial, budget, FlatRebuild),
      run_maintenance_mode(initial, budget, SharedValues),
    )
  }
  assert_true(maintenance_batch(cohort, budget, FlatRebuild))
  assert_true(maintenance_batch(cohort, budget, SharedValues))
  b.bench(
    fn() { b.keep(maintenance_query(pigeon, budget, FlatRebuild)) },
    name="pigeonhole six into five rebuild query",
  )
  b.bench(
    fn() { b.keep(maintenance_query(pigeon, budget, SharedValues)) },
    name="pigeonhole six into five shared query",
  )
  b.bench(
    fn() { b.keep(maintenance_batch(cohort, budget, FlatRebuild)) },
    name="thousand six-variable queries rebuild",
  )
  b.bench(
    fn() { b.keep(maintenance_batch(cohort, budget, SharedValues)) },
    name="thousand six-variable queries shared",
  )
}
