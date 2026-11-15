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
/// Every operation returns a canonical residue. Inverse returns None exactly
/// for values whose residue is zero, including unreduced multiples of p.
pub fn arithmetic(field : Field) -> @rowreduce.Field[@binary.Binary] {
  let modulus = field.modulus
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
