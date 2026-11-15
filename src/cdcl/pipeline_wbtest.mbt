///|
fn run_selected_mode(
  search : Search,
  budget : @core.Nat,
  diagnostic : Bool,
  indexed : Bool,
  skip_recount : Bool,
) -> (Status, Statistics) {
  match budget {
    Zero => (Paused(search), search.statistics)
    Succ(rest) => {
      let (inspection, search) = match search.watch {
        None => (inspect_database(search.database, search.trail), search)
        Some(watched) => {
          let (inspection, watched) = watch_inspect_using(
            watched,
            search.database,
            diagnostic,
          )
          (inspection, { ..search, watch: Some(watched), })
        }
      }
      match transition_using(search, inspection, indexed, skip_recount) {
        (Paused(next), _) =>
          run_selected_mode(next, rest, diagnostic, indexed, skip_recount)
        terminal => terminal
      }
    }
  }
}

///|
fn hinted_pipeline(
  cnf : @sat.Cnf,
  budget : @core.Nat,
  diagnostic : Bool,
  indexed : Bool,
  skip_recount : Bool,
) -> Bool {
  let (outcome, _) = run_selected_mode(
    start(cnf),
    budget,
    diagnostic,
    indexed,
    skip_recount,
  )
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
test "same executable complete sixty-four-bit hinted query comparison" (
  b : @bench.T,
) {
  let cnf = @circuit.cnf(miter_formula(64))
  let initial = start(cnf)
  let budget = fuel(200000)
  let baseline = run_selected_mode(initial, budget, true, false, false)
  assert_eq(baseline, run_selected_mode(initial, budget, false, false, false))
  assert_eq(baseline, run_selected_mode(initial, budget, false, true, false))
  assert_eq(baseline, run_measured(initial, budget))
  let (outcome, _) = baseline
  let proof = match outcome {
    Unsatisfiable(proof) => proof
    _ => fail("pipeline miter must be refuted")
  }
  let input = @ruplog.prepare(cnf)
  let logged = @ruplog.build_prepared(input, proof).unwrap()
  assert_true(@ruplog.check_prepared(input, logged))
  assert_true(hinted_pipeline(cnf, budget, true, false, false))
  assert_true(hinted_pipeline(cnf, budget, false, false, false))
  assert_true(hinted_pipeline(cnf, budget, false, true, false))
  b.bench(fn() { b.keep(start(cnf)) }, name="unchanged solver startup control")
  b.bench(
    fn() { b.keep(hinted_pipeline(cnf, budget, true, false, false)) },
    name="full diagnostic and linear recount hinted query",
  )
  b.bench(
    fn() { b.keep(hinted_pipeline(cnf, budget, false, false, false)) },
    name="first-open and linear recount hinted query",
  )
  b.bench(
    fn() { b.keep(hinted_pipeline(cnf, budget, false, true, false)) },
    name="first-open and indexed recount hinted query",
  )
  b.bench(
    fn() { b.keep(@ruplog.build_prepared(input, proof)) },
    name="unchanged prepared hinted builder control",
  )
  b.bench(
    fn() { b.keep(@ruplog.check_prepared(input, logged)) },
    name="unchanged prepared hinted checker control",
  )
}
