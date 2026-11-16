///|
#derive(ToJson)
priv struct TraceFrame {
  case_name : String
  step : Int32
  kind : String
  value : String
}

///|
fn[T : Debug] emit_frame(
  case_name : String,
  step : Int32,
  kind : String,
  value : T,
) -> Unit raise {
  let rendered = @debug.render(@debug.Repr(value), max_depth=10000)
  assert_false(rendered.contains("..."))
  let frame = TraceFrame::{ case_name, step, kind, value: rendered, }
  println("MORPH_CDCL_TRACE:\{@json.to_json(frame).stringify()}")
}

///|
fn emit_case_trace(
  cnf : @sat.Cnf,
  case_name : String,
  watched : Bool,
) -> Unit raise {
  let initial = if watched { start(cnf) } else { start_scanning(cnf) }
  emit_frame(case_name, 0, "initial", initial)
  for state = initial, step = 1 {
    assert_true(step < 10000)
    let result = run_measured(state, fuel(1))
    let (status, _) = result
    match status {
      Paused(next) => {
        emit_frame(case_name, step, "paused", result)
        continue next, step + 1
      }
      Unsatisfiable(proof) => {
        assert_true(check_refutation(cnf, proof))
        emit_frame(case_name, step, "terminal", result)
        break
      }
      Satisfiable(model) => {
        assert_true(@sat.check_model(cnf, model))
        emit_frame(case_name, step, "terminal", result)
        break
      }
      _ => fail("trace fixtures must finish without invariant violations")
    }
  }
}

///|
// No dump in ordinary tests. This adapter compares complete saved-ELF states.
test "opt-in complete continuation traces" (_b : @bench.T) {
  match @env.get_env_var("MORPH_CDCL_TRACE") {
    None => ()
    Some(selection) => {
      assert_true(selection == "1" || selection == "full")
      let width = if selection == "full" { 4 } else { 2 }
      let formulas = [
        pigeonhole(4, 3),
        @circuit.cnf(miter_formula(width)),
        cnf([
          [lit(0, true), lit(3, true)],
          [lit(1, true), lit(4, true)],
          [lit(2, true), lit(5, true)],
          [lit(0, false), lit(2, false), lit(6, true)],
          [lit(0, false), lit(2, false), lit(6, false)],
        ]),
      ]
      let names = ["pigeonhole4-3", "miter\{width}", "nonchronological-sat"]
      for index in 0..<formulas.length() {
        emit_case_trace(formulas[index], "\{names[index]}-watch", true)
        emit_case_trace(formulas[index], "\{names[index]}-scan", false)
      }
    }
  }
}
