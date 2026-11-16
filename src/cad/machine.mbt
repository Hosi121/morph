///|
fn step_node(
  problem : Problem,
  node : Node,
  searching : Bool,
) -> Result[NodeProgress, CadError] {
  match node {
    Pending(point, levels, parent_signs) => {
      let partial = if searching {
        @prefix.evaluate(
          problem.prefix,
          @core.length(point.coordinates),
          parent_signs,
        )
      } else {
        Ok(@prefix.Undetermined)
      }
      match partial {
        Err(error) => Err(PrefixFailure(error))
        Ok(Known(false)) => Ok(Finished(Leaf(false)))
        Ok(Known(true)) => {
          let candidate = complete_point(point, @core.length(levels))
          if check_witness(problem, candidate) {
            Ok(Found(candidate))
          } else {
            Err(InternalInvariant)
          }
        }
        Ok(Undetermined) =>
          match levels {
            Nil =>
              match evaluate_formula(point, problem.formula) {
                Ok(true) =>
                  if searching {
                    Ok(Found(point))
                  } else {
                    Ok(Finished(Leaf(true)))
                  }
                Ok(false) => Ok(Finished(Leaf(false)))
                Err(error) => Err(error)
              }
            Cons(level, _) =>
              match prepare_fibre(point, level.family) {
                Err(error) => Err(error)
                Ok(fibre) =>
                  match @tower.isolate(fibre.system) {
                    Err(error) => Err(TowerFailure(error))
                    Ok(state) =>
                      Ok(Working(Isolating(point, levels, fibre, state)))
                  }
              }
          }
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
                Pending(next, rest, signs),
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
      match step_node(problem, child, searching) {
        Err(error) => Err(error)
        Ok(Found(point)) => Ok(Found(point))
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
      Nil,
    ),
  }
}

///|
pub fn step(state : Machine) -> Result[Progress, CadError] {
  match step_node(state.problem, state.node, false) {
    Err(error) => Err(error)
    Ok(Found(_)) => Err(InternalInvariant)
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

///|
/// Full Collins projection is shared with start; lifting is demand driven.
/// A false constant cylinder is recorded as a shortened checked leaf. A true
/// cylinder returns a full exact point, without constructing unused siblings.
pub fn start_search(problem : Problem) -> Search {
  {
    problem,
    node: Pending(
      rational_point(Nil),
      @core.drop(Succ(Zero), problem.projection.levels),
      Nil,
    ),
  }
}

///|
pub fn search_step(state : Search) -> Result[SearchProgress, CadError] {
  match step_node(state.problem, state.node, true) {
    Err(error) => Err(error)
    Ok(Working(node)) => Ok(Paused({ ..state, node, }))
    Ok(Found(point)) => Ok(Satisfiable(point))
    Ok(Finished(tree)) => {
      let proof : Certificate = {
        arity: state.problem.arity,
        formula: state.problem.formula,
        projection: state.problem.projection,
        tree,
      }
      Ok(Unsatisfiable({ problem: state.problem, proof, }))
    }
  }
}

///|
/// Fuel counts transitions, not fixed time. Paused or errors never imply UNSAT.
pub fn search_run(
  state : Search,
  fuel : @core.Nat,
) -> Result[SearchProgress, CadError] {
  match fuel {
    Zero => Ok(Paused(state))
    Succ(rest) =>
      match search_step(state) {
        Ok(Paused(next)) => search_run(next, rest)
        result => result
      }
  }
}
