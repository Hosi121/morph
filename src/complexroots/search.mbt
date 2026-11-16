///|
#derive(Debug)
enum Phase {
  Constant
  Separating(@variety.SeparationSearch)
  Completing(
    @variety.SeparationCertificate,
    @core.Chain[@variety.ProjectedPoint],
    @core.Chain[Root]
  )
}

///|
pub extend Phase with Debug::{to_repr}

///|
#derive(Debug)
pub struct Search {
  problem : Problem
  phase : Phase
}

///|
pub extend Search with Debug::{to_repr}

///|
#derive(Eq, Debug)
pub(all) enum PauseReason {
  AttemptLimit
  ComputationFuel
}

///|
pub extend PauseReason with Eq::{equal, not_equal}

///|
pub extend PauseReason with Debug::{to_repr}

///|
#derive(Debug)
pub(all) enum Progress {
  Complete(RootSet)
  Paused(Search, PauseReason)
}

///|
pub extend Progress with Debug::{to_repr}

///|
pub fn start(problem : Problem) -> Search {
  {
    problem,
    phase: if degree(problem.squarefree).equal(Zero) {
      Constant
    } else {
      Separating(@variety.separation_start(problem.variety))
    },
  }
}

///|
/// Work fuel counts delegated F4/Sturm steps and completed-root multiplicity
/// jobs. A job includes exact polynomial and Tarski computations; neither a
/// step nor the final certificate check has a fixed wall-time bound.
/// Attempt fuel counts newly started separating forms, not resumed forms.
pub fn run(
  state : Search,
  attempts : @core.Nat,
  fuel : @core.Nat,
) -> Result[Progress, RootError] {
  match state.phase {
    Constant =>
      Ok(
        Complete({
          problem: state.problem,
          proof: {
            source: state.problem.source,
            separation: None,
            multiplicities: Nil,
          },
          roots: Nil,
        }),
      )
    Separating(job) =>
      match fuel {
        Zero => Ok(Paused(state, ComputationFuel))
        Succ(rest) => {
          let allowance : @core.Nat = match attempts {
            Zero => Zero
            Succ(_) => Succ(Zero)
          }
          match @variety.separation_advance(job, allowance, Succ(Zero)) {
            Err(error) => Err(VarietyFailure(error))
            Ok(SeparationNoSolutions(_)) => Err(InternalInvariant)
            Ok(SeparationPaused(next, reason)) => {
              let remaining = if @variety.attempted(next).equal(
                  @variety.attempted(job),
                ) {
                attempts
              } else {
                match attempts {
                  Zero => Zero
                  Succ(tail) => tail
                }
              }
              let updated : Search = { ..state, phase: Separating(next), }
              match (reason, remaining) {
                (AttemptLimit, Zero) => Ok(Paused(updated, AttemptLimit))
                _ => run(updated, remaining, rest)
              }
            }
            Ok(Separated(value)) =>
              match @variety.projected_points(value) {
                Err(error) => Err(VarietyFailure(error))
                Ok(points) =>
                  run(
                    {
                      ..state,
                      phase: Completing(
                        @variety.separation_certificate(value),
                        points,
                        Nil,
                      ),
                    },
                    attempts,
                    rest,
                  )
              }
          }
        }
      }
    Completing(separation, pending, accepted) =>
      match pending {
        Nil => {
          let roots = @core.reverse(accepted)
          let proof : Certificate = {
            source: state.problem.source,
            separation: Some(separation),
            multiplicities: @core.map(roots, fn(root) { root.multiplicity }),
          }
          let value : RootSet = { problem: state.problem, proof, roots, }
          if check_result(state.problem.source, value, proof) {
            Ok(Complete(value))
          } else {
            Err(InternalInvariant)
          }
        }
        Cons(point, tail) =>
          match fuel {
            Zero => Ok(Paused(state, ComputationFuel))
            Succ(rest) =>
              match produce_multiplicity(state.problem.source, point) {
                None => Err(InternalInvariant)
                Some(multiplicity) =>
                  run(
                    {
                      ..state,
                      phase: Completing(
                        separation,
                        tail,
                        Cons(
                          { source: state.problem.source, point, multiplicity, },
                          accepted,
                        ),
                      ),
                    },
                    attempts,
                    rest,
                  )
              }
          }
      }
  }
}
