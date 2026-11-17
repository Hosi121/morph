///|
type Rat = (Int32, Int32)

///|
type Host2 = Array[Array[Rat]]

///|
type Host3 = Array[Host2]

///|
type Host4 = Array[Host3]

///|
struct Fixture {
  name : String
  n : Int32
  metric : Host2
  first : Host3
  second : Host4
  inverse : Host2
  first_kind : Host3
  second_kind : Host3
  lower : Host4
  upper : Host4
  ricci : Host2
  scalar : Rat
  positive : Bool
}

///|
fn rational(value : Rat) -> @exact.Rational {
  let (numerator, denominator) = value
  @oracle.rational(numerator, denominator)
}

///|
fn tensor2(values : Host2) -> Tensor2 {
  @oracle.chain(values.map(fn(row) { @oracle.chain(row.map(rational)) }))
}

///|
fn tensor3(values : Host3) -> Tensor3 {
  @oracle.chain(values.map(tensor2))
}

///|
fn tensor4(values : Host4) -> Tensor4 {
  @oracle.chain(values.map(tensor3))
}

///|
fn matrix(values : Host2, n : Int32) -> @matrix.Matrix[@exact.Rational] {
  @matrix.matrix(@oracle.nat(n), tensor2(values)).unwrap()
}

///|
fn jet_for(f : Fixture) -> MetricJet {
  metric_jet(
    matrix(f.metric, f.n),
    @oracle.chain(f.first.map(fn(value) { matrix(value, f.n) })),
    @oracle.chain(
      f.second.map(fn(row) {
        @oracle.chain(row.map(fn(value) { matrix(value, f.n) }))
      }),
    ),
  ).unwrap()
}

///|
fn constant_jet(values : Host2, n : Int32) -> Result[MetricJet, JetError] {
  let zero = matrix(Array::makei(n, fn(_) { Array::make(n, (0, 1)) }), n)
  metric_jet(
    matrix(values, n),
    @oracle.chain(Array::make(n, zero)),
    @oracle.chain(Array::make(n, @oracle.chain(Array::make(n, zero)))),
  )
}

///|
test "all components match independent Fraction derivative-of-inverse oracle" {
  for f in independent_fixtures() {
    let jet = jet_for(f)
    let c = connection(jet)
    let r = curvature(c)
    assert_eq(dimension(jet), @oracle.nat(f.n), msg=f.name)
    assert_eq(metric(jet), matrix(f.metric, f.n), msg=f.name)
    assert_eq(inverse_metric(jet), matrix(f.inverse, f.n), msg=f.name)
    assert_eq(
      first_derivatives(jet),
      @oracle.chain(f.first.map(fn(value) { matrix(value, f.n) })),
      msg=f.name,
    )
    assert_eq(
      second_derivatives(jet),
      @oracle.chain(
        f.second.map(fn(row) {
          @oracle.chain(row.map(fn(value) { matrix(value, f.n) }))
        }),
      ),
      msg=f.name,
    )
    assert_eq(connection_jet(c), jet, msg=f.name)
    assert_eq(curvature_connection(r), c, msg=f.name)
    assert_eq(christoffel_first(c), tensor3(f.first_kind), msg=f.name)
    assert_eq(christoffel_second(c), tensor3(f.second_kind), msg=f.name)
    assert_eq(lowered_riemann(r), tensor4(f.lower), msg=f.name)
    assert_eq(riemann(r), tensor4(f.upper), msg=f.name)
    assert_eq(ricci(r), tensor2(f.ricci), msg=f.name)
    assert_eq(scalar_curvature(r), rational(f.scalar), msg=f.name)
    assert_eq(is_positive_definite(jet), f.positive, msg=f.name)
  }
}

///|
test "all metric-jet shape symmetry and singularity errors are explicit" {
  let zero = matrix([[(0, 1), (0, 1)], [(0, 1), (0, 1)]], 2)
  let id = matrix([[(1, 1), (0, 1)], [(0, 1), (1, 1)]], 2)
  let asym = matrix([[(1, 1), (1, 1)], [(0, 1), (1, 1)]], 2)
  let first = @oracle.chain([zero, zero])
  let second = @oracle.chain([
    @oracle.chain([zero, zero]),
    @oracle.chain([zero, zero]),
  ])
  assert_eq(metric_jet(matrix([], 2), first, second), Err(MetricShape))
  assert_eq(
    metric_jet(id, @oracle.chain([zero]), second),
    Err(FirstDerivativeShape),
  )
  assert_eq(
    metric_jet(id, @oracle.chain([matrix([], 2), zero]), second),
    Err(FirstDerivativeShape),
  )
  assert_eq(
    metric_jet(id, first, @oracle.chain([@oracle.chain([zero, zero])])),
    Err(SecondDerivativeShape),
  )
  assert_eq(
    metric_jet(
      id,
      first,
      @oracle.chain([@oracle.chain([zero]), @oracle.chain([zero, zero])]),
    ),
    Err(SecondDerivativeShape),
  )
  assert_eq(
    metric_jet(
      id,
      first,
      @oracle.chain([
        @oracle.chain([matrix([], 2), zero]),
        @oracle.chain([zero, zero]),
      ]),
    ),
    Err(SecondDerivativeShape),
  )
  assert_eq(metric_jet(asym, first, second), Err(MetricSymmetry))
  assert_eq(
    metric_jet(id, @oracle.chain([asym, zero]), second),
    Err(FirstDerivativeSymmetry),
  )
  assert_eq(
    metric_jet(
      id,
      first,
      @oracle.chain([@oracle.chain([asym, zero]), @oracle.chain([zero, zero])]),
    ),
    Err(SecondDerivativeSymmetry),
  )
  assert_eq(
    metric_jet(
      id,
      first,
      @oracle.chain([@oracle.chain([zero, id]), @oracle.chain([zero, zero])]),
    ),
    Err(MixedDerivativeSymmetry),
  )
  assert_eq(metric_jet(zero, first, second), Err(SingularMetric))
}

///|
test "dimension zero and indefinite nondegenerate are accepted without positivity claim" {
  let empty = constant_jet([], 0).unwrap()
  assert_eq(dimension(empty), @oracle.nat(0))
  assert_true(is_positive_definite(empty))
  assert_eq(
    scalar_curvature(curvature(connection(empty))),
    @exact.rational_zero(),
  )
  let indefinite = constant_jet([[(0, 1), (1, 1)], [(1, 1), (0, 1)]], 2).unwrap()
  assert_true(!is_positive_definite(indefinite))
  assert_eq(inverse_metric(indefinite), metric(indefinite))
  let negative = constant_jet([[(-1, 1)]], 1).unwrap()
  assert_true(!is_positive_definite(negative))
}

///|
test "component lookup returns None beyond each tensor index" {
  let two = @oracle.nat(2)
  let zero = @oracle.nat(0)
  let jet = constant_jet([[(1, 1), (0, 1)], [(0, 1), (1, 1)]], 2).unwrap()
  let c = connection(jet)
  let r = curvature(c)
  assert_eq(component2(ricci(r), two, zero), None)
  assert_eq(component2(ricci(r), zero, two), None)
  assert_eq(component3(christoffel_second(c), two, zero, zero), None)
  assert_eq(component3(christoffel_second(c), zero, two, zero), None)
  assert_eq(component3(christoffel_second(c), zero, zero, two), None)
  assert_eq(component4(riemann(r), two, zero, zero, zero), None)
  assert_eq(component4(riemann(r), zero, two, zero, zero), None)
  assert_eq(component4(riemann(r), zero, zero, two, zero), None)
  assert_eq(component4(riemann(r), zero, zero, zero, two), None)
  assert_eq(
    component4(riemann(r), zero, zero, zero, zero),
    Some(@exact.rational_zero()),
  )
}

///|
fn vector(values : Array[Rat]) -> @core.Chain[@exact.Rational] {
  @oracle.chain(values.map(rational))
}

///|
test "pointwise vector operations and exact polar geodesic equation" {
  let f = fixture_named("flat_polar_3_2")
  let jet = jet_for(f)
  let c = connection(jet)
  let r = curvature(c)
  let v = vector([(1, 1), (2, 1)])
  let zero = matrix([[(0, 1), (0, 1)], [(0, 1), (0, 1)]], 2)
  assert_eq(lower_index(jet, v), Some(vector([(1, 1), (9, 2)])))
  assert_eq(raise_index(jet, lower_index(jet, v).unwrap()), Some(v))
  assert_eq(pairing(jet, v, v), Some(rational((10, 1))))
  assert_eq(geodesic_acceleration(c, v), Some(vector([(6, 1), (-8, 3)])))
  assert_eq(
    covariant_derivative(c, v, zero),
    Some(matrix([[(0, 1), (4, 3)], [(-3, 1), (2, 3)]], 2)),
  )
  assert_eq(
    covariant_derivative_covector(c, v, zero),
    Some(matrix([[(0, 1), (-4, 3)], [(-4, 3), (3, 2)]], 2)),
  )
  assert_eq(
    sectional_curvature(r, vector([(1, 1), (0, 1)]), vector([(0, 1), (1, 1)])),
    Some(@exact.rational_zero()),
  )
  let nonzero = matrix([[(1, 2), (-2, 3)], [(3, 4), (5, 6)]], 2)
  let actual = covariant_derivative(c, v, nonzero).unwrap()
  assert_eq(
    @matrix.rows(actual),
    tensor2([[(1, 2), (2, 3)], [(-9, 4), (3, 2)]]),
  )
}

///|
test "sphere and Lorentz sectional curvature and degenerate plane guards" {
  let a = vector([(1, 1), (0, 1)])
  let b = vector([(0, 1), (1, 1)])
  for f in independent_fixtures() {
    if f.n == 2 && f.name != "flat_nonlinear_shear" {
      let jet = jet_for(f)
      let r = curvature(connection(jet))
      // In two dimensions every nondegenerate plane has scalar / two.
      assert_eq(
        sectional_curvature(r, a, b),
        Some(@exact.rational_half(scalar_curvature(r))),
        msg=f.name,
      )
      assert_eq(sectional_curvature(r, a, a), None, msg=f.name)
      assert_eq(sectional_curvature(r, a, vector([])), None, msg=f.name)
      assert_eq(
        raise_index(jet, lower_index(jet, a).unwrap()),
        Some(a),
        msg=f.name,
      )
      assert_eq(
        lower_index(jet, raise_index(jet, b).unwrap()),
        Some(b),
        msg=f.name,
      )
    }
  }
  let null_jet = constant_jet([[(-1, 1), (0, 1)], [(0, 1), (1, 1)]], 2).unwrap()
  let null_vector = vector([(1, 1), (1, 1)])
  assert_eq(
    pairing(null_jet, null_vector, null_vector),
    Some(@exact.rational_zero()),
  )
  assert_eq(
    sectional_curvature(
      curvature(connection(null_jet)),
      null_vector,
      null_vector,
    ),
    None,
  )
}

///|
test "vector jet shape errors and zero dimensional operations" {
  let jet = constant_jet([[(-1, 1)]], 1).unwrap()
  let c = connection(jet)
  let empty = matrix([], 0)
  let v = vector([(1, 1)])
  assert_eq(lower_index(jet, vector([])), None)
  assert_eq(raise_index(jet, vector([])), None)
  assert_eq(pairing(jet, v, vector([])), None)
  assert_eq(geodesic_acceleration(c, vector([])), None)
  assert_eq(covariant_derivative(c, vector([]), matrix([[(0, 1)]], 1)), None)
  assert_eq(covariant_derivative(c, v, empty), None)
  assert_eq(covariant_derivative(c, v, matrix([], 1)), None)
  assert_eq(
    covariant_derivative_covector(c, vector([]), matrix([[(0, 1)]], 1)),
    None,
  )
  assert_eq(covariant_derivative_covector(c, v, empty), None)
  let zero_jet = constant_jet([], 0).unwrap()
  let zero_c = connection(zero_jet)
  assert_eq(lower_index(zero_jet, vector([])), Some(vector([])))
  assert_eq(raise_index(zero_jet, vector([])), Some(vector([])))
  assert_eq(
    pairing(zero_jet, vector([]), vector([])),
    Some(@exact.rational_zero()),
  )
  assert_eq(geodesic_acceleration(zero_c, vector([])), Some(vector([])))
  assert_eq(covariant_derivative(zero_c, vector([]), empty), Some(empty))
  assert_eq(
    covariant_derivative_covector(zero_c, vector([]), empty),
    Some(empty),
  )
  assert_eq(
    sectional_curvature(curvature(zero_c), vector([]), vector([])),
    None,
  )
}

///|
test "production curvature identities and metric compatibility on all fixtures" {
  for f in independent_fixtures() {
    let jet = jet_for(f)
    let c = connection(jet)
    let r = curvature(c)
    let gamma = christoffel_second(c)
    let lowered = lowered_riemann(r)
    for i in 0..<f.n {
      for j in 0..<f.n {
        assert_eq(
          component2(ricci(r), @oracle.nat(i), @oracle.nat(j)),
          component2(ricci(r), @oracle.nat(j), @oracle.nat(i)),
          msg=f.name,
        )
        for k in 0..<f.n {
          let mut covariant_metric = rational(f.first[k][i][j])
          for a in 0..<f.n {
            covariant_metric = @exact.rational_subtract(
              covariant_metric,
              @exact.rational_add(
                @exact.rational_multiply(
                  rational(f.metric[a][j]),
                  value3(gamma, @oracle.nat(a), @oracle.nat(k), @oracle.nat(i)),
                ),
                @exact.rational_multiply(
                  rational(f.metric[i][a]),
                  value3(gamma, @oracle.nat(a), @oracle.nat(k), @oracle.nat(j)),
                ),
              ),
            )
          }
          assert_eq(covariant_metric, @exact.rational_zero(), msg=f.name)
          for l in 0..<f.n {
            let (i, j, k, l) = (
              @oracle.nat(i),
              @oracle.nat(j),
              @oracle.nat(k),
              @oracle.nat(l),
            )
            let value = value4(lowered, i, j, k, l)
            assert_eq(
              value,
              @exact.rational_negate(value4(lowered, j, i, k, l)),
              msg=f.name,
            )
            assert_eq(
              value,
              @exact.rational_negate(value4(lowered, i, j, l, k)),
              msg=f.name,
            )
            assert_eq(value, value4(lowered, k, l, i, j), msg=f.name)
            assert_eq(
              @exact.rational_add(
                value,
                @exact.rational_add(
                  value4(lowered, i, k, l, j),
                  value4(lowered, i, l, j, k),
                ),
              ),
              @exact.rational_zero(),
              msg=f.name,
            )
          }
        }
      }
    }
  }
}

///|
fn fixture_named(name : String) -> Fixture {
  let mut chosen = None
  for fixture in independent_fixtures() {
    if fixture.name == name {
      chosen = Some(fixture)
    }
  }
  chosen.unwrap()
}

///|
test "vector covector duality and geodesic contraction on all fixtures" {
  for f in independent_fixtures() {
    let jet = jet_for(f)
    let c = connection(jet)
    let v = vector(Array::makei(f.n, fn(i) { (i + 1, 2) }))
    let w = vector(Array::makei(f.n, fn(i) { (i * 2 - 1, 3) }))
    let p = matrix(
      Array::makei(f.n, fn(i) { Array::makei(f.n, fn(j) { (i - j, 2) }) }),
      f.n,
    )
    let q = matrix(
      Array::makei(f.n, fn(i) { Array::makei(f.n, fn(j) { (i + j, 3) }) }),
      f.n,
    )
    let zero = matrix(
      Array::makei(f.n, fn(_) { Array::make(f.n, (0, 1)) }),
      f.n,
    )
    let dv = covariant_derivative(c, v, p).unwrap()
    let dw = covariant_derivative_covector(c, w, q).unwrap()
    let constant = covariant_derivative(c, v, zero).unwrap()
    let acceleration = geodesic_acceleration(c, v).unwrap()
    assert_eq(
      raise_index(jet, lower_index(jet, v).unwrap()),
      Some(v),
      msg=f.name,
    )
    assert_eq(
      lower_index(jet, raise_index(jet, w).unwrap()),
      Some(w),
      msg=f.name,
    )
    for i in 0..<f.n {
      let mut lhs = @exact.rational_zero()
      let mut rhs = @exact.rational_zero()
      let mut contraction = @exact.rational_zero()
      for j in 0..<f.n {
        let (i, j) = (@oracle.nat(i), @oracle.nat(j))
        lhs = @exact.rational_add(
          lhs,
          @exact.rational_add(
            @exact.rational_multiply(
              value2(@matrix.rows(dw), i, j),
              vector_value(v, j),
            ),
            @exact.rational_multiply(
              vector_value(w, j),
              value2(@matrix.rows(dv), i, j),
            ),
          ),
        )
        rhs = @exact.rational_add(
          rhs,
          @exact.rational_add(
            @exact.rational_multiply(
              value2(@matrix.rows(q), i, j),
              vector_value(v, j),
            ),
            @exact.rational_multiply(
              vector_value(w, j),
              value2(@matrix.rows(p), i, j),
            ),
          ),
        )
        contraction = @exact.rational_subtract(
          contraction,
          @exact.rational_multiply(
            vector_value(v, j),
            value2(@matrix.rows(constant), j, i),
          ),
        )
      }
      assert_eq(lhs, rhs, msg=f.name)
      assert_eq(
        vector_value(acceleration, @oracle.nat(i)),
        contraction,
        msg=f.name,
      )
    }
  }
}
