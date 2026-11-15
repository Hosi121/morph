///|
fn remove_vertex(
  xs : @core.Chain[@core.Nat],
  vertex : @core.Nat,
) -> @core.Chain[@core.Nat] {
  match xs {
    Nil => Nil
    Cons(x, rest) =>
      match @core.compare(x, vertex) {
        Equal => rest
        _ => Cons(x, remove_vertex(rest, vertex))
      }
  }
}

///|
/// Kahn's algorithm, recomputing incoming edges from the remaining vertex set.
/// None means there is a directed cycle, including a self-loop.
pub fn topological(g : Graph) -> @core.Chain[@core.Nat]? {
  fn incoming(
    es : @core.Chain[Edge],
    remaining : @core.Chain[@core.Nat],
    target : @core.Nat,
  ) -> Bool {
    match es {
      Nil => false
      Cons(edge, rest) =>
        match (@core.compare(edge.to, target), contains(remaining, edge.from)) {
          (Equal, true) => true
          _ => incoming(rest, remaining, target)
        }
    }
  }
  fn choose(
    candidates : @core.Chain[@core.Nat],
    remaining : @core.Chain[@core.Nat],
  ) -> @core.Nat? {
    match candidates {
      Nil => None
      Cons(v, rest) =>
        match incoming(g.edges, remaining, v) {
          false => Some(v)
          true => choose(rest, remaining)
        }
    }
  }
  fn walk(
    remaining : @core.Chain[@core.Nat],
    order : @core.Chain[@core.Nat],
  ) -> @core.Chain[@core.Nat]? {
    match remaining {
      Nil => Some(@core.reverse(order))
      _ =>
        match choose(remaining, remaining) {
          None => None
          Some(v) => walk(remove_vertex(remaining, v), Cons(v, order))
        }
    }
  }
  walk(g.vertices, Nil)
}

///|
pub fn transpose(g : Graph) -> Graph {
  {
    vertices: g.vertices,
    edges: @core.map(g.edges, fn(edge) {
      { from: edge.to, to: edge.from, weight: edge.weight, }
    }),
  }
}

///|
/// Kosaraju's two-pass strongly connected components, without mutable colors.
pub fn strongly_connected(g : Graph) -> @core.Chain[@core.Chain[@core.Nat]] {
  fn finish(
    v : @core.Nat,
    seen : @core.Chain[@core.Nat],
    order : @core.Chain[@core.Nat],
  ) -> (@core.Chain[@core.Nat], @core.Chain[@core.Nat]) {
    fn neighbors(
      es : @core.Chain[Edge],
      marked : @core.Chain[@core.Nat],
      finished : @core.Chain[@core.Nat],
    ) -> (@core.Chain[@core.Nat], @core.Chain[@core.Nat]) {
      match es {
        Nil => (marked, finished)
        Cons(edge, rest) =>
          match @core.compare(edge.from, v) {
            Equal => {
              let (next_seen, next_order) = finish(edge.to, marked, finished)
              neighbors(rest, next_seen, next_order)
            }
            _ => neighbors(rest, marked, finished)
          }
      }
    }
    match contains(seen, v) {
      true => (seen, order)
      false => {
        let (next_seen, next_order) = neighbors(g.edges, Cons(v, seen), order)
        (next_seen, Cons(v, next_order))
      }
    }
  }
  let initial : (@core.Chain[@core.Nat], @core.Chain[@core.Nat]) = (Nil, Nil)
  let (_, order) = @core.fold_left(g.vertices, initial, fn(state, v) {
    let (seen, finished) = state
    finish(v, seen, finished)
  })
  let reversed = transpose(g)
  fn collect(
    v : @core.Nat,
    seen : @core.Chain[@core.Nat],
    component : @core.Chain[@core.Nat],
  ) -> (@core.Chain[@core.Nat], @core.Chain[@core.Nat]) {
    match contains(seen, v) {
      true => (seen, component)
      false =>
        @core.fold_left(reversed.edges, (Cons(v, seen), Cons(v, component)), fn(
          state,
          edge,
        ) {
          let (marked, members) = state
          match @core.compare(edge.from, v) {
            Equal => collect(edge.to, marked, members)
            _ => state
          }
        })
    }
  }
  let groups_initial : (
    @core.Chain[@core.Nat],
    @core.Chain[@core.Chain[@core.Nat]],
  ) = (Nil, Nil)
  let (_, components) = @core.fold_left(order, groups_initial, fn(state, v) {
    let (seen, groups) = state
    match contains(seen, v) {
      true => state
      false => {
        let (marked, members) = collect(v, seen, Nil)
        (marked, Cons(@core.reverse(members), groups))
      }
    }
  })
  @core.reverse(components)
}
