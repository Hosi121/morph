///|
priv enum CheckedClause {
  TrueClause
  FalseClause
  Single(Literal)
  Nonunit
}

///|
/// Checker-only evaluator. It consumes only the clause selected by a hint and
/// does not scan the database or call the builder's propagation code.
fn checked_clause(clause : Lits, values : Trie[Bool]) -> CheckedClause {
  fn visit(rest : Lits, only : Literal?, multiple : Bool) -> CheckedClause {
    match rest {
      Nil =>
        match (only, multiple) {
          (None, _) => FalseClause
          (Some(value), false) => Single(value)
          _ => Nonunit
        }
      Cons(value, tail) =>
        match get(values, @binary.bits(value.key)) {
          Some(assigned) =>
            match (assigned, value.source.positive) {
              (true, true) | (false, false) => TrueClause
              _ => visit(tail, only, multiple)
            }
          None =>
            match only {
              None => visit(tail, Some(value), multiple)
              Some(_) => visit(tail, only, true)
            }
        }
    }
  }
  visit(clause, None, false)
}

///|
/// Added clauses in this subset use strictly increasing variable labels,
/// excluding both repetitions and complementary pairs.
fn checked_canonical(source : @sat.Clause) -> Lits? {
  fn visit(
    rest : @sat.Clause,
    previous : @binary.Binary?,
    reversed : Lits,
  ) -> Lits? {
    match rest {
      Nil => Some(@core.reverse(reversed))
      Cons(value, tail) => {
        let value = literal(value)
        let increasing = match previous {
          None => true
          Some(key) => @binary.compare(key, value.key) is Less
        }
        match increasing {
          false => None
          true => visit(tail, Some(value.key), Cons(value, reversed))
        }
      }
    }
  }
  visit(source, None, Nil)
}

///|
fn checker_assumptions(clause : Lits, values : Trie[Bool]) -> Trie[Bool] {
  match clause {
    Nil => values
    Cons(value, rest) =>
      checker_assumptions(
        rest,
        put(values, @binary.bits(value.key), !value.source.positive),
      )
  }
}

///|
fn replay(
  database : Database,
  hints : @core.Chain[@binary.Binary],
  values : Trie[Bool],
) -> Bool {
  match hints {
    Nil => false
    Cons(id, rest) =>
      match get(database.indexed, @binary.bits(id)) {
        None | Some(Tautology) => false
        Some(Terms(clause)) =>
          match checked_clause(clause, values) {
            FalseClause => rest is Nil
            Single(value) =>
              replay(
                database,
                rest,
                put(values, @binary.bits(value.key), value.source.positive),
              )
            TrueClause | Nonunit => false
          }
      }
  }
}

///|
/// Check sequential additions with positive IDs, no RAT and no deletions.
/// Every hint must be unit, followed by a final falsified-clause hint.
/// All hints must be consumed, and the last addition must be empty.
pub fn check_prepared(input : Input, certificate : Certificate) -> Bool {
  fn visit(rest : @core.Chain[Step], database : Database) -> Bool {
    match rest {
      Nil => false
      Cons(step, tail) =>
        match @binary.compare(step.id, database.next) {
          Less | Greater => false
          Equal =>
            match checked_canonical(step.clause) {
              None => false
              Some(clause) => {
                let shaped = match (clause, tail) {
                  (Nil, Nil) => Some(true)
                  (Nil, Cons(_, _)) | (Cons(_, _), Nil) => None
                  _ => Some(false)
                }
                match shaped {
                  None => false
                  Some(last_step) =>
                    match
                      replay(
                        database,
                        step.hints,
                        checker_assumptions(clause, Empty),
                      ) {
                      false => false
                      true =>
                        match last_step {
                          true => true
                          false =>
                            visit(tail, add(database, step.id, Terms(clause)))
                        }
                    }
                }
              }
            }
        }
    }
  }
  visit(certificate.steps, input.database)
}

///|
pub fn check(cnf : @sat.Cnf, certificate : Certificate) -> Bool {
  check_prepared(prepare(cnf), certificate)
}
