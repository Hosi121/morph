///|
fn dc(left : Int32, right : Int32, bound : Int32) -> @difference.Constraint {
  {
    left: @oracle.nat(left),
    right: @oracle.nat(right),
    bound: @oracle.integer(bound),
  }
}

///|
fn lit(variable : Int32, positive : Bool) -> @sat.Literal {
  { variable: @oracle.nat(variable), positive, }
}

///|
fn cnf_of(items : Array[Array[Int32]]) -> @sat.Cnf {
  @oracle.chain(
    items.map(fn(row) {
      @oracle.chain(
        row.map(fn(code) {
          lit(if code > 0 { code - 1 } else { -code - 1 }, code > 0)
        }),
      )
    }),
  )
}

///|
let shared_test_fuel : @core.Nat = @oracle.nat(20000)

///|
// Enumerate actual integer assignments, without a graph solver or Boolean SAT.
fn native_satisfiable(atoms : Array[Atom], cnf : Array[Array[Int32]]) -> Bool {
  for x in -4..<=4 {
    for y in -4..<=4 {
      let integers = [0, x, y]
      for free in 0..<(1 << atoms.length()) {
        let booleans = Array::makei(atoms.length(), fn(i) {
          match atoms[i] {
            Free => (free & (1 << i)) != 0
            Difference(c) =>
              integers[@oracle.int_of_nat(c.left)] -
              integers[@oracle.int_of_nat(c.right)] <=
              @oracle.int_of_integer(c.bound)
          }
        })
        if cnf.all(fn(clause) {
            clause.any(fn(code) {
              if code > 0 {
                booleans[code - 1]
              } else {
                !booleans[-code - 1]
              }
            })
          }) {
          return true
        }
      }
    }
  }
  false
}

///|
fn verify_case(
  atoms : Array[Atom],
  clauses : Array[Array[Int32]],
) -> Unit raise {
  let p = problem(@oracle.chain(atoms), cnf_of(clauses)).unwrap()
  let expected = native_satisfiable(atoms, clauses)
  match run(start(p), shared_test_fuel) {
    Satisfiable(model) => {
      assert_true(expected)
      assert_true(check_model(p, model))
      assert_true(@sat.check_model(cnf(p), booleans(model)))
      let raw = @oracle.array(booleans(model))
      assert_eq(raw.length(), atoms.length())
      for i in 0..<atoms.length() {
        match atoms[i] {
          Free => ()
          Difference(c) => {
            let left = @oracle.int_of_integer(
              @difference.value(integers(model), c.left).unwrap(),
            )
            let right = @oracle.int_of_integer(
              @difference.value(integers(model), c.right).unwrap(),
            )
            assert_eq(
              left - right <= @oracle.int_of_integer(c.bound),
              raw[i].positive,
            )
          }
        }
      }
    }
    Unsatisfiable(proof) => {
      assert_false(expected)
      assert_true(check_refutation(p, proof))
    }
    Paused(_) => fail("tiny SMT case exhausted fuel")
    InvariantViolation => fail("SMT model or proof was invalid")
  }
}

///|
test "integer theory refutes Boolean models and skips free atom slots correctly" {
  let c = [Difference(dc(1, 0, 0)), Difference(dc(0, 1, -1))]
  verify_case(c, [[1], [2]])
  verify_case(c, [[-1, 2], [1, -2]])
  verify_case(c, [[1, 2]])
  verify_case([Free, c[0], Free, c[1]], [[2], [4]])
  verify_case([Difference(dc(0, 0, 0))], [])
  verify_case([Difference(dc(0, 0, -1))], [])
  verify_case([Free, Free], [[1, 2], [-1, -2]])
  verify_case([], [])
  verify_case([], [[]])
  assert_eq(problem(@core.Nil, cnf_of([[1]])), None)
  let atoms = @oracle.chain([dc(1, 0, 0), dc(0, 1, -1)])
  let p = differences(atoms, cnf_of([[1], [2]])).unwrap()
  match run(start(p), @oracle.nat(20000)) {
    Unsatisfiable(proof) => {
      assert_true(@oracle.int_of_nat(@core.length(proof.lemmas)) > 0)
      assert_false(check_refutation(p, { ..proof, lemmas: @core.Nil, }))
      let changed = differences(
        @oracle.chain([dc(1, 0, 1), dc(0, 1, -1)]),
        cnf_of([[1], [2]]),
      ).unwrap()
      assert_false(check_refutation(changed, proof))
    }
    _ => fail("two contradictory unit inequalities must be UNSAT")
  }
}

///|
test "all small two-atom CNFs match independent bounded integer enumeration" {
  let pool = [
    Difference(dc(1, 0, -1)),
    Difference(dc(1, 0, 0)),
    Difference(dc(0, 1, 0)),
    Difference(dc(0, 1, -1)),
    Difference(dc(1, 1, -1)),
    Difference(dc(0, 0, 0)),
    Free,
  ]
  let clauses : Array[Array[Int32]] = [
    [],
    [1],
    [-1],
    [2],
    [-2],
    [1, 2],
    [1, -2],
    [-1, 2],
    [-1, -2],
    [1, -1],
    [2, 2],
  ]
  for a in pool {
    for b in pool {
      verify_case([a, b], [])
      for c in clauses {
        verify_case([a, b], [c])
        for d in clauses {
          verify_case([a, b], [c, d])
        }
      }
    }
  }
}

///|
test "generated three-integer formulas mix disjunctions and arithmetic cycles" {
  let pool = [
    Difference(dc(1, 0, 0)),
    Difference(dc(0, 1, -1)),
    Difference(dc(2, 0, 1)),
    Difference(dc(0, 2, -1)),
    Difference(dc(1, 2, -1)),
    Difference(dc(2, 1, 0)),
    Free,
  ]
  for seed in 0..<500 {
    let count = 1 + seed % 5
    let atoms = Array::makei(count, fn(i) {
      pool[(seed * 5 + i * 3 + i / 2) % pool.length()]
    })
    let clauses = Array::makei(seed % 7, fn(i) {
      Array::makei(1 + (seed + i) % 3, fn(j) {
        let variable = 1 + (seed * 13 + i * 5 + j * 7) % count
        if (seed + i + j) % 2 == 0 {
          variable
        } else {
          -variable
        }
      })
    })
    verify_case(atoms, clauses)
  }
}

///|
test "theory lemma checker rejects free labels wrong edges and nonnegative walks" {
  let p = problem(
    @oracle.chain([Free, Difference(dc(1, 0, 0)), Difference(dc(0, 1, -1))]),
    @core.Nil,
  ).unwrap()
  assert_true(
    lemma_clause(p, { cycle: @oracle.chain([lit(1, true), lit(2, true)]), })
    is Some(_),
  )
  assert_eq(lemma_clause(p, { cycle: @core.Nil, }), None)
  assert_eq(lemma_clause(p, { cycle: @core.Cons(lit(0, true), Nil), }), None)
  assert_eq(lemma_clause(p, { cycle: @core.Cons(lit(99, true), Nil), }), None)
  assert_eq(lemma_clause(p, { cycle: @core.Cons(lit(1, true), Nil), }), None)
  // Both false is also impossible: these two predicates are exact complements.
  assert_true(
    lemma_clause(p, { cycle: @oracle.chain([lit(1, false), lit(2, false)]), })
    is Some(_),
  )
  let nonnegative = differences(
    @oracle.chain([dc(1, 0, 1), dc(0, 1, 1)]),
    @core.Nil,
  ).unwrap()
  assert_eq(
    lemma_clause(nonnegative, {
      cycle: @oracle.chain([lit(0, true), lit(1, true)]),
    }),
    None,
  )
  assert_false(
    check_refutation(p, {
      lemmas: @core.Nil,
      propositional: @cdcl.Rup(@core.Cons(@core.Nil, Nil)),
    }),
  )
  let unrelated = @difference.problem(@core.Nil)
  match @difference.solve(unrelated) {
    Feasible(solution) => {
      let forged = Model::{
        booleans: @oracle.chain([lit(0, false), lit(1, true), lit(2, true)]),
        integers: solution,
      }
      assert_false(check_model(p, forged))
      let contradicted = {
        ..forged,
        booleans: @oracle.chain([lit(0, true), lit(0, false)]),
      }
      assert_false(check_model(p, contradicted))
    }
    _ => fail("empty arithmetic problem should be feasible")
  }
}

///|
test "fuel splitting resumes both Boolean and theory phases" {
  let p = differences(
    @oracle.chain([dc(1, 0, 0), dc(0, 1, -1)]),
    cnf_of([[-1, 2], [1, -2]]),
  ).unwrap()
  let initial = start(p)
  match run(initial, @core.Zero) {
    Paused(s) => assert_eq(transitions(s), @core.Zero)
    _ => fail("zero fuel pauses")
  }
  let expected = match run(initial, @oracle.nat(20000)) {
    Unsatisfiable(proof) => proof
    _ => fail("integer complements cannot have the same truth value")
  }
  let mut current = initial
  let mut finished = false
  for _ in 0..<20000 {
    match run(current, @core.Succ(Zero)) {
      Paused(next) => {
        assert_eq(
          @oracle.int_of_nat(transitions(next)),
          @oracle.int_of_nat(transitions(current)) + 1,
        )
        current = next
      }
      Unsatisfiable(proof) => {
        assert_eq(proof, expected)
        assert_true(@oracle.int_of_nat(@core.length(proof.lemmas)) >= 2)
        finished = true
        break
      }
      _ => fail("single-step execution disagrees")
    }
  }
  assert_true(finished)
}
