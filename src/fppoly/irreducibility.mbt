///|
/// Frobenius powers x^(p^i) mod f for i=1,...,degree(f), together with
/// Bezout witnesses for gcd(f, x^(p^i)-x)=1 up to floor(degree(f)/2).
#derive(Eq, Debug)
pub(all) struct IrreducibilityCertificate {
  frobenius : @core.Chain[Polynomial]
  coprime : @core.Chain[Bezout]
}

///|
pub extend IrreducibilityCertificate with Eq::{equal, not_equal}

///|
pub extend IrreducibilityCertificate with Debug::{to_repr}

///|
/// Check the Bezout identity directly, without running polynomial Euclid.
pub fn check_bezout(a : Polynomial, b : Polynomial, witness : Bezout) -> Bool {
  match (multiply(a, witness.left), multiply(b, witness.right)) {
    (Ok(left), Ok(right)) =>
      match add(left, right) {
        Err(_) => false
        Ok(result) => result.equal(witness.gcd)
      }
    _ => false
  }
}

///|
fn frobenius_chain(
  modulus : Polynomial,
  current : Polynomial,
  remaining : @core.Nat,
) -> Result[@core.Chain[Polynomial], PolyError] {
  match remaining {
    Zero => Ok(Nil)
    Succ(rest) =>
      match power_mod(current, characteristic(modulus), modulus) {
        Err(error) => Err(error)
        Ok(next) =>
          match frobenius_chain(modulus, next, rest) {
            Err(error) => Err(error)
            Ok(tail) => Ok(Cons(next, tail))
          }
      }
  }
}

///|
fn coprime_witnesses(
  modulus : Polynomial,
  x : Polynomial,
  powers : @core.Chain[Polynomial],
) -> Result[@core.Chain[Bezout]?, PolyError] {
  match powers {
    Nil => Ok(Some(Nil))
    Cons(power, rest) =>
      match extended_gcd(modulus, subtract_raw(power, x)) {
        Err(error) => Err(error)
        Ok(witness) =>
          match witness.gcd.equal(one(modulus.field)) {
            false => Ok(None)
            true =>
              match coprime_witnesses(modulus, x, rest) {
                Err(error) => Err(error)
                Ok(None) => Ok(None)
                Ok(Some(tail)) => Ok(Some(Cons(witness, tail)))
              }
          }
      }
  }
}

///|
/// Return a certificate precisely for monic irreducible positive-degree inputs.
/// The half-degree test uses every i, avoiding any factorization oracle for n.
pub fn irreducibility(
  value : Polynomial,
) -> Result[IrreducibilityCertificate?, PolyError] {
  match (degree(value), leading(value)) {
    (Some(Succ(_) as n), Some(coefficient)) =>
      match coefficient.equal(@binary.one()) {
        false => Ok(None)
        true =>
          match divide(indeterminate(value.field), value) {
            Err(error) => Err(error)
            Ok({ remainder: x, .. }) =>
              match frobenius_chain(value, x, n) {
                Err(error) => Err(error)
                Ok(powers) =>
                  match @core.last(powers) {
                    Some(last) =>
                      match last.equal(x) {
                        false => Ok(None)
                        true => {
                          let half = @core.half_nat(n)
                          match
                            coprime_witnesses(
                              value,
                              x,
                              @core.take(half, powers),
                            ) {
                            Err(error) => Err(error)
                            Ok(None) => Ok(None)
                            Ok(Some(coprime)) =>
                              Ok(Some({ frobenius: powers, coprime, }))
                          }
                        }
                      }
                    None => Err(InternalInvariant)
                  }
              }
          }
      }
    _ => Ok(None)
  }
}

///|
/// Validate the entire supplied orbit and Bezout identities, with exact shapes.
/// This does not trust the certificate producer or run the factorization solver.
pub fn check_irreducible(
  value : Polynomial,
  certificate : IrreducibilityCertificate,
) -> Bool {
  fn check_powers(
    current : Polynomial,
    todo : @core.Chain[Polynomial],
    remaining : @core.Nat,
    x : Polynomial,
  ) -> Bool {
    match (todo, remaining) {
      (Nil, Zero) => current.equal(x)
      (Cons(next, rest), Succ(remaining)) =>
        match power_mod(current, characteristic(value), value) {
          Err(_) => false
          Ok(expected) =>
            expected.equal(next) && check_powers(next, rest, remaining, x)
        }
      _ => false
    }
  }
  fn check_witnesses(
    powers : @core.Chain[Polynomial],
    witnesses : @core.Chain[Bezout],
    x : Polynomial,
  ) -> Bool {
    match (powers, witnesses) {
      (Nil, Nil) => true
      (Cons(power, rest), Cons(witness, tail)) =>
        witness.gcd.equal(one(value.field)) &&
        check_bezout(value, subtract_raw(power, x), witness) &&
        check_witnesses(rest, tail, x)
      _ => false
    }
  }
  match (degree(value), leading(value)) {
    (Some(Succ(_) as n), Some(coefficient)) =>
      match coefficient.equal(@binary.one()) {
        false => false
        true =>
          match divide(indeterminate(value.field), value) {
            Err(_) => false
            Ok({ remainder: x, .. }) => {
              let half = @core.half_nat(n)
              check_powers(x, certificate.frobenius, n, x) &&
              check_witnesses(
                @core.take(half, certificate.frobenius),
                certificate.coprime,
                x,
              )
            }
          }
      }
    _ => false
  }
}
