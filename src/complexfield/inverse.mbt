///|
/// Untrusted witness bound to source/result and the real-field Bezout identity.
#derive(Debug)
pub(all) struct InverseCertificate {
  input : Element
  value : Element
  denominator_inverse : @nf.Element
  denominator_certificate : @nf.InverseCertificate
}

///|
pub extend InverseCertificate with Debug::{to_repr}

///|
#derive(Debug)
pub(all) struct Inverse {
  value : Element
  certificate : InverseCertificate
}

///|
pub extend Inverse with Debug::{to_repr}

///|
pub fn inverse_with_certificate(
  value : Element,
) -> Result[Inverse?, FieldError] {
  if !valid(value) {
    return Err(DifferentField)
  }
  if is_zero(value) {
    return Ok(None)
  }
  let denominator = match relative_norm(value) {
    Ok(result) => result
    Err(error) => return Err(error)
  }
  let inverted = match lift(@nf.inverse_with_certificate(denominator)) {
    Ok(Some(result)) => result
    Ok(None) => return Err(InternalInvariant)
    Err(error) => return Err(error)
  }
  match
    (
      @nf.multiply(value.real, inverted.value),
      @nf.multiply(@nf.negate(value.imaginary), inverted.value),
    ) {
    (Ok(real), Ok(imaginary)) => {
      let result = match element(value.field, real, imaginary) {
        Ok(result) => result
        Err(error) => return Err(error)
      }
      let certificate : InverseCertificate = {
        input: value,
        value: result,
        denominator_inverse: inverted.value,
        denominator_certificate: inverted.certificate,
      }
      if check_inverse_result(value, result, certificate) {
        Ok(Some({ value: result, certificate, }))
      } else {
        Err(InternalInvariant)
      }
    }
    _ => Err(InternalInvariant)
  }
}

///|
pub fn inverse(value : Element) -> Result[Element?, FieldError] {
  match inverse_with_certificate(value) {
    Ok(Some(result)) => Ok(Some(result.value))
    Ok(None) => Ok(None)
    Err(error) => Err(error)
  }
}

///|
/// Authenticate source, result, contexts and denominator Bezout witness;
/// then check input*result=1 independently of the inversion algorithm.
pub fn check_inverse_result(
  input : Element,
  value : Element,
  proof : InverseCertificate,
) -> Bool {
  if !same_context(input, value) ||
    is_zero(input) ||
    !equal(input, proof.input) ||
    !equal(value, proof.value) {
    return false
  }
  match relative_norm(input) {
    Ok(denominator) =>
      if !@nf.check_inverse_result(
          denominator,
          proof.denominator_inverse,
          proof.denominator_certificate,
        ) {
        return false
      }
    Err(_) => return false
  }
  match multiply(input, value) {
    Ok(product) => equal(product, one(input.field))
    Err(_) => false
  }
}

///|
pub fn divide(a : Element, b : Element) -> Result[Element?, FieldError] {
  if !same_context(a, b) {
    return Err(DifferentField)
  }
  match inverse(b) {
    Ok(Some(inverted)) =>
      match multiply(a, inverted) {
        Ok(result) => Ok(Some(result))
        Err(error) => Err(error)
      }
    Ok(None) => Ok(None)
    Err(error) => Err(error)
  }
}
