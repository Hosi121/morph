///|
fn channel(rows : Array[Array[(Int32, Int32)]]) -> @probability.Channel {
  let rows = @oracle.chain(
    rows.map(fn(row) {
      match @probability.distribution(vector(row)) {
        Some(value) => value
        None => abort("distribution")
      }
    }),
  )
  match @probability.channel(rows) {
    Some(value) => value
    None => abort("channel")
  }
}

///|
fn quadratic(
  matrix : @matrix.Matrix[@exact.Rational],
  a : Int32,
  b : Int32,
) -> @exact.Rational {
  let values = [q(a, 1), q(b, 1)]
  let mut total = q(0, 1)
  for i in 0..<2 {
    for j in 0..<2 {
      total = @exact.rational_add(
        total,
        @exact.rational_multiply(
          @exact.rational_multiply(values[i], values[j]),
          entry(matrix, @oracle.nat(i), @oracle.nat(j)),
        ),
      )
    }
  }
  total
}

///|
test "coarse graining contracts Fisher information and agrees with family pushforward" {
  let coarse = channel([[(1, 1), (0, 1)], [(1, 1), (0, 1)], [(0, 1), (1, 1)]])
  let noisy = channel([[(1, 2), (1, 2)], [(1, 3), (2, 3)], [(1, 4), (3, 4)]])
  let family = checked_family(2, [
    polynomial(2, [(1, 1, [1, 0])]),
    polynomial(2, [(1, 1, [0, 1])]),
    polynomial(2, [(1, 1, [0, 0]), (-1, 1, [1, 0]), (-1, 1, [0, 1])]),
  ])
  for c in [coarse, noisy] {
    let transmitted = match through_family(family, c) {
      Ok(value) => value
      Err(_) => abort("family pushforward")
    }
    for a in 1..<4 {
      for b in 1..<(6 - a) {
        let m = categorical(a, b, 6)
        let reduced = required(through(m, c))
        assert_eq(
          distribution(reduced),
          match @probability.apply(c, distribution(m)) {
            Some(value) => value
            None => abort("apply")
          },
        )
        assert_eq(
          local_model(checked_point(transmitted, [(a, 6), (b, 6)])),
          reduced,
        )
        for x in -2..<=2 {
          for y in -2..<=2 {
            let loss = @exact.rational_subtract(
              quadratic(fisher(m), x, y),
              quadratic(fisher(reduced), x, y),
            )
            assert_true(@exact.rational_compare(loss, q(0, 1)) != @core.Less)
          }
        }
      }
    }
  }
}

///|
test "a sufficient split is Fisher isometric and Bayes reconstructs its probability jets" {
  let zero = mat([[(0, 1)]], 1)
  let m = required(
    model(
      @oracle.nat(1),
      @oracle.chain([
        { probability: q(1, 6), gradient: vector([(1, 3)]), hessian: zero, },
        { probability: q(1, 3), gradient: vector([(2, 3)]), hessian: zero, },
        { probability: q(1, 2), gradient: vector([(-1, 1)]), hessian: zero, },
      ]),
    ),
  )
  let coarse = channel([[(1, 1), (0, 1)], [(1, 1), (0, 1)], [(0, 1), (1, 1)]])
  let reduced = required(through(m, coarse))
  assert_eq(fisher(m), fisher(reduced))
  let inverse = match @probability.bayesian_inverse(coarse, distribution(m)) {
    Some(value) => value
    None => abort("Bayes inverse")
  }
  assert_eq(through(reduced, inverse), Ok(m))
}

///|
test "channels require matching sample spaces and positive output masses for local geometry" {
  let m = categorical(1, 2, 6)
  assert_true(through(m, channel([[(1, 1)]])) is Err(DimensionMismatch))
  assert_true(
    through(m, channel([[(1, 1), (0, 1)], [(1, 1), (0, 1)], [(1, 1), (0, 1)]]))
    is Err(NotInterior),
  )
}
