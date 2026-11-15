///|
fn literal(variable : Int32, positive : Bool) -> Literal {
  { variable: @oracle.nat(variable), positive, }
}

///|
fn clause(code : Int32) -> Clause {
  let result = []
  let mut digits = code
  for variable in 0..<3 {
    let digit = digits % 3
    digits /= 3
    if digit != 0 {
      result.push(literal(variable, digit == 1))
    }
  }
  @oracle.chain(result)
}

///|
fn brute(cnf : Array[Array[Literal]]) -> Bool {
  for mask in 0..<8 {
    if cnf.all(fn(clause) {
        clause.any(fn(lit) {
          ((mask & (1 << @oracle.int_of_nat(lit.variable))) != 0) ==
          lit.positive
        })
      }) {
      return true
    }
  }
  false
}

///|
fn validate(cnf : Cnf) -> Unit raise {
  let expected = brute(@oracle.array(cnf).map(@oracle.array))
  match solve(cnf) {
    Satisfiable(model) => {
      assert_true(expected)
      assert_true(check_model(cnf, model))
    }
    Unsatisfiable(proof) => {
      assert_false(expected)
      assert_true(check_refutation(cnf, proof))
    }
  }
}

///|
test "DPLL models and proofs exhaust triples of all three-variable non-tautological clauses" {
  for a in 0..<27 {
    for b in 0..<27 {
      for c in 0..<27 {
        validate(@oracle.chain([clause(a), clause(b), clause(c)]))
      }
    }
  }
}

///|
test "branching refutations, duplicate literals, tautologies and forged certificates" {
  let positives = [literal(0, true), literal(1, true), literal(2, true)]
  let all_clauses = [
    for pattern in 0..<8 => {
      @oracle.chain(
        [
          for i in 0..<3 => {
            if (pattern & (1 << i)) != 0 {
              positives[i]
            } else {
              negate(positives[i])
            }
          }
        ],
      )
    }
  ]
  for subset in 0..<256 {
    validate(
      @oracle.chain(
        [
          for i in 0..<8 if (subset & (1 << i)) != 0 => all_clauses[i]
        ],
      ),
    )
  }
  let a = positives[0]
  let tautology = @oracle.chain([@oracle.chain([a, negate(a), a])])
  validate(tautology)
  assert_false(check_refutation(tautology, Conflict))
  assert_false(check_refutation(tautology, UnitStep(a, Conflict)))
  assert_false(check_refutation(tautology, PureStep(a, Conflict)))
  assert_false(
    check_model(
      @oracle.chain([@oracle.chain([a]), @oracle.chain([negate(a)])]),
      @oracle.chain([a, negate(a)]),
    ),
  )
  validate(Nil)
  validate(@oracle.chain([Nil]))
}
