///|
/// a+b sqrt(det(g)); both parts have the same coordinate and exterior grading.
/// Returned values are canonical: b vanishes when the positive root is rational.
#derive(Eq, Debug)
pub(all) struct Parts {
  rational : @forms.Form
  radical : @forms.Form
}

///|
pub extend Parts with Eq::{equal, not_equal}

///|
pub extend Parts with Debug::{to_repr}

///|
#derive(Eq, Debug)
enum Expression {
  Expanded(Parts)
  Starred(HodgeForm, PreparedHodge?)
  Negated(HodgeForm)
  Added(HodgeForm, HodgeForm)
  Scaled(HodgeForm, @exact.Rational)
  Wedged(HodgeForm, HodgeForm)
  InteriorSharp(HodgeForm, HodgeForm)
  Sheared(HodgeForm, @core.Nat, @core.Nat, @exact.Rational)
}

///|
pub extend Expression with Eq::{equal, not_equal}

///|
pub extend Expression with Debug::{to_repr}

///|
/// Equality is structural; equivalent expands and compares canonical values.
#derive(Eq, Debug)
pub struct HodgeForm {
  space_value : Space
  degree_value : @core.Nat
  expression : Expression
}

///|
pub extend HodgeForm with Eq::{equal, not_equal}

///|
pub extend HodgeForm with Debug::{to_repr}

///|
pub fn Space::from_parts(
  self : Space,
  parts : Parts,
) -> Result[HodgeForm, HodgeError] {
  if !@forms.variables(parts.rational).equal(self.dimension()) ||
    !@forms.variables(parts.radical).equal(self.dimension()) {
    return Err(DimensionMismatch)
  }
  let degree_value = @forms.degree(parts.rational)
  if !degree_value.equal(@forms.degree(parts.radical)) {
    return Err(DegreeMismatch)
  }
  if @core.compare(degree_value, self.dimension()) is Greater {
    return Err(DegreeOutOfRange)
  }
  let parts = match self.rational_root {
    None => parts
    Some(root) => {
      let scaled = match scale_form(parts.radical, root) {
        Ok(value) => value
        Err(error) => return Err(error)
      }
      let rational = match add_forms(parts.rational, scaled) {
        Ok(value) => value
        Err(error) => return Err(error)
      }
      Parts::{ rational, radical: @forms.zero(self.dimension(), degree_value), }
    }
  }
  Ok({ space_value: self, degree_value, expression: Expanded(parts), })
}

///|
pub fn Space::lift(
  self : Space,
  value : @forms.Form,
) -> Result[HodgeForm, HodgeError] {
  self.from_parts({
    rational: value,
    radical: @forms.zero(@forms.variables(value), @forms.degree(value)),
  })
}

///|
pub fn Space::zero(
  self : Space,
  degree : @core.Nat,
) -> Result[HodgeForm, HodgeError] {
  self.lift(@forms.zero(self.dimension(), degree))
}

///|
pub fn Space::scalar(
  self : Space,
  a : @exact.Rational,
  b : @exact.Rational,
) -> HodgeForm {
  let rational = @forms.scalar(@poly.constant(self.dimension(), a))
  let radical = @forms.scalar(@poly.constant(self.dimension(), b))
  let parts = match self.rational_root {
    None => Parts::{ rational, radical, }
    Some(root) =>
      {
        rational: @forms.scalar(
          @poly.constant(
            self.dimension(),
            @exact.rational_add(a, @exact.rational_multiply(b, root)),
          ),
        ),
        radical: @forms.zero(self.dimension(), Zero),
      }
  }
  { space_value: self, degree_value: Zero, expression: Expanded(parts), }
}

///|
pub fn HodgeForm::parent(self : HodgeForm) -> Space {
  self.space_value
}

///|
pub fn HodgeForm::degree(self : HodgeForm) -> @core.Nat {
  self.degree_value
}

///|
pub fn HodgeForm::negate(self : HodgeForm) -> HodgeForm {
  match self.expression {
    Negated(original) => original
    _ => { ..self, expression: Negated(self), }
  }
}

///|
/// No compound matrix or square root arithmetic is performed here.
pub fn HodgeForm::star(self : HodgeForm) -> HodgeForm {
  match self.expression {
    Starred(original, _) =>
      if odd(original.degree_value) && odd(self.degree_value) {
        original.negate()
      } else {
        original
      }
    Negated(original) => original.star().negate()
    _ =>
      {
        space_value: self.space_value,
        degree_value: @core.subtract(
          self.space_value.dimension(),
          self.degree_value,
        ),
        expression: Starred(self, None),
      }
  }
}

///|
pub fn HodgeForm::parts(self : HodgeForm) -> Result[Parts, HodgeError] {
  self.parts_with(Factorized)
}

///|
/// Hodge star is invertible, so its zero test need not expand any components.
pub fn HodgeForm::is_zero(self : HodgeForm) -> Result[Bool, HodgeError] {
  match self.known_zero() {
    Some(value) => Ok(value)
    None =>
      match self.parts() {
        Ok(value) =>
          Ok(@forms.is_zero(value.rational) && @forms.is_zero(value.radical))
        Err(error) => Err(error)
      }
  }
}

///|
pub fn HodgeForm::equivalent(
  self : HodgeForm,
  other : HodgeForm,
) -> Result[Bool, HodgeError] {
  if !self.space_value.equal(other.space_value) {
    return Err(SpaceMismatch)
  }
  if !self.degree_value.equal(other.degree_value) {
    return Ok(false)
  }
  let a = match self.parts() {
    Ok(value) => value
    Err(error) => return Err(error)
  }
  match other.parts() {
    Ok(b) => Ok(a.equal(b))
    Err(error) => Err(error)
  }
}

///|
pub fn HodgeForm::add(
  self : HodgeForm,
  other : HodgeForm,
) -> Result[HodgeForm, HodgeError] {
  if !self.space_value.equal(other.space_value) {
    return Err(SpaceMismatch)
  }
  if !self.degree_value.equal(other.degree_value) {
    return Err(DegreeMismatch)
  }
  Ok({ ..self, expression: Added(self, other), })
}

///|
pub fn HodgeForm::scale(
  self : HodgeForm,
  factor : @exact.Rational,
) -> Result[HodgeForm, HodgeError] {
  Ok({ ..self, expression: Scaled(self, factor), })
}

///|
/// Product in QQ[sqrt(D)], retaining the exterior grade. Degrees outside the
/// supported Hodge range are rejected even when the algebraic product is zero.
pub fn HodgeForm::wedge(
  self : HodgeForm,
  other : HodgeForm,
) -> Result[HodgeForm, HodgeError] {
  if !self.space_value.equal(other.space_value) {
    return Err(SpaceMismatch)
  }
  let degree_value = @core.add(self.degree_value, other.degree_value)
  if @core.compare(degree_value, self.space_value.dimension()) is Greater {
    return Err(DegreeOutOfRange)
  }
  Ok({
    space_value: self.space_value,
    degree_value,
    expression: Wedged(self, other),
  })
}

///|
/// Hodge star is an isometry for the stored positive definite metric.
pub fn HodgeForm::inner(
  self : HodgeForm,
  other : HodgeForm,
) -> Result[HodgeForm, HodgeError] {
  if !self.space_value.equal(other.space_value) {
    return Err(SpaceMismatch)
  }
  if !self.degree_value.equal(other.degree_value) {
    return Err(DegreeMismatch)
  }
  match (self.expression, other.expression) {
    (Starred(a, _), Starred(b, _)) => a.inner(b)
    _ =>
      match self.space_value.prepare(self.degree_value) {
        Err(error) => Err(error)
        Ok(rule) => rule.inner(self, other)
      }
  }
}

///|
pub fn Space::volume(self : Space) -> HodgeForm {
  self.scalar(@exact.rational_one(), @exact.rational_zero()).star()
}
