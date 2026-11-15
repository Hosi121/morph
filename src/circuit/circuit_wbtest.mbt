///|
fn assignment(bits : Int32, count : Int32) -> @sat.Model {
  @oracle.chain(
    [
      for i in 0..<count => {
        @sat.Literal::{
          variable: @oracle.nat(i),
          positive: (bits & (1 << i)) != 0,
        }
      }
    ],
  )
}

///|
fn truth(expr : Expr, bits : Int32) -> Bool {
  match expr {
    Constant(value) => value
    Variable(id) => (bits & (1 << @oracle.int_of_nat(id))) != 0
    Negation(a) => !truth(a, bits)
    Conjunction(a, b) => truth(a, bits) && truth(b, bits)
    Disjunction(a, b) => truth(a, bits) || truth(b, bits)
    Exclusive(a, b) => truth(a, bits) != truth(b, bits)
    Select(c, a, b) =>
      if truth(c, bits) {
        truth(a, bits)
      } else {
        truth(b, bits)
      }
  }
}

///|
test "Tseitin definitions agree with every source assignment including negative arguments" {
  let atoms = [
    Constant(false),
    Constant(true),
    Variable(@oracle.nat(0)),
    Variable(@oracle.nat(1)),
  ]
  let formulas = atoms.copy()
  for a in atoms {
    formulas.push(Negation(a))
  }
  for a in atoms {
    for b in atoms {
      formulas.push(Conjunction(a, b))
      formulas.push(Disjunction(a, b))
      formulas.push(Exclusive(a, b))
      for c in atoms {
        formulas.push(Select(c, a, b))
      }
    }
  }
  for i in 0..<64 {
    formulas.push(
      Exclusive(
        Negation(formulas[i]),
        Select(
          formulas[(i * 7 + 3) % 120],
          formulas[(i * 11 + 5) % 120],
          atoms[i % 4],
        ),
      ),
    )
  }
  for expr in formulas {
    let encoding = compile(@core.Cons(expr, Nil))
    for bits in 0..<4 {
      let expected = truth(expr, bits)
      assert_eq(evaluate(expr, assignment(bits, 2)), Some(expected))
      let fixed = @core.map(encoding.source_variables, fn(variable) {
        @core.Cons(
          @sat.Literal::{
            variable,
            positive: (bits & (1 << @oracle.int_of_nat(variable))) != 0,
          },
          Nil,
        )
      })
      let cnf = @core.append(cnf(encoding), fixed)
      match @sat.solve(cnf) {
        Satisfiable(model) => {
          assert_true(expected)
          assert_true(@sat.check_model(cnf, model))
        }
        Unsatisfiable(proof) => {
          assert_false(expected)
          assert_true(@sat.check_refutation(cnf, proof))
        }
      }
    }
    match @sat.solve(cnf(encoding)) {
      Satisfiable(model) => {
        let source = source_model(encoding, model).unwrap()
        assert_true(check_source_model(encoding, source))
        assert_eq(evaluate(expr, source), Some(true))
      }
      Unsatisfiable(proof) =>
        assert_true(@sat.check_refutation(cnf(encoding), proof))
    }
  }
}

///|
test "source variables and auxiliaries never collide; sharing and counterexamples are explicit" {
  let a = Variable(@oracle.nat(20))
  let b = Variable(@oracle.nat(1))
  let shared = Conjunction(a, b)
  let encoding = compile(@oracle.chain([shared, Negation(shared)]))
  assert_eq(gates(encoding), @oracle.nat(1))
  match @sat.solve(cnf(encoding)) {
    Unsatisfiable(proof) =>
      assert_true(@sat.check_refutation(cnf(encoding), proof))
    _ => fail("shared expression and its negation cannot both hold")
  }
  let broken = miter(
    @core.Cons(Conjunction(a, b), Nil),
    @core.Cons(Disjunction(a, b), Nil),
  ).unwrap()
  match @sat.solve(cnf(broken)) {
    Satisfiable(model) => {
      let source = source_model(broken, model).unwrap()
      assert_true(check_source_model(broken, source))
      assert_true(
        evaluate(Conjunction(a, b), source) !=
        evaluate(Disjunction(a, b), source),
      )
    }
    _ => fail("broken optimization must have a counterexample")
  }
  assert_eq(miter(Nil, @core.Cons(a, Nil)), None)
  let empty = miter(Nil, Nil).unwrap()
  match @sat.solve(cnf(empty)) {
    Unsatisfiable(_) => ()
    _ => fail("empty outputs are equivalent")
  }
  let inconsistent = @oracle.chain([
    @sat.Literal::{ variable: @oracle.nat(20), positive: false, },
    @sat.Literal::{ variable: @oracle.nat(20), positive: true, },
  ])
  assert_eq(evaluate(a, inconsistent), None)
  assert_eq(source_model(broken, inconsistent), None)
}

///|
test "full-adder forms and ripple words are equivalent with checked SAT proofs" {
  for width in 0..<=5 {
    let encoding = adder_miter(@oracle.nat(width), Propagate, Multiplexer).unwrap()
    match @cdcl.run(@cdcl.start(cnf(encoding)), @oracle.nat(20000)) {
      Unsatisfiable(proof) =>
        assert_true(@cdcl.check_refutation(cnf(encoding), proof))
      Satisfiable(_) => fail("addition circuits disagree")
      _ => fail("small addition proof exceeded work bound")
    }
  }
  let reference = adder_miter(@oracle.nat(1), Minterms, Multiplexer).unwrap()
  match @sat.solve(cnf(reference)) {
    Unsatisfiable(proof) =>
      assert_true(@sat.check_refutation(cnf(reference), proof))
    _ => fail("reference truth table and mux disagree")
  }
}
