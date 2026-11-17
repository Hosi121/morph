///|
/// A covariant cubic tensor and its contractions with a nondegenerate Fisher metric.
/// All component arrays use [i,j,k]; difference raises the last index.
#derive(Eq, Debug)
pub struct AmariChentsov {
  metric : @matrix.Matrix[@exact.Rational]
  covariant : @tensor.Tensor[@exact.Rational]
  difference : @tensor.Tensor[@exact.Rational]
  contravariant : @tensor.Tensor[@exact.Rational]
  trace : @core.Chain[@exact.Rational]
  norm_squared : @exact.Rational
}

///|
pub extend AmariChentsov with Eq::{equal, not_equal}

///|
pub extend AmariChentsov with Debug::{to_repr}

///|
fn prepare_amari(
  metric : @matrix.Matrix[@exact.Rational],
  covariant : @tensor.Tensor[@exact.Rational],
) -> Result[AmariChentsov, GeometryError] {
  let inverse = match @linear.inverse(metric) {
    None => return Err(Metric(SingularMetric))
    Some(value) => value
  }
  fn raise_axis(
    value : @tensor.Tensor[@exact.Rational],
    axis : @core.Nat,
  ) -> Result[@tensor.Tensor[@exact.Rational], GeometryError] {
    match @tensor.mode_product(value, axis, inverse, @algebra.rationals()) {
      Ok(value) => Ok(value)
      Err(error) => Err(Tensor(error))
    }
  }
  let difference = match raise_axis(covariant, Succ(Succ(Zero))) {
    Ok(value) => value
    Err(error) => return Err(error)
  }
  let raised = match raise_axis(difference, Zero) {
    Ok(value) => value
    Err(error) => return Err(error)
  }
  let contravariant = match raise_axis(raised, Succ(Zero)) {
    Ok(value) => value
    Err(error) => return Err(error)
  }
  let products = match
    @tensor.zip(covariant, contravariant, @exact.rational_multiply) {
    Ok(value) => value
    Err(error) => return Err(Tensor(error))
  }
  let norm_squared = @core.fold_left(
    @tensor.entries(products),
    @exact.rational_zero(),
    @exact.rational_add,
  )
  let trace = match
    @tensor.contract(
      @algebra.rationals(),
      difference,
      Succ(Zero),
      Succ(Succ(Zero)),
    ) {
    Ok(value) => @tensor.entries(value)
    Err(error) => return Err(Tensor(error))
  }
  Ok({ metric, covariant, difference, contravariant, trace, norm_squared, })
}

///|
/// Requires an immersed finite model. Singular Fisher forms remain available
/// through amari_chentsov_tensor, without any arbitrary inverse or pseudoinverse.
pub fn amari_chentsov(
  model : @infogeom.Model,
) -> Result[AmariChentsov, GeometryError] {
  match amari_chentsov_tensor(model) {
    Err(error) => Err(error)
    Ok(covariant) => prepare_amari(@infogeom.fisher(model), covariant)
  }
}

///|
/// Gaussian natural coordinates: X_i followed by X_i X_j, i<=j.
/// Uses only second/third cumulants, without constructing fourth cumulants.
pub fn gaussian_amari_chentsov(
  source : @gaussian.Gaussian,
) -> Result[AmariChentsov, GeometryError] {
  match @gaussian.information(source) {
    Err(error) => Err(Gaussian(error))
    Ok(info) => prepare_amari(info.fisher(), info.amari_chentsov())
  }
}

///|
pub fn AmariChentsov::metric(
  self : AmariChentsov,
) -> @matrix.Matrix[@exact.Rational] {
  self.metric
}

///|
pub fn AmariChentsov::covariant(
  self : AmariChentsov,
) -> @tensor.Tensor[@exact.Rational] {
  self.covariant
}

///|
/// K[i,j,k] = g^(kl) T_ijl, so nabla^(alpha)=nabla^(zero)-alpha K/two.
pub fn AmariChentsov::difference(
  self : AmariChentsov,
) -> @tensor.Tensor[@exact.Rational] {
  self.difference
}

///|
pub fn AmariChentsov::contravariant(
  self : AmariChentsov,
) -> @tensor.Tensor[@exact.Rational] {
  self.contravariant
}

///|
/// Covector tau_i = sum_jk g^(jk) T_ijk, not a coordinate scalar.
pub fn AmariChentsov::trace(
  self : AmariChentsov,
) -> @core.Chain[@exact.Rational] {
  self.trace
}

///|
/// sum_ijk T_ijk T^(ijk). Nonnegative because the checked Fisher metric is positive.
pub fn AmariChentsov::norm_squared(self : AmariChentsov) -> @exact.Rational {
  self.norm_squared
}

///|
fn apply_vector(
  value : @tensor.Tensor[@exact.Rational],
  axis : @core.Nat,
  vector : @core.Chain[@exact.Rational],
) -> Result[@tensor.Tensor[@exact.Rational], GeometryError] {
  let row = match @matrix.matrix(@core.length(vector), Cons(vector, Nil)) {
    Some(value) => value
    None => return Err(MissingDerivative)
  }
  match @tensor.mode_product(value, axis, row, @algebra.rationals()) {
    Ok(value) => Ok(value)
    Err(error) => Err(Tensor(error))
  }
}

///|
pub fn AmariChentsov::product(
  self : AmariChentsov,
  u : @core.Chain[@exact.Rational],
  v : @core.Chain[@exact.Rational],
) -> Result[@core.Chain[@exact.Rational], GeometryError] {
  let d = @matrix.width(self.metric)
  if !@core.length(u).equal(d) || !@core.length(v).equal(d) {
    return Err(Tensor(ModeWidthMismatch))
  }
  let first = match apply_vector(self.difference, Zero, u) {
    Ok(value) => value
    Err(error) => return Err(error)
  }
  match apply_vector(first, Succ(Zero), v) {
    Ok(value) => Ok(@tensor.entries(value))
    Err(error) => Err(error)
  }
}

///|
pub fn AmariChentsov::evaluate(
  self : AmariChentsov,
  u : @core.Chain[@exact.Rational],
  v : @core.Chain[@exact.Rational],
  w : @core.Chain[@exact.Rational],
) -> Result[@exact.Rational, GeometryError] {
  let d = @matrix.width(self.metric)
  if !@core.length(u).equal(d) ||
    !@core.length(v).equal(d) ||
    !@core.length(w).equal(d) {
    return Err(Tensor(ModeWidthMismatch))
  }
  let first = match apply_vector(self.covariant, Zero, u) {
    Ok(value) => value
    Err(error) => return Err(error)
  }
  let second = match apply_vector(first, Succ(Zero), v) {
    Ok(value) => value
    Err(error) => return Err(error)
  }
  let third = match apply_vector(second, Succ(Succ(Zero)), w) {
    Ok(value) => value
    Err(error) => return Err(error)
  }
  match @tensor.at(third, Cons(Zero, Cons(Zero, Cons(Zero, Nil)))) {
    Ok(value) => Ok(value)
    Err(error) => Err(Tensor(error))
  }
}
