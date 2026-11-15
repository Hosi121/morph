///|
/// A deterministic unit-propagation checker. It performs no decisions and
/// does not invoke the solver or conflict analysis.
fn unit_conflict(db : Database, trail : Trail) -> Bool {
  match inspect_database(db, trail) {
    Contradiction(_) => true
    Propagate(literal, reason) =>
      unit_conflict(
        db,
        Cons({ literal, level: Zero, reason: Some(reason), }, trail),
      )
    Complete | Decide(_) | Broken => false
  }
}

///|
fn assumptions(clause : @sat.Clause, trail : Trail) -> Trail? {
  match clause {
    Nil => Some(trail)
    Cons(literal, rest) => {
      let literal = opposite(atom(literal))
      match value(literal, trail) {
        True => assumptions(rest, trail)
        False => None
        Unassigned =>
          assumptions(
            rest,
            Cons({ literal, level: Zero, reason: None, }, trail),
          )
      }
    }
  }
}

///|
fn rup(db : Database, clause : @sat.Clause) -> Bool {
  match assumptions(clause, Nil) {
    None => true
    Some(trail) => unit_conflict(db, trail)
  }
}

///|
/// Verify each RUP addition against only the input and previous additions.
/// The last addition must be the empty clause.
fn check_refutation_scanning(cnf : @sat.Cnf, proof : Proof) -> Bool {
  fn check(db : Database, steps : @core.Chain[@sat.Clause]) -> Bool {
    match steps {
      Nil => false
      Cons(clause, Nil) =>
        match clause {
          Nil => rup(db, clause)
          _ => false
        }
      Cons(clause, rest) =>
        match rup(db, clause) {
          false => false
          true =>
            match normalize(clause) {
              None => check(db, rest)
              Some(clause) => check(Cons(clause, db), rest)
            }
        }
    }
  }
  match proof {
    Rup(steps) => check(database(cnf), steps)
  }
}

///|
test "independent indexed RUP and scanning RUP agree on every small candidate lemma" {
  for a in 0..<27 {
    for b in 0..<27 {
      let formula = @oracle.chain([ternary_clause(a, 3), ternary_clause(b, 3)])
      let db = database(formula)
      for code in 0..<27 {
        let clause = ternary_clause(code, 3)
        let accepted = checking_rup(db, clause)
        assert_eq(accepted, rup(db, clause))
        if accepted {
          let assumed = @core.append(
            formula,
            @core.map(clause, fn(literal) {
              @core.Cons(@sat.negate(literal), @core.Nil)
            }),
          )
          assert_false(brute(assumed, 3))
        }
      }
    }
  }
}

///|
test "certificate order and forged steps agree between independent checkers" {
  let cube = [
    for mask in 0..<8 => {
      @oracle.chain(
        [
          for variable in 0..<3 => lit(variable, (mask & (1 << variable)) != 0)
        ],
      )
    }
  ]
  for count in [7, 8] {
    let formula = @oracle.chain(cube[:count].to_owned())
    for a in 0..<27 {
      for b in 0..<27 {
        let proof = Rup(
          @oracle.chain([ternary_clause(a, 3), ternary_clause(b, 3), @core.Nil]),
        )
        let accepted = check_refutation(formula, proof)
        assert_eq(accepted, check_refutation_scanning(formula, proof))
        if accepted {
          assert_false(brute(formula, 3))
        }
      }
    }
  }
}
