///|
/// A presentation GF(p)[x]/(f), checked with an irreducibility certificate.
/// The certificate is not part of the identity of the resulting field.
#derive(Eq, Debug)
pub struct Field {
  modulus : @fppoly.Polynomial
  degree : @core.Nat
}

///|
pub extend Field with Eq::{equal, not_equal}

///|
pub extend Field with Debug::{to_repr}

///|
#derive(Eq, Debug)
pub struct Element {
  field : Field
  representative : @fppoly.Polynomial
}

///|
pub extend Element with Eq::{equal, not_equal}

///|
pub extend Element with Debug::{to_repr}

///|
#derive(Eq, Debug)
pub(all) enum FieldError {
  FieldMismatch
  ZeroDivisor
  PolynomialError(@fppoly.PolyError)
  InternalInvariant
}

///|
pub extend FieldError with Eq::{equal, not_equal}

///|
pub extend FieldError with Debug::{to_repr}

///|
/// Accept only a monic positive-degree modulus with a valid certificate.
pub fn extension(
  modulus : @fppoly.Polynomial,
  certificate : @fppoly.IrreducibilityCertificate,
) -> Field? {
  match @fppoly.check_irreducible(modulus, certificate) {
    false => None
    true =>
      match @fppoly.degree(modulus) {
        Some(Succ(_) as degree) => Some({ modulus, degree, })
        _ => None
      }
  }
}

///|
pub fn modulus(field : Field) -> @fppoly.Polynomial {
  field.modulus
}

///|
pub fn prime_field(field : Field) -> @primefield.Field {
  @fppoly.field_of(field.modulus)
}

///|
pub fn degree(field : Field) -> @core.Nat {
  field.degree
}

///|
pub fn characteristic(field : Field) -> @binary.Binary {
  @fppoly.characteristic(field.modulus)
}

///|
pub fn cardinality(field : Field) -> @binary.Binary {
  @binary.power(characteristic(field), @binary.from_nat(field.degree))
}

///|
pub fn field_of(value : Element) -> Field {
  value.field
}

///|
pub fn representative(value : Element) -> @fppoly.Polynomial {
  value.representative
}

///|
pub fn element(
  field : Field,
  polynomial : @fppoly.Polynomial,
) -> Result[Element, FieldError] {
  match @fppoly.divide(polynomial, field.modulus) {
    Err(error) => Err(PolynomialError(error))
    Ok({ remainder, .. }) => Ok({ field, representative: remainder, })
  }
}

///|
pub fn constant(field : Field, coefficient : @binary.Binary) -> Element {
  { field, representative: @fppoly.constant(prime_field(field), coefficient), }
}

///|
pub fn zero(field : Field) -> Element {
  constant(field, @binary.zero())
}

///|
pub fn one(field : Field) -> Element {
  constant(field, @binary.one())
}

///|
/// The algebra generator x mod f. It need not generate the multiplicative group.
pub fn generator(field : Field) -> Result[Element, FieldError] {
  element(field, @fppoly.indeterminate(prime_field(field)))
}

///|
pub fn is_zero(value : Element) -> Bool {
  @fppoly.is_zero(value.representative)
}

///|
pub fn negate(value : Element) -> Element {
  { field: value.field, representative: @fppoly.negate(value.representative), }
}

///|
pub fn add(a : Element, b : Element) -> Result[Element, FieldError] {
  match a.field.equal(b.field) {
    false => Err(FieldMismatch)
    true =>
      match @fppoly.add(a.representative, b.representative) {
        Err(error) => Err(PolynomialError(error))
        Ok(representative) => Ok({ field: a.field, representative, })
      }
  }
}

///|
pub fn subtract(a : Element, b : Element) -> Result[Element, FieldError] {
  add(a, negate(b))
}

///|
pub fn multiply(a : Element, b : Element) -> Result[Element, FieldError] {
  match a.field.equal(b.field) {
    false => Err(FieldMismatch)
    true => {
      match is_binary_field(a.field) {
        true => return Ok(binary_field_product(a, b))
        false => ()
      }
      match @fppoly.multiply(a.representative, b.representative) {
        Err(error) => Err(PolynomialError(error))
        Ok(product) => element(a.field, product)
      }
    }
  }
}

///|
/// The Bezout coefficient of a nonzero representative is its inverse modulo f.
pub fn inverse(value : Element) -> Result[Element, FieldError] {
  match is_zero(value) {
    true => Err(ZeroDivisor)
    false =>
      match @fppoly.extended_gcd(value.representative, value.field.modulus) {
        Err(error) => Err(PolynomialError(error))
        Ok(witness) =>
          match witness.gcd.equal(@fppoly.one(prime_field(value.field))) {
            false => Err(InternalInvariant)
            true => element(value.field, witness.left)
          }
      }
  }
}

///|
pub fn divide(a : Element, b : Element) -> Result[Element, FieldError] {
  match a.field.equal(b.field) {
    false => Err(FieldMismatch)
    true =>
      match inverse(b) {
        Err(error) => Err(error)
        Ok(reciprocal) => multiply(a, reciprocal)
      }
  }
}

///|
/// Nonnegative binary exponentiation, with zero^zero=one.
pub fn power(
  value : Element,
  exponent : @binary.Binary,
) -> Result[Element, FieldError] {
  match @binary.is_zero(exponent) {
    true => Ok(one(value.field))
    false =>
      match power(value, @binary.half(exponent)) {
        Err(error) => Err(error)
        Ok(half) =>
          match multiply(half, half) {
            Err(error) => Err(error)
            Ok(square) =>
              match @binary.odd(exponent) {
                false => Ok(square)
                true => multiply(square, value)
              }
          }
      }
  }
}

///|
pub fn frobenius(value : Element) -> Result[Element, FieldError] {
  power(value, characteristic(value.field))
}

///|
fn base_coefficient(value : Element) -> Result[@binary.Binary, FieldError] {
  match @fppoly.coefficients(value.representative) {
    Nil => Ok(@binary.zero())
    Cons(coefficient, Nil) => Ok(coefficient)
    _ => Err(InternalInvariant)
  }
}

///|
fn trace_loop(
  value : Element,
  remaining : @core.Nat,
  accumulator : Element,
) -> Result[@binary.Binary, FieldError] {
  match remaining {
    Zero => base_coefficient(accumulator)
    Succ(rest) =>
      match (add(accumulator, value), frobenius(value)) {
        (Ok(next), Ok(conjugate)) => trace_loop(conjugate, rest, next)
        (Err(error), _) | (_, Err(error)) => Err(error)
      }
  }
}

///|
/// Sum of the degree-many Frobenius conjugates, returned in the prime field.
pub fn trace(value : Element) -> Result[@binary.Binary, FieldError] {
  trace_loop(value, value.field.degree, zero(value.field))
}

///|
fn norm_loop(
  value : Element,
  remaining : @core.Nat,
  accumulator : Element,
) -> Result[@binary.Binary, FieldError] {
  match remaining {
    Zero => base_coefficient(accumulator)
    Succ(rest) =>
      match (multiply(accumulator, value), frobenius(value)) {
        (Ok(next), Ok(conjugate)) => norm_loop(conjugate, rest, next)
        (Err(error), _) | (_, Err(error)) => Err(error)
      }
  }
}

///|
/// Product of the Frobenius conjugates, returned in the prime field.
pub fn norm(value : Element) -> Result[@binary.Binary, FieldError] {
  norm_loop(value, value.field.degree, one(value.field))
}
