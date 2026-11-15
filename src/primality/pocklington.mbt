///|
/// Pocklington with a certified partial factor F of n minus one. We use the
/// conservative threshold F squared greater than n. Each supplied child must
/// pass the existing Lucas checker, and multiplicities count toward F.
pub fn check_pocklington(
  number : @binary.Binary,
  witness : @binary.Binary,
  factors : @core.Chain[Certificate],
) -> Prime? {
  match
    (
      @binary.compare(number, @binary.double(@binary.one())),
      @binary.odd(number),
      @modular.modulus(number),
      @binary.subtract(number, @binary.one()),
    ) {
    (Greater, true, Some(modulus), Some(predecessor)) => {
      fn verify_factors(
        remaining : @binary.Binary,
        factors : @core.Chain[Certificate],
        product : @binary.Binary,
        distinct : @core.Chain[@binary.Binary],
      ) -> (@binary.Binary, @core.Chain[@binary.Binary])? {
        match factors {
          Nil => Some((product, distinct))
          Cons(certificate, rest) =>
            match check(certificate) {
              None => None
              Some(prime) =>
                match @binary.divmod(remaining, prime.value) {
                  Some((next, remainder)) =>
                    match @binary.is_zero(remainder) {
                      false => None
                      true =>
                        verify_factors(
                          next,
                          rest,
                          @binary.multiply(product, prime.value),
                          match
                            @core.any(distinct, fn(q) {
                              @binary.compare(q, prime.value) is Equal
                            }) {
                            true => distinct
                            false => Cons(prime.value, distinct)
                          },
                        )
                    }
                  None => None
                }
            }
        }
      }
      match verify_factors(predecessor, factors, @binary.one(), Nil) {
        None => None
        Some((product, distinct)) => {
          let large_enough = @binary.compare(
              @binary.multiply(product, product),
              number,
            )
            is Greater
          let fermat = @binary.compare(
              @modular.power(modulus, witness, predecessor),
              @binary.one(),
            )
            is Equal
          let orders = large_enough &&
            fermat &&
            @core.all(distinct, fn(q) {
              match @binary.divmod(predecessor, q) {
                Some((exponent, _)) => {
                  let residue = @modular.power(modulus, witness, exponent)
                  let difference = @modular.subtract(
                    modulus,
                    residue,
                    @binary.one(),
                  )
                  @binary.compare(
                    @binary.gcd(difference, number),
                    @binary.one(),
                  )
                  is Equal
                }
                None => false
              }
            })
          match orders {
            true => Some({ value: number, })
            false => None
          }
        }
      }
    }
    _ => None
  }
}
