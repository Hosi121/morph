///|
/// A general prime field, including characteristic two. Constructors either
/// perform exact trial division or require an already checked Prime.
#derive(Eq, Debug)
pub struct Field {
  modulus : @modular.Modulus
}

///|
pub extend Field with Eq::{equal, not_equal}

///|
pub extend Field with Debug::{to_repr}

///|
pub fn field(number : @binary.Binary) -> Field? {
  match @modular.is_prime(number) {
    false => None
    true =>
      match @modular.modulus(number) {
        None => None
        Some(modulus) => Some({ modulus, })
      }
  }
}

///|
/// The Prime type carries the checked boundary. Do not repeat trial division.
pub fn from_prime(prime : @primality.Prime) -> Field? {
  match @modular.modulus(@primality.value(prime)) {
    None => None
    Some(modulus) => Some({ modulus, })
  }
}

///|
pub fn modulus(field : Field) -> @modular.Modulus {
  field.modulus
}

///|
fn parity_residue(a : @binary.Binary) -> @binary.Binary {
  match @binary.odd(a) {
    false => @binary.zero()
    true => @binary.one()
  }
}

///|
fn add_two(a : @binary.Binary, b : @binary.Binary) -> @binary.Binary {
  match (@binary.odd(a), @binary.odd(b)) {
    (false, false) | (true, true) => @binary.zero()
    _ => @binary.one()
  }
}

///|
fn multiply_two(a : @binary.Binary, b : @binary.Binary) -> @binary.Binary {
  match @binary.odd(a) && @binary.odd(b) {
    false => @binary.zero()
    true => @binary.one()
  }
}

///|
fn inverse_two(a : @binary.Binary) -> @binary.Binary? {
  match @binary.odd(a) {
    false => None
    true => Some(@binary.one())
  }
}

///|
/// Parity is reduction modulo two even for unreduced inputs. Each operation
/// therefore returns the same canonical residue without constructing arithmetic
/// intermediates or an extended-GCD certificate that the dictionary discards.
fn arithmetic_two() -> @rowreduce.Field[@binary.Binary] {
  {
    zero: @binary.zero(),
    one: @binary.one(),
    add: add_two,
    subtract: add_two,
    negate: parity_residue,
    multiply: multiply_two,
    inverse: inverse_two,
  }
}

///|
/// Every operation returns a canonical residue. Inverse returns None exactly
/// for values whose residue is zero, including unreduced multiples of p.
pub fn arithmetic(field : Field) -> @rowreduce.Field[@binary.Binary] {
  let modulus = field.modulus
  match @binary.bits(@modular.value(modulus)) {
    Cons(false, Cons(true, Nil)) => return arithmetic_two()
    _ => ()
  }
  {
    zero: @binary.zero(),
    one: @binary.one(),
    add: fn(a, b) { @modular.add(modulus, a, b) },
    subtract: fn(a, b) { @modular.subtract(modulus, a, b) },
    negate: fn(a) { @modular.subtract(modulus, @binary.zero(), a) },
    multiply: fn(a, b) { @modular.multiply(modulus, a, b) },
    inverse: fn(a) { @modular.inverse(modulus, a) },
  }
}
