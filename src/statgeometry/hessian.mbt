///|
#derive(Eq, Debug)
enum NaturalSource {
  FiniteNatural(@infogeom.ExponentialFamily)
  GaussianNatural(@gaussian.Information)
}

///|
pub extend NaturalSource with Eq::{equal, not_equal}

///|
pub extend NaturalSource with Debug::{to_repr}

///|
/// Prepared natural-coordinate Hessian geometry. The source construction implies
/// g=F'', T=F''' and dual flatness; arbitrary pointwise (g,T) cannot enter here.
/// Only metric/cubic data are used: no probability three-jet or fourth cumulants.
#derive(Eq, Debug)
pub struct HessianPoint {
  source : NaturalSource
  form : @positiveform.PositiveDefinite
  inverse : @matrix.Matrix[@exact.Rational]
  cubic_value : @tensor.Tensor[@exact.Rational]
  difference_value : @tensor.Tensor[@exact.Rational]
  trace_value : @core.Chain[@exact.Rational]
  ricci_zero : @matrix.Matrix[@exact.Rational]
  scalar_zero : @exact.Rational
}

///|
pub extend HessianPoint with Eq::{equal, not_equal}

///|
pub extend HessianPoint with Debug::{to_repr}

///|
fn quarter(value : @exact.Rational) -> @exact.Rational {
  @exact.rational_half(@exact.rational_half(value))
}

///|
fn HessianPoint::entry(
  self : HessianPoint,
  i : @core.Nat,
  j : @core.Nat,
  r : @core.Nat,
) -> @exact.Rational {
  tensor_entry(self.difference_value, Cons(i, Cons(j, Cons(r, Nil))))
}

///|
fn prepare_hessian(
  source : NaturalSource,
) -> Result[HessianPoint, GeometryError] {
  let (metric, cubic_value) = match source {
    FiniteNatural(family) => {
      let value = match
        from_slices(family.dimension(), family.amari_chentsov()) {
        Ok(value) => value
        Err(error) => return Err(error)
      }
      (family.fisher(), value)
    }
    GaussianNatural(info) => (info.fisher(), info.amari_chentsov())
  }
  let form = match @positiveform.positive_definite(metric) {
    Ok(value) => value
    Err(NotPositiveDefinite) => return Err(Metric(SingularMetric))
    Err(error) => return Err(Form(error))
  }
  let inverse = match form.inverse().matrix() {
    Ok(value) => value
    Err(error) => return Err(Form(error))
  }
  let d = form.dimension()
  let indices = @core.indices(d)
  let difference_value = match
    @tensor.mode_product(
      cubic_value,
      Succ(Succ(Zero)),
      inverse,
      @algebra.rationals(),
    ) {
    Ok(value) => value
    Err(error) => return Err(Tensor(error))
  }
  fn k(i : @core.Nat, j : @core.Nat, r : @core.Nat) -> @exact.Rational {
    tensor_entry(difference_value, Cons(i, Cons(j, Cons(r, Nil))))
  }
  let trace_value = @core.map(indices, fn(i) {
    sum_indices(indices, fn(j) { k(i, j, j) })
  })
  fn tau(i : @core.Nat) -> @exact.Rational {
    match @core.nth(trace_value, i) {
      Some(value) => value
      None => @exact.rational_zero()
    }
  }
  // Ric^LC_ij = (tr(K_i K_j) - tau_m K^m_ij)/four.
  // This contracts the commutator identity directly, without rank-four R.
  let ricci_zero = match
    @matrix.matrix(
      d,
      @core.map(indices, fn(i) {
        @core.map(indices, fn(j) {
          let gram = sum_indices(indices, fn(r) {
            sum_indices(indices, fn(s) {
              @exact.rational_multiply(k(i, s, r), k(j, r, s))
            })
          })
          let traced = sum_indices(indices, fn(m) {
            @exact.rational_multiply(tau(m), k(i, j, m))
          })
          quarter(@exact.rational_subtract(gram, traced))
        })
      }),
    ) {
    Some(value) => value
    None => return Err(Tensor(InternalShape))
  }
  let scalar_zero = sum_indices(indices, fn(i) {
    sum_indices(indices, fn(j) {
      @exact.rational_multiply(
        matrix_entry(inverse, i, j),
        matrix_entry(ricci_zero, i, j),
      )
    })
  })
  Ok({
    source,
    form,
    inverse,
    cubic_value,
    difference_value,
    trace_value,
    ricci_zero,
    scalar_zero,
  })
}

///|
pub fn exponential_hessian(
  source : @infogeom.ExponentialFamily,
) -> Result[HessianPoint, GeometryError] {
  prepare_hessian(FiniteNatural(source))
}

///|
pub fn gaussian_hessian(
  source : @gaussian.Information,
) -> Result[HessianPoint, GeometryError] {
  prepare_hessian(GaussianNatural(source))
}

///|
pub fn HessianPoint::dimension(self : HessianPoint) -> @core.Nat {
  self.form.dimension()
}

///|
pub fn HessianPoint::metric_form(
  self : HessianPoint,
) -> @positiveform.PositiveDefinite {
  self.form
}

///|
pub fn HessianPoint::metric(
  self : HessianPoint,
) -> @matrix.Matrix[@exact.Rational] {
  match self.source {
    FiniteNatural(source) => source.fisher()
    GaussianNatural(source) => source.fisher()
  }
}

///|
pub fn HessianPoint::inverse_metric(
  self : HessianPoint,
) -> @matrix.Matrix[@exact.Rational] {
  self.inverse
}

///|
pub fn HessianPoint::amari_chentsov(
  self : HessianPoint,
) -> @tensor.Tensor[@exact.Rational] {
  self.cubic_value
}

///|
pub fn HessianPoint::difference(
  self : HessianPoint,
) -> @tensor.Tensor[@exact.Rational] {
  self.difference_value
}

///|
pub fn HessianPoint::exponential_source(
  self : HessianPoint,
) -> @infogeom.ExponentialFamily? {
  match self.source {
    FiniteNatural(source) => Some(source)
    _ => None
  }
}

///|
pub fn HessianPoint::gaussian_source(
  self : HessianPoint,
) -> @gaussian.Information? {
  match self.source {
    GaussianNatural(source) => Some(source)
    _ => None
  }
}

///|
// Coordinate compatibility uses the generating data, not equality of cached tensors.
// Equal dimensions or a coincidentally equal metric/cubic are insufficient.
pub fn HessianPoint::same_coordinates(
  self : HessianPoint,
  other : HessianPoint,
) -> Bool {
  match (self.source, other.source) {
    (FiniteNatural(a), FiniteNatural(b)) =>
      a.base().equal(b.base()) && a.statistics().equal(b.statistics())
    (GaussianNatural(a), GaussianNatural(b)) => a.parent().equal(b.parent())
    _ => false
  }
}

///|
#derive(Eq, Debug)
enum CurvatureFormula {
  FlatFormula
  ScaledFormula(@exact.Rational)
}

///|
pub extend CurvatureFormula with Eq::{equal, not_equal}

///|
pub extend CurvatureFormula with Debug::{to_repr}

///|
/// A curvature operator, not a pre-expanded rank-four array.
/// Formula stores R^alpha=(one-alpha squared) R^LC; dual endpoints are zero.
#derive(Eq, Debug)
pub struct HessianCurvature {
  source : HessianPoint
  alpha_value : @exact.Rational
  formula : CurvatureFormula
}

///|
pub extend HessianCurvature with Eq::{equal, not_equal}

///|
pub extend HessianCurvature with Debug::{to_repr}

///|
pub fn HessianPoint::curvature(
  self : HessianPoint,
  alpha : @exact.Rational,
) -> HessianCurvature {
  let weight = @exact.rational_subtract(
    @exact.rational_one(),
    @exact.rational_multiply(alpha, alpha),
  )
  let formula = match (self.dimension(), @exact.nonzero(weight)) {
    (Zero, _) | (Succ(Zero), _) | (_, None) => FlatFormula
    _ => ScaledFormula(weight)
  }
  { source: self, alpha_value: alpha, formula, }
}

///|
pub fn HessianCurvature::parent(self : HessianCurvature) -> HessianPoint {
  self.source
}

///|
pub fn HessianCurvature::alpha(self : HessianCurvature) -> @exact.Rational {
  self.alpha_value
}

///|
pub fn HessianCurvature::coefficients(
  self : HessianCurvature,
) -> @tensor.Tensor[@exact.Rational] {
  let factor = @exact.rational_half(
    @exact.rational_subtract(@exact.rational_one(), self.alpha_value),
  )
  @tensor.map(self.source.difference_value, fn(value) {
    @exact.rational_multiply(factor, value)
  })
}

///|
pub fn HessianCurvature::scalar(self : HessianCurvature) -> @exact.Rational {
  match self.formula {
    FlatFormula => @exact.rational_zero()
    ScaledFormula(weight) =>
      @exact.rational_multiply(weight, self.source.scalar_zero)
  }
}

///|
pub fn HessianCurvature::ricci(
  self : HessianCurvature,
) -> Result[@matrix.Matrix[@exact.Rational], GeometryError] {
  let weight = match self.formula {
    FlatFormula => @exact.rational_zero()
    ScaledFormula(value) => value
  }
  match
    @matrix.matrix(
      self.source.dimension(),
      @core.map(@matrix.rows(self.source.ricci_zero), fn(row) {
        @core.map(row, fn(value) { @exact.rational_multiply(weight, value) })
      }),
    ) {
    Some(value) => Ok(value)
    None => Err(Tensor(InternalShape))
  }
}

///|
fn[A] hessian_row(
  rows : @core.Chain[@core.Chain[A]],
  index : @core.Nat,
) -> @core.Chain[A] {
  match @core.nth(rows, index) {
    Some(row) => row
    None => Nil
  }
}

///|
fn hessian_dot(
  left : @core.Chain[@exact.Rational],
  right : @core.Chain[@exact.Rational],
) -> @exact.Rational {
  match (left, right) {
    (Cons(a, rest_a), Cons(b, rest_b)) =>
      @exact.rational_add(
        @exact.rational_multiply(a, b),
        hessian_dot(rest_a, rest_b),
      )
    _ => @exact.rational_zero()
  }
}

///|
/// Explicit coordinate expansion R[r,j,k,l]. Operator application avoids this.
pub fn HessianCurvature::riemann(
  self : HessianCurvature,
) -> @tensor.Tensor[@exact.Rational] {
  let d = self.source.dimension()
  let indices = @core.indices(d)
  match self.formula {
    FlatFormula => four_tensor(d, fn(_, _, _, _) { @exact.rational_zero() })
    ScaledFormula(weight) => {
      let coefficient = @exact.rational_negate(quarter(weight))
      // Materialize the small K_k operators once. Flat tensor indexing scans a
      // linked list; repeating that scan inside every contracted component is
      // more expensive than computing all matrix products with sequential dots.
      let operators = @core.map(indices, fn(k) {
        let rows = @core.map(indices, fn(r) {
          @core.map(indices, fn(j) { self.source.entry(k, j, r) })
        })
        let columns = @core.map(indices, fn(j) {
          @core.map(indices, fn(r) { self.source.entry(k, j, r) })
        })
        (rows, columns)
      })
      let products = @core.map(operators, fn(left) {
        let (rows, _) = left
        @core.map(operators, fn(right) {
          let (_, columns) = right
          @core.map(rows, fn(row) {
            @core.map(columns, fn(column) { hessian_dot(row, column) })
          })
        })
      })
      fn product(
        k : @core.Nat,
        l : @core.Nat,
        r : @core.Nat,
        j : @core.Nat,
      ) -> @exact.Rational {
        let row = hessian_row(hessian_row(hessian_row(products, k), l), r)
        match @core.nth(row, j) {
          Some(value) => value
          None => @exact.rational_zero()
        }
      }
      four_tensor(d, fn(r, j, k, l) {
        if k.equal(l) {
          return @exact.rational_zero()
        }
        @exact.rational_multiply(
          coefficient,
          @exact.rational_subtract(product(k, l, r, j), product(l, k, r, j)),
        )
      })
    }
  }
}

///|
pub fn HessianCurvature::lowered_riemann(
  self : HessianCurvature,
) -> Result[@tensor.Tensor[@exact.Rational], GeometryError] {
  match
    @tensor.mode_product(
      self.riemann(),
      Zero,
      self.source.metric(),
      @algebra.rationals(),
    ) {
    Ok(value) => Ok(value)
    Err(error) => Err(Tensor(error))
  }
}
