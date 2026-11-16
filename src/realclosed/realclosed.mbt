///|
#derive(Eq, Debug)
pub(all) enum SolverError {
  FormulaFailure(@logic.BuildError)
  CadFailure(@cad.CadError)
  InvalidCertificate
}

///|
pub extend SolverError with Eq::{equal, not_equal}

///|
pub extend SolverError with Debug::{to_repr}

///|
#derive(Debug)
pub struct Problem {
  normal : @logic.Prenex
  cad : @cad.Problem
}

///|
pub extend Problem with Debug::{to_repr}

///|
#derive(Eq, Debug)
pub(all) struct Certificate {
  normalization : @logic.Certificate
  elimination : @cad.EliminationCertificate
}

///|
pub extend Certificate with Eq::{equal, not_equal}

///|
pub extend Certificate with Debug::{to_repr}

///|
#derive(Debug)
pub struct Solution {
  problem : Problem
  value : @cad.Elimination
}

///|
pub extend Solution with Debug::{to_repr}

///|
#derive(Debug)
pub struct Machine {
  problem : Problem
  state : @cad.Machine
}

///|
pub extend Machine with Debug::{to_repr}

///|
#derive(Debug)
pub(all) enum Progress {
  Complete(Solution)
  Paused(Machine)
}

///|
pub extend Progress with Debug::{to_repr}

///|
/// At lexical depth d, atom polynomials have free_variables+d variables.
/// A quantifier appends a new local variable. Sibling binders are renamed to
/// fresh distinct global slots before the prefix is hoisted.
pub fn prepare(
  free_variables : @core.Nat,
  formula : @logic.Formula,
) -> Result[Problem, SolverError] {
  match @logic.normalize(free_variables, formula) {
    Err(error) => Err(FormulaFailure(error))
    Ok(normal) =>
      match @cad.prepare(@logic.variables(normal), @logic.matrix(normal)) {
        Ok(cad) => Ok({ normal, cad, })
        Err(error) => Err(CadFailure(error))
      }
  }
}

///|
pub fn source(problem : Problem) -> @logic.Formula {
  @logic.source(problem.normal)
}

///|
pub fn free_variables(problem : Problem) -> @core.Nat {
  @logic.free_variables(problem.normal)
}

///|
pub fn prenex(problem : Problem) -> @logic.Prenex {
  problem.normal
}

///|
pub fn start(problem : Problem) -> Machine {
  { problem, state: @cad.start(problem.cad), }
}

///|
/// The continuation is persistent. Fuel bounds CAD transitions, not exact
/// field work within one transition or preparation's projection computation.
pub fn run(state : Machine, fuel : @core.Nat) -> Result[Progress, SolverError] {
  match @cad.run(state.state, fuel) {
    Err(error) => Err(CadFailure(error))
    Ok(Paused(next)) => Ok(Paused({ ..state, state: next, }))
    Ok(Complete(decomposition)) =>
      match
        @cad.eliminate(
          decomposition,
          @logic.free_variables(state.problem.normal),
          @logic.quantifiers(state.problem.normal),
        ) {
        Ok(value) => Ok(Complete({ problem: state.problem, value, }))
        Err(error) => Err(CadFailure(error))
      }
  }
}

///|
pub fn quantifier_free(value : Solution) -> @qf.Formula {
  @cad.quantifier_free(value.value)
}

///|
/// Returns None if free variables remain. Complete closed sentences always
/// produce Truth; unfinished computations cannot be passed as Solution.
pub fn truth(value : Solution) -> Bool? {
  match (@logic.free_variables(value.problem.normal), quantifier_free(value)) {
    (Zero, Truth(answer)) => Some(answer)
    _ => None
  }
}

///|
pub fn certificate(value : Solution) -> Certificate {
  {
    normalization: @logic.certificate(value.problem.normal),
    elimination: @cad.elimination_certificate(value.value),
  }
}

///|
/// Revalidates both transformations against the caller's original source.
/// Geometric and arithmetic checkers recompute exact decisions; they do not
/// constitute a machine-checked proof of the entire RCF implementation.
pub fn check(
  free_variables : @core.Nat,
  formula : @logic.Formula,
  proof : Certificate,
) -> Solution? {
  match @logic.check(free_variables, formula, proof.normalization) {
    None => None
    Some(normal) =>
      match @cad.prepare(@logic.variables(normal), @logic.matrix(normal)) {
        Err(_) => None
        Ok(cad) =>
          match
            @cad.check_elimination(
              cad,
              @logic.free_variables(normal),
              @logic.quantifiers(normal),
              proof.elimination,
            ) {
            Some(value) => Some({ problem: { normal, cad, }, value, })
            None => None
          }
      }
  }
}

///|
pub fn check_result(
  free_variables : @core.Nat,
  formula : @logic.Formula,
  value : Solution,
  proof : Certificate,
) -> Bool {
  certificate(value).equal(proof) &&
  @logic.free_variables(value.problem.normal).equal(free_variables) &&
  @logic.source(value.problem.normal).equal(formula) &&
  check(free_variables, formula, proof) is Some(_)
}
