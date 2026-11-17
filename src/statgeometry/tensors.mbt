///|
fn from_slices(
  dimension : @core.Nat,
  slices : @infogeom.Tensor,
) -> Result[@tensor.Tensor[@exact.Rational], GeometryError] {
  let reversed = @core.fold_left(slices, @core.Nil, fn(reversed, slice) {
    @core.fold_left(@matrix.rows(slice), reversed, fn(reversed, row) {
      @core.reverse_onto(row, reversed)
    })
  })
  match
    @tensor.from_flat(
      Cons(dimension, Cons(dimension, Cons(dimension, @core.Nil))),
      @core.reverse(reversed),
    ) {
    Ok(value) => Ok(value)
    Err(error) => Err(Tensor(error))
  }
}

///|
pub fn amari_chentsov_tensor(
  model : @infogeom.Model,
) -> Result[@tensor.Tensor[@exact.Rational], GeometryError] {
  match @infogeom.amari_chentsov(model) {
    None => Err(MissingDerivative)
    Some(slices) => from_slices(@infogeom.dimension(model), slices)
  }
}

///|
/// Compatibility name for the covariant Amari-Chentsov tensor.
pub fn cubic_tensor(
  model : @infogeom.Model,
) -> Result[@tensor.Tensor[@exact.Rational], GeometryError] {
  amari_chentsov_tensor(model)
}

///|
/// Output order [i,j,k] contains Gamma^k_ij, raising the last lowered index.
pub fn alpha_raised(
  model : @infogeom.Model,
  alpha : @exact.Rational,
) -> Result[@tensor.Tensor[@exact.Rational], GeometryError] {
  let inverse = match @linear.inverse(@infogeom.fisher(model)) {
    None => return Err(Metric(SingularMetric))
    Some(inverse) => inverse
  }
  let lower = match @infogeom.alpha_lower(model, alpha) {
    None => return Err(MissingDerivative)
    Some(lower) => lower
  }
  match from_slices(@infogeom.dimension(model), lower) {
    Err(error) => Err(error)
    Ok(lower) =>
      match
        @tensor.mode_product(
          lower,
          Succ(Succ(Zero)),
          inverse,
          @algebra.rationals(),
        ) {
        Ok(upper) => Ok(upper)
        Err(error) => Err(Tensor(error))
      }
  }
}

///|
/// Pull back the covariant cubic tensor with J[old parameter,new parameter].
/// Unlike connection coefficients, cubic tensors need only first derivatives.
pub fn pullback_amari_chentsov(
  model : @infogeom.Model,
  jacobian : @matrix.Matrix[@exact.Rational],
) -> Result[@tensor.Tensor[@exact.Rational], GeometryError] {
  let transformed = @matrix.transpose(jacobian)
  let cubic = match amari_chentsov_tensor(model) {
    Ok(value) => value
    Err(error) => return Err(error)
  }
  fn change(
    value : @tensor.Tensor[@exact.Rational],
    axis : @core.Nat,
  ) -> Result[@tensor.Tensor[@exact.Rational], GeometryError] {
    match @tensor.mode_product(value, axis, transformed, @algebra.rationals()) {
      Ok(value) => Ok(value)
      Err(error) => Err(Tensor(error))
    }
  }
  match change(cubic, Zero) {
    Err(error) => Err(error)
    Ok(value) =>
      match change(value, Succ(Zero)) {
        Err(error) => Err(error)
        Ok(value) => change(value, Succ(Succ(Zero)))
      }
  }
}

///|
/// Compatibility name for pullback_amari_chentsov.
pub fn pullback_cubic(
  model : @infogeom.Model,
  jacobian : @matrix.Matrix[@exact.Rational],
) -> Result[@tensor.Tensor[@exact.Rational], GeometryError] {
  pullback_amari_chentsov(model, jacobian)
}

///|
/// Trace Ric_ij g^ij through the shared tensor product and contraction kernels.
pub fn scalar_by_contraction(
  value : @riemann.Curvature,
) -> Result[@exact.Rational, GeometryError] {
  let jet = @riemann.connection_jet(@riemann.curvature_connection(value))
  let d = @riemann.dimension(jet)
  fn matrix_tensor(
    rows : @riemann.Tensor2,
  ) -> Result[@tensor.Tensor[@exact.Rational], GeometryError] {
    let flat = @core.reverse(
      @core.fold_left(rows, @core.Nil, fn(reversed, row) {
        @core.reverse_onto(row, reversed)
      }),
    )
    match @tensor.from_flat(Cons(d, Cons(d, @core.Nil)), flat) {
      Ok(value) => Ok(value)
      Err(error) => Err(Tensor(error))
    }
  }
  let inverse = match
    matrix_tensor(@matrix.rows(@riemann.inverse_metric(jet))) {
    Ok(value) => value
    Err(error) => return Err(error)
  }
  let ricci = match matrix_tensor(@riemann.ricci(value)) {
    Ok(value) => value
    Err(error) => return Err(error)
  }
  let product = @tensor.product(@algebra.rationals(), inverse, ricci)
  let first = match
    @tensor.contract(@algebra.rationals(), product, Zero, Succ(Succ(Zero))) {
    Ok(value) => value
    Err(error) => return Err(Tensor(error))
  }
  match @tensor.contract(@algebra.rationals(), first, Zero, Succ(Zero)) {
    Err(error) => Err(Tensor(error))
    Ok(scalar) =>
      match @tensor.at(scalar, @core.Nil) {
        Ok(value) => Ok(value)
        Err(error) => Err(Tensor(error))
      }
  }
}
