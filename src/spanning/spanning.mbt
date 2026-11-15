///|
/// All graph edges are interpreted as undirected, retaining parallel-edge identities.
/// The forest includes every input vertex, including isolated vertices.
#derive(Eq, Debug)
pub(all) struct Forest {
  edges : @core.Chain[@graph.Edge]
  total : @binary.Binary
}

///|
pub extend Forest with Eq::{equal, not_equal}

///|
pub extend Forest with Debug::{to_repr}

///|
fn contains(vertices : @core.Chain[@core.Nat], v : @core.Nat) -> Bool {
  @core.any(vertices, fn(other) {
    match @core.compare(v, other) {
      Equal => true
      _ => false
    }
  })
}

///|
fn extract(
  groups : @core.Chain[@core.Chain[@core.Nat]],
  vertex : @core.Nat,
) -> (@core.Chain[@core.Nat], @core.Chain[@core.Chain[@core.Nat]])? {
  match groups {
    Nil => None
    Cons(group, rest) =>
      match contains(group, vertex) {
        true => Some((group, rest))
        false =>
          match extract(rest, vertex) {
            None => None
            Some((found, others)) => Some((found, Cons(group, others)))
          }
      }
  }
}

///|
/// Persistent disjoint components; None means the edge closes a cycle.
fn join(
  groups : @core.Chain[@core.Chain[@core.Nat]],
  a : @core.Nat,
  b : @core.Nat,
) -> @core.Chain[@core.Chain[@core.Nat]]? {
  match extract(groups, a) {
    None => None
    Some((left, rest)) =>
      match contains(left, b) {
        true => None
        false =>
          match extract(rest, b) {
            None => None
            Some((right, others)) =>
              Some(Cons(@core.append(left, right), others))
          }
      }
  }
}

///|
fn compare_edges(a : @graph.Edge, b : @graph.Edge) -> @core.Ordering {
  @binary.compare(a.weight, b.weight)
}

///|
/// Kruskal minimum spanning forest, using persistent component lists.
pub fn kruskal(g : @graph.Graph) -> Forest {
  let components = @core.map(@graph.vertices(g), fn(v) { @core.Cons(v, Nil) })
  let initial : (
    @core.Chain[@core.Chain[@core.Nat]],
    @core.Chain[@graph.Edge],
    @binary.Binary,
  ) = (components, Nil, @binary.zero())
  let (_, selected, total) = @core.fold_left(
    @sorting.merge_sort(@graph.edges(g), compare_edges),
    initial,
    fn(state, edge) {
      let (groups, selected, total) = state
      match join(groups, edge.from, edge.to) {
        None => state
        Some(groups) =>
          (groups, Cons(edge, selected), @binary.add(total, edge.weight))
      }
    },
  )
  { edges: @core.reverse(selected), total, }
}

///|
/// A separate Prim implementation, restarting at every disconnected component.
pub fn prim(g : @graph.Graph) -> Forest {
  fn next_root(
    vertices : @core.Chain[@core.Nat],
    visited : @core.Chain[@core.Nat],
  ) -> @core.Nat? {
    match vertices {
      Nil => None
      Cons(v, rest) =>
        match contains(visited, v) {
          true => next_root(rest, visited)
          false => Some(v)
        }
    }
  }
  fn incident(
    edges : @core.Chain[@graph.Edge],
    v : @core.Nat,
    heap : @heap.Heap[@graph.Edge],
  ) -> @heap.Heap[@graph.Edge] {
    match edges {
      Nil => heap
      Cons(edge, rest) =>
        match (@core.compare(edge.from, v), @core.compare(edge.to, v)) {
          (Equal, _) | (_, Equal) =>
            incident(rest, v, @heap.insert(heap, edge, compare_edges))
          _ => incident(rest, v, heap)
        }
    }
  }
  fn grow(
    visited : @core.Chain[@core.Nat],
    heap : @heap.Heap[@graph.Edge],
    selected : @core.Chain[@graph.Edge],
    total : @binary.Binary,
  ) -> Forest {
    match @heap.pop(heap, compare_edges) {
      None =>
        match next_root(@graph.vertices(g), visited) {
          None => { edges: @core.reverse(selected), total, }
          Some(root) =>
            grow(
              Cons(root, visited),
              incident(@graph.edges(g), root, @heap.empty()),
              selected,
              total,
            )
        }
      Some((edge, rest)) => {
        let next = match
          (contains(visited, edge.from), contains(visited, edge.to)) {
          (true, false) => Some(edge.to)
          (false, true) => Some(edge.from)
          _ => None
        }
        match next {
          None => grow(visited, rest, selected, total)
          Some(vertex) =>
            grow(
              Cons(vertex, visited),
              incident(@graph.edges(g), vertex, rest),
              Cons(edge, selected),
              @binary.add(total, edge.weight),
            )
        }
      }
    }
  }
  grow(Nil, @heap.empty(), Nil, @binary.zero())
}

///|
fn same_edge(a : @graph.Edge, b : @graph.Edge) -> Bool {
  match
    (
      @core.compare(a.from, b.from),
      @core.compare(a.to, b.to),
      @binary.compare(a.weight, b.weight),
    ) {
    (Equal, Equal, Equal) => true
    _ => false
  }
}

///|
fn remove_edge(
  edges : @core.Chain[@graph.Edge],
  edge : @graph.Edge,
) -> @core.Chain[@graph.Edge]? {
  match edges {
    Nil => None
    Cons(first, rest) =>
      match same_edge(first, edge) {
        true => Some(rest)
        false =>
          match remove_edge(rest, edge) {
            None => None
            Some(tail) => Some(Cons(first, tail))
          }
      }
  }
}

///|
/// Unique forest path, with the maximum edge weight on it.
fn path_max(
  edges : @core.Chain[@graph.Edge],
  from : @core.Nat,
  to : @core.Nat,
  visited : @core.Chain[@core.Nat],
) -> @binary.Binary? {
  fn try_edges(todo : @core.Chain[@graph.Edge]) -> @binary.Binary? {
    match todo {
      Nil => None
      Cons(edge, rest) => {
        let next = match
          (@core.compare(edge.from, from), @core.compare(edge.to, from)) {
          (Equal, _) => Some(edge.to)
          (_, Equal) => Some(edge.from)
          _ => None
        }
        let path = match next {
          None => None
          Some(next) => path_max(edges, next, to, Cons(from, visited))
        }
        match path {
          None => try_edges(rest)
          Some(weight) =>
            Some(
              match @binary.compare(weight, edge.weight) {
                Greater => weight
                _ => edge.weight
              },
            )
        }
      }
    }
  }
  match @core.compare(from, to) {
    Equal => Some(@binary.zero())
    _ =>
      match contains(visited, from) {
        true => None
        false => try_edges(edges)
      }
  }
}

///|
/// Check input-edge multiplicity, acyclicity, total weight, component coverage,
/// and the cycle optimality condition for every original edge. No greedy search.
pub fn check(g : @graph.Graph, forest : Forest) -> Bool {
  fn consume(
    selected : @core.Chain[@graph.Edge],
    available : @core.Chain[@graph.Edge],
    groups : @core.Chain[@core.Chain[@core.Nat]],
    total : @binary.Binary,
  ) -> Bool {
    match selected {
      Nil =>
        match @binary.compare(total, forest.total) {
          Equal => true
          _ => false
        }
      Cons(edge, rest) =>
        match (remove_edge(available, edge), join(groups, edge.from, edge.to)) {
          (Some(available), Some(groups)) =>
            consume(rest, available, groups, @binary.add(total, edge.weight))
          _ => false
        }
    }
  }
  let groups = @core.map(@graph.vertices(g), fn(v) { @core.Cons(v, Nil) })
  match consume(forest.edges, @graph.edges(g), groups, @binary.zero()) {
    false => false
    true =>
      @core.all(@graph.edges(g), fn(edge) {
        match path_max(forest.edges, edge.from, edge.to, Nil) {
          None => false
          Some(weight) =>
            match @binary.compare(weight, edge.weight) {
              Greater => false
              _ => true
            }
        }
      })
  }
}
