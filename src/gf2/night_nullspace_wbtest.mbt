///|
fn night_legacy_row_for(
  pairs : @core.Chain[(@core.Nat, @core.Chain[Bool])],
  variable : @core.Nat,
) -> @core.Chain[Bool]? {
  match pairs {
    Nil => None
    Cons((column, row), rest) =>
      match @core.compare(column, variable) {
        Equal => Some(row)
        _ => night_legacy_row_for(rest, variable)
      }
  }
}

///|
fn night_legacy_nullspace(
  width : @core.Nat,
  pairs : @core.Chain[(@core.Nat, @core.Chain[Bool])],
) -> @core.Chain[@core.Chain[Bool]] {
  let columns = @core.indices(width)
  let free = @core.filter(columns, fn(column) {
    night_legacy_row_for(pairs, column) is None
  })
  @core.map(free, fn(free_column) {
    @core.map(columns, fn(column) {
      match @core.compare(column, free_column) {
        Equal => true
        _ =>
          match night_legacy_row_for(pairs, column) {
            None => false
            Some(row) => @core.nth(row, free_column).equal(Some(true))
          }
      }
    })
  })
}

///|
test "night monotone nullspace preserves frozen lookup basis on pivot gaps and dense free columns" {
  for
    (height, width) in [
      (0, 0),
      (0, 13),
      (7, 0),
      (1, 3),
      (8, 32),
      (16, 32),
      (25, 17),
    ] {
    for seed in 0..<6 {
      let rows = Array::makei(height, fn(i) {
        Array::makei(width, fn(j) {
          if seed == 0 {
            i == j
          } else if seed == 1 {
            j == i * 3 || j == 25 + i % 7
          } else {
            ((i + 1) * 197 + (j + 1) * 269 + seed * 17 + i * j * 137) % 521 % 2 ==
            0
          }
        })
      })
      let factor = factor(input(width, rows)).unwrap()
      let reduced = reduction(factor)
      let pairs = @core.zip(
        reduced.pivots,
        @core.take(@core.length(reduced.pivots), @matrix.rows(reduced.matrix)),
      ).unwrap()
      let wanted = night_legacy_nullspace(@oracle.nat(width), pairs)
      assert_eq(nullspace_factor(factor), wanted)
      let (host_rows, host_pivots) = machine_rref(width, rows)
      let host_basis = []
      for free in 0..<width {
        if !host_pivots.contains(free) {
          let vector = Array::make(width, false)
          vector[free] = true
          for i, pivot in host_pivots {
            vector[pivot] = host_rows[i][free]
          }
          host_basis.push(@oracle.chain(vector))
        }
      }
      assert_eq(wanted, @oracle.chain(host_basis))
      let rhs = @core.replicate(@oracle.nat(height), false)
      assert_eq(solve_factor(factor, rhs), solve(input(width, rows), rhs))
    }
  }
}

///|
test "night nullspace retains zero dimensions unique affine and malformed RHS contracts" {
  for (height, width) in [(0, 0), (0, 7), (5, 0), (1, 1)] {
    let source = input(
      width,
      Array::makei(height, fn(_) { Array::make(width, false) }),
    )
    let factor = factor(source).unwrap()
    let zero = @core.replicate(@oracle.nat(height), false)
    assert_eq(
      solve_factor(factor, zero),
      @rowreduce.solve(field(), source, zero),
    )
    let wrong = @core.Cons(false, zero)
    assert_eq(solve_factor(factor, wrong), None)
    assert_eq(solve(source, wrong), None)
  }
}
