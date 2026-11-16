///|
#derive(Debug)
pub(all) struct Certificate {
  source : @poly.Polynomial
  ambient : @cf.Field
  roots : @core.Chain[Root]
  generated : @sub.Certificate
  primitive : @sub.PrimitiveCertificate
  images : @core.Chain[RootImage]
}

///|
pub extend Certificate with Debug::{to_repr}

///|
#derive(Debug)
pub struct Splitting {
  priv proof : Certificate
  priv field : @sub.Field
  priv representation : @sub.Representation
}

///|
pub extend Splitting with Debug::{to_repr}

///|
pub fn source(value : Splitting) -> @poly.Polynomial {
  value.proof.source
}

///|
pub fn ambient(value : Splitting) -> @cf.Field {
  value.proof.ambient
}

///|
pub fn roots(value : Splitting) -> @core.Chain[Root] {
  value.proof.roots
}

///|
pub fn root_images(value : Splitting) -> @core.Chain[RootImage] {
  value.proof.images
}

///|
pub fn generated_field(value : Splitting) -> @sub.Field {
  value.field
}

///|
pub fn representation(value : Splitting) -> @sub.Representation {
  value.representation
}

///|
pub fn degree(value : Splitting) -> @core.Nat {
  @sub.degree(value.field)
}

///|
pub fn modulus(value : Splitting) -> @poly.Polynomial {
  @sub.modulus(value.representation)
}

///|
pub fn certificate(value : Splitting) -> Certificate {
  value.proof
}

///|
/// All roots are complete, and monomial provenance plus closure certifies the
/// SMALLEST generated subfield, rather than an oversized ambient field.
pub fn check(
  source : @poly.Polynomial,
  ambient : @cf.Field,
  proof : Certificate,
) -> Bool {
  if !source.equal(proof.source) ||
    !@cf.same_field(ambient, proof.ambient) ||
    !valid_roots(source, ambient, proof.roots) {
    return false
  }
  let field = match
    @sub.from_certificate(ambient, root_values(proof.roots), proof.generated) {
    Ok(value) => value
    Err(_) => return false
  }
  match @sub.from_primitive_certificate(field, proof.primitive) {
    Ok(representation) =>
      check_images(representation, proof.roots, proof.images)
    Err(_) => false
  }
}

///|
pub fn check_result(
  source : @poly.Polynomial,
  ambient : @cf.Field,
  result : Splitting,
  proof : Certificate,
) -> Bool {
  source.equal(result.proof.source) &&
  @cf.same_field(ambient, result.proof.ambient) &&
  same_roots(result.proof.roots, proof.roots) &&
  check(source, ambient, proof) &&
  check(source, ambient, result.proof) &&
  @sub.check_result(
    ambient,
    root_values(proof.roots),
    result.field,
    proof.generated,
  ) &&
  @sub.check_primitive_result(
    result.field,
    result.representation,
    proof.primitive,
  ) &&
  check_images(result.representation, roots(result), result.proof.images)
}

///|
pub fn from_certificate(
  source : @poly.Polynomial,
  ambient : @cf.Field,
  proof : Certificate,
) -> Result[Splitting, SplittingError] {
  if !check(source, ambient, proof) {
    return Err(InvalidCertificate)
  }
  let field = match
    @sub.from_certificate(ambient, root_values(proof.roots), proof.generated) {
    Ok(value) => value
    Err(_) => return Err(InvalidCertificate)
  }
  match @sub.from_primitive_certificate(field, proof.primitive) {
    Ok(representation) => Ok({ proof, field, representation, })
    Err(_) => Err(InvalidCertificate)
  }
}

///|
fn finish(
  source : @poly.Polynomial,
  ambient : @cf.Field,
  values : @core.Chain[Root],
  field : @sub.Field,
  representation : @sub.Representation,
  primitive : @sub.PrimitiveCertificate,
) -> Result[Splitting, SplittingError] {
  let images = match make_images(representation, values) {
    Some(value) => value
    None => return Err(InternalInvariant)
  }
  let proof : Certificate = {
    source,
    ambient,
    roots: values,
    generated: @sub.certificate(field),
    primitive,
    images,
  }
  let result : Splitting = { proof, field, representation, }
  if check_result(source, ambient, result, proof) {
    Ok(result)
  } else {
    Err(InternalInvariant)
  }
}
