///|
fn step_node(problem : Problem, node : Node) -> Result[NodeProgress, CadError] {
  match node {
    Pending(point, Nil) =>
      match evaluate_formula(point, problem.formula) {
        Ok(value) => Ok(Finished(Leaf(value)))
        Err(error) => Err(error)
      }
    Pending(point, Cons(level, _) as levels) =>
      match prepare_fibre(point, level.family) {
        Err(error) => Err(error)
        Ok(fibre) =>
          match @tower.isolate(fibre.system) {
            Err(error) => Err(TowerFailure(error))
            Ok(state) => Ok(Working(Isolating(point, levels, fibre, state)))
          }
      }
    Isolating(point, levels, fibre, state) =>
      match @tower.advance(state, Succ(Zero)) {
        Err(error) => Err(TowerFailure(error))
        Ok(Paused(next)) => Ok(Working(Isolating(point, levels, fibre, next)))
        Ok(Isolated(solution)) =>
          Ok(
            Working(
              Separating(
                point,
                levels,
                fibre,
                @tower.solution_certificate(solution),
                @tower.roots(solution),
              ),
            ),
          )
      }
    Separating(point, levels, fibre, proof, roots) =>
      match separate_once(roots) {
        Err(error) => Err(error)
        Ok(Some(next)) =>
          Ok(Working(Separating(point, levels, fibre, proof, next)))
        Ok(None) => {
          let updated : @tower.SolutionCertificate = {
            ..proof,
            roots: @core.map(roots, @tower.root_certificate),
          }
          match samples(updated.roots) {
            None => Err(InternalInvariant)
            Some(pending) =>
              Ok(Working(Sampling(point, levels, fibre, updated, pending, Nil)))
          }
        }
      }
    Sampling(_, _, _, proof, Nil, finished) =>
      Ok(Finished(Stack(proof, @core.reverse(finished))))
    Sampling(
      point,
      Cons(_, rest) as levels,
      fibre,
      proof,
      Cons(sample, pending),
      finished
    ) =>
      match (classify(fibre, sample), extend_point(point, fibre, sample)) {
        (Ok(signs), Ok(next)) =>
          Ok(
            Working(
              Descending(
                point,
                levels,
                fibre,
                proof,
                pending,
                finished,
                sample,
                signs,
                Pending(next, rest),
              ),
            ),
          )
        (Err(error), _) | (_, Err(error)) => Err(error)
      }
    Sampling(_, Nil, _, _, Cons(_, _), _) => Err(InternalInvariant)
    Descending(
      point,
      levels,
      fibre,
      proof,
      pending,
      finished,
      sample,
      signs,
      child
    ) =>
      match step_node(problem, child) {
        Err(error) => Err(error)
        Ok(Working(next)) =>
          Ok(
            Working(
              Descending(
                point, levels, fibre, proof, pending, finished, sample, signs, next,
              ),
            ),
          )
        Ok(Finished(subtree)) =>
          Ok(
            Working(
              Sampling(
                point,
                levels,
                fibre,
                proof,
                pending,
                Cons({ sample, signs, subtree, }, finished),
              ),
            ),
          )
      }
  }
}

///|
pub fn start(problem : Problem) -> Machine {
  {
    problem,
    node: Pending(
      rational_point(Nil),
      @core.drop(Succ(Zero), problem.projection.levels),
    ),
  }
}

///|
pub fn step(state : Machine) -> Result[Progress, CadError] {
  match step_node(state.problem, state.node) {
    Err(error) => Err(error)
    Ok(Working(node)) => Ok(Paused({ ..state, node, }))
    Ok(Finished(tree)) => {
      let proof : Certificate = {
        arity: state.problem.arity,
        formula: state.problem.formula,
        projection: state.problem.projection,
        tree,
      }
      // The public checker is also available for untrusted serialized proof
      // values. Generation builds all records through checked tower APIs.
      Ok(Complete({ problem: state.problem, proof, }))
    }
  }
}

///|
/// Fuel counts outer transitions. A transition contains exact field, PRS or
/// projection work; it is not a fixed real-time or allocation budget.
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
