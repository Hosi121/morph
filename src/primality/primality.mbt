///|
/// A Lucas/Pratt certificate. The children list the prime factors of p minus one,
/// with multiplicity. The checker never searches for factors or witnesses.
#derive(Eq, Debug)
pub(all) enum Certificate {
  Two
  Lucas(@binary.Binary, @binary.Binary, @core.Chain[Certificate])
}

///|
pub extend Certificate with Eq::{equal, not_equal}

///|
pub extend Certificate with Debug::{to_repr}

///|
/// A prime value accepted by the certificate checker; clients cannot construct it.
#derive(Eq, Debug)
pub struct Prime {
  value : @binary.Binary
}

///|
pub extend Prime with Eq::{equal, not_equal}

///|
pub extend Prime with Debug::{to_repr}

///|
pub fn value(prime : Prime) -> @binary.Binary {
  prime.value
}

///|
/// The number claimed by a certificate, before any checking.
pub fn candidate(certificate : Certificate) -> @binary.Binary {
  match certificate {
    Two => @binary.double(@binary.one())
    Lucas(n, _, _) => n
  }
}

///|
/// Exact Lucas criterion, with recursive prime certificates for the full
/// factorization of n minus one. None means only that this certificate failed.
pub fn check(certificate : Certificate) -> Prime? {
  match certificate {
    Two => Some({ value: @binary.double(@binary.one()), })
    Lucas(n, witness, factors) =>
      match (@modular.modulus(n), @binary.subtract(n, @binary.one())) {
        (Some(modulus), Some(predecessor)) => {
          fn check_factors(
            remaining : @binary.Binary,
            factors : @core.Chain[Certificate],
          ) -> Bool {
            match factors {
              Nil => @binary.compare(remaining, @binary.one()) is Equal
              Cons(child, rest) =>
                match check(child) {
                  None => false
                  Some(prime) =>
                    match
                      (
                        @binary.divmod(remaining, prime.value),
                        @binary.divmod(predecessor, prime.value),
                      ) {
                      (Some((remaining, remainder)), Some((exponent, _))) =>
                        @binary.is_zero(remainder) &&
                        !(@binary.compare(
                          @modular.power(modulus, witness, exponent),
                          @binary.one(),
                        )
                        is Equal) &&
                        check_factors(remaining, rest)
                      _ => false
                    }
                }
            }
          }
          match
            @binary.compare(
              @modular.power(modulus, witness, predecessor),
              @binary.one(),
            ) {
            Equal =>
              match check_factors(predecessor, factors) {
                true => Some({ value: n, })
                false => None
              }
            _ => None
          }
        }
        _ => None
      }
  }
}
