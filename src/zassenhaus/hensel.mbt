///|
/// Public, untrusted lifting data. A certificate is accepted only by check_lift.
/// factors are monic, positive-degree, pairwise coprime modulo prime; lifts are
/// their monic representatives modulo prime^exponent.
#derive(Eq, Debug)
pub(all) struct LiftCertificate {
  target : Polynomial
  prime : @binary.Binary
  exponent : @core.Nat
  factors : @core.Chain[@fppoly.Polynomial]
  lifts : @core.Chain[Polynomial]
}

///|
pub extend LiftCertificate with Eq::{equal, not_equal}

///|
pub extend LiftCertificate with Debug::{to_repr}

///|
#derive(Eq, Debug)
pub struct Lift {
  certificate : LiftCertificate
  modulus : @modular.Modulus
  inverses : @core.Chain[@fppoly.Polynomial]
}

///|
pub extend Lift with Eq::{equal, not_equal}

///|
pub extend Lift with Debug::{to_repr}

///|
pub fn lift_certificate(value : Lift) -> LiftCertificate {
  value.certificate
}

///|
pub fn lift_modulus(value : Lift) -> @binary.Binary {
  @modular.value(value.modulus)
}

///|
fn prime_power(prime : @binary.Binary, exponent : @core.Nat) -> @binary.Binary {
  match exponent {
    Zero => @binary.one()
    Succ(rest) => @binary.multiply(prime, prime_power(prime, rest))
  }
}

///|
fn fp_product(
  field : @primefield.Field,
  values : @core.Chain[@fppoly.Polynomial],
) -> @fppoly.Polynomial? {
  match values {
    Nil => Some(@fppoly.one(field))
    Cons(head, rest) =>
      match fp_product(field, rest) {
        Some(tail) =>
          match @fppoly.multiply(head, tail) {
            Ok(p) => Some(p)
            Err(_) => None
          }
        None => None
      }
  }
}

///|
fn monic_positive(value : Polynomial) -> Bool {
  match (degree(value), leading(value)) {
    (Some(Succ(_)), Some(c)) => c.equal(ione())
    _ => false
  }
}

///|
fn fp_monic_positive(value : @fppoly.Polynomial) -> Bool {
  match (@fppoly.degree(value), @fppoly.leading(value)) {
    (Some(Succ(_)), Some(c)) => c.equal(@binary.one())
    _ => false
  }
}

///|
/// The inverse of lc(target) times each complementary product, modulo its factor.
fn correction_inverses(
  target : Polynomial,
  field : @primefield.Field,
  factors : @core.Chain[@fppoly.Polynomial],
) -> @core.Chain[@fppoly.Polynomial]? {
  fn walk(
    prefix : @core.Chain[@fppoly.Polynomial],
    rest : @core.Chain[@fppoly.Polynomial],
  ) -> @core.Chain[@fppoly.Polynomial]? {
    match rest {
      Nil => Some(Nil)
      Cons(head, tail) =>
        match
          (
            fp_product(field, @core.append(prefix, tail)),
            leading(target),
            walk(Cons(head, prefix), tail),
          ) {
          (Some(complement), Some(lc), Some(inverses)) => {
            let complement = @fppoly.scale(
              complement,
              @modular.signed_reduce(@primefield.modulus(field), lc),
            )
            match @fppoly.extended_gcd(complement, head) {
              Ok(bezout) =>
                if bezout.gcd.equal(@fppoly.one(field)) {
                  match @fppoly.divide(bezout.left, head) {
                    Ok(d) => Some(Cons(d.remainder, inverses))
                    Err(_) => None
                  }
                } else {
                  None
                }
              Err(_) => None
            }
          }
          _ => None
        }
    }
  }
  walk(Nil, factors)
}

///|
fn certificate_shape(
  certificate : LiftCertificate,
  field : @primefield.Field,
  modulus : @modular.Modulus,
) -> Bool {
  fn pairs(
    factors : @core.Chain[@fppoly.Polynomial],
    lifts : @core.Chain[Polynomial],
  ) -> Bool {
    match (factors, lifts) {
      (Nil, Nil) => true
      (Cons(f, fs), Cons(g, gs)) =>
        fp_monic_positive(f) &&
        @fppoly.field_of(f).equal(field) &&
        monic_positive(g) &&
        degree(g).equal(@fppoly.degree(f)) &&
        reduce(g, field).equal(f) &&
        modulo(g, modulus).equal(g) &&
        pairs(fs, gs)
      _ => false
    }
  }
  match
    (certificate.exponent, certificate.factors, leading(certificate.target)) {
    (Succ(_), Cons(_, _), Some(lc)) => {
      let reduced = reduce(certificate.target, field)
      !@binary.is_zero(@modular.signed_reduce(@primefield.modulus(field), lc)) &&
      degree(certificate.target).equal(@fppoly.degree(reduced)) &&
      pairs(certificate.factors, certificate.lifts) &&
      modulo(
        subtract(certificate.target, scale(product(certificate.lifts), lc)),
        modulus,
      ).equal(zero())
    }
    _ => false
  }
}

///|
/// Checks prime-power precision, degree preservation, pairwise coprimality,
/// residue ranges, and the complete product congruence. This proves lifting
/// validity, not integer irreducibility.
pub fn check_lift(certificate : LiftCertificate) -> Bool {
  match
    (
      @primefield.field(certificate.prime),
      @modular.modulus(prime_power(certificate.prime, certificate.exponent)),
    ) {
    (Some(field), Some(modulus)) =>
      certificate_shape(certificate, field, modulus) &&
      correction_inverses(certificate.target, field, certificate.factors)
      is Some(_)
    _ => false
  }
}

///|
/// Start a simultaneous monic lift of any pairwise coprime modular factors.
/// The integer target may have any nonzero leading coefficient prime to p.
pub fn start_lift(
  target : Polynomial,
  factors : @core.Chain[@fppoly.Polynomial],
) -> Result[Lift, AlgebraError] {
  match factors {
    Nil => Err(InvalidLift)
    Cons(first, _) => {
      let field = @fppoly.field_of(first)
      let prime = @fppoly.characteristic(first)
      let certificate : LiftCertificate = {
        target,
        prime,
        exponent: Succ(Zero),
        factors,
        lifts: @core.map(factors, lift_representative),
      }
      let modulus = @primefield.modulus(field)
      if !certificate_shape(certificate, field, modulus) {
        Err(InvalidLift)
      } else {
        match correction_inverses(target, field, factors) {
          Some(inverses) => Ok({ certificate, modulus, inverses, })
          None => Err(InvalidLift)
        }
      }
    }
  }
}

///|
/// Linear simultaneous Hensel lifting: m = p^k becomes mp = p^(k+1).
/// delta_i = ((f-lc(f)*product(g_j))/m) * (lc(f)*product(j!=i) f_j)^-1 mod f_i.
pub fn lift_step(value : Lift) -> Result[Lift, AlgebraError] {
  let certificate = value.certificate
  match (leading(certificate.target), @primefield.field(certificate.prime)) {
    (Some(lc), Some(field)) =>
      match
        divide_coefficients(
          subtract(certificate.target, scale(product(certificate.lifts), lc)),
          @exact.positive(@modular.value(value.modulus)),
        ) {
        None => Err(InternalInvariant)
        Some(error) => {
          let error = reduce(error, field)
          let next_value = @binary.multiply(
            @modular.value(value.modulus),
            certificate.prime,
          )
          match @modular.modulus(next_value) {
            None => Err(InternalInvariant)
            Some(next_modulus) => {
              fn correct(
                factors : @core.Chain[@fppoly.Polynomial],
                lifts : @core.Chain[Polynomial],
                inverses : @core.Chain[@fppoly.Polynomial],
              ) -> @core.Chain[Polynomial]? {
                match (factors, lifts, inverses) {
                  (Nil, Nil, Nil) => Some(Nil)
                  (Cons(f, fs), Cons(g, gs), Cons(inv, invs)) =>
                    match
                      (@fppoly.multiply(error, inv), correct(fs, gs, invs)) {
                      (Ok(correction), Some(tail)) =>
                        match @fppoly.divide(correction, f) {
                          Ok(d) =>
                            Some(
                              Cons(
                                modulo(
                                  add(
                                    g,
                                    scale(
                                      lift_representative(d.remainder),
                                      @exact.positive(
                                        @modular.value(value.modulus),
                                      ),
                                    ),
                                  ),
                                  next_modulus,
                                ),
                                tail,
                              ),
                            )
                          Err(_) => None
                        }
                      _ => None
                    }
                  _ => None
                }
              }
              match
                correct(certificate.factors, certificate.lifts, value.inverses) {
                None => Err(InternalInvariant)
                Some(lifts) => {
                  let next : LiftCertificate = {
                    target: certificate.target,
                    prime: certificate.prime,
                    exponent: Succ(certificate.exponent),
                    factors: certificate.factors,
                    lifts,
                  }
                  if certificate_shape(next, field, next_modulus) {
                    Ok({
                      certificate: next,
                      modulus: next_modulus,
                      inverses: value.inverses,
                    })
                  } else {
                    Err(InternalInvariant)
                  }
                }
              }
            }
          }
        }
      }
    _ => Err(InternalInvariant)
  }
}

///|
#derive(Eq, Debug)
pub(all) enum LiftStatus {
  Reached(Lift)
  Suspended(Lift)
}

///|
pub extend LiftStatus with Eq::{equal, not_equal}

///|
pub extend LiftStatus with Debug::{to_repr}

///|
/// Run until modulus > threshold, consuming at most fuel lifting steps.
pub fn lift_above(
  value : Lift,
  threshold : @binary.Binary,
  fuel : @core.Nat,
) -> Result[LiftStatus, AlgebraError] {
  match @binary.compare(lift_modulus(value), threshold) {
    Greater => Ok(Reached(value))
    _ =>
      match fuel {
        Zero => Ok(Suspended(value))
        Succ(rest) =>
          match lift_step(value) {
            Ok(next) => lift_above(next, threshold, rest)
            Err(error) => Err(error)
          }
      }
  }
}
