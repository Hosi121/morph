///|
pub fn start(problem : Problem) -> Search {
  let formula = cnf(problem)
  {
    problem,
    formula,
    lemmas_rev: Nil,
    phase: Boolean(@cdcl.start(formula)),
    transitions: Zero,
  }
}

///|
pub fn transitions(search : Search) -> @core.Nat {
  search.transitions
}

///|
pub fn theory_conflicts(search : Search) -> @core.Nat {
  @core.length(search.lemmas_rev)
}

///|
pub fn step(search : Search) -> Result[Outcome, SmtError] {
  let search = { ..search, transitions: Succ(search.transitions), }
  match search.phase {
    Boolean(solver) =>
      match @cdcl.run(solver, Succ(Zero)) {
        Paused(solver) => Ok(Paused({ ..search, phase: Boolean(solver), }))
        InvariantViolation => Err(InternalInvariant)
        Unsatisfiable(propositional) => {
          let proof = Refutation::{
            context: context(search.problem),
            lemmas: @core.reverse(search.lemmas_rev),
            propositional,
          }
          if check_refutation(search.problem, proof) {
            Ok(Unsatisfiable(proof))
          } else {
            Err(InternalInvariant)
          }
        }
        Satisfiable(partial) =>
          match complete_boolean(search.formula, partial) {
            None => Err(InternalInvariant)
            Some(full) =>
              match source_assignment(search.problem, full) {
                None => Err(InternalInvariant)
                Some(assignment) =>
                  match signed_formula(search.problem, assignment) {
                    None => Err(InternalInvariant)
                    Some(signed) =>
                      match @cad.prepare(arity(search.problem), signed) {
                        Err(error) => Err(CadFailure(error))
                        Ok(theory) =>
                          Ok(
                            Paused({
                              ..search,
                              phase: Theory(
                                full,
                                assignment,
                                theory,
                                @cad.start(theory),
                              ),
                            }),
                          )
                      }
                  }
              }
          }
      }
    Theory(full, assignment, theory, machine) =>
      match @cad.step(machine) {
        Err(error) => Err(CadFailure(error))
        Ok(Paused(next)) =>
          Ok(
            Paused({ ..search, phase: Theory(full, assignment, theory, next), }),
          )
        Ok(Complete(decomposition)) =>
          match @cad.witness(decomposition) {
            Err(error) => Err(CadFailure(error))
            Ok(Some(point)) => {
              let model = Model::{
                context: context(search.problem),
                booleans: full,
                point,
              }
              if check_model(search.problem, model) {
                Ok(Satisfiable(model))
              } else {
                Err(InternalInvariant)
              }
            }
            Ok(None) => {
              let lemma = Lemma::{
                context: context(search.problem),
                assignment,
                decomposition: @cad.certificate(decomposition),
              }
              match lemma_clause(search.problem, lemma) {
                None => Err(InternalInvariant)
                Some(clause) =>
                  if @sat.check_model(Cons(clause, Nil), full) {
                    Err(InternalInvariant)
                  } else {
                    let formula = @core.append(
                      search.formula,
                      Cons(clause, Nil),
                    )
                    Ok(
                      Paused({
                        ..search,
                        formula,
                        lemmas_rev: Cons(lemma, search.lemmas_rev),
                        phase: Boolean(@cdcl.start(formula)),
                      }),
                    )
                  }
              }
            }
          }
      }
  }
}

///|
/// Fuel counts outer phase transitions. A CAD transition, projection setup,
/// certificate validation, or CDCL transition is exact but not constant time.
/// Errors and exhausted fuel are never translated to UNSAT.
pub fn run(search : Search, fuel : @core.Nat) -> Result[Outcome, SmtError] {
  match fuel {
    Zero => Ok(Paused(search))
    Succ(rest) =>
      match step(search) {
        Ok(Paused(next)) => run(next, rest)
        result => result
      }
  }
}
