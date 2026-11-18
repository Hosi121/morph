///|
fn natural(
  base : Array[(Int32, Int32)],
  statistics : Array[Array[(Int32, Int32)]],
  d : Int32,
) -> @infogeom.ExponentialFamily {
  @infogeom.exponential_family(
    @probability.distribution(vec(base)).unwrap(),
    matrix(statistics, d),
  ).unwrap()
}

///|
fn gaussian_point(
  mean : Array[(Int32, Int32)],
  covariance : Array[Array[(Int32, Int32)]],
) -> HessianPoint {
  let source = @gaussian.gaussian(vec(mean), matrix(covariance, mean.length())).unwrap()
  gaussian_hessian(@gaussian.information(source).unwrap()).unwrap()
}

///|
fn riemann_tensor(value : @riemann.Curvature) -> @core.Chain[@exact.Rational] {
  @core.fold_left(@riemann.riemann(value), @core.Nil, fn(result, tensor) {
    @core.fold_left(tensor, result, fn(result, matrix) {
      @core.fold_left(matrix, result, @core.append)
    })
  })
}

///|
test "Hessian natural families reproduce general probability jet alpha geometry" {
  let families = [
    natural([(1, 3), (2, 3)], [[(0, 1)], [(1, 1)]], 1),
    natural(
      [(1, 6), (1, 3), (1, 2)],
      [[(1, 1), (0, 1)], [(0, 1), (1, 1)], [(0, 1), (0, 1)]],
      2,
    ),
    natural(
      [(1, 10), (1, 5), (3, 10), (2, 5)],
      [
        [(2, 1), (1, 1)],
        [(-1, 1), (3, 1)],
        [(1, 1), (-2, 1)],
        [(2, 1), (-1, 1)],
      ],
      2,
    ),
  ]
  for family in families {
    let h = exponential_hessian(family).unwrap()
    let legacy = family.point().unwrap()
    assert_eq(h.exponential_source(), Some(family))
    assert_eq(h.gaussian_source(), None)
    assert_eq(h.metric(), family.fisher())
    assert_eq(h.metric_form().matrix(), Ok(family.fisher()))
    assert_eq(
      h.amari_chentsov(),
      amari_chentsov_tensor(@infogeom.local_model(family.point().unwrap())).unwrap(),
    )
    for alpha in [q(-1, 1), q(0, 1), q(1, 1), q(2, 3), q(-3, 5), q(2, 1)] {
      let actual = h.curvature(alpha)
      let expected = alpha_geometry(legacy, alpha).unwrap()
      assert_eq(actual.alpha(), alpha)
      assert_eq(actual.parent(), h)
      assert_eq(actual.coefficients(), alpha_coefficients(expected))
      assert_eq(actual.riemann(), alpha_riemann(expected))
      assert_eq(actual.lowered_riemann(), Ok(alpha_lowered_riemann(expected)))
      assert_eq(actual.ricci(), Ok(alpha_ricci(expected)))
      assert_eq(actual.scalar(), alpha_scalar(expected))
      let d = @oracle.int_of_nat(h.dimension())
      let uv = @oracle.chain(Array::makei(d, fn(i) { q(i + 1, i + 2) }))
      let vv = @oracle.chain(Array::makei(d, fn(i) { q(2 - i, i + 1) }))
      let wv = @oracle.chain(Array::makei(d, fn(i) { q(i - 2, 3) }))
      let u = h.tangent(uv).unwrap()
      let v = h.tangent(vv).unwrap()
      let w = h.tangent(wv).unwrap()
      let uu = @oracle.array(uv)
      let va = @oracle.array(vv)
      let wa = @oracle.array(wv)
      let components = @oracle.chain(
        Array::makei(d, fn(r) {
          let mut total = q(0, 1)
          for j in 0..<d {
            for k in 0..<d {
              for l in 0..<d {
                let component = @tensor.at(
                  alpha_riemann(expected),
                  @oracle.chain([r, j, k, l].map(@oracle.nat)),
                ).unwrap()
                total = @exact.rational_add(
                  total,
                  @exact.rational_multiply(
                    component,
                    @exact.rational_multiply(
                      uu[k],
                      @exact.rational_multiply(va[l], wa[j]),
                    ),
                  ),
                )
              }
            }
          }
          total
        }),
      )
      assert_eq(actual.apply(u, v, w).unwrap().components(), components)
    }
  }
}

///|
test "categorical exponential Hessian curvature matches the independent sphere identity" {
  let family = natural(
    [(1, 6), (1, 3), (1, 2)],
    [[(1, 1), (0, 1)], [(0, 1), (1, 1)], [(0, 1), (0, 1)]],
    2,
  )
  let point = exponential_hessian(family).unwrap()
  assert_eq(point.curvature(q(0, 1)).scalar(), q(1, 2))
  for alpha in [q(-1, 1), q(0, 1), q(1, 1), q(2, 3)] {
    let actual = point.curvature(alpha)
    let lower = actual.lowered_riemann().unwrap()
    let g = @oracle.array(@matrix.rows(point.metric())).map(@oracle.array)
    let scale = @exact.rational_half(
      @exact.rational_half(
        @exact.rational_subtract(
          q(1, 1),
          @exact.rational_multiply(alpha, alpha),
        ),
      ),
    )
    for i in 0..<2 {
      for j in 0..<2 {
        for k in 0..<2 {
          for l in 0..<2 {
            let expected = @exact.rational_multiply(
              scale,
              @exact.rational_subtract(
                @exact.rational_multiply(g[i][k], g[j][l]),
                @exact.rational_multiply(g[i][l], g[j][k]),
              ),
            )
            assert_eq(
              @tensor.at(lower, @oracle.chain([i, j, k, l].map(@oracle.nat))),
              Ok(expected),
            )
          }
        }
      }
    }
  }
}

///|
test "Gaussian Hessian geometry matches fourth-cumulant general metric route" {
  let points = [
    gaussian_point([(0, 1)], [[(1, 1)]]),
    gaussian_point([(2, 3)], [[(3, 2)]]),
    gaussian_point([(-3, 4)], [[(2, 5)]]),
    gaussian_point([(1, 4), (-2, 3)], [[(2, 1), (1, 3)], [(1, 3), (3, 2)]]),
  ]
  for point in points {
    let info = point.gaussian_source().unwrap()
    assert_eq(point.exponential_source(), None)
    let expected = @riemann.curvature(
      @riemann.connection(@gaussian.fisher_jet(info.parent()).unwrap()),
    )
    let actual = point.curvature(q(0, 1))
    assert_eq(@tensor.entries(actual.riemann()), riemann_tensor(expected))
    assert_eq(@matrix.rows(actual.ricci().unwrap()), @riemann.ricci(expected))
    assert_eq(actual.scalar(), @riemann.scalar_curvature(expected))
    if @oracle.int_of_nat(point.dimension()) == 2 {
      assert_eq(actual.scalar(), q(-1, 1))
    }
    for alpha in [q(-1, 1), q(1, 1)] {
      let flat = point.curvature(alpha)
      assert_true(flat.formula is FlatFormula)
      assert_eq(flat.scalar(), q(0, 1))
      assert_true(
        @core.all(@tensor.entries(flat.riemann()), fn(value) {
          value.equal(q(0, 1))
        }),
      )
    }
  }
}

///|
test "typed musical maps trace and curvature action keep their coordinate context" {
  let point = gaussian_point([(0, 1)], [[(1, 1)]])
  let u = point.tangent(vec([(1, 1), (0, 1)])).unwrap()
  let v = point.tangent(vec([(0, 1), (1, 1)])).unwrap()
  assert_eq(u.add(u).unwrap().scale(q(1, 2)), u)
  assert_eq(
    point.trace().add(point.trace()).unwrap(),
    point.trace().scale(q(2, 1)),
  )
  assert_eq(point.evaluate(point.trace().scale(q(2, 1)), v), Ok(q(12, 1)))
  assert_eq(point.lower_index(v).unwrap().components(), vec([(0, 1), (2, 1)]))
  assert_eq(point.raise_index(point.lower_index(v).unwrap()), Ok(v))
  assert_eq(
    point.lower_index(point.raise_index(point.trace()).unwrap()),
    Ok(point.trace()),
  )
  assert_eq(point.trace().components(), vec([(0, 1), (6, 1)]))
  assert_eq(point.pairing(v, v), Ok(q(2, 1)))
  let curvature = point.curvature(q(0, 1))
  assert_eq(
    curvature.apply(u, v, v).unwrap().components(),
    vec([(-1, 1), (0, 1)]),
  )
  assert_eq(
    curvature.apply(v, u, v).unwrap().components(),
    vec([(1, 1), (0, 1)]),
  )
  assert_eq(
    curvature.apply(u, u, v).unwrap().components(),
    vec([(0, 1), (0, 1)]),
  )
  assert_eq(point.product(u, u), Ok(v))
  let other = gaussian_point([(1, 1)], [[(1, 1)]])
  let foreign = other.tangent(vec([(1, 1), (0, 1)])).unwrap()
  assert_eq(u.add(foreign), Err(PointMismatch))
  assert_eq(point.lower_index(foreign), Err(PointMismatch))
  assert_eq(curvature.apply(foreign, v, v), Err(PointMismatch))
  assert_eq(point.curvature(q(1, 1)).apply(foreign, v, v), Err(PointMismatch))
  assert_true(point.tangent(vec([(1, 1)])) is Err(Tensor(ModeWidthMismatch)))
  let reconstructed = gaussian_point([(0, 1)], [[(1, 1)]])
  assert_true(point.same_coordinates(reconstructed))
  assert_eq(
    reconstructed.lower_index(u).unwrap().components(),
    vec([(1, 1), (0, 1)]),
  )
}

///|
test "equal point tensors do not imply equal charts and singular or empty cases stay explicit" {
  let a = exponential_hessian(
    natural([(1, 2), (1, 2)], [[(0, 1)], [(1, 1)]], 1),
  ).unwrap()
  let b = exponential_hessian(
    natural([(1, 2), (1, 2)], [[(1, 1)], [(0, 1)]], 1),
  ).unwrap()
  assert_eq(a.metric(), b.metric())
  assert_eq(a.amari_chentsov(), b.amari_chentsov())
  assert_false(a.same_coordinates(b))
  assert_eq(
    a.raise_index(b.cotangent(vec([(1, 1)])).unwrap()),
    Err(PointMismatch),
  )
  let redundant = natural([(1, 2), (1, 2)], [[(1, 1)], [(1, 1)]], 1)
  assert_true(exponential_hessian(redundant) is Err(Metric(SingularMetric)))
  let zero = exponential_hessian(natural([(1, 1)], [[]], 0)).unwrap()
  let tangent = zero.tangent(@core.Nil).unwrap()
  assert_eq(zero.raise_index(zero.trace()).unwrap(), tangent)
  assert_eq(zero.curvature(q(2, 3)).scalar(), q(0, 1))
  assert_eq(
    zero.curvature(q(2, 3)).apply(tangent, tangent, tangent),
    Ok(tangent),
  )
  assert_eq(@tensor.entries(zero.curvature(q(0, 1)).riemann()), @core.Nil)
  assert_eq(zero.curvature(q(0, 1)).ricci(), Ok(matrix([], 0)))
}
