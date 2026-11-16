///|
fn samples(intervals : @core.Chain[@sturm.Interval]) -> @core.Chain[Sample]? {
  fn after(
    left : @sturm.Interval,
    rest : @core.Chain[@sturm.Interval],
  ) -> @core.Chain[Sample]? {
    match rest {
      Nil =>
        Some(
          Cons(
            RationalPoint(
              @exact.rational_add(left.upper, @exact.rational_one()),
            ),
            Nil,
          ),
        )
      Cons(right, tail) =>
        match @exact.rational_compare(left.upper, right.lower) {
          Less =>
            match after(right, tail) {
              Some(following) =>
                Some(
                  Cons(
                    RationalPoint(
                      @exact.rational_half(
                        @exact.rational_add(left.upper, right.lower),
                      ),
                    ),
                    Cons(AlgebraicPoint(right), following),
                  ),
                )
              None => None
            }
          _ => None
        }
    }
  }
  match intervals {
    Nil => Some(Cons(RationalPoint(@exact.rational_zero()), Nil))
    Cons(first, rest) =>
      match after(first, rest) {
        Some(following) =>
          Some(
            Cons(
              RationalPoint(
                @exact.rational_subtract(first.lower, @exact.rational_one()),
              ),
              Cons(AlgebraicPoint(first), following),
            ),
          )
        None => None
      }
  }
}

///|
fn separate_once(
  roots : @core.Chain[@ordered.Root],
) -> Result[@core.Chain[@ordered.Root]?, CadError] {
  match roots {
    Nil | Cons(_, Nil) => Ok(None)
    Cons(left, Cons(right, rest)) => {
      let a = @ordered.root_interval(left)
      let b = @ordered.root_interval(right)
      match @exact.rational_compare(a.upper, b.lower) {
        Less =>
          match separate_once(Cons(right, rest)) {
            Ok(Some(tail)) => Ok(Some(Cons(left, tail)))
            Ok(None) => Ok(None)
            Err(error) => Err(error)
          }
        _ =>
          match @ordered.refine(right, Succ(Zero)) {
            Ok(refined) => Ok(Some(Cons(left, Cons(refined, rest))))
            Err(error) => Err(OrderedFailure(error))
          }
      }
    }
  }
}

///|
pub fn start(problem : Problem) -> Result[Machine, CadError] {
  match @ordered.isolate(problem.system) {
    Ok(state) => Ok({ problem, phase: Isolating(state), })
    Err(error) => Err(OrderedFailure(error))
  }
}

///|
pub fn step(state : Machine) -> Result[Progress, CadError] {
  match state.phase {
    Isolating(job) =>
      match @ordered.advance(job, Succ(Zero)) {
        Err(error) => Err(OrderedFailure(error))
        Ok(Paused(next)) => Ok(Paused({ ..state, phase: Isolating(next), }))
        Ok(Isolated(solutions)) =>
          Ok(
            Paused({
              ..state,
              phase: Separating(
                @ordered.solution_certificate(solutions),
                @ordered.roots(solutions),
              ),
            }),
          )
      }
    Separating(proof, roots) =>
      match separate_once(roots) {
        Err(error) => Err(error)
        Ok(Some(next)) =>
          Ok(Paused({ ..state, phase: Separating(proof, next), }))
        Ok(None) => {
          let updated : @ordered.SolutionCertificate = {
            ..proof,
            roots: @core.map(roots, @ordered.root_certificate),
          }
          match samples(@core.map(roots, @ordered.root_interval)) {
            Some(pending) =>
              Ok(Paused({ ..state, phase: Sampling(updated, pending, Nil), }))
            None => Err(InternalInvariant)
          }
        }
      }
    Sampling(proof, pending, cells) =>
      match pending {
        Nil => {
          let candidate : Certificate = {
            isolation: proof,
            cells: @core.reverse(cells),
          }
          match check(state.problem, candidate) {
            Some(result) => Ok(Complete(result))
            None => Err(InternalInvariant)
          }
        }
        Cons(sample, rest) =>
          match classify(state.problem, sample) {
            Ok(cell) =>
              Ok(
                Paused({
                  ..state,
                  phase: Sampling(proof, rest, Cons(cell, cells)),
                }),
              )
            Err(error) => Err(error)
          }
      }
  }
}

///|
/// Fuel counts isolation, gap refinement and cell steps, not field operations
/// or elapsed time inside a step. The continuation is persistent and reusable.
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
pub fn check(problem : Problem, proof : Certificate) -> Decomposition? {
  if !@ordered.check_isolation(problem.product, proof.isolation) {
    None
  } else {
    let intervals = @core.map(proof.isolation.roots, fn(root) {
      root.count.interval
    })
    match samples(intervals) {
      None => None
      Some(expected) =>
        match map_result(expected, fn(sample) { classify(problem, sample) }) {
          Ok(cells) =>
            if cells.equal(proof.cells) {
              Some({ problem, certificate: proof, })
            } else {
              None
            }
          Err(_) => None
        }
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
pub fn cells(value : Decomposition) -> @core.Chain[Cell] {
  value.certificate.cells
}

///|
pub fn witness(value : Decomposition) -> Sample? {
  fn first(rest : @core.Chain[Cell]) -> Sample? {
    match rest {
      Nil => None
      Cons(cell, tail) =>
        if cell.holds {
          Some(cell.sample)
        } else {
          first(tail)
        }
    }
  }
  first(value.certificate.cells)
}

///|
pub fn universally_true(value : Decomposition) -> Bool {
  fn all(rest : @core.Chain[Cell]) -> Bool {
    match rest {
      Nil => true
      Cons(cell, tail) => cell.holds && all(tail)
    }
  }
  all(value.certificate.cells)
}
