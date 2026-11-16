///|
pub fn start(problem : Problem, budget : Budget) -> Machine {
  { problem, budget, phase: Base(@base.start(problem.base)), }
}

///|
pub fn rebudget(state : Machine, budget : Budget) -> Machine {
  { ..state, budget, }
}

///|
pub fn step(state : Machine) -> Result[Progress, CadError] {
  match state.phase {
    Base(job) =>
      match @base.step(job) {
        Fault => Err(BaseFailure)
        Paused(next) => Ok(Paused({ ..state, phase: Base(next), }))
        Complete(value) =>
          Ok(
            Paused({
              ..state,
              phase: Next(@base.certificate(value), @base.cells(value), Nil),
            }),
          )
      }
    Next(base, pending, completed) =>
      match pending {
        Nil => {
          let proof : Certificate = {
            formula: state.problem.formula,
            projection: state.problem.projection,
            base,
            stacks: @core.reverse(completed),
          }
          match check(state.problem, proof, state.budget.verification) {
            Some(value) => Ok(Complete(value))
            None => Err(InternalInvariant)
          }
        }
        Cons(cell, rest) =>
          match make_field(state.problem, cell.sample, state.budget) {
            Err(error) => Err(error)
            Ok(Insufficient(reason)) => Ok(NeedsBudget(state, reason))
            Ok(Ready(field, proof)) =>
              match fibre_problem(state.problem, field) {
                Err(error) => Err(error)
                Ok(problem) =>
                  match @relative.start(problem) {
                    Err(error) => Err(RelativeFailure(error))
                    Ok(job) =>
                      Ok(
                        Paused({
                          ..state,
                          phase: Lifting(
                            base,
                            rest,
                            completed,
                            cell.sample,
                            proof,
                            job,
                          ),
                        }),
                      )
                  }
              }
          }
      }
    Lifting(base, pending, completed, sample, minimal, job) =>
      match @relative.step(job) {
        Err(error) => Err(RelativeFailure(error))
        Ok(Paused(next)) =>
          Ok(
            Paused({
              ..state,
              phase: Lifting(base, pending, completed, sample, minimal, next),
            }),
          )
        Ok(Complete(value)) =>
          Ok(
            Paused({
              ..state,
              phase: Next(
                base,
                pending,
                Cons(
                  { sample, minimal, fibre: @relative.certificate(value), },
                  completed,
                ),
              ),
            }),
          )
      }
  }
}

///|
/// Fuel counts base/lift state steps. Projection, exact field arithmetic and
/// factorization inside a step are not constant-time operations.
pub fn run(state : Machine, fuel : @core.Nat) -> Result[Progress, CadError] {
  match fuel {
    Zero => Ok(Paused(state))
    Succ(rest) =>
      match step(state) {
        Ok(Paused(next)) => run(next, rest)
        other => other
      }
  }
}

///|
pub fn check(
  problem : Problem,
  proof : Certificate,
  verification : @core.Nat,
) -> Decomposition? {
  fn stacks_match(
    cells : @core.Chain[@base.Cell],
    stacks : @core.Chain[StackCertificate],
  ) -> Bool {
    match (cells, stacks) {
      (Nil, Nil) => true
      (Cons(cell, tail), Cons(stack, rest)) =>
        if !cell.sample.equal(stack.sample) {
          false
        } else {
          match
            checked_field(problem, cell.sample, stack.minimal, verification) {
            None => false
            Some(field) =>
              match fibre_problem(problem, field) {
                Err(_) => false
                Ok(fibre) =>
                  match @relative.check(fibre, stack.fibre) {
                    Some(_) => stacks_match(tail, rest)
                    None => false
                  }
              }
          }
        }
      _ => false
    }
  }
  if !problem.formula.equal(proof.formula) ||
    !problem.projection.equal(proof.projection) ||
    !@projection.check(
      CollinsProjection,
      problem.atoms,
      Succ(Zero),
      proof.projection,
    ) {
    None
  } else {
    match @base.check(problem.base, proof.base) {
      Some(base) =>
        if stacks_match(@base.cells(base), proof.stacks) {
          Some({ problem, certificate: proof, })
        } else {
          None
        }
      None => None
    }
  }
}

///|
pub fn certificate(value : Decomposition) -> Certificate {
  value.certificate
}

///|
pub fn problem_of(value : Decomposition) -> Problem {
  value.problem
}

///|
pub fn stacks(value : Decomposition) -> @core.Chain[StackCertificate] {
  value.certificate.stacks
}
