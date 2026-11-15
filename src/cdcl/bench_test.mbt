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
