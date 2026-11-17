///|
#derive(Eq, Debug)
pub(all) enum FieldError {
  InvalidCertificate
  VerificationBudget
  DimensionMismatch
  DifferentField
  InternalInvariant
}

///|
pub extend FieldError with Eq::{equal, not_equal}

///|
pub extend FieldError with Debug::{to_repr}

///|
/// Opaque checked field with a fixed real embedding context.
#derive(Debug)
pub struct Field {
  proof : @minimal.Certificate
  degree : @core.Nat
  priv reduction : @poly.Polynomial
}

///|
pub extend Field with Debug::{to_repr}

///|
/// Opaque canonical residue with its checked field context.
#derive(Debug)
pub struct Element {
  field : Field
  residue : @poly.Polynomial
}

///|
pub extend Element with Debug::{to_repr}

///|
/// Both the modulus and selected-root interval are part of field identity.
pub fn same_field(a : Field, b : Field) -> Bool {
  a.proof.result.equal(b.proof.result)
}

///|
pub fn certificate(field : Field) -> @minimal.Certificate {
  field.proof
}

///|
pub fn modulus(field : Field) -> @poly.Polynomial {
  field.proof.result.polynomial
}

///|
pub fn embedding(field : Field) -> @real.RootCertificate {
  field.proof.result
}

///|
pub fn degree(field : Field) -> @core.Nat {
  field.degree
}

///|
/// Verification cannot be skipped. Undecided irreducibility is not a field.
pub fn field(
  proof : @minimal.Certificate,
  verification_fuel : @core.Nat,
) -> Result[Field, FieldError] {
  match @minimal.check(proof, verification_fuel) {
    @zass.Refuted => Err(InvalidCertificate)
    @zass.Undecided => Err(VerificationBudget)
    @zass.Proven =>
      match @poly.terms(proof.result.polynomial) {
        Cons({ exponents: Cons(d, Nil), .. }, _) =>
          match d {
            Zero => Err(InvalidCertificate)
            Succ(_) =>
              Ok({
                proof,
                degree: d,
                reduction: @poly.negate(@poly.monic(proof.result.polynomial)),
              })
          }
        _ => Err(InvalidCertificate)
      }
  }
}

///|
/// Constructor additionally authenticating a separately supplied Number.
pub fn field_result(
  value : @real.Number,
  proof : @minimal.Certificate,
  verification_fuel : @core.Nat,
) -> Result[Field, FieldError] {
  if !@real.root_certificate(value).equal(proof.result) {
    return Err(InvalidCertificate)
  }
  field(proof, verification_fuel)
}

///|
pub fn element(
  field : Field,
  polynomial : @poly.Polynomial,
) -> Result[Element, FieldError] {
  if !@poly.variables(polynomial).equal(Succ(Zero)) {
    return Err(DimensionMismatch)
  }
  match @poly.normal_form(polynomial, Cons(modulus(field), Nil)) {
    Err(_) => Err(InternalInvariant)
    Ok(residue) => Ok({ field, residue, })
  }
}

///|
pub fn parent(value : Element) -> Field {
  value.field
}

///|
pub fn representative(value : Element) -> @poly.Polynomial {
  value.residue
}

///|
pub fn equal(a : Element, b : Element) -> Bool {
  same_field(a.field, b.field) && a.residue.equal(b.residue)
}

///|
pub fn is_zero(value : Element) -> Bool {
  @poly.is_zero(value.residue)
}

///|
pub fn rational(field : Field, value : @exact.Rational) -> Element {
  { field, residue: @poly.constant(Succ(Zero), value), }
}

///|
pub fn zero(field : Field) -> Element {
  rational(field, @exact.rational_zero())
}

///|
pub fn one(field : Field) -> Element {
  rational(field, @exact.rational_one())
}

///|
fn power_monomial(exponent : @core.Nat) -> @poly.Polynomial? {
  match
    @poly.polynomial(
      Succ(Zero),
      Cons(
        { coefficient: @exact.rational_one(), exponents: Cons(exponent, Nil), },
        Nil,
      ),
    ) {
    Ok(value) => Some(value)
    Err(_) => None
  }
}

///|
pub fn generator(field : Field) -> Result[Element, FieldError] {
  match power_monomial(Succ(Zero)) {
    Some(value) => element(field, value)
    None => Err(InternalInvariant)
  }
}

///|
pub fn negate(value : Element) -> Element {
  { field: value.field, residue: @poly.negate(value.residue), }
}

///|
/// Add/subtract preserve the degree bound of both opaque canonical residues.
/// Their polynomial operations also retain sorted unique terms and remove zeros.
fn combine_canonical(
  a : Element,
  b : Element,
  operation : (@poly.Polynomial, @poly.Polynomial) -> Result[
    @poly.Polynomial,
    @poly.PolyError,
  ],
) -> Result[Element, FieldError] {
  if !same_field(a.field, b.field) {
    return Err(DifferentField)
  }
  match operation(a.residue, b.residue) {
    Err(_) => Err(InternalInvariant)
    Ok(residue) => Ok({ field: a.field, residue, })
  }
}

///|
pub fn add(a : Element, b : Element) -> Result[Element, FieldError] {
  combine_canonical(a, b, @poly.add)
}

///|
pub fn subtract(a : Element, b : Element) -> Result[Element, FieldError] {
  combine_canonical(a, b, @poly.subtract)
}

///|
pub fn multiply(a : Element, b : Element) -> Result[Element, FieldError] {
  if !same_field(a.field, b.field) {
    return Err(DifferentField)
  }
  match @poly.multiply(a.residue, b.residue) {
    Err(_) => Err(InternalInvariant)
    Ok(product) =>
      match prepared_remainder(product, a.field.reduction, a.field.degree) {
        Err(error) => Err(error)
        Ok(residue) => Ok({ field: a.field, residue, })
      }
  }
}
