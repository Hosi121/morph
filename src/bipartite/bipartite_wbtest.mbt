///|
fn edges(mask : Int32) -> @core.Chain[(@core.Nat, @core.Nat)] {
  @oracle.chain(
    [
      for i in 0..<16 if (mask & (1 << i)) != 0 => {
        (@oracle.nat(i / 4), @oracle.nat(i % 4))
      }
    ],
  )
}

///|
fn brute(mask : Int32) -> Int32 {
  fn assign(left : Int32, used : Int32) -> Int32 {
    if left == 4 {
      return 0
    }
    let mut best = assign(left + 1, used)
    for right in 0..<4 {
      if (used & (1 << right)) == 0 && (mask & (1 << (left * 4 + right))) != 0 {
        let candidate = 1 + assign(left + 1, used | (1 << right))
        if candidate > best {
          best = candidate
        }
      }
    }
    best
  }
  assign(0, 0)
}

///|
test "all 65536 four-by-four bipartite graphs match exhaustive assignment" {
  let vertices = @oracle.chain([0, 1, 2, 3].map(@oracle.nat))
  for mask in 0..<65536 {
    let p = problem(vertices, vertices, edges(mask)).unwrap()
    let result = maximum(p).unwrap()
    assert_true(check(p, result))
    assert_eq(@oracle.int_of_nat(@core.length(result.pairs)), brute(mask))
  }
}

///|
test "matching agrees with independent max-flow reduction and edge order reversal" {
  let vertices = @oracle.chain([0, 1, 2, 3].map(@oracle.nat))
  for sample in 0..<256 {
    let mask = (sample * 7919 + 12345) & 65535
    let pairs = edges(mask)
    let p = problem(vertices, vertices, @core.reverse(pairs)).unwrap()
    let result = maximum(p).unwrap()
    assert_true(check(p, result))
    let flow_edges = []
    for i in 0..<4 {
      flow_edges.push(@graph.Edge::{
        from: @oracle.nat(8),
        to: @oracle.nat(i),
        weight: @binary.one(),
      })
      flow_edges.push(@graph.Edge::{
        from: @oracle.nat(4 + i),
        to: @oracle.nat(9),
        weight: @binary.one(),
      })
    }
    for (a, b) in @oracle.array(pairs) {
      flow_edges.push(@graph.Edge::{
        from: a,
        to: @core.add(@oracle.nat(4), b),
        weight: @binary.one(),
      })
    }
    let graph = @graph.graph(
      @oracle.chain([ for i in 0..<10 => @oracle.nat(i) ]),
      @oracle.chain(flow_edges),
    ).unwrap()
    let flow = @maxflow.max_flow(graph, @oracle.nat(8), @oracle.nat(9)).unwrap()
    assert_true(@maxflow.check(graph, @oracle.nat(8), @oracle.nat(9), flow))
    assert_eq(
      @oracle.int_of_binary(flow.value),
      @oracle.int_of_nat(@core.length(result.pairs)),
    )
  }
}

///|
test "overlapping namespaces, isolated and empty partitions, duplicate edges and forged covers" {
  let a = @oracle.nat(9)
  let b = @oracle.nat(2)
  let c = @oracle.nat(20)
  let p = problem(
    @oracle.chain([a, b, c]),
    @oracle.chain([b, a]),
    @oracle.chain([(a, b), (a, b), (b, a), (c, a)]),
  ).unwrap()
  let result = maximum(p).unwrap()
  assert_eq(@oracle.int_of_nat(@core.length(result.pairs)), 2)
  assert_true(check(p, result))
  assert_false(check(p, { ..result, cover_left: Nil, cover_right: Nil, }))
  assert_false(check(p, { ..result, pairs: @oracle.chain([(a, b), (a, a)]), }))
  assert_false(check(p, { ..result, pairs: @oracle.chain([(a, b), (b, b)]), }))
  assert_false(
    check(p, {
      ..result,
      cover_left: @oracle.chain([@oracle.nat(99)]),
      cover_right: @oracle.chain([b]),
    }),
  )
  for
    p in [
      problem(Nil, Nil, Nil).unwrap(),
      problem(@oracle.chain([a, b]), Nil, Nil).unwrap(),
      problem(Nil, @oracle.chain([a, b]), Nil).unwrap(),
    ] {
    let result = maximum(p).unwrap()
    assert_eq(result.pairs, Nil)
    assert_true(check(p, result))
  }
  assert_eq(problem(@oracle.chain([a, a]), Nil, Nil), None)
  assert_eq(
    problem(@oracle.chain([a]), @oracle.chain([b]), @oracle.chain([(b, a)])),
    None,
  )
}
