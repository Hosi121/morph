///|
#derive(Eq, Debug)
pub(all) struct EndpointJet {
  order : @core.Nat
  value : @poly.Polynomial
  sign : ScalarCertificate
}

///|
pub extend EndpointJet with Eq::{equal, not_equal}

///|
pub extend EndpointJet with Debug::{to_repr}

///|
#derive(Eq, Debug)
pub(all) struct CountCertificate {
  system : SystemCertificate
  interval : @sturm.Interval
  lower : @core.Chain[EndpointJet]
  upper : @core.Chain[EndpointJet]
  count : @core.Nat
}

///|
pub extend CountCertificate with Eq::{equal, not_equal}

///|
pub extend CountCertificate with Debug::{to_repr}

///|
fn endpoint(
  p : Polynomial,
  x : @exact.Rational,
) -> Result[EndpointJet, OrderedError] {
  fn walk(
    current : Polynomial,
    order : @core.Nat,
  ) -> Result[EndpointJet, OrderedError] {
    match evaluate(current, x) {
      Err(e) => Err(e)
      Ok(value) =>
        if @nf.is_zero(value) {
          if is_zero(current) {
            Err(InternalInvariant)
          } else {
            match derivative(current) {
              Ok(d) => walk(d, Succ(order))
              Err(e) => Err(e)
            }
          }
        } else {
          match scalar_sign(value) {
            Ok(sign) =>
              Ok({
                order,
                value: @nf.representative(value),
                sign: sign.certificate,
              })
            Err(e) => Err(e)
          }
        }
    }
  }
  walk(p, Zero)
}

///|
fn endpoint_values(
  sequence : @core.Chain[Polynomial],
  x : @exact.Rational,
) -> Result[@core.Chain[EndpointJet], OrderedError] {
  match sequence {
    Nil => Ok(Nil)
    Cons(head, rest) =>
      match (endpoint(head, x), endpoint_values(rest, x)) {
        (Ok(v), Ok(vs)) => Ok(Cons(v, vs))
        (Err(e), _) | (_, Err(e)) => Err(e)
      }
  }
}

///|
fn variations(values : @core.Chain[EndpointJet]) -> @core.Nat {
  fn scan(
    values : @core.Chain[EndpointJet],
    previous : @core.Ordering,
    count : @core.Nat,
  ) -> @core.Nat {
    match values {
      Nil => count
      Cons(head, rest) => {
        let current = head.sign.sign
        match (previous, current) {
          (Less, Greater) | (Greater, Less) => scan(rest, current, Succ(count))
          _ => scan(rest, current, count)
        }
      }
    }
  }
  scan(values, Equal, Zero)
}

///|
fn difference(
  lower : @core.Chain[EndpointJet],
  upper : @core.Chain[EndpointJet],
) -> @exact.Integer {
  @exact.subtract(
    @exact.positive(@binary.from_nat(variations(lower))),
    @exact.positive(@binary.from_nat(variations(upper))),
  )
}

///|
fn check_endpoint(
  p : Polynomial,
  x : @exact.Rational,
  proof : EndpointJet,
) -> Bool {
  fn walk(current : Polynomial, remaining : @core.Nat) -> Bool {
    match evaluate(current, x) {
      Err(_) => false
      Ok(value) =>
        match remaining {
          Zero =>
            !@nf.is_zero(value) &&
            @nf.representative(value).equal(proof.value) &&
            check_scalar(value, proof.sign.sign, proof.sign)
          Succ(rest) =>
            @nf.is_zero(value) &&
            (match derivative(current) {
              Ok(d) => walk(d, rest)
              Err(_) => false
            })
        }
    }
  }
  match degree(p) {
    Some(n) =>
      !@core.compare(proof.order, n).equal(Greater) && walk(p, proof.order)
    None => false
  }
}

///|
fn check_endpoints(
  sequence : @core.Chain[Polynomial],
  x : @exact.Rational,
  proofs : @core.Chain[EndpointJet],
) -> Bool {
  match (sequence, proofs) {
    (Nil, Nil) => true
    (Cons(p, ps), Cons(proof, rest)) =>
      check_endpoint(p, x, proof) && check_endpoints(ps, x, rest)
    _ => false
  }
}

///|
/// Distinct relative real roots in the HALF-OPEN interval (lower,upper]. Every
/// field-valued endpoint sign is certified by Sturm-Tarski at the base alpha.
pub fn count_between(
  system : System,
  interval : @sturm.Interval,
) -> Result[CountCertificate, OrderedError] {
  if !@exact.rational_compare(interval.lower, interval.upper).equal(Less) {
    Err(InvalidInterval)
  } else {
    match
      (
        endpoint_values(system.sequence, interval.lower),
        endpoint_values(system.sequence, interval.upper),
      ) {
      (Ok(lower), Ok(upper)) => {
        let value = difference(lower, upper)
        if @exact.negative(value) {
          Err(InternalInvariant)
        } else {
          Ok({
            system: system.certificate,
            interval,
            lower,
            upper,
            count: @binary.to_nat(@exact.magnitude(value)),
          })
        }
      }
      (Err(e), _) | (_, Err(e)) => Err(e)
    }
  }
}

///|
pub fn check_count(
  system : System,
  interval : @sturm.Interval,
  count : @core.Nat,
  proof : CountCertificate,
) -> Bool {
  system.certificate.equal(proof.system) &&
  interval.equal(proof.interval) &&
  count.equal(proof.count) &&
  @exact.rational_compare(interval.lower, interval.upper).equal(Less) &&
  check_system(system.polynomial, proof.system) &&
  check_endpoints(system.sequence, interval.lower, proof.lower) &&
  check_endpoints(system.sequence, interval.upper, proof.upper) &&
  difference(proof.lower, proof.upper).equal(
    @exact.positive(@binary.from_nat(count)),
  )
}
