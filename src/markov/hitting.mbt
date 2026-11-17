///|
/// Unconditional expectation of the first target visit, with time zero included.
/// Infinite means positive probability of never hitting the target set.
#derive(Eq, Debug)
pub(all) enum HittingTime {
  Finite(@exact.Rational)
  Infinite
}

///|
pub extend HittingTime with Eq::{equal, not_equal}

///|
pub extend HittingTime with Debug::{to_repr}

///|
/// Exact probabilities and unconditional times, with a reachability certificate.
/// Some(path) proves a positive-probability route from that state to a target.
/// None states form a target-disjoint set closed under all positive transitions.
#derive(Eq, Debug)
pub struct Hitting {
  context : Kernel
  targets : @core.Chain[Bool]
  chances : @core.Chain[@exact.Rational]
  times : @core.Chain[HittingTime]
  paths : @core.Chain[@core.Chain[@core.Nat]?]
}

///|
pub extend Hitting with Eq::{equal, not_equal}

///|
pub extend Hitting with Debug::{to_repr}

///|
pub fn hitting_kernel(result : Hitting) -> Kernel {
  result.context
}

///|
/// Canonical, increasing target indices. Duplicate input indices are harmless.
pub fn hitting_targets(result : Hitting) -> @core.Chain[@core.Nat] {
  @core.filter(@core.indices(states(result.context)), fn(index) {
    @core.nth(result.targets, index) is Some(true)
  })
}

///|
pub fn hitting_probabilities(result : Hitting) -> @core.Chain[@exact.Rational] {
  result.chances
}

///|
pub fn expected_hitting_times(result : Hitting) -> @core.Chain[HittingTime] {
  result.times
}

///|
pub fn hitting_paths(result : Hitting) -> @core.Chain[@core.Chain[@core.Nat]?] {
  result.paths
}

///|
fn positive_probability(value : @exact.Rational) -> Bool {
  @exact.rational_compare(value, @exact.rational_zero()) is Greater
}

///|
fn target_mask(
  value : Kernel,
  targets : @core.Chain[@core.Nat],
) -> Result[@core.Chain[Bool], MarkovError] {
  if !@core.all(targets, fn(index) {
      @core.compare(index, states(value)) is Less
    }) {
    Err(InvalidState)
  } else {
    Ok(
      @core.map(@core.indices(states(value)), fn(index) {
        @core.any(targets, fn(target) { target.equal(index) })
      }),
    )
  }
}

///|
fn reach_paths(
  value : Kernel,
  targets : @core.Chain[Bool],
) -> @core.Chain[@core.Chain[@core.Nat]?]? {
  fn successor(
    row : @core.Chain[@exact.Rational],
    paths : @core.Chain[@core.Chain[@core.Nat]?],
  ) -> @core.Chain[@core.Nat]? {
    match (row, paths) {
      (Cons(weight, rest), Cons(Some(path), tail)) =>
        if positive_probability(weight) {
          Some(path)
        } else {
          successor(rest, tail)
        }
      (Cons(_, rest), Cons(None, tail)) => successor(rest, tail)
      _ => None
    }
  }
  fn extend_paths(
    rows : @core.Chain[@core.Chain[@exact.Rational]],
    old : @core.Chain[@core.Chain[@core.Nat]?],
    index : @core.Nat,
  ) -> @core.Chain[@core.Chain[@core.Nat]?]? {
    match rows {
      Nil => Some(Nil)
      Cons(row, rest) =>
        match (@core.nth(old, index), extend_paths(rest, old, Succ(index))) {
          (Some(previous), Some(tail)) => {
            let current = match previous {
              Some(path) => Some(path)
              None =>
                match successor(row, old) {
                  None => None
                  Some(path) => Some(Cons(index, path))
                }
            }
            Some(Cons(current, tail))
          }
          _ => None
        }
    }
  }
  fn advance(
    fuel : @core.Nat,
    paths : @core.Chain[@core.Chain[@core.Nat]?],
  ) -> @core.Chain[@core.Chain[@core.Nat]?]? {
    match fuel {
      Zero => Some(paths)
      Succ(rest) =>
        match extend_paths(@matrix.rows(value.transition), paths, Zero) {
          None => None
          Some(updated) => advance(rest, updated)
        }
    }
  }
  let initial : @core.Chain[@core.Chain[@core.Nat]?] = @core.map(
    @core.indices(states(value)),
    fn(index) {
      if @core.nth(targets, index) is Some(true) {
        Some(Cons(index, Nil))
      } else {
        None
      }
    },
  )
  // Every reachable target has a simple path with fewer than n edges.
  advance(states(value), initial)
}

///|
fn unit_row(value : Kernel, index : @core.Nat) -> @core.Chain[@exact.Rational] {
  @core.map(@core.indices(states(value)), fn(column) {
    if column.equal(index) {
      @exact.rational_one()
    } else {
      @exact.rational_zero()
    }
  })
}

///|
/// Boundary rows fix a coordinate. Other rows impose x_i - sum(P_ij x_j).
fn dirichlet_system(
  value : Kernel,
  boundary : @core.Chain[Bool],
) -> @matrix.Matrix[@exact.Rational]? {
  fn build(
    rows : @core.Chain[@core.Chain[@exact.Rational]],
    flags : @core.Chain[Bool],
    index : @core.Nat,
  ) -> @core.Chain[@core.Chain[@exact.Rational]]? {
    match (rows, flags) {
      (Nil, Nil) => Some(Nil)
      (Cons(row, rest), Cons(fixed, tail)) => {
        let equation = if fixed {
          Some(unit_row(value, index))
        } else {
          subtract_rows(unit_row(value, index), row)
        }
        match (equation, build(rest, tail, Succ(index))) {
          (Some(current), Some(rows)) => Some(Cons(current, rows))
          _ => None
        }
      }
      _ => None
    }
  }
  match build(@matrix.rows(value.transition), boundary, Zero) {
    None => None
    Some(rows) => @matrix.matrix(states(value), rows)
  }
}

///|
fn solve_unique(
  value : Kernel,
  boundary : @core.Chain[Bool],
  rhs : @core.Chain[@exact.Rational],
) -> @core.Chain[@exact.Rational]? {
  match dirichlet_system(value, boundary) {
    None => None
    Some(equations) =>
      match @linear.solve(equations, rhs) {
        Some(Unique(solution)) => Some(solution)
        _ => None
      }
  }
}

///|
/// First visit T=min{n>=0 : X_n in targets}. Targets need not be absorbing in P.
/// The empty target set is valid: chance zero and Infinite time from every state.
/// A partial chance of eventual absorption gives Infinite, not a conditional time.
pub fn hitting(
  value : Kernel,
  target_indices : @core.Chain[@core.Nat],
) -> Result[Hitting, MarkovError] {
  match target_mask(value, target_indices) {
    Err(error) => Err(error)
    Ok(targets) =>
      match reach_paths(value, targets) {
        None => Err(InternalInvariant)
        Some(paths) =>
          match @core.zip(targets, paths) {
            None => Err(InternalInvariant)
            Some(pairs) => {
              let boundary = @core.map(pairs, fn(pair) {
                let (target, path) = pair
                target || path is None
              })
              let rhs = @core.map(targets, fn(target) {
                if target {
                  @exact.rational_one()
                } else {
                  @exact.rational_zero()
                }
              })
              match solve_unique(value, boundary, rhs) {
                None => Err(InternalInvariant)
                Some(chances) =>
                  match @core.zip(targets, chances) {
                    None => Err(InternalInvariant)
                    Some(entries) => {
                      let stopped = @core.map(entries, fn(pair) {
                        let (target, chance) = pair
                        target || !chance.equal(@exact.rational_one())
                      })
                      let time_rhs = @core.map(stopped, fn(fixed) {
                        if fixed {
                          @exact.rational_zero()
                        } else {
                          @exact.rational_one()
                        }
                      })
                      match solve_unique(value, stopped, time_rhs) {
                        None => Err(InternalInvariant)
                        Some(finite_values) =>
                          match @core.zip(chances, finite_values) {
                            None => Err(InternalInvariant)
                            Some(results) => {
                              let times = @core.map(results, fn(pair) {
                                let (chance, duration) = pair
                                if chance.equal(@exact.rational_one()) {
                                  Finite(duration)
                                } else {
                                  Infinite
                                }
                              })
                              let result = Hitting::{
                                context: value,
                                targets,
                                chances,
                                times,
                                paths,
                              }
                              if check_hitting(value, target_indices, result) {
                                Ok(result)
                              } else {
                                Err(InternalInvariant)
                              }
                            }
                          }
                      }
                    }
                  }
              }
            }
          }
      }
  }
}
