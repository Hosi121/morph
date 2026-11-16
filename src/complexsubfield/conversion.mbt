///|
#derive(Debug)
pub(all) struct ConversionCertificate {
  representation : PrimitiveCertificate
  input : @cf.Element
  polynomial : @poly.Polynomial
}

///|
pub extend ConversionCertificate with Debug::{to_repr}

///|
#derive(Debug)
pub(all) struct Conversion {
  polynomial : @poly.Polynomial
  certificate : ConversionCertificate
}

///|
pub extend Conversion with Debug::{to_repr}

///|
fn coefficients_polynomial(
  values : @core.Chain[@exact.Rational],
) -> @poly.Polynomial? {
  match @core.zip(@core.indices(@core.length(values)), values) {
    Some(entries) =>
      match
        @poly.polynomial(
          Succ(Zero),
          @core.map(entries, fn(entry) {
            let (index, coefficient) = entry
            @poly.Term::{ coefficient, exponents: Cons(index, Nil), }
          }),
        ) {
        Ok(value) => Some(value)
        Err(_) => None
      }
    None => None
  }
}

///|
/// The actual source and canonical polynomial are separately supplied. Direct
/// evaluation binds them independently of producer coordinate metadata.
pub fn check_conversion_for(
  representation : Representation,
  input : @cf.Element,
  polynomial : @poly.Polynomial,
  proof : ConversionCertificate,
) -> Bool {
  let field = representation_field(representation)
  if !@cf.same_field(ambient(field), @cf.parent(input)) ||
    !@cf.equal(input, proof.input) ||
    !polynomial.equal(proof.polynomial) ||
    !same_primitive_certificate(
      primitive_certificate(representation),
      proof.representation,
    ) ||
    !canonical(degree(field), polynomial) ||
    !check_primitive_result(field, representation, proof.representation) {
    return false
  }
  match @cf.evaluate_polynomial(primitive_element(representation), polynomial) {
    Some(value) => @cf.equal(input, value)
    None => false
  }
}

///|
pub fn to_polynomial(
  representation : Representation,
  input : @cf.Element,
) -> Result[Conversion, SubfieldError] {
  let field = representation_field(representation)
  if !@cf.same_field(ambient(field), @cf.parent(input)) {
    return Err(DifferentField)
  }
  match
    @linear.solve(representation.proof.power_basis, @cf.coordinates(input)) {
    Some(@linear.Unique(coefficients)) =>
      match coefficients_polynomial(coefficients) {
        Some(polynomial) => {
          let proof : ConversionCertificate = {
            representation: primitive_certificate(representation),
            input,
            polynomial,
          }
          Ok({ polynomial, certificate: proof, })
        }
        None => Err(InternalInvariant)
      }
    Some(@linear.Inconsistent) => Err(NotInSubfield)
    _ => Err(InternalInvariant)
  }
}

///|
/// Reduce any univariate polynomial modulo the checked minimum and evaluate its
/// canonical residue in the original ambient field.
pub fn from_polynomial(
  representation : Representation,
  polynomial : @poly.Polynomial,
) -> Result[@cf.Element, SubfieldError] {
  if !@poly.variables(polynomial).equal(Succ(Zero)) {
    return Err(NotUnivariate)
  }
  match @poly.normal_form(polynomial, Cons(modulus(representation), Nil)) {
    Ok(reduced) =>
      match
        @cf.evaluate_polynomial(primitive_element(representation), reduced) {
        Some(value) => Ok(value)
        None => Err(InternalInvariant)
      }
    Err(_) => Err(InternalInvariant)
  }
}
