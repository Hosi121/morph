///|
test "twenty thousand clauses do not consume one stack frame per CNF clause" {
  let positive = @oracle.chain([lit(0, true)])
  let repeated = for remaining = 20000, formula = @core.Nil; remaining > 0; {
    continue remaining - 1, @core.Cons(positive, formula)
  } nobreak {
    formula
  }
  match run(start(repeated), fuel(10)) {
    Satisfiable(model) => assert_true(@sat.check_model(repeated, model))
    _ => fail("repeated positive units must be satisfiable")
  }
  let contradiction = @core.Cons(@oracle.chain([lit(0, false)]), repeated)
  match run(start(contradiction), fuel(10)) {
    Unsatisfiable(proof) => assert_true(check_refutation(contradiction, proof))
    _ => fail("opposite units must be refuted")
  }
  let binary = @oracle.chain([lit(0, true), lit(1, true)])
  let branching = for remaining = 20000, formula = @core.Nil; remaining > 0; {
    continue remaining - 1, @core.Cons(binary, formula)
  } nobreak {
    formula
  }
  for initial in [start(branching), start_scanning(branching)] {
    match run(initial, fuel(10)) {
      Satisfiable(model) => assert_true(@sat.check_model(branching, model))
      _ => fail("repeated binary clauses must be satisfiable")
    }
  }
}

///|
test "sparse variable identifier 65535 survives startup model and proof checking" {
  let variable = fuel(65535)
  let positive : @sat.Literal = { variable, positive: true, }
  let negative : @sat.Literal = { variable, positive: false, }
  let satisfiable = cnf([[positive]])
  match run(start(satisfiable), fuel(10)) {
    Satisfiable(model) => assert_true(@sat.check_model(satisfiable, model))
    _ => fail("a high-identifier unit must be satisfiable")
  }
  let contradictory = cnf([[positive], [negative]])
  match run(start(contradictory), fuel(10)) {
    Unsatisfiable(proof) => assert_true(check_refutation(contradictory, proof))
    _ => fail("opposite high-identifier units must be refuted")
  }
}
