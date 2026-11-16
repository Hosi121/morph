///|
fn review_polynomial(
  arity : Int32,
  terms : Array[(Int32, Int32, Array[Int32])],
) -> @polynomial.Polynomial {
  @polynomial.polynomial(
    @oracle.nat(arity),
    @oracle.chain(
      terms.map(fn(term) {
        let (numerator, denominator, powers) = term
        @polynomial.Term::{
          coefficient: @oracle.rational(numerator, denominator),
          exponents: @oracle.chain(powers.map(@oracle.nat)),
        }
      }),
    ),
  ).unwrap()
}

///|
fn review_problem(arity : Int32, source : @qf.Formula) -> Problem {
  prepare(@oracle.nat(arity), source).unwrap()
}

///|
fn review_solve(problem : Problem) -> Outcome raise {
  let mut search = start(problem)
  for _ in 0..<100000 {
    match step(search) {
      Ok(Paused(next)) => search = next
      Ok(outcome) => return outcome
      Err(error) =>
        fail("independent review unexpected SMT error: \{error.to_repr()}")
    }
  }
  fail("independent review transition budget exhausted; no decision inferred")
}

///|
fn review_expect(
  arity : Int32,
  source : @qf.Formula,
  expected : Bool,
) -> Unit raise {
  let problem = review_problem(arity, source)
  match review_solve(problem) {
    Satisfiable(model) => {
      assert_true(expected)
      assert_true(check_model(problem, model))
      assert_eq(@cad.evaluate_formula(point(model), source), Ok(true))
      assert_eq(
        @core.length(@cad.coordinates(point(model))),
        @oracle.nat(arity),
      )
    }
    Unsatisfiable(proof) => {
      assert_false(expected)
      assert_true(check_refutation(problem, proof))
      for lemma in @oracle.array(proof.lemmas) {
        assert_true(lemma_clause(problem, lemma) is Some(_))
      }
    }
    Paused(_) => fail("independent review failed to obtain a decision")
  }
}

///|
fn review_model(problem : Problem) -> Model raise {
  match review_solve(problem) {
    Satisfiable(model) => {
      assert_true(check_model(problem, model))
      model
    }
    _ => fail("independent attack setup expected SAT")
  }
}

///|
fn review_refutation(problem : Problem) -> Refutation raise {
  match review_solve(problem) {
    Unsatisfiable(proof) => {
      assert_true(check_refutation(problem, proof))
      proof
    }
    _ => fail("independent attack setup expected UNSAT")
  }
}

///|
fn[A] review_drop_final(values : @core.Chain[A]) -> @core.Chain[A] {
  match values {
    Nil | Cons(_, Nil) => Nil
    Cons(head, rest) => Cons(head, review_drop_final(rest))
  }
}

///|
fn review_flip_leaf(tree : @cad.TreeCertificate) -> @cad.TreeCertificate {
  match tree {
    Leaf(value) => Leaf(!value)
    Stack(whole, Cons(cell, rest)) =>
      Stack(
        whole,
        Cons({ ..cell, subtree: review_flip_leaf(cell.subtree), }, rest),
      )
    Stack(_, Nil) => tree
  }
}
