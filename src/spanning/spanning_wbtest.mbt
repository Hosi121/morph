///|
fn graph(n : Int32, edges : Array[(Int32, Int32, Int32)]) -> @graph.Graph {
  let vertices = @oracle.chain([ for i in 0..<n => @oracle.nat(i) ])
  let es = @oracle.chain(
    edges.map(fn(e) {
      @graph.Edge::{
        from: @oracle.nat(e.0),
        to: @oracle.nat(e.1),
        weight: @oracle.binary(e.2),
      }
    }),
  )
  match @graph.graph(vertices, es) {
    Some(g) => g
    None => abort("test graph")
  }
}

///|
fn brute(edges : Array[(Int32, Int32, Int32)]) -> (Int32, Int32) {
  let mut most = -1
  let mut best = 999
  for subset in 0..<(1 << edges.length()) {
    let parent = [0, 1, 2, 3]
    fn root(x : Int32) -> Int32 {
      for x = x; parent[x] != x; {
        continue parent[x]
      } nobreak {
        x
      }
    }
    let mut count = 0
    let mut total = 0
    let mut valid = true
    for i, e in edges {
      if (subset & (1 << i)) != 0 {
        let a = root(e.0)
        let b = root(e.1)
        if a == b {
          valid = false
        } else {
          parent[a] = b
          count += 1
          total += e.2
        }
      }
    }
    if valid && (count > most || (count == most && total < best)) {
      most = count
      best = total
    }
  }
  (most, best)
}

///|
test "Kruskal and Prim match exhaustive forests for all small weighted four-vertex graphs" {
  let endpoints = [(0, 1), (0, 2), (0, 3), (1, 2), (1, 3), (2, 3)]
  for code in 0..<4096 {
    let mut digits = code
    let edges = []
    for (from, to) in endpoints {
      let digit = digits % 4
      digits /= 4
      if digit != 0 {
        edges.push((from, to, digit - 1))
      }
    }
    let g = graph(4, edges)
    let (count, weight) = brute(edges)
    for algorithm in [kruskal, prim] {
      let forest = algorithm(g)
      assert_eq(@oracle.int_of_nat(@core.length(forest.edges)), count)
      assert_eq(@oracle.int_of_binary(forest.total), weight)
      assert_true(check(g, forest))
    }
  }
}

///|
test "parallel edges, self loops, isolated vertices and forged forests" {
  let g = graph(4, [(0, 1, 4), (0, 1, 1), (1, 2, 2), (2, 0, 9), (1, 1, 0)])
  let forest = kruskal(g)
  assert_eq(@oracle.int_of_binary(forest.total), 3)
  assert_true(check(g, forest))
  assert_eq(@oracle.int_of_binary(prim(g).total), 3)
  assert_false(check(g, { edges: forest.edges, total: @oracle.binary(4), }))
  assert_false(check(g, { edges: @graph.edges(g), total: @oracle.binary(16), }))
  assert_eq(kruskal(graph(0, [])), Forest::{
    edges: Nil,
    total: @oracle.binary(0),
  })
}
