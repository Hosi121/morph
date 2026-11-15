///|
priv enum Status {
  Satisfied
  Conflict
  Unit(Literal)
  Open
}

///|
/// Builder-only clause scan. The checking kernel has its own evaluator.
fn builder_clause(clause : Lits, values : Trie[Bool]) -> Status {
  match clause {
    Nil => Conflict
    Cons(value, tail) =>
      match get(values, @binary.bits(value.key)) {
        Some(assigned) =>
          match (assigned, value.source.positive) {
            (true, true) | (false, false) => Satisfied
            _ => builder_clause(tail, values)
          }
        None =>
          match builder_clause(tail, values) {
            Satisfied => Satisfied
            Conflict => Unit(value)
            Unit(_) | Open => Open
          }
      }
  }
}

///|
priv enum Propagation {
  Finished
  Falsified(@binary.Binary)
  Implied(@binary.Binary, Literal)
}

///|
fn builder_find(
  entries : @core.Chain[Entry],
  values : Trie[Bool],
) -> Propagation {
  match entries {
    Nil => Finished
    Cons(entry, rest) =>
      match entry.clause {
        Tautology => builder_find(rest, values)
        Terms(clause) =>
          match builder_clause(clause, values) {
            Satisfied | Open => builder_find(rest, values)
            Conflict => Falsified(entry.id)
            Unit(value) => Implied(entry.id, value)
          }
      }
  }
}

///|
fn builder_hints(
  database : Database,
  clause : Lits,
) -> @core.Chain[@binary.Binary]? {
  let values = @core.fold_left(clause, Empty, fn(values, value) {
    put(values, @binary.bits(value.key), !value.source.positive)
  })
  fn propagate(
    values : Trie[Bool],
    reversed : @core.Chain[@binary.Binary],
  ) -> @core.Chain[@binary.Binary]? {
    match builder_find(database.entries, values) {
      Finished => None
      Falsified(id) => Some(@core.reverse(Cons(id, reversed)))
      Implied(id, value) =>
        propagate(
          put(values, @binary.bits(value.key), value.source.positive),
          Cons(id, reversed),
        )
    }
  }
  propagate(values, Nil)
}

///|
/// Enrich an existing RUP list without invoking SAT search. Source tautological
/// lemmas are omitted. Other clauses are sorted and deduplicated. An empty
/// clause is required exactly at the end.
pub fn build_prepared(input : Input, proof : @cdcl.Proof) -> Certificate? {
  fn visit(
    rest : @core.Chain[@sat.Clause],
    database : Database,
    reversed : @core.Chain[Step],
  ) -> Certificate? {
    match rest {
      Nil => None
      Cons(source, tail) =>
        match normalize(source) {
          Tautology => visit(tail, database, reversed)
          Terms(clause) => {
            let last_step = match (clause, tail) {
              (Nil, Nil) => Some(true)
              (Nil, Cons(_, _)) | (Cons(_, _), Nil) => None
              _ => Some(false)
            }
            match last_step {
              None => None
              Some(last_step) =>
                match builder_hints(database, clause) {
                  None => None
                  Some(hints) => {
                    let step = Step::{
                      id: database.next,
                      clause: @core.map(clause, fn(value) { value.source }),
                      hints,
                    }
                    match last_step {
                      true =>
                        Some({ steps: @core.reverse(Cons(step, reversed)), })
                      false =>
                        visit(
                          tail,
                          add(database, step.id, Terms(clause)),
                          Cons(step, reversed),
                        )
                    }
                  }
                }
            }
          }
        }
    }
  }
  match proof {
    Rup(steps) => visit(steps, input.database, Nil)
  }
}

///|
pub fn build(cnf : @sat.Cnf, proof : @cdcl.Proof) -> Certificate? {
  build_prepared(prepare(cnf), proof)
}
