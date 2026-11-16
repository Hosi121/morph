///|
fn arena(
  owners : Array[Bool],
  priorities : Array[Int32],
  edges : Array[Array[Int32]],
) -> Game {
  game(
    @oracle.chain(
      [
        for i in 0..<owners.length() => {
          Position::{
            id: @oracle.nat(i),
            owner: if owners[i] {
              OddPlayer
            } else {
              EvenPlayer
            },
            priority: @oracle.nat(priorities[i]),
            successors: @oracle.chain(edges[i].map(@oracle.nat)),
          }
        }
      ],
    ),
  ).unwrap()
}

///|
fn solve(g : Game) -> Solution raise {
  match run(start(g), @oracle.nat(1024)) {
    Complete(solution) => {
      assert_true(check(g, certificate(solution)))
      solution
    }
    _ => abort("small parity game failed to complete")
  }
}

///|
fn outcomes(g : Game) -> Array[Bool] raise {
  let solution = solve(g)
  @oracle.array(positions(g)).map(fn(p) {
    winner(solution, p.id).unwrap() == OddPlayer
  })
}

///|
test "self loops, cycles, traps and a greatest-priority convention" {
  assert_eq(outcomes(arena([false], [0], [[0]])), [false])
  assert_eq(outcomes(arena([true], [1], [[0]])), [true])
  assert_eq(outcomes(arena([false, true], [1, 2], [[1], [0]])), [false, false])
  assert_eq(outcomes(arena([true, false], [1, 2], [[0, 1], [1]])), [true, false])
  assert_eq(outcomes(arena([false, true], [2, 1], [[0, 1], [1]])), [false, true])
  assert_eq(
    outcomes(arena([false, true, true], [1, 2, 3], [[1, 2], [0], [2]])),
    [false, false, true],
  )
  assert_eq(outcomes(game(Nil).unwrap()), [])
}

///|
test "strategy checker detects bad subcycles even inside a good maximum SCC" {
  // Entire SCC has maximum even priority2, but Odd can stay at its1-loop.
  let g = arena([true, true], [1, 2], [[0, 1], [0]])
  let false_certificate : Certificate = {
    even_region: @oracle.chain([@oracle.nat(0), @oracle.nat(1)]),
    odd_region: Nil,
    even_strategy: Nil,
    odd_strategy: Nil,
  }
  assert_false(check(g, false_certificate))
  assert_eq(outcomes(g), [true, true])
}

///|
test "dead ends, repeated labels, duplicate arcs and undefined edges are invalid" {
  let p = Position::{
    id: @oracle.nat(4),
    owner: EvenPlayer,
    priority: @oracle.nat(7),
    successors: Cons(@oracle.nat(4), Nil),
  }
  assert_true(game(Cons(p, Nil)) is Some(_))
  assert_true(game(@oracle.chain([p, p])) is None)
  assert_true(game(Cons({ ..p, successors: Nil, }, Nil)) is None)
  assert_true(
    game(Cons({ ..p, successors: Cons(@oracle.nat(5), Nil), }, Nil)) is None,
  )
  assert_true(
    game(
      Cons(
        { ..p, successors: @oracle.chain([@oracle.nat(4), @oracle.nat(4)]), },
        Nil,
      ),
    )
    is None,
  )
}

///|
test "fuel pauses and strategy/certificate tampering is rejected" {
  let g = arena([false, true, true], [1, 2, 3], [[1, 2], [0], [2]])
  let initial = start(g)
  assert_eq(run(initial, Zero), Paused(initial))
  let expected = solve(g)
  let mut current = initial
  let mut done = false
  for _ in 0..<1024 {
    match run(current, @oracle.nat(1)) {
      Paused(next) => current = next
      Complete(actual) => {
        assert_eq(actual, expected)
        done = true
        break
      }
      Fault => fail("Zielonka invariant failed")
    }
  }
  assert_true(done)
  let good = certificate(expected)
  assert_true(checked(g, good) is Some(_))
  assert_false(check(g, { ..good, even_region: Nil, }))
  assert_false(check(g, { ..good, even_strategy: Nil, }))
  assert_false(check(g, { ..good, odd_strategy: Nil, }))
  assert_false(
    check(g, {
      ..good,
      even_strategy: Cons(
        { source: @oracle.nat(0), target: @oracle.nat(2), },
        Nil,
      ),
    }),
  )
  assert_eq(winner(expected, @oracle.nat(9)), None)
}
