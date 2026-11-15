///|
fn stage_chain(length : Int32) -> @sat.Cnf {
  cnf(
    [
      [lit(0, true)],
      ..[
        for i in 0..<length => [lit(i, false), lit(i + 1, true)]
      ],
      [lit(length, false)],
    ],
  )
}

///|
test "stage database normalization implication chain 256" (b : @bench.T) {
  let formula = stage_chain(256)
  b.bench(fn() { b.keep(database(formula)) })
}

///|
test "stage variable collection implication chain 256" (b : @bench.T) {
  let formula = stage_chain(256)
  b.bench(fn() { b.keep(variables(formula)) })
}

///|
test "stage watch construction implication chain 256" (b : @bench.T) {
  let db = database(stage_chain(256))
  b.bench(fn() { b.keep(watch_start(db)) })
}

///|
test "stage watched search implication chain 256 without start" (b : @bench.T) {
  let initial = start(stage_chain(256))
  let budget = fuel(20000)
  b.bench(fn() { b.keep(run(initial, budget)) })
}

///|
test "stage unary to binary key conversion all implication chain 256 occurrences" (
  b : @bench.T,
) {
  let formula = stage_chain(256)
  b.bench(fn() {
    b.keep(@core.map(formula, fn(clause) { @core.map(clause, atom) }))
  })
}

///|
test "candidate halving binary key conversion all implication chain 256 occurrences" (
  b : @bench.T,
) {
  let formula = stage_chain(256)
  b.bench(fn() {
    b.keep(
      @core.map(formula, fn(clause) {
        @core.map(clause, fn(literal) {
          Atom::{
            key: binary_key(literal.variable),
            source: literal.variable,
            positive: literal.positive,
          }
        })
      }),
    )
  })
}

///|
test "stage previous scan RUP checker implication chain 256" (b : @bench.T) {
  let formula = stage_chain(256)
  let proof = match run(start(formula), fuel(20000)) {
    Unsatisfiable(proof) => proof
    _ => fail("benchmark chain must be refuted")
  }
  b.bench(fn() { b.keep(check_refutation_scanning(formula, proof)) })
}

///|
test "stage independent indexed RUP checker implication chain 256" (
  b : @bench.T,
) {
  let formula = stage_chain(256)
  let proof = match run(start(formula), fuel(20000)) {
    Unsatisfiable(proof) => proof
    _ => fail("benchmark chain must be refuted")
  }
  b.bench(fn() { b.keep(check_refutation(formula, proof)) })
}

///|
test "stage ripple adder miter width sixteen circuit construction" (
  b : @bench.T,
) {
  let width = @oracle.nat(16)
  b.bench(fn() { b.keep(@circuit.adder_miter(width, Propagate, Multiplexer)) })
}

///|
test "stage ripple adder miter width sixteen start alone" (b : @bench.T) {
  let formula = @circuit.cnf(miter_formula(16))
  b.bench(fn() { b.keep(start(formula)) })
}

///|
test "stage ripple adder miter width sixteen watched search without start" (
  b : @bench.T,
) {
  let initial = start(@circuit.cnf(miter_formula(16)))
  let budget = fuel(20000)
  b.bench(fn() { b.keep(run(initial, budget)) })
}

///|
test "stage ripple adder miter width sixteen RUP checker" (b : @bench.T) {
  let formula = @circuit.cnf(miter_formula(16))
  let proof = match run(start(formula), fuel(20000)) {
    Unsatisfiable(proof) => proof
    _ => fail("equivalent adder miter must be refuted")
  }
  b.bench(fn() { b.keep(check_refutation(formula, proof)) })
}
