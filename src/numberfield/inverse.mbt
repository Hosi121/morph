///|
/// Exact identity input*inverse + modulus*cofactor = 1 in Q[t], not just
/// congruence. All public certificate fields are untrusted checker inputs.
#derive(Eq, Debug)
pub(all) struct InverseCertificate {
  context : @real.RootCertificate
  input : @poly.Polynomial
  inverse : @poly.Polynomial
  cofactor : @poly.Polynomial
}

///|
pub extend InverseCertificate with Eq::{equal, not_equal}

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
/// Extended Euclid: r = s*input modulo modulus. Strict degree descent in r
/// makes this finite independently of any irreducibility verification budget.
fn euclid(
  old_r : @poly.Polynomial,
  r : @poly.Polynomial,
  old_s : @poly.Polynomial,
  s : @poly.Polynomial,
) -> (@poly.Polynomial, @poly.Polynomial)? {
  if @poly.is_zero(r) {
    return Some((old_r, old_s))
  }
  match @poly.divide(old_r, Cons(r, Nil)) {
    Ok({ quotients: Cons(q, Nil), remainder, }) =>
      match @poly.multiply(q, s) {
        Ok(product) =>
          match @poly.subtract(old_s, product) {
            Ok(next_s) => euclid(r, remainder, s, next_s)
            Err(_) => None
          }
        Err(_) => None
      }
    _ => None
  }
}

///|
pub fn inverse_with_certificate(
  value : Element,
) -> Result[Inverse?, FieldError] {
  if is_zero(value) {
    return Ok(None)
  }
  let field = value.field
  let unity = @poly.constant(Succ(Zero), @exact.rational_one())
  let (gcd, bezout) = match
    euclid(modulus(field), value.residue, @poly.zero(Succ(Zero)), unity) {
    Some(result) => result
    None => return Err(InternalInvariant)
  }
  let c = match @poly.terms(gcd) {
    Cons({ coefficient, exponents: Cons(Zero, Nil), }, Nil) => coefficient
    _ => return Err(InternalInvariant)
  }
  let scale = match @exact.rational_divide(@exact.rational_one(), c) {
    Some(scale) => scale
    None => return Err(InternalInvariant)
  }
  let normalized = match
    @poly.scale(bezout, { coefficient: scale, exponents: Cons(Zero, Nil), }) {
    Ok(result) => result
    Err(_) => return Err(InternalInvariant)
  }
  let inverse = match element(field, normalized) {
    Ok(result) => result
    Err(error) => return Err(error)
  }
  let product = match @poly.multiply(value.residue, inverse.residue) {
    Ok(result) => result
    Err(_) => return Err(InternalInvariant)
  }
  let difference = match @poly.subtract(unity, product) {
    Ok(result) => result
    Err(_) => return Err(InternalInvariant)
  }
  let cofactor = match @poly.divide(difference, Cons(modulus(field), Nil)) {
    Ok({ quotients: Cons(q, Nil), remainder, }) => {
      if !@poly.is_zero(remainder) {
        return Err(InternalInvariant)
      }
      q
    }
    _ => return Err(InternalInvariant)
  }
  Ok(
    Some({
      value: inverse,
      certificate: {
        context: embedding(field),
        input: value.residue,
        inverse: inverse.residue,
        cofactor,
      },
    }),
  )
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
/// Separate exact polynomial checker. It authenticates both Element payloads
/// and context, then checks Bezout without rerunning Euclid.
pub fn check_inverse_result(
  input : Element,
  value : Element,
  proof : InverseCertificate,
) -> Bool {
  if !same_field(input.field, value.field) ||
    !proof.context.equal(embedding(input.field)) ||
    !proof.input.equal(input.residue) ||
    !proof.inverse.equal(value.residue) ||
    is_zero(input) {
    return false
  }
  match
    (
      @poly.multiply(proof.input, proof.inverse),
      @poly.multiply(modulus(input.field), proof.cofactor),
    ) {
    (Ok(left), Ok(right)) =>
      match @poly.add(left, right) {
        Ok(result) =>
          result.equal(@poly.constant(Succ(Zero), @exact.rational_one()))
        Err(_) => false
      }
    _ => false
  }
}

///|
pub fn divide(a : Element, b : Element) -> Result[Element?, FieldError] {
  if !same_field(a.field, b.field) {
    return Err(DifferentField)
  }
  match inverse(b) {
    Err(error) => Err(error)
    Ok(None) => Ok(None)
    Ok(Some(inverted)) =>
      match multiply(a, inverted) {
        Ok(value) => Ok(Some(value))
        Err(error) => Err(error)
      }
  }
}
