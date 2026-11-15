///|
fn nat(n : Int32) -> @core.Nat {
  if n == 0 {
    Zero
  } else {
    Succ(nat(n - 1))
  }
}

///|
fn[A] chain(xs : Array[A]) -> @core.Chain[A] {
  for i = xs.length() - 1, result = @core.Nil; i >= 0; {
    continue i - 1, @core.Cons(xs[i], result)
  } nobreak {
    result
  }
}

///|
fn bool_matrix(xs : Array[Array[Bool]]) -> Matrix[Bool] {
  let width = if xs.is_empty() { 0 } else { xs[0].length() }
  match matrix(nat(width), chain(xs.map(chain))) {
    Some(m) => m
    None => abort("test shape")
  }
}

///|
test "matrix dimensions, transpose, zero dimensions and identity" {
  let a = bool_matrix([[true, false, true], [false, true, false]])
  assert_eq(transpose(transpose(a)), a)
  assert_eq(
    multiply(a, identity(nat(3), @algebra.booleans()), @algebra.booleans()),
    Some(a),
  )
  assert_eq(multiply(a, a, @algebra.booleans()), None)
  assert_eq(matrix(nat(2), chain([chain([true]), chain([false, true])])), None)
  let empty : Matrix[Bool] = { width: nat(3), rows: Nil, }
  assert_eq(transpose(transpose(empty)), empty)
  let zero_width : Matrix[Bool] = { width: nat(0), rows: chain([Nil, Nil]), }
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
  let nine = @binary.from_bits(chain([true, false, false, true]))
  let inf = @algebra.Infinity
  let rows = chain([
    chain([@algebra.Finite(z), Finite(two), Finite(nine)]),
    chain([inf, Finite(z), Finite(three)]),
    chain([inf, inf, Finite(z)]),
  ])
  match matrix(nat(3), rows) {
    None => fail("test shape")
    Some(m) =>
      match warshall(m, @algebra.tropical()) {
        None => fail("square rejected")
        Some(result) =>
          assert_eq(
            @core.nth(@core.drop(nat(0), result.rows), nat(0)).map(fn(row) {
              @core.nth(row, nat(2))
            }),
            Some(Some(@algebra.Finite(@binary.add(two, three)))),
          )
      }
  }
  // Fibonacci Q-matrix, with no integer arithmetic in the implementation.
  let q : Matrix[@binary.Binary] = {
    width: nat(2),
    rows: chain([chain([one, one]), chain([one, z])]),
  }
  match
    power(
      q,
      @binary.from_bits(chain([false, true, false, true])),
      @algebra.naturals(),
    ) {
    None => fail("square rejected")
    Some(result) =>
      assert_eq(
        @core.nth(result.rows, nat(0)).map(fn(row) { @core.nth(row, nat(1)) }),
        Some(Some(@binary.from_nat(nat(55)))),
      )
  }
}
