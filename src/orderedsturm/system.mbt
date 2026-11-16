///|
#derive(Eq, Debug)
pub(all) struct SystemCertificate {
  context : @real.RootCertificate
  polynomial : @core.Chain[@poly.Polynomial]
  normalized : @core.Chain[@poly.Polynomial]
  gcd_sequence : @core.Chain[@core.Chain[@poly.Polynomial]]
  gcd_quotients : @core.Chain[@core.Chain[@poly.Polynomial]]
  squarefree : @core.Chain[@poly.Polynomial]
  sequence : @core.Chain[@core.Chain[@poly.Polynomial]]
  quotients : @core.Chain[@core.Chain[@poly.Polynomial]]
}

///|
pub extend SystemCertificate with Eq::{equal, not_equal}

///|
pub extend SystemCertificate with Debug::{to_repr}

///|
#derive(Debug)
pub struct System {
  polynomial : Polynomial
  squarefree : Polynomial
  sequence : @core.Chain[Polynomial]
  certificate : SystemCertificate
}

///|
pub extend System with Debug::{to_repr}

///|
pub fn system_certificate(value : System) -> SystemCertificate {
  value.certificate
}

///|
pub fn squarefree(value : System) -> Polynomial {
  value.squarefree
}

///|
fn encode_sequence(
  values : @core.Chain[Polynomial],
) -> @core.Chain[@core.Chain[@poly.Polynomial]] {
  @core.map(values, representatives)
}

///|
fn decode_sequence(
  field : @nf.Field,
  values : @core.Chain[@core.Chain[@poly.Polynomial]],
) -> Result[@core.Chain[Polynomial], OrderedError] {
  match values {
    Nil => Ok(Nil)
    Cons(head, rest) =>
      match (decode(field, head), decode_sequence(field, rest)) {
        (Ok(p), Ok(ps)) => Ok(Cons(p, ps))
        (Err(e), _) | (_, Err(e)) => Err(e)
      }
  }
}

///|
fn smaller(a : Polynomial, b : Polynomial) -> Bool {
  match (degree(a), degree(b)) {
    (Some(a), Some(b)) => @core.compare(a, b).equal(Less)
    _ => false
  }
}

///|
fn build_sequence(
  a : Polynomial,
  b : Polynomial,
) -> Result[(@core.Chain[Polynomial], @core.Chain[Polynomial]), OrderedError] {
  if is_zero(b) {
    Ok((Cons(a, Nil), Nil))
  } else {
    match divide(a, b) {
      Err(e) => Err(e)
      Ok(d) =>
        match build_sequence(b, negate(d.remainder)) {
          Ok((ps, qs)) => Ok((Cons(a, ps), Cons(d.quotient, qs)))
          Err(e) => Err(e)
        }
    }
  }
}

///|
fn check_sequence(
  entries : @core.Chain[Polynomial],
  quotients : @core.Chain[Polynomial],
) -> Bool {
  match entries {
    Cons(a, Nil) =>
      !is_zero(a) &&
      (match quotients {
        Nil => true
        _ => false
      })
    Cons(a, Cons(b, rest)) =>
      if is_zero(b) {
        false
      } else {
        match quotients {
          Cons(q, qs) =>
            match multiply(q, b) {
              Ok(product) =>
                match subtract(a, product) {
                  Ok(r) =>
                    match rest {
                      Nil =>
                        is_zero(r) &&
                        (match qs {
                          Nil => true
                          _ => false
                        })
                      Cons(c, cs) =>
                        !is_zero(c) &&
                        smaller(c, b) &&
                        equal(r, negate(c)) &&
                        check_sequence(Cons(b, Cons(c, cs)), qs)
                    }
                  Err(_) => false
                }
              Err(_) => false
            }
          Nil => false
        }
      }
    Nil => false
  }
}

///|
fn correct_start(
  entries : @core.Chain[Polynomial],
  first : Polynomial,
  second : Polynomial,
) -> Bool {
  match (entries, is_zero(second)) {
    (Cons(a, Nil), true) => equal(a, first)
    (Cons(a, Cons(b, _)), false) =>
      equal(a, first) && equal(b, second) && smaller(b, a)
    _ => false
  }
}

///|
fn monic_value(p : Polynomial) -> Bool {
  match leading(p) {
    Some(lc) => @nf.equal(lc, @nf.one(p.field))
    None => false
  }
}

///|
/// Check original-context binding, exact gcd PRS, the square-free quotient, and
/// a second signed PRS for that square-free polynomial. No division history is
/// replayed: supplied quotients must satisfy exact identities and degree bounds.
pub fn check_system(p : Polynomial, proof : SystemCertificate) -> Bool {
  if is_zero(p) ||
    !@nf.embedding(p.field).equal(proof.context) ||
    !representatives(p).equal(proof.polynomial) {
    false
  } else {
    match
      (
        monic(p),
        decode(p.field, proof.normalized),
        decode_sequence(p.field, proof.gcd_sequence),
        decode_sequence(p.field, proof.gcd_quotients),
        decode(p.field, proof.squarefree),
        decode_sequence(p.field, proof.sequence),
        decode_sequence(p.field, proof.quotients),
      ) {
      (
        Ok(expected),
        Ok(normalized),
        Ok(gcd_sequence),
        Ok(gcd_quotients),
        Ok(sf),
        Ok(sequence),
        Ok(quotients),
      ) =>
        if !equal(expected, normalized) || !monic_value(sf) {
          false
        } else {
          match
            (
              derivative(normalized),
              @core.last(gcd_sequence),
              derivative(sf),
              @core.last(sequence),
            ) {
            (Ok(d), Some(last), Ok(ds), Some(terminal)) =>
              if !correct_start(gcd_sequence, normalized, d) ||
                !check_sequence(gcd_sequence, gcd_quotients) ||
                !correct_start(sequence, sf, ds) ||
                !check_sequence(sequence, quotients) ||
                !(degree(terminal) is Some(Zero)) {
                false
              } else {
                match monic(last) {
                  Ok(gcd) =>
                    match multiply(gcd, sf) {
                      Ok(product) => equal(product, normalized)
                      Err(_) => false
                    }
                  Err(_) => false
                }
              }
            _ => false
          }
        }
      _ => false
    }
  }
}

///|
pub fn system_from_certificate(
  p : Polynomial,
  proof : SystemCertificate,
) -> Result[System, OrderedError] {
  if !check_system(p, proof) {
    Err(InvalidCertificate)
  } else {
    match
      (
        decode(p.field, proof.squarefree),
        decode_sequence(p.field, proof.sequence),
      ) {
      (Ok(squarefree), Ok(sequence)) =>
        Ok({ polynomial: p, squarefree, sequence, certificate: proof, })
      _ => Err(InternalInvariant)
    }
  }
}

///|
/// Normalize to a monic square-free polynomial over the SAME real-embedded
/// coefficient field; repeated roots are subsequently counted once.
pub fn system(p : Polynomial) -> Result[System, OrderedError] {
  if is_zero(p) {
    Err(ZeroPolynomial)
  } else {
    match monic(p) {
      Err(e) => Err(e)
      Ok(normalized) =>
        match derivative(normalized) {
          Err(e) => Err(e)
          Ok(d) =>
            match build_sequence(normalized, d) {
              Err(e) => Err(e)
              Ok((gcd_sequence, gcd_quotients)) =>
                match @core.last(gcd_sequence) {
                  None => Err(InternalInvariant)
                  Some(last) =>
                    match monic(last) {
                      Err(e) => Err(e)
                      Ok(gcd) =>
                        match divide(normalized, gcd) {
                          Err(e) => Err(e)
                          Ok(division) =>
                            if !is_zero(division.remainder) {
                              Err(InternalInvariant)
                            } else {
                              let sf = division.quotient
                              match derivative(sf) {
                                Err(e) => Err(e)
                                Ok(ds) =>
                                  match build_sequence(sf, ds) {
                                    Err(e) => Err(e)
                                    Ok((sequence, quotients)) => {
                                      let proof : SystemCertificate = {
                                        context: @nf.embedding(p.field),
                                        polynomial: representatives(p),
                                        normalized: representatives(normalized),
                                        gcd_sequence: encode_sequence(
                                          gcd_sequence,
                                        ),
                                        gcd_quotients: encode_sequence(
                                          gcd_quotients,
                                        ),
                                        squarefree: representatives(sf),
                                        sequence: encode_sequence(sequence),
                                        quotients: encode_sequence(quotients),
                                      }
                                      system_from_certificate(p, proof)
                                    }
                                  }
                              }
                            }
                        }
                    }
                }
            }
        }
    }
  }
}
