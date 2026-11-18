///|
fn bool_matrix(xs : Array[Array[Bool]]) -> Matrix[Bool] {
  let width = if xs.is_empty() { 0 } else { xs[0].length() }
  match matrix(@oracle.nat(width), @oracle.chain(xs.map(@oracle.chain))) {
    Some(m) => m
    None => abort("test shape")
  }
}

///|
test "matrix dimensions, transpose, zero dimensions and identity" {
  let a = bool_matrix([[true, false, true], [false, true, false]])
  assert_eq(transpose(transpose(a)), a)
  assert_eq(column(a, @oracle.nat(1)), Some(@oracle.chain([false, true])))
  assert_eq(column(a, @oracle.nat(3)), None)
  assert_eq(
    multiply(
      a,
      identity(@oracle.nat(3), @algebra.booleans()),
      @algebra.booleans(),
    ),
    Some(a),
  )
  assert_eq(multiply(a, a, @algebra.booleans()), None)
  assert_eq(
    matrix(
      @oracle.nat(2),
      @oracle.chain([@oracle.chain([true]), @oracle.chain([false, true])]),
    ),
    None,
  )
  let empty : Matrix[Bool] = { width: @oracle.nat(3), rows: Nil, }
  assert_eq(transpose(transpose(empty)), empty)
  let zero_width : Matrix[Bool] = {
    width: @oracle.nat(0),
    rows: @oracle.chain([Nil, Nil]),
  }
  assert_eq(transpose(transpose(zero_width)), zero_width)
}

///|
test "Warshall reachability exhaustive directed graphs on three vertices" {
  for mask in 0..<512 {
    let oracle = Array::make(3, 0).map(fn(_) { Array::make(3, false) })
    for i in 0..<3 {
      for j in 0..<3 {
        oracle[i][j] = i == j || (mask & (1 << (i * 3 + j))) != 0
      }
    }
    let input = bool_matrix(oracle)
    for k in 0..<3 {
      for i in 0..<3 {
        for j in 0..<3 {
          oracle[i][j] = oracle[i][j] || (oracle[i][k] && oracle[k][j])
        }
      }
    }
    assert_eq(warshall(input, @algebra.booleans()), Some(bool_matrix(oracle)))
  }
}

///|
test "min-plus shortest paths and binary matrix exponentiation" {
  let z = @binary.zero()
  let one = @binary.one()
  let two = @binary.double(one)
  let three = @binary.successor(two)
  let nine = @binary.from_bits(@oracle.chain([true, false, false, true]))
  let inf = @algebra.Infinity
  let rows = @oracle.chain([
    @oracle.chain([@algebra.Finite(z), Finite(two), Finite(nine)]),
    @oracle.chain([inf, Finite(z), Finite(three)]),
    @oracle.chain([inf, inf, Finite(z)]),
  ])
  match matrix(@oracle.nat(3), rows) {
    None => fail("test shape")
    Some(m) =>
      match warshall(m, @algebra.tropical()) {
        None => fail("square rejected")
        Some(result) =>
          assert_eq(
            @core.nth(@core.drop(@oracle.nat(0), result.rows), @oracle.nat(0)).map(fn(
                row,
              ) {
                @core.nth(row, @oracle.nat(2))
              },
            ),
            Some(Some(@algebra.Finite(@binary.add(two, three)))),
          )
      }
  }
  // Fibonacci Q-matrix, with no integer arithmetic in the implementation.
  let q : Matrix[@binary.Binary] = {
    width: @oracle.nat(2),
    rows: @oracle.chain([@oracle.chain([one, one]), @oracle.chain([one, z])]),
  }
  match
    power(
      q,
      @binary.from_bits(@oracle.chain([false, true, false, true])),
      @algebra.naturals(),
    ) {
    None => fail("square rejected")
    Some(result) =>
      assert_eq(
        @core.nth(result.rows, @oracle.nat(0)).map(fn(row) {
          @core.nth(row, @oracle.nat(1))
        }),
        Some(Some(@binary.from_nat(@oracle.nat(55)))),
      )
  }
}

///|
type NoncommBlock = (Int32, Int32, Int32, Int32)

///|
test "Warshall preserves snapshot recurrence for noncommutative coefficients" {
  // 2x2 matrices over F_7 form a semiring with noncommutative multiplication.
  fn plus(a : NoncommBlock, b : NoncommBlock) -> NoncommBlock {
    let (a0, a1, a2, a3) = a
    let (b0, b1, b2, b3) = b
    ((a0 + b0) % 7, (a1 + b1) % 7, (a2 + b2) % 7, (a3 + b3) % 7)
  }
  fn times(a : NoncommBlock, b : NoncommBlock) -> NoncommBlock {
    let (a0, a1, a2, a3) = a
    let (b0, b1, b2, b3) = b
    (
      (a0 * b0 + a1 * b2) % 7,
      (a0 * b1 + a1 * b3) % 7,
      (a2 * b0 + a3 * b2) % 7,
      (a2 * b1 + a3 * b3) % 7,
    )
  }
  let ops : @algebra.Semiring[NoncommBlock] = {
    zero: (0, 0, 0, 0),
    one: (1, 0, 0, 1),
    plus,
    times,
  }
  let left : NoncommBlock = (0, 1, 0, 0)
  let right : NoncommBlock = (0, 0, 1, 0)
  assert_true(times(left, right) != times(right, left))
  for n in 0..<5 {
    for seed in 0..<8 {
      let values = Array::makei(n, fn(i) {
        Array::makei(n, fn(j) {
          (
            (seed + i + j * 2) % 7,
            (seed + i * 3 + j + 1) % 7,
            (i + j + 2) % 7,
            (seed + i * 2 + j * 3) % 7,
          )
        })
      })
      let input = matrix(
        @oracle.nat(n),
        @oracle.chain(values.map(@oracle.chain)),
      ).unwrap()
      let mut previous = values
      for k in 0..<n {
        let updated = previous.map(fn(row) { row.copy() })
        for i in 0..<n {
          for j in 0..<n {
            updated[i][j] = plus(
              previous[i][j],
              times(previous[i][k], previous[k][j]),
            )
          }
        }
        previous = updated
      }
      let expected = matrix(
        @oracle.nat(n),
        @oracle.chain(previous.map(@oracle.chain)),
      ).unwrap()
      assert_eq(warshall(input, ops), Some(expected))
    }
  }
}

///|
test "matrix callback grouping remains exact" {
  // Deliberately nonassociative diagnostic callbacks expose operand/grouping drift.
  let ops : @algebra.Semiring[String] = {
    zero: "0",
    one: "1",
    plus: fn(a, b) { "(\{a}+\{b})" },
    times: fn(a, b) { "(\{a}*\{b})" },
  }
  let row = matrix(
    @oracle.nat(3),
    @oracle.chain([@oracle.chain(["a", "b", "c"])]),
  ).unwrap()
  let col = matrix(
    @oracle.nat(1),
    @oracle.chain([
      @oracle.chain(["x"]),
      @oracle.chain(["y"]),
      @oracle.chain(["z"]),
    ]),
  ).unwrap()
  assert_eq(
    rows(multiply(row, col, ops).unwrap()),
    @oracle.chain([@oracle.chain(["((a*x)+((b*y)+((c*z)+0)))"])]),
  )
  let single = matrix(@oracle.nat(1), @oracle.chain([@oracle.chain(["a"])])).unwrap()
  assert_eq(
    rows(warshall(single, ops).unwrap()),
    @oracle.chain([@oracle.chain(["(a+(a*a))"])]),
  )
}

///|
test "Warshall empty singleton and rectangular rejection" {
  let ops = @algebra.booleans()
  for value in [false, true] {
    let single = bool_matrix([[value]])
    assert_eq(warshall(single, ops), Some(single))
  }
  let empty : Matrix[Bool] = matrix(@oracle.nat(0), Nil).unwrap()
  assert_eq(warshall(empty, ops), Some(empty))
  assert_eq(
    warshall(bool_matrix([[true, false, true], [false, true, false]]), ops),
    None,
  )
  let no_rows : Matrix[Bool] = matrix(@oracle.nat(3), Nil).unwrap()
  assert_eq(warshall(no_rows, ops), None)
  assert_eq(warshall(bool_matrix([[], []]), ops), None)
}

///|
test "Warshall all three vertex digraphs agree with positive length DFS" {
  // Unlike the older reflexive fixtures, these 512 graphs vary every diagonal.
  for mask in 0..<512 {
    let edges = Array::makei(3, fn(i) {
      Array::makei(3, fn(j) { (mask & (1 << (i * 3 + j))) != 0 })
    })
    let expected = Array::makei(3, fn(start) {
      let reached = Array::make(3, false)
      let pending = []
      for v in 0..<3 {
        if edges[start][v] {
          pending.push(v)
        }
      }
      while !pending.is_empty() {
        let v = pending.pop().unwrap()
        if !reached[v] {
          reached[v] = true
          for w in 0..<3 {
            if edges[v][w] {
              pending.push(w)
            }
          }
        }
      }
      reached
    })
    assert_eq(
      warshall(bool_matrix(edges), @algebra.booleans()),
      Some(bool_matrix(expected)),
    )
  }
}
