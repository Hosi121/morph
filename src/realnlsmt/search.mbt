///|
fn start_with_mode(
  problem : Problem,
  mode : TheoryMode,
  boolean_mode : BooleanMode,
) -> Search {
  let formula = cnf(problem)
  {
    problem,
    mode,
    boolean_mode,
    restarts: Zero,
    formula,
    lemmas_rev: Nil,
    phase: Boolean(@cdcl.start(formula)),
    transitions: Zero,
  }
}

///|
/// Default theory search stops at an exact model and omits cylinders whose
/// truth is established over the whole parent cell. CDCL learned clauses,
/// trail and watches survive checked theory-clause additions. Projection
/// remains global.
pub fn start(problem : Problem) -> Search {
  start_with_mode(problem, PrunedCad, Retained)
}

///|
/// Reference with pruned CAD but a fresh CDCL search after each theory conflict.
pub fn start_restarting(problem : Problem) -> Search {
  start_with_mode(problem, PrunedCad, Restarting)
}

///|
/// Reference search constructs the full CAD for each Boolean candidate.
/// Theory clauses persist across candidates. This full-CAD reference restarts
/// CDCL after a theory conflict, as does start_restarting.
pub fn start_full(problem : Problem) -> Search {
  start_with_mode(problem, FullCad, Restarting)
}

///|
fn start_theory(mode : TheoryMode, problem : @cad.Problem) -> TheorySolver {
  match mode {
    FullCad => FullSolver(@cad.start(problem))
    PrunedCad => PrunedSolver(@cad.start_search(problem))
  }
}

///|
fn advance_theory(solver : TheorySolver) -> Result[TheoryProgress, SmtError] {
  match solver {
    FullSolver(machine) =>
      match @cad.step(machine) {
        Err(error) => Err(CadFailure(error))
        Ok(Paused(next)) => Ok(Working(FullSolver(next)))
        Ok(Complete(decomposition)) =>
          match @cad.witness(decomposition) {
            Err(error) => Err(CadFailure(error))
            Ok(Some(point)) => Ok(Found(point))
            Ok(None) => Ok(Rejected(decomposition))
          }
      }
    PrunedSolver(search) =>
      match @cad.search_step(search) {
        Err(error) => Err(CadFailure(error))
        Ok(Paused(next)) => Ok(Working(PrunedSolver(next)))
        Ok(Satisfiable(point)) => Ok(Found(point))
        Ok(Unsatisfiable(decomposition)) => Ok(Rejected(decomposition))
      }
  }
}

///|
fn finish_model(
  search : Search,
  full : @sat.Model,
  point : @cad.Point,
) -> Result[Outcome, SmtError] {
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

///|
fn finish_conflict(
  search : Search,
  full : @sat.Model,
  assignment : @sat.Model,
  cursor : @cdcl.Search,
  decomposition : @cad.Decomposition,
) -> Result[Outcome, SmtError] {
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
        let formula = @core.append(search.formula, Cons(clause, Nil))
        Ok(
          Paused({
            ..search,
            formula,
            lemmas_rev: Cons(lemma, search.lemmas_rev),
            phase: Boolean(
              match search.boolean_mode {
                Restarting => @cdcl.start(formula)
                Retained => @cdcl.add_clause(cursor, clause)
              },
            ),
            restarts: match search.boolean_mode {
              Restarting => Succ(search.restarts)
              Retained => search.restarts
            },
          }),
        )
      }
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
/// Counts fresh Boolean searches caused by theory conflicts, excluding start.
pub fn boolean_restarts(search : Search) -> @core.Nat {
  search.restarts
}

///|
pub fn step(search : Search) -> Result[Outcome, SmtError] {
  let search = { ..search, transitions: Succ(search.transitions), }
  match search.phase {
    Boolean(solver) =>
      match @cdcl.run_incremental(solver, Succ(Zero)) {
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
        Satisfiable(partial, cursor) =>
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
                                cursor,
                                start_theory(search.mode, theory),
                              ),
                            }),
                          )
                      }
                  }
              }
          }
      }
    Theory(full, assignment, cursor, solver) =>
      match advance_theory(solver) {
        Err(error) => Err(error)
        Ok(Working(next)) =>
          Ok(
            Paused({ ..search, phase: Theory(full, assignment, cursor, next), }),
          )
        Ok(Found(point)) => finish_model(search, full, point)
        Ok(Rejected(decomposition)) =>
          finish_conflict(search, full, assignment, cursor, decomposition)
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
