///|
#derive(Eq, Debug)
pub(all) enum Orientation {
  Positive
  Negative
}

///|
pub extend Orientation with Eq::{equal, not_equal}

///|
pub extend Orientation with Debug::{to_repr}

///|
#derive(Eq, Debug)
pub(all) enum HodgeError {
  SpaceMismatch
  DimensionMismatch
  DegreeMismatch
  DegreeOutOfRange
  Form(@forms.FormError)
  Polynomial(@poly.PolyError)
  PositiveForm(@positiveform.FormError)
  Algebraic(@realalgebraic.AlgebraError)
  InternalShape
}

///|
pub extend HodgeError with Eq::{equal, not_equal}

///|
pub extend HodgeError with Debug::{to_repr}

///|
/// Fixed coordinate inner product, not a variable metric field or a metric jet.
/// A rational volume root is detected once. Otherwise t^two-D is irreducible
/// over QQ and the coefficient pair a+b sqrt(D) is unique.
#derive(Debug)
pub struct Space {
  metric_value : @positiveform.PositiveDefinite
  matrix_value : @matrix.Matrix[@exact.Rational]
  congruence_value : @positiveform.Congruence
  orientation_value : Orientation
  rational_root : @exact.Rational?
}

///|
pub impl Eq for Space with fn equal(self : Space, other : Space) -> Bool {
  self.orientation_value.equal(other.orientation_value) &&
  self.matrix_value.equal(other.matrix_value)
}

///|
pub extend Space with Eq::{equal, not_equal}

///|
pub extend Space with Debug::{to_repr}

///|
pub fn space(
  metric : @positiveform.PositiveDefinite,
  orientation : Orientation,
) -> Result[Space, HodgeError] {
  let matrix_value = match metric.matrix() {
    Ok(value) => value
    Err(error) => return Err(PositiveForm(error))
  }
  let square = metric.determinant().value()
  let (nr, nrest) = @binary.sqrt_rem(@exact.magnitude(@exact.numerator(square)))
  let (dr, drest) = @binary.sqrt_rem(@exact.denominator(square))
  let rational_root = if @binary.is_zero(nrest) && @binary.is_zero(drest) {
    match @exact.ratio(@exact.positive(nr), dr) {
      Some(value) => Some(value)
      None => return Err(InternalShape)
    }
  } else {
    None
  }
  Ok({
    metric_value: metric,
    matrix_value,
    congruence_value: metric.congruence(),
    orientation_value: orientation,
    rational_root,
  })
}

///|
pub fn Space::dimension(self : Space) -> @core.Nat {
  self.metric_value.dimension()
}

///|
pub fn Space::metric(self : Space) -> @positiveform.PositiveDefinite {
  self.metric_value
}

///|
pub fn Space::orientation(self : Space) -> Orientation {
  self.orientation_value
}

///|
pub fn Space::reverse_orientation(self : Space) -> Space {
  {
    ..self,
    orientation_value: match self.orientation_value {
      Positive => Negative
      Negative => Positive
    },
  }
}

///|
pub fn Space::volume_squared(self : Space) -> @positiveform.PositiveScalar {
  self.metric_value.determinant()
}

///|
/// Positive volume magnitude; the orientation sign is represented separately.
pub fn Space::rational_volume(self : Space) -> @exact.Rational? {
  self.rational_root
}

///|
/// Explicit boundary to the existing generic real-algebraic root machinery.
pub fn Space::volume_root(
  self : Space,
) -> Result[@realalgebraic.Number, HodgeError] {
  match self.rational_root {
    Some(value) =>
      match @realalgebraic.rational(value) {
        Ok(value) => Ok(value)
        Err(error) => Err(Algebraic(error))
      }
    None => {
      let d = self.volume_squared().value()
      let polynomial = match
        @poly.polynomial(
          Succ(Zero),
          Cons(
            {
              coefficient: @exact.rational_one(),
              exponents: Cons(Succ(Succ(Zero)), Nil),
            },
            Cons(
              {
                coefficient: @exact.rational_negate(d),
                exponents: Cons(Zero, Nil),
              },
              Nil,
            ),
          ),
        ) {
        Ok(value) => value
        Err(error) => return Err(Polynomial(error))
      }
      match
        @realalgebraic.number({
          polynomial,
          interval: {
            lower: @exact.rational_zero(),
            upper: @exact.rational_add(d, @exact.rational_one()),
          },
        }) {
        Ok(value) => Ok(value)
        Err(error) => Err(Algebraic(error))
      }
    }
  }
}

///|
fn odd(value : @core.Nat) -> Bool {
  match value {
    Zero => false
    Succ(Zero) => true
    Succ(Succ(rest)) => odd(rest)
  }
}

///|
fn[A, B] traverse(
  values : @core.Chain[A],
  f : (A) -> Result[B, HodgeError],
) -> Result[@core.Chain[B], HodgeError] {
  match values {
    Nil => Ok(Nil)
    Cons(head, tail) => {
      let value = match f(head) {
        Ok(value) => value
        Err(error) => return Err(error)
      }
      match traverse(tail, f) {
        Ok(rest) => Ok(Cons(value, rest))
        Err(error) => Err(error)
      }
    }
  }
}

///|
fn scale_polynomial(
  value : @poly.Polynomial,
  factor : @exact.Rational,
) -> Result[@poly.Polynomial, HodgeError] {
  match
    @poly.scale(value, {
      coefficient: factor,
      exponents: @core.replicate(@poly.variables(value), Zero),
    }) {
    Ok(value) => Ok(value)
    Err(error) => Err(Polynomial(error))
  }
}

///|
fn scale_form(
  value : @forms.Form,
  factor : @exact.Rational,
) -> Result[@forms.Form, HodgeError] {
  if factor.equal(@exact.rational_zero()) {
    return Ok(@forms.zero(@forms.variables(value), @forms.degree(value)))
  }
  if factor.equal(@exact.rational_one()) {
    return Ok(value)
  }
  let terms = match
    traverse(@forms.terms(value), fn(term) {
      match scale_polynomial(term.coefficient, factor) {
        Ok(coefficient) =>
          Ok(@forms.Term::{ coefficient, indices: term.indices, })
        Err(error) => Err(error)
      }
    }) {
    Ok(value) => value
    Err(error) => return Err(error)
  }
  match @forms.form(@forms.variables(value), @forms.degree(value), terms) {
    Ok(value) => Ok(value)
    Err(error) => Err(Form(error))
  }
}

///|
fn add_forms(
  a : @forms.Form,
  b : @forms.Form,
) -> Result[@forms.Form, HodgeError] {
  match @forms.add(a, b) {
    Ok(value) => Ok(value)
    Err(error) => Err(Form(error))
  }
}

///|
fn wedge_forms(
  a : @forms.Form,
  b : @forms.Form,
) -> Result[@forms.Form, HodgeError] {
  match @forms.wedge(a, b) {
    Ok(value) => Ok(value)
    Err(error) => Err(Form(error))
  }
}

///|
fn add_polynomials(
  a : @poly.Polynomial,
  b : @poly.Polynomial,
) -> Result[@poly.Polynomial, HodgeError] {
  match @poly.add(a, b) {
    Ok(value) => Ok(value)
    Err(error) => Err(Polynomial(error))
  }
}

///|
fn multiply_polynomials(
  a : @poly.Polynomial,
  b : @poly.Polynomial,
) -> Result[@poly.Polynomial, HodgeError] {
  match @poly.multiply(a, b) {
    Ok(value) => Ok(value)
    Err(error) => Err(Polynomial(error))
  }
}
