///|
/// The public divide loop without constructing the discarded quotient.
fn remainder_loop(
  remainder : Polynomial,
  divisor : Polynomial,
  divisor_width : @core.Nat,
  inverse_leading : @binary.Binary,
) -> Polynomial {
  match leading(remainder) {
    None => remainder
    Some(coefficient) => {
      let remainder_width = @core.length(remainder.coefficients)
      match @core.compare(remainder_width, divisor_width) {
        Less => remainder
        _ => {
          let exponent = @core.subtract(remainder_width, divisor_width)
          let scalar = match @primefield.is_f2(remainder.field) {
            true => coefficient
            false =>
              multiply_reduced(
                @primefield.modulus(remainder.field),
                coefficient,
                inverse_leading,
              )
          }
          remainder_loop(
            subtract_raw(remainder, shifted(scale(divisor, scalar), exponent)),
            divisor,
            divisor_width,
            inverse_leading,
          )
        }
      }
    }
  }
}

///|
/// Preserve the public constant-divisor inverse check even though its quotient
/// is discarded. The canonical remainder is always zero.
fn remainder_by_constant(
  value : Polynomial,
  coefficient : @binary.Binary,
) -> Result[Polynomial, PolyError] {
  let remainder = zero(value.field)
  match @binary.bits(coefficient) {
    Cons(true, Nil) => Ok(remainder)
    _ =>
      match @modular.inverse(@primefield.modulus(value.field), coefficient) {
        None => Err(InternalInvariant)
        Some(_) => Ok(remainder)
      }
  }
}

///|
/// Same compatibility, zero, constant and leading-inverse order as public divide.
fn remainder_only(
  a : Polynomial,
  b : Polynomial,
) -> Result[Polynomial, PolyError] {
  match compatible(a, b) {
    false => Err(FieldMismatch)
    true =>
      match leading(b) {
        None => Err(ZeroDivisor)
        Some(coefficient) => {
          match is_zero(a) {
            true => return Ok(a)
            false => ()
          }
          match b.coefficients {
            Cons(_, Nil) => return remainder_by_constant(a, coefficient)
            _ => ()
          }
          let divisor_width = @core.length(b.coefficients)
          match @primefield.is_f2(b.field) {
            true =>
              return Ok(remainder_loop(a, b, divisor_width, @binary.one()))
            false => ()
          }
          match @modular.inverse(@primefield.modulus(b.field), coefficient) {
            None => Err(InternalInvariant)
            Some(inverse_leading) =>
              Ok(remainder_loop(a, b, divisor_width, inverse_leading))
          }
        }
      }
  }
}
