///|
fn q(n : Int32, d : Int32) -> @exact.Rational {
  @oracle.rational(n, d)
}

///|
fn polynomial(
  variables : Int32,
  terms : Array[(Int32, Array[Int32])],
) -> @polynomial.Polynomial {
  match
    @polynomial.polynomial(
      @oracle.nat(variables),
      @oracle.chain(
        terms.map(fn(term) {
          {
            coefficient: q(term.0, 1),
            exponents: @oracle.chain(term.1.map(@oracle.nat)),
          }
        }),
      ),
    ) {
    Ok(value) => value
    Err(_) => abort("invalid polynomial")
  }
}

///|
fn point(
  outcomes : Array[@polynomial.Polynomial],
  parameters : Array[(Int32, Int32)],
) -> @infogeom.PolynomialPoint {
  let family = match
    @infogeom.family(@oracle.nat(parameters.length()), @oracle.chain(outcomes)) {
    Ok(value) => value
    Err(_) => abort("family")
  }
  match
    @infogeom.at(
      family,
      @oracle.chain(parameters.map(fn(pair) { q(pair.0, pair.1) })),
    ) {
    Ok(value) => value
    Err(_) => abort("point")
  }
}

///|
fn required(
  value : Result[@riemann.Curvature, GeometryError],
) -> @riemann.Curvature {
  match value {
    Ok(value) => value
    Err(_) => abort("geometry")
  }
}

///|
fn check_constant_curvature(
  value : @riemann.Curvature,
  sectional : @exact.Rational,
  scalar : @exact.Rational,
) -> Unit raise {
  let connection = @riemann.curvature_connection(value)
  let jet = @riemann.connection_jet(connection)
  let g = @matrix.rows(@riemann.metric(jet))
  let n = @oracle.int_of_nat(@riemann.dimension(jet))
  assert_true(@riemann.is_positive_definite(jet))
  assert_eq(@riemann.scalar_curvature(value), scalar)
  fn get(i : Int32, j : Int32) -> @exact.Rational {
    match @riemann.component2(g, @oracle.nat(i), @oracle.nat(j)) {
      Some(x) => x
      None => abort("metric")
    }
  }
  for i in 0..<n {
    for j in 0..<n {
      for k in 0..<n {
        for l in 0..<n {
          let expected = @exact.rational_multiply(
            sectional,
            @exact.rational_subtract(
              @exact.rational_multiply(get(i, k), get(j, l)),
              @exact.rational_multiply(get(i, l), get(j, k)),
            ),
          )
          assert_eq(
            @riemann.component4(
              @riemann.lowered_riemann(value),
              @oracle.nat(i),
              @oracle.nat(j),
              @oracle.nat(k),
              @oracle.nat(l),
            ),
            Some(expected),
          )
        }
      }
    }
  }
}

///|
test "Fisher simplex has constant sectional curvature one quarter" {
  // The independent geometric oracle is the square-root embedding p -> 2 sqrt(p)
  // into a sphere of radius two, hence K=1/4, scalar=d(d-1)/4.
  for a in 1..<4 {
    for b in 1..<(6 - a) {
      let p = point(
        [
          polynomial(2, [(1, [1, 0])]),
          polynomial(2, [(1, [0, 1])]),
          polynomial(2, [(1, [0, 0]), (-1, [1, 0]), (-1, [0, 1])]),
        ],
        [(a, 6), (b, 6)],
      )
      check_constant_curvature(required(curvature(p)), q(1, 4), q(1, 2))
    }
  }
  let p = point(
    [
      polynomial(3, [(1, [1, 0, 0])]),
      polynomial(3, [(1, [0, 1, 0])]),
      polynomial(3, [(1, [0, 0, 1])]),
      polynomial(3, [
        (1, [0, 0, 0]),
        (-1, [1, 0, 0]),
        (-1, [0, 1, 0]),
        (-1, [0, 0, 1]),
      ]),
    ],
    [(1, 5), (1, 5), (1, 5)],
  )
  check_constant_curvature(required(curvature(p)), q(1, 4), q(3, 2))
}

///|
test "nonlinear simplex coordinates preserve curvature and Levi Civita coefficients" {
  let p = point(
    [
      polynomial(2, [(1, [2, 0])]),
      polynomial(2, [(1, [0, 1])]),
      polynomial(2, [(1, [0, 0]), (-1, [2, 0]), (-1, [0, 1])]),
    ],
    [(1, 2), (1, 3)],
  )
  let value = required(curvature(p))
  check_constant_curvature(value, q(1, 4), q(1, 2))
  let lower = @riemann.christoffel_first(@riemann.curvature_connection(value))
  let statistical = match
    @infogeom.alpha_lower(@infogeom.local_model(p), q(0, 1)) {
    Some(value) => value
    None => abort("alpha")
  }
  for i in 0..<2 {
    for j in 0..<2 {
      for k in 0..<2 {
        let slice = match @core.nth(statistical, @oracle.nat(i)) {
          Some(value) => value
          None => abort("slice")
        }
        let expected = @riemann.component2(
          @matrix.rows(slice),
          @oracle.nat(j),
          @oracle.nat(k),
        )
        // Riemann stores the lowered output index first: Gamma_{k i j}.
        assert_eq(
          @riemann.component3(
            lower,
            @oracle.nat(k),
            @oracle.nat(i),
            @oracle.nat(j),
          ),
          expected,
        )
      }
    }
  }
}

///|
test "product Bernoulli family is flat while redundant coordinates have no metric inverse" {
  let p = point(
    [
      polynomial(2, [(1, [1, 1])]),
      polynomial(2, [(1, [1, 0]), (-1, [1, 1])]),
      polynomial(2, [(1, [0, 1]), (-1, [1, 1])]),
      polynomial(2, [(1, [0, 0]), (-1, [1, 0]), (-1, [0, 1]), (1, [1, 1])]),
    ],
    [(1, 3), (2, 5)],
  )
  check_constant_curvature(required(curvature(p)), q(0, 1), q(0, 1))
  let redundant = point(
    [
      polynomial(2, [(1, [1, 0]), (1, [0, 1])]),
      polynomial(2, [(1, [0, 0]), (-1, [1, 0]), (-1, [0, 1])]),
    ],
    [(1, 4), (1, 4)],
  )
  assert_true(fisher_jet(redundant) is Err(Metric(SingularMetric)))
}

///|
test "natural exponential coordinates recover the same constant simplex curvature" {
  let base = match
    @infogeom.family(
      @oracle.nat(2),
      @oracle.chain([
        polynomial(2, [(1, [1, 0])]),
        polynomial(2, [(1, [0, 1])]),
        polynomial(2, [(1, [0, 0]), (-1, [1, 0]), (-1, [0, 1])]),
      ]),
    ) {
    Ok(value) => value
    Err(_) => abort("family")
  }
  for a in 1..<4 {
    for b in 1..<(6 - a) {
      let at = match @infogeom.at(base, @oracle.chain([q(a, 6), q(b, 6)])) {
        Ok(value) => value
        Err(_) => abort("point")
      }
      let distribution = @infogeom.distribution(@infogeom.local_model(at))
      let statistics = match
        @matrix.matrix(
          @oracle.nat(2),
          @oracle.chain([
            @oracle.chain([q(1, 1), q(0, 1)]),
            @oracle.chain([q(0, 1), q(1, 1)]),
            @oracle.chain([q(0, 1), q(0, 1)]),
          ]),
        ) {
        Some(value) => value
        None => abort("statistics")
      }
      let natural = match
        @infogeom.exponential_point(distribution, statistics) {
        Ok(value) => value
        Err(_) => abort("natural jet")
      }
      check_constant_curvature(required(curvature(natural)), q(1, 4), q(1, 2))
    }
  }
}
