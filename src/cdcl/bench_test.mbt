///|
fn bench_lit(variable : Int32, positive : Bool) -> @sat.Literal {
  { variable: @oracle.nat(variable), positive, }
}

///|
fn bench_pigeonhole(pigeons : Int32, holes : Int32) -> @sat.Cnf {
  let clauses = []
  for pigeon in 0..<pigeons {
    clauses.push(
      @oracle.chain(
        [
          for hole in 0..<holes => bench_lit(pigeon * holes + hole, true)
        ],
      ),
    )
  }
  for hole in 0..<holes {
    for left in 0..<pigeons {
      for right in (left + 1)..<pigeons {
        clauses.push(
          @oracle.chain([
            bench_lit(left * holes + hole, false),
            bench_lit(right * holes + hole, false),
          ]),
        )
      }
    }
  }
  @oracle.chain(clauses)
}

///|
fn bench_fuel() -> @core.Nat {
  for remaining = 20000, result = @core.Zero; remaining > 0; {
    continue remaining - 1, @core.Succ(result)
  } nobreak {
    result
  }
}

///|
test "DPLL pigeonhole five into four" (b : @bench.T) {
  let formula = bench_pigeonhole(5, 4)
  b.bench(fn() { b.keep(@sat.solve(formula)) })
}

///|
test "scan CDCL pigeonhole five into four including start" (b : @bench.T) {
  let formula = bench_pigeonhole(5, 4)
  let fuel = bench_fuel()
  b.bench(fn() { b.keep(@cdcl.run(@cdcl.start_scanning(formula), fuel)) })
}

///|
test "DPLL pigeonhole six into five" (b : @bench.T) {
  let formula = bench_pigeonhole(6, 5)
  b.bench(fn() { b.keep(@sat.solve(formula)) })
}

///|
test "scan CDCL pigeonhole six into five including start" (b : @bench.T) {
  let formula = bench_pigeonhole(6, 5)
  let fuel = bench_fuel()
  b.bench(fn() { b.keep(@cdcl.run(@cdcl.start_scanning(formula), fuel)) })
}

///|
test "watched CDCL pigeonhole five into four including start" (b : @bench.T) {
  let formula = bench_pigeonhole(5, 4)
  let fuel = bench_fuel()
  b.bench(fn() { b.keep(@cdcl.run(@cdcl.start(formula), fuel)) })
}

///|
test "watched CDCL pigeonhole six into five including start" (b : @bench.T) {
  let formula = bench_pigeonhole(6, 5)
  let fuel = bench_fuel()
  b.bench(fn() { b.keep(@cdcl.run(@cdcl.start(formula), fuel)) })
}

///|
fn bench_chain(length : Int32) -> @sat.Cnf {
  @oracle.chain(
    [
      @oracle.chain([bench_lit(0, true)]),
      ..[
        for i in 0..<length => {
          @oracle.chain([bench_lit(i, false), bench_lit(i + 1, true)])
        }
      ],
      @oracle.chain([bench_lit(length, false)]),
    ],
  )
}

///|
test "DPLL implication chain 256 contradiction" (b : @bench.T) {
  let formula = bench_chain(256)
  b.bench(fn() { b.keep(@sat.solve(formula)) })
}

///|
test "scan CDCL implication chain 256 contradiction including start" (
  b : @bench.T,
) {
  let formula = bench_chain(256)
  let fuel = bench_fuel()
  b.bench(fn() { b.keep(@cdcl.run(@cdcl.start_scanning(formula), fuel)) })
}

///|
test "watched CDCL implication chain 256 contradiction including start" (
  b : @bench.T,
) {
  let formula = bench_chain(256)
  let fuel = bench_fuel()
  b.bench(fn() { b.keep(@cdcl.run(@cdcl.start(formula), fuel)) })
}

///|
test "watched CDCL implication chain 256 start alone" (b : @bench.T) {
  let formula = bench_chain(256)
  b.bench(fn() { b.keep(@cdcl.start(formula)) })
}

///|
test "RUP checker implication chain 256 contradiction" (b : @bench.T) {
  let formula = bench_chain(256)
  let proof = match @cdcl.run(@cdcl.start(formula), bench_fuel()) {
    Unsatisfiable(proof) => proof
    _ => fail("benchmark chain must be refuted")
  }
  b.bench(fn() { b.keep(@cdcl.check_refutation(formula, proof)) })
}

///|
fn bench_offset(formula : @sat.Cnf, offset : Int32) -> @sat.Cnf {
  @oracle.chain(
    @oracle.array(formula).map(fn(clause) {
      @oracle.chain(
        @oracle.array(clause).map(fn(literal) {
          bench_lit(
            @oracle.int_of_nat(literal.variable) + offset,
            literal.positive,
          )
        }),
      )
    }),
  )
}

///|
test "watched CDCL pigeonhole five into four start alone dense IDs" (
  b : @bench.T,
) {
  let formula = bench_pigeonhole(5, 4)
  b.bench(fn() { b.keep(@cdcl.start(formula)) })
}

///|
test "watched CDCL pigeonhole five into four start alone IDs offset 1024" (
  b : @bench.T,
) {
  let formula = bench_offset(bench_pigeonhole(5, 4), 1024)
  b.bench(fn() { b.keep(@cdcl.start(formula)) })
}
