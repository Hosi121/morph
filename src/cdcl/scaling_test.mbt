///|
fn scaling_fuel() -> @core.Nat {
  for remaining = 200000, result = @core.Zero; remaining > 0; {
    continue remaining - 1, @core.Succ(result)
  } nobreak {
    result
  }
}

///|
fn scaling_proof(
  width : Int32,
) -> (@sat.Cnf, @cdcl.Proof, @cdcl.Statistics) raise {
  let formula = bench_miter(width)
  let (outcome, stats) = @cdcl.run_measured(
    @cdcl.start(formula),
    scaling_fuel(),
  )
  match outcome {
    Unsatisfiable(proof) => {
      assert_true(@cdcl.check_refutation(formula, proof))
      println(
        "miter width=\{width}, clauses=\{@oracle.array(formula).length()}, transitions=\{@oracle.int_of_nat(stats.transitions)}, decisions=\{@oracle.int_of_nat(stats.decisions)}, conflicts=\{@oracle.int_of_nat(stats.conflicts)}, learned=\{@oracle.int_of_nat(stats.learned)}",
      )
      (formula, proof, stats)
    }
    Paused(_) => fail("scaling miter exceeded its declared transition budget")
    _ => fail("equivalent scaling miter must be refuted")
  }
}

///|
test "watched CDCL ripple adder miter width thirty two including start" (
  b : @bench.T,
) {
  let (formula, _, _) = scaling_proof(32)
  let budget = scaling_fuel()
  b.bench(fn() { b.keep(@cdcl.run(@cdcl.start(formula), budget)) })
}

///|
test "RUP checker ripple adder miter width thirty two" (b : @bench.T) {
  let (formula, proof, _) = scaling_proof(32)
  b.bench(fn() { b.keep(@cdcl.check_refutation(formula, proof)) })
}

///|
test "watched CDCL ripple adder miter width sixty four including start" (
  b : @bench.T,
) {
  let (formula, _, _) = scaling_proof(64)
  let budget = scaling_fuel()
  b.bench(fn() { b.keep(@cdcl.run(@cdcl.start(formula), budget)) })
}

///|
test "RUP checker ripple adder miter width sixty four" (b : @bench.T) {
  let (formula, proof, _) = scaling_proof(64)
  b.bench(fn() { b.keep(@cdcl.check_refutation(formula, proof)) })
}
