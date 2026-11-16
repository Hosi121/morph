///|
priv struct Preparing {
  database_rev : Database
  variables : Lits
  seen : Index[Bool]
}

///|
/// Convert each source literal once. Continue collecting variables after a
/// tautology so the returned model domain matches the original CNF.
fn prepared_clause(
  source : @sat.Clause,
  normalized : Lits?,
  known : Lits,
  seen : Index[Bool],
) -> (Lits?, Lits, Index[Bool]) {
  match source {
    Nil => {
      let normalized = match normalized {
        None => None
        Some(reversed) => Some(@core.reverse(reversed))
      }
      (normalized, known, seen)
    }
    Cons(source, rest) => {
      let literal = atom(source)
      let normalized = match normalized {
        None => None
        Some(reversed) =>
          match contains(reversed, opposite(literal)) {
            true => None
            false =>
              match contains(reversed, literal) {
                true => normalized
                false => Some(Cons(literal, reversed))
              }
          }
      }
      match index_get(seen, @binary.bits(literal.key)) {
        Some(_) => prepared_clause(rest, normalized, known, seen)
        None =>
          prepared_clause(
            rest,
            normalized,
            Cons(literal, known),
            index_put(seen, @binary.bits(literal.key), true),
          )
      }
    }
  }
}

///|
fn indexed_prepare(cnf : @sat.Cnf) -> (Database, Lits) {
  let initial = Preparing::{ database_rev: Nil, variables: Nil, seen: Empty, }
  let prepared = @core.fold_left(cnf, initial, fn(prepared, clause) {
    let (normalized, variables, seen) = prepared_clause(
      clause,
      Some(Nil),
      prepared.variables,
      prepared.seen,
    )
    let database_rev = match normalized {
      None => prepared.database_rev
      Some(clause) => Cons(clause, prepared.database_rev)
    }
    Preparing::{ database_rev, variables, seen, }
  })
  (@core.reverse(prepared.database_rev), prepared.variables)
}

///|
fn start_prepared(cnf : @sat.Cnf) -> Search {
  let (clauses, labels) = indexed_prepare(cnf)
  Search::{
    database: clauses,
    variables: labels,
    watch: None,
    trail: Nil,
    level: Zero,
    proof_rev: Nil,
    statistics: empty_statistics(),
  }
}
