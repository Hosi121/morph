///|
/// Left and right namespaces are separate; their Nat labels may overlap.
#derive(Eq, Debug)
pub struct Problem {
  left : @core.Chain[@core.Nat]
  right : @core.Chain[@core.Nat]
  edges : @core.Chain[(@core.Nat, @core.Nat)]
}

///|
pub extend Problem with Eq::{equal, not_equal}

///|
pub extend Problem with Debug::{to_repr}

///|
fn same(a : @core.Nat, b : @core.Nat) -> Bool {
  match @core.compare(a, b) {
    Equal => true
    _ => false
  }
}

///|
fn contains(xs : @core.Chain[@core.Nat], value : @core.Nat) -> Bool {
  @core.any(xs, fn(x) { same(x, value) })
}

///|
fn unique(xs : @core.Chain[@core.Nat]) -> Bool {
  match xs {
    Nil => true
    Cons(x, rest) => !contains(rest, x) && unique(rest)
  }
}

///|
pub fn problem(
  left : @core.Chain[@core.Nat],
  right : @core.Chain[@core.Nat],
  edges : @core.Chain[(@core.Nat, @core.Nat)],
) -> Problem? {
  match
    unique(left) &&
    unique(right) &&
    @core.all(edges, fn(edge) {
      let (a, b) = edge
      contains(left, a) && contains(right, b)
    }) {
    true => Some({ left, right, edges, })
    false => None
  }
}

///|
fn lookup(
  pairs : @core.Chain[(@core.Nat, @core.Nat)],
  key : @core.Nat,
) -> @core.Nat? {
  match pairs {
    Nil => None
    Cons((a, b), rest) =>
      match same(a, key) {
        true => Some(b)
        false => lookup(rest, key)
      }
  }
}

///|
fn right_mate(
  pairs : @core.Chain[(@core.Nat, @core.Nat)],
  key : @core.Nat,
) -> @core.Nat? {
  match pairs {
    Nil => None
    Cons((a, b), rest) =>
      match same(b, key) {
        true => Some(a)
        false => right_mate(rest, key)
      }
  }
}

///|
fn assign(
  pairs : @core.Chain[(@core.Nat, @core.Nat)],
  left : @core.Nat,
  right : @core.Nat,
) -> @core.Chain[(@core.Nat, @core.Nat)] {
  Cons(
    (left, right),
    @core.filter(pairs, fn(pair) {
      let (a, b) = pair
      !same(a, left) && !same(b, right)
    }),
  )
}

///|
fn free_left(
  p : Problem,
  pairs : @core.Chain[(@core.Nat, @core.Nat)],
) -> @core.Chain[@core.Nat] {
  @core.filter(p.left, fn(a) {
    match lookup(pairs, a) {
      None => true
      Some(_) => false
    }
  })
}

///|
/// Distances count alternating left-to-right steps. None means no augmenting path.
fn layers(
  p : Problem,
  pairs : @core.Chain[(@core.Nat, @core.Nat)],
) -> (@core.Chain[(@core.Nat, @core.Nat)], @core.Nat?) {
  let initial = @core.map(free_left(p, pairs), fn(a) { (a, @core.Zero) })
  let queue = @core.fold_left(initial, @core.queue(), fn(queue, item) {
    @core.enqueue(queue, item)
  })
  fn breadth_first(
    queue : @core.Queue[(@core.Nat, @core.Nat)],
    distances : @core.Chain[(@core.Nat, @core.Nat)],
    shortest : @core.Nat?,
  ) -> (@core.Chain[(@core.Nat, @core.Nat)], @core.Nat?) {
    match @core.dequeue(queue) {
      None => (distances, shortest)
      Some(((a, d), rest)) => {
        let useful = match shortest {
          None => true
          Some(s) =>
            match @core.compare(d, s) {
              Less => true
              _ => false
            }
        }
        match useful {
          false => (distances, shortest)
          true => {
            let initial = (rest, distances, shortest)
            let (queue, distances, shortest) = @core.fold_left(
              p.edges,
              initial,
              fn(state, edge) {
                let (left, right) = edge
                let (queue, distances, shortest) = state
                match same(left, a) {
                  false => state
                  true =>
                    match right_mate(pairs, right) {
                      None => {
                        let next = @core.Succ(d)
                        let shortest = match shortest {
                          None => Some(next)
                          Some(previous) => Some(@core.minimum(next, previous))
                        }
                        (queue, distances, shortest)
                      }
                      Some(next) =>
                        match lookup(distances, next) {
                          Some(_) => state
                          None => {
                            let distance = @core.Succ(d)
                            (
                              @core.enqueue(queue, (next, distance)),
                              Cons((next, distance), distances),
                              shortest,
                            )
                          }
                        }
                    }
                }
              },
            )
            breadth_first(queue, distances, shortest)
          }
        }
      }
    }
  }
  breadth_first(queue, initial, None)
}

///|
/// Failed left vertices are disabled for the rest of this fixed-layer phase.
fn augment(
  p : Problem,
  pairs : @core.Chain[(@core.Nat, @core.Nat)],
  distances : @core.Chain[(@core.Nat, @core.Nat)],
  shortest : @core.Nat,
  left : @core.Nat,
  blocked : @core.Chain[@core.Nat],
) -> (@core.Chain[(@core.Nat, @core.Nat)]?, @core.Chain[@core.Nat]) {
  fn try_edges(
    edges : @core.Chain[(@core.Nat, @core.Nat)],
    next_distance : @core.Nat,
    blocked : @core.Chain[@core.Nat],
  ) -> (@core.Chain[(@core.Nat, @core.Nat)]?, @core.Chain[@core.Nat]) {
    match edges {
      Nil => (None, Cons(left, blocked))
      Cons((a, b), rest) =>
        match same(a, left) {
          false => try_edges(rest, next_distance, blocked)
          true =>
            match right_mate(pairs, b) {
              None =>
                match same(next_distance, shortest) {
                  true => (Some(assign(pairs, left, b)), blocked)
                  false => try_edges(rest, next_distance, blocked)
                }
              Some(next) =>
                match lookup(distances, next) {
                  Some(d) =>
                    match same(d, next_distance) {
                      false => try_edges(rest, next_distance, blocked)
                      true =>
                        match
                          augment(p, pairs, distances, shortest, next, blocked) {
                          (Some(updated), blocked) =>
                            (Some(assign(updated, left, b)), blocked)
                          (None, blocked) =>
                            try_edges(rest, next_distance, blocked)
                        }
                    }
                  None => try_edges(rest, next_distance, blocked)
                }
            }
        }
    }
  }
  match (contains(blocked, left), lookup(distances, left)) {
    (false, Some(d)) => try_edges(p.edges, Succ(d), blocked)
    _ => (None, blocked)
  }
}

///|
#derive(Eq, Debug)
pub(all) struct Solution {
  pairs : @core.Chain[(@core.Nat, @core.Nat)]
  cover_left : @core.Chain[@core.Nat]
  cover_right : @core.Chain[@core.Nat]
}

///|
pub extend Solution with Eq::{equal, not_equal}

///|
pub extend Solution with Debug::{to_repr}

///|
fn cover(p : Problem, pairs : @core.Chain[(@core.Nat, @core.Nat)]) -> Solution {
  let free = free_left(p, pairs)
  let queue = @core.fold_left(free, @core.queue(), fn(queue, a) {
    @core.enqueue(queue, a)
  })
  fn reach(
    queue : @core.Queue[@core.Nat],
    left : @core.Chain[@core.Nat],
    right : @core.Chain[@core.Nat],
  ) -> Solution {
    match @core.dequeue(queue) {
      None =>
        {
          pairs,
          cover_left: @core.filter(p.left, fn(a) { !contains(left, a) }),
          cover_right: right,
        }
      Some((a, rest)) => {
        let (queue, left, right) = @core.fold_left(
          p.edges,
          (rest, left, right),
          fn(state, edge) {
            let (x, y) = edge
            let (queue, left, right) = state
            let matched = match lookup(pairs, x) {
              None => false
              Some(mate) => same(mate, y)
            }
            match same(x, a) && !matched && !contains(right, y) {
              false => state
              true =>
                match right_mate(pairs, y) {
                  None => (queue, left, Cons(y, right))
                  Some(next) =>
                    match contains(left, next) {
                      true => (queue, left, Cons(y, right))
                      false =>
                        (
                          @core.enqueue(queue, next),
                          Cons(next, left),
                          Cons(y, right),
                        )
                    }
                }
            }
          },
        )
        reach(queue, left, right)
      }
    }
  }
  reach(queue, free, Nil)
}

///|
/// Hopcroft-Karp: BFS shortest augmenting layers, then a blocking DFS phase.
/// Returns a matching and an equally sized vertex cover. None is defensive if
/// a nonempty shortest layer fails to yield any augmentation.
pub fn maximum(p : Problem) -> Solution? {
  fn phases(pairs : @core.Chain[(@core.Nat, @core.Nat)]) -> Solution? {
    match layers(p, pairs) {
      (_, None) => Some(cover(p, pairs))
      (distances, Some(shortest)) => {
        let initial : (
          @core.Chain[(@core.Nat, @core.Nat)],
          @core.Chain[@core.Nat],
          Bool,
        ) = (pairs, Nil, false)
        let (updated, _, changed) = @core.fold_left(
          free_left(p, pairs),
          initial,
          fn(state, left) {
            let (current, blocked, changed) = state
            match augment(p, current, distances, shortest, left, blocked) {
              (None, blocked) => (current, blocked, changed)
              (Some(current), blocked) => (current, blocked, true)
            }
          },
        )
        match changed {
          true => phases(updated)
          false => None
        }
      }
    }
  }
  phases(Nil)
}

///|
/// Check matching and cover validity plus equal cardinalities, without searching.
/// Every matching is bounded by every vertex cover, so equality proves optimality.
pub fn check(p : Problem, solution : Solution) -> Bool {
  let left = @core.map(solution.pairs, fn(pair) {
    let (a, _) = pair
    a
  })
  let right = @core.map(solution.pairs, fn(pair) {
    let (_, b) = pair
    b
  })
  unique(left) &&
  unique(right) &&
  unique(solution.cover_left) &&
  unique(solution.cover_right) &&
  @core.all(solution.pairs, fn(pair) {
    let (a, b) = pair
    @core.any(p.edges, fn(edge) {
      let (x, y) = edge
      same(a, x) && same(b, y)
    })
  }) &&
  @core.all(solution.cover_left, fn(a) { contains(p.left, a) }) &&
  @core.all(solution.cover_right, fn(b) { contains(p.right, b) }) &&
  @core.all(p.edges, fn(edge) {
    let (a, b) = edge
    contains(solution.cover_left, a) || contains(solution.cover_right, b)
  }) &&
  same(
    @core.length(solution.pairs),
    @core.add(
      @core.length(solution.cover_left),
      @core.length(solution.cover_right),
    ),
  )
}
