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
