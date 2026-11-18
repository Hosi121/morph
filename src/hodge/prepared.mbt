///|
/// A grade-specific view of the original-space congruence. No exterior basis
/// enumeration or compound matrix is retained.
#derive(Eq, Debug)
pub struct PreparedHodge {
  space_value : Space
  degree_value : @core.Nat
}

///|
pub extend PreparedHodge with Eq::{equal, not_equal}

///|
pub extend PreparedHodge with Debug::{to_repr}

///|
pub fn Space::prepare(
  self : Space,
  degree : @core.Nat,
) -> Result[PreparedHodge, HodgeError] {
  if @core.compare(degree, self.dimension()) is Greater {
    return Err(DegreeOutOfRange)
  }
  Ok({ space_value: self, degree_value: degree, })
}

///|
pub fn PreparedHodge::parent(self : PreparedHodge) -> Space {
  self.space_value
}

///|
pub fn PreparedHodge::degree(self : PreparedHodge) -> @core.Nat {
  self.degree_value
}

///|
pub fn PreparedHodge::apply(
  self : PreparedHodge,
  value : HodgeForm,
) -> Result[HodgeForm, HodgeError] {
  if !self.space_value.equal(value.space_value) {
    return Err(SpaceMismatch)
  }
  if !self.degree_value.equal(value.degree_value) {
    return Err(DegreeMismatch)
  }
  match value.expression {
    Starred(_, _) | Negated(_) => Ok(value.star())
    _ =>
      Ok({
        space_value: self.space_value,
        degree_value: @core.subtract(
          self.space_value.dimension(),
          self.degree_value,
        ),
        expression: Starred(value, Some(self)),
      })
  }
}

///|
fn coefficient(
  terms : @core.Chain[@forms.Term],
  indices : @core.Chain[@core.Nat],
  dimension : @core.Nat,
) -> @poly.Polynomial {
  match terms {
    Nil => @poly.zero(dimension)
    Cons(term, tail) =>
      if term.indices.equal(indices) {
        term.coefficient
      } else {
        coefficient(tail, indices, dimension)
      }
  }
}

///|
fn apply_inverse_shears(
  word : @core.Chain[@positiveform.Shear],
  value : @forms.Form,
  transposed : Bool,
) -> Result[@forms.Form, HodgeError] {
  match word {
    Nil => Ok(value)
    Cons(shear, tail) => {
      let shear = if transposed {
        shear.transpose().inverse()
      } else {
        shear.inverse()
      }
      let next = match
        @forms.shear(value, shear.target(), shear.source(), shear.coefficient()) {
        Ok(value) => value
        Err(error) => return Err(Form(error))
      }
      apply_inverse_shears(tail, next, transposed)
    }
  }
}

///|
/// g^-one = F^-T D^-one F^-one. The word lists MATRIX product order.
fn PreparedHodge::covector_action(
  self : PreparedHodge,
  value : @forms.Form,
) -> Result[@forms.Form, HodgeError] {
  let factorization = self.space_value.congruence_value
  let word = factorization.shears()
  let first = match apply_inverse_shears(word, value, false) {
    Ok(value) => value
    Err(error) => return Err(error)
  }
  let diagonal = @core.map(factorization.diagonal(), fn(value) {
    value.inverse().value()
  })
  let scaled = match @forms.scale_axes(first, diagonal) {
    Ok(value) => value
    Err(error) => return Err(Form(error))
  }
  apply_inverse_shears(@core.reverse(word), scaled, true)
}

///|
fn PreparedHodge::transform(
  self : PreparedHodge,
  value : @forms.Form,
) -> Result[@forms.Form, HodgeError] {
  let mapped = match self.covector_action(value) {
    Ok(value) => value
    Err(error) => return Err(error)
  }
  match @forms.euclidean_star(mapped) {
    Err(error) => Err(Form(error))
    Ok(value) =>
      Ok(
        match self.space_value.orientation_value {
          Positive => value
          Negative => @forms.negate(value)
        },
      )
  }
}

///|
fn PreparedHodge::expand(
  self : PreparedHodge,
  value : Parts,
) -> Result[Parts, HodgeError] {
  let radical = match self.transform(value.rational) {
    Ok(value) => value
    Err(error) => return Err(error)
  }
  let rational = match self.transform(value.radical) {
    Ok(value) => value
    Err(error) => return Err(error)
  }
  match scale_form(rational, self.space_value.volume_squared().value()) {
    Ok(rational) => Ok({ rational, radical, })
    Err(error) => Err(error)
  }
}

///|
fn sparse_dot(
  a : @forms.Form,
  b : @forms.Form,
) -> Result[@poly.Polynomial, HodgeError] {
  let dimension = @forms.variables(a)
  fn walk(
    terms : @core.Chain[@forms.Term],
  ) -> Result[@poly.Polynomial, HodgeError] {
    match terms {
      Nil => Ok(@poly.zero(dimension))
      Cons(term, tail) => {
        let product = match
          multiply_polynomials(
            term.coefficient,
            coefficient(@forms.terms(b), term.indices, dimension),
          ) {
          Ok(value) => value
          Err(error) => return Err(error)
        }
        let rest = match walk(tail) {
          Ok(value) => value
          Err(error) => return Err(error)
        }
        add_polynomials(product, rest)
      }
    }
  }
  walk(@forms.terms(a))
}

///|
pub fn PreparedHodge::inner(
  self : PreparedHodge,
  a : HodgeForm,
  b : HodgeForm,
) -> Result[HodgeForm, HodgeError] {
  if !self.space_value.equal(a.space_value) ||
    !self.space_value.equal(b.space_value) {
    return Err(SpaceMismatch)
  }
  if !self.degree_value.equal(a.degree_value) ||
    !self.degree_value.equal(b.degree_value) {
    return Err(DegreeMismatch)
  }
  let a = match a.parts() {
    Ok(value) => value
    Err(error) => return Err(error)
  }
  let b = match b.parts() {
    Ok(value) => value
    Err(error) => return Err(error)
  }
  let b0 = match self.covector_action(b.rational) {
    Ok(value) => value
    Err(error) => return Err(error)
  }
  let b1 = match self.covector_action(b.radical) {
    Ok(value) => value
    Err(error) => return Err(error)
  }
  let aa = match sparse_dot(a.rational, b0) {
    Ok(value) => value
    Err(error) => return Err(error)
  }
  let bb = match sparse_dot(a.radical, b1) {
    Ok(value) => value
    Err(error) => return Err(error)
  }
  let bb = match
    scale_polynomial(bb, self.space_value.volume_squared().value()) {
    Ok(value) => value
    Err(error) => return Err(error)
  }
  let ab = match sparse_dot(a.rational, b1) {
    Ok(value) => value
    Err(error) => return Err(error)
  }
  let ba = match sparse_dot(a.radical, b0) {
    Ok(value) => value
    Err(error) => return Err(error)
  }
  let rational = match add_polynomials(aa, bb) {
    Ok(value) => value
    Err(error) => return Err(error)
  }
  let radical = match add_polynomials(ab, ba) {
    Ok(value) => value
    Err(error) => return Err(error)
  }
  self.space_value.from_parts({
    rational: @forms.scalar(rational),
    radical: @forms.scalar(radical),
  })
}

///|
fn contract_component(
  vector : @forms.Form,
  value : @forms.Form,
) -> Result[@forms.Form, HodgeError] {
  let dimension = @forms.variables(value)
  let components = @core.map(@core.indices(dimension), fn(i) {
    coefficient(@forms.terms(vector), Cons(i, Nil), dimension)
  })
  let field = match @forms.vector_field(dimension, components) {
    Ok(value) => value
    Err(error) => return Err(Form(error))
  }
  match @forms.contract(field, value) {
    Ok(Some(value)) => Ok(value)
    Ok(None) => Err(DegreeOutOfRange)
    Err(error) => Err(Form(error))
  }
}

///|
fn Space::interior_parts(
  self : Space,
  covector : Parts,
  value : Parts,
) -> Result[Parts, HodgeError] {
  let rule = PreparedHodge::{ space_value: self, degree_value: Succ(Zero), }
  let a0 = match rule.covector_action(covector.rational) {
    Ok(value) => value
    Err(error) => return Err(error)
  }
  let a1 = match rule.covector_action(covector.radical) {
    Ok(value) => value
    Err(error) => return Err(error)
  }
  let aa = match contract_component(a0, value.rational) {
    Ok(value) => value
    Err(error) => return Err(error)
  }
  let bb = match contract_component(a1, value.radical) {
    Ok(value) => value
    Err(error) => return Err(error)
  }
  let bb = match scale_form(bb, self.volume_squared().value()) {
    Ok(value) => value
    Err(error) => return Err(error)
  }
  let ab = match contract_component(a0, value.radical) {
    Ok(value) => value
    Err(error) => return Err(error)
  }
  let ba = match contract_component(a1, value.rational) {
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
  Ok({ rational, radical, })
}
