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
  match outcome {
    Unsatisfiable(proof) => {
      let logged = @ruplog.build(cnf, proof).unwrap()
      assert_true(@ruplog.check(cnf, logged))
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
}

///|
test "phase profile of sixteen-bit watched miter" (b : @bench.T) {
  measure_phases(16, b)
}

///|
test "phase profile of sixty-four-bit watched miter" (b : @bench.T) {
  measure_phases(64, b)
}
