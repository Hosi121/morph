///|
/// A source-bound squarefree system. No irreducibility assertion is made.
pub fn system(value : Polynomial) -> Result[System, TowerError] {
  if is_zero(value) {
    Err(ZeroPolynomial)
  } else {
    next(rp_squarefree(value.field, value.values), fn(sf) {
      next(rp_derivative(value.field, sf), fn(d) {
        next(rp_sequence(value.field, sf, d), fn(sequence) {
          let squarefree : Polynomial = { field: value.field, values: sf, }
          Ok({
            polynomial: value,
            squarefree,
            sequence,
            certificate: {
              field: value.field,
              polynomial: value.values,
              squarefree: sf,
            },
          })
        })
      })
    })
  }
}

///|
pub fn check_system(value : Polynomial, proof : SystemCertificate) -> Bool {
  same_field(value.field, proof.field) &&
  value.values.equal(proof.polynomial) &&
  (match system(value) {
    Ok(s) => s.certificate.equal(proof)
    Err(_) => false
  })
}

///|
pub fn system_from_certificate(
  value : Polynomial,
  proof : SystemCertificate,
) -> Result[System, TowerError] {
  next(system(value), fn(s) {
    if s.certificate.equal(proof) {
      Ok(s)
    } else {
      Err(InvalidCertificate)
    }
  })
}

///|
/// Count distinct real roots in (lower, upper], with exact right-limit signs.
pub fn count_between(
  value : System,
  interval : @sturm.Interval,
) -> Result[CountCertificate, TowerError] {
  if !@exact.rational_compare(interval.lower, interval.upper).equal(Less) {
    Err(InvalidInterval)
  } else {
    next(rp_difference(value.polynomial.field, value.sequence, interval), fn(
      n,
    ) {
      if @exact.negative(n) {
        Err(InternalInvariant)
      } else {
        Ok({
          system: value.certificate,
          interval,
          count: @binary.to_nat(@exact.magnitude(n)),
        })
      }
    })
  }
}

///|
pub fn check_count(
  value : System,
  interval : @sturm.Interval,
  count : @core.Nat,
  proof : CountCertificate,
) -> Bool {
  value.certificate.equal(proof.system) &&
  interval.equal(proof.interval) &&
  count.equal(proof.count) &&
  check_system(value.polynomial, proof.system) &&
  (match count_between(value, interval) {
    Ok(c) => c.equal(proof)
    Err(_) => false
  })
}

///|
pub fn root_in_interval(
  value : System,
  interval : @sturm.Interval,
) -> Result[Root, TowerError] {
  next(count_between(value, interval), fn(count) {
    if count.count.equal(Succ(Zero)) {
      Ok({ system: value, certificate: { system: value.certificate, count, }, })
    } else {
      Err(InvalidInterval)
    }
  })
}

///|
pub fn check_root(value : Polynomial, proof : RootCertificate) -> Bool {
  proof.system.equal(proof.count.system) &&
  (match system_from_certificate(value, proof.system) {
    Ok(s) => check_count(s, proof.count.interval, Succ(Zero), proof.count)
    Err(_) => false
  })
}

///|
pub fn root_from_certificate(
  value : Polynomial,
  proof : RootCertificate,
) -> Result[Root, TowerError] {
  next(system_from_certificate(value, proof.system), fn(s) {
    if proof.system.equal(proof.count.system) &&
      check_count(s, proof.count.interval, Succ(Zero), proof.count) {
      Ok({ system: s, certificate: proof, })
    } else {
      Err(InvalidCertificate)
    }
  })
}

///|
pub fn check_root_result(
  value : Polynomial,
  root : Root,
  proof : RootCertificate,
) -> Bool {
  value.equal(root.system.polynomial) &&
  root.certificate.equal(proof) &&
  root.system.certificate.equal(proof.system) &&
  check_root(value, proof)
}

///|
/// Adjoin exactly the selected relative root, retaining a possibly reducible
/// monic squarefree definition. The generator is reduced modulo that definition.
pub fn adjoin(value : Root) -> Result[Extension, TowerError] {
  if !check_root_result(value.system.polynomial, value, value.certificate) {
    Err(InvalidCertificate)
  } else {
    let parent = value.system.polynomial.field
    let field : Field = {
      context: Extension(
        parent,
        value.system.squarefree.values,
        root_interval(value),
      ),
    }
    next(
      raw_fraction(
        field,
        Cons(raw_zero(parent), Cons(raw_one(parent), Nil)),
        Cons(raw_one(parent), Nil),
      ),
      fn(raw) { Ok({ field, generator: { field, value: raw, }, }) },
    )
  }
}
