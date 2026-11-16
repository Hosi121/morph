///|
#derive(Eq, Debug)
pub(all) struct RootSignCertificate {
  root : @real.RootCertificate
  query : @poly.Polynomial
  query_certificate : QueryCertificate
  sign : @core.Ordering
}

///|
pub extend RootSignCertificate with Eq::{equal, not_equal}

///|
pub extend RootSignCertificate with Debug::{to_repr}

///|
#derive(Eq, Debug)
pub(all) struct SignResult {
  sign : @core.Ordering
  certificate : RootSignCertificate
}

///|
pub extend SignResult with Eq::{equal, not_equal}

///|
pub extend SignResult with Debug::{to_repr}

///|
fn unit_integer(value : @exact.Integer) -> Bool {
  !@binary.compare(@exact.magnitude(value), @binary.one()).equal(Greater)
}

///|
fn integer_sign(value : @exact.Integer) -> @core.Ordering {
  @exact.compare(value, @exact.positive(@binary.zero()))
}

///|
/// Determine sign(Q(alpha)) at a checked one-root half-open interval.
/// Less/Equal/Greater mean negative/zero/positive. Neither the selected interval
/// nor any other root interval is refined or numerically approximated.
pub fn root_sign(
  root : @real.RootCertificate,
  q : @poly.Polynomial,
) -> Result[SignResult, TarskiError] {
  if !@real.check_root(root) {
    Err(InvalidRoot)
  } else {
    match query(root.polynomial, q, root.interval) {
      Err(error) => Err(error)
      Ok(result) =>
        if !unit_integer(result.value) {
          Err(InternalInvariant)
        } else {
          let sign = integer_sign(result.value)
          Ok({
            sign,
            certificate: {
              root,
              query: q,
              query_certificate: result.certificate,
              sign,
            },
          })
        }
    }
  }
}

///|
/// Bind the external root definition, interval, Q and Ordering payload, then
/// verify the one-root condition and the complete signed query certificate.
pub fn check_root_sign(
  root : @real.RootCertificate,
  q : @poly.Polynomial,
  value : @core.Ordering,
  proof : RootSignCertificate,
) -> Bool {
  root.equal(proof.root) &&
  q.equal(proof.query) &&
  value.equal(proof.sign) &&
  @real.check_root(root) &&
  check_query(root.polynomial, q, root.interval, proof.query_certificate) &&
  unit_integer(proof.query_certificate.result) &&
  integer_sign(proof.query_certificate.result).equal(value)
}

///|
pub fn sign_at(
  value : @real.Number,
  q : @poly.Polynomial,
) -> Result[SignResult, TarskiError] {
  root_sign(@real.root_certificate(value), q)
}

///|
pub fn check_sign_at(
  value : @real.Number,
  q : @poly.Polynomial,
  sign : @core.Ordering,
  proof : RootSignCertificate,
) -> Bool {
  check_root_sign(@real.root_certificate(value), q, sign, proof)
}
