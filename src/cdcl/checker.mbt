///|
/// This evaluator is independent of the solver's clause-status evaluator,
/// watches, trail reasons, decisions, and conflict analysis. Only immutable
/// key/index operations and input normalization are shared.
priv enum CheckingClause {
  Holds
  EmptyClause
  Implication(Atom)
  Undetermined
}

///|
fn checking_clause(clause : Lits, values : Index[Bool]) -> CheckingClause {
  match clause {
    Nil => EmptyClause
    Cons(literal, rest) =>
      match index_get(values, @binary.bits(literal.key)) {
        Some(assigned) =>
          match (assigned, literal.positive) {
            (true, true) | (false, false) => Holds
            _ => checking_clause(rest, values)
          }
        None =>
          match checking_clause(rest, values) {
            Holds => Holds
            EmptyClause => Implication(literal)
            Implication(_) | Undetermined => Undetermined
          }
      }
  }
}

///|
priv enum CheckingStep {
  Inconsistent
  Implied(Atom)
  Stable
}

///|
fn checking_step(db : Database, values : Index[Bool]) -> CheckingStep {
  match db {
    Nil => Stable
    Cons(clause, rest) =>
      match checking_clause(clause, values) {
        EmptyClause => Inconsistent
        Implication(literal) => Implied(literal)
        Holds | Undetermined => checking_step(rest, values)
      }
  }
}

///|
fn checking_conflict(db : Database, values : Index[Bool]) -> Bool {
  match checking_step(db, values) {
    Inconsistent => true
    Stable => false
    Implied(literal) =>
      checking_conflict(
        db,
        index_put(values, @binary.bits(literal.key), literal.positive),
      )
  }
}

///|
fn checking_assumptions(
  clause : @sat.Clause,
  values : Index[Bool],
) -> Index[Bool]? {
  match clause {
    Nil => Some(values)
    Cons(literal, rest) => {
      let literal = atom(literal)
      match index_get(values, @binary.bits(literal.key)) {
        None =>
          checking_assumptions(
            rest,
            index_put(values, @binary.bits(literal.key), !literal.positive),
          )
        Some(assigned) =>
          match (assigned, literal.positive) {
            (true, true) | (false, false) => None
            _ => checking_assumptions(rest, values)
          }
      }
    }
  }
}

///|
fn checking_rup(db : Database, clause : @sat.Clause) -> Bool {
  match checking_assumptions(clause, Empty) {
    None => true
    Some(values) => checking_conflict(db, values)
  }
}

///|
/// Check the RUP additions in order with deterministic unit propagation.
/// No solver, decisions, conflict analysis, or watch indices are invoked.
/// A finite certificate must end with a justified empty clause.
pub fn check_refutation(cnf : @sat.Cnf, proof : Proof) -> Bool {
  fn check(db : Database, steps : @core.Chain[@sat.Clause]) -> Bool {
    match steps {
      Nil => false
      Cons(clause, Nil) =>
        match clause {
          Nil => checking_rup(db, clause)
          _ => false
        }
      Cons(clause, rest) =>
        match checking_rup(db, clause) {
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
