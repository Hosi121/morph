///|
fn selected(mask : Int32, index : Int32) -> Bool {
  (mask & (1 << index)) != 0
}

///|
fn numeric_strategies(
  owners : Array[Bool],
  edges : Array[Array[Int32]],
  odd : Bool,
) -> Array[Array[Int32]] {
  let found : Array[Array[Int32]] = []
  fn enumerate(i : Int32, values : Array[Int32]) -> Unit {
    if i == owners.length() {
      found.push(values.copy())
    } else if owners[i] == odd {
      for next in edges[i] {
        values[i] = next
        enumerate(i + 1, values)
      }
    } else {
      values[i] = edges[i][0]
      enumerate(i + 1, values)
    }
  }
  enumerate(0, Array::make(owners.length(), 0))
  found
}

///|
fn numeric_play(
  owners : Array[Bool],
  priorities : Array[Int32],
  even : Array[Int32],
  odd : Array[Int32],
  start : Int32,
) -> Bool {
  let seen = Array::make(owners.length(), -1)
  let path : Array[Int32] = []
  let mut vertex = start
  while seen[vertex] < 0 {
    seen[vertex] = path.length()
    path.push(vertex)
    vertex = if owners[vertex] { odd[vertex] } else { even[vertex] }
  }
  let mut maximum = 0
  for i in seen[vertex]..<path.length() {
    if priorities[path[i]] > maximum {
      maximum = priorities[path[i]]
    }
  }
  maximum % 2 == 1
}

///|
fn numeric_outcomes(
  owners : Array[Bool],
  priorities : Array[Int32],
  edges : Array[Array[Int32]],
) -> Array[Bool] {
  let evens = numeric_strategies(owners, edges, false)
  let odds = numeric_strategies(owners, edges, true)
  [
    for start in 0..<owners.length() => {
      let mut has_even = false
      for even in evens {
        let mut good = true
        for odd in odds {
          if numeric_play(owners, priorities, even, odd, start) {
            good = false
            break
          }
        }
        if good {
          has_even = true
          break
        }
      }
      !has_even
    }
  ]
}

///|
fn numeric_certificate(
  owners : Array[Bool],
  priorities : Array[Int32],
  edges : Array[Array[Int32]],
  odd_region : Int32,
  even : Array[Int32],
  odd : Array[Int32],
) -> Bool {
  fn region(i : Int32) -> Bool {
    selected(odd_region, i)
  }
  for i in 0..<owners.length() {
    if owners[i] == region(i) {
      let next = if owners[i] { odd[i] } else { even[i] }
      if region(next) != region(i) {
        return false
      }
    } else {
      for next in edges[i] {
        if region(next) != region(i) {
          return false
        }
      }
    }
  }
  let evens = numeric_strategies(owners, edges, false)
  let odds = numeric_strategies(owners, edges, true)
  for i in 0..<owners.length() {
    if region(i) {
      for opponent in evens {
        if !numeric_play(owners, priorities, opponent, odd, i) {
          return false
        }
      }
    } else {
      for opponent in odds {
        if numeric_play(owners, priorities, even, opponent, i) {
          return false
        }
      }
    }
  }
  true
}

///|
test "all 74088 total three-position games versus positional strategy enumeration" {
  for arc_code in 0..<343 {
    let edges = [
      for i in 0..<3 => {
        let mask = arc_code / [1, 7, 49][i] % 7 + 1
        [
          for j in 0..<3 if selected(mask, j) => j
        ]
      }
    ]
    for owner_code in 0..<8 {
      let owners = [ for i in 0..<3 => selected(owner_code, i) ]
      for priority_code in 0..<27 {
        let priorities = [ for i in 0..<3 => priority_code / [1, 3, 9][i] % 3 ]
        assert_eq(
          outcomes(arena(owners, priorities, edges)),
          numeric_outcomes(owners, priorities, edges),
          msg="game \{arc_code}/\{owner_code}/\{priority_code}",
        )
      }
    }
  }
}

///|
test "all two-position priority assignments and complete strategy certificate enumeration" {
  for arc_code in 0..<9 {
    let edges = [
      for i in 0..<2 => {
        let mask = arc_code / [1, 3][i] % 3 + 1
        [
          for j in 0..<2 if selected(mask, j) => j
        ]
      }
    ]
    for owner_code in 0..<4 {
      let owners = [ for i in 0..<2 => selected(owner_code, i) ]
      for priority_code in 0..<25 {
        let priorities = [ for i in 0..<2 => priority_code / [1, 5][i] % 5 ]
        let g = arena(owners, priorities, edges)
        assert_eq(outcomes(g), numeric_outcomes(owners, priorities, edges))
        for odd_region in 0..<4 {
          for even in numeric_strategies(owners, edges, false) {
            for odd in numeric_strategies(owners, edges, true) {
              let proof : Certificate = {
                even_region: @oracle.chain(
                  [
                    for i in 0..<2 if !selected(odd_region, i) => @oracle.nat(i)
                  ],
                ),
                odd_region: @oracle.chain(
                  [
                    for i in 0..<2 if selected(odd_region, i) => @oracle.nat(i)
                  ],
                ),
                even_strategy: @oracle.chain(
                  [
                    for i in 0..<2 if !owners[i] && !selected(odd_region, i) => {
                      Move::{
                        source: @oracle.nat(i),
                        target: @oracle.nat(even[i]),
                      }
                    }
                  ],
                ),
                odd_strategy: @oracle.chain(
                  [
                    for i in 0..<2 if owners[i] && selected(odd_region, i) => {
                      Move::{
                        source: @oracle.nat(i),
                        target: @oracle.nat(odd[i]),
                      }
                    }
                  ],
                ),
              }
              assert_eq(
                check(g, proof),
                numeric_certificate(
                  owners, priorities, edges, odd_region, even, odd,
                ),
              )
            }
          }
        }
      }
    }
  }
}

///|
test "one thousand larger arenas and sparse relabeling versus strategy enumeration" {
  let mut seed = 37
  fn next() -> Int32 {
    seed = (seed * 251 + 17) % 65521
    seed
  }
  for _ in 0..<1000 {
    let owners : Array[Bool] = []
    let priorities : Array[Int32] = []
    let edges : Array[Array[Int32]] = []
    for _ in 0..<7 {
      owners.push(next() % 2 == 1)
      priorities.push(next() % 8)
      let a = next() % 7
      let b = next() % 7
      edges.push(if a == b { [a] } else { [a, b] })
    }
    let expected = numeric_outcomes(owners, priorities, edges)
    assert_eq(outcomes(arena(owners, priorities, edges)), expected)
    let ids = [17, 103, 257, 511, 1024, 2049, 4095]
    let sparse = game(
      @oracle.chain(
        [
          for i in 0..<7 => {
            Position::{
              id: @oracle.nat(ids[i]),
              owner: if owners[i] {
                OddPlayer
              } else {
                EvenPlayer
              },
              priority: @oracle.nat(priorities[i] * 2 + priorities[i] % 2),
              successors: @oracle.chain(
                edges[i].map(fn(j) { @oracle.nat(ids[j]) }),
              ),
            }
          }
        ],
      ),
    ).unwrap()
    assert_eq(outcomes(sparse), expected)
  }
}
