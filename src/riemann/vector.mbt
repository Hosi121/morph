///|
fn vector_value(
  values : @core.Chain[@exact.Rational],
  i : @core.Nat,
) -> @exact.Rational {
  match @core.nth(values, i) {
    None => @exact.rational_zero()
    Some(value) => value
  }
}

///|
fn apply_components(
  matrix : Tensor2,
  indices : @core.Chain[@core.Nat],
  vector : @core.Chain[@exact.Rational],
) -> @core.Chain[@exact.Rational] {
  @core.map(indices, fn(i) {
    sum(indices, fn(j) {
      @exact.rational_multiply(value2(matrix, i, j), vector_value(vector, j))
    })
  })
}

///|
/// Lower a contravariant vector index using the pointwise metric.
pub fn lower_index(
  jet : MetricJet,
  vector : @core.Chain[@exact.Rational],
) -> @core.Chain[@exact.Rational]? {
  let n = dimension(jet)
  if !@core.length(vector).equal(n) {
    return None
  }
  Some(apply_components(@matrix.rows(metric(jet)), @core.indices(n), vector))
}

///|
/// Raise a covector index using the checked inverse metric.
pub fn raise_index(
  jet : MetricJet,
  covector : @core.Chain[@exact.Rational],
) -> @core.Chain[@exact.Rational]? {
  let n = dimension(jet)
  if !@core.length(covector).equal(n) {
    return None
  }
  Some(
    apply_components(
      @matrix.rows(inverse_metric(jet)),
      @core.indices(n),
      covector,
    ),
  )
}

///|
/// g(u,v), including indefinite metrics; a null value need not mean a zero vector.
pub fn pairing(
  jet : MetricJet,
  u : @core.Chain[@exact.Rational],
  v : @core.Chain[@exact.Rational],
) -> @exact.Rational? {
  let n = dimension(jet)
  if !@core.length(u).equal(n) || !@core.length(v).equal(n) {
    return None
  }
  let indices = @core.indices(n)
  Some(
    sum(indices, fn(i) {
      sum(indices, fn(j) {
        @exact.rational_multiply(
          value2(@matrix.rows(metric(jet)), i, j),
          @exact.rational_multiply(vector_value(u, i), vector_value(v, j)),
        )
      })
    }),
  )
}

///|
/// Coordinate acceleration of an affinely parameterized geodesic at this point:
/// a^i = -Gamma^i_jk v^j v^k. This does not integrate or construct a geodesic.
pub fn geodesic_acceleration(
  value : Connection,
  velocity : @core.Chain[@exact.Rational],
) -> @core.Chain[@exact.Rational]? {
  let n = dimension(connection_jet(value))
  if !@core.length(velocity).equal(n) {
    return None
  }
  let indices = @core.indices(n)
  Some(
    @core.map(indices, fn(i) {
      @exact.rational_negate(
        sum(indices, fn(j) {
          sum(indices, fn(k) {
            @exact.rational_multiply(
              value3(christoffel_second(value), i, j, k),
              @exact.rational_multiply(
                vector_value(velocity, j),
                vector_value(velocity, k),
              ),
            )
          })
        }),
      )
    }),
  )
}

///|
/// partials[i,j] = partial_i V^j; result[i,j] = nabla_i V^j.
/// A supplied vector one-jet is used; no derivative of an arbitrary function is inferred.
pub fn covariant_derivative(
  value : Connection,
  vector : @core.Chain[@exact.Rational],
  partials : @matrix.Matrix[@exact.Rational],
) -> @matrix.Matrix[@exact.Rational]? {
  let n = dimension(connection_jet(value))
  if !@core.length(vector).equal(n) || !square(partials, n) {
    return None
  }
  let indices = @core.indices(n)
  @matrix.matrix(
    n,
    table2(indices, fn(i, j) {
      @exact.rational_add(
        value2(@matrix.rows(partials), i, j),
        sum(indices, fn(k) {
          @exact.rational_multiply(
            value3(christoffel_second(value), j, i, k),
            vector_value(vector, k),
          )
        }),
      )
    }),
  )
}

///|
/// partials[i,j] = partial_i omega_j; result[i,j] = nabla_i omega_j.
pub fn covariant_derivative_covector(
  value : Connection,
  covector : @core.Chain[@exact.Rational],
  partials : @matrix.Matrix[@exact.Rational],
) -> @matrix.Matrix[@exact.Rational]? {
  let n = dimension(connection_jet(value))
  if !@core.length(covector).equal(n) || !square(partials, n) {
    return None
  }
  let indices = @core.indices(n)
  @matrix.matrix(
    n,
    table2(indices, fn(i, j) {
      @exact.rational_subtract(
        value2(@matrix.rows(partials), i, j),
        sum(indices, fn(k) {
          @exact.rational_multiply(
            value3(christoffel_second(value), k, i, j),
            vector_value(covector, k),
          )
        }),
      )
    }),
  )
}

///|
/// R(u,v,u,v)/(g(u,u)g(v,v)-g(u,v)^two). Defined for nondegenerate planes,
/// also in indefinite signature. None means wrong vector size or zero denominator.
pub fn sectional_curvature(
  value : Curvature,
  u : @core.Chain[@exact.Rational],
  v : @core.Chain[@exact.Rational],
) -> @exact.Rational? {
  let jet = connection_jet(curvature_connection(value))
  match (pairing(jet, u, u), pairing(jet, v, v), pairing(jet, u, v)) {
    (Some(uu), Some(vv), Some(uv)) => {
      let indices = @core.indices(dimension(jet))
      let numerator = sum(indices, fn(i) {
        sum(indices, fn(j) {
          sum(indices, fn(k) {
            sum(indices, fn(l) {
              @exact.rational_multiply(
                value4(lowered_riemann(value), i, j, k, l),
                @exact.rational_multiply(
                  @exact.rational_multiply(
                    vector_value(u, i),
                    vector_value(v, j),
                  ),
                  @exact.rational_multiply(
                    vector_value(u, k),
                    vector_value(v, l),
                  ),
                ),
              )
            })
          })
        })
      })
      @exact.rational_divide(
        numerator,
        @exact.rational_subtract(
          @exact.rational_multiply(uu, vv),
          @exact.rational_multiply(uv, uv),
        ),
      )
    }
    _ => None
  }
}
