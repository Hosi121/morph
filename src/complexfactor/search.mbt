///|
#derive(Debug)
enum Phase {
  Between(@core.Chain[@zassenhaus.Factor])
  Solving(@complexroots.Search, @core.Chain[@zassenhaus.Factor])
}

///|
pub extend Phase with Debug::{to_repr}

///|
#derive(Debug)
pub struct Search {
  problem : Problem
  phase : Phase
  completed : @core.Chain[@complexroots.RootSet]
}

///|
pub extend Search with Debug::{to_repr}

///|
#derive(Debug)
pub(all) enum Progress {
  Complete(RootFamily)
  Paused(Search, @complexroots.PauseReason)
}

///|
pub extend Progress with Debug::{to_repr}

///|
pub fn start(problem : Problem) -> Search {
  { problem, phase: Between(problem.factorization.factors), completed: Nil, }
}

///|
/// Each call delegates the supplied attempts/fuel budget separately to each
/// factor it reaches. A paused factor keeps its exact bare Search, and completed
/// factor groups are retained. Neither these budgets nor certificate checks
/// promise a wall-time bound. Preparation/factorization is separately bounded.
pub fn run(
  state : Search,
  attempts : @core.Nat,
  fuel : @core.Nat,
) -> Result[Progress, RootError] {
  match state.phase {
    Between(Nil) =>
      match assemble(state.problem, @core.reverse(state.completed)) {
        None => Err(InternalInvariant)
        Some(value) => Ok(Complete(value))
      }
    Between(Cons(factor, rest)) =>
      match @complexroots.prepare(factor_polynomial(factor)) {
        Err(error) => Err(RootFailure(error))
        Ok(problem) =>
          run(
            { ..state, phase: Solving(@complexroots.start(problem), rest), },
            attempts,
            fuel,
          )
      }
    Solving(job, rest) =>
      match @complexroots.run(job, attempts, fuel) {
        Err(error) => Err(RootFailure(error))
        Ok(Paused(next, reason)) =>
          Ok(Paused({ ..state, phase: Solving(next, rest), }, reason))
        Ok(Complete(group)) =>
          run(
            {
              ..state,
              phase: Between(rest),
              completed: Cons(group, state.completed),
            },
            attempts,
            fuel,
          )
      }
  }
}
