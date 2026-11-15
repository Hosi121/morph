///|
fn graph(n : Int32, edges : Array[(Int32, Int32, Int32)]) -> @graph.Graph {
  let vertices = @oracle.chain([ for i in 0..<n => @oracle.nat(i) ])
  let edges = @oracle.chain(
    edges.map(fn(e) {
      @graph.Edge::{
        from: @oracle.nat(e.0),
        to: @oracle.nat(e.1),
        weight: @oracle.binary(e.2),
      }
    }),
  )
  match @graph.graph(vertices, edges) {
    Some(g) => g
    None => abort("test graph")
  }
}

///|
test "Edmonds-Karp matches all cuts of all four-vertex unit-capacity directed graphs" {
  let candidates = []
  for i in 0..<4 {
    for j in 0..<4 {
      if i != j {
        candidates.push((i, j))
      }
    }
  }
  for mask in 0..<4096 {
    let edges = [
      for i in 0..<12 if (mask & (1 << i)) != 0 => {
        (candidates[i].0, candidates[i].1, 1)
      }
    ]
    let g = graph(4, edges)
    let mut expected = 999
    for cut in 0..<4 {
      fn inside(v : Int32) -> Bool {
        v == 0 || (v == 1 && (cut & 1) != 0) || (v == 2 && (cut & 2) != 0)
      }
      let mut capacity = 0
      for edge in edges {
        if inside(edge.0) && !inside(edge.1) {
          capacity += edge.2
        }
      }
      expected = Int32::min(expected, capacity)
    }
    match max_flow(g, @oracle.nat(0), @oracle.nat(3)) {
      None => fail("valid graph rejected")
      Some(flow) => {
        assert_eq(@oracle.int_of_binary(flow.value), expected)
        assert_true(check(g, @oracle.nat(0), @oracle.nat(3), flow))
      }
    }
  }
}

///|
test "reverse cancellation, parallel and antiparallel edges, self loops and forged certificates" {
  let cancellation = graph(6, [
    (0, 1, 1),
    (1, 3, 1),
    (3, 5, 1),
    (0, 2, 1),
    (2, 3, 1),
    (1, 4, 1),
    (4, 5, 1),
  ])
  match max_flow(cancellation, @oracle.nat(0), @oracle.nat(5)) {
    None => fail("valid graph rejected")
    Some(flow) => {
      assert_eq(@oracle.int_of_binary(flow.value), 2)
      assert_true(check(cancellation, @oracle.nat(0), @oracle.nat(5), flow))
      assert_eq(@oracle.int_of_binary(@oracle.array(flow.edges)[1].flow), 0)
    }
  }
  let g = graph(4, [
    (0, 1, 3),
    (0, 1, 2),
    (1, 0, 1),
    (1, 2, 3),
    (2, 3, 4),
    (1, 3, 2),
    (0, 2, 1),
    (1, 1, 9),
  ])
  match max_flow(g, @oracle.nat(0), @oracle.nat(3)) {
    None => fail("valid graph rejected")
    Some(flow) => {
      assert_eq(@oracle.int_of_binary(flow.value), 6)
      assert_true(check(g, @oracle.nat(0), @oracle.nat(3), flow))
      assert_false(
        check(g, @oracle.nat(0), @oracle.nat(3), {
          value: @oracle.binary(7),
          edges: flow.edges,
          cut: flow.cut,
        }),
      )
      assert_false(
        check(g, @oracle.nat(0), @oracle.nat(3), {
          value: flow.value,
          edges: flow.edges,
          cut: @graph.vertices(g),
        }),
      )
    }
  }
  assert_eq(max_flow(g, @oracle.nat(0), @oracle.nat(0)), None)
  assert_eq(max_flow(g, @oracle.nat(0), @oracle.nat(99)), None)
}
