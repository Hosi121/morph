///|
fn q(n : Int32, d : Int32) -> @exact.Rational {
  @oracle.rational(n, d)
}

///|
fn matrix(
  rows : @core.Chain[@core.Chain[@exact.Rational]],
  width : Int32,
) -> @matrix.Matrix[@exact.Rational] {
  match @matrix.matrix(@oracle.nat(width), rows) {
    Some(value) => value
    None => abort("matrix")
  }
}

///|
fn checked_gaussian(
  mean : @core.Chain[@exact.Rational],
  covariance : @matrix.Matrix[@exact.Rational],
) -> Gaussian {
  match gaussian(mean, covariance) {
    Ok(value) => value
    Err(_) => abort("Gaussian")
  }
}

///|
fn fraction(n : String, negative : Bool, d : String) -> @exact.Rational {
  let numerator = @exact.positive(@oracle.binary_from_hex(n))
  let numerator = if negative { @exact.negate(numerator) } else { numerator }
  match @exact.ratio(numerator, @oracle.binary_from_hex(d)) {
    Some(value) => value
    None => abort("fraction")
  }
}

///|
test "Gaussian constructor rejects indefinite, singular, asymmetric and malformed parameters" {
  let mean = @oracle.chain([q(0, 1), q(0, 1)])
  assert_true(
    gaussian(
      mean,
      matrix(
        @oracle.chain([
          @oracle.chain([q(1, 1), q(2, 1)]),
          @oracle.chain([q(2, 1), q(1, 1)]),
        ]),
        2,
      ),
    )
    is Err(NotPositiveDefinite),
  )
  assert_true(
    gaussian(
      mean,
      matrix(
        @oracle.chain([
          @oracle.chain([q(1, 1), q(1, 1)]),
          @oracle.chain([q(1, 1), q(1, 1)]),
        ]),
        2,
      ),
    )
    is Err(NotPositiveDefinite),
  )
  assert_true(
    gaussian(
      mean,
      matrix(
        @oracle.chain([
          @oracle.chain([q(1, 1), q(1, 1)]),
          @oracle.chain([q(0, 1), q(1, 1)]),
        ]),
        2,
      ),
    )
    is Err(NotSymmetric),
  )
  assert_true(
    gaussian(mean, matrix(@oracle.chain([@oracle.chain([q(1, 1)])]), 1))
    is Err(DimensionMismatch),
  )
  let point = checked_gaussian(@core.Nil, matrix(@core.Nil, 0))
  assert_eq(moment(point, @core.Nil), Ok(q(1, 1)))
  assert_true(
    moment(point, @oracle.chain([@core.Zero])) is Err(DimensionMismatch),
  )
}

///|
test "persistent moment plans preserve context, reuse states and integrate polynomials exactly" {
  let source = checked_gaussian(
    @oracle.chain([q(1, 1), q(-1, 1)]),
    matrix(
      @oracle.chain([
        @oracle.chain([q(2, 1), q(1, 1)]),
        @oracle.chain([q(1, 1), q(2, 1)]),
      ]),
      2,
    ),
  )
  let empty = moments(source)
  let powers = @oracle.chain([@oracle.nat(2), @oracle.nat(2)])
  let (value, plan) = match moment_with(empty, powers) {
    Ok(value) => value
    Err(_) => abort("moment")
  }
  assert_eq(value, q(7, 1))
  assert_eq(cached_moments(empty), @oracle.binary(0))
  assert_eq(moments_source(plan), source)
  let (again, same) = match moment_with(plan, powers) {
    Ok(value) => value
    Err(_) => abort("moment")
  }
  assert_eq(again, value)
  assert_eq(same, plan)
  let p = match
    @polynomial.polynomial(
      @oracle.nat(2),
      @oracle.chain([
        {
          coefficient: q(1, 1),
          exponents: @oracle.chain([@oracle.nat(2), @oracle.nat(2)]),
        },
        {
          coefficient: q(2, 1),
          exponents: @oracle.chain([@oracle.nat(1), @oracle.nat(1)]),
        },
        {
          coefficient: q(-1, 1),
          exponents: @oracle.chain([@core.Zero, @core.Zero]),
        },
      ]),
    ) {
    Ok(value) => value
    Err(_) => abort("polynomial")
  }
  assert_eq(expectation(source, p), Ok(q(6, 1)))
  assert_true(
    expectation(source, @polynomial.zero(@core.Zero)) is Err(DimensionMismatch),
  )
  assert_eq(mean(source), @oracle.chain([q(1, 1), q(-1, 1)]))
  assert_eq(dimension(source), @oracle.nat(2))
  let identity = @matrix.multiply(
    covariance(source),
    precision(source),
    @algebra.rationals(),
  )
  assert_eq(
    identity,
    Some(@matrix.identity(@oracle.nat(2), @algebra.rationals())),
  )
}
