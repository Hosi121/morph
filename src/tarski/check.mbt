///|
/// Verify a first-nonzero-derivative witness, including minimality of the order.
fn check_jet(
  p : @poly.Polynomial,
  x : @exact.Rational,
  witness : RightJet,
) -> Bool {
  fn walk(current : @poly.Polynomial, remaining : @core.Nat) -> Bool {
    match @poly.evaluate(current, Cons(x, Nil)) {
      None => false
      Some(value) =>
        match remaining {
          Zero => value.equal(witness.value) && !sign(value).equal(Equal)
          Succ(rest) =>
            sign(value).equal(Equal) &&
            (match derivative(current) {
              Some(d) => walk(d, rest)
              None => false
            })
        }
    }
  }
  match degree(p) {
    Some(degree) =>
      !@core.compare(witness.order, degree).equal(Greater) &&
      walk(p, witness.order)
    None => false
  }
}

///|
fn check_jets(
  sequence : @core.Chain[@poly.Polynomial],
  x : @exact.Rational,
  jets : @core.Chain[RightJet],
) -> Bool {
  match (sequence, jets) {
    (Nil, Nil) => true
    (Cons(p, ps), Cons(jet, rest)) =>
      check_jet(p, x, jet) && check_jets(ps, x, rest)
    _ => false
  }
}

///|
/// Verifies quotient identities and strict degree descent. This does not rerun
/// Euclidean division. The last quotient must prove an EXACT terminal division.
fn check_sequence(
  sequence : @core.Chain[@poly.Polynomial],
  quotients : @core.Chain[@poly.Polynomial],
) -> Bool {
  match sequence {
    Cons(a, Nil) =>
      !@poly.is_zero(a) &&
      (match quotients {
        Nil => true
        _ => false
      })
    Cons(a, Cons(b, rest)) =>
      if @poly.is_zero(b) || !@poly.variables(b).equal(Succ(Zero)) {
        false
      } else {
        match quotients {
          Nil => false
          Cons(q, qs) =>
            match @poly.multiply(q, b) {
              Err(_) => false
              Ok(product) =>
                match @poly.subtract(a, product) {
                  Err(_) => false
                  Ok(remainder) =>
                    match rest {
                      Nil =>
                        @poly.is_zero(remainder) &&
                        (match qs {
                          Nil => true
                          _ => false
                        })
                      Cons(c, cs) =>
                        !@poly.is_zero(c) &&
                        smaller(c, b) &&
                        remainder.equal(@poly.negate(c)) &&
                        check_sequence(Cons(b, Cons(c, cs)), qs)
                    }
                }
            }
        }
      }
    Nil => false
  }
}

///|
/// Bind the original P,Q and half-open interval, verify the signed PRS and
/// endpoint jets, and recompute the claimed signed variation difference.
pub fn check_query(
  p : @poly.Polynomial,
  q : @poly.Polynomial,
  interval : @sturm.Interval,
  proof : QueryCertificate,
) -> Bool {
  if !p.equal(proof.polynomial) ||
    !q.equal(proof.query) ||
    !interval.equal(proof.interval) {
    false
  } else {
    match valid_inputs(p, q, interval) {
      Err(_) => false
      Ok(_) => {
        let normalized = @poly.monic(p)
        match seed(normalized, q) {
          None => false
          Some(expected_seed) => {
            let correct_start = match
              (proof.sequence, @poly.is_zero(expected_seed)) {
              (Cons(first, Nil), true) => first.equal(normalized)
              (Cons(first, Cons(second, _)), false) =>
                first.equal(normalized) &&
                second.equal(expected_seed) &&
                smaller(second, first)
              _ => false
            }
            proof.normalized.equal(normalized) &&
            proof.seed.equal(expected_seed) &&
            correct_start &&
            check_sequence(proof.sequence, proof.quotients) &&
            check_jets(proof.sequence, interval.lower, proof.lower_jets) &&
            check_jets(proof.sequence, interval.upper, proof.upper_jets) &&
            proof.result.equal(difference(proof.lower_jets, proof.upper_jets))
          }
        }
      }
    }
  }
}

///|
/// Also bind a separately supplied Integer payload; public result records can
/// otherwise be paired with a valid certificate for a different value.
pub fn check_query_result(
  p : @poly.Polynomial,
  q : @poly.Polynomial,
  interval : @sturm.Interval,
  value : @exact.Integer,
  proof : QueryCertificate,
) -> Bool {
  value.equal(proof.result) && check_query(p, q, interval, proof)
}
