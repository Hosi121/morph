///|
/// A finite loopless undirected graph. Vertex labels need not be consecutive.
/// Duplicate edges, including reversed duplicates, are accepted.
#derive(Eq, Debug)
pub struct Problem {
  vertices : @core.Chain[@core.Nat]
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
fn contains(xs : @core.Chain[@core.Nat], x : @core.Nat) -> Bool {
  @core.any(xs, fn(y) { same(x, y) })
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
  vertices : @core.Chain[@core.Nat],
  edges : @core.Chain[(@core.Nat, @core.Nat)],
) -> Problem? {
  if unique(vertices) &&
    @core.all(edges, fn(edge) {
      let (a, b) = edge
      !same(a, b) && contains(vertices, a) && contains(vertices, b)
    }) {
    Some({ vertices, edges, })
  } else {
    None
  }
}

///|
fn neighbor(edge : (@core.Nat, @core.Nat), x : @core.Nat) -> @core.Nat? {
  let (a, b) = edge
  if same(a, x) {
    Some(b)
  } else if same(b, x) {
    Some(a)
  } else {
    None
  }
}

///|
fn adjacent(
  edges : @core.Chain[(@core.Nat, @core.Nat)],
  a : @core.Nat,
  b : @core.Nat,
) -> Bool {
  @core.any(edges, fn(edge) {
    match neighbor(edge, a) {
      Some(x) => same(x, b)
      None => false
    }
  })
}

///|
fn mate(
  pairs : @core.Chain[(@core.Nat, @core.Nat)],
  x : @core.Nat,
) -> @core.Nat? {
  match pairs {
    Nil => None
    Cons(edge, rest) =>
      match neighbor(edge, x) {
        Some(y) => Some(y)
        None => mate(rest, x)
      }
  }
}

///|
fn endpoints(
  pairs : @core.Chain[(@core.Nat, @core.Nat)],
) -> @core.Chain[@core.Nat] {
  match pairs {
    Nil => Nil
    Cons((a, b), rest) => Cons(a, Cons(b, endpoints(rest)))
  }
}

///|
/// Ordinary feasibility checker; it does not search for larger matchings.
pub fn check_matching(
  p : Problem,
  pairs : @core.Chain[(@core.Nat, @core.Nat)],
) -> Bool {
  unique(endpoints(pairs)) &&
  @core.all(pairs, fn(edge) {
    let (a, b) = edge
    adjacent(p.edges, a, b)
  })
}

///|
/// Validate a simple augmenting path independently of the search forest.
pub fn check_augmenting(
  p : Problem,
  pairs : @core.Chain[(@core.Nat, @core.Nat)],
  path : @core.Chain[@core.Nat],
) -> Bool {
  fn walk(xs : @core.Chain[@core.Nat], matched : Bool) -> Bool {
    match xs {
      Cons(a, Cons(b, rest)) =>
        adjacent(p.edges, a, b) &&
        (if matched { adjacent(pairs, a, b) } else { !adjacent(pairs, a, b) }) &&
        walk(Cons(b, rest), !matched)
      Cons(last, Nil) => matched && mate(pairs, last) is None
      Nil => false
    }
  }
  check_matching(p, pairs) &&
  unique(path) &&
  (match path {
    Cons(first, Cons(_, _)) => mate(pairs, first) is None && walk(path, false)
    _ => false
  })
}

///|
/// Flip an independently validated augmenting path.
pub fn augment(
  p : Problem,
  pairs : @core.Chain[(@core.Nat, @core.Nat)],
  path : @core.Chain[@core.Nat],
) -> @core.Chain[(@core.Nat, @core.Nat)]? {
  fn new_pairs(
    xs : @core.Chain[@core.Nat],
  ) -> @core.Chain[(@core.Nat, @core.Nat)] {
    match xs {
      Cons(a, Cons(b, rest)) => Cons((a, b), new_pairs(rest))
      _ => Nil
    }
  }
  if check_augmenting(p, pairs, path) {
    Some(
      @core.append(
        new_pairs(path),
        @core.filter(pairs, fn(edge) {
          let (a, b) = edge
          !contains(path, a) && !contains(path, b)
        }),
      ),
    )
  } else {
    None
  }
}

///|
/// Only even vertices carry paths, stored from the vertex back to its free root.
priv enum Label {
  Even(@core.Nat, @core.Chain[@core.Nat])
  Odd
}

///|
fn label(
  labels : @core.Chain[(@core.Nat, Label)],
  vertex : @core.Nat,
) -> Label? {
  match labels {
    Nil => None
    Cons((x, value), rest) =>
      if same(x, vertex) {
        Some(value)
      } else {
        label(rest, vertex)
      }
  }
}

///|
priv enum Detection {
  Path(@core.Chain[@core.Nat])
  Blossom(@core.Chain[@core.Nat])
  Exhausted
  Inconsistent
}

///|
/// Remove the shared root prefix and keep the final shared vertex as the base.
fn blossom_cycle(
  left : @core.Chain[@core.Nat],
  right : @core.Chain[@core.Nat],
) -> @core.Chain[@core.Nat] {
  fn diverge(
    xs : @core.Chain[@core.Nat],
    ys : @core.Chain[@core.Nat],
    base : @core.Nat,
  ) -> @core.Chain[@core.Nat] {
    match (xs, ys) {
      (Cons(x, xt), Cons(y, yt)) =>
        if same(x, y) {
          diverge(xt, yt, x)
        } else {
          Cons(base, @core.append(xs, @core.reverse(ys)))
        }
      _ => Cons(base, @core.append(xs, @core.reverse(ys)))
    }
  }
  match (@core.reverse(left), @core.reverse(right)) {
    (Cons(x, xt), Cons(_, yt)) => diverge(xt, yt, x)
    _ => Nil
  }
}

///|
fn detect(
  p : Problem,
  pairs : @core.Chain[(@core.Nat, @core.Nat)],
) -> Detection {
  let roots = @core.filter(p.vertices, fn(x) { mate(pairs, x) is None })
  let labels = @core.map(roots, fn(x) { (x, Even(x, Cons(x, Nil))) })
  let queue = @core.fold_left(roots, @core.queue(), fn(q, x) {
    @core.enqueue(q, x)
  })
  breadth_first(p, pairs, queue, labels)
}

///|
fn breadth_first(
  p : Problem,
  pairs : @core.Chain[(@core.Nat, @core.Nat)],
  queue : @core.Queue[@core.Nat],
  labels : @core.Chain[(@core.Nat, Label)],
) -> Detection {
  match @core.dequeue(queue) {
    None => Exhausted
    Some((x, rest)) =>
      match label(labels, x) {
        Some(Even(root, path)) =>
          scan(p, pairs, p.edges, x, root, path, rest, labels)
        _ => Inconsistent
      }
  }
}

///|
fn scan(
  p : Problem,
  pairs : @core.Chain[(@core.Nat, @core.Nat)],
  edges : @core.Chain[(@core.Nat, @core.Nat)],
  x : @core.Nat,
  root : @core.Nat,
  path : @core.Chain[@core.Nat],
  queue : @core.Queue[@core.Nat],
  labels : @core.Chain[(@core.Nat, Label)],
) -> Detection {
  match edges {
    Nil => breadth_first(p, pairs, queue, labels)
    Cons(edge, rest) =>
      match neighbor(edge, x) {
        None => scan(p, pairs, rest, x, root, path, queue, labels)
        Some(y) =>
          if adjacent(pairs, x, y) {
            scan(p, pairs, rest, x, root, path, queue, labels)
          } else {
            match label(labels, y) {
              Some(Odd) => scan(p, pairs, rest, x, root, path, queue, labels)
              Some(Even(other_root, other_path)) =>
                if same(root, other_root) {
                  Blossom(blossom_cycle(path, other_path))
                } else {
                  Path(@core.append(@core.reverse(path), other_path))
                }
              None =>
                match mate(pairs, y) {
                  None => Inconsistent
                  Some(z) =>
                    scan(
                      p,
                      pairs,
                      rest,
                      x,
                      root,
                      path,
                      @core.enqueue(queue, z),
                      Cons(
                        (z, Even(root, Cons(z, Cons(y, path)))),
                        Cons((y, Odd), labels),
                      ),
                    )
                }
            }
          }
      }
  }
}

///|
fn contract_vertex(
  cycle : @core.Chain[@core.Nat],
  base : @core.Nat,
  x : @core.Nat,
) -> @core.Nat {
  if contains(cycle, x) {
    base
  } else {
    x
  }
}

///|
fn contract_edges(
  edges : @core.Chain[(@core.Nat, @core.Nat)],
  cycle : @core.Chain[@core.Nat],
  base : @core.Nat,
) -> @core.Chain[(@core.Nat, @core.Nat)] {
  match edges {
    Nil => Nil
    Cons((a, b), rest) => {
      let x = contract_vertex(cycle, base, a)
      let y = contract_vertex(cycle, base, b)
      let tail = contract_edges(rest, cycle, base)
      if same(x, y) {
        tail
      } else {
        Cons((x, y), tail)
      }
    }
  }
}

///|
fn contract(
  p : Problem,
  cycle : @core.Chain[@core.Nat],
  base : @core.Nat,
) -> Problem {
  {
    vertices: @core.filter(p.vertices, fn(x) {
      same(x, base) || !contains(cycle, x)
    }),
    edges: contract_edges(p.edges, cycle, base),
  }
}

///|
fn prefix_to(
  xs : @core.Chain[@core.Nat],
  target : @core.Nat,
) -> @core.Chain[@core.Nat]? {
  match xs {
    Nil => None
    Cons(x, rest) =>
      if same(x, target) {
        Some(Cons(x, Nil))
      } else {
        match prefix_to(rest, target) {
          None => None
          Some(tail) => Some(Cons(x, tail))
        }
      }
  }
}

///|
fn even_route(
  cycle : @core.Chain[@core.Nat],
  target : @core.Nat,
) -> @core.Chain[@core.Nat]? {
  match (cycle, prefix_to(cycle, target)) {
    (Cons(base, rest), Some(path)) => {
      let (_, odd_vertices) = @core.halve_nat(@core.length(path))
      if odd_vertices {
        Some(path)
      } else {
        prefix_to(Cons(base, @core.reverse(rest)), target)
      }
    }
    _ => None
  }
}

///|
fn attachment(
  edges : @core.Chain[(@core.Nat, @core.Nat)],
  pairs : @core.Chain[(@core.Nat, @core.Nat)],
  cycle : @core.Chain[@core.Nat],
  outside : @core.Nat,
) -> @core.Nat? {
  match edges {
    Nil => None
    Cons(edge, rest) =>
      match neighbor(edge, outside) {
        Some(inside) =>
          if contains(cycle, inside) && !adjacent(pairs, inside, outside) {
            Some(inside)
          } else {
            attachment(rest, pairs, cycle, outside)
          }
        None => attachment(rest, pairs, cycle, outside)
      }
  }
}

///|
/// Orient the quotient path so its unmatched edge at the base points forward.
fn lift(
  p : Problem,
  pairs : @core.Chain[(@core.Nat, @core.Nat)],
  cycle : @core.Chain[@core.Nat],
  base : @core.Nat,
  path : @core.Chain[@core.Nat],
) -> @core.Chain[@core.Nat]? {
  fn forward(xs : @core.Chain[@core.Nat]) -> @core.Chain[@core.Nat]? {
    match xs {
      Nil => None
      Cons(x, rest) =>
        if same(x, base) {
          match rest {
            Cons(outside, _) =>
              match attachment(p.edges, pairs, cycle, outside) {
                None => None
                Some(inside) =>
                  match even_route(cycle, inside) {
                    None => None
                    Some(route) => Some(@core.append(route, rest))
                  }
              }
            Nil => None
          }
        } else {
          match forward(rest) {
            None => None
            Some(tail) => Some(Cons(x, tail))
          }
        }
    }
  }
  fn unmatched_forward(xs : @core.Chain[@core.Nat]) -> Bool {
    match xs {
      Cons(x, Cons(y, rest)) =>
        if same(x, base) {
          !adjacent(contract_edges(pairs, cycle, base), base, y)
        } else {
          unmatched_forward(Cons(y, rest))
        }
      _ => false
    }
  }
  if !contains(path, base) {
    Some(path)
  } else if unmatched_forward(path) {
    forward(path)
  } else {
    match forward(@core.reverse(path)) {
      None => None
      Some(lifted) => Some(@core.reverse(lifted))
    }
  }
}

///|
/// Each listed odd cycle was really contracted. Later cycles use quotient labels,
/// so multiple entries witness recursive, possibly nested blossom contraction.
#derive(Eq, Debug)
pub(all) struct Search {
  path : @core.Chain[@core.Nat]?
  blossoms : @core.Chain[@core.Chain[@core.Nat]]
}

///|
pub extend Search with Eq::{equal, not_equal}

///|
pub extend Search with Debug::{to_repr}

///|
fn search(p : Problem, pairs : @core.Chain[(@core.Nat, @core.Nat)]) -> Search? {
  match detect(p, pairs) {
    Inconsistent => None
    Exhausted => Some({ path: None, blossoms: Nil, })
    Path(path) =>
      if check_augmenting(p, pairs, path) {
        Some({ path: Some(path), blossoms: Nil, })
      } else {
        None
      }
    Blossom(cycle) =>
      match cycle {
        Cons(base, Cons(_, Cons(_, _))) => {
          let quotient = contract(p, cycle, base)
          let contracted_pairs = contract_edges(pairs, cycle, base)
          match search(quotient, contracted_pairs) {
            None => None
            Some(child) =>
              match child.path {
                None =>
                  Some({ path: None, blossoms: Cons(cycle, child.blossoms), })
                Some(path) =>
                  match lift(p, pairs, cycle, base, path) {
                    None => None
                    Some(lifted) =>
                      if check_augmenting(p, pairs, lifted) {
                        Some({
                          path: Some(lifted),
                          blossoms: Cons(cycle, child.blossoms),
                        })
                      } else {
                        None
                      }
                  }
              }
          }
        }
        _ => None
      }
  }
}

///|
/// Find one augmenting path using Edmonds's recursive shrinking and lifting.
/// None rejects an invalid seed or detects an internal invariant failure.
/// Some with path=None means the seed is already maximum.
pub fn augmenting_search(
  p : Problem,
  pairs : @core.Chain[(@core.Nat, @core.Nat)],
) -> Search? {
  if check_matching(p, pairs) {
    search(p, pairs)
  } else {
    None
  }
}

///|
/// Compute a maximum matching without producing the optional optimality witness.
pub fn maximum_matching(p : Problem) -> @core.Chain[(@core.Nat, @core.Nat)]? {
  fn improve(
    pairs : @core.Chain[(@core.Nat, @core.Nat)],
  ) -> @core.Chain[(@core.Nat, @core.Nat)]? {
    match search(p, pairs) {
      None => None
      Some(result) =>
        match result.path {
          None => Some(pairs)
          Some(path) =>
            match augment(p, pairs, path) {
              None => None
              Some(next) => improve(next)
            }
        }
    }
  }
  improve(Nil)
}
