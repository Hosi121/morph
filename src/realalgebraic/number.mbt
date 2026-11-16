///|
/// Untrusted representation of a distinct root in the half-open (lower, upper].
#derive(Eq, Debug)
pub(all) struct RootCertificate {
  polynomial : @poly.Polynomial
  interval : @sturm.Interval
}

///|
pub extend RootCertificate with Eq::{equal, not_equal}

///|
pub extend RootCertificate with Debug::{to_repr}

///|
/// An exactly represented real algebraic root; construction verifies one root.
#derive(Debug)
pub struct Number {
  system : @sturm.System
  interval : @sturm.Interval
}

///|
pub extend Number with Debug::{to_repr}

///|
pub fn number(data : RootCertificate) -> Result[Number, AlgebraError] {
  match @sturm.system(data.polynomial) {
    Err(_) => Err(InvalidDefinition)
    Ok(system) =>
      match
        @sturm.count_between(system, data.interval.lower, data.interval.upper) {
        Some(Succ(Zero)) => Ok({ system, interval: data.interval, })
        _ => Err(InvalidInterval)
      }
  }
}

///|
pub fn check_root(data : RootCertificate) -> Bool {
  number(data) is Ok(_)
}

///|
pub fn root_certificate(value : Number) -> RootCertificate {
  { polynomial: @sturm.squarefree(value.system), interval: value.interval, }
}

///|
pub fn interval(value : Number) -> @sturm.Interval {
  value.interval
}

///|
pub fn definition(value : Number) -> @poly.Polynomial {
  @sturm.squarefree(value.system)
}

///|
pub fn refine(
  value : Number,
  steps : @core.Nat,
) -> Result[Number, AlgebraError] {
  match @sturm.refine(value.system, value.interval, steps) {
    Some(interval) => Ok({ system: value.system, interval, })
    None => Err(InternalInvariant)
  }
}

///|
pub fn rational(value : @exact.Rational) -> Result[Number, AlgebraError] {
  match
    sparse(
      Cons(@exact.rational_negate(value), Cons(@exact.rational_one(), Nil)),
    ) {
    None => Err(InternalInvariant)
    Some(polynomial) =>
      number({
        polynomial,
        interval: {
          lower: @exact.rational_subtract(value, @exact.rational_one()),
          upper: value,
        },
      })
  }
}

///|
fn qmin(a : @exact.Rational, b : @exact.Rational) -> @exact.Rational {
  match @exact.rational_compare(a, b) {
    Greater => b
    _ => a
  }
}

///|
fn qmax(a : @exact.Rational, b : @exact.Rational) -> @exact.Rational {
  match @exact.rational_compare(a, b) {
    Less => b
    _ => a
  }
}

///|
fn contained(inner : @sturm.Interval, outer : @sturm.Interval) -> Bool {
  !@exact.rational_compare(inner.lower, outer.lower).equal(Less) &&
  !@exact.rational_compare(inner.upper, outer.upper).equal(Greater)
}

///|
fn same_root_refinement(
  original : Number,
  interval : @sturm.Interval,
) -> Number? {
  if !contained(interval, original.interval) {
    None
  } else {
    match
      @sturm.count_between(original.system, interval.lower, interval.upper) {
      Some(Succ(Zero)) => Some({ system: original.system, interval, })
      _ => None
    }
  }
}

///|
fn common_system(
  a : Number,
  b : Number,
) -> Result[@sturm.System?, AlgebraError] {
  match @poly.univariate_gcd(definition(a), definition(b)) {
    Err(_) => Err(InternalInvariant)
    Ok(gcd) =>
      match positive_dense(gcd) {
        None => Ok(None)
        Some(_) =>
          match @sturm.system(gcd) {
            Ok(system) => Ok(Some(system))
            Err(_) => Err(InternalInvariant)
          }
      }
  }
}

///|
fn interval_order(
  a : @sturm.Interval,
  b : @sturm.Interval,
  common : @sturm.System?,
) -> @core.Ordering? {
  if !@exact.rational_compare(a.upper, b.lower).equal(Greater) {
    Some(Less)
  } else if !@exact.rational_compare(b.upper, a.lower).equal(Greater) {
    Some(Greater)
  } else {
    match common {
      None => None
      Some(system) =>
        match
          @sturm.count_between(
            system,
            qmax(a.lower, b.lower),
            qmin(a.upper, b.upper),
          ) {
          Some(Succ(_)) => Some(Equal)
          _ => None
        }
    }
  }
}

///|
#derive(Eq, Debug)
pub(all) struct ComparisonCertificate {
  left : RootCertificate
  right : RootCertificate
  left_refined : @sturm.Interval
  right_refined : @sturm.Interval
  order : @core.Ordering
}

///|
pub extend ComparisonCertificate with Eq::{equal, not_equal}

///|
pub extend ComparisonCertificate with Debug::{to_repr}

///|
pub fn check_comparison(proof : ComparisonCertificate) -> Bool {
  match (number(proof.left), number(proof.right)) {
    (Ok(a), Ok(b)) =>
      match
        (
          same_root_refinement(a, proof.left_refined),
          same_root_refinement(b, proof.right_refined),
        ) {
        (Some(ar), Some(br)) =>
          match common_system(ar, br) {
            Ok(common) =>
              match interval_order(ar.interval, br.interval, common) {
                Some(order) => order.equal(proof.order)
                None => false
              }
            Err(_) => false
          }
        _ => false
      }
    _ => false
  }
}

///|
#derive(Debug)
pub struct Comparison {
  original_left : RootCertificate
  original_right : RootCertificate
  left : Number
  right : Number
  common : @sturm.System?
}

///|
pub extend Comparison with Debug::{to_repr}

///|
#derive(Debug)
pub(all) enum ComparisonProgress {
  Compared(@core.Ordering, ComparisonCertificate)
  ComparisonPaused(Comparison)
}

///|
pub extend ComparisonProgress with Debug::{to_repr}

///|
pub fn comparison(
  left : Number,
  right : Number,
) -> Result[Comparison, AlgebraError] {
  match common_system(left, right) {
    Err(error) => Err(error)
    Ok(common) =>
      Ok({
        original_left: root_certificate(left),
        original_right: root_certificate(right),
        left,
        right,
        common,
      })
  }
}

///|
/// Fuel counts paired exact bisections. Equality is decided using a common root
/// of the gcd in the intersection, never by interval overlap alone.
pub fn compare_advance(
  state : Comparison,
  fuel : @core.Nat,
) -> Result[ComparisonProgress, AlgebraError] {
  match
    interval_order(state.left.interval, state.right.interval, state.common) {
    Some(order) =>
      Ok(
        Compared(order, {
          left: state.original_left,
          right: state.original_right,
          left_refined: state.left.interval,
          right_refined: state.right.interval,
          order,
        }),
      )
    None =>
      match fuel {
        Zero => Ok(ComparisonPaused(state))
        Succ(rest) =>
          match
            (refine(state.left, Succ(Zero)), refine(state.right, Succ(Zero))) {
            (Ok(left), Ok(right)) =>
              compare_advance({ ..state, left, right, }, rest)
            _ => Err(InternalInvariant)
          }
      }
  }
}

///|
pub fn compare(
  left : Number,
  right : Number,
  fuel : @core.Nat,
) -> Result[ComparisonProgress, AlgebraError] {
  match comparison(left, right) {
    Ok(state) => compare_advance(state, fuel)
    Err(error) => Err(error)
  }
}
