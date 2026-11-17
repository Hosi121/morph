///|
#derive(Eq, Debug)
pub struct Node {
  remaining : @core.Nat
  choose : @core.Nat
  prefix : @core.Chain[Bool]
}

///|
pub extend Node with Eq::{equal, not_equal}

///|
pub extend Node with Debug::{to_repr}

///|
/// Immutable continuation of exact, increasing-Hamming-weight enumeration.
/// Fuel counts candidate vectors tested, not recursion nodes or field ops.
#derive(Eq, Debug)
pub struct DistanceState {
  source : Code
  axis : Axis
  next_weight : @core.Nat
  frontier : @core.Chain[Node]
  checked : @core.Nat
}

///|
pub extend DistanceState with Eq::{equal, not_equal}

///|
pub extend DistanceState with Debug::{to_repr}

///|
#derive(Eq, Debug)
pub(all) struct DistanceWitness {
  source : Code
  axis : Axis
  vector : @core.Chain[Bool]
  distance : @core.Nat
}

///|
pub extend DistanceWitness with Eq::{equal, not_equal}

///|
pub extend DistanceWitness with Debug::{to_repr}

///|
#derive(Eq, Debug)
pub(all) enum DistanceSearch {
  Paused(DistanceState)
  Found(DistanceWitness)
  NoLogical
}

///|
pub extend DistanceSearch with Eq::{equal, not_equal}

///|
pub extend DistanceSearch with Debug::{to_repr}

///|
fn frontier(n : @core.Nat, weight : @core.Nat) -> @core.Chain[Node] {
  Cons({ remaining: n, choose: weight, prefix: Nil, }, Nil)
}

///|
pub fn start_distance(code : Code, axis : Axis) -> DistanceState {
  let next_weight = @core.Succ(@core.Zero)
  {
    source: code,
    axis,
    next_weight,
    frontier: frontier(parameters(code).physical, next_weight),
    checked: Zero,
  }
}

///|
/// Number of candidates already tested and weight of the active layer.
pub fn progress(state : DistanceState) -> (@core.Nat, @core.Nat) {
  (state.checked, state.next_weight)
}

///|
fn next_candidate(
  nodes : @core.Chain[Node],
) -> (@core.Chain[Bool], @core.Chain[Node])? {
  match nodes {
    Nil => None
    Cons(node, rest) =>
      match @core.compare(node.choose, node.remaining) {
        Greater => next_candidate(rest)
        _ =>
          match (node.remaining, node.choose) {
            (_, Zero) =>
              Some(
                (
                  @core.reverse_onto(
                    node.prefix,
                    @core.replicate(node.remaining, false),
                  ),
                  rest,
                ),
              )
            (Succ(left), Succ(chosen)) =>
              next_candidate(
                Cons(
                  {
                    remaining: left,
                    choose: node.choose,
                    prefix: Cons(false, node.prefix),
                  },
                  Cons(
                    {
                      remaining: left,
                      choose: chosen,
                      prefix: Cons(true, node.prefix),
                    },
                    rest,
                  ),
                ),
              )
            _ => next_candidate(rest)
          }
      }
  }
}

///|
fn next_layer(state : DistanceState) -> DistanceState {
  let next_weight = @core.Succ(state.next_weight)
  {
    ..state,
    next_weight,
    frontier: frontier(parameters(state.source).physical, next_weight),
  }
}

///|
/// Exact exhaustive search, resumable after every candidate. k=0 returns
/// NoLogical (distance absent), including with zero fuel. Paused is never a
/// distance or a lower-bound certificate. Worst-case work is exponential.
pub fn run_distance(state : DistanceState, fuel : @core.Nat) -> DistanceSearch {
  let p = parameters(state.source)
  match
    @core.is_zero(p.logical) ||
    @core.compare(state.next_weight, p.physical) is Greater {
    true => NoLogical
    false =>
      match next_candidate(state.frontier) {
        None => run_distance(next_layer(state), fuel)
        Some((vector, rest)) =>
          match fuel {
            Zero => Paused(state)
            Succ(remaining) => {
              let next = {
                ..state,
                frontier: rest,
                checked: Succ(state.checked),
              }
              match is_logical(state.source, state.axis, vector) {
                Some(true) =>
                  Found({
                    source: state.source,
                    axis: state.axis,
                    vector,
                    distance: state.next_weight,
                  })
                _ => run_distance(next, remaining)
              }
            }
          }
      }
  }
}

///|
/// An explicit source-bound replay continuation for a claimed minimum.
#derive(Eq, Debug)
pub struct CheckState {
  search : DistanceState
  witness : DistanceWitness
}

///|
pub extend CheckState with Eq::{equal, not_equal}

///|
pub extend CheckState with Debug::{to_repr}

///|
#derive(Eq, Debug)
pub(all) enum DistanceCheck {
  CheckPaused(CheckState)
  Verified
  Rejected
}

///|
pub extend DistanceCheck with Eq::{equal, not_equal}

///|
pub extend DistanceCheck with Debug::{to_repr}

///|
/// Replay all candidates of strictly smaller weight. A vector itself is a
/// short nontrivial-logical witness; minimum distance requires this additional
/// exponential exclusion check. Fuel has the same candidate units as search.
pub fn resume_check(state : CheckState, fuel : @core.Nat) -> DistanceCheck {
  let search = state.search
  match @core.compare(search.next_weight, state.witness.distance) {
    Equal | Greater => Verified
    Less =>
      match next_candidate(search.frontier) {
        None => resume_check({ ..state, search: next_layer(search), }, fuel)
        Some((vector, rest)) =>
          match fuel {
            Zero => CheckPaused(state)
            Succ(remaining) =>
              match is_logical(search.source, search.axis, vector) {
                Some(true) => Rejected
                _ =>
                  resume_check(
                    {
                      ..state,
                      search: {
                        ..search,
                        frontier: rest,
                        checked: Succ(search.checked),
                      },
                    },
                    remaining,
                  )
              }
          }
      }
  }
}

///|
/// Verify source, axis, width, nontriviality and weight before minimum replay.
/// Zero fuel can reject malformed witnesses or verify distance one immediately.
pub fn check_distance(
  code : Code,
  axis : Axis,
  witness : DistanceWitness,
  fuel : @core.Nat,
) -> DistanceCheck {
  match
    witness.source.equal(code) &&
    witness.axis.equal(axis) &&
    !@core.is_zero(witness.distance) &&
    witness.distance.equal(weight(witness.vector)) &&
    is_logical(code, axis, witness.vector).equal(Some(true)) {
    false => Rejected
    true => resume_check({ search: start_distance(code, axis), witness, }, fuel)
  }
}
