///|
/// An immutable suspended reduction. Construction is restricted to start/run.
/// A paused state carries no accepted homology result.
#derive(Eq, Debug)
pub struct State {
  source : Filtration
  remaining : @core.Chain[@core.Chain[@core.Nat]]
  reduced_rev : @core.Chain[@core.Chain[@core.Nat]]
  change_rev : @core.Chain[@core.Chain[@core.Nat]]
  index : @core.Nat
  active : (@core.Chain[@core.Nat], @core.Chain[@core.Nat])?
}

///|
pub extend State with Eq::{equal, not_equal}

///|
pub extend State with Debug::{to_repr}

///|
#derive(Eq, Debug)
pub(all) enum Computation {
  Done(Certificate)
  Paused(State)
  InvalidWitness
}

///|
pub extend Computation with Eq::{equal, not_equal}

///|
pub extend Computation with Debug::{to_repr}

///|
/// Construct the sparse boundary once; reduction work is subsequently fueled.
pub fn start(source : Filtration) -> State {
  {
    source,
    remaining: boundary_columns(source),
    reduced_rev: Nil,
    change_rev: Nil,
    index: Zero,
    active: None,
  }
}

///|
fn collision(
  reduced : @core.Chain[@core.Chain[@core.Nat]],
  change : @core.Chain[@core.Chain[@core.Nat]],
  pivot : @core.Nat,
) -> (@core.Chain[@core.Nat], @core.Chain[@core.Nat])? {
  match (reduced, change) {
    (Cons(r, rs), Cons(v, vs)) =>
      match @core.last(r).equal(Some(pivot)) {
        true => Some((r, v))
        false => collision(rs, vs, pivot)
      }
    _ => None
  }
}

///|
fn finish(state : State) -> Computation {
  let reduced = @core.reverse(state.reduced_rev)
  let change = @core.reverse(state.change_rev)
  let pairings = pairings_of(reduced, Zero)
  match bars_of(state.source, reduced, pairings) {
    None => InvalidWitness
    Some(bars) => {
      let witness = Certificate::{
        source: state.source,
        reduced,
        change,
        pairings,
        bars,
      }
      match check_result(state.source, bars, witness) {
        true => Done(witness)
        false => InvalidWitness
      }
    }
  }
}

///|
/// Standard sparse left-to-right GF(2) column reduction with R = D V.
/// Each initialization, whole-column XOR, or column commit consumes one
/// operation. Each commit additionally consumes one column. Either exhausted
/// budget returns Paused, and budgets are fresh on resumption. Sparse-list
/// traversal, initial boundary construction and final checking are not fueled;
/// this is an algebraic work budget, not a runtime or allocation limit.
pub fn run(
  state : State,
  operation_fuel : @core.Nat,
  column_fuel : @core.Nat,
) -> Computation {
  match (state.active, state.remaining) {
    (None, Nil) => finish(state)
    _ =>
      match (operation_fuel, column_fuel) {
        (Succ(operations), Succ(columns)) =>
          match state.active {
            None =>
              match state.remaining {
                Nil => finish(state)
                Cons(column, rest) =>
                  run(
                    {
                      ..state,
                      remaining: rest,
                      active: Some((column, Cons(state.index, Nil))),
                    },
                    operations,
                    column_fuel,
                  )
              }
            Some((r, v)) => {
              let previous = match @core.last(r) {
                None => None
                Some(pivot) => collision(state.reduced_rev, state.change_rev, pivot)
              }
              match previous {
                Some((old_r, old_v)) =>
                  run(
                    { ..state, active: Some((xor(r, old_r), xor(v, old_v))) },
                    operations,
                    column_fuel,
                  )
                None =>
                  run(
                    {
                      ..state,
                      reduced_rev: Cons(r, state.reduced_rev),
                      change_rev: Cons(v, state.change_rev),
                      index: Succ(state.index),
                      active: None,
                    },
                    operations,
                    columns,
                  )
              }
            }
          }
        _ => Paused(state)
      }
  }
}
