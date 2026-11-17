///|
fn input(width : Int32, rows : Array[Array[Bool]]) -> @matrix.Matrix[Bool] {
  @matrix.matrix(@oracle.nat(width), @oracle.chain(rows.map(@oracle.chain))).unwrap()
}

///|
/// Independent imperative oracle: ordinary indexed Gauss-Jordan elimination.
fn machine_rref(
  width : Int32,
  rows : Array[Array[Bool]],
) -> (Array[Array[Bool]], Array[Int32]) {
  let cells = rows.map(fn(row) { row.copy() })
  let pivots = []
  let mut top = 0
  for column in 0..<width {
    let mut chosen = top
    while chosen < cells.length() && !cells[chosen][column] {
      chosen += 1
    }
    if chosen < cells.length() {
      let row = cells[top]
      cells[top] = cells[chosen]
      cells[chosen] = row
      for target in 0..<cells.length() {
        if target != top && cells[target][column] {
          for index in 0..<width {
            cells[target][index] = cells[target][index] != cells[top][index]
          }
        }
      }
      pivots.push(column)
      top += 1
    }
  }
  (cells, pivots)
}

///|
fn validate_case(
  width : Int32,
  rows : Array[Array[Bool]],
  all_rhs : Bool,
) -> Unit raise {
  let source = input(width, rows)
  let old = @rowreduce.rref(field(), source).unwrap()
  let result = rref(source).unwrap()
  assert_eq(result, old)
  let (expected, pivots) = machine_rref(width, rows)
  assert_eq(
    @oracle.array(@matrix.rows(result.matrix)).map(@oracle.array),
    expected,
  )
  assert_eq(@oracle.array(result.pivots).map(@oracle.int_of_nat), pivots)
  let decomposition = factor(source).unwrap()
  assert_eq(reduction(decomposition), result)
  let witness = certificate(decomposition).unwrap()
  assert_true(check_certificate(source, result, witness))
  assert_eq(inverse(source), @rowreduce.inverse(field(), source))
  assert_eq(determinant(source), @rowreduce.determinant(field(), source))
  let homogeneous = @rowreduce.solve(
    field(),
    source,
    @core.replicate(@oracle.nat(rows.length()), false),
  ).unwrap()
  let expected_basis = match homogeneous {
    Unique(_) => @core.Nil
    Affine(_, basis) => basis
    Inconsistent => abort("homogeneous system inconsistent")
  }
  assert_eq(nullspace_factor(decomposition), expected_basis)
  let rhs_count = if all_rhs { 1 << rows.length() } else { 4 }
  for bits in 0..<rhs_count {
    let rhs = @oracle.chain(
      Array::makei(rows.length(), fn(i) { (bits & (1 << (i % 16))) != 0 }),
    )
    let expected = @rowreduce.solve(field(), source, rhs)
    assert_eq(solve_factor(decomposition, rhs), expected)
    assert_eq(solve(source, rhs), expected)
  }
  assert_eq(
    solve_factor(
      decomposition,
      @core.Cons(false, @core.replicate(@oracle.nat(rows.length()), false)),
    ),
    None,
  )
}

///|
test "exhaustive all binary matrices through 3x3 including every RHS" {
  for height in 0..<4 {
    for width in 0..<4 {
      for bits in 0..<(1 << (width * height)) {
        let rows = Array::makei(height, fn(i) {
          Array::makei(width, fn(j) { (bits & (1 << (i * width + j))) != 0 })
        })
        validate_case(width, rows, true)
      }
    }
  }
}

///|
test "seeded rectangular sparse dense and dependent rows" {
  for
    (height, width) in [
      (0, 9),
      (9, 0),
      (2, 11),
      (11, 2),
      (6, 9),
      (9, 6),
      (8, 8),
    ] {
    for seed in 1..<5 {
      let rows = Array::makei(height, fn(i) {
        Array::makei(width, fn(j) {
          let row = if seed == 3 && i > height / 2 { i % 2 } else { i }
          let value = (
              (row + 1) * 197 + (j + 1) * 269 + seed * 17 + row * j * 137
            ) %
            521
          value % (if seed == 2 { 7 } else { 2 }) == 0
        })
      })
      validate_case(width, rows, false)
    }
  }
}

///|
test "certificate binds source result transforms and pivots" {
  let source = input(3, [
    [false, true, true],
    [true, true, false],
    [true, true, false],
  ])
  let value = factor(source).unwrap()
  let result = reduction(value)
  let witness = certificate(value).unwrap()
  let identity = @matrix.identity(@oracle.nat(3), scalars())
  assert_true(check_certificate(source, result, witness))
  assert_false(check_certificate(identity, result, witness))
  assert_false(check_certificate(source, { ..result, factor: false, }, witness))
  assert_false(
    check_certificate(source, { ..result, pivots: @core.Nil, }, witness),
  )
  assert_false(
    check_certificate(source, { ..result, matrix: identity, }, witness),
  )
  assert_false(
    check_certificate(source, result, { ..witness, source: identity, }),
  )
  assert_false(
    check_certificate(source, result, { ..witness, reduced: identity, }),
  )
  assert_false(
    check_certificate(source, result, { ..witness, transform: identity, }),
  )
  assert_false(
    check_certificate(source, result, {
      ..witness,
      inverse_transform: identity,
    }),
  )
  assert_false(
    check_certificate(source, result, { ..witness, pivots: @core.Nil, }),
  )
  assert_false(
    check_certificate(source, result, { ..witness, transform: input(0, []), }),
  )
  let noncanonical = input(3, [
    [true, true, false],
    [false, true, true],
    [false, false, false],
  ])
  assert_false(
    check_certificate(
      noncanonical,
      {
        matrix: noncanonical,
        pivots: @oracle.chain([@oracle.nat(0), @oracle.nat(1)]),
        factor: true,
      },
      {
        source: noncanonical,
        reduced: noncanonical,
        transform: identity,
        inverse_transform: identity,
        pivots: @oracle.chain([@oracle.nat(0), @oracle.nat(1)]),
      },
    ),
  )
}

///|
test "multiplication dimension and empty boundaries" {
  for (height, shared, width) in [(0, 3, 4), (3, 0, 4), (3, 4, 0), (4, 5, 6)] {
    let left = input(
      shared,
      Array::makei(height, fn(i) {
        Array::makei(shared, fn(j) { (i + j) % 3 == 0 })
      }),
    )
    let right = input(
      width,
      Array::makei(shared, fn(i) {
        Array::makei(width, fn(j) { (i * 3 + j) % 2 == 0 })
      }),
    )
    let actual = multiply(left, right).unwrap()
    let lrows = @oracle.array(@matrix.rows(left)).map(@oracle.array)
    let rrows = @oracle.array(@matrix.rows(right)).map(@oracle.array)
    let expected = Array::makei(height, fn(i) {
      Array::makei(width, fn(j) {
        for k = 0, acc = false; k < shared; {
          continue k + 1, acc != (lrows[i][k] && rrows[k][j])
        } nobreak {
          acc
        }
      })
    })
    assert_eq(@oracle.array(@matrix.rows(actual)).map(@oracle.array), expected)
  }
  assert_eq(multiply(input(1, []), input(0, [])), None)
}
