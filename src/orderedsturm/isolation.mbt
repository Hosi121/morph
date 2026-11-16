///|
#derive(Eq, Debug)
pub(all) struct BoundCertificate {
  system : SystemCertificate
  bound : @exact.Rational
  coefficients : @core.Chain[ScalarCertificate]
  comparison : ScalarCertificate
}

///|
pub extend BoundCertificate with Eq::{equal, not_equal}

///|
pub extend BoundCertificate with Debug::{to_repr}

///|
fn without_last(values : @core.Chain[@nf.Element]) -> @core.Chain[@nf.Element] {
  match values {
    Nil | Cons(_, Nil) => Nil
    Cons(head, rest) => Cons(head, without_last(rest))
  }
}

///|
fn absolute_sum(
  field : @nf.Field,
  values : @core.Chain[@nf.Element],
) -> Result[(@nf.Element, @core.Chain[ScalarCertificate]), OrderedError] {
  match values {
    Nil => Ok((@nf.one(field), Nil))
    Cons(head, rest) =>
      match (scalar_sign(head), absolute_sum(field, rest)) {
        (Ok(sign), Ok((tail, proofs))) => {
          let absolute = if sign.sign.equal(Less) {
            @nf.negate(head)
          } else {
            head
          }
          match @nf.add(absolute, tail) {
            Ok(sum) => Ok((sum, Cons(sign.certificate, proofs)))
            Err(e) => Err(FieldFailure(e))
          }
        }
        (Err(e), _) | (_, Err(e)) => Err(e)
      }
  }
}

///|
fn checked_sum(
  field : @nf.Field,
  values : @core.Chain[@nf.Element],
  proofs : @core.Chain[ScalarCertificate],
) -> @nf.Element? {
  match (values, proofs) {
    (Nil, Nil) => Some(@nf.one(field))
    (Cons(head, rest), Cons(proof, ps)) =>
      if !check_scalar(head, proof.sign, proof) {
        None
      } else {
        match checked_sum(field, rest, ps) {
          None => None
          Some(tail) => {
            let absolute = if proof.sign.equal(Less) {
              @nf.negate(head)
            } else {
              head
            }
            match @nf.add(absolute, tail) {
              Ok(sum) => Some(sum)
              Err(_) => None
            }
          }
        }
      }
    _ => None
  }
}

///|
/// A strict Cauchy radius B > 1 + sum |a_i| for the monic square-free polynomial.
pub fn check_bound(system : System, proof : BoundCertificate) -> Bool {
  system_payload(system, proof.system) &&
  @exact.rational_compare(proof.bound, @exact.rational_zero()).equal(Greater) &&
  (match
    checked_sum(
      system.polynomial.field,
      without_last(system.squarefree.coefficients),
      proof.coefficients,
    ) {
    Some(threshold) =>
      match
        @nf.subtract(
          @nf.rational(system.polynomial.field, proof.bound),
          threshold,
        ) {
        Ok(delta) => check_scalar(delta, Greater, proof.comparison)
        Err(_) => false
      }
    None => false
  })
}

///|
#derive(Eq, Debug)
pub(all) struct RootCertificate {
  system : SystemCertificate
  count : CountCertificate
}

///|
pub extend RootCertificate with Eq::{equal, not_equal}

///|
pub extend RootCertificate with Debug::{to_repr}

///|
/// A relative real root beta over the fixed real embedding alpha. This is a
/// tower root descriptor, not a field Q(alpha,beta) or an absolute RootCertificate.
#derive(Debug)
pub struct Root {
  system : System
  certificate : RootCertificate
}

///|
pub extend Root with Debug::{to_repr}

///|
pub fn root_certificate(root : Root) -> RootCertificate {
  root.certificate
}

///|
pub fn root_interval(root : Root) -> @sturm.Interval {
  root.certificate.count.interval
}

///|
pub fn root_polynomial(root : Root) -> Polynomial {
  root.system.polynomial
}

///|
pub fn root_field(root : Root) -> @nf.Field {
  root.system.polynomial.field
}

///|
pub fn check_root(p : Polynomial, proof : RootCertificate) -> Bool {
  match system_from_certificate(p, proof.system) {
    Ok(system) =>
      check_count(system, proof.count.interval, Succ(Zero), proof.count)
    Err(_) => false
  }
}

///|
pub fn root_from_certificate(
  p : Polynomial,
  proof : RootCertificate,
) -> Result[Root, OrderedError] {
  match system_from_certificate(p, proof.system) {
    Err(e) => Err(e)
    Ok(system) =>
      if check_count(system, proof.count.interval, Succ(Zero), proof.count) {
        Ok({ system, certificate: proof, })
      } else {
        Err(InvalidCertificate)
      }
  }
}

///|
pub fn check_root_result(
  p : Polynomial,
  root : Root,
  proof : RootCertificate,
) -> Bool {
  equal(p, root.system.polynomial) &&
  system_payload(root.system, proof.system) &&
  root.certificate.equal(proof) &&
  check_root(p, proof)
}

///|
#derive(Eq, Debug)
pub(all) struct SolutionCertificate {
  system : SystemCertificate
  bound : BoundCertificate
  whole : CountCertificate
  roots : @core.Chain[RootCertificate]
}

///|
pub extend SolutionCertificate with Eq::{equal, not_equal}

///|
pub extend SolutionCertificate with Debug::{to_repr}

///|
#derive(Debug)
pub struct SolutionSet {
  system : System
  roots : @core.Chain[Root]
  certificate : SolutionCertificate
}

///|
pub extend SolutionSet with Debug::{to_repr}

///|
pub fn roots(value : SolutionSet) -> @core.Chain[Root] {
  value.roots
}

///|
pub fn solution_certificate(value : SolutionSet) -> SolutionCertificate {
  value.certificate
}

///|
fn bounding_interval(bound : @exact.Rational) -> @sturm.Interval {
  { lower: @exact.rational_negate(bound), upper: bound, }
}

///|
/// Coverage uses a strict global bound, the whole-interval count, disjoint
/// one-root subintervals and cardinality equality. A product check is not used.
pub fn check_isolation(p : Polynomial, proof : SolutionCertificate) -> Bool {
  match system_from_certificate(p, proof.system) {
    Err(_) => false
    Ok(system) => {
      let span = bounding_interval(proof.bound.bound)
      fn walk(
        values : @core.Chain[RootCertificate],
        lower : @exact.Rational,
      ) -> Bool {
        match values {
          Nil => true
          Cons(head, rest) => {
            let interval = head.count.interval
            head.system.equal(proof.system) &&
            !@exact.rational_compare(interval.lower, lower).equal(Less) &&
            !@exact.rational_compare(interval.upper, span.upper).equal(Greater) &&
            check_count(system, interval, Succ(Zero), head.count) &&
            walk(rest, interval.upper)
          }
        }
      }
      check_bound(system, proof.bound) &&
      check_count(system, span, proof.whole.count, proof.whole) &&
      @core.length(proof.roots).equal(proof.whole.count) &&
      walk(proof.roots, span.lower)
    }
  }
}

///|
pub fn check_isolation_result(
  p : Polynomial,
  value : SolutionSet,
  proof : SolutionCertificate,
) -> Bool {
  equal(p, value.system.polynomial) &&
  system_payload(value.system, proof.system) &&
  @core.all(value.roots, fn(root) {
    equal(p, root.system.polynomial) &&
    system_payload(root.system, proof.system)
  }) &&
  value.certificate.equal(proof) &&
  @core.map(value.roots, root_certificate).equal(proof.roots) &&
  check_isolation(p, proof)
}

///|
#derive(Debug)
enum Phase {
  FindingBound
  Splitting(
    BoundCertificate,
    CountCertificate,
    @core.Chain[CountCertificate],
    @core.Chain[RootCertificate]
  )
}

///|
pub extend Phase with Debug::{to_repr}

///|
#derive(Debug)
pub struct State {
  system : System
  threshold : @nf.Element
  signs : @core.Chain[ScalarCertificate]
  candidate : @binary.Binary
  phase : Phase
}

///|
pub extend State with Debug::{to_repr}

///|
#derive(Debug)
pub(all) enum Progress {
  Isolated(SolutionSet)
  Paused(State)
}

///|
pub extend Progress with Debug::{to_repr}

///|
pub fn isolate(system : System) -> Result[State, OrderedError] {
  match
    absolute_sum(
      system.polynomial.field,
      without_last(system.squarefree.coefficients),
    ) {
    Err(e) => Err(e)
    Ok((threshold, signs)) =>
      Ok({
        system,
        threshold,
        signs,
        candidate: @binary.one(),
        phase: FindingBound,
      })
  }
}

///|
fn midpoint(interval : @sturm.Interval) -> @exact.Rational {
  @exact.rational_half(@exact.rational_add(interval.lower, interval.upper))
}

///|
fn split(
  system : System,
  interval : @sturm.Interval,
) -> Result[(CountCertificate, CountCertificate), OrderedError] {
  let middle = midpoint(interval)
  match
    (
      count_between(system, { lower: interval.lower, upper: middle, }),
      count_between(system, { lower: middle, upper: interval.upper, }),
    ) {
    (Ok(left), Ok(right)) => Ok((left, right))
    (Err(e), _) | (_, Err(e)) => Err(e)
  }
}

///|
fn complete(
  system : System,
  bound : BoundCertificate,
  whole : CountCertificate,
  accepted : @core.Chain[RootCertificate],
) -> Result[Progress, OrderedError] {
  let proofs = @core.reverse(accepted)
  let proof : SolutionCertificate = {
    system: system.certificate,
    bound,
    whole,
    roots: proofs,
  }
  let values = @core.map(proofs, fn(certificate) {
    Root::{ system, certificate, }
  })
  Ok(Isolated({ system, roots: values, certificate: proof, }))
}

///|
/// One fuel unit performs a bound comparison or processes one bisection node.
/// It does not bound the bit complexity of field arithmetic or certificate checking.
pub fn advance(
  state : State,
  fuel : @core.Nat,
) -> Result[Progress, OrderedError] {
  match (state.phase, fuel) {
    (Splitting(bound, whole, Nil, accepted), _) =>
      complete(state.system, bound, whole, accepted)
    (_, Zero) => Ok(Paused(state))
    (FindingBound, Succ(rest)) => {
      let radius = @exact.whole(@exact.positive(state.candidate))
      match
        @nf.subtract(
          @nf.rational(state.system.polynomial.field, radius),
          state.threshold,
        ) {
        Err(e) => Err(FieldFailure(e))
        Ok(delta) =>
          match scalar_sign(delta) {
            Err(e) => Err(e)
            Ok(sign) =>
              if sign.sign.equal(Greater) {
                let bound : BoundCertificate = {
                  system: state.system.certificate,
                  bound: radius,
                  coefficients: state.signs,
                  comparison: sign.certificate,
                }
                match count_between(state.system, bounding_interval(radius)) {
                  Err(e) => Err(e)
                  Ok(whole) =>
                    advance(
                      {
                        ..state,
                        phase: Splitting(bound, whole, Cons(whole, Nil), Nil),
                      },
                      rest,
                    )
                }
              } else {
                advance(
                  {
                    ..state,
                    candidate: @binary.add(state.candidate, state.candidate),
                  },
                  rest,
                )
              }
          }
      }
    }
    (Splitting(bound, whole, Cons(head, pending), accepted), Succ(rest)) =>
      match head.count {
        Zero =>
          advance(
            { ..state, phase: Splitting(bound, whole, pending, accepted), },
            rest,
          )
        Succ(Zero) => {
          let root : RootCertificate = {
            system: state.system.certificate,
            count: head,
          }
          advance(
            {
              ..state,
              phase: Splitting(bound, whole, pending, Cons(root, accepted)),
            },
            rest,
          )
        }
        _ =>
          match split(state.system, head.interval) {
            Err(e) => Err(e)
            Ok((left, right)) =>
              if @core.add(left.count, right.count).equal(head.count) {
                advance(
                  {
                    ..state,
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
          }
      }
  }
}

///|
/// Perform exactly `steps` rational bisections, always retaining a checked
/// one-root interval. Zero steps returns the same valid root descriptor.
pub fn refine(root : Root, steps : @core.Nat) -> Result[Root, OrderedError] {
  match steps {
    Zero => Ok(root)
    Succ(rest) =>
      match split(root.system, root_interval(root)) {
        Err(e) => Err(e)
        Ok((left, right)) => {
          let chosen = if left.count.equal(Succ(Zero)) { left } else { right }
          if !chosen.count.equal(Succ(Zero)) ||
            !@core.add(left.count, right.count).equal(Succ(Zero)) {
            Err(InternalInvariant)
          } else {
            refine(
              {
                system: root.system,
                certificate: { system: root.system.certificate, count: chosen, },
              },
              rest,
            )
          }
        }
      }
  }
}
