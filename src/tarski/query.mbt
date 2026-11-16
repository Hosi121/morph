///|
#derive(Eq, Debug)
pub(all) enum TarskiError {
  NotUnivariate
  ZeroPolynomial
  InvalidInterval
  InvalidRoot
  PolynomialFailure
  InternalInvariant
}

///|
pub extend TarskiError with Eq::{equal, not_equal}

///|
pub extend TarskiError with Debug::{to_repr}

///|
/// First nonzero derivative at an endpoint: its sign is the right-hand limit
/// sign of the original polynomial. All earlier derivatives must vanish.
#derive(Eq, Debug)
pub(all) struct RightJet {
  order : @core.Nat
  value : @exact.Rational
}

///|
pub extend RightJet with Eq::{equal, not_equal}

///|
pub extend RightJet with Debug::{to_repr}

///|
#derive(Eq, Debug)
pub(all) struct QueryCertificate {
  polynomial : @poly.Polynomial
  query : @poly.Polynomial
  interval : @sturm.Interval
  normalized : @poly.Polynomial
  seed : @poly.Polynomial
  sequence : @core.Chain[@poly.Polynomial]
  quotients : @core.Chain[@poly.Polynomial]
  lower_jets : @core.Chain[RightJet]
  upper_jets : @core.Chain[RightJet]
  result : @exact.Integer
}

///|
pub extend QueryCertificate with Eq::{equal, not_equal}

///|
pub extend QueryCertificate with Debug::{to_repr}

///|
#derive(Eq, Debug)
pub(all) struct QueryResult {
  value : @exact.Integer
  certificate : QueryCertificate
}

///|
pub extend QueryResult with Eq::{equal, not_equal}

///|
pub extend QueryResult with Debug::{to_repr}

///|
fn valid_inputs(
  p : @poly.Polynomial,
  q : @poly.Polynomial,
  interval : @sturm.Interval,
) -> Result[Unit, TarskiError] {
  if !@poly.variables(p).equal(Succ(Zero)) ||
    !@poly.variables(q).equal(Succ(Zero)) {
    Err(NotUnivariate)
  } else if @poly.is_zero(p) {
    Err(ZeroPolynomial)
  } else if !@exact.rational_compare(interval.lower, interval.upper).equal(Less) {
    Err(InvalidInterval)
  } else {
    Ok(())
  }
}

///|
fn degree(p : @poly.Polynomial) -> @core.Nat? {
  match @poly.terms(p) {
    Cons({ exponents: Cons(n, Nil), .. }, _) => Some(n)
    _ => None
  }
}

///|
fn smaller(a : @poly.Polynomial, b : @poly.Polynomial) -> Bool {
  match (degree(a), degree(b)) {
    (Some(a), Some(b)) => @core.compare(a, b).equal(Less)
    _ => false
  }
}

///|
fn sign(value : @exact.Rational) -> @core.Ordering {
  @exact.rational_compare(value, @exact.rational_zero())
}

///|
fn derivative(p : @poly.Polynomial) -> @poly.Polynomial? {
  @poly.derivative(p, Zero)
}

///|
fn seed(p : @poly.Polynomial, q : @poly.Polynomial) -> @poly.Polynomial? {
  match derivative(p) {
    None => None
    Some(d) =>
      match @poly.multiply(d, q) {
        Ok(product) =>
          match @poly.normal_form(product, Cons(p, Nil)) {
            Ok(seed) => Some(seed)
            Err(_) => None
          }
        Err(_) => None
      }
  }
}

///|
fn build_sequence(
  a : @poly.Polynomial,
  b : @poly.Polynomial,
) -> (@core.Chain[@poly.Polynomial], @core.Chain[@poly.Polynomial])? {
  if @poly.is_zero(b) {
    Some((Cons(a, Nil), Nil))
  } else {
    match @poly.divide(a, Cons(b, Nil)) {
      Ok({ quotients: Cons(quotient, Nil), remainder, }) =>
        match build_sequence(b, @poly.negate(remainder)) {
          Some((sequence, quotients)) =>
            Some((Cons(a, sequence), Cons(quotient, quotients)))
          None => None
        }
      _ => None
    }
  }
}

///|
fn right_jet(p : @poly.Polynomial, x : @exact.Rational) -> RightJet? {
  fn walk(p : @poly.Polynomial, order : @core.Nat) -> RightJet? {
    match @poly.evaluate(p, Cons(x, Nil)) {
      None => None
      Some(value) =>
        if !sign(value).equal(Equal) {
          Some({ order, value, })
        } else if @poly.is_zero(p) {
          None
        } else {
          match derivative(p) {
            Some(d) => walk(d, Succ(order))
            None => None
          }
        }
    }
  }
  walk(p, Zero)
}

///|
fn endpoint_jets(
  sequence : @core.Chain[@poly.Polynomial],
  x : @exact.Rational,
) -> @core.Chain[RightJet]? {
  match sequence {
    Nil => Some(Nil)
    Cons(head, rest) =>
      match (right_jet(head, x), endpoint_jets(rest, x)) {
        (Some(jet), Some(tail)) => Some(Cons(jet, tail))
        _ => None
      }
  }
}

///|
fn variations(jets : @core.Chain[RightJet]) -> @core.Nat {
  fn scan(
    values : @core.Chain[RightJet],
    previous : @core.Ordering,
    count : @core.Nat,
  ) -> @core.Nat {
    match values {
      Nil => count
      Cons(head, rest) => {
        let current = sign(head.value)
        match (previous, current) {
          (Less, Greater) | (Greater, Less) => scan(rest, current, Succ(count))
          _ => scan(rest, current, count)
        }
      }
    }
  }
  scan(jets, Equal, Zero)
}

///|
fn difference(
  lower : @core.Chain[RightJet],
  upper : @core.Chain[RightJet],
) -> @exact.Integer {
  @exact.subtract(
    @exact.positive(@binary.from_nat(variations(lower))),
    @exact.positive(@binary.from_nat(variations(upper))),
  )
}

///|
/// Sum sign(Q(r)) over DISTINCT real roots r of nonzero P in (lower, upper].
/// P may have repeated roots and P,Q may have common roots. Zero Q and constant
/// nonzero P are supported. No root isolation, endpoint perturbation or interval
/// refinement is performed: right-limit signs use exact endpoint derivatives.
pub fn query(
  p : @poly.Polynomial,
  q : @poly.Polynomial,
  interval : @sturm.Interval,
) -> Result[QueryResult, TarskiError] {
  match valid_inputs(p, q, interval) {
    Err(error) => Err(error)
    Ok(_) => {
      let normalized = @poly.monic(p)
      match seed(normalized, q) {
        None => Err(PolynomialFailure)
        Some(seed) =>
          match build_sequence(normalized, seed) {
            None => Err(PolynomialFailure)
            Some((sequence, quotients)) =>
              match
                (
                  endpoint_jets(sequence, interval.lower),
                  endpoint_jets(sequence, interval.upper),
                ) {
                (Some(lower_jets), Some(upper_jets)) => {
                  let value = difference(lower_jets, upper_jets)
                  Ok({
                    value,
                    certificate: {
                      polynomial: p,
                      query: q,
                      interval,
                      normalized,
                      seed,
                      sequence,
                      quotients,
                      lower_jets,
                      upper_jets,
                      result: value,
                    },
                  })
                }
                _ => Err(InternalInvariant)
              }
          }
      }
    }
  }
}
