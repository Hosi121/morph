///|
/// Coordinate components attached to their statistical point and generating chart.
#derive(Eq, Debug)
pub struct HessianTangent {
  point : HessianPoint
  values : @core.Chain[@exact.Rational]
}

///|
pub extend HessianTangent with Eq::{equal, not_equal}

///|
pub extend HessianTangent with Debug::{to_repr}

///|
#derive(Eq, Debug)
pub struct HessianCotangent {
  point : HessianPoint
  values : @core.Chain[@exact.Rational]
}

///|
pub extend HessianCotangent with Eq::{equal, not_equal}

///|
pub extend HessianCotangent with Debug::{to_repr}

///|
pub fn HessianPoint::tangent(
  self : HessianPoint,
  values : @core.Chain[@exact.Rational],
) -> Result[HessianTangent, GeometryError] {
  if !@core.length(values).equal(self.dimension()) {
    return Err(Tensor(ModeWidthMismatch))
  }
  Ok({ point: self, values, })
}

///|
pub fn HessianPoint::cotangent(
  self : HessianPoint,
  values : @core.Chain[@exact.Rational],
) -> Result[HessianCotangent, GeometryError] {
  if !@core.length(values).equal(self.dimension()) {
    return Err(Tensor(ModeWidthMismatch))
  }
  Ok({ point: self, values, })
}

///|
pub fn HessianTangent::parent(self : HessianTangent) -> HessianPoint {
  self.point
}

///|
pub fn HessianCotangent::parent(self : HessianCotangent) -> HessianPoint {
  self.point
}

///|
pub fn HessianTangent::components(
  self : HessianTangent,
) -> @core.Chain[@exact.Rational] {
  self.values
}

///|
pub fn HessianCotangent::components(
  self : HessianCotangent,
) -> @core.Chain[@exact.Rational] {
  self.values
}

///|
fn add_fiber_values(
  a : @core.Chain[@exact.Rational],
  b : @core.Chain[@exact.Rational],
) -> Result[@core.Chain[@exact.Rational], GeometryError] {
  match @core.zip(a, b) {
    None => Err(Tensor(InternalShape))
    Some(pairs) =>
      Ok(
        @core.map(pairs, fn(pair) {
          let (a, b) = pair
          @exact.rational_add(a, b)
        }),
      )
  }
}

///|
pub fn HessianTangent::add(
  self : HessianTangent,
  other : HessianTangent,
) -> Result[HessianTangent, GeometryError] {
  if !self.point.same_coordinates(other.point) {
    return Err(PointMismatch)
  }
  match add_fiber_values(self.values, other.values) {
    Err(error) => Err(error)
    Ok(values) => Ok({ point: self.point, values, })
  }
}

///|
pub fn HessianCotangent::add(
  self : HessianCotangent,
  other : HessianCotangent,
) -> Result[HessianCotangent, GeometryError] {
  if !self.point.same_coordinates(other.point) {
    return Err(PointMismatch)
  }
  match add_fiber_values(self.values, other.values) {
    Err(error) => Err(error)
    Ok(values) => Ok({ point: self.point, values, })
  }
}

///|
pub fn HessianTangent::scale(
  self : HessianTangent,
  factor : @exact.Rational,
) -> HessianTangent {
  {
    point: self.point,
    values: @core.map(self.values, fn(value) {
      @exact.rational_multiply(factor, value)
    }),
  }
}

///|
pub fn HessianCotangent::scale(
  self : HessianCotangent,
  factor : @exact.Rational,
) -> HessianCotangent {
  {
    point: self.point,
    values: @core.map(self.values, fn(value) {
      @exact.rational_multiply(factor, value)
    }),
  }
}

///|
pub fn HessianPoint::trace(self : HessianPoint) -> HessianCotangent {
  { point: self, values: self.trace_value, }
}

///|
pub fn HessianPoint::raise_index(
  self : HessianPoint,
  value : HessianCotangent,
) -> Result[HessianTangent, GeometryError] {
  if !self.same_coordinates(value.point) {
    return Err(PointMismatch)
  }
  match self.form.solve(value.values) {
    None => Err(Tensor(InternalShape))
    Some(values) => Ok({ point: self, values, })
  }
}

///|
pub fn HessianPoint::lower_index(
  self : HessianPoint,
  value : HessianTangent,
) -> Result[HessianCotangent, GeometryError] {
  if !self.same_coordinates(value.point) {
    return Err(PointMismatch)
  }
  match self.form.apply(value.values) {
    None => Err(Tensor(InternalShape))
    Some(values) => Ok({ point: self, values, })
  }
}

///|
pub fn HessianPoint::evaluate(
  self : HessianPoint,
  covector : HessianCotangent,
  vector : HessianTangent,
) -> Result[@exact.Rational, GeometryError] {
  if !self.same_coordinates(covector.point) ||
    !self.same_coordinates(vector.point) {
    return Err(PointMismatch)
  }
  match @core.zip(covector.values, vector.values) {
    None => Err(Tensor(InternalShape))
    Some(pairs) =>
      Ok(
        @core.fold_left(pairs, @exact.rational_zero(), fn(total, pair) {
          let (a, b) = pair
          @exact.rational_add(total, @exact.rational_multiply(a, b))
        }),
      )
  }
}

///|
pub fn HessianPoint::pairing(
  self : HessianPoint,
  u : HessianTangent,
  v : HessianTangent,
) -> Result[@exact.Rational, GeometryError] {
  match self.lower_index(u) {
    Err(error) => Err(error)
    Ok(lowered) => self.evaluate(lowered, v)
  }
}

///|
fn HessianPoint::product_values(
  self : HessianPoint,
  u : @core.Chain[@exact.Rational],
  v : @core.Chain[@exact.Rational],
) -> Result[@core.Chain[@exact.Rational], GeometryError] {
  let first = match apply_vector(self.difference_value, Zero, u) {
    Err(error) => return Err(error)
    Ok(value) => value
  }
  match apply_vector(first, Succ(Zero), v) {
    Err(error) => Err(error)
    Ok(value) => Ok(@tensor.entries(value))
  }
}

///|
pub fn HessianPoint::product(
  self : HessianPoint,
  u : HessianTangent,
  v : HessianTangent,
) -> Result[HessianTangent, GeometryError] {
  if !self.same_coordinates(u.point) || !self.same_coordinates(v.point) {
    return Err(PointMismatch)
  }
  match self.product_values(u.values, v.values) {
    Err(error) => Err(error)
    Ok(values) => Ok({ point: self, values, })
  }
}

///|
/// R(u,v)w using the commutator of K_u,K_v. No rank-four array is built.
pub fn HessianCurvature::apply(
  self : HessianCurvature,
  u : HessianTangent,
  v : HessianTangent,
  w : HessianTangent,
) -> Result[HessianTangent, GeometryError] {
  let point = self.source
  if !point.same_coordinates(u.point) ||
    !point.same_coordinates(v.point) ||
    !point.same_coordinates(w.point) {
    return Err(PointMismatch)
  }
  match self.formula {
    FlatFormula =>
      Ok({
        point,
        values: @core.replicate(point.dimension(), @exact.rational_zero()),
      })
    ScaledFormula(weight) => {
      let vw = match point.product_values(v.values, w.values) {
        Err(error) => return Err(error)
        Ok(value) => value
      }
      let uw = match point.product_values(u.values, w.values) {
        Err(error) => return Err(error)
        Ok(value) => value
      }
      let first = match point.product_values(u.values, vw) {
        Err(error) => return Err(error)
        Ok(value) => value
      }
      let second = match point.product_values(v.values, uw) {
        Err(error) => return Err(error)
        Ok(value) => value
      }
      let coefficient = @exact.rational_negate(quarter(weight))
      match @core.zip(first, second) {
        None => Err(Tensor(InternalShape))
        Some(pairs) =>
          Ok({
            point,
            values: @core.map(pairs, fn(pair) {
              let (a, b) = pair
              @exact.rational_multiply(
                coefficient,
                @exact.rational_subtract(a, b),
              )
            }),
          })
      }
    }
  }
}
