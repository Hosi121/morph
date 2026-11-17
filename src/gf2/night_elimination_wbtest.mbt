///|
/// Earlier columns are already zero in the basis, so only XOR the active suffix.
fn elimination_legacy_xor_suffix(
  row : @core.Chain[Bool],
  basis : @core.Chain[Bool],
  column : @core.Nat,
) -> @core.Chain[Bool] {
  match (column, row, basis) {
    (Zero, _, _) => xor_rows(row, basis)
    (Succ(rest), Cons(x, xs), Cons(_, ys)) =>
      Cons(x, elimination_legacy_xor_suffix(xs, ys, rest))
    _ => row
  }
}

///|
fn elimination_legacy_eliminate(
  row : @core.Chain[Bool],
  basis : @core.Chain[Bool],
  column : @core.Nat,
) -> @core.Chain[Bool] {
  match @core.nth(row, column) {
    Some(true) => elimination_legacy_xor_suffix(row, basis, column)
    _ => row
  }
}

///|
fn elimination_legacy_reduce(
  rows : @core.Chain[@core.Chain[Bool]],
  todo : @core.Nat,
  column : @core.Nat,
  base : @core.Nat,
  tracked : Bool,
  operations : @core.Chain[Operation],
) -> (
  @core.Chain[@core.Chain[Bool]],
  @core.Chain[@core.Nat],
  @core.Chain[Operation],
) {
  match todo {
    Zero => (rows, Nil, operations)
    Succ(rest) =>
      match select(rows, column) {
        None =>
          elimination_legacy_reduce(
            rows,
            rest,
            Succ(column),
            base,
            tracked,
            operations,
          )
        Some((chosen, others, index)) => {
          let selected = if tracked {
            log_selection(index, base, operations)
          } else {
            operations
          }
          fn below(
            rows : @core.Chain[@core.Chain[Bool]],
            target : @core.Nat,
            log : @core.Chain[Operation],
          ) -> (@core.Chain[@core.Chain[Bool]], @core.Chain[Operation]) {
            match rows {
              Nil => (Nil, log)
              Cons(row, tail) => {
                let nonzero = @core.nth(row, column) is Some(true)
                let next : @core.Chain[Operation] = if tracked && nonzero {
                  Cons(Add(target, base), log)
                } else {
                  log
                }
                let (lower, finished) = below(tail, Succ(target), next)
                (
                  Cons(
                    if nonzero {
                      elimination_legacy_xor_suffix(row, chosen, column)
                    } else {
                      row
                    },
                    lower,
                  ),
                  finished,
                )
              }
            }
          }
          let (lower, below_log) = below(others, Succ(base), selected)
          let (reduced, pivots, lower_log) = elimination_legacy_reduce(
            lower,
            rest,
            Succ(column),
            Succ(base),
            tracked,
            below_log,
          )
          fn above(
            row : @core.Chain[Bool],
            bases : @core.Chain[@core.Chain[Bool]],
            pivots : @core.Chain[@core.Nat],
            source : @core.Nat,
            log : @core.Chain[Operation],
          ) -> (@core.Chain[Bool], @core.Chain[Operation]) {
            match (bases, pivots) {
              (Cons(basis, bt), Cons(pivot, pt)) => {
                let nonzero = @core.nth(row, pivot) is Some(true)
                let next : @core.Chain[Operation] = if tracked && nonzero {
                  Cons(Add(base, source), log)
                } else {
                  log
                }
                above(
                  elimination_legacy_eliminate(row, basis, pivot),
                  bt,
                  pt,
                  Succ(source),
                  next,
                )
              }
              _ => (row, log)
            }
          }
          let (top, finished) = above(
            chosen,
            reduced,
            pivots,
            Succ(base),
            lower_log,
          )
          (Cons(top, reduced), Cons(column, pivots), finished)
        }
      }
  }
}

///|
test "elimination fused probe preserves absent pivots and arbitrary private row shapes" {
  for width in 0..<=5 {
    for basis_width in 0..<=5 {
      for bits in 0..<(1 << width) {
        let row = @oracle.chain(
          Array::makei(width, fn(j) { (bits & (1 << j)) != 0 }),
        )
        for basis_bits in 0..<(1 << basis_width) {
          let basis = @oracle.chain(
            Array::makei(basis_width, fn(j) { (basis_bits & (1 << j)) != 0 }),
          )
          for column in 0..<(width + 2) {
            let column = @oracle.nat(column)
            let changed = @core.nth(row, column) is Some(true)
            let old = elimination_legacy_eliminate(row, basis, column)
            match eliminate_once(row, basis, column) {
              None => {
                assert_false(changed)
                assert_eq(old, row)
              }
              Some(actual) => {
                assert_true(changed)
                assert_eq(actual, old)
              }
            }
          }
        }
      }
    }
  }
}

///|
test "elimination preserves exact reduced rows pivots transform and reverse operation log" {
  for
    (height, width) in [
      (0, 0),
      (0, 7),
      (7, 0),
      (3, 4),
      (8, 12),
      (12, 24),
      (6, 40),
      (24, 12),
    ] {
    for seed in 0..<4 {
      let rows = Array::makei(height, fn(i) {
        Array::makei(width, fn(j) {
          if seed == 0 {
            i == j
          } else if seed == 1 {
            j == i * 3 || j == 25 + i % 7
          } else {
            let k = if seed == 2 { i % 2 } else { i }
            ((k + 1) * 197 + (j + 1) * 269 + k * j * 137 + 19) % 521 % 2 == 0
          }
        })
      })
      let source = input(width, rows)
      let identity = @matrix.identity(@oracle.nat(height), scalars())
      let augmented = @core.map(
        @core.zip(@matrix.rows(source), @matrix.rows(identity)).unwrap(),
        fn(pair) { @core.append(pair.0, pair.1) },
      )
      for tracked in [false, true] {
        assert_eq(
          reduce(
            augmented,
            @oracle.nat(width),
            @core.Zero,
            @core.Zero,
            tracked,
            @core.Nil,
          ),
          elimination_legacy_reduce(
            augmented,
            @oracle.nat(width),
            @core.Zero,
            @core.Zero,
            tracked,
            @core.Nil,
          ),
        )
      }
      let (old, pivots, operations) = elimination_legacy_reduce(
        augmented,
        @oracle.nat(width),
        @core.Zero,
        @core.Zero,
        true,
        @core.Nil,
      )
      let factor = factor(source).unwrap()
      assert_eq(factor.reverse_operations, operations)
      assert_eq(factor.reduction.pivots, pivots)
      assert_eq(
        @matrix.rows(factor.reduction.matrix),
        @core.map(old, fn(row) { @core.take(@oracle.nat(width), row) }),
      )
      assert_eq(
        @matrix.rows(factor.transform),
        @core.map(old, fn(row) { @core.drop(@oracle.nat(width), row) }),
      )
      assert_true(
        check_certificate(
          source,
          factor.reduction,
          certificate(factor).unwrap(),
        ),
      )
    }
  }
}
