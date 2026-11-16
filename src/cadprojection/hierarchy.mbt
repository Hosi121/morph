///|
fn constant_sign(p : @poly.Polynomial) -> @core.Ordering? {
  if @core.all(@poly.terms(p), fn(t) { @core.all(t.exponents, @core.is_zero) }) {
    Some(
      @exact.rational_compare(
        @core.fold_left(@poly.terms(p), @exact.rational_zero(), fn(acc, t) {
          @exact.rational_add(acc, t.coefficient)
        }),
        @exact.rational_zero(),
      ),
    )
  } else {
    None
  }
}

///|
fn member_index(
  p : @poly.Polynomial,
  family : @core.Chain[@poly.Polynomial],
  index : @core.Nat,
) -> @core.Nat? {
  match family {
    Nil => None
    Cons(q, rest) =>
      if p.equal(q) {
        Some(index)
      } else {
        member_index(p, rest, Succ(index))
      }
  }
}

///|
/// Stable exact deduplication only; no monic or sign-changing normalization.
fn prune(
  source : @core.Chain[@poly.Polynomial],
) -> @core.Chain[@poly.Polynomial] {
  @core.fold_left(source, @core.Nil, fn(found, p) {
    if constant_sign(p) is Some(_) || member_index(p, found, Zero) is Some(_) {
      found
    } else {
      @core.append(found, @core.Cons(p, @core.Nil))
    }
  })
}

///|
fn derivative_tail(
  p : @poly.Polynomial,
  selected : @core.Nat,
) -> Result[@core.Chain[@poly.Polynomial], ProjectionError] {
  match @poly.derivative(p, selected) {
    None => Err(ArithmeticFailure)
    Some(d) =>
      if constant_sign(d) is Some(_) {
        Ok(Nil)
      } else {
        match derivative_tail(d, selected) {
          Ok(tail) => Ok(Cons(d, tail))
          Err(e) => Err(e)
        }
      }
  }
}

///|
fn close_family(
  source : @core.Chain[@poly.Polynomial],
  selected : @core.Nat,
) -> Result[@core.Chain[@poly.Polynomial], ProjectionError] {
  let originals = prune(source)
  fn go(
    ps : @core.Chain[@poly.Polynomial],
  ) -> Result[@core.Chain[@poly.Polynomial], ProjectionError] {
    match ps {
      Nil => Ok(Nil)
      Cons(p, rest) =>
        match (derivative_tail(p, selected), go(rest)) {
          (Ok(own), Ok(tail)) => Ok(@core.append(own, tail))
          _ => Err(ArithmeticFailure)
        }
    }
  }
  match go(originals) {
    Ok(ds) => Ok(prune(@core.append(originals, ds)))
    Err(e) => Err(e)
  }
}

///|
fn bind_one(
  p : @poly.Polynomial,
  family : @core.Chain[@poly.Polynomial],
) -> Binding? {
  match constant_sign(p) {
    Some(sign) => Some(Constant(sign))
    None =>
      match member_index(p, family, Zero) {
        Some(index) => Some(Member(index))
        None => None
      }
  }
}

///|
fn bindings(
  source : @core.Chain[@poly.Polynomial],
  family : @core.Chain[@poly.Polynomial],
) -> @core.Chain[Binding]? {
  match source {
    Nil => Some(Nil)
    Cons(p, rest) =>
      match (bind_one(p, family), bindings(rest, family)) {
        (Some(binding), Some(tail)) => Some(Cons(binding, tail))
        _ => None
      }
  }
}

///|
fn derivative_bindings(
  ps : @core.Chain[@poly.Polynomial],
  family : @core.Chain[@poly.Polynomial],
  selected : @core.Nat,
) -> @core.Chain[Binding]? {
  match ps {
    Nil => Some(Nil)
    Cons(p, rest) =>
      match @poly.derivative(p, selected) {
        None => None
        Some(d) =>
          match
            (bind_one(d, family), derivative_bindings(rest, family, selected)) {
            (Some(binding), Some(tail)) => Some(Cons(binding, tail))
            _ => None
          }
      }
  }
}

///|
fn build_levels(
  arity : @core.Nat,
  source : @core.Chain[@poly.Polynomial],
) -> Result[@core.Chain[Level], ProjectionError] {
  match arity {
    Zero =>
      match bindings(source, Nil) {
        Some(bindings) =>
          Ok(
            Cons(
              {
                arity,
                source,
                family: Nil,
                bindings,
                derivatives: Nil,
                projection: None,
              },
              Nil,
            ),
          )
        None => Err(ArithmeticFailure)
      }
    Succ(selected) =>
      match close_family(source, selected) {
        Err(e) => Err(e)
        Ok(family) =>
          match
            (
              bindings(source, family),
              derivative_bindings(family, family, selected),
              full_collins(arity, family),
            ) {
            (Some(bindings), Some(derivatives), Ok(projection)) =>
              match
                build_levels(
                  selected,
                  prune(projection_polynomials(projection)),
                ) {
                Err(e) => Err(e)
                Ok(lower) =>
                  Ok(
                    @core.append(
                      lower,
                      Cons(
                        {
                          arity,
                          source,
                          family,
                          bindings,
                          derivatives,
                          projection: Some(projection),
                        },
                        Nil,
                      ),
                    ),
                  )
              }
            _ => Err(ArithmeticFailure)
          }
      }
  }
}

///|
pub fn prepare(
  arity : @core.Nat,
  atoms : @core.Chain[@poly.Polynomial],
) -> Result[Plan, ProjectionError] {
  match validate(arity, atoms) {
    Err(e) => Err(e)
    Ok(_) =>
      match build_levels(arity, atoms) {
        Err(e) => Err(e)
        Ok(levels) => Ok({ proof: { arity, atoms, levels, }, })
      }
  }
}

///|
/// Bind the whole derivation, source arity/order and deterministic derivative
/// closure, all reducta and all PSC entries. Recompute algebraic data; this is
/// a checker for the finite projection construction, not a formal CAD theorem.
pub fn check(
  arity : @core.Nat,
  atoms : @core.Chain[@poly.Polynomial],
  proof : Certificate,
) -> Bool {
  match prepare(arity, atoms) {
    Ok(plan) => plan.proof.equal(proof)
    Err(_) => false
  }
}

///|
pub fn checked(
  arity : @core.Nat,
  atoms : @core.Chain[@poly.Polynomial],
  proof : Certificate,
) -> Plan? {
  if check(arity, atoms, proof) {
    Some({ proof, })
  } else {
    None
  }
}

///|
pub fn check_result(
  arity : @core.Nat,
  atoms : @core.Chain[@poly.Polynomial],
  plan : Plan,
  proof : Certificate,
) -> Bool {
  plan.proof.equal(proof) && check(arity, atoms, proof)
}
