///|
/// Every original edge has distinct forward/reverse residual arcs, even when
/// the input has parallel edges, antiparallel edges, or self-loops.
priv struct Arc {
  id : @core.Nat
  reverse : Bool
  from : @core.Nat
  to : @core.Nat
  residual : @binary.Binary
}

///|
#derive(Eq, Debug)
pub(all) struct EdgeFlow {
  edge : @graph.Edge
  flow : @binary.Binary
}

///|
pub extend EdgeFlow with Eq::{equal, not_equal}

///|
pub extend EdgeFlow with Debug::{to_repr}

///|
/// A primal flow and a source-side cut certificate, in original edge order.
#derive(Eq, Debug)
pub(all) struct MaxFlow {
  value : @binary.Binary
  edges : @core.Chain[EdgeFlow]
  cut : @core.Chain[@core.Nat]
}

///|
pub extend MaxFlow with Eq::{equal, not_equal}

///|
pub extend MaxFlow with Debug::{to_repr}

///|
priv enum Search {
  Found(@core.Chain[Arc], @binary.Binary)
  Blocked(@core.Chain[@core.Nat])
}

///|
fn contains(vertices : @core.Chain[@core.Nat], vertex : @core.Nat) -> Bool {
  @core.any(vertices, fn(other) {
    match @core.compare(vertex, other) {
      Equal => true
      _ => false
    }
  })
}

///|
fn initial_arcs(
  edges : @core.Chain[@graph.Edge],
  id : @core.Nat,
) -> @core.Chain[Arc] {
  match edges {
    Nil => Nil
    Cons(edge, rest) =>
      Cons(
        {
          id,
          reverse: false,
          from: edge.from,
          to: edge.to,
          residual: edge.weight,
        },
        Cons(
          {
            id,
            reverse: true,
            from: edge.to,
            to: edge.from,
            residual: @binary.zero(),
          },
          initial_arcs(rest, Succ(id)),
        ),
      )
  }
}

///|
fn search(
  g : @graph.Graph,
  arcs : @core.Chain[Arc],
  source : @core.Nat,
  sink : @core.Nat,
) -> Search? {
  let positive = @core.filter(arcs, fn(arc) {
    match @binary.is_zero(arc.residual) {
      true => false
      false => true
    }
  })
  let edges = @core.map(positive, fn(arc) {
    @graph.Edge::{ from: arc.from, to: arc.to, weight: arc.residual, }
  })
  fn choose(arcs : @core.Chain[Arc], from : @core.Nat, to : @core.Nat) -> Arc? {
    match arcs {
      Nil => None
      Cons(arc, rest) =>
        match (@core.compare(arc.from, from), @core.compare(arc.to, to)) {
          (Equal, Equal) => Some(arc)
          _ => choose(rest, from, to)
        }
    }
  }
  fn route(path : @core.Chain[@core.Nat]) -> @core.Chain[Arc]? {
    match path {
      Nil | Cons(_, Nil) => Some(Nil)
      Cons(from, Cons(to, _) as tail) =>
        match (choose(positive, from, to), route(tail)) {
          (Some(arc), Some(rest)) => Some(Cons(arc, rest))
          _ => None
        }
    }
  }
  match @graph.graph(@graph.vertices(g), edges) {
    None => None
    Some(residual) =>
      match @graph.bfs(residual, source) {
        None => None
        Some(visits) =>
          match @graph.path(visits, sink) {
            None => Some(Blocked(@core.map(visits, fn(visit) { visit.vertex })))
            Some(path) =>
              match route(path) {
                Some(Cons(first, rest) as path) => {
                  let bottleneck = @core.fold_left(rest, first.residual, fn(
                    smallest,
                    arc,
                  ) {
                    match @binary.compare(smallest, arc.residual) {
                      Greater => arc.residual
                      _ => smallest
                    }
                  })
                  Some(Found(path, bottleneck))
                }
                _ => None
              }
          }
      }
  }
}

///|
fn augment(
  arcs : @core.Chain[Arc],
  path : @core.Chain[Arc],
  amount : @binary.Binary,
) -> @core.Chain[Arc]? {
  fn selected(path : @core.Chain[Arc], id : @core.Nat) -> Bool? {
    match path {
      Nil => None
      Cons(arc, rest) =>
        match @core.compare(arc.id, id) {
          Equal => Some(arc.reverse)
          _ => selected(rest, id)
        }
    }
  }
  match arcs {
    Nil => Some(Nil)
    Cons(arc, rest) => {
      let capacity = match (selected(path, arc.id), arc.reverse) {
        (None, _) => Some(arc.residual)
        (Some(false), false) | (Some(true), true) =>
          @binary.subtract(arc.residual, amount)
        _ => Some(@binary.add(arc.residual, amount))
      }
      match (capacity, augment(rest, path, amount)) {
        (Some(residual), Some(rest)) =>
          Some(
            Cons(
              {
                id: arc.id,
                reverse: arc.reverse,
                from: arc.from,
                to: arc.to,
                residual,
              },
              rest,
            ),
          )
        _ => None
      }
    }
  }
}

///|
fn output_flows(
  edges : @core.Chain[@graph.Edge],
  arcs : @core.Chain[Arc],
  id : @core.Nat,
) -> @core.Chain[EdgeFlow]? {
  fn flow(arcs : @core.Chain[Arc]) -> @binary.Binary? {
    match arcs {
      Nil => None
      Cons(arc, rest) =>
        match (@core.compare(arc.id, id), arc.reverse) {
          (Equal, true) => Some(arc.residual)
          _ => flow(rest)
        }
    }
  }
  match edges {
    Nil => Some(Nil)
    Cons(edge, rest) =>
      match (flow(arcs), output_flows(rest, arcs, Succ(id))) {
        (Some(flow), Some(rest)) => Some(Cons({ edge, flow, }, rest))
        _ => None
      }
  }
}

///|
/// Edmonds-Karp: BFS-shortest residual paths, then exact binary augmentation.
/// Source and sink must be distinct defined vertices. Weights mean capacities.
pub fn max_flow(
  g : @graph.Graph,
  source : @core.Nat,
  sink : @core.Nat,
) -> MaxFlow? {
  fn advance_flow(arcs : @core.Chain[Arc], value : @binary.Binary) -> MaxFlow? {
    match search(g, arcs, source, sink) {
      None => None
      Some(Found(path, amount)) =>
        match augment(arcs, path, amount) {
          None => None
          Some(next) => advance_flow(next, @binary.add(value, amount))
        }
      Some(Blocked(cut)) =>
        match output_flows(@graph.edges(g), arcs, Zero) {
          None => None
          Some(edges) => Some({ value, edges, cut, })
        }
    }
  }
  match
    (
      contains(@graph.vertices(g), source),
      contains(@graph.vertices(g), sink),
      @core.compare(source, sink),
    ) {
    (true, true, Less) | (true, true, Greater) =>
      advance_flow(initial_arcs(@graph.edges(g), Zero), @binary.zero())
    _ => None
  }
}

///|
/// Independent certificate checker: capacity bounds, flow conservation,
/// source/sink values, valid cut, and cut capacity equal to flow value.
/// This does not run the residual search or augmenting algorithm.
pub fn check(
  g : @graph.Graph,
  source : @core.Nat,
  sink : @core.Nat,
  result : MaxFlow,
) -> Bool {
  let valid_endpoints = match
    (
      contains(@graph.vertices(g), source),
      contains(@graph.vertices(g), sink),
      @core.compare(source, sink),
    ) {
    (true, true, Less) | (true, true, Greater) => true
    _ => false
  }
  let valid_edges = match @core.zip(@graph.edges(g), result.edges) {
    None => false
    Some(pairs) =>
      @core.all(pairs, fn(pair) {
        let (edge, claimed) = pair
        match
          (
            @core.compare(edge.from, claimed.edge.from),
            @core.compare(edge.to, claimed.edge.to),
            @binary.compare(edge.weight, claimed.edge.weight),
            @binary.compare(claimed.flow, edge.weight),
          ) {
          (Equal, Equal, Equal, Less) | (Equal, Equal, Equal, Equal) => true
          _ => false
        }
      })
  }
  let valid_cut = match
    (contains(result.cut, source), contains(result.cut, sink)) {
    (true, false) =>
      @core.all(result.cut, fn(vertex) { contains(@graph.vertices(g), vertex) })
    _ => false
  }
  let cut_capacity = @core.fold_left(@graph.edges(g), @binary.zero(), fn(
    sum,
    edge,
  ) {
    match (contains(result.cut, edge.from), contains(result.cut, edge.to)) {
      (true, false) => @binary.add(sum, edge.weight)
      _ => sum
    }
  })
  let conserved = @core.all(@graph.vertices(g), fn(vertex) {
    let (incoming, outgoing) = @core.fold_left(
      result.edges,
      (@binary.zero(), @binary.zero()),
      fn(totals, entry) {
        let (incoming, outgoing) = totals
        let incoming = match @core.compare(entry.edge.to, vertex) {
          Equal => @binary.add(incoming, entry.flow)
          _ => incoming
        }
        let outgoing = match @core.compare(entry.edge.from, vertex) {
          Equal => @binary.add(outgoing, entry.flow)
          _ => outgoing
        }
        (incoming, outgoing)
      },
    )
    match (@core.compare(vertex, source), @core.compare(vertex, sink)) {
      (Equal, _) =>
        match @binary.subtract(outgoing, incoming) {
          Some(net) =>
            match @binary.compare(net, result.value) {
              Equal => true
              _ => false
            }
          None => false
        }
      (_, Equal) =>
        match @binary.subtract(incoming, outgoing) {
          Some(net) =>
            match @binary.compare(net, result.value) {
              Equal => true
              _ => false
            }
          None => false
        }
      _ =>
        match @binary.compare(incoming, outgoing) {
          Equal => true
          _ => false
        }
    }
  })
  match
    (
      valid_endpoints,
      valid_edges,
      valid_cut,
      conserved,
      @binary.compare(cut_capacity, result.value),
    ) {
    (true, true, true, true, Equal) => true
    _ => false
  }
}
