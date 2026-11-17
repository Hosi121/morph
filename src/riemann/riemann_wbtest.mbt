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
