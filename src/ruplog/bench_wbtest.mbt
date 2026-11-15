///|
fn miter(width : Int32) -> (@sat.Cnf, @cdcl.Proof) raise {
  let encoding = @circuit.adder_miter(
    @oracle.nat(width),
    Propagate,
    Multiplexer,
  ).unwrap()
  let cnf = @circuit.cnf(encoding)
  match @cdcl.run(@cdcl.start(cnf), @oracle.nat(200000)) {
    Unsatisfiable(proof) => (cnf, proof)
    _ => fail("equivalent adder miter must be refuted")
  }
}

///|
fn measure(width : Int32, b : @bench.T) -> Unit raise {
  let (cnf, proof) = miter(width)
  let input = prepare(cnf)
  let logged = build_scanning_prepared(input, proof).unwrap()
  assert_true(@cdcl.check_refutation(cnf, proof))
  assert_true(check_prepared(input, logged))
  println(
    "miter width=\{width}, clauses=\{@oracle.array(cnf).length()}, additions=\{@oracle.array(logged.steps).length()}, hints=\{@oracle.int_of_nat(hint_count(logged))}",
  )
  b.bench(
    fn() { b.keep(@cdcl.check_refutation(cnf, proof)) },
    name="unhinted RUP checker",
  )
  b.bench(
    fn() { b.keep(build_scanning(cnf, proof)) },
    name="hint builder including preparation",
  )
  b.bench(
    fn() { b.keep(check(cnf, logged)) },
    name="hint checker including preparation",
  )
  b.bench(
    fn() { b.keep(check_prepared(input, logged)) },
    name="hint checker prepared input",
  )
  b.bench(fn() { b.keep(prepare(cnf)) }, name="input preparation alone")
}

///|
test "sixteen-bit miter same proof builder and checker costs" (b : @bench.T) {
  measure(16, b)
}

///|
test "sixty-four-bit miter same proof builder and checker costs" (b : @bench.T) {
  measure(64, b)
}

///|
test "miter learned clauses retain a separately checkable hinted proof" {
  let (cnf, proof) = miter(8)
  let logged = build(cnf, proof).unwrap()
  assert_true(check(cnf, logged))
  assert_true(@cdcl.check_refutation(cnf, erase(logged)))
  assert_true(
    @oracle.int_of_nat(hint_count(logged)) >
    @oracle.array(logged.steps).length(),
  )
}

///|
fn measure_indexed(width : Int32, b : @bench.T) -> Unit raise {
  let (cnf, proof) = miter(width)
  let input = prepare(cnf)
  let scanned = build_scanning_prepared(input, proof).unwrap()
  let indexed = build_prepared(input, proof).unwrap()
  assert_true(check_prepared(input, scanned))
  assert_true(check_prepared(input, indexed))
  println(
    "indexed miter width=\{width}, additions=\{@oracle.array(indexed.steps).length()}, scan hints=\{@oracle.int_of_nat(hint_count(scanned))}, indexed hints=\{@oracle.int_of_nat(hint_count(indexed))}",
  )
  b.bench(
    fn() { b.keep(build_scanning(cnf, proof)) },
    name="scan builder including preparation",
  )
  b.bench(
    fn() { b.keep(build(cnf, proof)) },
    name="occurrence builder including preparation",
  )
  b.bench(fn() { b.keep(check(cnf, scanned)) }, name="checker with scan hints")
  b.bench(
    fn() { b.keep(check(cnf, indexed)) },
    name="checker with occurrence hints",
  )
}

///|
test "sixteen-bit miter scan and occurrence builders" (b : @bench.T) {
  measure_indexed(16, b)
}

///|
test "sixty-four-bit miter scan and occurrence builders" (b : @bench.T) {
  measure_indexed(64, b)
}

///|
fn pipeline(cnf : @sat.Cnf, budget : @core.Nat, hinted : Bool) -> Bool {
  match @cdcl.run(@cdcl.start(cnf), budget) {
    Unsatisfiable(proof) =>
      if hinted {
        match build(cnf, proof) {
          None => false
          Some(logged) => check(cnf, logged)
        }
      } else {
        @cdcl.check_refutation(cnf, proof)
      }
    _ => false
  }
}

///|
test "sixty-four-bit miter solve plus certificate generation and checking" (
  b : @bench.T,
) {
  let encoding = @circuit.adder_miter(@oracle.nat(64), Propagate, Multiplexer).unwrap()
  let cnf = @circuit.cnf(encoding)
  let budget = @oracle.nat(200000)
  assert_true(pipeline(cnf, budget, false))
  assert_true(pipeline(cnf, budget, true))
  b.bench(
    fn() { b.keep(pipeline(cnf, budget, false)) },
    name="solve plus unhinted RUP checking",
  )
  b.bench(
    fn() { b.keep(pipeline(cnf, budget, true)) },
    name="solve plus occurrence builder plus hinted checking",
  )
}
