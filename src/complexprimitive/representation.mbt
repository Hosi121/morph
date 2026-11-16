///|
#derive(Eq, Debug)
pub(all) enum PrimitiveError {
  InvalidCertificate
  DifferentField
  NotUnivariate
  InternalInvariant
}

///|
pub extend PrimitiveError with Eq::{equal, not_equal}

///|
pub extend PrimitiveError with Debug::{to_repr}

///|
/// Untrusted witness for theta=alpha+i and the absolute Q power basis.
/// Columns of basis are theta^j in [1,alpha,...,i,i*alpha,...].
#derive(Debug)
pub(all) struct Certificate {
  source : @cf.Field
  theta : @cf.Element
  modulus : @poly.Polynomial
  basis : @matrix.Matrix[@exact.Rational]
  inverse_basis : @matrix.Matrix[@exact.Rational]
  real_generator_image : @poly.Polynomial
  imaginary_unit_image : @poly.Polynomial
}

///|
pub extend Certificate with Debug::{to_repr}

///|
/// A checked absolute monogenic presentation of a fixed real field plus i.
#derive(Debug)
pub struct Representation {
  priv proof : Certificate
}

///|
pub extend Representation with Debug::{to_repr}

///|
pub fn source(value : Representation) -> @cf.Field {
  value.proof.source
}

///|
pub fn degree(value : Representation) -> @core.Nat {
  @cf.degree(source(value))
}

///|
pub fn generator(value : Representation) -> @cf.Element {
  value.proof.theta
}

///|
pub fn modulus(value : Representation) -> @poly.Polynomial {
  value.proof.modulus
}

///|
pub fn basis_matrix(value : Representation) -> @matrix.Matrix[@exact.Rational] {
  value.proof.basis
}

///|
pub fn inverse_basis_matrix(
  value : Representation,
) -> @matrix.Matrix[@exact.Rational] {
  value.proof.inverse_basis
}

///|
pub fn real_generator_image(value : Representation) -> @poly.Polynomial {
  value.proof.real_generator_image
}

///|
pub fn imaginary_unit_image(value : Representation) -> @poly.Polynomial {
  value.proof.imaginary_unit_image
}

///|
pub fn certificate(value : Representation) -> Certificate {
  value.proof
}

///|
fn real_generator(field : @cf.Field) -> @cf.Element? {
  let real = @cf.real_field(field)
  match @nf.generator(real) {
    Ok(alpha) =>
      match @cf.element(field, alpha, @nf.zero(real)) {
        Ok(value) => Some(value)
        Err(_) => None
      }
    Err(_) => None
  }
}

///|
fn expected_generator(field : @cf.Field) -> @cf.Element? {
  match real_generator(field) {
    Some(alpha) =>
      match @cf.add(alpha, @cf.imaginary_unit(field)) {
        Ok(value) => Some(value)
        Err(_) => None
      }
    None => None
  }
}

///|
/// CF contexts deliberately have no derived Eq: bind them and theta explicitly.
fn same_certificate(a : Certificate, b : Certificate) -> Bool {
  @cf.same_field(a.source, b.source) &&
  @cf.equal(a.theta, b.theta) &&
  a.modulus.equal(b.modulus) &&
  a.basis.equal(b.basis) &&
  a.inverse_basis.equal(b.inverse_basis) &&
  a.real_generator_image.equal(b.real_generator_image) &&
  a.imaginary_unit_image.equal(b.imaginary_unit_image)
}

///|
/// Independently bind the source, theta, its true minimum, every power-basis
/// column, both inverse equations, and the images of alpha and i.
pub fn check(field : @cf.Field, proof : Certificate) -> Bool {
  if !@cf.same_field(field, proof.source) ||
    !@cf.same_field(field, @cf.parent(proof.theta)) {
    return false
  }
  match expected_generator(field) {
    Some(theta) => if !@cf.equal(theta, proof.theta) { return false }
    None => return false
  }
  let d = @cf.degree(field)
  if !polynomial_degree(proof.modulus).equal(Some(d)) ||
    !@cf.check_minimal_polynomial(proof.theta, proof.modulus) {
    return false
  }
  match power_basis(field, proof.theta) {
    Some(expected) => if !expected.equal(proof.basis) { return false }
    None => return false
  }
  let identity = @matrix.identity(d, @algebra.rationals())
  match
    (
      @matrix.multiply(proof.basis, proof.inverse_basis, @algebra.rationals()),
      @matrix.multiply(proof.inverse_basis, proof.basis, @algebra.rationals()),
    ) {
    (Some(left), Some(right)) =>
      if !left.equal(identity) || !right.equal(identity) {
        return false
      }
    _ => return false
  }
  if !canonical(d, proof.real_generator_image) ||
    !canonical(d, proof.imaginary_unit_image) {
    return false
  }
  match
    (
      real_generator(field),
      @cf.evaluate_polynomial(proof.theta, proof.real_generator_image),
      @cf.evaluate_polynomial(proof.theta, proof.imaginary_unit_image),
    ) {
    (Some(alpha), Some(real_image), Some(imaginary_image)) =>
      @cf.equal(alpha, real_image) &&
      @cf.equal(@cf.imaginary_unit(field), imaginary_image)
    _ => false
  }
}

///|
pub fn from_certificate(
  field : @cf.Field,
  proof : Certificate,
) -> Result[Representation, PrimitiveError] {
  if check(field, proof) {
    Ok({ proof, })
  } else {
    Err(InvalidCertificate)
  }
}

///|
/// The returned presentation as well as the supplied source must match proof.
pub fn check_result(
  field : @cf.Field,
  result : Representation,
  proof : Certificate,
) -> Bool {
  same_certificate(result.proof, proof) && check(field, proof)
}

///|
/// Finite exact construction; no primitive-element search or fuel is needed.
pub fn prepare(field : @cf.Field) -> Result[Representation, PrimitiveError] {
  let theta = match expected_generator(field) {
    Some(value) => value
    None => return Err(InternalInvariant)
  }
  let minimum = match @cf.minimal_polynomial(theta) {
    Ok(value) => value
    Err(_) => return Err(InternalInvariant)
  }
  if !polynomial_degree(minimum).equal(Some(@cf.degree(field))) {
    return Err(InternalInvariant)
  }
  let basis = match power_basis(field, theta) {
    Some(value) => value
    None => return Err(InternalInvariant)
  }
  let inverse_basis = match @linear.inverse(basis) {
    Some(value) => value
    None => return Err(InternalInvariant)
  }
  let alpha = match real_generator(field) {
    Some(value) => value
    None => return Err(InternalInvariant)
  }
  match
    (
      coordinates_polynomial(inverse_basis, alpha),
      coordinates_polynomial(inverse_basis, @cf.imaginary_unit(field)),
    ) {
    (Some(real_generator_image), Some(imaginary_unit_image)) => {
      let proof : Certificate = {
        source: field,
        theta,
        modulus: minimum,
        basis,
        inverse_basis,
        real_generator_image,
        imaginary_unit_image,
      }
      if check(field, proof) {
        Ok({ proof, })
      } else {
        Err(InternalInvariant)
      }
    }
    _ => Err(InternalInvariant)
  }
}
