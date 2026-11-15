///|
/// Ascending coefficients, reduced modulo the checked prime characteristic.
/// Trailing zero coefficients are omitted; Nil is the unique zero.
#derive(Eq, Debug)
pub struct Polynomial {
  field : @primefield.Field
  coefficients : @core.Chain[@binary.Binary]
}

///|
pub extend Polynomial with Eq::{equal, not_equal}

///|
pub extend Polynomial with Debug::{to_repr}

///|
#derive(Eq, Debug)
pub(all) enum PolyError {
  FieldMismatch
  ZeroDivisor
  ZeroPolynomial
  InternalInvariant
}

///|
pub extend PolyError with Eq::{equal, not_equal}

///|
pub extend PolyError with Debug::{to_repr}

///|
#derive(Eq, Debug)
pub(all) struct Division {
  quotient : Polynomial
  remainder : Polynomial
}

///|
pub extend Division with Eq::{equal, not_equal}

///|
pub extend Division with Debug::{to_repr}

///|
/// gcd = left*a + right*b, with a monic nonzero gcd.
#derive(Eq, Debug)
pub(all) struct Bezout {
  gcd : Polynomial
  left : Polynomial
  right : Polynomial
}

///|
pub extend Bezout with Eq::{equal, not_equal}

///|
pub extend Bezout with Debug::{to_repr}

///|
fn trim(
  modulus : @modular.Modulus,
  coefficients : @core.Chain[@binary.Binary],
) -> @core.Chain[@binary.Binary] {
  match coefficients {
    Nil => Nil
    Cons(head, tail) => {
      let head = @modular.reduce(modulus, head)
      let tail = trim(modulus, tail)
      match (tail, @binary.is_zero(head)) {
        (Nil, true) => Nil
        _ => Cons(head, tail)
      }
    }
  }
}

///|
/// Private arithmetic already returns reduced coefficients. Only high zeros
/// need removing; sending these values through public construction repeats all
/// modular divisions without strengthening the invariant.
fn trim_reduced(
  coefficients : @core.Chain[@binary.Binary],
) -> @core.Chain[@binary.Binary] {
  match coefficients {
    Nil => Nil
    Cons(head, rest) => {
      let tail = trim_reduced(rest)
      match (tail, @binary.is_zero(head)) {
        (Nil, true) => Nil
        _ => Cons(head, tail)
      }
    }
  }
}

///|
pub fn polynomial(
  field : @primefield.Field,
  coefficients : @core.Chain[@binary.Binary],
) -> Polynomial {
  {
    field,
    coefficients: match characteristic_two(field) {
      true => char_two_trim(coefficients, @binary.zero(), @binary.one())
      false => trim(@primefield.modulus(field), coefficients)
    },
  }
}

///|
pub fn field_of(value : Polynomial) -> @primefield.Field {
  value.field
}

///|
pub fn characteristic(value : Polynomial) -> @binary.Binary {
  @modular.value(@primefield.modulus(value.field))
}

///|
pub fn coefficients(value : Polynomial) -> @core.Chain[@binary.Binary] {
  value.coefficients
}

///|
pub fn is_zero(value : Polynomial) -> Bool {
  match value.coefficients {
    Nil => true
    _ => false
  }
}

///|
pub fn degree(value : Polynomial) -> @core.Nat? {
  match @core.length(value.coefficients) {
    Zero => None
    Succ(degree) => Some(degree)
  }
}

///|
pub fn leading(value : Polynomial) -> @binary.Binary? {
  @core.last(value.coefficients)
}

///|
pub fn zero(field : @primefield.Field) -> Polynomial {
  { field, coefficients: Nil, }
}

///|
pub fn constant(
  field : @primefield.Field,
  coefficient : @binary.Binary,
) -> Polynomial {
  polynomial(field, Cons(coefficient, Nil))
}

///|
pub fn one(field : @primefield.Field) -> Polynomial {
  constant(field, @binary.one())
}

///|
pub fn indeterminate(field : @primefield.Field) -> Polynomial {
  polynomial(field, Cons(@binary.zero(), Cons(@binary.one(), Nil)))
}

///|
fn compatible(a : Polynomial, b : Polynomial) -> Bool {
  characteristic(a).equal(characteristic(b))
}

///|
fn add_coefficients(
  modulus : @modular.Modulus,
  a : @core.Chain[@binary.Binary],
  b : @core.Chain[@binary.Binary],
) -> @core.Chain[@binary.Binary] {
  match (a, b) {
    (Nil, _) => b
    (_, Nil) => a
    (Cons(x, xs), Cons(y, ys)) =>
      Cons(@modular.add(modulus, x, y), add_coefficients(modulus, xs, ys))
  }
}

///|
fn add_raw(a : Polynomial, b : Polynomial) -> Polynomial {
  match characteristic_two(a.field) {
    true =>
      return {
        field: a.field,
        coefficients: char_two_add(
          a.coefficients,
          b.coefficients,
          @binary.zero(),
        ),
      }
    false => ()
  }
  {
    field: a.field,
    coefficients: trim_reduced(
      add_coefficients(
        @primefield.modulus(a.field),
        a.coefficients,
        b.coefficients,
      ),
    ),
  }
}

///|
pub fn add(a : Polynomial, b : Polynomial) -> Result[Polynomial, PolyError] {
  match compatible(a, b) {
    false => Err(FieldMismatch)
    true => Ok(add_raw(a, b))
  }
}

///|
pub fn negate(value : Polynomial) -> Polynomial {
  match characteristic_two(value.field) {
    true => return value
    false => ()
  }
  let modulus = @primefield.modulus(value.field)
  {
    field: value.field,
    coefficients: @core.map(value.coefficients, fn(coefficient) {
      @modular.subtract(modulus, @binary.zero(), coefficient)
    }),
  }
}

///|
fn subtract_raw(a : Polynomial, b : Polynomial) -> Polynomial {
  add_raw(a, negate(b))
}

///|
pub fn subtract(
  a : Polynomial,
  b : Polynomial,
) -> Result[Polynomial, PolyError] {
  match compatible(a, b) {
    false => Err(FieldMismatch)
    true => Ok(subtract_raw(a, b))
  }
}

///|
pub fn scale(value : Polynomial, scalar : @binary.Binary) -> Polynomial {
  match characteristic_two(value.field) {
    true =>
      return match @binary.odd(scalar) {
        true => value
        false => zero(value.field)
      }
    false => ()
  }
  let modulus = @primefield.modulus(value.field)
  {
    field: value.field,
    coefficients: trim_reduced(
      @core.map(value.coefficients, fn(coefficient) {
        @modular.multiply(modulus, coefficient, scalar)
      }),
    ),
  }
}

///|
fn multiply_coefficients(
  modulus : @modular.Modulus,
  a : @core.Chain[@binary.Binary],
  b : @core.Chain[@binary.Binary],
) -> @core.Chain[@binary.Binary] {
  match a {
    Nil => Nil
    Cons(head, tail) =>
      add_coefficients(
        modulus,
        @core.map(b, fn(coefficient) {
          @modular.multiply(modulus, head, coefficient)
        }),
        Cons(@binary.zero(), multiply_coefficients(modulus, tail, b)),
      )
  }
}

///|
fn multiply_raw(a : Polynomial, b : Polynomial) -> Polynomial {
  match characteristic_two(a.field) {
    true =>
      return {
        field: a.field,
        coefficients: char_two_multiply(
          a.coefficients,
          b.coefficients,
          @binary.zero(),
        ),
      }
    false => ()
  }
  {
    field: a.field,
    coefficients: trim_reduced(
      multiply_coefficients(
        @primefield.modulus(a.field),
        a.coefficients,
        b.coefficients,
      ),
    ),
  }
}

///|
pub fn multiply(
  a : Polynomial,
  b : Polynomial,
) -> Result[Polynomial, PolyError] {
  match compatible(a, b) {
    false => Err(FieldMismatch)
    true => Ok(multiply_raw(a, b))
  }
}

///|
fn prepend_zeros(
  coefficients : @core.Chain[@binary.Binary],
  exponent : @core.Nat,
  zero : @binary.Binary,
) -> @core.Chain[@binary.Binary] {
  match exponent {
    Zero => coefficients
    Succ(rest) => Cons(zero, prepend_zeros(coefficients, rest, zero))
  }
}

///|
fn shifted(value : Polynomial, exponent : @core.Nat) -> Polynomial {
  match is_zero(value) {
    true => value
    false =>
      {
        field: value.field,
        coefficients: prepend_zeros(
          value.coefficients,
          exponent,
          @binary.zero(),
        ),
      }
  }
}

///|
fn divide_loop(
  remainder : Polynomial,
  divisor : Polynomial,
  inverse_leading : @binary.Binary,
  quotient : Polynomial,
) -> Division {
  match leading(remainder) {
    None => { quotient, remainder, }
    Some(coefficient) =>
      match
        @core.compare(
          @core.length(remainder.coefficients),
          @core.length(divisor.coefficients),
        ) {
        Less => { quotient, remainder, }
        _ => {
          let exponent = @core.subtract(
            @core.length(remainder.coefficients),
            @core.length(divisor.coefficients),
          )
          let scalar = match characteristic_two(remainder.field) {
            true => coefficient
            false =>
              @modular.multiply(
                @primefield.modulus(remainder.field),
                coefficient,
                inverse_leading,
              )
          }
          let term = shifted(constant(remainder.field, scalar), exponent)
          divide_loop(
            subtract_raw(remainder, shifted(scale(divisor, scalar), exponent)),
            divisor,
            inverse_leading,
            add_raw(quotient, term),
          )
        }
      }
  }
}

///|
/// Euclidean quotient and remainder; degree(remainder) is below degree(divisor).
pub fn divide(a : Polynomial, b : Polynomial) -> Result[Division, PolyError] {
  match compatible(a, b) {
    false => Err(FieldMismatch)
    true =>
      match leading(b) {
        None => Err(ZeroDivisor)
        Some(coefficient) => {
          match characteristic_two(b.field) {
            true => return Ok(divide_loop(a, b, @binary.one(), zero(a.field)))
            false => ()
          }
          match @modular.inverse(@primefield.modulus(b.field), coefficient) {
            None => Err(InternalInvariant)
            Some(inverse_leading) =>
              Ok(divide_loop(a, b, inverse_leading, zero(a.field)))
          }
        }
      }
  }
}

///|
pub fn monic(value : Polynomial) -> Result[Polynomial, PolyError] {
  match characteristic_two(value.field) {
    true => return Ok(value)
    false => ()
  }
  match leading(value) {
    None => Ok(value)
    Some(coefficient) =>
      match @modular.inverse(@primefield.modulus(value.field), coefficient) {
        None => Err(InternalInvariant)
        Some(inverse_leading) => Ok(scale(value, inverse_leading))
      }
  }
}

///|
pub fn gcd(a : Polynomial, b : Polynomial) -> Result[Polynomial, PolyError] {
  match compatible(a, b) {
    false => Err(FieldMismatch)
    true =>
      match is_zero(b) {
        true => monic(a)
        false =>
          match divide(a, b) {
            Err(error) => Err(error)
            Ok(division) => gcd(b, division.remainder)
          }
      }
  }
}

///|
fn euclid(
  a : Polynomial,
  b : Polynomial,
  u : Polynomial,
  v : Polynomial,
  s : Polynomial,
  t : Polynomial,
) -> Result[Bezout, PolyError] {
  match is_zero(b) {
    true =>
      match leading(a) {
        None => Ok({ gcd: a, left: zero(a.field), right: zero(a.field), })
        Some(coefficient) => {
          match characteristic_two(a.field) {
            true => return Ok({ gcd: a, left: u, right: s, })
            false => ()
          }
          match @modular.inverse(@primefield.modulus(a.field), coefficient) {
            None => Err(InternalInvariant)
            Some(inverse_leading) =>
              Ok({
                gcd: scale(a, inverse_leading),
                left: scale(u, inverse_leading),
                right: scale(s, inverse_leading),
              })
          }
        }
      }
    false =>
      match divide(a, b) {
        Err(error) => Err(error)
        Ok({ quotient, remainder, }) =>
          euclid(
            b,
            remainder,
            v,
            subtract_raw(u, multiply_raw(quotient, v)),
            t,
            subtract_raw(s, multiply_raw(quotient, t)),
          )
      }
  }
}

///|
pub fn extended_gcd(
  a : Polynomial,
  b : Polynomial,
) -> Result[Bezout, PolyError] {
  match compatible(a, b) {
    false => Err(FieldMismatch)
    true =>
      euclid(a, b, one(a.field), zero(a.field), zero(a.field), one(a.field))
  }
}

///|
fn derivative_coefficients(
  modulus : @modular.Modulus,
  coefficients : @core.Chain[@binary.Binary],
  exponent : @binary.Binary,
) -> @core.Chain[@binary.Binary] {
  match coefficients {
    Nil => Nil
    Cons(coefficient, rest) =>
      Cons(
        @modular.multiply(modulus, coefficient, exponent),
        derivative_coefficients(modulus, rest, @binary.successor(exponent)),
      )
  }
}

///|
/// Formal derivative, including the zero derivative of p-th powers in char p.
pub fn derivative(value : Polynomial) -> Polynomial {
  match value.coefficients {
    Nil => value
    Cons(_, rest) =>
      {
        field: value.field,
        coefficients: trim_reduced(
          derivative_coefficients(
            @primefield.modulus(value.field),
            rest,
            @binary.one(),
          ),
        ),
      }
  }
}

///|
pub fn evaluate(value : Polynomial, point : @binary.Binary) -> @binary.Binary {
  fn horner(coefficients : @core.Chain[@binary.Binary]) -> @binary.Binary {
    match coefficients {
      Nil => @binary.zero()
      Cons(coefficient, rest) =>
        @modular.add(
          @primefield.modulus(value.field),
          coefficient,
          @modular.multiply(
            @primefield.modulus(value.field),
            point,
            horner(rest),
          ),
        )
    }
  }
  horner(value.coefficients)
}

///|
fn product_remainder(
  a : Polynomial,
  b : Polynomial,
  modulus : Polynomial,
) -> Result[Polynomial, PolyError] {
  match divide(multiply_raw(a, b), modulus) {
    Err(error) => Err(error)
    Ok(division) => Ok(division.remainder)
  }
}

///|
fn power_loop(
  base : Polynomial,
  exponent : @binary.Binary,
  modulus : Polynomial,
  accumulator : Polynomial,
) -> Result[Polynomial, PolyError] {
  match @binary.is_zero(exponent) {
    true => Ok(accumulator)
    false => {
      let next = match @binary.odd(exponent) {
        false => Ok(accumulator)
        true => product_remainder(accumulator, base, modulus)
      }
      match (next, product_remainder(base, base, modulus)) {
        (Ok(accumulator), Ok(square)) =>
          power_loop(square, @binary.half(exponent), modulus, accumulator)
        (Err(error), _) | (_, Err(error)) => Err(error)
      }
    }
  }
}

///|
/// Modular exponentiation; even exponent zero rejects a zero polynomial modulus.
pub fn power_mod(
  base : Polynomial,
  exponent : @binary.Binary,
  modulus : Polynomial,
) -> Result[Polynomial, PolyError] {
  match compatible(base, modulus) {
    false => Err(FieldMismatch)
    true =>
      match (divide(base, modulus), divide(one(base.field), modulus)) {
        (Ok(base), Ok(unit)) =>
          power_loop(base.remainder, exponent, modulus, unit.remainder)
        (Err(error), _) | (_, Err(error)) => Err(error)
      }
  }
}
