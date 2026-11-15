///|
fn make_graph(n : Int32, es : Array[(Int32, Int32, Int32)]) -> Graph {
  let vertices = @oracle.chain([ for i in 0..<n => @oracle.nat(i) ])
  let edges = @oracle.chain(
    es.map(fn(e) {
      Edge::{
        from: @oracle.nat(e.0),
        to: @oracle.nat(e.1),
        weight: @oracle.binary(e.2),
      }
    }),
  )
  match graph(vertices, edges) {
    Some(g) => g
    None => abort("test graph")
  }
}

///|
test "Dijkstra and BFS exhaust all directed three-vertex unit graphs" {
  for mask in 0..<512 {
    let es = []
    let dist = Array::make(3, 0).map(fn(_) { Array::make(3, 999) })
    for i in 0..<3 {
      dist[i][i] = 0
      for j in 0..<3 {
        if (mask & (1 << (i * 3 + j))) != 0 {
          es.push((i, j, 1))
          if i != j {
            dist[i][j] = 1
          }
        }
      }
    }
    for k in 0..<3 {
      for i in 0..<3 {
        for j in 0..<3 {
          dist[i][j] = Int32::min(dist[i][j], dist[i][k] + dist[k][j])
        }
      }
    }
    let g = make_graph(3, es)
    for source in 0..<3 {
      for search in [bfs, dijkstra] {
        match search(g, @oracle.nat(source)) {
          None => fail("source rejected")
          Some(visits) =>
            for target in 0..<3 {
              match lookup(visits, @oracle.nat(target)) {
                None => assert_eq(dist[source][target], 999)
                Some(visit) => {
                  assert_eq(
                    @oracle.int_of_binary(visit.distance),
                    dist[source][target],
                  )
                  match path(visits, @oracle.nat(target)) {
                    None => fail("missing path")
                    Some(route) =>
                      assert_eq(
                        @oracle.array(route).length(),
                        dist[source][target] + 1,
                      )
                  }
                }
              }
            }
        }
      }
    }
  }
}

///|
test "weighted Dijkstra handles zero edges, parallel edges and stale entries" {
  let g = make_graph(5, [
    (0, 1, 9),
    (0, 1, 4),
    (0, 2, 1),
    (2, 1, 1),
    (1, 3, 0),
    (2, 3, 8),
    (3, 0, 0),
  ])
  match dijkstra(g, @oracle.nat(0)) {
    None => fail("source rejected")
    Some(visits) => {
      assert_eq(
        lookup(visits, @oracle.nat(3)).map(fn(v) {
          @oracle.int_of_binary(v.distance)
        }),
        Some(2),
      )
      assert_eq(
        path(visits, @oracle.nat(3)).map(fn(xs) {
          @oracle.array(xs).map(@oracle.int_of_nat)
        }),
        Some([0, 2, 1, 3]),
      )
      assert_eq(path(visits, @oracle.nat(4)), None)
    }
  }
  assert_eq(bfs(g, @oracle.nat(99)), None)
  assert_eq(graph(@oracle.chain([@oracle.nat(0), @oracle.nat(0)]), Nil), None)
  assert_eq(
    graph(
      @oracle.chain([@oracle.nat(0)]),
      @oracle.chain([
        Edge::{
          from: @oracle.nat(0),
          to: @oracle.nat(1),
          weight: @oracle.binary(1),
        },
      ]),
    ),
    None,
  )
  let bad = @oracle.chain([
    Visit::{
      vertex: @oracle.nat(0),
      distance: @oracle.binary(0),
      predecessor: Some(@oracle.nat(0)),
    },
  ])
  assert_eq(path(bad, @oracle.nat(0)), None)
}
