///|
/// Evaluation is explicit. InteriorProduct uses decomposable one-form graphs
/// when available and otherwise falls back to the factorized exterior action.
#derive(Eq, Debug)
pub(all) enum Evaluation {
  Factorized
  InteriorProduct
}

///|
pub extend Evaluation with Eq::{equal, not_equal}

///|
pub extend Evaluation with Debug::{to_repr}

///|
pub fn HodgeForm::contract_sharp(
  self : HodgeForm,
  covector : HodgeForm,
) -> Result[HodgeForm, HodgeError] {
  if !self.space_value.equal(covector.space_value) {
    return Err(SpaceMismatch)
  }
  if !covector.degree_value.equal(Succ(Zero)) {
    return Err(DegreeMismatch)
  }
  match self.degree_value {
    Zero => Err(DegreeOutOfRange)
    Succ(degree_value) =>
      Ok({
        space_value: self.space_value,
        degree_value,
        expression: InteriorSharp(covector, self),
      })
  }
}

///|
/// Active exterior action in the fixed basis, not a change of metric context.
pub fn HodgeForm::shear(
  self : HodgeForm,
  target : @core.Nat,
  source : @core.Nat,
  factor : @exact.Rational,
) -> Result[HodgeForm, HodgeError] {
  if !(@core.compare(target, self.space_value.dimension()) is Less) ||
    !(@core.compare(source, self.space_value.dimension()) is Less) {
    return Err(DimensionMismatch)
  }
  if target.equal(source) {
    return Err(Form(InvalidShear))
  }
  Ok({ ..self, expression: Sheared(self, target, source, factor), })
}

///|
/// A structural zero fact is optional; unknown never means nonzero.
pub fn HodgeForm::known_zero(self : HodgeForm) -> Bool? {
  match self.expression {
    Expanded(value) =>
      Some(@forms.is_zero(value.rational) && @forms.is_zero(value.radical))
    Negated(value) | Starred(value, _) | Sheared(value, _, _, _) =>
      value.known_zero()
    Scaled(value, factor) =>
      if factor.equal(@exact.rational_zero()) {
        Some(true)
      } else {
        value.known_zero()
      }
    Added(a, b) =>
      if a.known_zero() is Some(true) && b.known_zero() is Some(true) {
        Some(true)
      } else {
        None
      }
    Wedged(a, b) | InteriorSharp(a, b) =>
      if a.known_zero() is Some(true) || b.known_zero() is Some(true) {
        Some(true)
      } else {
        None
      }
  }
}

///|
fn Space::canonical_parts(
  self : Space,
  value : Parts,
) -> Result[Parts, HodgeError] {
  match self.from_parts(value) {
    Ok({ expression: Expanded(value), .. }) => Ok(value)
    _ => Err(InternalShape)
  }
}

///|
fn Space::product_parts(
  self : Space,
  a : Parts,
  b : Parts,
) -> Result[Parts, HodgeError] {
  let aa = match wedge_forms(a.rational, b.rational) {
    Ok(value) => value
    Err(error) => return Err(error)
  }
  let bb = match wedge_forms(a.radical, b.radical) {
    Ok(value) => value
    Err(error) => return Err(error)
  }
  let bb = match scale_form(bb, self.volume_squared().value()) {
    Ok(value) => value
    Err(error) => return Err(error)
  }
  let ab = match wedge_forms(a.rational, b.radical) {
    Ok(value) => value
    Err(error) => return Err(error)
  }
  let ba = match wedge_forms(a.radical, b.rational) {
    Ok(value) => value
    Err(error) => return Err(error)
  }
  let rational = match add_forms(aa, bb) {
    Ok(value) => value
    Err(error) => return Err(error)
  }
  let radical = match add_forms(ab, ba) {
    Ok(value) => value
    Err(error) => return Err(error)
  }
  self.canonical_parts({ rational, radical, })
}

///|
fn one_form_factors(value : HodgeForm) -> @core.Chain[HodgeForm]? {
  if value.degree_value.equal(Succ(Zero)) {
    return Some(Cons(value, Nil))
  }
  match value.expression {
    Wedged(a, b) =>
      match (one_form_factors(a), one_form_factors(b)) {
        (Some(a), Some(b)) => Some(@core.append(a, b))
        _ => None
      }
    _ => None
  }
}

///|
fn contract_factors(
  factors : @core.Chain[HodgeForm],
  volume : HodgeForm,
) -> Result[HodgeForm, HodgeError] {
  match factors {
    Nil => Ok(volume)
    Cons(first, tail) =>
      match volume.contract_sharp(first) {
        Err(error) => Err(error)
        Ok(value) => contract_factors(tail, value)
      }
  }
}

///|
pub fn HodgeForm::parts_with(
  self : HodgeForm,
  evaluation : Evaluation,
) -> Result[Parts, HodgeError] {
  let s = self.space_value
  if self.known_zero() is Some(true) {
    let zero = @forms.zero(s.dimension(), self.degree_value)
    return Ok({ rational: zero, radical: zero, })
  }
  match self.expression {
    Expanded(value) => Ok(value)
    Negated(original) =>
      match original.parts_with(evaluation) {
        Ok(value) =>
          Ok({
            rational: @forms.negate(value.rational),
            radical: @forms.negate(value.radical),
          })
        Err(error) => Err(error)
      }
    Scaled(original, factor) => {
      let value = match original.parts_with(evaluation) {
        Ok(value) => value
        Err(error) => return Err(error)
      }
      let rational = match scale_form(value.rational, factor) {
        Ok(value) => value
        Err(error) => return Err(error)
      }
      let radical = match scale_form(value.radical, factor) {
        Ok(value) => value
        Err(error) => return Err(error)
      }
      s.canonical_parts({ rational, radical, })
    }
    Added(a, b) => {
      let a = match a.parts_with(evaluation) {
        Ok(value) => value
        Err(error) => return Err(error)
      }
      let b = match b.parts_with(evaluation) {
        Ok(value) => value
        Err(error) => return Err(error)
      }
      let rational = match add_forms(a.rational, b.rational) {
        Ok(value) => value
        Err(error) => return Err(error)
      }
      let radical = match add_forms(a.radical, b.radical) {
        Ok(value) => value
        Err(error) => return Err(error)
      }
      s.canonical_parts({ rational, radical, })
    }
    Wedged(a, b) => {
      let a = match a.parts_with(evaluation) {
        Ok(value) => value
        Err(error) => return Err(error)
      }
      let b = match b.parts_with(evaluation) {
        Ok(value) => value
        Err(error) => return Err(error)
      }
      s.product_parts(a, b)
    }
    Sheared(original, target, source, factor) => {
      let value = match original.parts_with(evaluation) {
        Ok(value) => value
        Err(error) => return Err(error)
      }
      let rational = match
        @forms.shear(value.rational, target, source, factor) {
        Ok(value) => value
        Err(error) => return Err(Form(error))
      }
      let radical = match @forms.shear(value.radical, target, source, factor) {
        Ok(value) => value
        Err(error) => return Err(Form(error))
      }
      s.canonical_parts({ rational, radical, })
    }
    InteriorSharp(covector, original) => {
      let vector = match covector.parts_with(evaluation) {
        Ok(value) => value
        Err(error) => return Err(error)
      }
      let value = match original.parts_with(evaluation) {
        Ok(value) => value
        Err(error) => return Err(error)
      }
      match s.interior_parts(vector, value) {
        Ok(value) => s.canonical_parts(value)
        Err(error) => Err(error)
      }
    }
    Starred(original, prepared) => {
      if evaluation is InteriorProduct {
        // A single one-form is safe too: volume has degree-zero source, so this
        // does not recursively re-enter the same decomposition.
        match one_form_factors(original) {
          Some(factors) => {
            let graph = match contract_factors(factors, s.volume()) {
              Ok(value) => value
              Err(error) => return Err(error)
            }
            return graph.parts_with(evaluation)
          }
          None => ()
        }
      }
      let rule = match prepared {
        Some(value) => value
        None =>
          match s.prepare(original.degree_value) {
            Ok(value) => value
            Err(error) => return Err(error)
          }
      }
      let value = match original.parts_with(evaluation) {
        Ok(value) => value
        Err(error) => return Err(error)
      }
      match rule.expand(value) {
        Ok(value) => s.canonical_parts(value)
        Err(error) => Err(error)
      }
    }
  }
}
