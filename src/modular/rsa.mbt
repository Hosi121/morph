///|
/// Textbook RSA arithmetic for small symbolic experiments, without padding.
#derive(Eq, Debug)
pub struct RsaKey {
  modulus : Modulus
  public_exponent : @binary.Binary
  private_exponent : @binary.Binary
}

///|
pub extend RsaKey with Eq::{equal, not_equal}

///|
pub extend RsaKey with Debug::{to_repr}

///|
/// Check distinct primes and require one < e < phi with a modular inverse.
pub fn rsa_key(
  p : @binary.Binary,
  q : @binary.Binary,
  e : @binary.Binary,
) -> RsaKey? {
  match (is_prime(p), is_prime(q), @binary.compare(p, q)) {
    (true, true, Equal) => None
    (true, true, _) =>
      match
        (@binary.subtract(p, @binary.one()), @binary.subtract(q, @binary.one())) {
        (Some(pm), Some(qm)) => {
          let phi = @binary.multiply(pm, qm)
          match
            (
              @binary.compare(e, @binary.one()),
              @binary.compare(e, phi),
              modulus(phi),
              modulus(@binary.multiply(p, q)),
            ) {
            (Greater, Less, Some(totient), Some(modulus)) =>
              match inverse(totient, e) {
                None => None
                Some(private_exponent) =>
                  Some({ modulus, public_exponent: e, private_exponent, })
              }
            _ => None
          }
        }
        _ => None
      }
    _ => None
  }
}

///|
pub fn rsa_public(key : RsaKey) -> (Modulus, @binary.Binary) {
  (key.modulus, key.public_exponent)
}

///|
/// Message representatives must be strictly less than the modulus.
pub fn rsa_encrypt(key : RsaKey, message : @binary.Binary) -> @binary.Binary? {
  match @binary.compare(message, key.modulus.value) {
    Less => Some(power(key.modulus, message, key.public_exponent))
    _ => None
  }
}

///|
pub fn rsa_decrypt(
  key : RsaKey,
  ciphertext : @binary.Binary,
) -> @binary.Binary? {
  match @binary.compare(ciphertext, key.modulus.value) {
    Less => Some(power(key.modulus, ciphertext, key.private_exponent))
    _ => None
  }
}
