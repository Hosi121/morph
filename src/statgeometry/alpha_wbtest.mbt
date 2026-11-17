///|
fn alpha_required(
  point : @infogeom.ModelPoint,
  alpha : @exact.Rational,
) -> AlphaGeometry {
  match alpha_geometry(point, alpha) {
    Ok(value) => value
    Err(_) => abort("alpha geometry")
  }
}

///|
fn tensor4(
  tensor : @tensor.Tensor[@exact.Rational],
  i : Int32,
  j : Int32,
  k : Int32,
  l : Int32,
) -> @exact.Rational {
  match @tensor.at(tensor, @oracle.chain([i, j, k, l].map(@oracle.nat))) {
    Ok(value) => value
    Err(_) => abort("tensor4")
  }
}

///|
test "alpha simplex curvature equals one minus alpha squared over four" {
  for parameters in [[(1, 6), (1, 3)], [(1, 4), (1, 4)], [(1, 5), (2, 5)]] {
    let p = point(
      [
        polynomial(2, [(1, [1, 0])]),
        polynomial(2, [(1, [0, 1])]),
        polynomial(2, [(1, [0, 0]), (-1, [1, 0]), (-1, [0, 1])]),
      ],
      parameters,
    )
    let metric = @infogeom.fisher(@infogeom.local_model(p))
    for parameter in [(-2, 1), (-1, 1), (0, 1), (1, 1), (2, 1), (3, 5)] {
      let alpha = q(parameter.0, parameter.1)
      let value = alpha_required(p, alpha)
      let sectional = @exact.rational_multiply(
        q(1, 4),
        @exact.rational_subtract(
          q(1, 1),
          @exact.rational_multiply(alpha, alpha),
        ),
      )
      assert_eq(alpha_scalar(value), @exact.rational_add(sectional, sectional))
      assert_eq(alpha_parameter(value), alpha)
      assert_eq(alpha_model(value), @infogeom.local_model(p))
      for i in 0..<2 {
        for j in 0..<2 {
          for k in 0..<2 {
            for l in 0..<2 {
              let g = fn(a, b) {
                matrix_entry(metric, @oracle.nat(a), @oracle.nat(b))
              }
              let expected = @exact.rational_multiply(
                sectional,
                @exact.rational_subtract(
                  @exact.rational_multiply(g(i, k), g(j, l)),
                  @exact.rational_multiply(g(i, l), g(j, k)),
                ),
              )
              assert_eq(
                tensor4(alpha_lowered_riemann(value), i, j, k, l),
                expected,
              )
            }
          }
        }
      }
    }
  }
}

///|
test "zero alpha agrees with independently implemented metric curvature on a curved submodel" {
  let p = point(
    [
      polynomial(2, [(1, [1, 0])]),
      polynomial(2, [(1, [0, 1])]),
      polynomial(2, [(1, [1, 1])]),
      polynomial(2, [(1, [0, 0]), (-1, [1, 0]), (-1, [0, 1]), (-1, [1, 1])]),
    ],
    [(1, 4), (1, 3)],
  )
  let alpha = alpha_required(p, q(0, 1))
  let lc = required(curvature(p))
  assert_eq(alpha_scalar(alpha), @riemann.scalar_curvature(lc))
  assert_eq(@matrix.rows(alpha_ricci(alpha)), @riemann.ricci(lc))
  for i in 0..<2 {
    for j in 0..<2 {
      for k in 0..<2 {
        for l in 0..<2 {
          assert_eq(
            Some(tensor4(alpha_riemann(alpha), i, j, k, l)),
            @riemann.component4(
              @riemann.riemann(lc),
              @oracle.nat(i),
              @oracle.nat(j),
              @oracle.nat(k),
              @oracle.nat(l),
            ),
          )
        }
      }
    }
  }
  let plus = alpha_required(p, q(3, 5))
  let minus = alpha_required(p, q(-3, 5))
  for i in 0..<2 {
    for j in 0..<2 {
      for k in 0..<2 {
        for l in 0..<2 {
          assert_eq(
            tensor4(alpha_lowered_riemann(plus), i, j, k, l),
            @exact.rational_negate(
              tensor4(alpha_lowered_riemann(minus), j, i, k, l),
            ),
          )
        }
      }
    }
  }
}

///|
test "natural exponential and mixture coordinates have flat dual connections" {
  let p = point(
    [
      polynomial(2, [(1, [1, 0])]),
      polynomial(2, [(1, [0, 1])]),
      polynomial(2, [(1, [0, 0]), (-1, [1, 0]), (-1, [0, 1])]),
    ],
    [(1, 6), (1, 3)],
  )
  let base = @infogeom.distribution(@infogeom.local_model(p))
  let statistics = matrix(
    [[(1, 1), (0, 1)], [(0, 1), (1, 1)], [(0, 1), (0, 1)]],
    2,
  )
  let natural = match @infogeom.exponential_point(base, statistics) {
    Ok(value) => value
    Err(_) => abort("natural")
  }
  for point in [p, natural] {
    for a in [-1, 1] {
      let value = alpha_required(point, q(a, 1))
      assert_true(
        @core.all(@tensor.entries(alpha_riemann(value)), fn(x) { x == q(0, 1) }),
      )
    }
  }
  let value = alpha_required(natural, q(1, 1))
  assert_true(
    @core.all(@tensor.entries(alpha_coefficients(value)), fn(x) { x == q(0, 1) }),
  )
  assert_true(
    @core.all(@tensor.entries(alpha_derivatives(value)), fn(x) { x == q(0, 1) }),
  )
  let zero = alpha_required(natural, q(0, 1))
  assert_eq(alpha_scalar(zero), q(1, 2))
}
