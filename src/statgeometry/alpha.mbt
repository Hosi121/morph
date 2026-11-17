///|
/// Curvature of an expected alpha connection, using a checked probability jet.
/// Coefficients use [i,j,r] for Gamma^r_ij; curvature uses [r,j,k,l].
#derive(Eq, Debug)
pub struct AlphaGeometry {
  model : @infogeom.Model
  alpha : @exact.Rational
  coefficients : @tensor.Tensor[@exact.Rational]
  derivatives : @tensor.Tensor[@exact.Rational]
  upper : @tensor.Tensor[@exact.Rational]
  lower : @tensor.Tensor[@exact.Rational]
  ricci : @matrix.Matrix[@exact.Rational]
  scalar : @exact.Rational
}

///|
pub extend AlphaGeometry with Eq::{equal, not_equal}

///|
pub extend AlphaGeometry with Debug::{to_repr}

///|
fn matrix_entry(
  value : @matrix.Matrix[@exact.Rational],
  i : @core.Nat,
  j : @core.Nat,
) -> @exact.Rational {
  match @riemann.component2(@matrix.rows(value), i, j) {
    Some(value) => value
    None => @exact.rational_zero()
  }
}

///|
// Internal reads only use the shape-validated coordinate ranges below.
fn tensor_entry(
  value : @tensor.Tensor[@exact.Rational],
  coordinates : @core.Chain[@core.Nat],
) -> @exact.Rational {
  match @tensor.at(value, coordinates) {
    Ok(value) => value
    Err(_) => @exact.rational_zero()
  }
}

///|
fn sum_indices(
  indices : @core.Chain[@core.Nat],
  f : (@core.Nat) -> @exact.Rational,
) -> @exact.Rational {
  @core.fold_left(indices, @exact.rational_zero(), fn(total, i) {
    @exact.rational_add(total, f(i))
  })
}

///|
fn four_tensor(
  d : @core.Nat,
  f : (@core.Nat, @core.Nat, @core.Nat, @core.Nat) -> @exact.Rational,
) -> @tensor.Tensor[@exact.Rational] {
  @tensor.tabulate(Cons(d, Cons(d, Cons(d, Cons(d, Nil)))), fn(coords) {
    match coords {
      Cons(a, Cons(b, Cons(c, Cons(d, Nil)))) => f(a, b, c, d)
      _ => @exact.rational_zero()
    }
  })
}

///|
pub fn alpha_geometry(
  point : @infogeom.ModelPoint,
  alpha : @exact.Rational,
) -> Result[AlphaGeometry, GeometryError] {
  let model = @infogeom.local_model(point)
  let d = @infogeom.dimension(model)
  let indices = @core.indices(d)
  let inverse = match @linear.inverse(@infogeom.fisher(model)) {
    None => return Err(Metric(SingularMetric))
    Some(value) => value
  }
  let lower = match @infogeom.alpha_lower(model, alpha) {
    None => return Err(MissingDerivative)
    Some(slices) =>
      match from_slices(d, slices) {
        Ok(value) => value
        Err(error) => return Err(error)
      }
  }
  let coefficients = match
    @tensor.mode_product(lower, Succ(Succ(Zero)), inverse, @algebra.rationals()) {
    Ok(value) => value
    Err(error) => return Err(Tensor(error))
  }
  let first = match @infogeom.metric_first(model) {
    None => return Err(MissingDerivative)
    Some(slices) =>
      match from_slices(d, slices) {
        Ok(value) => value
        Err(error) => return Err(error)
      }
  }
  let partial_lower = match @infogeom.alpha_lower_first(point, alpha) {
    None => return Err(MissingDerivative)
    Some(value) => value
  }
  fn partial(
    k : @core.Nat,
    i : @core.Nat,
    j : @core.Nat,
    l : @core.Nat,
  ) -> @exact.Rational {
    match @core.nth(partial_lower, k) {
      None => @exact.rational_zero()
      Some(slices) =>
        match @core.nth(slices, i) {
          None => @exact.rational_zero()
          Some(slice) => matrix_entry(slice, j, l)
        }
    }
  }
  fn inverse_partial(
    k : @core.Nat,
    r : @core.Nat,
    s : @core.Nat,
  ) -> @exact.Rational {
    @exact.rational_negate(
      sum_indices(indices, fn(a) {
        sum_indices(indices, fn(b) {
          @exact.rational_multiply(
            @exact.rational_multiply(
              matrix_entry(inverse, r, a),
              tensor_entry(first, Cons(k, Cons(a, Cons(b, Nil)))),
            ),
            matrix_entry(inverse, b, s),
          )
        })
      }),
    )
  }
  let inverse_partials = @tensor.tabulate(Cons(d, Cons(d, Cons(d, Nil))), fn(
    coordinates,
  ) {
    match coordinates {
      Cons(k, Cons(r, Cons(s, Nil))) => inverse_partial(k, r, s)
      _ => @exact.rational_zero()
    }
  })
  let derivatives = four_tensor(d, fn(k, i, j, r) {
    sum_indices(indices, fn(s) {
      @exact.rational_add(
        @exact.rational_multiply(
          tensor_entry(inverse_partials, Cons(k, Cons(r, Cons(s, Nil)))),
          tensor_entry(lower, Cons(i, Cons(j, Cons(s, Nil)))),
        ),
        @exact.rational_multiply(
          matrix_entry(inverse, r, s),
          partial(k, i, j, s),
        ),
      )
    })
  })
  let upper = four_tensor(d, fn(r, j, k, l) {
    let differential = @exact.rational_subtract(
      tensor_entry(derivatives, Cons(k, Cons(l, Cons(j, Cons(r, Nil))))),
      tensor_entry(derivatives, Cons(l, Cons(k, Cons(j, Cons(r, Nil))))),
    )
    let products = sum_indices(indices, fn(m) {
      @exact.rational_subtract(
        @exact.rational_multiply(
          tensor_entry(coefficients, Cons(k, Cons(m, Cons(r, Nil)))),
          tensor_entry(coefficients, Cons(l, Cons(j, Cons(m, Nil)))),
        ),
        @exact.rational_multiply(
          tensor_entry(coefficients, Cons(l, Cons(m, Cons(r, Nil)))),
          tensor_entry(coefficients, Cons(k, Cons(j, Cons(m, Nil)))),
        ),
      )
    })
    @exact.rational_add(differential, products)
  })
  let lower = match
    @tensor.mode_product(
      upper,
      Zero,
      @infogeom.fisher(model),
      @algebra.rationals(),
    ) {
    Ok(value) => value
    Err(error) => return Err(Tensor(error))
  }
  let ricci_tensor = match
    @tensor.contract(@algebra.rationals(), upper, Zero, Succ(Succ(Zero))) {
    Ok(value) => value
    Err(error) => return Err(Tensor(error))
  }
  let ricci = match
    @matrix.matrix(
      d,
      @core.map(indices, fn(j) {
        @core.map(indices, fn(l) {
          tensor_entry(ricci_tensor, Cons(j, Cons(l, Nil)))
        })
      }),
    ) {
    Some(value) => value
    None => return Err(MissingDerivative)
  }
  let scalar = sum_indices(indices, fn(j) {
    sum_indices(indices, fn(l) {
      @exact.rational_multiply(
        matrix_entry(inverse, j, l),
        matrix_entry(ricci, j, l),
      )
    })
  })
  Ok({ model, alpha, coefficients, derivatives, upper, lower, ricci, scalar, })
}

///|
pub fn alpha_model(value : AlphaGeometry) -> @infogeom.Model {
  value.model
}

///|
pub fn alpha_parameter(value : AlphaGeometry) -> @exact.Rational {
  value.alpha
}

///|
pub fn alpha_coefficients(
  value : AlphaGeometry,
) -> @tensor.Tensor[@exact.Rational] {
  value.coefficients
}

///|
/// Derivative order [k,i,j,r] = partial_k Gamma^r_ij.
pub fn alpha_derivatives(
  value : AlphaGeometry,
) -> @tensor.Tensor[@exact.Rational] {
  value.derivatives
}

///|
pub fn alpha_riemann(value : AlphaGeometry) -> @tensor.Tensor[@exact.Rational] {
  value.upper
}

///|
pub fn alpha_lowered_riemann(
  value : AlphaGeometry,
) -> @tensor.Tensor[@exact.Rational] {
  value.lower
}

///|
pub fn alpha_ricci(value : AlphaGeometry) -> @matrix.Matrix[@exact.Rational] {
  value.ricci
}

///|
pub fn alpha_scalar(value : AlphaGeometry) -> @exact.Rational {
  value.scalar
}
