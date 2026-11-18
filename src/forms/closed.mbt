///|
/// A checked closed polynomial form on the fixed affine coordinate space QQ^n.
/// Constructors and closure-preserving operations are the only public entries.
#derive(Eq, Debug)
pub struct ClosedForm {
  value : Form
}

///|
pub extend ClosedForm with Eq::{equal, not_equal}

///|
pub extend ClosedForm with Debug::{to_repr}

///|
pub fn closed_form(value : Form) -> Result[ClosedForm, FormError] {
  // A checked form already has valid indices and grading. Above the top degree
  // it is zero; at the top degree its differential is necessarily zero.
  if is_zero(value) || !(@core.compare(value.degree, value.variables) is Less) {
    return Ok({ value, })
  }
  match exterior_derivative(value) {
    Err(error) => Err(error)
    Ok(differential) =>
      if is_zero(differential) {
        Ok({ value, })
      } else {
        Err(NotClosed)
      }
  }
}

///|
pub fn ClosedForm::value(self : ClosedForm) -> Form {
  self.value
}

///|
/// The result follows from closedness and retains the exterior grading.
pub fn ClosedForm::exterior_derivative(self : ClosedForm) -> Form {
  zero(self.value.variables, Succ(self.value.degree))
}

///|
pub fn ClosedForm::add(
  self : ClosedForm,
  other : ClosedForm,
) -> Result[ClosedForm, FormError] {
  match add(self.value, other.value) {
    Err(error) => Err(error)
    Ok(value) => Ok({ value, })
  }
}

///|
pub fn ClosedForm::negate(self : ClosedForm) -> ClosedForm {
  { value: negate(self.value), }
}

///|
pub fn ClosedForm::wedge(
  self : ClosedForm,
  other : ClosedForm,
) -> Result[ClosedForm, FormError] {
  match wedge(self.value, other.value) {
    Err(error) => Err(error)
    Ok(value) => Ok({ value, })
  }
}

///|
pub fn ClosedForm::pullback(
  self : ClosedForm,
  mapping : PolynomialMap,
) -> Result[ClosedForm, FormError] {
  match pullback(mapping, self.value) {
    Err(error) => Err(error)
    Ok(value) => Ok({ value, })
  }
}

///|
/// A polynomial primitive is retained as a witness. Equal forms may have
/// different primitives; equality compares the form, not the chosen witness.
#derive(Debug)
pub struct ExactForm {
  closed_value : ClosedForm
  primitive_value : Form
}

///|
pub impl Eq for ExactForm with fn equal(self : ExactForm, other : ExactForm) -> Bool {
  self.closed_value.equal(other.closed_value)
}

///|
pub extend ExactForm with Eq::{equal, not_equal}

///|
pub extend ExactForm with Debug::{to_repr}

///|
/// d(primitive), with the primitive retained and closedness supplied by d d=zero.
/// Degree zero exact forms are not modelled: there is no degree-minus-one Form.
pub fn exact_differential(primitive : Form) -> Result[ExactForm, FormError] {
  match exterior_derivative(primitive) {
    Err(error) => Err(error)
    Ok(value) => Ok({ closed_value: { value, }, primitive_value: primitive, })
  }
}

///|
pub fn ExactForm::value(self : ExactForm) -> Form {
  self.closed_value.value
}

///|
pub fn ExactForm::as_closed(self : ExactForm) -> ClosedForm {
  self.closed_value
}

///|
pub fn ExactForm::primitive(self : ExactForm) -> Form {
  self.primitive_value
}

///|
/// Explicit equation checking, separate from operations using the stored law.
pub fn ExactForm::check(self : ExactForm) -> Bool {
  check_primitive(self.value(), self.primitive_value)
}

///|
pub fn ExactForm::exterior_derivative(self : ExactForm) -> Form {
  self.closed_value.exterior_derivative()
}

///|
/// Polynomial Poincare homotopy on affine space supplies the primitive directly.
/// Positive exterior degree is essential; no global-manifold claim is made.
pub fn ClosedForm::primitive(self : ClosedForm) -> Result[ExactForm, FormError] {
  match self.value.degree {
    Zero => Err(ZeroDegree)
    Succ(_) =>
      match radial_homotopy(self.value) {
        Err(error) => Err(error)
        Ok(None) => Err(InternalInvariant)
        Ok(Some(primitive_value)) =>
          Ok({ closed_value: self, primitive_value, })
      }
  }
}

///|
pub fn ExactForm::negate(self : ExactForm) -> ExactForm {
  {
    closed_value: self.closed_value.negate(),
    primitive_value: negate(self.primitive_value),
  }
}

///|
pub fn ExactForm::add(
  self : ExactForm,
  other : ExactForm,
) -> Result[ExactForm, FormError] {
  match self.closed_value.add(other.closed_value) {
    Err(error) => Err(error)
    Ok(closed_value) =>
      match add(self.primitive_value, other.primitive_value) {
        Err(error) => Err(error)
        Ok(primitive_value) => Ok({ closed_value, primitive_value, })
      }
  }
}

///|
/// (d eta) wedge beta = d(eta wedge beta) when beta is closed.
pub fn ExactForm::wedge_closed(
  self : ExactForm,
  other : ClosedForm,
) -> Result[ExactForm, FormError] {
  match self.closed_value.wedge(other) {
    Err(error) => Err(error)
    Ok(closed_value) =>
      match wedge(self.primitive_value, other.value) {
        Err(error) => Err(error)
        Ok(primitive_value) => Ok({ closed_value, primitive_value, })
      }
  }
}

///|
/// alpha wedge d eta = d((-one)^degree(alpha) alpha wedge eta) for closed alpha.
pub fn ClosedForm::wedge_exact(
  self : ClosedForm,
  other : ExactForm,
) -> Result[ExactForm, FormError] {
  match self.wedge(other.closed_value) {
    Err(error) => Err(error)
    Ok(closed_value) =>
      match wedge(self.value, other.primitive_value) {
        Err(error) => Err(error)
        Ok(candidate) => {
          let (_, odd) = @core.halve_nat(self.value.degree)
          let primitive_value = if odd { negate(candidate) } else { candidate }
          Ok({ closed_value, primitive_value, })
        }
      }
  }
}

///|
pub fn ExactForm::wedge(
  self : ExactForm,
  other : ExactForm,
) -> Result[ExactForm, FormError] {
  self.wedge_closed(other.closed_value)
}

///|
pub fn ExactForm::pullback(
  self : ExactForm,
  mapping : PolynomialMap,
) -> Result[ExactForm, FormError] {
  match self.closed_value.pullback(mapping) {
    Err(error) => Err(error)
    Ok(closed_value) =>
      match pullback(mapping, self.primitive_value) {
        Err(error) => Err(error)
        Ok(primitive_value) => Ok({ closed_value, primitive_value, })
      }
  }
}
