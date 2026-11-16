///|
fn graph_of(n : Int32, edges : Array[(Int32, Int32)]) -> Problem {
  problem(
    @oracle.chain([ for x in 0..<n => @oracle.nat(x) ]),
    @oracle.chain(
      edges.map(fn(edge) {
        let (a, b) = edge
        (@oracle.nat(a), @oracle.nat(b))
      }),
    ),
  ).unwrap()
}

///|
fn graph_mask(n : Int32, mask : Int32) -> Problem {
  let edges = []
  let mut bit = 0
  for a in 0..<n {
    for b in (a + 1)..<n {
      if (mask & (1 << bit)) != 0 {
        edges.push((a, b))
      }
      bit += 1
    }
  }
  graph_of(n, edges)
}

///|
/// Numeric test oracle: choose the first remaining vertex, leave it unmatched or
/// pair it with each remaining neighbor. No alternating forest or contraction.
fn brute(p : Problem) -> Int32 {
  let vertices = @oracle.array(p.vertices).map(@oracle.int_of_nat)
  let edges = @oracle.array(p.edges).map(fn(edge) {
    let (a, b) = edge
    (@oracle.int_of_nat(a), @oracle.int_of_nat(b))
  })
  fn solve(left : Array[Int32]) -> Int32 {
    if left.length() < 2 {
      return 0
    }
    let first = left[0]
    let rest = left[1:].to_owned()
    let mut best = solve(rest)
    for other in rest {
      if edges.any(fn(edge) {
          let (a, b) = edge
          (a == first && b == other) || (a == other && b == first)
        }) {
        let candidate = 1 + solve(rest.filter(fn(x) { x != other }))
        if candidate > best {
          best = candidate
        }
      }
    }
    best
  }
  solve(vertices)
}

///|
test "all 1100 labeled graphs through five vertices agree with independent brute force and barrier checker" {
  let mut count = 0
  for n in 0..<=5 {
    let bits = n * (n - 1) / 2
    for mask in 0..<(1 << bits) {
      let p = graph_mask(n, mask)
      let result = maximum(p).unwrap()
      assert_true(check(p, result))
      assert_eq(@oracle.int_of_nat(@core.length(result.pairs)), brute(p))
      count += 1
    }
  }
  assert_eq(count, 1100)
}

///|
test "all 32768 six vertex graphs agree with an independent exhaustive matching oracle" {
  for mask in 0..<32768 {
    let p = graph_mask(6, mask)
    let pairs = maximum_matching(p).unwrap()
    assert_true(check_matching(p, pairs))
    assert_eq(@oracle.int_of_nat(@core.length(pairs)), brute(p))
  }
}

///|
test "invalid graph constructors, matching seeds, paths and forged certificates" {
  let a = @oracle.nat(0)
  let b = @oracle.nat(1)
  let c = @oracle.nat(2)
  let p = graph_of(3, [(0, 1), (1, 2), (2, 0)])
  assert_eq(problem(@oracle.chain([a, a]), Nil), None)
  assert_eq(problem(@oracle.chain([a]), @oracle.chain([(a, a)])), None)
  assert_eq(problem(@oracle.chain([a]), @oracle.chain([(a, b)])), None)
  let overlapping = @oracle.chain([(a, b), (b, c)])
  assert_false(check_matching(p, overlapping))
  assert_eq(augmenting_search(p, overlapping), None)
  assert_eq(augment(p, Nil, @oracle.chain([a, b, a])), None)
  assert_eq(augment(p, Nil, @oracle.chain([a])), None)
  assert_eq(augment(p, Nil, @oracle.chain([a, b, c])), None)
  assert_false(check(p, { pairs: Nil, barrier: Nil, }))
  assert_false(
    check(p, { pairs: @oracle.chain([(a, b)]), barrier: @oracle.chain([a, a]), }),
  )
  assert_false(
    check(p, {
      pairs: @oracle.chain([(a, b)]),
      barrier: @oracle.chain([@oracle.nat(9)]),
    }),
  )
  assert_eq(certify(p, Nil), None)
}

///|
test "triangle contraction lifts a path through a nonbase boundary vertex in either orientation" {
  let p = graph_of(4, [(0, 1), (1, 2), (2, 0), (1, 3)])
  let seed = @oracle.chain([(@oracle.nat(1), @oracle.nat(2))])
  let cycle = @oracle.chain([0, 1, 2].map(@oracle.nat))
  let quotient = contract(p, cycle, @oracle.nat(0))
  let contracted = contract_edges(seed, cycle, @oracle.nat(0))
  assert_eq(@oracle.array(quotient.vertices).map(@oracle.int_of_nat), [0, 3])
  assert_eq(contracted, Nil)
  let qpath = @oracle.chain([0, 3].map(@oracle.nat))
  for path in [qpath, @core.reverse(qpath)] {
    assert_true(check_augmenting(quotient, contracted, path))
    let lifted = lift(p, seed, cycle, @oracle.nat(0), path).unwrap()
    assert_true(check_augmenting(p, seed, lifted))
    assert_eq(@oracle.int_of_nat(@core.length(lifted)), 4)
    assert_eq(
      @oracle.int_of_nat(@core.length(augment(p, seed, lifted).unwrap())),
      2,
    )
  }
  let result = augmenting_search(p, seed).unwrap()
  assert_true(result.path is Some(_))
  assert_eq(@oracle.int_of_nat(@core.length(result.blossoms)), 1)
}

///|
test "nonempty barrier certifies a star with isolated and odd cycle components" {
  let p = graph_of(9, [(0, 1), (0, 2), (0, 3), (4, 5), (5, 6), (6, 4)])
  let result = maximum(p).unwrap()
  assert_eq(@oracle.int_of_nat(@core.length(result.pairs)), 2)
  assert_eq(@oracle.array(result.barrier).map(@oracle.int_of_nat), [0])
  assert_true(check(p, result))
  assert_false(check(p, { ..result, barrier: Nil, }))
}

///|
test "two nested blossoms contract and lift into the unique six vertex augmenting path" {
  let p = graph_of(6, [(0, 1), (1, 2), (2, 0), (2, 3), (3, 4), (4, 0), (4, 5)])
  let seed = @oracle.chain(
    [(1, 2), (3, 4)].map(fn(edge) {
      let (a, b) = edge
      (@oracle.nat(a), @oracle.nat(b))
    }),
  )
  let result = augmenting_search(p, seed).unwrap()
  assert_eq(@oracle.int_of_nat(@core.length(result.blossoms)), 2)
  let cycles = @oracle.array(result.blossoms).map(fn(xs) {
    @oracle.array(xs).map(@oracle.int_of_nat)
  })
  assert_true(cycles[0].contains(0))
  assert_true(cycles[0].contains(1))
  assert_true(cycles[0].contains(2))
  assert_true(cycles[1].contains(0))
  assert_true(cycles[1].contains(3))
  assert_true(cycles[1].contains(4))
  let path = result.path.unwrap()
  assert_true(check_augmenting(p, seed, path))
  assert_eq(@oracle.int_of_nat(@core.length(path)), 6)
  let next = augment(p, seed, path).unwrap()
  assert_true(check_matching(p, next))
  assert_eq(@oracle.int_of_nat(@core.length(next)), 3)
  assert_true(check(p, certify(p, next).unwrap()))
}

///|
test "stemmed blossom lifts an internal contracted vertex in both path directions" {
  let p = graph_of(6, [(0, 1), (1, 2), (2, 3), (3, 4), (4, 2), (3, 5)])
  let seed = @oracle.chain(
    [(1, 2), (3, 4)].map(fn(edge) {
      let (a, b) = edge
      (@oracle.nat(a), @oracle.nat(b))
    }),
  )
  let cycle = @oracle.chain([2, 3, 4].map(@oracle.nat))
  let base = @oracle.nat(2)
  let qpath = @oracle.chain([0, 1, 2, 5].map(@oracle.nat))
  let quotient = contract(p, cycle, base)
  let qm = contract_edges(seed, cycle, base)
  assert_eq(@oracle.int_of_nat(@core.length(qm)), 1)
  for path in [qpath, @core.reverse(qpath)] {
    assert_true(check_augmenting(quotient, qm, path))
    let lifted = lift(p, seed, cycle, base, path).unwrap()
    assert_true(check_augmenting(p, seed, lifted))
    assert_eq(@oracle.int_of_nat(@core.length(lifted)), 6)
  }
  let unaffected = graph_of(8, [
    (0, 1),
    (1, 2),
    (2, 3),
    (3, 4),
    (4, 2),
    (3, 5),
    (6, 7),
  ])
  let untouched = @oracle.chain([6, 7].map(@oracle.nat))
  assert_eq(lift(unaffected, seed, cycle, base, untouched), Some(untouched))
}

///|
test "all graph and matching seeds through five vertices give complete augmenting searches" {
  let mut seeds = 0
  let mut contracted = 0
  for mask in 0..<1024 {
    let p = graph_mask(5, mask)
    let optimum = brute(p)
    fn visit(
      todo : Array[Int32],
      selected : Array[(@core.Nat, @core.Nat)],
    ) -> Unit raise {
      if todo.length() == 0 {
        let seed = @oracle.chain(selected)
        let result = augmenting_search(p, seed).unwrap()
        assert_eq(result.path is Some(_), selected.length() < optimum)
        match result.path {
          Some(path) => {
            assert_true(check_augmenting(p, seed, path))
            assert_eq(
              @oracle.int_of_nat(@core.length(augment(p, seed, path).unwrap())),
              selected.length() + 1,
            )
          }
          None => assert_true(check(p, certify(p, seed).unwrap()))
        }
        seeds += 1
        if result.blossoms is Cons(_, _) {
          contracted += 1
        }
        return
      }
      let first = todo[0]
      let rest = todo[1:].to_owned()
      visit(rest, selected)
      for other in rest {
        if adjacent(p.edges, @oracle.nat(first), @oracle.nat(other)) {
          let next = selected.copy()
          next.push((@oracle.nat(first), @oracle.nat(other)))
          visit(rest.filter(fn(x) { x != other }), next)
        }
      }
    }
    visit([0, 1, 2, 3, 4], [])
  }
  assert_eq(seeds, 9984)
  assert_true(contracted > 100)
}

///|
test "nonconsecutive labels duplicate undirected edges disconnected graphs and deterministic larger samples" {
  let labels = [9, 2, 20, 7, 31]
  let p = problem(
    @oracle.chain(labels.map(@oracle.nat)),
    @oracle.chain(
      [(9, 2), (2, 9), (9, 2), (2, 20), (20, 9), (7, 31)].map(fn(edge) {
        let (a, b) = edge
        (@oracle.nat(a), @oracle.nat(b))
      }),
    ),
  ).unwrap()
  assert_true(check(p, maximum(p).unwrap()))
  assert_eq(@oracle.int_of_nat(@core.length(maximum_matching(p).unwrap())), 2)
  let mut state = 17
  for sample in 0..<1000 {
    let n = 7 + sample % 4
    let edges = []
    for a in 0..<n {
      for b in (a + 1)..<n {
        state = (state * 25173 + 13849) & 65535
        if state % 100 < sample % 80 + 10 {
          edges.push((a, b))
        }
      }
    }
    let p = graph_of(n, edges)
    let optimum = brute(p)
    let solution = maximum(p).unwrap()
    assert_true(check(p, solution))
    assert_eq(@oracle.int_of_nat(@core.length(solution.pairs)), optimum)
    let reversed : Problem = {
      edges: @core.reverse(p.edges),
      vertices: @core.reverse(p.vertices),
    }
    let reverse_solution = maximum(reversed).unwrap()
    assert_true(check(reversed, reverse_solution))
    assert_eq(@oracle.int_of_nat(@core.length(reverse_solution.pairs)), optimum)
  }
}

///|
/// A conventional numeric connected-component oracle, separate from the kernel.
fn numeric_odd(p : Problem, deleted : Array[Int32]) -> Int32 {
  let labels = @oracle.array(p.vertices).map(@oracle.int_of_nat)
  let edges = @oracle.array(p.edges).map(fn(edge) {
    let (a, b) = edge
    (@oracle.int_of_nat(a), @oracle.int_of_nat(b))
  })
  let remaining = labels.filter(fn(x) { !deleted.contains(x) })
  let seen = []
  let mut odd = 0
  for root in remaining {
    if seen.contains(root) {
      continue
    }
    let stack = [root]
    seen.push(root)
    let mut size = 0
    while stack.length() > 0 {
      let x = stack.pop().unwrap()
      size += 1
      for (a, b) in edges {
        let next = if a == x { b } else if b == x { a } else { -1 }
        if remaining.contains(next) && !seen.contains(next) {
          seen.push(next)
          stack.push(next)
        }
      }
    }
    odd += size % 2
  }
  odd
}

///|
test "all five vertex graph barriers match an independent component counter and reject suboptimal matchings" {
  let mut witnesses = 0
  for mask in 0..<1024 {
    let p = graph_mask(5, mask)
    let pairs = maximum_matching(p).unwrap()
    let k = @oracle.int_of_nat(@core.length(pairs))
    for deleted_mask in 0..<32 {
      let deleted = [ for x in 0..<5 if (deleted_mask & (1 << x)) != 0 => x ]
      let barrier = @oracle.chain(deleted.map(@oracle.nat))
      let expected = 2 * k + numeric_odd(p, deleted) == 5 + deleted.length()
      assert_eq(
        @oracle.int_of_nat(odd_components(p, barrier)),
        numeric_odd(p, deleted),
      )
      assert_eq(check(p, { pairs, barrier, }), expected)
      if expected {
        witnesses += 1
      }
      if k > 0 {
        assert_false(check(p, { pairs: Nil, barrier, }))
      }
    }
  }
  assert_true(witnesses > 1024)
}

///|
test "sixteen levels of nested blossom contraction recursively lift a complete augmenting path" {
  for depth in 1..<=16 {
    let edges = [(0, 1), (1, 2), (2, 0)]
    let seed_edges = [(1, 2)]
    for level in 1..<depth {
      let before = 2 * level
      let odd = before + 1
      let even = before + 2
      edges.push((before, odd))
      edges.push((odd, even))
      edges.push((even, 0))
      seed_edges.push((odd, even))
    }
    edges.push((2 * depth, 2 * depth + 1))
    let p = graph_of(2 * depth + 2, edges)
    let seed = @oracle.chain(
      seed_edges.map(fn(edge) {
        let (a, b) = edge
        (@oracle.nat(a), @oracle.nat(b))
      }),
    )
    let result = augmenting_search(p, seed).unwrap()
    assert_eq(@oracle.int_of_nat(@core.length(result.blossoms)), depth)
    let path = result.path.unwrap()
    assert_true(check_augmenting(p, seed, path))
    assert_eq(@oracle.int_of_nat(@core.length(path)), 2 * depth + 2)
    let pairs = augment(p, seed, path).unwrap()
    assert_true(check_matching(p, pairs))
    assert_eq(@oracle.int_of_nat(@core.length(pairs)), depth + 1)
    assert_true(check(p, certify(p, pairs).unwrap()))
  }
}
