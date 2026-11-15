///|
#derive(Eq, Debug)
pub(all) struct Edge {
  from : @core.Nat
  to : @core.Nat
  weight : @binary.Binary
}

///|
pub extend Edge with Eq::{equal, not_equal}

///|
pub extend Edge with Debug::{to_repr}

///|
/// Finite graph with unique vertices and valid endpoints. Parallel edges allowed.
#derive(Eq, Debug)
pub struct Graph {
  vertices : @core.Chain[@core.Nat]
  edges : @core.Chain[Edge]
}

///|
pub extend Graph with Eq::{equal, not_equal}

///|
pub extend Graph with Debug::{to_repr}

///|
fn contains(xs : @core.Chain[@core.Nat], x : @core.Nat) -> Bool {
  match xs {
    Nil => false
    Cons(y, rest) =>
      match @core.compare(x, y) {
        Equal => true
        _ => contains(rest, x)
      }
  }
}

///|
pub fn graph(
  vertices : @core.Chain[@core.Nat],
  edges : @core.Chain[Edge],
) -> Graph? {
  fn unique(xs : @core.Chain[@core.Nat]) -> Bool {
    match xs {
      Nil => true
      Cons(x, rest) =>
        match contains(rest, x) {
          true => false
          false => unique(rest)
        }
    }
  }
  fn valid(es : @core.Chain[Edge]) -> Bool {
    match es {
      Nil => true
      Cons(e, rest) =>
        match (contains(vertices, e.from), contains(vertices, e.to)) {
          (true, true) => valid(rest)
          _ => false
        }
    }
  }
  match (unique(vertices), valid(edges)) {
    (true, true) => Some({ vertices, edges, })
    _ => None
  }
}

///|
pub fn vertices(g : Graph) -> @core.Chain[@core.Nat] {
  g.vertices
}

///|
pub fn edges(g : Graph) -> @core.Chain[Edge] {
  g.edges
}

///|
#derive(Eq, Debug)
pub(all) struct Visit {
  vertex : @core.Nat
  distance : @binary.Binary
  predecessor : @core.Nat?
}

///|
pub extend Visit with Eq::{equal, not_equal}

///|
pub extend Visit with Debug::{to_repr}

///|
pub fn lookup(visits : @core.Chain[Visit], vertex : @core.Nat) -> Visit? {
  match visits {
    Nil => None
    Cons(visit, rest) =>
      match @core.compare(visit.vertex, vertex) {
        Equal => Some(visit)
        _ => lookup(rest, vertex)
      }
  }
}

///|
/// Breadth-first search counts edges, ignoring stored weights.
pub fn bfs(g : Graph, source : @core.Nat) -> @core.Chain[Visit]? {
  fn expand(
    es : @core.Chain[Edge],
    visit : Visit,
    queue : @core.Queue[Visit],
    seen : @core.Chain[Visit],
  ) -> (@core.Queue[Visit], @core.Chain[Visit]) {
    match es {
      Nil => (queue, seen)
      Cons(edge, rest) =>
        match (@core.compare(edge.from, visit.vertex), lookup(seen, edge.to)) {
          (Equal, None) => {
            let next : Visit = {
              vertex: edge.to,
              distance: @binary.successor(visit.distance),
              predecessor: Some(visit.vertex),
            }
            expand(rest, visit, @core.enqueue(queue, next), Cons(next, seen))
          }
          _ => expand(rest, visit, queue, seen)
        }
    }
  }
  fn walk(
    queue : @core.Queue[Visit],
    seen : @core.Chain[Visit],
    output : @core.Chain[Visit],
  ) -> @core.Chain[Visit] {
    match @core.dequeue(queue) {
      None => @core.reverse(output)
      Some((visit, rest)) => {
        let (next_queue, next_seen) = expand(g.edges, visit, rest, seen)
        walk(next_queue, next_seen, Cons(visit, output))
      }
    }
  }
  match contains(g.vertices, source) {
    false => None
    true => {
      let first : Visit = {
        vertex: source,
        distance: @binary.zero(),
        predecessor: None,
      }
      Some(walk(@core.enqueue(@core.queue(), first), Cons(first, Nil), Nil))
    }
  }
}

///|
/// Nonnegative Dijkstra with persistent heap and stale-entry skipping.
pub fn dijkstra(g : Graph, source : @core.Nat) -> @core.Chain[Visit]? {
  let compare = fn(a : Visit, b : Visit) {
    @binary.compare(a.distance, b.distance)
  }
  fn expand(
    es : @core.Chain[Edge],
    visit : Visit,
    heap : @heap.Heap[Visit],
  ) -> @heap.Heap[Visit] {
    match es {
      Nil => heap
      Cons(edge, rest) =>
        match @core.compare(edge.from, visit.vertex) {
          Equal => {
            let next : Visit = {
              vertex: edge.to,
              distance: @binary.add(visit.distance, edge.weight),
              predecessor: Some(visit.vertex),
            }
            expand(rest, visit, @heap.insert(heap, next, compare))
          }
          _ => expand(rest, visit, heap)
        }
    }
  }
  fn walk(
    heap : @heap.Heap[Visit],
    settled : @core.Chain[Visit],
  ) -> @core.Chain[Visit] {
    match @heap.pop(heap, compare) {
      None => @core.reverse(settled)
      Some((visit, rest)) =>
        match lookup(settled, visit.vertex) {
          Some(_) => walk(rest, settled)
          None => walk(expand(g.edges, visit, rest), Cons(visit, settled))
        }
    }
  }
  match contains(g.vertices, source) {
    false => None
    true =>
      Some(
        walk(
          @heap.singleton({
            vertex: source,
            distance: @binary.zero(),
            predecessor: None,
          }),
          Nil,
        ),
      )
  }
}

///|
/// Reconstruct a source-to-target path. Fuel rejects malformed cyclic parents.
pub fn path(
  visits : @core.Chain[Visit],
  target : @core.Nat,
) -> @core.Chain[@core.Nat]? {
  fn walk(
    vertex : @core.Nat,
    fuel : @core.Chain[Visit],
    suffix : @core.Chain[@core.Nat],
  ) -> @core.Chain[@core.Nat]? {
    match fuel {
      Nil => None
      Cons(_, rest) =>
        match lookup(visits, vertex) {
          None => None
          Some(visit) =>
            match visit.predecessor {
              None => Some(Cons(vertex, suffix))
              Some(parent) => walk(parent, rest, Cons(vertex, suffix))
            }
        }
    }
  }
  walk(target, visits, Nil)
}
