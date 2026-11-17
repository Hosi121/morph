///|
/// A modulus greater than one. No assumption of primality is hidden here.
#derive(Eq, Debug)
pub struct Modulus {
  value : @binary.Binary
}

///|
pub extend Modulus with Eq::{equal, not_equal}

///|
pub extend Modulus with Debug::{to_repr}

///|
pub fn modulus(value : @binary.Binary) -> Modulus? {
  match @binary.compare(value, @binary.one()) {
    Greater => Some({ value, })
    _ => None
  }
}

///|
pub fn value(m : Modulus) -> @binary.Binary {
  m.value
}

///|
pub fn reduce(m : Modulus, a : @binary.Binary) -> @binary.Binary {
  match @binary.remainder(a, m.value) {
    Some(remainder) => remainder
    None => @binary.zero()
  }
}

///|
pub fn add(
  m : Modulus,
  a : @binary.Binary,
  b : @binary.Binary,
) -> @binary.Binary {
  reduce(m, @binary.add(a, b))
}

///|
pub fn subtract(
  m : Modulus,
  a : @binary.Binary,
  b : @binary.Binary,
) -> @binary.Binary {
  let x = reduce(m, a)
  let y = reduce(m, b)
  match @binary.subtract(x, y) {
    Some(difference) => difference
    None =>
      match @binary.subtract(@binary.add(x, m.value), y) {
        Some(difference) => difference
        None => @binary.zero()
      }
  }
}

///|
pub fn multiply(
  m : Modulus,
  a : @binary.Binary,
  b : @binary.Binary,
) -> @binary.Binary {
  reduce(m, @binary.multiply(a, b))
}

///|
/// Reduce after every multiplication, so intermediates do not grow with exponent.
pub fn power(
  m : Modulus,
  base : @binary.Binary,
  exponent : @binary.Binary,
) -> @binary.Binary {
  fn go(bits : @core.Chain[Bool]) -> @binary.Binary {
    match bits {
      Nil => @binary.one()
      Cons(bit, rest) => {
        let half = go(rest)
        let square = multiply(m, half, half)
        match bit {
          false => square
          true => multiply(m, base, square)
        }
      }
    }
  }
  go(@binary.bits(exponent))
}

///|
/// Bezout certificate: a*x + b*y = gcd(a,b), including (0,0).
pub fn extended_gcd(
  a : @binary.Binary,
  b : @binary.Binary,
) -> (@binary.Binary, @exact.Integer, @exact.Integer) {
  match @binary.divmod(a, b) {
    None => (a, @exact.positive(@binary.one()), @exact.positive(@binary.zero()))
    Some((quotient, remainder)) => {
      let (g, x, y) = extended_gcd(b, remainder)
      (g, y, @exact.subtract(x, @exact.multiply(@exact.positive(quotient), y)))
    }
  }
}

///|
/// Inverse exists exactly when a and modulus are coprime.
pub fn inverse(m : Modulus, a : @binary.Binary) -> @binary.Binary? {
  let (g, x, _) = extended_gcd(a, m.value)
  match @binary.compare(g, @binary.one()) {
    Equal => Some(signed_reduce(m, x))
    _ => None
  }
}

///|
pub fn signed_reduce(m : Modulus, a : @exact.Integer) -> @binary.Binary {
  let remainder = reduce(m, @exact.magnitude(a))
  match @exact.negative(a) {
    false => remainder
    // The residue above is already below the modulus; negate it directly.
    true =>
      match @binary.is_zero(remainder) {
        true => remainder
        false =>
          match @binary.subtract(m.value, remainder) {
            Some(difference) => difference
            None => @binary.zero()
          }
      }
  }
}

///|
/// Exact trial division, suitable for small symbolic experiments.
pub fn is_prime(n : @binary.Binary) -> Bool {
  fn trial(divisor : @binary.Binary) -> Bool {
    match @binary.compare(@binary.multiply(divisor, divisor), n) {
      Greater => true
      _ =>
        match @binary.divmod(n, divisor) {
          Some((_, remainder)) =>
            match @binary.is_zero(remainder) {
              true => false
              false => trial(@binary.successor(divisor))
            }
          None => false
        }
    }
  }
  match @binary.compare(n, @binary.one()) {
    Greater => trial(@binary.double(@binary.one()))
    _ => false
  }
}

///|
pub fn semiring(m : Modulus) -> @algebra.Semiring[@binary.Binary] {
  {
    zero: @binary.zero(),
    one: @binary.one(),
    plus: fn(a, b) { add(m, a, b) },
    times: fn(a, b) { multiply(m, a, b) },
  }
}
