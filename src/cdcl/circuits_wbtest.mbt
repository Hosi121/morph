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

///|
test "large incorrect adder returns a checked source-level carry counterexample" {
  let width = 32
  let left = @circuit.adder_outputs(fuel(width), Propagate)
  let a = @oracle.chain(
    [
      for variable in 0..<width => @circuit.Variable(fuel(variable))
    ],
  )
  let b = @oracle.chain(
    [
      for variable in 0..<width => @circuit.Variable(fuel(variable + width))
    ],
  )
  let ops = @circuit.algebra()
  let adder = fn(a, b, carry) { @boolean.full_adder_mux(ops, a, b, carry) }
  let right = match @boolean.add_words(adder, a, b, @circuit.Constant(false)) {
    None => fail("equal-width words must construct the incorrect adder")
    Some((sum, carry)) => @core.append(sum, Cons(carry, Nil))
  }
  let encoding = match @circuit.miter(left, right) {
    None => fail("equal-width adder output lists must construct a miter")
    Some(encoding) => encoding
  }
  let formula = @circuit.cnf(encoding)
  match run(start(formula), fuel(20000)) {
    Satisfiable(model) => {
      assert_true(@sat.check_model(formula, model))
      assert_true(@circuit.check_source_model(encoding, model))
      let carry = @sat.Literal::{
        variable: fuel(width + width),
        positive: true,
      }
      match @circuit.source_model(encoding, model) {
        None => fail("counterexample must project back to source variables")
        Some(source) =>
          assert_true(@core.any(source, fn(literal) { literal.equal(carry) }))
      }
    }
    _ =>
      fail("discarding initial carry must produce a satisfiable counterexample")
  }
}
