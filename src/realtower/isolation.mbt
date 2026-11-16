///|
fn without_last(
  values : @core.Chain[Representation],
) -> @core.Chain[Representation] {
  match values {
    Nil | Cons(_, Nil) => Nil
    Cons(c, cs) => Cons(c, without_last(cs))
  }
}

///|
fn absolute_sum(
  field : Field,
  values : @core.Chain[Representation],
) -> Result[Representation, TowerError] {
  match values {
    Nil => Ok(raw_one(field))
    Cons(c, cs) =>
      both(raw_sign(field, c), absolute_sum(field, cs), fn(sign, rest) {
        raw_add(field, if sign.equal(Less) { raw_negate(c) } else { c }, rest)
      })
  }
}

///|
fn bounding_interval(bound : @exact.Rational) -> @sturm.Interval {
  { lower: @exact.rational_negate(bound), upper: bound, }
}

///|
/// Strict Cauchy radius B > 1 + sum |a_i| for the monic squarefree polynomial.
pub fn check_bound(value : System, proof : BoundCertificate) -> Bool {
  value.certificate.equal(proof.system) &&
  system_payload(value, proof.system) &&
  @exact.rational_compare(proof.bound, @exact.rational_zero()).equal(Greater) &&
  (match
    absolute_sum(value.polynomial.field, without_last(value.squarefree.values)) {
    Err(_) => false
    Ok(sum) =>
      match
        raw_add(
          value.polynomial.field,
          raw_rational(value.polynomial.field, proof.bound),
          raw_negate(sum),
        ) {
        Err(_) => false
        Ok(delta) =>
          match raw_sign(value.polynomial.field, delta) {
            Ok(Greater) => true
            _ => false
          }
      }
  })
}

///|
/// Verify a global bound, whole-root count, and disjoint one-root intervals.
/// All checks recompute exact decisions and bind the original source/context.
pub fn check_isolation(value : Polynomial, proof : SolutionCertificate) -> Bool {
  match system_from_certificate(value, proof.system) {
    Err(_) => false
    Ok(s) => {
      let span = bounding_interval(proof.bound.bound)
      fn walk(
        values : @core.Chain[RootCertificate],
        lower : @exact.Rational,
      ) -> Bool {
        match values {
          Nil => true
          Cons(c, cs) => {
            let interval = c.count.interval
            c.system.equal(proof.system) &&
            c.count.system.equal(proof.system) &&
            !@exact.rational_compare(interval.lower, lower).equal(Less) &&
            !@exact.rational_compare(interval.upper, span.upper).equal(Greater) &&
            check_count(s, interval, Succ(Zero), c.count) &&
            walk(cs, interval.upper)
          }
        }
      }
      proof.bound.system.equal(proof.system) &&
      proof.whole.system.equal(proof.system) &&
      check_bound(s, proof.bound) &&
      check_count(s, span, proof.whole.count, proof.whole) &&
      @core.length(proof.roots).equal(proof.whole.count) &&
      walk(proof.roots, span.lower)
    }
  }
}

///|
pub fn check_isolation_result(
  value : Polynomial,
  result : SolutionSet,
  proof : SolutionCertificate,
) -> Bool {
  value.equal(result.system.polynomial) &&
  system_payload(result.system, proof.system) &&
  result.certificate.equal(proof) &&
  @core.map(result.roots, root_certificate).equal(proof.roots) &&
  @core.all(result.roots, fn(root) {
    value.equal(root.system.polynomial) &&
    system_payload(root.system, proof.system)
  }) &&
  check_isolation(value, proof)
}

///|
pub fn isolate(value : System) -> Result[State, TowerError] {
  next(
    absolute_sum(value.polynomial.field, without_last(value.squarefree.values)),
    fn(threshold) {
      Ok({
        system: value,
        threshold: { field: value.polynomial.field, value: threshold, },
        candidate: @binary.one(),
        phase: FindingBound,
      })
    },
  )
}

///|
pub fn start(value : Polynomial) -> Result[State, TowerError] {
  next(system(value), isolate)
}

///|
fn midpoint(interval : @sturm.Interval) -> @exact.Rational {
  @exact.rational_half(@exact.rational_add(interval.lower, interval.upper))
}

///|
fn split(
  value : System,
  interval : @sturm.Interval,
) -> Result[(CountCertificate, CountCertificate), TowerError] {
  let middle = midpoint(interval)
  both(
    count_between(value, { lower: interval.lower, upper: middle, }),
    count_between(value, { lower: middle, upper: interval.upper, }),
    fn(a, b) { Ok((a, b)) },
  )
}

///|
fn complete(
  value : System,
  bound : BoundCertificate,
  whole : CountCertificate,
  accepted : @core.Chain[RootCertificate],
) -> Result[Progress, TowerError] {
  let proofs = @core.reverse(accepted)
  let proof : SolutionCertificate = {
    system: value.certificate,
    bound,
    whole,
    roots: proofs,
  }
  let roots = @core.map(proofs, fn(certificate) {
    Root::{ system: value, certificate, }
  })
  Ok(Isolated({ system: value, roots, certificate: proof, }))
}

///|
/// Fuel counts bound comparisons or bisection nodes, not arithmetic complexity.
/// Zero fuel preserves state; a Paused result never means no roots.
pub fn advance(value : State, fuel : @core.Nat) -> Result[Progress, TowerError] {
  match (value.phase, fuel) {
    (Splitting(bound, whole, Nil, accepted), _) =>
      complete(value.system, bound, whole, accepted)
    (_, Zero) => Ok(Paused(value))
    (FindingBound, Succ(rest)) => {
      let radius = @exact.whole(@exact.positive(value.candidate))
      next(
        scalar_subtract(
          rational(value.system.polynomial.field, radius),
          value.threshold,
        ),
        fn(delta) {
          next(scalar_sign(delta), fn(sign) {
            if sign.sign.equal(Greater) {
              let bound : BoundCertificate = {
                system: value.system.certificate,
                bound: radius,
              }
              next(count_between(value.system, bounding_interval(radius)), fn(
                whole,
              ) {
                advance(
                  {
                    ..value,
                    phase: Splitting(bound, whole, Cons(whole, Nil), Nil),
                  },
                  rest,
                )
              })
            } else {
              advance(
                { ..value, candidate: @binary.double(value.candidate), },
                rest,
              )
            }
          })
        },
      )
    }
    (Splitting(bound, whole, Cons(head, pending), accepted), Succ(rest)) =>
      match head.count {
        Zero =>
          advance(
            { ..value, phase: Splitting(bound, whole, pending, accepted), },
            rest,
          )
        Succ(Zero) => {
          let root : RootCertificate = {
            system: value.system.certificate,
            count: head,
          }
          advance(
            {
              ..value,
              phase: Splitting(bound, whole, pending, Cons(root, accepted)),
            },
            rest,
          )
        }
        _ =>
          next(split(value.system, head.interval), fn(pair) {
            let (left, right) = pair
            if @core.add(left.count, right.count).equal(head.count) {
              advance(
                {
                  ..value,
                  phase: Splitting(
                    bound,
                    whole,
                    Cons(left, Cons(right, pending)),
                    accepted,
                  ),
                },
                rest,
              )
            } else {
              Err(InternalInvariant)
            }
          })
      }
  }
}

///|
pub fn refine(value : Root, steps : @core.Nat) -> Result[Root, TowerError] {
  match steps {
    Zero => Ok(value)
    Succ(rest) =>
      next(split(value.system, root_interval(value)), fn(pair) {
        let (left, right) = pair
        if !@core.add(left.count, right.count).equal(Succ(Zero)) {
          Err(InternalInvariant)
        } else {
          let chosen = if left.count.equal(Succ(Zero)) { left } else { right }
          if !chosen.count.equal(Succ(Zero)) {
            Err(InternalInvariant)
          } else {
            refine(
              {
                system: value.system,
                certificate: {
                  system: value.system.certificate,
                  count: chosen,
                },
              },
              rest,
            )
          }
        }
      })
  }
}
