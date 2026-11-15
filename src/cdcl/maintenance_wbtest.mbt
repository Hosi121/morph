// Profile retained baseline helpers; actual transitions use the current engine.

///|
fn sample_maintenance(
  initial : Search,
  b : @bench.T,
) -> (Status, Array[Int32], Array[Double]) raise {
  let counts = Array::make(3, 0)
  let elapsed = Array::make(4, 0.0)
  for state = initial, remaining = 200000; remaining > 0; {
    let (inspection, watched) = watch_inspect(
      state.watch.unwrap(),
      state.database,
    )
    match inspection {
      Contradiction(conflict) => {
        let lookup = fn(literal : Atom) {
          index_get(watched.values, @binary.bits(literal.key))
        }
        let started = @bench.monotonic_clock_start()
        let conflict_level = highest_level(conflict, lookup)
        match conflict_level {
          Zero => ()
          Succ(_) => {
            let learned = analyze(conflict, state.trail, lookup, conflict_level).unwrap()
            let literal = asserting(learned, lookup, conflict_level).unwrap()
            let level = backjump_level(learned, lookup, literal)
            elapsed[0] += @bench.monotonic_clock_end(started)
            let started = @bench.monotonic_clock_start()
            let trail : Trail = Cons(
              { literal, level, reason: Some(learned), },
              backjump(state.trail, level),
            )
            elapsed[1] += @bench.monotonic_clock_end(started)
            let started = @bench.monotonic_clock_start()
            let next_watch = watch_learn(Some(watched), learned, literal, trail)
            elapsed[2] += @bench.monotonic_clock_end(started)
            b.keep(next_watch)
            let started = @bench.monotonic_clock_start()
            let second = second_watch(learned, literal, trail)
            elapsed[3] += @bench.monotonic_clock_end(started)
            b.keep(second)
            counts[0] += 1
            counts[1] += @oracle.array(trail).length()
            for entry in @oracle.array(state.trail) {
              if @core.compare(entry.level, level) is Greater {
                counts[2] += 1
              }
            }
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
      terminal => break (terminal, counts, elapsed)
    }
  } nobreak {
    fail("maintenance sampler exhausted fuel")
  }
}

///|
test "sixty-four-bit conflict maintenance profile" (b : @bench.T) {
  let cnf = @circuit.cnf(miter_formula(64))
  let initial = start(cnf)
  let (outcome, counts, elapsed) = sample_maintenance(initial, b)
  let (input, logged) = match outcome {
    Unsatisfiable(proof) => {
      let input = @ruplog.prepare(cnf)
      let logged = @ruplog.build_prepared(input, proof).unwrap()
      assert_true(@ruplog.check_prepared(input, logged))
      (input, logged)
    }
    _ => fail("profiled miter must be refuted")
  }
  println(
    "maintenance width=64 learned=\{counts[0]} rebuilt-entries=\{counts[1]} abandoned-entries=\{counts[2]} analysis_ms=\{elapsed[0]/1000.0} backjump_ms=\{elapsed[1]/1000.0} watch-learn_ms=\{elapsed[2]/1000.0} second-watch-subset_ms=\{elapsed[3]/1000.0}",
  )
  b.bench(
    fn() { b.keep(@ruplog.check_prepared(input, logged)) },
    name="unchanged prepared hinted checker control",
  )
}
