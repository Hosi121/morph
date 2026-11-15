///|
/// A complete prime factorization, accepted only after checking every prime
/// certificate and the exact product. Multiplicity and supplied order remain.
#derive(Eq, Debug)
pub struct Factorization {
  number : @binary.Binary
  primes : @core.Chain[@primality.Prime]
}

///|
pub extend Factorization with Eq::{equal, not_equal}

///|
pub extend Factorization with Debug::{to_repr}

///|
pub fn factorization_value(factorization : Factorization) -> @binary.Binary {
  factorization.number
}

///|
pub fn prime_factors(
  factorization : Factorization,
) -> @core.Chain[@primality.Prime] {
  factorization.primes
}

///|
/// A search-free complete-factorization checker. One has the empty
/// factorization; zero has none. A nontrivial Split alone is insufficient.
pub fn check_factorization(
  number : @binary.Binary,
  certificates : @core.Chain[@primality.Certificate],
) -> Factorization? {
  fn verify(
    remaining : @binary.Binary,
    certificates : @core.Chain[@primality.Certificate],
  ) -> @core.Chain[@primality.Prime]? {
    match certificates {
      Nil =>
        match @binary.compare(remaining, @binary.one()) {
          Equal => Some(Nil)
          _ => None
        }
      Cons(certificate, rest) =>
        match @primality.check(certificate) {
          None => None
          Some(prime) =>
            match @binary.divmod(remaining, @primality.value(prime)) {
              Some((next, remainder)) =>
                match @binary.is_zero(remainder) {
                  false => None
                  true =>
                    match verify(next, rest) {
                      None => None
                      Some(primes) => Some(Cons(prime, primes))
                    }
                }
              None => None
            }
        }
    }
  }
  match verify(number, certificates) {
    None => None
    Some(primes) => Some({ number, primes, })
  }
}
