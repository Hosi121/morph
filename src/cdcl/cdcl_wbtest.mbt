///|
fn lit(variable : Int32, positive : Bool) -> @sat.Literal {
  { variable: @oracle.nat(variable), positive, }
}

///|
fn cnf(clauses : Array[Array[@sat.Literal]]) -> @sat.Cnf {
  @oracle.chain(clauses.map(@oracle.chain))
}

///|
fn fuel(amount : Int32) -> @core.Nat {
  for remaining = amount, result = @core.Zero; remaining > 0; {
    continue remaining - 1, @core.Succ(result)
  } nobreak {
    result
  }
}

///|
fn ternary_clause(code : Int32, variables : Int32) -> @sat.Clause {
  let result = []
  let mut digits = code
  for variable in 0..<variables {
    let digit = digits % 3
    digits /= 3
    if digit != 0 {
      result.push(lit(variable, digit == 1))
    }
  }
  @oracle.chain(result)
}

///|
fn brute(formula : @sat.Cnf, variables : Int32) -> Bool {
  let clauses = @oracle.array(formula).map(@oracle.array)
  for mask in 0..<(1 << variables) {
    if clauses.all(fn(clause) {
        clause.any(fn(literal) {
          ((mask & (1 << @oracle.int_of_nat(literal.variable))) != 0) ==
          literal.positive
        })
      }) {
      return true
    }
  }
  false
}

///|
fn validate(formula : @sat.Cnf, variables : Int32) -> Unit raise {
  let expected = brute(formula, variables)
  let old = match @sat.solve(formula) {
    Satisfiable(model) => {
      assert_true(@sat.check_model(formula, model))
      true
    }
    Unsatisfiable(proof) => {
      assert_true(@sat.check_refutation(formula, proof))
      false
    }
  }
  assert_eq(old, expected)
  match run(start(formula), @oracle.nat(1000)) {
    Satisfiable(model) => {
      assert_true(expected)
      assert_true(@sat.check_model(formula, model))
    }
    Unsatisfiable(proof) => {
      assert_false(expected)
      assert_true(check_refutation(formula, proof))
    }
    Paused(_) => fail("small formula exhausted transition budget")
    InvariantViolation => fail("CDCL invariant violated")
  }
}

///|
test "CDCL agrees with truth tables and DPLL on all triples of three-variable clauses" {
  for a in 0..<27 {
    for b in 0..<27 {
      for c in 0..<27 {
        validate(
          @oracle.chain([
            ternary_clause(a, 3),
            ternary_clause(b, 3),
            ternary_clause(c, 3),
          ]),
          3,
        )
      }
    }
  }
}

///|
test "CDCL learns on every subset of the full three-variable cube" {
  let clauses = [
    for mask in 0..<8 => {
      @oracle.chain(
        [
          for variable in 0..<3 => lit(variable, (mask & (1 << variable)) != 0)
        ],
      )
    }
  ]
  for subset in 0..<256 {
    validate(
      @oracle.chain(
        [
          for i in 0..<8 if (subset & (1 << i)) != 0 => clauses[i]
        ],
      ),
      3,
    )
  }
}

///|
test "duplicates tautologies empty formulas and sparse identifiers retain semantics" {
  let a = lit(0, true)
  let b = lit(1, true)
  validate(cnf([]), 2)
  validate(cnf([[]]), 2)
  validate(cnf([[a, a], [@sat.negate(a), @sat.negate(a)]]), 2)
  validate(cnf([[a, @sat.negate(a), a], [b, b]]), 2)
  validate(cnf([[a, @sat.negate(a)], [a, b], [@sat.negate(a), b]]), 2)
  let sparse = cnf([[lit(200, true)], [lit(200, false), lit(500, true)]])
  match run(start(sparse), @oracle.nat(10)) {
    Satisfiable(model) => assert_true(@sat.check_model(sparse, model))
    _ => fail("sparse identifier formula must be satisfiable")
  }
}

///|
test "single transition resumption matches uninterrupted runs and snapshots are persistent" {
  let formula = cnf([
    [lit(0, true), lit(1, true)],
    [lit(0, false), lit(1, true)],
    [lit(0, true), lit(1, false)],
    [lit(0, false), lit(1, false)],
  ])
  let initial = start(formula)
  let complete = run(initial, @oracle.nat(100))
  assert_eq(run(initial, @core.Zero), Paused(initial))
  let resumed = for state = initial, transitions = 0 {
    assert_true(transitions < 100)
    match run(state, @oracle.nat(1)) {
      Paused(next) => continue next, transitions + 1
      terminal => break terminal
    }
  }
  assert_eq(resumed, complete)
  assert_eq(run(initial, @oracle.nat(100)), complete)
  match complete {
    Unsatisfiable(proof) => assert_true(check_refutation(formula, proof))
    _ => fail("the full two-variable cube is unsatisfiable")
  }
}

///|
test "first UIP learning skips an irrelevant decision level" {
  let formula = cnf([
    [lit(0, true), lit(3, true)],
    [lit(1, true), lit(4, true)],
    [lit(2, true), lit(5, true)],
    [lit(0, false), lit(2, false), lit(6, true)],
    [lit(0, false), lit(2, false), lit(6, false)],
  ])
  let (outcome, stats) = run_measured(start(formula), @oracle.nat(100))
  assert_true(@oracle.int_of_nat(stats.learned) > 0)
  assert_true(@oracle.int_of_nat(stats.nonchronological) > 0)
  match outcome {
    Satisfiable(model) => assert_true(@sat.check_model(formula, model))
    _ => fail("formula with an irrelevant middle decision must be satisfiable")
  }
}

///|
test "RUP checker rejects forged additions and truncated proofs and accepts valid repetition" {
  let formula = cnf([
    [lit(0, true), lit(1, true)],
    [lit(0, false), lit(1, true)],
    [lit(0, true), lit(1, false)],
    [lit(0, false), lit(1, false)],
  ])
  let a = @oracle.chain([lit(0, true)])
  let unrelated = @oracle.chain([lit(2, true)])
  assert_false(check_refutation(formula, Rup(@core.Nil)))
  assert_false(check_refutation(formula, Rup(@oracle.chain([@core.Nil]))))
  assert_false(check_refutation(formula, Rup(@oracle.chain([a]))))
  assert_false(
    check_refutation(formula, Rup(@oracle.chain([unrelated, a, @core.Nil]))),
  )
  assert_true(check_refutation(formula, Rup(@oracle.chain([a, a, @core.Nil]))))
  assert_true(
    check_refutation(
      formula,
      Rup(
        @oracle.chain([
          @oracle.chain([lit(2, true), lit(2, false)]),
          a,
          @core.Nil,
        ]),
      ),
    ),
  )
  let satisfiable = cnf([[lit(0, true), lit(1, true)]])
  assert_false(
    check_refutation(satisfiable, Rup(@oracle.chain([a, @core.Nil]))),
  )
  assert_true(check_refutation(cnf([[]]), Rup(@oracle.chain([@core.Nil]))))
}

///|
fn pigeonhole(pigeons : Int32, holes : Int32) -> @sat.Cnf {
  let clauses = []
  for pigeon in 0..<pigeons {
    clauses.push([ for hole in 0..<holes => lit(pigeon * holes + hole, true) ])
  }
  for hole in 0..<holes {
    for left in 0..<pigeons {
      for right in (left + 1)..<pigeons {
        clauses.push([
          lit(left * holes + hole, false),
          lit(right * holes + hole, false),
        ])
      }
    }
  }
  cnf(clauses)
}

///|
test "pigeonhole family exercises learned refutations" {
  for holes in 1..<=4 {
    let formula = pigeonhole(holes + 1, holes)
    let (outcome, stats) = run_measured(start(formula), fuel(20000))
    match outcome {
      Unsatisfiable(proof) => assert_true(check_refutation(formula, proof))
      _ =>
        fail("pigeonhole formula must be refuted within the transition budget")
    }
    if holes > 1 {
      assert_true(@oracle.int_of_nat(stats.learned) > 0)
    }
    if holes == 4 {
      debug_inspect(
        [
          @oracle.int_of_nat(stats.transitions),
          @oracle.int_of_nat(stats.decisions),
          @oracle.int_of_nat(stats.propagations),
          @oracle.int_of_nat(stats.conflicts),
          @oracle.int_of_nat(stats.learned),
          @oracle.int_of_nat(stats.backjumps),
          @oracle.int_of_nat(stats.nonchronological),
        ],
        content=(
          #|[355, 29, 296, 30, 29, 29, 0]
        ),
      )
    }
  }
}

///|
test "deterministic four-variable formulas agree with two independent solvers" {
  let mut state = 49157
  for _ in 0..<3000 {
    let clauses = []
    for _ in 0..<12 {
      let values = []
      for variable in 0..<4 {
        state = (state * 61 + 17) % 65521
        let digit = state % 3
        if digit != 0 {
          values.push(lit(variable, digit == 1))
        }
      }
      clauses.push(values)
    }
    validate(cnf(clauses), 4)
  }
}
