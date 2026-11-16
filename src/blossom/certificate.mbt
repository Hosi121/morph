///|
/// A maximum matching and a Tutte-Berge barrier. A barrier may be empty even
/// when no perfect matching exists: an odd connected component contributes one.
#derive(Eq, Debug)
pub(all) struct Solution {
  pairs : @core.Chain[(@core.Nat, @core.Nat)]
  barrier : @core.Chain[@core.Nat]
}

///|
pub extend Solution with Eq::{equal, not_equal}

///|
pub extend Solution with Debug::{to_repr}

///|
fn without(p : Problem, vertex : @core.Nat) -> Problem {
  {
    vertices: @core.filter(p.vertices, fn(x) { !same(x, vertex) }),
    edges: @core.filter(p.edges, fn(edge) { neighbor(edge, vertex) is None }),
  }
}

///|
/// Count odd connected components after deleting a supplied set of vertices.
/// This traversal knows nothing about blossoms, alternating forests or matching.
fn odd_components(p : Problem, removed : @core.Chain[@core.Nat]) -> @core.Nat {
  fn reach(
    todo : @core.Chain[@core.Nat],
    unseen : @core.Chain[@core.Nat],
    odd : Bool,
  ) -> (@core.Chain[@core.Nat], Bool) {
    match todo {
      Nil => (unseen, odd)
      Cons(x, rest) => {
        let (todo, unseen) = @core.fold_left(p.edges, (rest, unseen), fn(
          state,
          edge,
        ) {
          let (todo, unseen) = state
          match neighbor(edge, x) {
            Some(y) =>
              if contains(unseen, y) {
                (Cons(y, todo), @core.filter(unseen, fn(z) { !same(y, z) }))
              } else {
                state
              }
            None => state
          }
        })
        reach(todo, unseen, !odd)
      }
    }
  }
  fn count(unseen : @core.Chain[@core.Nat], total : @core.Nat) -> @core.Nat {
    match unseen {
      Nil => total
      Cons(x, rest) => {
        let (remaining, odd) = reach(Cons(x, Nil), rest, false)
        count(remaining, if odd { Succ(total) } else { total })
      }
    }
  }
  count(@core.filter(p.vertices, fn(x) { !contains(removed, x) }), Zero)
}

///|
/// Verify feasibility and the equality
/// twice the matching size plus odd components equals vertices plus barrier.
/// The elementary Tutte-Berge upper bound makes this a general optimality
/// certificate. This checker never calls the matching solver or its search.
pub fn check(p : Problem, solution : Solution) -> Bool {
  let size = @core.length(solution.pairs)
  check_matching(p, solution.pairs) &&
  unique(solution.barrier) &&
  @core.all(solution.barrier, fn(x) { contains(p.vertices, x) }) &&
  same(
    @core.add(@core.add(size, size), odd_components(p, solution.barrier)),
    @core.add(@core.length(p.vertices), @core.length(solution.barrier)),
  )
}

///|
/// Gallai-Edmonds: D consists of vertices exposable by some maximum matching.
/// For a matched vertex, delete it and its matching edge, then ask for just one
/// augmentation. This avoids recomputing a maximum matching from scratch.
fn exposable(
  p : Problem,
  pairs : @core.Chain[(@core.Nat, @core.Nat)],
  todo : @core.Chain[@core.Nat],
) -> @core.Chain[@core.Nat]? {
  match todo {
    Nil => Some(Nil)
    Cons(x, rest) => {
      let exposed = match mate(pairs, x) {
        None => Some(true)
        Some(_) => {
          let reduced = without(p, x)
          let seed = @core.filter(pairs, fn(edge) { neighbor(edge, x) is None })
          match search(reduced, seed) {
            None => None
            Some(result) => Some(result.path is Some(_))
          }
        }
      }
      match (exposed, exposable(p, pairs, rest)) {
        (Some(yes), Some(tail)) => Some(if yes { Cons(x, tail) } else { tail })
        _ => None
      }
    }
  }
}

///|
/// Certify a supplied maximum matching with A = neighbors(D) excluding D.
/// Invalid or nonmaximum matchings return None; the independent checker is the
/// final authority. General witness production can require one search per vertex.
pub fn certify(
  p : Problem,
  pairs : @core.Chain[(@core.Nat, @core.Nat)],
) -> Solution? {
  if !check_matching(p, pairs) {
    return None
  }
  let trivial : Solution = { pairs, barrier: Nil, }
  if check(p, trivial) {
    return Some(trivial)
  }
  match exposable(p, pairs, p.vertices) {
    None => None
    Some(d) => {
      let barrier = @core.filter(p.vertices, fn(x) {
        !contains(d, x) && @core.any(d, fn(y) { adjacent(p.edges, x, y) })
      })
      let solution : Solution = { pairs, barrier, }
      if check(p, solution) {
        Some(solution)
      } else {
        None
      }
    }
  }
}

///|
/// Edmonds maximum-cardinality matching with an independently checkable general
/// graph optimality certificate. Use maximum_matching to omit witness production.
pub fn maximum(p : Problem) -> Solution? {
  match maximum_matching(p) {
    None => None
    Some(pairs) => certify(p, pairs)
  }
}
