///|
priv enum Separation {
  Ready
  Changed(@core.Chain[@sturm.Interval])
  Failed
}

///|
fn separate(
  system : @sturm.System,
  roots : @core.Chain[@sturm.Interval],
) -> Separation {
  match roots {
    Cons(a, Cons(b, rest)) =>
      match @exact.rational_compare(a.upper, b.lower) {
        Greater => Failed
        Equal =>
          match @sturm.refine(system, b, Succ(Zero)) {
            None => Failed
            Some(narrower) => Changed(Cons(a, Cons(narrower, rest)))
          }
        Less =>
          match separate(system, Cons(b, rest)) {
            Changed(tail) => Changed(Cons(a, tail))
            Ready => Ready
            Failed => Failed
          }
      }
    _ => Ready
  }
}

///|
pub fn start(problem : Problem) -> Machine {
  { problem, phase: Isolating(@sturm.isolate(problem.system)), }
}

///|
/// One isolation node, one gap-refinement step, or one sign-cell construction.
/// Exact polynomial/rational work within a step has input-dependent cost.
pub fn step(state : Machine) -> Progress {
  match state.phase {
    Isolating(isolation) =>
      match @sturm.advance(isolation, Succ(Zero)) {
        Paused(next) => Paused({ ..state, phase: Isolating(next), })
        Isolated(roots) => Paused({ ..state, phase: Separating(roots), })
      }
    Separating(roots) =>
      match separate(state.problem.system, roots) {
        Failed => Fault
        Changed(roots) => Paused({ ..state, phase: Separating(roots), })
        Ready =>
          Paused({ ..state, phase: Sampling(roots, samples(roots), Nil), })
      }
    Sampling(roots, pending, accepted) =>
      match pending {
        Nil =>
          Complete({
            problem: state.problem,
            certificate: { roots, cells: @core.reverse(accepted), },
          })
        Cons(sample, rest) =>
          match classify(state.problem, sample) {
            None => Fault
            Some(cell) =>
              Paused({
                ..state,
                phase: Sampling(roots, rest, Cons(cell, accepted)),
              })
          }
      }
  }
}

///|
pub fn run(state : Machine, fuel : @core.Nat) -> Progress {
  match fuel {
    Zero => Paused(state)
    Succ(rest) =>
      match step(state) {
        Paused(next) => run(next, rest)
        result => result
      }
  }
}
