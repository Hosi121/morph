///|
/// A canonical presentation of QQ(zeta_N), for a positive power of two N.
/// The defining polynomial is x-1 at N=1, and x^(N/2)+1 otherwise.
#derive(Eq, Debug)
pub struct Field {
  order : @core.Nat
  degree : @core.Nat
  modulus : @polynomial.Polynomial
  root : @polynomial.Polynomial
}

///|
pub extend Field with Eq::{equal, not_equal}

///|
pub extend Field with Debug::{to_repr}

///|
/// The representative has one variable and degree below the field degree.
/// Construction is private so structural equality is equality in this field.
#derive(Eq, Debug)
pub struct Element {
  field : Field
  representative : @polynomial.Polynomial
}

///|
pub extend Element with Eq::{equal, not_equal}

///|
pub extend Element with Debug::{to_repr}

///|
#derive(Eq, Debug)
pub(all) enum CyclotomicError {
  FieldMismatch
  ZeroDivisor
  PolynomialError(@polynomial.PolyError)
  InternalInvariant
}

///|
pub extend CyclotomicError with Eq::{equal, not_equal}

///|
pub extend CyclotomicError with Debug::{to_repr}

///|
fn power_of_two(bits : @core.Chain[Bool]) -> Bool {
  match bits {
    Cons(true, Nil) => true
    Cons(false, rest) => power_of_two(rest)
    _ => false
  }
}

///|
/// Reject zero and all orders that are not powers of two.
/// N=1 and N=2 both present QQ, but remain distinct tagged presentations.
pub fn field(order : @core.Nat) -> Field? {
  let binary_order = @binary.from_nat(order)
  match power_of_two(@binary.bits(binary_order)) {
    false => None
    true => {
      let (degree, constant) : (@core.Nat, @exact.Rational) = match order {
        Succ(Zero) =>
          (Succ(Zero), @exact.rational_negate(@exact.rational_one()))
        _ => (@binary.to_nat(@binary.half(binary_order)), @exact.rational_one())
      }
      match
        @polynomial.polynomial(
          Succ(Zero),
          Cons(
            {
              coefficient: @exact.rational_one(),
              exponents: Cons(degree, Nil),
            },
            Cons({ coefficient: constant, exponents: Cons(Zero, Nil), }, Nil),
          ),
        ) {
        Ok(modulus) =>
          match
            @polynomial.polynomial(
              Succ(Zero),
              Cons(
                {
                  coefficient: @exact.rational_one(),
                  exponents: Cons(Succ(Zero), Nil),
                },
                Nil,
              ),
            ) {
            Err(_) => None
            Ok(variable) =>
              match @polynomial.normal_form(variable, Cons(modulus, Nil)) {
                Err(_) => None
                Ok(root) => Some({ order, degree, modulus, root, })
              }
          }
        Err(_) => None
      }
    }
  }
}

///|
pub fn order(field : Field) -> @core.Nat {
  field.order
}

///|
pub fn degree(field : Field) -> @core.Nat {
  field.degree
}

///|
pub fn defining_polynomial(field : Field) -> @polynomial.Polynomial {
  field.modulus
}

///|
pub fn field_of(value : Element) -> Field {
  value.field
}

///|
pub fn representative(value : Element) -> @polynomial.Polynomial {
  value.representative
}

///|
/// Reduce an arbitrary univariate rational polynomial into the canonical basis.
pub fn element(
  field : Field,
  polynomial : @polynomial.Polynomial,
) -> Result[Element, CyclotomicError] {
  match @polynomial.normal_form(polynomial, Cons(field.modulus, Nil)) {
    Ok(representative) => Ok({ field, representative, })
    Err(error) => Err(PolynomialError(error))
  }
}

///|
pub fn rational(field : Field, value : @exact.Rational) -> Element {
  { field, representative: @polynomial.constant(Succ(Zero), value), }
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
/// The distinguished primitive root. It is 1 at N=1 and -1 at N=2.
pub fn generator(field : Field) -> Element {
  { field, representative: field.root, }
}

///|
pub fn is_zero(value : Element) -> Bool {
  @polynomial.is_zero(value.representative)
}

///|
pub fn negate(value : Element) -> Element {
  {
    field: value.field,
    representative: @polynomial.negate(value.representative),
  }
}

///|
pub fn add(a : Element, b : Element) -> Result[Element, CyclotomicError] {
  match a.field.equal(b.field) {
    false => Err(FieldMismatch)
    true =>
      match @polynomial.add(a.representative, b.representative) {
        Ok(representative) => Ok({ field: a.field, representative, })
        Err(error) => Err(PolynomialError(error))
      }
  }
}

///|
pub fn subtract(a : Element, b : Element) -> Result[Element, CyclotomicError] {
  add(a, negate(b))
}

///|
pub fn multiply(a : Element, b : Element) -> Result[Element, CyclotomicError] {
  match a.field.equal(b.field) {
    false => Err(FieldMismatch)
    true =>
      match @polynomial.multiply(a.representative, b.representative) {
        Ok(product) => element(a.field, product)
        Err(error) => Err(PolynomialError(error))
      }
  }
}

///|
/// Binary exponentiation, including zero^zero=1.
pub fn power(
  value : Element,
  exponent : @binary.Binary,
) -> Result[Element, CyclotomicError] {
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
/// Track only the Bezout coefficient of the original value.
fn inverse_euclid(
  field : Field,
  a : @polynomial.Polynomial,
  b : @polynomial.Polynomial,
  u : @polynomial.Polynomial,
  v : @polynomial.Polynomial,
) -> Result[Element, CyclotomicError] {
  match @polynomial.is_zero(b) {
    true =>
      match @polynomial.terms(a) {
        Cons({ coefficient, exponents: Cons(Zero, Nil), }, Nil) =>
          match @exact.nonzero(coefficient) {
            None => Err(ZeroDivisor)
            Some(nonzero) =>
              match
                @polynomial.scale(u, {
                  coefficient: @exact.reciprocal(nonzero),
                  exponents: Cons(Zero, Nil),
                }) {
                Err(error) => Err(PolynomialError(error))
                Ok(result) => element(field, result)
              }
          }
        _ => Err(ZeroDivisor)
      }
    false =>
      match @polynomial.divide(a, Cons(b, Nil)) {
        Err(error) => Err(PolynomialError(error))
        Ok({ quotients: Cons(q, Nil), remainder, }) =>
          match @polynomial.multiply(q, v) {
            Err(error) => Err(PolynomialError(error))
            Ok(qv) =>
              match @polynomial.subtract(u, qv) {
                Err(error) => Err(PolynomialError(error))
                Ok(next) => inverse_euclid(field, b, remainder, v, next)
              }
          }
        Ok(_) => Err(InternalInvariant)
      }
  }
}

///|
/// Inversion by extended Euclid against the irreducible defining polynomial.
pub fn inverse(value : Element) -> Result[Element, CyclotomicError] {
  match is_zero(value) {
    true => Err(ZeroDivisor)
    false =>
      inverse_euclid(
        value.field,
        value.field.modulus,
        value.representative,
        @polynomial.zero(Succ(Zero)),
        @polynomial.constant(Succ(Zero), @exact.rational_one()),
      )
  }
}

///|
pub fn divide(a : Element, b : Element) -> Result[Element, CyclotomicError] {
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
fn evaluate_terms(
  field : Field,
  terms : @core.Chain[@polynomial.Term],
  value : Element,
) -> Result[Element, CyclotomicError] {
  match terms {
    Nil => Ok(zero(field))
    Cons({ coefficient, exponents: Cons(exponent, Nil), }, rest) =>
      match power(value, @binary.from_nat(exponent)) {
        Err(error) => Err(error)
        Ok(monomial) =>
          match multiply(rational(field, coefficient), monomial) {
            Err(error) => Err(error)
            Ok(term) =>
              match evaluate_terms(field, rest, value) {
                Err(error) => Err(error)
                Ok(tail) => add(term, tail)
              }
          }
      }
    _ => Err(InternalInvariant)
  }
}

///|
/// Complex conjugation substitutes zeta_N^(N-1) for zeta_N, fixing QQ.
pub fn conjugate(value : Element) -> Result[Element, CyclotomicError] {
  match
    power(
      generator(value.field),
      @binary.from_nat(@core.subtract(value.field.order, Succ(Zero))),
    ) {
    Err(error) => Err(error)
    Ok(root_inverse) =>
      evaluate_terms(
        value.field,
        @polynomial.terms(value.representative),
        root_inverse,
      )
  }
}
