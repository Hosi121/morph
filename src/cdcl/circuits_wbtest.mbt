///|
fn miter_formula(width : Int32) -> @circuit.Encoding raise {
  match @circuit.adder_miter(fuel(width), Propagate, Multiplexer) {
    None => fail("equal-width adder miter construction must succeed")
    Some(encoding) => encoding
  }
}

///|
test "budgeted ripple adder miter outcomes and checked certificates" {
  let observations = []
  for width in [2, 4, 8, 16] {
    let encoding = miter_formula(width)
    let formula = @circuit.cnf(encoding)
    let (outcome, stats) = run_measured(start(formula), fuel(20000))
    let status = match outcome {
      Satisfiable(_) => fail("equivalent adders must not have a counterexample")
      Unsatisfiable(proof) => {
        assert_true(check_refutation(formula, proof))
        1
      }
      Paused(_) => 2
      InvariantViolation => fail("adder miter violates a solver invariant")
    }
    observations.push([
      width,
      @oracle.int_of_nat(@circuit.gates(encoding)),
      @oracle.array(formula).length(),
      @oracle.int_of_nat(stats.transitions),
      @oracle.int_of_nat(stats.decisions),
      @oracle.int_of_nat(stats.conflicts),
      @oracle.int_of_nat(stats.learned),
      status,
    ])
  }
  debug_inspect(
    observations,
    content=(
      #|[
      #|  [2, 15, 54, 145, 15, 15, 14, 1],
      #|  [4, 33, 118, 382, 30, 27, 26, 1],
      #|  [8, 69, 246, 1040, 84, 58, 57, 1],
      #|  [16, 141, 502, 2680, 252, 118, 117, 1],
      #|]
    ),
  )
}
