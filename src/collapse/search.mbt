///|
/// Chronological local contractions. Endpoint binding is checked at every step.
#derive(Eq, Debug)
pub(all) struct Sequence {
  source : @homology.Complex
  target : @homology.Complex
  steps : @core.Chain[Certificate]
}

///|
pub extend Sequence with Eq::{equal, not_equal}

///|
pub extend Sequence with Debug::{to_repr}

///|
/// Immutable continuation. A candidate is an ordered (lower,upper) pair from
/// the current complex. Successful deletion restarts the complete enumeration.
#derive(Eq, Debug)
pub struct Search {
  source : @homology.Complex
  current : @homology.Complex
  reverse_steps : @core.Chain[Certificate]
  lower_todo : @core.Chain[@core.Chain[@core.Nat]]
  upper_todo : @core.Chain[@core.Chain[@core.Nat]]
}

///|
pub extend Search with Eq::{equal, not_equal}

///|
pub extend Search with Debug::{to_repr}

///|
/// Stalled certifies absence of an elementary pair in this final complex.
/// It says nothing about alternative collapse choices, noncontractibility,
/// or the possibility of simplification after elementary expansions.
#derive(Eq, Debug)
pub(all) enum Progress {
  Paused(Search)
  Stalled(Sequence)
  InvalidWitness
}

///|
pub extend Progress with Eq::{equal, not_equal}

///|
pub extend Progress with Debug::{to_repr}

///|
pub fn start(source : @homology.Complex) -> Search {
  let faces = @homology.all_simplices(source)
  {
    source,
    current: source,
    reverse_steps: Nil,
    lower_todo: faces,
    upper_todo: faces,
  }
}

///|
pub fn sequence(search : Search) -> Sequence {
  {
    source: search.source,
    target: search.current,
    steps: @core.reverse(search.reverse_steps),
  }
}

///|
pub fn check_sequence(
  source : @homology.Complex,
  actual_target : @homology.Complex,
  witness : Sequence,
) -> Bool {
  fn walk(
    current : @homology.Complex,
    todo : @core.Chain[Certificate],
  ) -> Bool {
    match todo {
      Nil => current.equal(actual_target)
      Cons(step, rest) =>
        check(current, step.target, step) && walk(step.target, rest)
    }
  }
  witness.source.equal(source) &&
  witness.target.equal(actual_target) &&
  walk(source, witness.steps)
}

///|
/// Each fuel unit attempts exactly one ordered candidate pair, including
/// rejected pairs. Finishing one row of candidates consumes no extra fuel.
/// Matrix construction/checking and immutable traversal within an attempt
/// are not separately metered; this is not a wall-clock or allocation bound.
pub fn run(search : Search, fuel : @core.Nat) -> Progress {
  match (search.lower_todo, search.upper_todo) {
    (Nil, _) => Stalled(sequence(search))
    (Cons(_, rest), Nil) => {
      let next = {
        ..search,
        lower_todo: rest,
        upper_todo: @homology.all_simplices(search.current),
      }
      run(next, fuel)
    }
    (Cons(lower, _), Cons(upper, tail)) =>
      match fuel {
        Zero => Paused(search)
        Succ(remaining) => {
          let pair = Pair::{ lower, upper, }
          if is_free(search.current, pair) {
            match elementary(search.current, pair) {
              None => InvalidWitness
              Some(step) => {
                let faces = @homology.all_simplices(step.target)
                run(
                  {
                    source: search.source,
                    current: step.target,
                    reverse_steps: Cons(step, search.reverse_steps),
                    lower_todo: faces,
                    upper_todo: faces,
                  },
                  remaining,
                )
              }
            }
          } else {
            run({ ..search, upper_todo: tail, }, remaining)
          }
        }
      }
  }
}
