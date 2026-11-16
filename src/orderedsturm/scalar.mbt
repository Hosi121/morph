///|
#derive(Eq, Debug)
pub(all) enum OrderedError {
  DifferentField
  ZeroDivisor
  ZeroPolynomial
  InvalidInterval
  InvalidCertificate
  FieldFailure(@nf.FieldError)
  SignFailure(@tarski.TarskiError)
  InternalInvariant
}

///|
pub extend OrderedError with Eq::{equal, not_equal}

///|
pub extend OrderedError with Debug::{to_repr}

///|
#derive(Eq, Debug)
pub(all) struct ScalarCertificate {
  context : @real.RootCertificate
  representative : @poly.Polynomial
  sign : @core.Ordering
  tarski : @tarski.RootSignCertificate
}

///|
pub extend ScalarCertificate with Eq::{equal, not_equal}

///|
pub extend ScalarCertificate with Debug::{to_repr}

///|
#derive(Eq, Debug)
pub(all) struct ScalarSign {
  sign : @core.Ordering
  certificate : ScalarCertificate
}

///|
pub extend ScalarSign with Eq::{equal, not_equal}

///|
pub extend ScalarSign with Debug::{to_repr}

///|
fn coherent(value : @nf.Element, sign : @core.Ordering) -> Bool {
  match (sign, @nf.is_zero(value)) {
    (Equal, true) | (Less, false) | (Greater, false) => true
    _ => false
  }
}

///|
/// Exact ordering of the checked field's selected REAL embedding. The base
/// root interval is retained unchanged by the Sturm-Tarski decision.
pub fn scalar_sign(value : @nf.Element) -> Result[ScalarSign, OrderedError] {
  let context = @nf.embedding(@nf.parent(value))
  let representative = @nf.representative(value)
  match @tarski.root_sign(context, representative) {
    Err(error) => Err(SignFailure(error))
    Ok(result) =>
      if coherent(value, result.sign) {
        Ok({
          sign: result.sign,
          certificate: {
            context,
            representative,
            sign: result.sign,
            tarski: result.certificate,
          },
        })
      } else {
        Err(InternalInvariant)
      }
  }
}

///|
/// Bind the Element, its full field embedding, Ordering payload and Tarski proof.
pub fn check_scalar(
  value : @nf.Element,
  sign : @core.Ordering,
  proof : ScalarCertificate,
) -> Bool {
  @nf.embedding(@nf.parent(value)).equal(proof.context) &&
  @nf.representative(value).equal(proof.representative) &&
  sign.equal(proof.sign) &&
  coherent(value, sign) &&
  @tarski.check_root_sign(
    proof.context,
    proof.representative,
    sign,
    proof.tarski,
  )
}
